import 'package:flutter/material.dart';

/// Ruled paper + red double margin — mirrors the web ledger cover.
class LedgerCover extends StatelessWidget {
  final Widget child;
  final bool heroGrid;
  const LedgerCover({super.key, required this.child, this.heroGrid = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F0ED),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _RuledPainter())),
          // red double margin at 64 logical px (web: left-[64px])
          Positioned(
            left: 64,
            top: 0,
            bottom: 0,
            width: 4,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: const Color(0x7FC23030).withValues(alpha: 0.5), width: 1.5),
                  right: BorderSide(color: const Color(0x7FC23030).withValues(alpha: 0.5), width: 1),
                ),
              ),
            ),
          ),
          // two decorative circles top-right (web: -top-24 -right-24)
          Positioned(
            top: -96,
            right: -96,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFD1D1D1))),
            ),
          ),
          Positioned(
            top: -64,
            right: -64,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFD1D1D1).withValues(alpha: 0.7))),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _RuledPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x0F404040)
      ..strokeWidth = 1;
    for (double y = 36; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Dashed seam bottom border (web: border-bottom:2px dashed #c9c9c3)
class DashedSeam extends StatelessWidget {
  final Widget child;
  const DashedSeam({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedPainter(),
      child: child,
    );
  }
}

class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFC9C9C3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const dash = 8.0;
    const gap = 4.0;
    double x = 0;
    final y = size.height;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset((x + dash).clamp(0, size.width), y), p);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
