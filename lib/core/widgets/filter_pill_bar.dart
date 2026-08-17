import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Horizontal animated pill selector shared by Home, Find Seats, and Blog.
class FilterPillBar extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double height;
  final bool insetPadding;

  const FilterPillBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.height = 38,
    this.insetPadding = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        clipBehavior: Clip.none,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        padding: EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.brandDark : AppColors.paperRaised,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.brandDark : AppColors.paperLine,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.brandDark.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  labels[index],
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.inkSoft,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
