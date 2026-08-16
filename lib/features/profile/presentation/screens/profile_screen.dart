import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Account & Profile',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.paperLine),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.brand, AppColors.brandDark],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MessMax Guest User',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Log in or register to post seat ads',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.inkFaded,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Quick Actions
            _sectionHeader('ACCOUNT ACTIONS'),
            _menuTile(
              icon: Icons.login_rounded,
              title: 'Login to MessMax',
              subtitle: 'Access your mess ledger & monthly meal counter',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Login screen coming in next iteration!')),
                );
              },
            ),
            _menuTile(
              icon: Icons.person_add_alt_1_rounded,
              title: 'Create Account',
              subtitle: 'Register as mess manager or room seeker',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Registration screen coming soon!')),
                );
              },
            ),

            const SizedBox(height: 20),

            _sectionHeader('MESS MANAGEMENT'),
            _menuTile(
              icon: Icons.add_business_rounded,
              title: 'Post a Seat Available Ad',
              subtitle: 'List your open mess seat for student/jobholder seekers',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Post ad flow requires manager login')),
                );
              },
            ),
            _menuTile(
              icon: Icons.calculate_rounded,
              title: 'Manage Daily Mess Meals',
              subtitle: 'Track meals, guest counts & bazar expenses',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Mess ledger requires logged in account')),
                );
              },
            ),

            const SizedBox(height: 20),

            _sectionHeader('SETTINGS & APP INFO'),
            _menuTile(
              icon: Icons.info_outline_rounded,
              title: 'About MessMax v1.0',
              subtitle: 'Universal mess meal counter & seat locator',
              onTap: () {},
            ),
            _menuTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy & Terms',
              subtitle: 'Data protection policies & listing terms',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: AppColors.inkFaded,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.paperLine),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.brandDark, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.inkFaded,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppColors.inkFaded, size: 20),
      ),
    );
  }
}
