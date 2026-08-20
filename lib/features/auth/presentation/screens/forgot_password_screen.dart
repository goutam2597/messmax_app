import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/locale/app_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _authRepository = AuthRepository();

  int _step = 1; // 1: Email, 2: OTP, 3: Password
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Step 2 PIN input state
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  // Resend timer state
  Timer? _timer;
  int _secondsLeft = 60;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  String get _fullOtp =>
      _otpControllers.map((c) => c.text.trim()).join();

  void _clearOtpFields() {
    for (final c in _otpControllers) {
      c.clear();
    }
  }

  // --- Step 1: Send OTP ---
  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'auth.invalid_email'.tr2);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authRepository.sendForgotPasswordOtp(email);
      if (!mounted) return;
      _clearOtpFields();
      setState(() {
        _isLoading = false;
        _step = 2;
      });
      _startResendTimer();
      // Auto focus 1st PIN box
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && _otpFocusNodes[0].canRequestFocus) {
          _otpFocusNodes[0].requestFocus();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e is DioException
            ? (e.error?.toString() ?? e.message ?? 'Failed to send OTP code.')
            : e.toString();
      });
    }
  }

  // --- Step 2: Verify OTP ---
  Future<void> _verifyOtp() async {
    final email = _emailController.text.trim();
    final otp = _fullOtp;

    if (otp.length < 6) {
      setState(() => _errorMessage = 'auth.6_digit_otp'.tr2);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authRepository.verifyForgotPasswordOtp(email: email, otp: otp);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _step = 3;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e is DioException
            ? (e.error?.toString() ?? e.message ?? 'Invalid OTP code.')
            : e.toString();
      });
    }
  }

  // --- Step 3: Reset Password ---
  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final otp = _fullOtp;
    final pass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (pass.length < 6) {
      setState(() => _errorMessage = 'auth.password_too_short'.tr2);
      return;
    }
    if (pass != confirm) {
      setState(() => _errorMessage = 'auth.passwords_do_not_match'.tr2);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authRepository.resetPasswordWithOtp(
        email: email,
        otp: otp,
        password: pass,
        passwordConfirmation: confirm,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auth.password_reset_success'.tr2),
          backgroundColor: Colors.green[800],
        ),
      );
      Navigator.of(context).pop(); // Return to LoginScreen
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e is DioException
            ? (e.error?.toString() ?? e.message ?? 'Failed to reset password.')
            : e.toString();
      });
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
        leading: const AppBackButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: ValueListenableBuilder<int>(
            valueListenable: AppTranslations.notifier,
            builder: (context, _, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppAuthHeader(
                    title: 'auth.forgot_password_title'.tr2,
                    subtitle: 'auth.security_recovery'.tr2,
                  ),
                  const SizedBox(height: 20),
                  _buildCard(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
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
          _buildWizardHeader(),
          const SizedBox(height: 18),
          if (_errorMessage != null) ...[
            AuthErrorBanner(message: _errorMessage!),
            const SizedBox(height: 14),
          ],
          if (_step == 1) ...[
            _buildStep1Email(),
          ] else if (_step == 2) ...[
            _buildStep2Otp(),
          ] else ...[
            _buildStep3Password(),
          ],
        ],
      ),
    );
  }

  // --- Wizard Step Header Indicator ---
  Widget _buildWizardHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.paperLine)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _stepBadge(
              stepNumber: 1,
              title: '1. Email',
              isCurrent: _step == 1,
              isCompleted: _step > 1,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _stepBadge(
              stepNumber: 2,
              title: '2. OTP',
              isCurrent: _step == 2,
              isCompleted: _step > 2,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _stepBadge(
              stepNumber: 3,
              title: '3. Password',
              isCurrent: _step == 3,
              isCompleted: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBadge({
    required int stepNumber,
    required String title,
    required bool isCurrent,
    required bool isCompleted,
  }) {
    Color bg = AppColors.paperLine.withValues(alpha: 0.4);
    Color border = AppColors.paperLine;
    Color textColor = AppColors.inkFaded;
    Widget icon = CircleAvatar(
      radius: 8,
      backgroundColor: AppColors.inkFaded.withValues(alpha: 0.2),
      child: Text(
        '$stepNumber',
        style: const TextStyle(fontSize: 9, color: AppColors.ink, fontWeight: FontWeight.bold),
      ),
    );

    if (isCompleted) {
      bg = const Color(0xFFEFFAF1);
      border = const Color(0xFFBCE7C7);
      textColor = const Color(0xFF1F6A39);
      icon = const CircleAvatar(
        radius: 8,
        backgroundColor: Color(0xFF1F6A39),
        child: Icon(Icons.check, size: 10, color: Colors.white),
      );
    } else if (isCurrent) {
      bg = const Color(0xFFFDF6EE);
      border = const Color(0xFFF6CFAA);
      textColor = AppColors.brandDark;
      icon = CircleAvatar(
        radius: 8,
        backgroundColor: AppColors.brandDark,
        child: Text(
          '$stepNumber',
          style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 1: Email Form ---
  Widget _buildStep1Email() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'auth.enter_email_desc'.tr2,
          style: const TextStyle(fontSize: 12.5, color: AppColors.inkFaded, height: 1.4),
        ),
        const SizedBox(height: 14),
        FieldLabel('auth.email'.tr2),
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'you@example.com',
            prefixIcon: const Icon(
              Icons.email_outlined,
              size: 20,
              color: AppColors.inkFaded,
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _isLoading ? null : _sendOtp,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('auth.send_otp'.tr2),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
        ),
      ],
    );
  }

  // --- Step 2: 6-Digit Box PinInput View ---
  Widget _buildStep2Otp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.paperLine.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.paperLine),
          ),
          child: Row(
            children: [
              const Icon(Icons.email_outlined, size: 16, color: AppColors.brandDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _emailController.text.trim(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    color: AppColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _step = 1),
                child: Text(
                  'auth.change'.tr2,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FieldLabel('auth.enter_otp'.tr2),
            Text(
              '${_fullOtp.length}/6 digits',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: _fullOtp.length == 6 ? const Color(0xFF1F6A39) : AppColors.inkFaded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Symmetrical 3 + Divider + 3 Pin Input Grid
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // First 3 Digits
            Row(
              children: List.generate(3, (index) => _pinBox(index)),
            ),

            // Centered Separator Dot
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.inkFaded,
                shape: BoxShape.circle,
              ),
            ),

            // Last 3 Digits
            Row(
              children: List.generate(3, (index) => _pinBox(index + 3)),
            ),
          ],
        ),

        const SizedBox(height: 20),
        FilledButton(
          onPressed: (_fullOtp.length < 6 || _isLoading) ? null : _verifyOtp,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('auth.verify_otp_code'.tr2),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
        ),

        const SizedBox(height: 16),
        const Divider(color: AppColors.paperLine),
        const SizedBox(height: 12),

        // Resend Timer (Hidden button until 0s)
        Center(
          child: _secondsLeft > 0
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${'auth.didnt_receive_otp'.tr2} Resend code in ',
                      style: const TextStyle(fontSize: 12, color: AppColors.inkFaded),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.paperLine,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_secondsLeft}s',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${'auth.didnt_receive_otp'.tr2} ',
                      style: const TextStyle(fontSize: 12, color: AppColors.inkFaded),
                    ),
                    InkWell(
                      onTap: _isLoading ? null : _sendOtp,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.refresh_rounded, size: 14, color: AppColors.brandDark),
                            const SizedBox(width: 4),
                            Text(
                              'auth.resend_otp'.tr2,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.brandDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // Custom 6-digit Box Widget with Auto-Advance & Backspace handling
  Widget _pinBox(int index) {
    final hasVal = _otpControllers[index].text.isNotEmpty;

    return Container(
      width: 42,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              _otpControllers[index].text.isEmpty &&
              index > 0) {
            _otpControllers[index - 1].clear();
            _otpFocusNodes[index - 1].requestFocus();
            setState(() {});
          }
        },
        child: TextField(
          controller: _otpControllers[index],
          focusNode: _otpFocusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: hasVal ? AppColors.brandDark : AppColors.ink,
          ),
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            fillColor: hasVal ? const Color(0xFFFDF6EE) : AppColors.paper,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasVal ? const Color(0xFFF6CFAA) : AppColors.paperLine,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasVal ? const Color(0xFFF6CFAA) : AppColors.paperLine,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.brandDark, width: 2),
            ),
          ),
          onChanged: (val) {
            setState(() {});
            if (val.isNotEmpty) {
              if (index < 5) {
                _otpFocusNodes[index + 1].requestFocus();
              } else {
                // Auto submit when 6th digit typed
                _otpFocusNodes[index].unfocus();
                if (_fullOtp.length == 6) {
                  _verifyOtp();
                }
              }
            }
          },
        ),
      ),
    );
  }

  // --- Step 3: Set Password View ---
  Widget _buildStep3Password() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEFFAF1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBCE7C7)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF1F6A39)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _emailController.text.trim(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    color: Color(0xFF1F6A39),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFBCE7C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'auth.otp_verified_title'.tr2.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F6A39),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FieldLabel('auth.new_password'.tr2),
        const SizedBox(height: 6),
        TextField(
          controller: _newPasswordController,
          obscureText: _obscureNew,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.inkFaded),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNew ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                size: 18,
                color: AppColors.inkFaded,
              ),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
        ),
        const SizedBox(height: 14),
        FieldLabel('auth.confirm_password'.tr2),
        const SizedBox(height: 6),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          onSubmitted: (_) => _resetPassword(),
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.inkFaded),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                size: 18,
                color: AppColors.inkFaded,
              ),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _isLoading ? null : _resetPassword,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('auth.save_and_reset_password'.tr2),
                    const SizedBox(width: 6),
                    const Icon(Icons.check_rounded, size: 18),
                  ],
                ),
        ),
      ],
    );
  }
}
