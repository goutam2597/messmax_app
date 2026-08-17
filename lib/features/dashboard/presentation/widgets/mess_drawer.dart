import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';

class MessDrawer extends StatelessWidget {
  final String activeSection;
  final ValueChanged<String>? onSectionSelected;

  const MessDrawer({
    super.key,
    this.activeSection = 'dashboard',
    this.onSectionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.paper,
      width: 310,
      child: Column(
        children: [
          _buildDrawerHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              children: [
                _buildSectionLabel('OVERVIEW'),
                _drawerTile(
                  id: 'dashboard',
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard & Ledger',
                  subtitle: 'Daily meal & expense stats',
                  badge: 'LIVE',
                  badgeColor: AppColors.brandDark,
                  context: context,
                ),
                _drawerTile(
                  id: 'daily_sheet',
                  icon: Icons.table_chart_rounded,
                  title: 'Daily Meal Sheet',
                  subtitle: 'Member B/L/D breakdown',
                  context: context,
                ),

                const SizedBox(height: 16),
                _buildSectionLabel('MEAL SYSTEM'),
                _drawerTile(
                  id: 'meal_off',
                  icon: Icons.do_not_disturb_on_rounded,
                  title: 'Meal Off Requests',
                  subtitle: 'Approve member off/on',
                  badge: '2 PENDING',
                  badgeColor: AppColors.accent,
                  context: context,
                ),
                _drawerTile(
                  id: 'meal_settings',
                  icon: Icons.rice_bowl_rounded,
                  title: 'Default Meal Settings',
                  subtitle: 'Configure member defaults',
                  context: context,
                ),

                const SizedBox(height: 16),
                _buildSectionLabel('BAZAR & FINANCE'),
                _drawerTile(
                  id: 'bazar_roster',
                  icon: Icons.shopping_basket_rounded,
                  title: 'Bazar Roster & Log',
                  subtitle: 'Daily market receipts',
                  context: context,
                ),
                _drawerTile(
                  id: 'deposits',
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Member Deposits',
                  subtitle: 'Track advances & balance',
                  context: context,
                ),

                const SizedBox(height: 16),
                _buildSectionLabel('SEATS & HOSTEL'),
                _drawerTile(
                  id: 'seat_ads',
                  icon: Icons.storefront_rounded,
                  title: 'My Seat Listings',
                  subtitle: '3 Active ads on MessMax',
                  badge: '3 LIVE',
                  badgeColor: const Color(0xFF0F9F59),
                  context: context,
                ),
                _drawerTile(
                  id: 'room_allocation',
                  icon: Icons.king_bed_rounded,
                  title: 'Room & Bed Roster',
                  subtitle: 'Manage capacity & rooms',
                  context: context,
                ),

                const SizedBox(height: 16),
                _buildSectionLabel('MEMBERS & MESS'),
                _drawerTile(
                  id: 'member_roster',
                  icon: Icons.people_alt_rounded,
                  title: 'Member Roster',
                  subtitle: '12 Active members',
                  context: context,
                ),
                _drawerTile(
                  id: 'invite_code',
                  icon: Icons.qr_code_2_rounded,
                  title: 'Mess Join Code',
                  subtitle: 'Invite new members',
                  context: context,
                ),

                const SizedBox(height: 16),
                _buildSectionLabel('SETTINGS'),
                _drawerTile(
                  id: 'mess_rules',
                  icon: Icons.gavel_rounded,
                  title: 'Mess Rules & Policy',
                  subtitle: 'Meal timing & notice period',
                  context: context,
                ),
                _drawerTile(
                  id: 'mess_settings',
                  icon: Icons.settings_rounded,
                  title: 'Mess Configuration',
                  subtitle: 'Manager rights & details',
                  context: context,
                ),
              ],
            ),
          ),
          _buildDrawerFooter(context),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final dashboardState = context.watch<DashboardCubit>().state;

    final user = authState is AuthAuthenticated ? authState.user : null;
    final activeMess = dashboardState is DashboardLoaded
        ? dashboardState.dashboard.activeMess
        : null;

    final messName = activeMess?.name ?? 'No Mess Joined';
    final messCode = activeMess != null ? activeMess.code : 'No Active Code';
    final roleLabel = user?.roleLabel ?? 'MEMBER';

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 16,
        16,
        18,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandDark, AppColors.brandDeep],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      messName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.key_rounded, size: 12, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          'Code: $messCode',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.unfold_more_rounded,
                color: Colors.white70,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF0F9F59),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'August 2026 • Active Month',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    roleLabel,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: AppColors.inkFaded,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _drawerTile({
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
    String? badge,
    Color? badgeColor,
    required BuildContext context,
  }) {
    final isSelected = activeSection == id;

    return Material(
      color: isSelected
          ? AppColors.brandDark.withValues(alpha: 0.08)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          Navigator.pop(context); // Close drawer
          if (onSectionSelected != null) {
            onSectionSelected!(id);
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.brandDark
                      : AppColors.paperRaised,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? null
                      : Border.all(color: AppColors.paperLine),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : AppColors.inkSoft,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                        color: isSelected ? AppColors.brandDark : AppColors.ink,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.inkFaded,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor ?? AppColors.brandDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerFooter(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final avatarUrl = user?.avatarUrl != null ? AppConfig.sanitizeImageUrl(user!.avatarUrl) : null;
    final userName = user?.name ?? 'Goutam Sharma';
    final userEmail = user?.email ?? 'goutam@example.com';
    final userInitials = user?.initials ?? 'GS';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.paperRaised,
        border: Border(top: BorderSide(color: AppColors.paperLine)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brandDark,
            ),
            child: ClipOval(
              child: avatarUrl != null
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Center(
                        child: Text(
                          userInitials,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        userInitials,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  userEmail,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.inkFaded,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('MessMax Manager Panel Active')),
              );
            },
            icon: const Icon(
              Icons.verified_rounded,
              color: AppColors.brandDark,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
