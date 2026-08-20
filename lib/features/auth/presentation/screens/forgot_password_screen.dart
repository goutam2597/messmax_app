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

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
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
  void initState() {
    super.initState();
    _newPasswordController.addListener(_updateState);
    _confirmPasswordController.addListener(_updateState);
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _newPasswordController.removeListener(_updateState);
    _confirmPasswordController.removeListener(_updateState);
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
      Future.delayed(const Duration(milliseconds: 200), () {
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
          backgroundColor: const Color(0xFF1F6A39),
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
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: const AppBackButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          child: ValueListenableBuilder<int>(
            valueListenable: AppTranslations.notifier,
            builder: (context, _, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderHero(),
                  const SizedBox(height: 22),
                  _buildMainCard(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // --- TOP HERO HEADER CARD ---
  Widget _buildHeaderHero() {
    IconData iconData;
    Color iconColor;
    Color iconBg;
    String title;
    String stepTag;

    if (_step == 1) {
      iconData = Icons.mark_email_read_rounded;
      iconColor = AppColors.brandDark;
      iconBg = AppColors.brandSoft;
      title = 'auth.forgot_password_title'.tr2;
      stepTag = 'Step 1 of 3';
    } else if (_step == 2) {
      iconData = Icons.dialpad_rounded;
      iconColor = const Color(0xFFE85D04);
      iconBg = const Color(0xFFFFF3EB);
      title = 'auth.enter_otp'.tr2;
      stepTag = 'Step 2 of 3';
    } else {
      iconData = Icons.lock_reset_rounded;
      iconColor = const Color(0xFF1F6A39);
      iconBg = const Color(0xFFEFFAF1);
      title = 'auth.reset_password_btn'.tr2;
      stepTag = 'Step 3 of 3';
    }

    return Column(
      children: [
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: iconBg.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(iconData, size: 28, color: iconColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.paperLine.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              stepTag.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.inkSoft,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }

  // --- MAIN CARD ---
  Widget _buildMainCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        border: Border.all(color: AppColors.paperLine),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepProgressBar(),
          const SizedBox(height: 20),

          if (_errorMessage != null) ...[
            AuthErrorBanner(message: _errorMessage!),
            const SizedBox(height: 14),
          ],

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _step == 1
                ? _buildStep1Email()
                : (_step == 2 ? _buildStep2Otp() : _buildStep3Password()),
          ),
        ],
      ),
    );
  }

  // --- STEP PROGRESS BAR ---
  Widget _buildStepProgressBar() {
    double fillPercent = _step / 3.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _stepHeaderItem(
              stepNum: 1,
              label: '1. Email',
              isActive: _step >= 1,
              isCurrent: _step == 1,
            ),
            _stepHeaderItem(
              stepNum: 2,
              label: '2. Code',
              isActive: _step >= 2,
              isCurrent: _step == 2,
            ),
            _stepHeaderItem(
              stepNum: 3,
              label: '3. Password',
              isActive: _step >= 3,
              isCurrent: _step == 3,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.paperLine,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: fillPercent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                height: 4,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.brandDark, Color(0xFFE85D04)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stepHeaderItem({
    required int stepNum,
    required String label,
    required bool isActive,
    required bool isCurrent,
  }) {
    Color textColor = AppColors.inkFaded;
    FontWeight fontW = FontWeight.w600;

    if (isCurrent) {
      textColor = AppColors.brandDark;
      fontW = FontWeight.w900;
    } else if (isActive) {
      textColor = AppColors.ink;
      fontW = FontWeight.w700;
    }

    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: isActive ? AppColors.brandDark : AppColors.paperLine,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isActive && !isCurrent
                ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                : Text(
                    '$stepNum',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : AppColors.inkSoft,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: fontW,
            color: textColor,
          ),
        ),
      ],
    );
  }

  // --- STEP 1: EMAIL INPUT FORM ---
  Widget _buildStep1Email() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'auth.enter_email_desc'.tr2,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.inkFaded,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 16),

        FieldLabel('auth.email'.tr2),
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          decoration: InputDecoration(
            hintText: 'you@example.com',
            prefixIcon: const Icon(
              Icons.email_outlined,
              size: 20,
              color: AppColors.inkFaded,
            ),
            suffixIcon: _emailController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.cancel_rounded,
                      size: 18,
                      color: AppColors.inkFaded,
                    ),
                    onPressed: () {
                      _emailController.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),

        // Info Tip Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.brandSoft.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.brandDark.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppColors.brandDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'auth.instant_email_otp_sub'.tr2,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: _isLoading ? null : _sendOtp,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'auth.send_otp'.tr2,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // --- STEP 2: 6-DIGIT OTP VERIFICATION ---
  Widget _buildStep2Otp() {
    final emailText = _emailController.text.trim();

    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Target Email Chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.brandSoft.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.brandDark.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.mark_email_read_rounded,
                size: 18,
                color: AppColors.brandDark,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verification code sent to',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.inkFaded,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      emailText,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                        color: AppColors.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => setState(() => _step = 1),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.edit_rounded,
                        size: 13,
                        color: AppColors.brandDark,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'auth.change'.tr2,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
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
        const SizedBox(height: 18),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FieldLabel('auth.enter_otp'.tr2),
            Text(
              '${_fullOtp.length} / 6 digits',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: _fullOtp.length == 6
                    ? const Color(0xFF1F6A39)
                    : AppColors.inkFaded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Symmetrical 3-box + Dot + 3-box Grid
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: List.generate(3, (index) => _pinBox(index)),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: AppColors.brandDark.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
            ),
            Row(
              children: List.generate(3, (index) => _pinBox(index + 3)),
            ),
          ],
        ),
        const SizedBox(height: 22),

        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: (_fullOtp.length < 6 || _isLoading) ? null : _verifyOtp,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'auth.verify_otp_code'.tr2,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 18),
        const Divider(color: AppColors.paperLine),
        const SizedBox(height: 12),

        // Resend Timer Row
        Center(
          child: _secondsLeft > 0
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${'auth.didnt_receive_otp'.tr2} Resend in ',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkFaded,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paperLine,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_secondsLeft}s',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkFaded,
                      ),
                    ),
                    InkWell(
                      onTap: _isLoading ? null : _sendOtp,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.refresh_rounded,
                              size: 15,
                              color: AppColors.brandDark,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'auth.resend_otp'.tr2,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
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

  // Pin Box Widget with Auto-Advance & Backspace handling
  Widget _pinBox(int index) {
    final hasVal = _otpControllers[index].text.isNotEmpty;
    final isFocused = _otpFocusNodes[index].hasFocus;

    return Container(
      width: 44,
      height: 52,
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
            fontSize: 22,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            color: hasVal ? AppColors.brandDark : AppColors.ink,
          ),
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            fillColor: hasVal
                ? const Color(0xFFFFF3EB)
                : (isFocused ? Colors.white : AppColors.paper),
            filled: true,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: hasVal ? const Color(0xFFF6CFAA) : AppColors.paperLine,
                width: hasVal ? 1.5 : 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.brandDark,
                width: 2.0,
              ),
            ),
          ),
          onChanged: (val) {
            setState(() {});
            if (val.isNotEmpty) {
              if (index < 5) {
                _otpFocusNodes[index + 1].requestFocus();
              } else {
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

  // --- STEP 3: CREATE NEW PASSWORD ---
  Widget _buildStep3Password() {
    final passText = _newPasswordController.text;
    final confirmText = _confirmPasswordController.text;
    final isMin6 = passText.length >= 6;
    final isMatch = passText.isNotEmpty && passText == confirmText;

    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // OTP Verified Success Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFEFFAF1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBCE7C7)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: Color(0xFF1F6A39),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _emailController.text.trim(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                        color: Color(0xFF1F6A39),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'OTP identity verified successfully',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E8B57),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        FieldLabel('auth.new_password'.tr2),
        const SizedBox(height: 6),
        TextField(
          controller: _newPasswordController,
          obscureText: _obscureNew,
          autofocus: true,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
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

        FieldLabel('auth.confirm_password'.tr2),
        const SizedBox(height: 6),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          onSubmitted: (_) => _resetPassword(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
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
        const SizedBox(height: 16),

        // Live Password Validation Checklist
        Row(
          children: [
            _validationChip(
              label: 'At least 6 chars',
              isValid: isMin6,
            ),
            const SizedBox(width: 8),
            _validationChip(
              label: 'Passwords match',
              isValid: isMatch,
            ),
          ],
        ),
        const SizedBox(height: 22),

        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: (_isLoading || !isMin6 || !isMatch)
                ? null
                : _resetPassword,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'auth.save_and_reset_password'.tr2,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.check_rounded, size: 18),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _validationChip({required String label, required bool isValid}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isValid
            ? const Color(0xFFEFFAF1)
            : AppColors.paperLine.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isValid ? const Color(0xFFBCE7C7) : AppColors.paperLine,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isValid ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 13,
            color: isValid ? const Color(0xFF1F6A39) : AppColors.inkFaded,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isValid ? const Color(0xFF1F6A39) : AppColors.inkFaded,
            ),
          ),
        ],
      ),
    );
  }
}
