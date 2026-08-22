import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Dashboard UI kit — boxy professional design language mirroring the web console.
/// Buttons/pills: 4px radius. Cards/surfaces: 6–8px. Avatars/dots stay round.
abstract final class DashUI {
  // ---- Radii ----
  static const double rBtn = 4;
  static const double rCard = 8;
  static const double rTile = 6;

  // ---- Card decoration ----
  static BoxDecoration card({
    Color color = AppColors.paperRaised,
    Color borderColor = AppColors.paperLine,
    double radius = rCard,
    List<BoxShadow>? shadow,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      boxShadow: shadow,
    );
  }

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  // ---- Section header row (icon chip + uppercase label + optional action) ----
  static Widget sectionHeader(
    IconData icon,
    String title, {
    Color iconColor = AppColors.brandDark,
    String? actionLabel,
    VoidCallback? onActionTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(icon, size: 15, color: iconColor),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.inkFaded,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onActionTap != null)
          InkWell(
            onTap: onActionTap,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accentDark,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    color: AppColors.accentDark,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ---- Small status badge (boxy) ----
  static Widget badge({
    required String text,
    required Color background,
    required Color textColor,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(rBtn),
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ---- Boxy filled button ----
  static Widget button({
    required String label,
    required IconData icon,
    required Color background,
    required Color foreground,
    Color? sideColor,
    VoidCallback? onPressed,
    double height = 46,
    double fontSize = 12.5,
  }) {
    return SizedBox(
      height: height,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: fontSize),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(rBtn),
            side: sideColor != null
                ? BorderSide(color: sideColor)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ---- Boxy outlined button ----
  static Widget outlineButton({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
    double height = 46,
    double fontSize = 12.5,
  }) {
    return SizedBox(
      height: height,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17, color: color),
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: fontSize,
            color: color,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(rBtn),
          ),
        ),
      ),
    );
  }
}
