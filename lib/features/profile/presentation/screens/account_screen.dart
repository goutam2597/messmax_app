import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../data/models/account_response_model.dart';
import '../../data/repositories/account_repository.dart';
import '../../../../features/dashboard/data/models/dashboard_model.dart';

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
        SnackBar(content: Text('Failed to pick avatar image: $e')),
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
    _loadAccountDetails();
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
      final res = await _repository.fetchAccountDetails(forceRefresh: forceRefresh);
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
      ).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile & avatar updated successfully!')),
      );
      _loadAccountDetails(forceRefresh: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile update failed: ${e.toString()}')),
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
        const SnackBar(content: Text('Enter your current password')),
      );
      return;
    }
    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password must be at least 6 characters'),
        ),
      );
      return;
    }
    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password update failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'My Account',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandDark, AppColors.brandDeep],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandDark.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
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
                                errorBuilder: (context, error, stackTrace) =>
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
                        ? const Color(0xFFE85D04)
                        : const Color(0xFF0F9F59),
                    borderRadius: BorderRadius.circular(12),
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
    );
  }

  Widget _buildProfileEditCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.paperLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.badge_outlined, color: AppColors.brandDark, size: 20),
              SizedBox(width: 8),
              Text(
                'Personal Profile Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'FULL NAME',
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
            decoration: const InputDecoration(
              hintText: 'Your name',
              prefixIcon: Icon(
                Icons.person_outline_rounded,
                size: 20,
                color: AppColors.inkFaded,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'EMAIL ADDRESS',
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
            decoration: const InputDecoration(
              hintText: 'you@example.com',
              prefixIcon: Icon(
                Icons.email_outlined,
                size: 20,
                color: AppColors.inkFaded,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'AVATAR / PROFILE PHOTO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: _pickAvatarImage,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(12),
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
                      borderRadius: BorderRadius.circular(8),
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
                          ? 'New photo selected (${_selectedAvatarPath!.split('/').last})'
                          : 'Tap to select new profile photo',
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
                  : const Text('Save Profile Details'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordEditCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.paperLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.lock_reset_rounded,
                color: AppColors.brandDark,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Change Password',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'CURRENT PASSWORD',
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
          const Text(
            'NEW PASSWORD',
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
              hintText: 'At least 6 characters',
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
          const Text(
            'CONFIRM NEW PASSWORD',
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
              hintText: 'Repeat new password',
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
                  : const Text('Update Password'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyMessesCard(List<MyMessModel> messes) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.paperLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.apartment_rounded,
                    color: AppColors.brandDark,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'My Messes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${messes.length} Total',
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(10),
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
                          '${messes[i].membersCount} Members • Role: ${messes[i].role.toUpperCase()}',
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
          ],
        ],
      ),
    );
  }

  Widget _buildDeleteAccountCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF2F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF8D7D7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFA02626),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Danger Zone',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFA02626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Deleting your account will remove your personal data and mess memberships.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF852222),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion requires web confirmation'),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFA02626),
              side: const BorderSide(color: Color(0xFFA02626), width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
}
