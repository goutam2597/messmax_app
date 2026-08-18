import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shimmer_box.dart';

/// Shimmer skeleton loader that mirrors the exact Home Screen layout:
/// Header app bar -> Search bar -> Featured carousel -> Category filter chips -> Masonry grid cards.
class HomeShimmer extends StatelessWidget {
  const HomeShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Bar Skeleton
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  const ShimmerBox(width: 38, height: 38, radius: 12),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 110, height: 16, radius: 4),
                      SizedBox(height: 5),
                      ShimmerBox(width: 70, height: 10, radius: 3),
                    ],
                  ),
                  const Spacer(),
                  const ShimmerCircle(size: 38),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Search Filter Bar Skeleton
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: ShimmerBox(
                height: 48,
                radius: 14,
                width: double.infinity,
              ),
            ),

            const SizedBox(height: 14),

            // Featured Slider Skeleton with Central Branded House+Meal Emblem
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                height: 260,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E4E9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    // Centered House & Meal Emblem
                    Center(
                      child: Opacity(
                        opacity: 0.6,
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(
                                Icons.apartment_rounded,
                                size: 56,
                                color: Color(0xFFB4B9C4),
                              ),
                              Positioned(
                                right: 6,
                                bottom: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFD0D5DF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.restaurant_rounded,
                                    size: 26,
                                    color: Color(0xFFB4B9C4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Row(
                            children: [
                              ShimmerBox(width: 85, height: 26, radius: 12),
                              SizedBox(width: 8),
                              ShimmerBox(width: 65, height: 26, radius: 12),
                            ],
                          ),
                          Spacer(),
                          ShimmerBox(width: double.infinity, height: 20, radius: 4),
                          SizedBox(height: 8),
                          ShimmerBox(width: 160, height: 14, radius: 4),
                          SizedBox(height: 14),
                          Row(
                            children: [
                              ShimmerBox(width: 90, height: 28, radius: 10),
                              Spacer(),
                              ShimmerBox(width: 110, height: 28, radius: 14),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Category Filter Pills Skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: const [
                  ShimmerBox(width: 70, height: 34, radius: 20),
                  SizedBox(width: 8),
                  ShimmerBox(width: 95, height: 34, radius: 20),
                  SizedBox(width: 8),
                  ShimmerBox(width: 90, height: 34, radius: 20),
                  SizedBox(width: 8),
                  ShimmerBox(width: 75, height: 34, radius: 20),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerBox(width: 140, height: 18, radius: 4),
                  ShimmerBox(width: 60, height: 14, radius: 4),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 2-Column Masonry Cards Skeleton
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
          // Image skeleton with central house & meal icon
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
