import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Unified search bar with an embedded filter button.
///
/// Design matches the market app: 46px rounded container, hairline border,
/// soft shadow, vertical divider, and a small brand-tinted filter square.
class SearchFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onFilterTap;
  final VoidCallback? onClearTap;
  final double height;

  const SearchFilterBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onSubmitted,
    required this.onFilterTap,
    this.onClearTap,
    this.height = 46,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.paperLine, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(
            Icons.search_rounded,
            color: AppColors.inkFaded,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: AppColors.inkFaded,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClearTap,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.inkFaded,
                ),
              ),
            ),
          Container(
            width: 1,
            height: 22,
            color: AppColors.paperLine.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onFilterTap,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: AppColors.brand,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}
