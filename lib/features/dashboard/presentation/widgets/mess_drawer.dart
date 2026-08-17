import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../ads/presentation/screens/my_ads_screen.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../main/presentation/screens/main_shell_screen.dart';
import '../../../profile/presentation/screens/account_screen.dart';
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
    final authState = context.watch<AuthCubit>().state;
    final dashboardState = context.watch<DashboardCubit>().state;

    final user = authState is AuthAuthenticated ? authState.user : null;
    final dashboard = dashboardState is DashboardLoaded
        ? dashboardState.dashboard
        : null;
    final activeMess = dashboard?.activeMess;
    final myMesses = dashboard?.myMesses ?? [];

    final isIndividual = user?.isIndividual ?? true;
    final managesAny =
        (user?.isHostelOwner ?? false) ||
        (activeMess?.isManager ?? false) ||
        myMesses.any((m) => m.isManager);
    final isMemberOnly = !isIndividual && !managesAny;

    return Drawer(
      backgroundColor: AppColors.paper,
      width: 290,
      child: Column(
        children: [
          _buildDrawerHeader(
            context: context,
            isIndividual: isIndividual,
            isMemberOnly: isMemberOnly,
            userRoleLabel: isIndividual
                ? 'INDIVIDUAL'
                : (isMemberOnly ? 'MEMBER' : 'HOSTEL OWNER'),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              children: [
                // --- CASE 1: INDIVIDUAL ---
                if (isIndividual) ...[
                  _drawerTile(
                    id: 'dashboard',
                    icon: Icons.dashboard_rounded,
                    title: 'Overview',
                    subtitle: 'Dashboard & stats',
                    context: context,
                  ),
                  if (activeMess != null)
                    _drawerTile(
                      id: 'current_mess',
                      icon: Icons.grid_view_rounded,
                      title: activeMess.name,
                      subtitle: 'Monthly sheet & daily meals',
                      context: context,
                    ),
                  _drawerTile(
                    id: 'members',
                    icon: Icons.people_alt_rounded,
                    title: 'Members',
                    subtitle: 'Member list & roster',
                    context: context,
                  ),
                  _drawerTile(
                    id: 'bazar_schedule',
                    icon: Icons.calendar_month_rounded,
                    title: 'Bazar Schedule',
                    subtitle: 'Shopping duty roster',
                    context: context,
                  ),

                  const SizedBox(height: 14),
                  _buildSectionLabel('SEATS'),
                  _drawerTile(
                    id: 'my_ads',
                    icon: Icons.home_work_rounded,
                    title: 'My Seat Ads',
                    subtitle: 'Manage posted seat listings',
                    context: context,
                  ),
                  _drawerTile(
                    id: 'find_mess',
                    icon: Icons.search_rounded,
                    title: 'Find Seats',
                    subtitle: 'Browse live seat ads',
                    context: context,
                  ),
                ]
                // --- CASE 2: HOSTEL OWNER / MANAGER ---
                else if (managesAny) ...[
                  _drawerTile(
                    id: 'dashboard',
                    icon: Icons.dashboard_rounded,
                    title: 'Overview',
                    subtitle: 'Dashboard & stats',
                    context: context,
                  ),
                  _drawerTile(
                    id: 'messes',
                    icon: Icons.archive_rounded,
                    title: 'Messes',
                    subtitle: 'All managed messes',
                    context: context,
                  ),
                  _drawerTile(
                    id: 'members',
                    icon: Icons.people_alt_rounded,
                    title: 'Members',
                    subtitle: 'Member list & roster',
                    context: context,
                  ),
                  if (activeMess == null)
                    _drawerTile(
                      id: 'bazar_schedule',
                      icon: Icons.calendar_month_rounded,
                      title: 'Bazar Schedule',
                      subtitle: 'Shopping duty roster',
                      context: context,
                    ),

                  if (activeMess != null) ...[
                    const SizedBox(height: 14),
                    _buildSectionLabel('CURRENT MESS'),
                    _drawerTile(
                      id: 'current_mess',
                      icon: Icons.grid_view_rounded,
                      title: activeMess.name,
                      subtitle: 'Monthly sheet & daily meals',
                      context: context,
                    ),
                    _drawerTile(
                      id: 'mess_bazar',
                      icon: Icons.shopping_basket_rounded,
                      title: 'Bazar Schedule',
                      subtitle: '${activeMess.name} duty',
                      context: context,
                    ),
                  ],

                  const SizedBox(height: 14),
                  _buildSectionLabel('SEATS'),
                  _drawerTile(
                    id: 'my_ads',
                    icon: Icons.home_work_rounded,
                    title: 'My Seat Ads',
                    subtitle: 'Manage posted seat listings',
                    context: context,
                  ),
                  _drawerTile(
                    id: 'find_mess',
                    icon: Icons.search_rounded,
                    title: 'Find Seats',
                    subtitle: 'Browse live seat ads',
                    context: context,
                  ),
                ]
                // --- CASE 3: MEMBER-ONLY ---
                else ...[
                  _drawerTile(
                    id: 'dashboard',
                    icon: Icons.dashboard_rounded,
                    title: 'Overview',
                    subtitle: 'Dashboard & stats',
                    context: context,
                  ),
                  _drawerTile(
                    id: 'messes',
                    icon: Icons.archive_rounded,
                    title: 'My Messes',
                    subtitle: 'Joined messes',
                    context: context,
                  ),
                  if (activeMess == null)
                    _drawerTile(
                      id: 'bazar_schedule',
                      icon: Icons.calendar_month_rounded,
                      title: 'Bazar Schedule',
                      subtitle: 'Shopping duty roster',
                      context: context,
                    ),

                  if (activeMess != null) ...[
                    const SizedBox(height: 14),
                    _buildSectionLabel('CURRENT MESS'),
                    _drawerTile(
                      id: 'current_mess',
                      icon: Icons.grid_view_rounded,
                      title: activeMess.name,
                      subtitle: 'Monthly sheet & daily meals',
                      context: context,
                    ),
                    _drawerTile(
                      id: 'mess_bazar',
                      icon: Icons.shopping_basket_rounded,
                      title: 'Bazar Schedule',
                      subtitle: '${activeMess.name} duty',
                      context: context,
                    ),
                  ],

                  const SizedBox(height: 14),
                  _buildSectionLabel('SEATS'),
                  _drawerTile(
                    id: 'find_mess',
                    icon: Icons.search_rounded,
                    title: 'Find Seats',
                    subtitle: 'Browse live seat ads',
                    context: context,
                  ),
                ],

                const SizedBox(height: 14),
                _buildSectionLabel('ACCOUNT'),
                _drawerTile(
                  id: 'account',
                  icon: Icons.person_outline_rounded,
                  title: 'My Account',
                  subtitle: 'Profile & preferences',
                  context: context,
                ),
              ],
            ),
          ),
          _buildDrawerFooter(
            context: context,
            roleSubtitle: isIndividual
                ? 'Individual'
                : (isMemberOnly ? 'Member' : 'Hostel owner'),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader({
    required BuildContext context,
    required bool isIndividual,
    required bool isMemberOnly,
    required String userRoleLabel,
  }) {
    final dashboardState = context.watch<DashboardCubit>().state;
    final activeMess = dashboardState is DashboardLoaded
        ? dashboardState.dashboard.activeMess
        : null;

    final messName = activeMess?.name ?? '';
    final messCode = activeMess?.code ?? '';
    final consoleSub = isIndividual
        ? 'MY MESS'
        : (isMemberOnly ? 'MEMBER' : 'CONSOLE');

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 14,
        16,
        16,
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: Colors.white,
                  size: 22,
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
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
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
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF0F9F59),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'MessMax • $consoleSub',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    userRoleLabel,
                    style: const TextStyle(
                      fontSize: 8.5,
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
          fontSize: 10,
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
    required BuildContext context,
  }) {
    final isSelected = activeSection == id;

    return Material(
      color: isSelected
          ? AppColors.brandDark.withValues(alpha: 0.08)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          Navigator.pop(context); // Close drawer
          if (id == 'account') {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AccountScreen()));
          } else if (id == 'my_ads') {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MyAdsScreen()));
          } else if (id == 'find_mess') {
            Navigator.of(context).popUntil((route) => route.isFirst);
            MainShellScope.of(context)?.selectTab(0);
          } else if (id == 'dashboard') {
            Navigator.of(context).popUntil((route) => route.isFirst);
            MainShellScope.of(context)?.selectTab(0);
          } else if (onSectionSelected != null) {
            onSectionSelected!(id);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.brandDark
                      : AppColors.paperRaised,
                  borderRadius: BorderRadius.circular(9),
                  border: isSelected
                      ? null
                      : Border.all(color: AppColors.paperLine),
                ),
                child: Icon(
                  icon,
                  size: 17,
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
                        fontWeight: isSelected
                            ? FontWeight.w900
                            : FontWeight.w700,
                        color: isSelected ? AppColors.brandDark : AppColors.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerFooter({
    required BuildContext context,
    required String roleSubtitle,
  }) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final avatarUrl = user?.avatarUrl != null
        ? AppConfig.sanitizeImageUrl(user!.avatarUrl)
        : null;
    final userName = user?.name ?? 'Mess User';
    final userEmail = user?.email ?? 'user@messmax.com';
    final userInitials = user?.initials ?? 'M';

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        12,
        14,
        12 + (bottomPadding > 0 ? bottomPadding : 4),
      ),
      decoration: const BoxDecoration(
        color: AppColors.paperRaised,
        border: Border(top: BorderSide(color: AppColors.paperLine)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        userInitials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      roleSubtitle,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandDark,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
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
            onPressed: () async {
              await context.read<AuthCubit>().logout();
            },
            icon: const Icon(
              Icons.logout_rounded,
              color: AppColors.inkFaded,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
