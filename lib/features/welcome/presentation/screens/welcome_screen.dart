import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../auth/presentation/screens/register_screen.dart';
import '../../../main/presentation/screens/main_shell_screen.dart';

/// Marketing / landing screen — the first thing after splash.
///
/// Fully light-themed: no dark hero band, just a soft paper/brand gradient
/// backdrop behind a floating logo medallion with six feature icons
/// orbiting it, flowing straight into the copy, feature chips and actions.
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

  // endless slow rotation for the orbiting feature icons
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
          // soft ambient glow blobs, echoing the splash screen — light only.
          const Positioned(
            top: -60,
            right: -50,
            child: _GlowBlob(size: 220, color: AppColors.brandSoft),
          ),
          const Positioned(
            top: 140,
            left: -70,
            child: _GlowBlob(size: 180, color: AppColors.brandSoft),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
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
                        const SizedBox(height: 22),
                        FadeTransition(
                          opacity: _textFade,
                          child: SlideTransition(
                            position: _textSlide,
                            child: const Text(
                              AppStrings.welcomeTitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                height: 1.15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                                letterSpacing: -0.6,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FadeTransition(
                          opacity: _textFade,
                          child: SlideTransition(
                            position: _textSlide,
                            child: const Text(
                              AppStrings.welcomeSubtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.5,
                                height: 1.5,
                                color: AppColors.inkFaded,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeTransition(
                          opacity: _chipsFade,
                          child: const _FeatureChips(),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                // Actions are pinned above the safe-area inset, never
                // flush against the very bottom edge or the system nav bar.
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
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
                            _PrimaryActionButton(
                              icon: Icons.travel_explore_rounded,
                              label: AppStrings.findMesses,
                              onPressed: _onFindMesses,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _onCreateMess,
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                              ),
                              label: Text(AppStrings.createMess),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.ink,
                                side: const BorderSide(
                                  color: AppColors.paperLine,
                                  width: 1.4,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
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
        builder: (_) => const MainShellScreen(initialTab: 1),
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

/// Central brand medallion with six feature icons slowly orbiting it.
class _OrbitingHero extends StatelessWidget {
  const _OrbitingHero({required this.controller});

  final AnimationController controller;

  static const _orbitIcons = [
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
      width: 260,
      height: 260,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // faint outer ring
              Container(
                width: 236,
                height: 236,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.brand.withValues(alpha: 0.16),
                    width: 1.2,
                  ),
                ),
              ),
              // dashed-look inner tick ring
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.brand.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              // orbiting icons
              for (var i = 0; i < _orbitIcons.length; i++) _orbitIcon(i),
              // brand medallion
              Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.brand, AppColors.brandDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.38),
                      blurRadius: 36,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: Colors.white,
                  size: 50,
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
    const radius = 118.0;
    final dx = radius * math.cos(angle);
    final dy = radius * math.sin(angle);
    final (icon, _) = _orbitIcons[index];
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.paperLine),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.brandDark, size: 18),
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
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
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

  static const _items = [
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.paperLine),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
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
                    fontSize: 12.5,
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
          const Text(
            '${AppStrings.alreadyHaveAccount} ',
            style: TextStyle(fontSize: 13.5, color: AppColors.inkFaded),
          ),
          GestureDetector(
            onTap: onTap,
            child: const Text(
              AppStrings.login,
              style: TextStyle(
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
