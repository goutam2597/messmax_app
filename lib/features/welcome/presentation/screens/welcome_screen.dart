import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/locale/app_translations.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../auth/presentation/screens/register_screen.dart';
import '../../../main/presentation/screens/main_shell_screen.dart';

/// Marketing / landing screen — the first thing after splash.
///
/// Fully light-themed: soft paper/brand gradient backdrop behind a floating
/// official logo emblem with six feature icons orbiting it, flowing into
/// the official wordmark, value proposition, feature chips and actions.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _heroFade;
  late final Animation<double> _heroScale;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _chipsFade;
  late final Animation<double> _actionsFade;
  late final Animation<Offset> _actionsSlide;

  // Endless slow rotation for the orbiting feature icons
  late final AnimationController _orbitController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();

    _heroFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.5, curve: Curves.easeOut),
    );
    _heroScale = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.8, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _chipsFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
    );
    _actionsFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1, curve: Curves.easeOut),
    );
    _actionsSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          // Soft ambient warm glow blobs
          const Positioned(
            top: -60,
            right: -50,
            child: _GlowBlob(size: 240, color: AppColors.brandSoft),
          ),
          const Positioned(
            top: 160,
            left: -70,
            child: _GlowBlob(size: 200, color: AppColors.brandSoft),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        // Orbiting Hero with official emblem
                        Center(
                          child: FadeTransition(
                            opacity: _heroFade,
                            child: ScaleTransition(
                              scale: _heroScale,
                              child: _OrbitingHero(
                                controller: _orbitController,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Official Logo Wordmark & Headline
                        FadeTransition(
                          opacity: _textFade,
                          child: SlideTransition(
                            position: _textSlide,
                            child: Column(
                              children: [
                                SvgPicture.asset(
                                  'assets/images/logo.svg',
                                  height: 38,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.brand.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.brand.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                  ),
                                  child: ValueListenableBuilder<int>(
                                    valueListenable: AppTranslations.notifier,
                                    builder: (context, _, _) => Text(
                                      'ui.welcome_network'.tr2,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.6,
                                        color: AppColors.brandDark,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                ValueListenableBuilder<int>(
                                  valueListenable: AppTranslations.notifier,
                                  builder: (context, _, _) => Text(
                                    'ui.welcome_title'.tr2,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      height: 1.25,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ValueListenableBuilder<int>(
                                  valueListenable: AppTranslations.notifier,
                                  builder: (context, _, _) => Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'ui.welcome_subtitle'.tr2,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        height: 1.45,
                                        color: AppColors.inkFaded,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Feature Pills
                        FadeTransition(
                          opacity: _chipsFade,
                          child: const _FeatureChips(),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.paper.withValues(alpha: 0),
                          AppColors.paper,
                        ],
                      ),
                    ),
                    child: FadeTransition(
                      opacity: _actionsFade,
                      child: SlideTransition(
                        position: _actionsSlide,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ValueListenableBuilder<int>(
                              valueListenable: AppTranslations.notifier,
                              builder: (context, _, _) => _PrimaryActionButton(
                                icon: Icons.travel_explore_rounded,
                                label: AppStrings.findMesses,
                                onPressed: _onFindMesses,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ValueListenableBuilder<int>(
                              valueListenable: AppTranslations.notifier,
                              builder: (context, _, _) => OutlinedButton.icon(
                                onPressed: _onCreateMess,
                                icon: const Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 18,
                                ),
                                label: Text(AppStrings.createMess),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.ink,
                                  side: const BorderSide(
                                    color: AppColors.paperLine,
                                    width: 1.4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _LoginLink(onTap: _onLogin),
                          ],
                        ),
                      ),
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

  void _onFindMesses() {
    AppLogger.d('Welcome: Find messes tapped');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MainShellScreen(initialTab: 0),
      ),
    );
  }

  void _onCreateMess() {
    AppLogger.d('Welcome: Create mess tapped');
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _onLogin() {
    AppLogger.d('Welcome: Login tapped');
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
}

/// Soft, blurred, translucent circle used purely as ambient decoration.
class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

/// Central brand medallion with official emblem and six feature icons slowly orbiting it.
class _OrbitingHero extends StatelessWidget {
  const _OrbitingHero({required this.controller});

  final AnimationController controller;

  static final _orbitIcons = [
    (Icons.rice_bowl_rounded, AppStrings.featureMealCount),
    (Icons.shopping_basket_rounded, AppStrings.featureBazarLedger),
    (Icons.savings_rounded, AppStrings.featureDeposits),
    (Icons.campaign_rounded, AppStrings.featurePostMessAds),
    (Icons.travel_explore_rounded, AppStrings.featureFindMess),
    (Icons.insights_rounded, AppStrings.featureSmartReports),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 250,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Faint outer ring
              Container(
                width: 228,
                height: 228,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.brand.withValues(alpha: 0.16),
                    width: 1.2,
                  ),
                ),
              ),
              // Inner orbit guide ring
              Container(
                width: 196,
                height: 196,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.brand.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              // Soft ambient glow behind emblem
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.brand.withValues(alpha: 0.18),
                      AppColors.brand.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              // Orbiting icons
              for (var i = 0; i < _orbitIcons.length; i++) _orbitIcon(i),
              // Official Emblem Card
              Container(
                width: 104,
                height: 104,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.brand.withValues(alpha: 0.22),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandDark.withValues(alpha: 0.14),
                      blurRadius: 32,
                      spreadRadius: 2,
                      offset: const Offset(0, 10),
                    ),
                    const BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SvgPicture.asset(
                    'assets/images/mm_fav.svg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _orbitIcon(int index) {
    final baseAngle = (index / _orbitIcons.length) * 2 * math.pi;
    final angle = baseAngle + controller.value * 2 * math.pi;
    const radius = 114.0;
    final dx = radius * math.cos(angle);
    final dy = radius * math.sin(angle);
    final (icon, _) = _orbitIcons[index];
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE4E4DF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.brandDark, size: 17),
      ),
    );
  }
}

/// Gradient-filled primary CTA button with brand glow shadow.
class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand, AppColors.brandDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.38),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Six value props in a wrap — meals, bazar, deposits, ads, find mess, reports.
class _FeatureChips extends StatelessWidget {
  const _FeatureChips();

  static final _items = [
    (Icons.rice_bowl_rounded, AppStrings.featureMealCount),
    (Icons.shopping_basket_rounded, AppStrings.featureBazarLedger),
    (Icons.savings_rounded, AppStrings.featureDeposits),
    (Icons.campaign_rounded, AppStrings.featurePostMessAds),
    (Icons.travel_explore_rounded, AppStrings.featureFindMess),
    (Icons.insights_rounded, AppStrings.featureSmartReports),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (icon, label) in _items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE5E5DF)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: AppColors.brandDark),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// "Already have a mess? Log in" inline link.
class _LoginLink extends StatelessWidget {
  const _LoginLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '${AppStrings.alreadyHaveAccount} ',
            style: const TextStyle(fontSize: 13.5, color: AppColors.inkFaded),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              AppStrings.login,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColors.brandDark,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
