import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  String _selectedCategory = 'All';

  static const _articles = [
    (
      title: '5 Essential Tips Before Moving into a Shared Mess in Dhaka',
      category: 'Mess Life',
      readTime: '4 min read',
      date: 'Aug 15, 2026',
      summary:
          'From verifying weekly bazar rosters to checking meal chit rules — here is everything a student or jobholder needs to confirm before paying deposit.',
      icon: Icons.checklist_rounded,
    ),
    (
      title: 'How MessMax Automates Daily Meals & Monthly Balance Calculation',
      category: 'Meal Rates',
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
      category: 'Mess Life',
      readTime: '4 min read',
      date: 'Aug 10, 2026',
      summary:
          'Assigning duty rosters fairly across flat members ensures smooth grocery purchases and transparent expense accounting.',
      icon: Icons.shopping_bag_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCategory == 'All'
        ? _articles
        : _articles.where((a) => a.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Category Bar
            _buildCategoryBar(),

            // Articles List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final article = filtered[index];
                  return _buildArticleCard(article);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MessMax Guides',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Articles & tips on room hunting and mess meal management',
              style: TextStyle(
                color: AppColors.inkFaded,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBar() {
    final categories = ['All', 'Mess Life', 'Meal Rates', 'Room Hunting'];
    return SizedBox(
      height: 38,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = cat;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.brandDark : AppColors.paperRaised,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.brandDark : AppColors.paperLine,
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.inkSoft,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArticleCard(({String category, String date, IconData icon, String readTime, String summary, String title}) article) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.paperLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(article.icon, color: AppColors.brandDark, size: 18),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  article.category,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandDark,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                article.readTime,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.inkFaded,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 12, color: AppColors.inkFaded),
              const SizedBox(width: 4),
              Text(
                article.date,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.inkFaded,
                ),
              ),
              const Spacer(),
              const Text(
                'Read Article →',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
