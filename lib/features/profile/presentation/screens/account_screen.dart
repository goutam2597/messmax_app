import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/locale/app_translations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/locale/locale_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../data/models/account_response_model.dart';
import '../../data/repositories/account_repository.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/delete_account_dialog.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../../features/dashboard/data/models/dashboard_model.dart';
import '../../../main/presentation/screens/main_shell_screen.dart';
import '../../../dashboard/presentation/widgets/dash_ui.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AccountRepository _repository = AccountRepository();
  AccountResponseModel? _accountData;
  bool _isLoading = true;
  bool _isSavingProfile = false;
  bool _isUpdatingPassword = false;
  String? _selectedAvatarPath;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  Future<void> _pickAvatarImage() async {
    try {
      final XFile? picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked != null) {
        setState(() => _selectedAvatarPath = picked.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'ui.account_pick_avatar_failed'.tr2}: $e')),
      );
    }
  }

  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    final cached = AccountRepository.getCached();
    if (cached != null) {
      _accountData = cached;
      _nameController.text = cached.user.name;
      _emailController.text = cached.user.email;
      _isLoading = false;
    } else {
      _loadAccountDetails();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _loadAccountDetails({bool forceRefresh = false}) async {
    try {
      final res = await _repository.fetchAccountDetails(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _accountData = res;
        _nameController.text = res.user.name;
        _emailController.text = res.user.email;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ui.account_name_empty'.tr2)));
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ui.account_email_invalid'.tr2)));
      return;
    }

    setState(() => _isSavingProfile = true);
    try {
      await _repository.updateProfile(
        name: name,
        email: email,
        avatarFilePath: _selectedAvatarPath,
      );
      if (!mounted) return;

      _selectedAvatarPath = null;
      // Re-hydrate AuthCubit to refresh user profile app-wide
      context.read<AuthCubit>().checkAuth();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ui.account_profile_updated'.tr2)));
      _loadAccountDetails(forceRefresh: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'ui.account_profile_failed'.tr2}: ${e.toString()}'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  Future<void> _updatePassword() async {
    final current = _currentPassController.text;
    final newPass = _newPassController.text;
    final confirm = _confirmPassController.text;

    if (current.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ui.account_current_required'.tr2)),
      );
      return;
    }
    if (newPass.length < 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ui.account_new_pass_short'.tr2)));
      return;
    }
    if (newPass != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ui.account_pass_mismatch'.tr2)));
      return;
    }

    setState(() => _isUpdatingPassword = true);
    try {
      await _repository.updatePassword(
        currentPassword: current,
        newPassword: newPass,
        newPasswordConfirmation: confirm,
      );
      if (!mounted) return;
      _currentPassController.clear();
      _newPassController.clear();
      _confirmPassController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ui.account_pass_updated'.tr2)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'ui.account_pass_failed'.tr2}: ${e.toString()}'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingPassword = false);
    }
  }

  void _backToDashboard() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _backToDashboard();
      },
      child: Scaffold(
        backgroundColor: AppColors.paper,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          leading: AppBackButton(onPressed: _backToDashboard),
          title: Text(
            'ui.my_account'.tr2,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    borderRadius: BorderRadius.circular(DashUI.rCard),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.paperLine),
                      ),
                      child: const Icon(
                        Icons.settings_rounded,
                        color: AppColors.ink,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.brandDark),
                )
              : RefreshIndicator(
                  color: AppColors.brandDark,
                  onRefresh: () => _loadAccountDetails(forceRefresh: true),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildUserHeaderCard(context),
                        const SizedBox(height: 20),
                        _buildLanguageCard(context),
                        const SizedBox(height: 20),
                        _buildProfileEditCard(),
                        const SizedBox(height: 20),
                        _buildPasswordEditCard(),
                        const SizedBox(height: 20),
                        if (_accountData != null &&
                            _accountData!.messes.isNotEmpty) ...[
                          _buildMyMessesCard(_accountData!.messes),
                          const SizedBox(height: 20),
                        ],
                        _buildDeleteAccountCard(context),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildUserHeaderCard(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState is AuthAuthenticated
        ? authState.user
        : _accountData?.user;
    final avatarUrl = user?.avatarUrl != null
        ? AppConfig.sanitizeImageUrl(user!.avatarUrl)
        : null;
    final userName = user?.name ?? 'Mess Member';
    final userEmail = user?.email ?? '';
    final roleLabel = user?.roleLabel ?? 'INDIVIDUAL';
    final initials = user?.initials ?? 'M';

    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandDark, AppColors.brandDeep],
        ),
        borderRadius: BorderRadius.circular(DashUI.rCard),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandDark.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -34,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            top: 22,
            right: -20,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1.5,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -38,
            left: -26,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: _pickAvatarImage,
                child: Stack(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: _selectedAvatarPath != null
                            ? Image.file(
                                File(_selectedAvatarPath!),
                                fit: BoxFit.cover,
                              )
                            : (avatarUrl != null
                                  ? Image.network(
                                      avatarUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Center(
                                                child: Text(
                                                  initials,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                    )
                                  : Center(
                                      child: Text(
                                        initials,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    )),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: AppColors.brandDark,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userEmail,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: user?.isIndividual == true
                            ? AppColors.amber
                            : AppColors.emerald,
                        borderRadius: BorderRadius.circular(DashUI.rTile),
                      ),
                      child: Text(
                        roleLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileEditCard() {
    return DashUI.accentedCard(
      accent: AppColors.brand,
      shape: DashShape.blob,
      rich: true,
      shadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.badge_outlined,
                  color: AppColors.brandDark,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'ui.account_personal_title'.tr2,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'ui.account_full_name'.tr2,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'ui.account_name_hint'.tr2,
                prefixIcon: Icon(
                  Icons.person_outline_rounded,
                  size: 20,
                  color: AppColors.inkFaded,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'ui.account_email_label'.tr2,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'ui.account_email_hint'.tr2,
                prefixIcon: Icon(
                  Icons.email_outlined,
                  size: 20,
                  color: AppColors.inkFaded,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'ui.account_avatar_label'.tr2,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickAvatarImage,
              borderRadius: BorderRadius.circular(DashUI.rTile),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(DashUI.rTile),
                  border: Border.all(
                    color: _selectedAvatarPath != null
                        ? AppColors.brandDark
                        : AppColors.paperLine,
                    width: _selectedAvatarPath != null ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.brandSoft,
                        borderRadius: BorderRadius.circular(DashUI.rBtn),
                      ),
                      child: const Icon(
                        Icons.add_a_photo_outlined,
                        size: 18,
                        color: AppColors.brandDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedAvatarPath != null
                            ? '${'ui.account_photo_selected'.tr2} (${_selectedAvatarPath!.split('/').last})'
                            : 'ui.account_photo_tap'.tr2,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _selectedAvatarPath != null
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: _selectedAvatarPath != null
                              ? AppColors.brandDark
                              : AppColors.inkSoft,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_selectedAvatarPath != null)
                      GestureDetector(
                        onTap: () => setState(() => _selectedAvatarPath = null),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.inkFaded,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSavingProfile ? null : _saveProfile,
                child: _isSavingProfile
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('ui.account_save_profile'.tr2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordEditCard() {
    return DashUI.accentedCard(
      accent: AppColors.blue,
      shape: DashShape.arc,
      rich: true,
      shadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.lock_reset_rounded,
                  color: AppColors.brandDark,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'ui.account_change_pass_title'.tr2,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'ui.account_current_pass'.tr2,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _currentPassController,
              obscureText: _obscureCurrent,
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  size: 20,
                  color: AppColors.inkFaded,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrent
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 18,
                    color: AppColors.inkFaded,
                  ),
                  onPressed: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'ui.account_new_pass'.tr2,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _newPassController,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                hintText: 'ui.account_new_pass_hint'.tr2,
                prefixIcon: const Icon(
                  Icons.key_rounded,
                  size: 20,
                  color: AppColors.inkFaded,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 18,
                    color: AppColors.inkFaded,
                  ),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'ui.account_confirm_new_pass'.tr2,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _confirmPassController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                hintText: 'ui.account_confirm_hint'.tr2,
                prefixIcon: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 20,
                  color: AppColors.inkFaded,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 18,
                    color: AppColors.inkFaded,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isUpdatingPassword ? null : _updatePassword,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandDark,
                ),
                child: _isUpdatingPassword
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('ui.account_update_pass'.tr2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyMessesCard(List<MyMessModel> messes) {
    return DashUI.accentedCard(
      accent: AppColors.teal,
      shape: DashShape.dots,
      rich: true,
      shadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.apartment_rounded,
                      color: AppColors.brandDark,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'ui.account_my_messes'.tr2,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(DashUI.rBtn),
                  ),
                  child: Text(
                    '${messes.length} ${'ui.account_total'.tr2}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < messes.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.paperLine),
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DashboardScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(DashUI.rTile),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 4,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.brandSoft,
                          borderRadius: BorderRadius.circular(DashUI.rBtn),
                        ),
                        child: const Icon(
                          Icons.home_work_rounded,
                          size: 18,
                          color: AppColors.brandDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              messes[i].name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              '${messes[i].membersCount} ${'ui.messes_members'.tr2} • ${'ui.account_role_label'.tr2}: ${messes[i].role.toUpperCase()}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.inkFaded,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.inkFaded,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteAccountCard(BuildContext context) {
    return DashUI.accentedCard(
      accent: AppColors.danger,
      shape: DashShape.band,
      color: AppColors.dangerSoft.withValues(alpha: 0.35),
      borderColor: AppColors.danger.withValues(alpha: 0.25),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.danger,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'ui.account_danger_zone'.tr2,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'ui.account_danger_desc'.tr2,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.inkSoft,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _handleDeleteAccount,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger, width: 1.2),
                  minimumSize: const Size(0, 48),
                  fixedSize: const Size.fromHeight(48),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DashUI.rCard),
                  ),
                ),
                icon: const Icon(Icons.delete_forever_rounded, size: 18),
                label: Text(
                  'ui.account_delete_btn'.tr2,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    final password = await DeleteAccountDialog.show(context);
    if (password == null || !mounted) return;

    // Show loading spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.danger),
        ),
      ),
    );

    try {
      await context.read<AuthCubit>().deleteAccount(
        password: password.isNotEmpty ? password : null,
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShellScreen(initialTab: 0)),
        (_) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ui.account_deleted'.tr2),
          backgroundColor: AppColors.ink,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Widget _buildLanguageCard(BuildContext context) {
    return DashUI.accentedCard(
      accent: AppColors.violet,
      shape: DashShape.dots,
      shadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(DashUI.rBtn),
                  ),
                  child: const Icon(
                    Icons.translate_rounded,
                    color: AppColors.brandDark,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ui.language'.tr2,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'ui.change_language'.tr2,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.inkFaded,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                BlocBuilder<LocaleCubit, Locale>(
                  builder: (context, locale) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandSoft,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        locale.languageCode == 'bn'
                            ? 'ui.bengali'.tr2
                            : 'ui.english'.tr2,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandDark,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            BlocBuilder<LocaleCubit, Locale>(
              builder: (context, locale) {
                final isEn = locale.languageCode == 'en';
                return Row(
                  children: [
                    Expanded(
                      child: _buildLangOption(
                        title: 'English',
                        subtitle: 'English',
                        selected: isEn,
                        onTap: () =>
                            context.read<LocaleCubit>().setLocale('en'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildLangOption(
                        title: 'বাংলা',
                        subtitle: 'Bengali',
                        selected: !isEn,
                        onTap: () =>
                            context.read<LocaleCubit>().setLocale('bn'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLangOption({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DashUI.rTile),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandDark : AppColors.paper,
          borderRadius: BorderRadius.circular(DashUI.rTile),
          border: Border.all(
            color: selected ? AppColors.brandDark : AppColors.paperLine,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? Colors.white.withValues(alpha: 0.18)
                    : AppColors.paperRaised,
                border: Border.all(
                  color: selected ? Colors.white : AppColors.paperLine,
                  width: selected ? 2 : 1,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 11,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : AppColors.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppColors.inkFaded,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
