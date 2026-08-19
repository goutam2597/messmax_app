import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/locale/app_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/signup_role_dialog.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _step = 1;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  String _accountType = 'individual';
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _toStep2() {
    final name = _name.text.trim();
    final email = _email.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('auth.full_name_required'.tr2)),
      );
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('auth.invalid_email'.tr2)),
      );
      return;
    }
    setState(() => _step = 2);
  }

  void _submit() {
    if (_pass.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('auth.password_too_short'.tr2)),
      );
      return;
    }
    if (_pass.text != _confirm.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('auth.passwords_do_not_match'.tr2)));
      return;
    }
    context.read<AuthCubit>().register(
      name: _name.text.trim(),
      email: _email.text.trim(),
      password: _pass.text,
      passwordConfirmation: _confirm.text,
      accountType: _accountType,
    );
  }

  void _googleWithPick() {
    // Google first — no dialog before. If the account is new, the listener
    // shows the role picker AFTER Google signs in; existing users go straight in.
    context.read<AuthCubit>().loginWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: const AppBackButton(),
      ),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) async {
          if (state is AuthAuthenticated) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
              (_) => false,
            );
          }
          if (state is AuthNeedsAccountType) {
            // NEW Google account — choose role AFTER Google signed in
            final picked = await SignUpRoleDialog.show(
              context,
              initialRole: _accountType,
            );
            if (!context.mounted) return;
            if (picked == null) {
              context.read<AuthCubit>().cancelGooglePick();
              return;
            }
            setState(() => _accountType = picked);
            context.read<AuthCubit>().completeGoogleWithAccountType(
              idToken: state.idToken,
              accountType: picked,
            );
          }
          if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: AppTranslations.notifier,
                  builder: (context, _, _) => AppAuthHeader(
                    title: 'auth.create_account'.tr2,
                    subtitle: 'auth.one_account_unlimited'.tr2,
                  ),
                ),
                const SizedBox(height: 22),
                _stepperHeader(),
                const SizedBox(height: 20),
                _card(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepperHeader() {
    return ValueListenableBuilder<int>(
      valueListenable: AppTranslations.notifier,
      builder: (context, _, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.paperRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.paperLine),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _stepBadge(1, 'auth.step_account_setup'.tr2, _step >= 1, _step == 1),
                Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: _step >= 2 ? AppColors.brand : AppColors.paperLine,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                _stepBadge(2, 'auth.step_security'.tr2, _step >= 2, _step == 2),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepBadge(int stepNum, String title, bool active, bool current) {
    final isDone = stepNum < _step;
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? const Color(0xFF1F6A39)
                : (current ? AppColors.brandDark : AppColors.paperLine),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : Text(
                    '$stepNum',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: current ? Colors.white : AppColors.inkFaded,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: current ? FontWeight.w800 : FontWeight.w600,
            color: current ? AppColors.ink : AppColors.inkFaded,
          ),
        ),
      ],
    );
  }

  Widget _card() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isAnyLoading = state is AuthLoading;
        final isEmailLoading =
            state is AuthLoading &&
            (state.type == AuthLoadingType.email ||
                state.type == AuthLoadingType.general);
        final isGoogleLoading =
            state is AuthLoading && state.type == AuthLoadingType.google;
        final err = state is AuthError ? state.message : null;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          decoration: BoxDecoration(
            color: AppColors.paperRaised,
            border: Border.all(color: AppColors.paperLine),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (err != null) ...[
                AuthErrorBanner(message: err),
                const SizedBox(height: 16),
              ],
              if (_step == 1) ...[
                FieldLabel('auth.full_name'.tr2),
                const SizedBox(height: 6),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'auth.full_name_hint'.tr2,
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      size: 20,
                      color: AppColors.inkFaded,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                FieldLabel('auth.email'.tr2),
                const SizedBox(height: 6),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'auth.email_hint'.tr2,
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      size: 20,
                      color: AppColors.inkFaded,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<int>(
                  valueListenable: AppTranslations.notifier,
                  builder: (context, _, _) => Row(
                    children: [
                      Text(
                        'ui.account_type'.tr2,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppColors.inkSoft,
                        ),
                      ),
                      const Text(
                        ' *',
                        style: TextStyle(
                          color: AppColors.brandDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ValueListenableBuilder<int>(
                  valueListenable: AppTranslations.notifier,
                  builder: (context, _, _) => Row(
                    children: [
                      Expanded(
                        child: AccountTypeTile(
                          title: 'auth.individual'.tr2,
                          subtitle: 'auth.single_mess'.tr2,
                          icon: Icons.person_rounded,
                          selected: _accountType == 'individual',
                          onTap: () =>
                              setState(() => _accountType = 'individual'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AccountTypeTile(
                          title: 'auth.hostel_owner'.tr2,
                          subtitle: 'auth.many_messes'.tr2,
                          icon: Icons.business_rounded,
                          selected: _accountType == 'hostel_owner',
                          onTap: () =>
                              setState(() => _accountType = 'hostel_owner'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ValueListenableBuilder<int>(
                  valueListenable: AppTranslations.notifier,
                  builder: (context, _, _) => FilledButton(
                    onPressed: isAnyLoading ? null : _toStep2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('auth.continue_to_security'.tr2),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<int>(
                  valueListenable: AppTranslations.notifier,
                  builder: (context, _, _) => Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.paperLine)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'auth.or'.tr2,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: AppColors.inkFaded,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.paperLine)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GoogleSignInButton(
                  loading: isGoogleLoading,
                  onPressed: isAnyLoading ? null : () => _googleWithPick(),
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<int>(
                  valueListenable: AppTranslations.notifier,
                  builder: (context, _, _) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${'auth.already_have_account'.tr2} ',
                        style: const TextStyle(fontSize: 13, color: AppColors.inkFaded),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Text(
                          'auth.sign_in'.tr2,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandDark,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.paperLine),
                  ),
                  child: Row(
                    children: [
                      AppBackButton(
                        onPressed: () => setState(() => _step = 1),
                        size: 32,
                        iconSize: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _name.text.trim(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _email.text.trim(),
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.inkFaded,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      ValueListenableBuilder<int>(
                        valueListenable: AppTranslations.notifier,
                        builder: (context, _, _) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _accountType == 'hostel_owner'
                                ? 'auth.hostel_owner'.tr2.toUpperCase()
                                : 'auth.individual'.tr2.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: AppColors.brandDark,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18),
                FieldLabel('auth.password'.tr2),
                const SizedBox(height: 6),
                TextField(
                  controller: _pass,
                  obscureText: _obscure1,
                  decoration: InputDecoration(
                    hintText: 'auth.password_hint'.tr2,
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      size: 20,
                      color: AppColors.inkFaded,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure1
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 18,
                        color: AppColors.inkFaded,
                      ),
                      onPressed: () => setState(() => _obscure1 = !_obscure1),
                    ),
                  ),
                ),
                SizedBox(height: 14),
                FieldLabel('auth.confirm_password'.tr2),
                const SizedBox(height: 6),
                TextField(
                  controller: _confirm,
                  obscureText: _obscure2,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'auth.confirm_password_hint'.tr2,
                    prefixIcon: const Icon(
                      Icons.lock_reset_rounded,
                      size: 20,
                      color: AppColors.inkFaded,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure2
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 18,
                        color: AppColors.inkFaded,
                      ),
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: isAnyLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandDark,
                  ),
                  child: isEmailLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : ValueListenableBuilder<int>(
                          valueListenable: AppTranslations.notifier,
                          builder: (context, _, _) => Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text('auth.create_account'.tr2),
                            ],
                          ),
                        ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
