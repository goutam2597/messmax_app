import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shimmer_box.dart';

/// Shimmer skeleton loader for the Blog Guides screen.
class BlogShimmer extends StatelessWidget {
  const BlogShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
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
                // Cover image skeleton
                Container(
                  height: 150,
                  width: double.infinity,
                  color: const Color(0xFFE2E4E8),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerBox(width: 80, height: 18, radius: 8),
                      SizedBox(height: 10),
                      ShimmerBox(width: double.infinity, height: 18, radius: 4),
                      SizedBox(height: 6),
                      ShimmerBox(width: 200, height: 14, radius: 4),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          ShimmerBox(width: 70, height: 12, radius: 3),
                          SizedBox(width: 12),
                          ShimmerBox(width: 90, height: 12, radius: 3),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
