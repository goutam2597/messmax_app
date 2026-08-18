import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// Shared screen header used by all tab screens.
///
/// Supports a leading slot (e.g. brand mark), actions row, and a `bottom`
/// slot for search fields or filter chips.
class MessMaxAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? bottom;
  final bool showBorder;
  final bool useLogo;

  const MessMaxAppBar({
    super.key,
    this.title = '',
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.bottom,
    this.showBorder = false,
    this.useLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    final showBrandLogo = useLogo || (title == 'MessMax' && subtitle == 'Seats & Meals Hub');

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: showBorder
            ? const Border(
                bottom: BorderSide(color: AppColors.paperLine),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showBrandLogo) ...[
                SvgPicture.asset(
                  'assets/images/logo.svg',
                  height: 28,
                  fit: BoxFit.contain,
                ),
              ] else ...[
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            color: AppColors.inkFaded,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const Spacer(),
              if (actions.isNotEmpty) ...[
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      actions[i],
                    ],
                  ],
                ),
              ],
            ],
          ),
          if (bottom != null) ...[
            const SizedBox(height: 12),
            bottom!,
          ],
        ],
      ),
    );
  }
}

/// Brand mark medallion using official favicon emblem SVG.
class BrandMark extends StatelessWidget {
  final double size;

  const BrandMark({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SvgPicture.asset(
          'assets/images/mm_fav.svg',
          width: size - 8,
          height: size - 8,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

/// Standard circular header action button (bell, tune, etc).
class AppBarActionButton extends StatelessWidget {
  final IconData icon;
  final String? svgAsset;
  final VoidCallback? onTap;
  final bool showDot;

  const AppBarActionButton({
    super.key,
    required this.icon,
    this.svgAsset,
    this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.paperRaised,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.paperLine),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (svgAsset != null)
              SvgPicture.asset(
                svgAsset!,
                width: 19,
                height: 19,
                colorFilter:
                    const ColorFilter.mode(AppColors.ink, BlendMode.srcIn),
              )
            else
              Icon(icon, size: 19, color: AppColors.ink),
            if (showDot)
              Positioned(
                top: 8,
                right: 9,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Location chip used in the Home app bar actions.
class LocationChip extends StatelessWidget {
  final String label;

  const LocationChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.paperLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_rounded,
            size: 13,
            color: AppColors.accent,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
