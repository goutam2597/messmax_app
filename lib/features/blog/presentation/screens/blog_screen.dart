import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class BlogScreen extends StatelessWidget {
  const BlogScreen({super.key});

  static const _articles = [
    (
      title: '5 Essential Tips Before Moving into a Shared Mess in Dhaka',
      category: 'Mess Life Guide',
      readTime: '4 min read',
      date: 'Aug 15, 2026',
      summary:
          'From verifying bazar manager rosters to checking meal chit rules — here is everything a student or jobholder needs to confirm before paying deposit.',
      icon: Icons.checklist_rounded,
    ),
    (
      title: 'How MessMax Automates Daily Meals & Monthly Balance Calculation',
      category: 'Feature Spotlight',
      readTime: '3 min read',
      date: 'Aug 14, 2026',
      summary:
          'No more disputes on Excel sheets! Learn how manager meal off requests, guest meal entries, and bazar logs compute accurate meal rates automatically.',
      icon: Icons.calculate_rounded,
    ),
    (
      title: 'Single vs Shared vs Semi-Private: Which Seat Option Fits You?',
      category: 'Room Hunting',
      readTime: '5 min read',
      date: 'Aug 12, 2026',
      summary:
          'Breakdown of room types, monthly budget expectations, privacy levels, and utility bill sharing arrangements in student hostels.',
      icon: Icons.king_bed_rounded,
    ),
    (
      title: 'Manager Best Practices: Organizing Weekly Bazar Schedules',
      category: 'Mess Management',
      readTime: '4 min read',
      date: 'Aug 10, 2026',
      summary:
          'Assigning duty rosters fairly across flat members ensures smooth grocery purchases and transparent expense accounting.',
      icon: Icons.shopping_bag_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'MessMax Blog & Guides',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _articles.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final article = _articles[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.paperLine),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.brandSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        article.category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandDark,
                        ),
                      ),
                    ),
                    Text(
                      article.readTime,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.inkFaded,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  article.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  article.summary,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 12, color: AppColors.inkFaded),
                    const SizedBox(width: 4),
                    Text(
                      article.date,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.inkFaded,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Read Guide →',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
