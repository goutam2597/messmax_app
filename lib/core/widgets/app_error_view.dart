import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable, animated error view.
///
/// Always shows a friendly message plus a stable error code chip
/// (e.g. ERR-NET-1001) so users/support can reference the exact failure,
/// with a retry action when [onRetry] is provided.
class AppErrorView extends StatefulWidget {
  final String code;
  final String title;
  final String? message;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final IconData icon;

  const AppErrorView({
    super.key,
    this.code = 'ERR-NET-0000',
    required this.title,
    this.message,
    this.retryLabel,
    this.onRetry,
    this.icon = Icons.cloud_off_rounded,
  });

  @override
  State<AppErrorView> createState() => _AppErrorViewState();
}

class _AppErrorViewState extends State<AppErrorView>
    with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  /// Forward-only looping controller: ripple rings expand continuously with
  /// no reversal jump, and the icon bobs on a smooth sine wave.
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void initState() {
    super.initState();
    _entrance.forward();
    _entrance.addStatusListener(_onEntranceDone);
  }

  void _onEntranceDone(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      _loop.repeat();
      _entrance.removeStatusListener(_onEntranceDone);
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _loop.dispose();
    super.dispose();
  }

  /// Staggered fade + slide-in for a child, starting at [start] (0..1) of the
  /// entrance timeline and taking 30% of its duration.
  Widget _stagger(double start, Widget child) {
    final anim = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, math.min(start + 0.3, 1.0),
          curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.18),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AnimatedErrorIcon(
              entrance: _entrance,
              loop: _loop,
              icon: widget.icon,
            ),

            const SizedBox(height: 24),
            _stagger(
              0.15,
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),

            const SizedBox(height: 8),
            if (widget.message != null) ...[
              _stagger(
                0.25,
                Text(
                  widget.message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: AppColors.inkFaded,
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            _stagger(0.35, _ErrorCodeChip(code: widget.code)),

            if (widget.onRetry != null) ...[
              const SizedBox(height: 22),
              _stagger(
                0.45,
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 26,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: widget.onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(widget.retryLabel ?? 'Try again'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Icon inside soft circle, with continuously expanding ripple rings behind
/// it and a gentle vertical bob once the entrance finishes.
class _AnimatedErrorIcon extends StatelessWidget {
  final AnimationController entrance;
  final AnimationController loop;
  final IconData icon;

  const _AnimatedErrorIcon({
    required this.entrance,
    required this.loop,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([entrance, loop]),
      builder: (context, _) {
        // Pop-in with slight overshoot, then settle at 1.0.
        final appear =
            Curves.easeOutBack.transform(entrance.value.clamp(0.0, 1.0));
        // Gentle bob: one full sine cycle per loop revolution.
        final bob = math.sin(loop.value * 2 * math.pi) * 3.5;
        // Soft breathing glow under the circle.
        final breathe = 0.10 + 0.05 * (0.5 - 0.5 * math.cos(loop.value * 2 * math.pi));

        return Transform.translate(
          offset: Offset(0, bob * appear),
          child: Transform.scale(
            scale: appear,
            child: Opacity(
              opacity: appear.clamp(0.0, 1.0),
              child: SizedBox(
                width: 170,
                height: 170,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Two ripple rings expanding outward, phase-shifted.
                    ...[0.0, 0.5].map(_rippleRing),
                    // Breathing halo.
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.danger.withValues(alpha: breathe),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.brandSoft,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 38,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _rippleRing(double phaseOffset) {
    final t = (loop.value + phaseOffset) % 1.0;
    final size = 96 + 64 * t;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.30 * (1 - t)),
          width: 2.0 - 1.4 * t,
        ),
      ),
    );
  }
}

class _ErrorCodeChip extends StatelessWidget {
  final String code;

  const _ErrorCodeChip({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.paperLine),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'CODE',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(width: 6),
          SelectableText(
            code,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}
