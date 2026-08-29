import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A polished, reusable animated circular progress ring.
///
/// * Indeterminate (`value == null`): a gradient arc with a solid head and a
///   softly fading tail orbits smoothly — no jitter, no hard edges.
/// * Determinate (`value` 0..1): the ring fills with an eased animation and
///   re-animates whenever the value changes.
///
/// Optionally hosts a [child] (percentage label, icon…) centered inside the
/// ring, and renders a whisper-soft glow under the arc when [glow] is on.
class AppCircularProgress extends StatefulWidget {
  const AppCircularProgress({
    super.key,
    this.value,
    this.size = 48,
    this.strokeWidth = 4,
    this.colors,
    this.trackColor,
    this.child,
    this.glow = true,
  });

  /// Completion 0..1. `null` shows an indeterminate orbiting arc.
  final double? value;

  /// Outer diameter of the ring.
  final double size;

  /// Thickness of the arc stroke.
  final double strokeWidth;

  /// Gradient applied along the arc (tail → head). Defaults to brand tones.
  final List<Color>? colors;

  /// Full-circle track behind the arc.
  final Color? trackColor;

  /// Widget drawn in the middle of the ring (e.g. `Text('64%')`).
  final Widget? child;

  /// Whether to render a soft glow beneath the arc.
  final bool glow;

  @override
  State<AppCircularProgress> createState() => _AppCircularProgressState();
}

class _AppCircularProgressState extends State<AppCircularProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1150),
  );

  late final CurvedAnimation _ease = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  Tween<double>? _fillTween;
  double _shownValue = 0;
  bool get _isDeterminate => widget.value != null;

  static const List<Color> _defaultColors = [
    AppColors.brandDark,
    AppColors.brand,
    Color(0xFFFF8A65),
  ];

  @override
  void initState() {
    super.initState();
    if (_isDeterminate) {
      _shownValue = widget.value!.clamp(0.0, 1.0);
      _fillTween = Tween(begin: 0, end: _shownValue);
      _controller.forward();
    } else {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AppCircularProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDeterminate) {
      if (oldWidget.value != null || !_controller.isAnimating) {
        _controller.repeat();
      }
      return;
    }
    if (widget.value != oldWidget.value) {
      // Animate from wherever the ring currently is to the new target.
      _fillTween = Tween(begin: _shownValue, end: widget.value!.clamp(0, 1));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ease.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = Size.square(widget.size);
    return SizedBox(
      width: size.width,
      height: size.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_isDeterminate) {
            _shownValue =
                _fillTween?.transform(_ease.value) ?? widget.value!.clamp(0, 1);
          } else {
            _shownValue = 0;
          }
          return CustomPaint(
            size: size,
            painter: _RingPainter(
              isDeterminate: _isDeterminate,
              progress: _shownValue,
              phase: _controller.value,
              colors: widget.colors ?? _defaultColors,
              trackColor: widget.trackColor ?? AppColors.paperLine,
              strokeWidth: widget.strokeWidth,
              glow: widget.glow,
            ),
            child: widget.child == null ? null : Center(child: widget.child!),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.isDeterminate,
    required this.progress,
    required this.phase,
    required this.colors,
    required this.trackColor,
    required this.strokeWidth,
    required this.glow,
  });

  final bool isDeterminate;
  final double progress;
  final double phase;
  final List<Color> colors;
  final Color trackColor;
  final double strokeWidth;
  final bool glow;

  static const double _startBase = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    if ((trackColor.a * 255.0).round() > 0) {
      final track = Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(center, radius, track);
    }

    final double start;
    final double sweep;
    if (isDeterminate) {
      start = _startBase;
      sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    } else {
      start = _startBase + phase * 2 * math.pi;
      sweep = math.pi * 0.72; // ~130° comet arc
    }
    if (sweep <= 0.0005) return;

    // Whisper-soft glow under the arc head.
    if (glow && strokeWidth >= 3) {
      final glowPaint = Paint()
        ..shader = _arcShader(rect, start, sweep, faded: true)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 1.9
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawArc(rect, start, sweep, false, glowPaint);
    }

    // Main arc — solid head fading into a transparent tail.
    final arcPaint = Paint()
      ..shader = _arcShader(rect, start, sweep)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep, false, arcPaint);
  }

  /// Sweep gradient pinned to the visible arc so colors run tail → head.
  Shader _arcShader(
    Rect rect,
    double start,
    double sweep, {
    bool faded = false,
  }) {
    final palette = colors.length < 2 ? [colors.first, colors.first] : colors;
    return SweepGradient(
      startAngle: 0,
      endAngle: sweep,
      colors: [
        palette.first.withValues(alpha: faded ? 0.05 : 0.15),
        for (var i = 1; i < palette.length - 1; i++)
          palette[i].withValues(alpha: faded ? 0.12 : 0.85),
        palette.last.withValues(alpha: faded ? 0.30 : 1.0),
      ],
      transform: GradientRotation(start),
    ).createShader(rect);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.phase != phase ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.glow != glow ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.isDeterminate != isDeterminate ||
      oldDelegate.colors != colors;
}
