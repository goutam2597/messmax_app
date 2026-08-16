import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Animated pill-shaped page indicator dots (active dot stretches to 20px).
class DotIndicatorRow extends StatelessWidget {
  final int count;
  final int activeIndex;
  final Color activeColor;
  final Color inactiveColor;
  final bool light;

  const DotIndicatorRow({
    super.key,
    required this.count,
    required this.activeIndex,
    this.activeColor = AppColors.brandDark,
    this.inactiveColor = AppColors.paperLine,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: activeIndex == i ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: activeIndex == i
                  ? (light ? Colors.white : activeColor)
                  : (light ? Colors.white.withValues(alpha: 0.4) : inactiveColor),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
