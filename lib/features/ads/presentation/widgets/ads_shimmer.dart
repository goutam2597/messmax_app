import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shimmer_box.dart';

/// Shimmer skeleton loader matching the exact Ads / Seat Search Screen:
/// Search bar with filter -> Quick filter chips -> Count pill -> 2-Column Staggered Grid.
class AdsShimmer extends StatelessWidget {
  const AdsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search & Filter Header
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: ShimmerBox(
                height: 48,
                radius: 14,
                width: double.infinity,
              ),
            ),

            // Filter Chips Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: Row(
                children: const [
                  ShimmerBox(width: 80, height: 32, radius: 20),
                  SizedBox(width: 8),
                  ShimmerBox(width: 90, height: 32, radius: 20),
                  SizedBox(width: 8),
                  ShimmerBox(width: 100, height: 32, radius: 20),
                  SizedBox(width: 8),
                  ShimmerBox(width: 60, height: 32, radius: 20),
                ],
              ),
            ),

            // Results count banner
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 4, 14, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerBox(width: 130, height: 14, radius: 4),
                  ShimmerBox(width: 50, height: 14, radius: 4),
                ],
              ),
            ),

            // Staggered Grid Skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: const [
                        _ShimmerGridCard(imageHeight: 150),
                        SizedBox(height: 12),
                        _ShimmerGridCard(imageHeight: 120),
                        SizedBox(height: 12),
                        _ShimmerGridCard(imageHeight: 150),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: const [
                        _ShimmerGridCard(imageHeight: 120),
                        SizedBox(height: 12),
                        _ShimmerGridCard(imageHeight: 150),
                        SizedBox(height: 12),
                        _ShimmerGridCard(imageHeight: 120),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerGridCard extends StatelessWidget {
  final double imageHeight;

  const _ShimmerGridCard({required this.imageHeight});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEBEF)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton with house & meal emblem
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: imageHeight,
                width: double.infinity,
                color: const Color(0xFFE2E4E8),
              ),
              Opacity(
                opacity: 0.55,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.apartment_rounded,
                        size: 32,
                        color: Color(0xFFB4B9C4),
                      ),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFFD0D5DF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.restaurant_rounded,
                            size: 14,
                            color: Color(0xFFB4B9C4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned(
                top: 10,
                left: 10,
                child: ShimmerBox(width: 50, height: 18, radius: 8),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 70, height: 18, radius: 8),
                SizedBox(height: 8),
                ShimmerBox(width: double.infinity, height: 14, radius: 4),
                SizedBox(height: 6),
                ShimmerBox(width: 90, height: 11, radius: 3),
                SizedBox(height: 10),
                Divider(height: 1, color: Color(0xFFEAEBEF)),
                SizedBox(height: 8),
                Row(
                  children: [
                    ShimmerCircle(size: 20),
                    SizedBox(width: 6),
                    Expanded(
                      child: ShimmerBox(width: 60, height: 11, radius: 3),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
