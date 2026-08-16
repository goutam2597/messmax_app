import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/messmax_app_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MessMaxAppBar(title: 'My Profile & Mess'),

              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserHeaderCard(context),

                    const SizedBox(height: 20),

                    _buildQuickActionsGrid(context),

                    const SizedBox(height: 24),

                    _sectionTitle('ACCOUNT & SETTINGS'),
                    _buildMenuGroup([
                      (
                        icon: Icons.person_outline_rounded,
                        title: 'Personal Information',
                        subtitle: 'Manage phone number, email and name',
                      ),
                      (
                        icon: Icons.notifications_none_rounded,
                        title: 'Notification Preferences',
                        subtitle:
                            'Meal off requests, bazar updates and seat alerts',
                      ),
                    ]),

                    const SizedBox(height: 20),

                    _sectionTitle('MESS MANAGEMENT'),
                    _buildMenuGroup([
                      (
                        icon: Icons.storefront_rounded,
                        title: 'My Posted Seat Listings',
                        subtitle: 'View and edit active seat availability ads',
                      ),
                      (
                        icon: Icons.event_note_rounded,
                        title: 'Bazar Roster & Meal Schedule',
                        subtitle: 'Assign shopping days to flat members',
                      ),
                    ]),

                    const SizedBox(height: 20),

                    _sectionTitle('HELP & LEGAL'),
                    _buildMenuGroup([
                      (
                        icon: Icons.help_outline_rounded,
                        title: 'Help Center & Support',
                        subtitle: 'MessMax customer support and FAQs',
                      ),
                      (
                        icon: Icons.shield_outlined,
                        title: 'Privacy Policy & Terms',
                        subtitle: 'Data safety and listing rules',
                      ),
                    ]),

                    const SizedBox(height: 30),

                    const Center(
                      child: Text(
                        'MessMax v1.0.0 • Universal Mess Network',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkFaded,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeaderCard(BuildContext context) {
    return Container(
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
            color: AppColors.brandDark.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            right: 40,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.15),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mess Manager Account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sign in to manage meals & post seat ads',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'GUEST ACCESS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Manager login coming soon.'),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Sign In / Register',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.brandDark,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _actionCard(
            context,
            icon: Icons.add_circle_outline_rounded,
            title: 'Post Seat Ad',
            subtitle: 'Manager listing',
            isAccent: true,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Manager login required to post a seat ad.')),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionCard(
            context,
            icon: Icons.restaurant_menu_rounded,
            title: 'Meal Counter',
            subtitle: 'Daily chits',
            isAccent: false,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Connect your mess account to track meals.')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _actionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isAccent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isAccent ? AppColors.brandDark : AppColors.paperRaised,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isAccent ? AppColors.brandDark : AppColors.paperLine,
          ),
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isAccent
                    ? Colors.white.withValues(alpha: 0.15)
                    : AppColors.brandSoft,
              ),
              child: Icon(
                icon,
                color: isAccent ? Colors.white : AppColors.brandDark,
                size: 22,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: isAccent ? Colors.white : AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isAccent
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppColors.inkFaded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          color: AppColors.inkFaded,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildMenuGroup(
    List<({IconData icon, String title, String subtitle})> items,
  ) {
    return Material(
      color: AppColors.paperRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.paperLine),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.paperLine),
            _menuRow(items[i]),
          ],
        ],
      ),
    );
  }

  Widget _menuRow(
    ({IconData icon, String title, String subtitle}) item,
  ) {
    return ListTile(
      onTap: () {},
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      tileColor: AppColors.paperRaised,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.brandSoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(item.icon, color: AppColors.brandDark, size: 20),
      ),
      title: Text(
        item.title,
        style: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
      subtitle: Text(
        item.subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.inkFaded,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.inkFaded, size: 20),
    );
  }
}
