import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../ads/presentation/screens/my_ads_screen.dart';
import '../../../bazar_schedule/presentation/screens/bazar_schedule_screen.dart';
import '../../../members/presentation/screens/members_screen.dart';
import '../../../mess/presentation/screens/messes_screen.dart';
import '../../../mess/presentation/screens/mess_detail_screen.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../main/presentation/screens/main_shell_screen.dart';
import '../../../profile/presentation/screens/account_screen.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import '../../../members/presentation/cubit/member_cubit.dart';
import '../../../members/presentation/cubit/member_state.dart';
import '../../../bazar_schedule/presentation/cubit/bazar_schedule_cubit.dart';
import '../../../bazar_schedule/presentation/cubit/bazar_schedule_state.dart';
import '../../../mess/presentation/cubit/mess_cubit.dart';
import '../../../mess/presentation/cubit/mess_state.dart';

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

    // Dashboard is only available inside MainShell's MultiBlocProvider.
    // On standalone routes (MembersScreen, MessDetailScreen, etc.) there is no DashboardCubit above us,
    // so we degrade gracefully: header falls back to Members/Mess cubit and body tiles still render.
    DashboardState? dashboardState;
    try {
      dashboardState = context.watch<DashboardCubit>().state;
    } catch (_) {
      dashboardState = null;
    }

    final user = authState is AuthAuthenticated ? authState.user : null;
    final dashboard = dashboardState is DashboardLoaded
        ? dashboardState.dashboard
        : null;
    var activeMess = dashboard?.activeMess;
    final myMesses = dashboard?.myMesses ?? [];

    // Fallback for standalone routes: synthesize activeMess from whatever cubit is available
    // so the "Green View" card / header doesn't disappear (the bug you reported with screenshot).
    String? fallbackMessName;
    if (activeMess == null) {
      try {
        final ms = context.watch<MemberCubit>().state;
        if (ms is MemberLoaded) {
          fallbackMessName = ms.response.messName;
        }
      } catch (_) {}
      if (fallbackMessName == null || fallbackMessName.isEmpty) {
        try {
          final ms = context.watch<MessCubit>().state;
          if (ms is MessDetailLoaded) {
            fallbackMessName = ms.detail.mess.name;
          } else if (ms is MessSheetLoaded) {
            final m = ms.sheet['mess'] as Map<String, dynamic>?;
            fallbackMessName = m?['name'] as String?;
          }
        } catch (_) {}
      }
      if (fallbackMessName == null || fallbackMessName.isEmpty) {
        try {
          final bs = context.watch<BazarScheduleCubit>().state;
          if (bs is BazarScheduleLoaded) {
            fallbackMessName = bs.schedule.mess.name;
          }
        } catch (_) {}
      }
    }

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
                  // Show active mess even when we only have a fallback (Members/Mess route)
                  if (activeMess != null)
                    _drawerTile(
                      id: 'current_mess',
                      icon: Icons.grid_view_rounded,
                      title: activeMess.name,
                      subtitle: 'Monthly sheet & daily meals',
                      context: context,
                    )
                  else if (fallbackMessName != null &&
                      fallbackMessName.isNotEmpty)
                    _drawerTile(
                      id: 'current_mess',
                      icon: Icons.grid_view_rounded,
                      title: fallbackMessName,
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
    // This header is built inside Drawer.build's context, so it sees whatever cubits
    // are above the Scaffold that owns the drawer — not necessarily DashboardCubit.
    // On routes like Members/MessDetail the drawer is hosted above a different BlocProvider,
    // so we watch whatever is available and fall back to a static label instead of hiding.
    DashboardState? dashboardState;
    try {
      dashboardState = context.watch<DashboardCubit>().state;
    } catch (_) {
      dashboardState = null;
    }
    final activeMess = dashboardState is DashboardLoaded
        ? (dashboardState).dashboard.activeMess
        : null;

    String headerMessName = activeMess?.name ?? '';
    String headerMessCode = activeMess?.code ?? '';
    if (headerMessName.isEmpty) {
      try {
        final memberCubitState = context.watch<MemberCubit>().state;
        if (memberCubitState is MemberLoaded) {
          headerMessName = memberCubitState.response.messName;
          headerMessCode = memberCubitState.response.messCode;
          if (headerMessName.isEmpty) headerMessName = 'Mess Members';
        }
      } catch (_) {}
      if (headerMessName.isEmpty) {
        try {
          final messCubitState = context.watch<MessCubit>().state;
          if (messCubitState is MessDetailLoaded) {
            headerMessName = messCubitState.detail.mess.name;
            headerMessCode =
                '#MX-${messCubitState.detail.mess.id.toString().padLeft(4, '0')}';
          } else if (messCubitState is MessSheetLoaded) {
            final m = messCubitState.sheet['mess'] as Map<String, dynamic>?;
            headerMessName = m?['name'] as String? ?? '';
            final mid = (m?['id'] is int)
                ? m!['id'] as int
                : int.tryParse('${m?['id'] ?? ''}') ?? 0;
            headerMessCode = mid != 0
                ? '#MX-${mid.toString().padLeft(4, '0')}'
                : '';
            if (headerMessName.isEmpty &&
                messCubitState.sheet['month'] != null) {
              headerMessName = 'Monthly Sheet';
            }
          }
        } catch (_) {}
      }
      if (headerMessName.isEmpty) {
        try {
          final bs = context.watch<BazarScheduleCubit>().state;
          if (bs is BazarScheduleLoaded) {
            headerMessName = bs.schedule.mess.name;
            headerMessCode = bs.schedule.mess.code.isNotEmpty
                ? bs.schedule.mess.code
                : '#MX-${bs.schedule.mess.id.toString().padLeft(4, '0')}';
          }
        } catch (_) {}
      }
    }
    // Final fallback — never hide the header completely (that's the bug you reported)
    if (headerMessName.isEmpty) headerMessName = 'MessMax';
    if (headerMessCode.isEmpty) headerMessCode = '—';
    final messName = headerMessName;
    final messCode = headerMessCode;
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
          // For current mess drill-down: open detail with real mess id.
          // Works from any route — falls back to Members/Mess cubit when DashboardCubit isn't above us.
          if (id == 'current_mess') {
            int? messId;
            try {
              final st = context.read<DashboardCubit>().state;
              final a = st is DashboardLoaded
                  ? (st).dashboard.activeMess
                  : null;
              messId = a?.id;
            } catch (_) {}
            if (messId == null) {
              try {
                final ms = context.read<MemberCubit>().state;
                if (ms is MemberLoaded) messId = ms.response.messId;
              } catch (_) {}
            }
            if (messId == null) {
              try {
                final ms = context.read<MessCubit>().state;
                if (ms is MessDetailLoaded) {
                  messId = ms.detail.mess.id;
                } else if (ms is MessSheetLoaded) {
                  final m = ms.sheet['mess'] as Map<String, dynamic>?;
                  messId = (m?['id'] is int)
                      ? m!['id'] as int
                      : int.tryParse('${m?['id'] ?? ''}');
                }
              } catch (_) {}
            }
            if (messId == null) {
              try {
                final bs = context.read<BazarScheduleCubit>().state;
                if (bs is BazarScheduleLoaded) {
                  messId = bs.schedule.mess.id;
                }
              } catch (_) {}
            }
            Navigator.pop(context);
            if (messId != null && messId != 0) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MessDetailScreen(messId: messId!),
                ),
              );
            }
            return;
          }
          Navigator.pop(context); // Close drawer
          if (id == 'account') {
            if (activeSection != 'account') {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AccountScreen()));
            }
          } else if (id == 'my_ads') {
            if (activeSection != 'my_ads') {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const MyAdsScreen()));
            }
          } else if (id == 'bazar_schedule' || id == 'mess_bazar') {
            if (activeSection != 'bazar_schedule' && activeSection != 'mess_bazar') {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BazarScheduleScreen()),
              );
            }
          } else if (id == 'members') {
            if (activeSection != 'members') {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const MembersScreen()));
            }
          } else if (id == 'messes') {
            if (activeSection != 'messes') {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const MessesScreen()));
            }
          } else if (id == 'find_mess') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MainShellScreen()),
            );
            MainShellScope.of(context)?.selectTab(0);
          } else if (id == 'dashboard') {
            // Overview should always land on the Dashboard
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).popUntil((route) => route.isFirst);
              final scope = MainShellScope.of(context);
              scope?.selectTab(0);
            }
            // If already inside MainShell (no pop needed), just closing drawer is enough.
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
              final rootNav = Navigator.of(context, rootNavigator: true);
              Navigator.of(context).pop();
              await context.read<AuthCubit>().logout();
              rootNav.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MainShellScreen()),
                (_) => false,
              );
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
