import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:messmax_app/features/welcome/presentation/screens/welcome_screen.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/locale/app_translations.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../cubit/splash_cubit.dart';
import '../cubit/splash_state.dart';

/// Animated brand splash in luminous light mode: drifting warm glow mesh,
/// orbiting feature icons, progress ring around the official logo emblem,
/// full logo wordmark fade-up, and gentle bottom waves.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _wordFade;
  late final Animation<Offset> _wordSlide;
  late final Animation<double> _ringFade;
  late final Animation<double> _progress;

  // Slow, endless ambience — orbit rotation + mesh drift + wave motion.
  late final AnimationController _ambientController;

  static const _orbitIcons = [
    Icons.rice_bowl_rounded,
    Icons.shopping_basket_rounded,
    Icons.savings_rounded,
    Icons.campaign_rounded,
    Icons.travel_explore_rounded,
    Icons.insights_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _ringFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.4, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _progress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.95, curve: Curves.easeOutCubic),
      ),
    );
    _wordFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.75, curve: Curves.easeOut),
      ),
    );
    _wordSlide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.4, 0.75, curve: Curves.easeOutCubic),
          ),
        );

    context.read<SplashCubit>().start();
  }

  @override
  void dispose() {
    _controller.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  void _onReady(BuildContext context, SplashDestination destination) {
    // Request native notification permission on app first install/open right as splash completes
    PushNotificationService.requestPermissionAndSync();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = destination == SplashDestination.dashboard
          ? const DashboardScreen()
          : const WelcomeScreen();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => target,
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 450),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final bool isThreeButtonNav = isAndroid && bottomInset >= 36;
    final double versionBottom = isThreeButtonNav ? (16.0 + bottomInset) : 34.0;
    final double dotsBottom = isThreeButtonNav ? (76.0 + bottomInset) : 96.0;

    return BlocListener<SplashCubit, SplashState>(
      listener: (context, state) {
        if (state is SplashReady) _onReady(context, state.destination);
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFAFAF7),
                Color(0xFFF2F2EC),
              ],
            ),
          ),
          child: Stack(
            children: [
              // drifting ambient warm glow mesh
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _ambientController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _MeshGlowPainter(_ambientController.value),
                    );
                  },
                ),
              ),

              // gentle animated wave hugging the bottom edge
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _ambientController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _WavePainter(_ambientController.value),
                    );
                  },
                ),
              ),

              // logo + orbit icons + progress ring + wordmark
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 216,
                      height: 216,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // orbiting feature icons
                          FadeTransition(
                            opacity: _ringFade,
                            child: AnimatedBuilder(
                              animation: _ambientController,
                              builder: (context, _) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    for (var i = 0; i < _orbitIcons.length; i++)
                                      _buildOrbitIcon(i),
                                  ],
                                );
                              },
                            ),
                          ),
                          // filling progress ring around the logo
                          FadeTransition(
                            opacity: _ringFade,
                            child: AnimatedBuilder(
                              animation: _progress,
                              builder: (context, _) {
                                return CustomPaint(
                                  size: const Size(156, 156),
                                  painter: _ProgressRingPainter(
                                    _progress.value,
                                  ),
                                );
                              },
                            ),
                          ),
                          // soft brand glow behind the logo
                          FadeTransition(
                            opacity: _wordFade,
                            child: Container(
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
                          ),
                          // Official Logo Emblem Card
                          FadeTransition(
                            opacity: _logoFade,
                            child: ScaleTransition(
                              scale: _logoScale,
                              child: Container(
                                width: 102,
                                height: 102,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(26),
                                  border: Border.all(
                                    color: AppColors.brand.withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.brandDark.withValues(
                                        alpha: 0.14,
                                      ),
                                      blurRadius: 36,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 10),
                                    ),
                                    const BoxShadow(
                                      color: Color(0x0A000000),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: SvgPicture.asset(
                                    'assets/images/mm_fav.svg',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeTransition(
                      opacity: _wordFade,
                      child: SlideTransition(
                        position: _wordSlide,
                        child: Column(
                          children: [
                            SvgPicture.asset(
                              'assets/images/logo.svg',
                              height: 34,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 12),
                            const _TaglineBadge(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // pulsing dots loader
              Positioned(
                bottom: dotsBottom,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _wordFade,
                  child: const _PulsingDots(),
                ),
              ),

              // version
              Positioned(
                bottom: versionBottom,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _wordFade,
                  child: const Text(
                    'v1.0.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.inkFaded,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrbitIcon(int index) {
    final baseAngle = (index / _orbitIcons.length) * 2 * math.pi;
    final angle = baseAngle + _ambientController.value * 2 * math.pi;
    const radius = 98.0;
    final dx = radius * math.cos(angle);
    final dy = radius * math.sin(angle);
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE4E4DF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Icon(_orbitIcons[index], color: AppColors.brandDark, size: 16),
      ),
    );
  }
}

/// Small pill badge that frames the tagline for a bit more polish.
class _TaglineBadge extends StatelessWidget {
  const _TaglineBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.brand.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ValueListenableBuilder<int>(
        valueListenable: AppTranslations.notifier,
        builder: (context, _, _) => Text(
          AppStrings.tagline,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.inkSoft,
            letterSpacing: 1.8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Paints two large, slowly drifting soft-glow warm blobs.
class _MeshGlowPainter extends CustomPainter {
  _MeshGlowPainter(this.t);

  /// 0..1 looping progress.
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final angle1 = t * 2 * math.pi;
    final angle2 = t * 2 * math.pi + math.pi;

    final center1 = Offset(
      size.width * 0.5 + math.cos(angle1) * size.width * 0.32,
      size.height * 0.32 + math.sin(angle1) * size.height * 0.14,
    );
    final center2 = Offset(
      size.width * 0.5 + math.cos(angle2) * size.width * 0.28,
      size.height * 0.72 + math.sin(angle2) * size.height * 0.12,
    );

    final paint1 = Paint()
      ..shader =
          RadialGradient(
            colors: [
              AppColors.brand.withValues(alpha: 0.08),
              AppColors.brand.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(center: center1, radius: size.width * 0.55),
          );
    final paint2 = Paint()
      ..shader =
          RadialGradient(
            colors: [
              AppColors.brandDark.withValues(alpha: 0.06),
              AppColors.brandDark.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(center: center2, radius: size.width * 0.5),
          );

    canvas.drawCircle(center1, size.width * 0.55, paint1);
    canvas.drawCircle(center2, size.width * 0.5, paint2);
  }

  @override
  bool shouldRepaint(covariant _MeshGlowPainter oldDelegate) =>
      oldDelegate.t != t;
}

/// Slim ring that fills clockwise as boot work progresses.
class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter(this.progress);

  /// 0..1 completion.
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    final track = Paint()
      ..color = const Color(0xFFE4E4DF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..color = AppColors.brand
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Soft, low-contrast rolling waves at the bottom of the screen.
class _WavePainter extends CustomPainter {
  _WavePainter(this.t);

  /// 0..1 looping progress.
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    _drawWave(
      canvas,
      size,
      phase: t * 2 * math.pi,
      amplitude: 12,
      baseHeight: size.height * 0.93,
      color: const Color(0x0C000000),
    );
    _drawWave(
      canvas,
      size,
      phase: t * 2 * math.pi + math.pi / 2,
      amplitude: 8,
      baseHeight: size.height * 0.96,
      color: const Color(0x08000000),
    );
  }

  void _drawWave(
    Canvas canvas,
    Size size, {
    required double phase,
    required double amplitude,
    required double baseHeight,
    required Color color,
  }) {
    final path = Path()..moveTo(0, baseHeight);
    const step = 12.0;
    for (var x = 0.0; x <= size.width; x += step) {
      final y =
          baseHeight +
          math.sin((x / size.width * 2 * math.pi) + phase) * amplitude;
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => oldDelegate.t != t;
}

/// Three dots that breathe in sequence while boot work runs.
class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = (_controller.value * 3 - index).clamp(0.0, 1.0);
            final pulse = (1 - (2 * t - 1).abs()).toDouble(); // 0→1→0
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 7 + 2 * pulse,
              height: 7 + 2 * pulse,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(
                  AppColors.brand.withValues(alpha: 0.25),
                  AppColors.brand,
                  pulse,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
