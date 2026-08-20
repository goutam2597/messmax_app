import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/locale/app_translations.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../auth/presentation/screens/register_screen.dart';
import '../../../main/presentation/screens/main_shell_screen.dart';

/// Premier Marketing / Welcome Screen — modern, elegant, and beautifully aligned.
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
  late final Animation<double> _cardsFade;
  late final Animation<double> _actionsFade;
  late final Animation<Offset> _actionsSlide;

  late final AnimationController _orbitController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();

    _heroFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.5, curve: Curves.easeOut),
    );
    _heroScale = Tween<double>(begin: 0.75, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.75, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.3, 0.75, curve: Curves.easeOutCubic),
          ),
        );
    _cardsFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
    );
    _actionsFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1, curve: Curves.easeOut),
    );
    _actionsSlide =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
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
          // Soft ambient background glow blobs
          const Positioned(
            top: -40,
            right: -40,
            child: _GlowBlob(size: 260, color: AppColors.brandSoft),
          ),
          const Positioned(
            top: 220,
            left: -60,
            child: _GlowBlob(size: 220, color: AppColors.brandSoft),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- TOP HERO ANIMATION FIRST, THEN LOGO ---
                        Column(
                          children: [
                            const SizedBox(height: 12),
                            // 1. Circle Orbiting Animation First
                            FadeTransition(
                              opacity: _heroFade,
                              child: ScaleTransition(
                                scale: _heroScale,
                                child: _OrbitingHero(
                                  controller: _orbitController,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // 2. Logo Wordmark under Animation
                            SvgPicture.asset(
                              'assets/images/logo.svg',
                              height: 36,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),

                        // --- HEADLINE & SUBTITLE ---
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: FadeTransition(
                            opacity: _textFade,
                            child: SlideTransition(
                              position: _textSlide,
                              child: Column(
                                children: [
                                  ValueListenableBuilder<int>(
                                    valueListenable: AppTranslations.notifier,
                                    builder: (context, _, _) => Text(
                                      'ui.welcome_title'.tr2,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 23,
                                        height: 1.25,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.ink,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ValueListenableBuilder<int>(
                                    valueListenable: AppTranslations.notifier,
                                    builder: (context, _, _) => Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      child: Text(
                                        'ui.welcome_subtitle'.tr2,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          height: 1.45,
                                          color: AppColors.inkFaded,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // --- 3 FEATURE HIGHLIGHT CARDS (EQUAL WIDTH & HEIGHT) ---
                        FadeTransition(
                          opacity: _cardsFade,
                          child: const _FeatureGrid(),
                        ),

                        // --- ACTION BUTTONS ---
                        Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 4),
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
                                      label: 'ui.welcome_find_messes'.tr2,
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
                                      label: Text('ui.welcome_create_mess'.tr2),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.ink,
                                        side: const BorderSide(
                                          color: AppColors.paperLine,
                                          width: 1.3,
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                      ],
                    ),
                  ),
                );
              },
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
      MaterialPageRoute(builder: (_) => const MainShellScreen(initialTab: 0)),
    );
  }

  void _onCreateMess() {
    AppLogger.d('Welcome: Create mess tapped');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  void _onLogin() {
    AppLogger.d('Welcome: Login tapped');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }
}

/// Ambient glow blob
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

/// Central Orbiting Hero Medallion (200x200)
class _OrbitingHero extends StatelessWidget {
  const _OrbitingHero({required this.controller});

  final AnimationController controller;

  static List<(IconData, String)> _orbitIcons(BuildContext context) => [
        (Icons.rice_bowl_rounded, 'ui.welcome_feature_meal'.tr2),
        (Icons.shopping_basket_rounded, 'ui.welcome_feature_bazar'.tr2),
        (Icons.savings_rounded, 'ui.welcome_feature_deposits'.tr2),
        (Icons.campaign_rounded, 'ui.welcome_feature_ads'.tr2),
        (Icons.travel_explore_rounded, 'ui.welcome_feature_find'.tr2),
        (Icons.insights_rounded, 'ui.welcome_feature_reports'.tr2),
      ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring
              Container(
                width: 182,
                height: 182,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.brand.withValues(alpha: 0.16),
                    width: 1.2,
                  ),
                ),
              ),
              // Inner guide ring
              Container(
                width: 156,
                height: 156,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.brand.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              // Glow
              Container(
                width: 110,
                height: 110,
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
              for (var i = 0; i < _orbitIcons(context).length; i++)
                _orbitIcon(context, i),
              // Central Emblem Card
              Container(
                width: 86,
                height: 86,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.brand.withValues(alpha: 0.22),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandDark.withValues(alpha: 0.14),
                      blurRadius: 24,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
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

  Widget _orbitIcon(BuildContext context, int index) {
    final baseAngle = (index / _orbitIcons(context).length) * 2 * math.pi;
    final angle = baseAngle + controller.value * 2 * math.pi;
    const radius = 90.0;
    final dx = radius * math.cos(angle);
    final dy = radius * math.sin(angle);
    final (icon, _) = _orbitIcons(context)[index];

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE4E4DF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.brandDark, size: 15),
      ),
    );
  }
}

/// 3 Feature Highlight Cards Grid (Equal Width & Height)
class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppTranslations.notifier,
      builder: (context, _, _) {
        final isBn = AppTranslations.locale == 'bn';

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _featureCard(
                  icon: Icons.rice_bowl_rounded,
                  title: 'auth.strip_meals'.tr2,
                  subtitle: isBn ? 'দৈনিক মিল হিসাব' : 'Daily meal count',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _featureCard(
                  icon: Icons.shopping_basket_rounded,
                  title: 'auth.strip_bazar'.tr2,
                  subtitle: isBn ? 'বাজার শিডিউল ও হিসাব' : 'Duty roster & logs',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _featureCard(
                  icon: Icons.travel_explore_rounded,
                  title: 'ui.welcome_find_messes'.tr2,
                  subtitle: isBn ? 'মেস সিট খোঁজা ও বুকিং' : 'Find & post seats',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(16),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppColors.brandDark),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              height: 1.3,
              color: AppColors.inkFaded,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Primary CTA Action Button
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
            color: AppColors.brand.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
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

/// Inline sign in link
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
            '${'ui.welcome_already_account'.tr2} ',
            style: const TextStyle(fontSize: 13, color: AppColors.inkFaded),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              'ui.welcome_login'.tr2,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.brandDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
