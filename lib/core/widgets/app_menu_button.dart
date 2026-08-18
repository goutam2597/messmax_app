import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable circular rounded menu/hamburger button matching the design system
/// (36x36 circular container with paper border, ink menu icon, and ripple effect).
class AppMenuButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final Color? iconColor;
  final double size;
  final double iconSize;

  const AppMenuButton({
    super.key,
    this.onPressed,
    this.color,
    this.iconColor,
    this.size = 36,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed ?? () => Scaffold.of(context).openDrawer(),
          borderRadius: BorderRadius.circular(size / 2),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color ?? AppColors.paper,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.paperLine),
            ),
            child: Center(
              child: Icon(
                Icons.menu_rounded,
                color: iconColor ?? AppColors.ink,
                size: iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
