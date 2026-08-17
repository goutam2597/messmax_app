import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/messmax_app_bar.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import 'package:messmax_app/features/main/presentation/screens/main_shell_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _goLogin(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

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
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        if (state is AuthAuthenticated) {
                          return _authedHeader(context, state);
                        }
                        if (state is AuthLoading) {
                          return _loadingHeader();
                        }
                        return _guestHeader(context);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDashboardButton(context),
                    const SizedBox(height: 16),
                    _quickActions(context),
                    const SizedBox(height: 24),
                    _sectionTitle('ACCOUNT & SETTINGS'),
                    _menuGroup([
                      (
                        icon: Icons.person_outline_rounded,
                        title: 'Personal Information',
                        subtitle: 'Manage name and email',
                      ),
                      (
                        icon: Icons.notifications_none_rounded,
                        title: 'Notification Preferences',
                        subtitle: 'Meal off, bazar and seat alerts',
                      ),
                    ]),
                    const SizedBox(height: 20),
                    _sectionTitle('MESS MANAGEMENT'),
                    _menuGroup([
                      (
                        icon: Icons.storefront_rounded,
                        title: 'My Posted Seat Listings',
                        subtitle: 'View and edit seat ads',
                      ),
                      (
                        icon: Icons.event_note_rounded,
                        title: 'Bazar Roster & Meal Schedule',
                        subtitle: 'Assign shopping days',
                      ),
                    ]),
                    const SizedBox(height: 20),
                    _sectionTitle('HELP & LEGAL'),
                    _menuGroup([
                      (
                        icon: Icons.help_outline_rounded,
                        title: 'Help Center & Support',
                        subtitle: 'FAQs and support team',
                      ),
                      (
                        icon: Icons.shield_outlined,
                        title: 'Privacy Policy & Terms',
                        subtitle: 'Data usage and safety rules',
                      ),
                    ]),
                    const SizedBox(height: 24),
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        if (state is AuthAuthenticated) {
                          return SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await context.read<AuthCubit>().logout();
                                if (!context.mounted) return;
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const MainShellScreen(initialTab: 0),
                                  ),
                                  (_) => false,
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.danger,
                                side: const BorderSide(color: AppColors.danger, width: 1.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              icon: const Icon(Icons.logout_rounded, size: 18),
                              label: const Text(
                                'Sign Out',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 30),
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        final sub = state is AuthAuthenticated
                            ? state.user.email
                            : 'Guest • Sign in to sync your mess';
                        return Center(
                          child: Column(
                            children: [
                              const Text(
                                'MessMax v1.0.0 • Universal Mess Network',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.inkFaded,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                sub,
                                style: const TextStyle(fontSize: 11, color: AppColors.inkFaded),
                              ),
                            ],
                          ),
                        );
                      },
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

  Widget _buildDashboardButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandDark, AppColors.brandDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandDark.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.dashboard_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Open Manager Dashboard',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Access meal ledger, bazar roster & mess drawer',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _loadingHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.brandDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      ),
    );
  }

  Widget _guestHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandDark, AppColors.brandDeep],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0x40202C36),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
              child: Icon(Icons.person_rounded, color: Colors.white, size: 34),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Mess Member Account',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Sign in to manage meals & seat ads',
                  style: TextStyle(fontSize: 12, color: Color(0xCCFFFFFF)),
                ),
                SizedBox(height: 6),
                _GuestBadge(),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const _AccountTierBadge(isPremium: false),
        ],
      ),
    );
  }

  Widget _authedHeader(BuildContext context, AuthAuthenticated state) {
    final user = state.user;
    final avatarUrl = AppConfig.sanitizeImageUrl(user.avatarUrl);
    // Hardcoded user plan tier: toggle to true for premium icon preview
    final isPremiumUser = user.isHostelOwner;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandDark, AppColors.brandDeep],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandDark.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
            child: ClipOval(
              child: avatarUrl != null
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, obj, stk) => _initialAvatar(user.initials),
                    )
                  : _initialAvatar(user.initials),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.isIndividual ? const Color(0xFFE85D04) : const Color(0xFF0F9F59),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.roleLabel,
                    style: const TextStyle(
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
          const SizedBox(width: 10),
          _AccountTierBadge(isPremium: isPremiumUser),
        ],
      ),
    );
  }

  Widget _initialAvatar(String ch) => Center(
        child: Text(
          ch,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
      );

  Widget _quickActions(BuildContext context) {
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
              final st = context.read<AuthCubit>().state;
              if (st is! AuthAuthenticated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sign in to post a seat ad')),
                );
                _goLogin(context);
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Post Seat Ad — coming soon')),
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
                const SnackBar(content: Text('Connect your mess account to track meals')),
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isAccent ? AppColors.brandDark : AppColors.paperLine),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isAccent ? Colors.white.withValues(alpha: 0.15) : AppColors.brandSoft,
              ),
              child: Icon(icon, color: isAccent ? Colors.white : AppColors.brandDark, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
                color: isAccent ? Colors.white : AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11.5,
                color: isAccent ? Colors.white.withValues(alpha: 0.7) : AppColors.inkFaded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          t,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            color: AppColors.inkFaded,
            letterSpacing: 0.6,
          ),
        ),
      );

  Widget _menuGroup(List<({IconData icon, String title, String subtitle})> items) => Material(
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

  Widget _menuRow(({IconData icon, String title, String subtitle}) item) => ListTile(
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        subtitle: Text(
          item.subtitle,
          style: const TextStyle(fontSize: 11.5, color: AppColors.inkFaded),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaded, size: 20),
      );
}

class _GuestBadge extends StatelessWidget {
  const _GuestBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
    );
  }
}

class _AccountTierBadge extends StatelessWidget {
  final bool isPremium;
  const _AccountTierBadge({required this.isPremium});

  @override
  Widget build(BuildContext context) {
    if (isPremium) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.workspace_premium_rounded,
          color: Colors.white,
          size: 20,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: const Icon(
        Icons.verified_user_outlined,
        color: Colors.white70,
        size: 20,
      ),
    );
  }
}
