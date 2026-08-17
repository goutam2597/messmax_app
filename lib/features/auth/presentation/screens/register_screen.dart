import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
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
  String _accountType = 'hostel_owner';
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
        const SnackBar(content: Text('Please enter your full name')),
      );
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }
    setState(() => _step = 2);
  }

  void _submit() {
    if (_pass.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }
    if (_pass.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
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

  void _googleWithPick() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.g_mobiledata_rounded, color: AppColors.brandDark, size: 24),
            ),
            const SizedBox(width: 10),
            const Text(
              'Google Sign In',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select account type for your new profile:',
              style: TextStyle(fontSize: 13, color: AppColors.inkFaded),
            ),
            const SizedBox(height: 14),
            StatefulBuilder(
              builder: (context, setDialogState) => Row(
                children: [
                  Expanded(
                    child: AccountTypeTile(
                      title: 'Hostel Owner',
                      subtitle: 'Multi mess',
                      icon: Icons.business_rounded,
                      selected: _accountType == 'hostel_owner',
                      onTap: () {
                        setState(() => _accountType = 'hostel_owner');
                        setDialogState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AccountTypeTile(
                      title: 'Individual',
                      subtitle: 'Single mess',
                      icon: Icons.person_rounded,
                      selected: _accountType == 'individual',
                      onTap: () {
                        setState(() => _accountType = 'individual');
                        setDialogState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.inkFaded)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.brandDark),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    context.read<AuthCubit>().loginWithGoogle(accountType: _accountType);
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
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
              (_) => false,
            );
          }
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppAuthHeader(
                  title: 'Create Account',
                  subtitle: 'One account, unlimited mess management',
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
    return Container(
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
              _stepBadge(1, 'Account Setup', _step >= 1, _step == 1),
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
              _stepBadge(2, 'Security', _step >= 2, _step == 2),
            ],
          ),
        ],
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
        final isEmailLoading = state is AuthLoading && (state.type == AuthLoadingType.email || state.type == AuthLoadingType.general);
        final isGoogleLoading = state is AuthLoading && state.type == AuthLoadingType.google;
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
                const FieldLabel('Full Name'),
                const SizedBox(height: 6),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Goutam Sharma',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20, color: AppColors.inkFaded),
                  ),
                ),
                const SizedBox(height: 14),
                const FieldLabel('Email Address'),
                const SizedBox(height: 6),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'you@example.com',
                    prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppColors.inkFaded),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: const [
                    Text(
                      'ACCOUNT TYPE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    Text(
                      ' *',
                      style: TextStyle(color: AppColors.brandDark, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: AccountTypeTile(
                        title: 'Hostel Owner',
                        subtitle: 'Multi-mess owner',
                        icon: Icons.business_rounded,
                        selected: _accountType == 'hostel_owner',
                        onTap: () => setState(() => _accountType = 'hostel_owner'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AccountTypeTile(
                        title: 'Individual',
                        subtitle: 'Single mess member',
                        icon: Icons.person_rounded,
                        selected: _accountType == 'individual',
                        onTap: () => setState(() => _accountType = 'individual'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: isAnyLoading ? null : _toStep2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text('Continue to Security'),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: const [
                    Expanded(child: Divider(color: AppColors.paperLine)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: AppColors.inkFaded,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.paperLine)),
                  ],
                ),
                const SizedBox(height: 16),
                GoogleSignInButton(
                  loading: isGoogleLoading,
                  onPressed: isAnyLoading ? null : () => _googleWithPick(),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? ', style: TextStyle(fontSize: 13, color: AppColors.inkFaded)),
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const Text(
                        'Sign in',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandDark,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.paperLine),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => setState(() => _step = 1),
                        icon: const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.ink),
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _name.text.trim(),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _email.text.trim(),
                              style: const TextStyle(fontSize: 11.5, color: AppColors.inkFaded),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.brandSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _accountType == 'hostel_owner' ? 'OWNER' : 'INDIVIDUAL',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.brandDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const FieldLabel('Password'),
                const SizedBox(height: 6),
                TextField(
                  controller: _pass,
                  obscureText: _obscure1,
                  decoration: InputDecoration(
                    hintText: 'At least 6 characters',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.inkFaded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure1 ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: AppColors.inkFaded),
                      onPressed: () => setState(() => _obscure1 = !_obscure1),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const FieldLabel('Confirm Password'),
                const SizedBox(height: 6),
                TextField(
                  controller: _confirm,
                  obscureText: _obscure2,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'Repeat password',
                    prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20, color: AppColors.inkFaded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure2 ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: AppColors.inkFaded),
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: isAnyLoading ? null : _submit,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.brandDark),
                  child: isEmailLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.check_circle_outline_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Create Account'),
                          ],
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
