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
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _email.text.trim();
    final pass = _password.text;
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('auth.invalid_email'.tr2)),
      );
      return;
    }
    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('auth.password_too_short'.tr2)),
      );
      return;
    }
    context.read<AuthCubit>().login(email: email, password: pass);
  }

  void _googleWithPick() {
    // Google first — no role dialog before. If the account is brand new,
    // the server returns needs_account_type and the listener shows the picker AFTER.
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
          } else if (state is AuthNeedsAccountType) {
            // NEW Google account — ask role AFTER Google signed in
            final picked = await SignUpRoleDialog.show(
              context,
              initialRole: 'individual',
            );
            if (!context.mounted) return;
            if (picked == null) {
              context.read<AuthCubit>().cancelGooglePick();
              return;
            }
            context.read<AuthCubit>().completeGoogleWithAccountType(
                  idToken: state.idToken,
                  accountType: picked,
                );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppAuthHeader(
                        title: 'auth.welcome_back'.tr2,
                        subtitle: 'auth.sign_in_to_messmax'.tr2,
                      ),
                      const SizedBox(height: 16),
                      _marketingStrip(),
                      const SizedBox(height: 18),
                      _card(),
                      const SizedBox(height: 16),
                      Text(
                        'auth.ledger_tagline'.tr2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.inkFaded,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _marketingStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        border: Border.all(color: AppColors.paperLine),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ValueListenableBuilder<int>(
        valueListenable: AppTranslations.notifier,
        builder: (context, _, _) => Row(
          children: [
            _miniStat('auth.strip_bazar'.tr2, 'auth.strip_ledger'.tr2),
            _divider(),
            _miniStat('auth.strip_meals'.tr2, 'auth.strip_count'.tr2),
            _divider(),
            _miniStat('auth.strip_rate'.tr2, 'auth.strip_auto'.tr2, highlight: true),
            _divider(),
            _miniStat('auth.strip_rest'.tr2, 'auth.strip_sync'.tr2, highlight: true),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 28,
    color: AppColors.paperLine,
    margin: const EdgeInsets.symmetric(horizontal: 6),
  );

  Widget _miniStat(String label, String value, {bool highlight = false}) =>
      Expanded(
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: AppColors.inkFaded,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: highlight ? AppColors.brandDark : AppColors.ink,
              ),
            ),
          ],
        ),
      );

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

        return Container(
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
              const SizedBox(height: 14),
              FieldLabel('auth.password'.tr2),
              const SizedBox(height: 6),
              TextField(
                controller: _password,
                obscureText: _obscure,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    size: 20,
                    color: AppColors.inkFaded,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 18,
                      color: AppColors.inkFaded,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                  ),
                  child: Text(
                    'auth.forgot_password_title'.tr2,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<int>(
                valueListenable: AppTranslations.notifier,
                builder: (context, _, _) => FilledButton(
                  onPressed: isAnyLoading ? null : _submit,
                  child: isEmailLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('auth.sign_in'.tr2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
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
              const SizedBox(height: 16),
              ValueListenableBuilder<int>(
                valueListenable: AppTranslations.notifier,
                builder: (context, _, _) => GoogleSignInButton(
                  loading: isGoogleLoading,
                  onPressed: isAnyLoading
                      ? null
                      : () => _googleWithPick(),
                ),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<int>(
                valueListenable: AppTranslations.notifier,
                builder: (context, _, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${'auth.new_here'.tr2} ',
                      style: const TextStyle(fontSize: 13, color: AppColors.inkFaded),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      ),
                      child: Text(
                        'auth.create_account_free'.tr2,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
