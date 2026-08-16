import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/filter_pill_bar.dart';
import '../../../../core/widgets/messmax_app_bar.dart';

class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

typedef _Article = ({
  String title,
  String category,
  String readTime,
  String date,
  String summary,
  IconData icon,
});

class _BlogScreenState extends State<BlogScreen> {
  String _selectedCategory = 'All';

  static const _categories = ['All', 'Mess Life', 'Meal Rates', 'Room Hunting'];

  static const _articles = <_Article>[
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
            const MessMaxAppBar(
              title: 'MessMax Guides',
              subtitle:
                  'Articles & tips on room hunting and mess meal management',
            ),

            const SizedBox(height: 8),

            FilterPillBar(
              labels: _categories,
              selectedIndex: _categories.indexOf(_selectedCategory),
              onSelected: (index) =>
                  setState(() => _selectedCategory = _categories[index]),
            ),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final article = filtered[index];
                  if (index == 0 && _selectedCategory == 'All') {
                    return _buildHeroArticleCard(article);
                  }
                  return _buildArticleCard(article);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroArticleCard(_Article article) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.brandDark, AppColors.brandDeep],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandDark.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Icon(
                    article.icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    article.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'FEATURED',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withValues(alpha: 0.9),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              article.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.25,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              article.summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  article.date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  article.readTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Read Article →',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accentSoft,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  (Color, Color) _categoryColors(String category) {
    switch (category) {
      case 'Mess Life':
        return (AppColors.brandSoft, AppColors.brandDark);
      case 'Meal Rates':
        return (AppColors.accentSoft, AppColors.accentDark);
      case 'Room Hunting':
        return (AppColors.emeraldSoft, AppColors.emerald);
      default:
        return (AppColors.brandSoft, AppColors.brandDark);
    }
  }

  Widget _buildArticleCard(_Article article) {
    final (bg, fg) = _categoryColors(article.category);

    return GestureDetector(
      onTap: () {},
      child: Container(
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
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(article.icon, color: fg, size: 18),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    article.category,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: fg,
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
      ),
    );
  }
}
