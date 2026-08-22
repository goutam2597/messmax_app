import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Decorative geometry variants for [DashUI.accentedCard] — each renders a
/// different kind of shape so neighbouring cards never look stamped.
enum DashShape { blob, wedge, dots, arc, band }

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

  /// Card with a soft decorative accent shape bleeding off a corner — keeps
  /// the boxy look while adding quiet visual interest. Each [DashShape]
  /// renders a *different* kind of geometry so sibling cards don't repeat.
  ///
  /// Set [rich] on LARGE cards (heroes, section panels): it layers extra
  /// geometry across all four corners so the card never feels empty.
  static Widget accentedCard({
    required Widget child,
    required Color accent,
    DashShape shape = DashShape.blob,
    Color color = AppColors.paperRaised,
    Color borderColor = AppColors.paperLine,
    double radius = rCard,
    List<BoxShadow>? shadow,
    bool rich = false,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: shadow,
      ),
      child: Stack(
        children: [
          ..._shapeLayers(shape, accent),
          if (rich) ..._richLayers(accent),
          // Content is a NON-positioned child so the Stack sizes to it even
          // when the parent gives unbounded constraints (e.g. scroll views).
          child,
        ],
      ),
    );
  }

  /// Extra geometry for large surfaces — spreads decoration across every
  /// corner and edge instead of clustering in one spot.
  static List<Widget> _richLayers(Color accent) {
    return [
      // Large soft wash hugging the bottom-left.
      Positioned(
        bottom: -60,
        left: -50,
        child: Container(
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.07),
          ),
        ),
      ),
      // Thin ring floating mid-right edge.
      Positioned(
        top: 42,
        right: -18,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: accent.withValues(alpha: 0.12)),
          ),
        ),
      ),
      // Mini dot pair, top-left quadrant.
      Positioned(
        top: 14,
        left: 14,
        child: Row(
          children: [
            _miniDot(accent, 0.28),
            const SizedBox(width: 5),
            _miniDot(accent, 0.16),
          ],
        ),
      ),
      // Hairline accent tick along the left edge.
      Positioned(
        left: 0,
        top: 0,
        bottom: 0,
        child: Container(width: 2.5, color: accent.withValues(alpha: 0.30)),
      ),
    ];
  }

  static Widget _miniDot(Color accent, double alpha) {
    return Container(
      width: 4.5,
      height: 4.5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: alpha),
      ),
    );
  }

  static List<Widget> _shapeLayers(DashShape shape, Color accent) {
    // Every composition is BALANCED: a primary element on one corner plus a
    // faint counter-echo on the opposite corner, so cards feel framed rather
    // than decorated on a single side.
    switch (shape) {
      case DashShape.blob:
        return [
          // Primary: filled circle + thin ring, top-right.
          Positioned(
            top: -26,
            right: -22,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            top: -12,
            right: 34,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.16)),
              ),
            ),
          ),
          // Echo: small dot + hairline arc, bottom-left.
          Positioned(
            bottom: 12,
            left: -8,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.14)),
              ),
            ),
          ),
        ];
      case DashShape.wedge:
        return [
          // Primary: diagonal ribbons slicing the top-right corner.
          Positioned(
            top: -30,
            right: -44,
            child: Transform.rotate(
              angle: -0.62,
              child: Container(width: 110, height: 34, color: accent.withValues(alpha: 0.14)),
            ),
          ),
          Positioned(
            top: -18,
            right: -50,
            child: Transform.rotate(
              angle: -0.62,
              child: Container(width: 120, height: 8, color: accent.withValues(alpha: 0.20)),
            ),
          ),
          // Echo: thin diagonal line, bottom-left corner.
          Positioned(
            bottom: -26,
            left: -30,
            child: Transform.rotate(
              angle: -0.62,
              child: Container(width: 90, height: 5, color: accent.withValues(alpha: 0.14)),
            ),
          ),
        ];
      case DashShape.dots:
        return [
          // Primary: 3×3 dot grid, bottom-right.
          Positioned(
            bottom: 10,
            right: 10,
            child: SizedBox(
              width: 38,
              height: 38,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var r = 0; r < 3; r++)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var c = 0; c < 3; c++)
                          Container(
                            width: 3.5,
                            height: 3.5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent.withValues(alpha: 0.22),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          // Echo: single soft dot, top-left.
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.20),
              ),
            ),
          ),
        ];
      case DashShape.arc:
        return [
          // Primary: quarter-discs rising from the bottom-right.
          Positioned(
            bottom: -40,
            right: -40,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.13),
              ),
            ),
          ),
          Positioned(
            bottom: -28,
            right: -28,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.10),
              ),
            ),
          ),
          // Echo: thin ring peeking from the top-left corner.
          Positioned(
            top: -16,
            left: -16,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.14)),
              ),
            ),
          ),
        ];
      case DashShape.band:
        return [
          // Primary: solid accent bar across the top edge.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(height: 3, color: accent.withValues(alpha: 0.55)),
          ),
          // Echo: faint baseline along the bottom edge.
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(height: 1.5, color: accent.withValues(alpha: 0.25)),
          ),
        ];
    }
  }

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
