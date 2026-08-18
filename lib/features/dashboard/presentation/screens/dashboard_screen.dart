import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_menu_button.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import '../../data/models/dashboard_model.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../main/presentation/screens/main_shell_screen.dart';
import '../../../mess/presentation/screens/mess_detail_screen.dart';
import '../../../mess/presentation/screens/mess_sheet_screen.dart';
import '../../../bazar_schedule/presentation/screens/bazar_schedule_screen.dart';
import '../widgets/mess_drawer.dart';
import 'dashboard_notifications_screen.dart';
import '../cubit/notification_cubit.dart';
import '../cubit/notification_state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DashboardCubit()..loadDashboard(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _activeSection = 'dashboard';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.paper,
      drawer: MessDrawer(
        activeSection: _activeSection,
        onSectionSelected: (section) {
          setState(() => _activeSection = section);
        },
      ),
      appBar: AppBar(
        backgroundColor: AppColors.paperRaised,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: AppMenuButton(
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            final activeMess = state is DashboardLoaded
                ? state.dashboard.activeMess
                : null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeMess?.name ?? 'MessMax Console',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Manager Console • ${activeMess?.code ?? "#MX-8921"}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.inkFaded,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: BlocBuilder<NotificationCubit, NotificationState>(
                builder: (context, notifState) {
                  return BlocBuilder<DashboardCubit, DashboardState>(
                    builder: (context, state) {
                      final notifUnread = notifState is NotificationLoaded
                          ? notifState.unreadCount
                          : 0;
                      final pendingCount = state is DashboardLoaded
                          ? state.dashboard.pendingRequests.total
                          : 0;
                      final badgeCount = notifUnread > 0
                          ? notifUnread
                          : pendingCount;

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const DashboardNotificationsScreen(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.paper,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.paperLine,
                                  ),
                                ),
                                child: Center(
                                  child: SvgPicture.asset(
                                    'assets/icons/bell.svg',
                                    width: 18,
                                    height: 18,
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.ink,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (badgeCount > 0)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(3.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFA02626),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.paperRaised,
                                    width: 1.5,
                                  ),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 15,
                                  minHeight: 15,
                                ),
                                child: Text(
                                  '$badgeCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is AuthLoading) {
            return const SafeArea(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.brandDark),
              ),
            );
          }
          if (authState is! AuthAuthenticated) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.paperRaised,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.paperLine),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.brandSoft,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.brandDark.withValues(
                                  alpha: 0.12,
                                ),
                              ),
                            ),
                            child: const Icon(
                              Icons.lock_rounded,
                              color: AppColors.brandDark,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Sign in required',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Your mess dashboard is only available after you sign in. No guest data is shown.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.inkFaded,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.login_rounded, size: 18),
                              label: const Text(
                                'Go to Login',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.brandDark,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const MainShellScreen(initialTab: 0),
                            ),
                            (_) => false,
                          );
                        },
                        child: const Text(
                          'Back to Home',
                          style: TextStyle(
                            color: AppColors.brandDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return SafeArea(
            child: BlocBuilder<DashboardCubit, DashboardState>(
              builder: (context, state) {
                if (state is DashboardLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.brandDark,
                    ),
                  );
                }

                if (state is DashboardError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: AppColors.accentSoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.wifi_off_rounded,
                              color: AppColors.accentDark,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Unable to load dashboard',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.inkFaded,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () =>
                                context.read<DashboardCubit>().loadDashboard(),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Try Again'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.brandDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is DashboardLoaded) {
                  final dashboard = state.dashboard;

                  if (!dashboard.hasMess) {
                    return RefreshIndicator(
                      color: AppColors.brandDark,
                      onRefresh: () =>
                          context.read<DashboardCubit>().loadDashboard(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.brandSoft,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Icon(
                                  Icons.apartment_rounded,
                                  color: AppColors.brandDark,
                                  size: 48,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'No Mess Joined Yet',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Create your first mess or ask your manager for an invite link to start tracking daily meals and expenses.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.inkFaded,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Create Mess coming soon'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add_rounded, size: 20),
                                label: const Text('Create New Mess'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.brandDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final activeMess = dashboard.activeMess;
                  final summary = dashboard.summaryStats;
                  final stats = dashboard.ledgerStats;
                  final pending = dashboard.pendingRequests;

                  return RefreshIndicator(
                    color: AppColors.brandDark,
                    onRefresh: () =>
                        context.read<DashboardCubit>().loadDashboard(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- 1. HERO OVERVIEW BANNER CARD ---
                          _buildHeroOverviewCard(context, summary, activeMess),
                          const SizedBox(height: 20),

                          // --- 2. MONTHLY LEDGER STATS ---
                          _buildSectionHeader(
                            Icons.insights_rounded,
                            'MONTHLY LEDGER STATS',
                            actionLabel: activeMess?.currentMonthId != null ? 'View Sheet' : null,
                            onActionTap: activeMess?.currentMonthId != null
                                ? () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => MessSheetScreen(
                                          messId: activeMess!.id,
                                          monthId: activeMess.currentMonthId!,
                                          initialTab: 1,
                                        ),
                                      ),
                                    )
                                : null,
                          ),
                          const SizedBox(height: 10),
                          _buildLedgerGrid(context, stats, activeMess),
                          const SizedBox(height: 22),

                          // --- 3. PENDING REQUESTS ALERT BANNER & LIST ---
                          if (pending.total > 0) ...[
                            _buildPendingApprovalBanner(context, pending),
                            const SizedBox(height: 14),
                          ],

                          if (dashboard.pendingItems.isNotEmpty) ...[
                            _buildSectionHeader(
                              Icons.pending_actions_rounded,
                              'PENDING MEAL & GUEST REQUESTS',
                              iconColor: AppColors.accentDark,
                              actionLabel: 'Review All',
                              onActionTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const DashboardNotificationsScreen(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildPendingItemsCard(context, dashboard.pendingItems),
                            const SizedBox(height: 22),
                          ],

                          // --- 4. BAZAR SHOPPING DUTY SCHEDULE ---
                          if (dashboard.bazarDuties.isNotEmpty) ...[
                            _buildSectionHeader(
                              Icons.shopping_basket_outlined,
                              'BAZAR SHOPPING DUTY SCHEDULE',
                              iconColor: const Color(0xFF0F9F59),
                              actionLabel: activeMess != null ? 'Full Schedule' : null,
                              onActionTap: activeMess != null
                                  ? () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => BazarScheduleScreen(
                                            messId: activeMess.id,
                                          ),
                                        ),
                                      )
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            _buildBazarDutyCard(context, dashboard.bazarDuties, activeMess),
                            const SizedBox(height: 22),
                          ],

                          // --- 5. TODAY'S MEAL SHEET TEASER ---
                          if (dashboard.dailySheetTeaser.isNotEmpty) ...[
                            _buildSectionHeader(
                              Icons.calendar_view_day_rounded,
                              'TODAY\'S MEAL SHEET TEASER',
                              actionLabel: activeMess?.currentMonthId != null ? 'Full Sheet' : null,
                              onActionTap: activeMess?.currentMonthId != null
                                  ? () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => MessSheetScreen(
                                            messId: activeMess!.id,
                                            monthId: activeMess.currentMonthId!,
                                            initialTab: 0,
                                          ),
                                        ),
                                      )
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            _buildDailyMealSheetCard(
                              context,
                              dashboard.dailySheetTeaser,
                              activeMess,
                            ),
                            const SizedBox(height: 22),
                          ],

                          // --- 6. MANAGED & MEMBER MESSES GRID ---
                          if (dashboard.myMesses.isNotEmpty) ...[
                            _buildSectionHeader(
                              Icons.apartment_rounded,
                              'YOUR MANAGED & MEMBER MESSES (${dashboard.myMesses.length})',
                            ),
                            const SizedBox(height: 10),
                            _buildMyMessesGrid(
                              context,
                              dashboard.myMesses,
                              activeMess,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
    IconData icon,
    String title, {
    Color iconColor = AppColors.brandDark,
    String? actionLabel,
    VoidCallback? onActionTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 15, color: iconColor),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: AppColors.inkFaded,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        if (actionLabel != null && onActionTap != null)
          InkWell(
            onTap: onActionTap,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios_rounded, size: 10, color: iconColor),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // --- 1. HERO OVERVIEW BANNER CARD ---
  Widget _buildHeroOverviewCard(
    BuildContext context,
    SummaryStatsModel summary,
    ActiveMessModel? activeMess,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B303B), Color(0xFF0F222D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B303B).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: activeMess != null
              ? () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MessDetailScreen(messId: activeMess.id),
                  ),
                )
              : null,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  activeMess?.name ?? 'Mess Console',
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE85D04),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  activeMess?.code ?? 'CODE',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                activeMess?.location.isNotEmpty == true
                                    ? activeMess!.location
                                    : 'Dhaka',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: activeMess != null && activeMess.currentMonthId != null
                          ? () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MessSheetScreen(
                                  messId: activeMess.id,
                                  monthId: activeMess.currentMonthId!,
                                  initialTab: 0,
                                ),
                              ),
                            )
                          : (activeMess != null
                              ? () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MessDetailScreen(messId: activeMess.id),
                                  ),
                                )
                              : null),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Open Sheet',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.view_comfortable_outlined,
                              size: 13,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _heroGlassChip(
                          label: 'MESSES',
                          val: '${summary.totalMesses}',
                          sub: '${summary.ownedMesses} owned',
                          onTap: activeMess != null
                              ? () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => MessDetailScreen(messId: activeMess.id),
                                    ),
                                  )
                              : null,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      Expanded(
                        child: _heroGlassChip(
                          label: 'MEMBERS',
                          val: '${summary.totalMembers}',
                          sub: 'Active',
                          onTap: activeMess != null
                              ? () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => MessDetailScreen(messId: activeMess.id),
                                    ),
                                  )
                              : null,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      Expanded(
                        child: _heroGlassChip(
                          label: 'CURRENT BAZAR',
                          val: '৳${summary.currentBazar.toInt()}',
                          sub: 'Spent',
                          onTap: activeMess != null && activeMess.currentMonthId != null
                              ? () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => MessSheetScreen(
                                        messId: activeMess.id,
                                        monthId: activeMess.currentMonthId!,
                                        initialTab: 0,
                                      ),
                                    ),
                                  )
                              : null,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      Expanded(
                        child: _heroGlassChip(
                          label: 'MEALS',
                          val: '${summary.currentMeals.toInt()}',
                          sub: 'Total',
                          onTap: activeMess != null && activeMess.currentMonthId != null
                              ? () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => MessSheetScreen(
                                        messId: activeMess.id,
                                        monthId: activeMess.currentMonthId!,
                                        initialTab: 0,
                                      ),
                                    ),
                                  )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroGlassChip({
    required String label,
    required String val,
    required String sub,
    VoidCallback? onTap,
  }) {
    final content = Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w900,
            color: Colors.white.withValues(alpha: 0.6),
            letterSpacing: 0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          sub,
          style: TextStyle(
            fontSize: 9,
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: content,
        ),
      ),
    );
  }

  // --- 2. LEDGER GRID STATS ---
  Widget _buildLedgerGrid(
    BuildContext context,
    LedgerStatsModel stats,
    ActiveMessModel? activeMess,
  ) {
    final totalMeals = stats.totalMeals.toInt();
    final totalBazar = stats.totalBazar.toInt();
    final mealRate = stats.mealRate;
    final totalDeposits = stats.totalDeposits.toInt();
    final restMoney = stats.restMoney.toInt();

    return GridView.count(
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.42,
      children: [
        _statTile(
          icon: Icons.restaurant_rounded,
          iconColor: AppColors.brandDark,
          bgColor: AppColors.brandSoft,
          title: 'Total Meals',
          value: '$totalMeals',
          subtitle: 'Today: ${stats.todayMeals} meals',
          onTap: activeMess?.currentMonthId != null
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MessSheetScreen(
                        messId: activeMess!.id,
                        monthId: activeMess.currentMonthId!,
                        initialTab: 0,
                      ),
                    ),
                  )
              : null,
        ),
        _statTile(
          icon: Icons.shopping_bag_rounded,
          iconColor: const Color(0xFF0F9F59),
          bgColor: const Color(0xFFE6F4EA),
          title: 'Total Bazar',
          value: '$totalBazar ৳',
          subtitle: 'Current month spend',
          onTap: activeMess?.currentMonthId != null
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MessSheetScreen(
                        messId: activeMess!.id,
                        monthId: activeMess.currentMonthId!,
                        initialTab: 0,
                      ),
                    ),
                  )
              : null,
        ),
        _statTile(
          icon: Icons.analytics_rounded,
          iconColor: AppColors.accentDark,
          bgColor: AppColors.accentSoft,
          title: 'Current Rate',
          value: '$mealRate ৳',
          subtitle: 'Calculated per meal',
          onTap: activeMess?.currentMonthId != null
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MessSheetScreen(
                        messId: activeMess!.id,
                        monthId: activeMess.currentMonthId!,
                        initialTab: 1,
                      ),
                    ),
                  )
              : null,
        ),
        _statTile(
          icon: Icons.account_balance_wallet_rounded,
          iconColor: const Color(0xFF1A73E8),
          bgColor: const Color(0xFFE8F0FE),
          title: 'Cash Deposit',
          value: '$totalDeposits ৳',
          subtitle: 'Rest: +$restMoney ৳',
          onTap: activeMess?.currentMonthId != null
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MessSheetScreen(
                        messId: activeMess!.id,
                        monthId: activeMess.currentMonthId!,
                        initialTab: 2,
                      ),
                    ),
                  )
              : null,
        ),
      ],
    );
  }

  Widget _statTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String value,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.paperLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 18, color: iconColor),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkFaded,
                          ),
                        ),
                        if (onTap != null) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 9,
                            color: AppColors.inkFaded,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.inkFaded,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 3. PENDING REQUESTS ALERT BANNER ---
  Widget _buildPendingApprovalBanner(
    BuildContext context,
    PendingRequestsModel pending,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const DashboardNotificationsScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pending_actions_rounded,
                    color: AppColors.accentDark,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${pending.total} Pending Requests Awaiting Review',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${pending.mealOffCount} Meal Off & ${pending.guestCount} Guest requests awaiting manager approval',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.inkFaded,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: AppColors.accentDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingItemsCard(
    BuildContext context,
    List<PendingItemModel> items,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.paperLine),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.paperLine),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DashboardNotificationsScreen(),
                    ),
                  );
                },
                borderRadius: i == 0
                    ? const BorderRadius.vertical(top: Radius.circular(18))
                    : i == items.length - 1
                        ? const BorderRadius.vertical(bottom: Radius.circular(18))
                        : BorderRadius.zero,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: items[i].type == 'guest_meal'
                              ? AppColors.brandSoft
                              : const Color(0xFFFDF2F2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          items[i].type == 'guest_meal'
                              ? Icons.person_add_outlined
                              : Icons.event_busy_outlined,
                          size: 20,
                          color: items[i].type == 'guest_meal'
                              ? AppColors.brandDark
                              : const Color(0xFFA02626),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              items[i].title,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              items[i].subtitle,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.inkFaded,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: items[i].type == 'guest_meal'
                              ? AppColors.brandDark
                              : const Color(0xFFA02626),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          items[i].status.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: AppColors.inkFaded,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- 4. BAZAR DUTY SCHEDULE LIST CARD ---
  Widget _buildBazarDutyCard(
    BuildContext context,
    List<BazarDutyItemModel> duties,
    ActiveMessModel? activeMess,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.paperLine),
      ),
      child: Column(
        children: [
          for (int i = 0; i < duties.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.paperLine),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: activeMess != null
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BazarScheduleScreen(
                              messId: activeMess.id,
                            ),
                          ),
                        )
                    : null,
                borderRadius: i == 0
                    ? const BorderRadius.vertical(top: Radius.circular(18))
                    : i == duties.length - 1
                        ? const BorderRadius.vertical(bottom: Radius.circular(18))
                        : BorderRadius.zero,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: duties[i].isToday
                              ? const Color(0xFFE6F4EA)
                              : AppColors.paper,
                          borderRadius: BorderRadius.circular(10),
                          border: duties[i].isToday
                              ? null
                              : Border.all(color: AppColors.paperLine),
                        ),
                        child: Icon(
                          Icons.shopping_basket_outlined,
                          size: 20,
                          color: duties[i].isToday
                              ? const Color(0xFF0F9F59)
                              : AppColors.inkSoft,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  duties[i].memberName,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                                if (duties[i].isToday) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0F9F59),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${duties[i].messName} • Day ${duties[i].day}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.inkFaded,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: duties[i].isToday
                              ? const Color(0xFF0F9F59)
                              : AppColors.paperLine,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          duties[i].dateLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: duties[i].isToday
                                ? Colors.white
                                : AppColors.inkSoft,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: AppColors.inkFaded,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- 5. TODAY'S MEAL SHEET TEASER CARD ---
  Widget _buildDailyMealSheetCard(
    BuildContext context,
    List<DailyMemberMealModel> teaser,
    ActiveMessModel? activeMess,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.paperLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: activeMess?.currentMonthId != null
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MessSheetScreen(
                        messId: activeMess!.id,
                        monthId: activeMess.currentMonthId!,
                        initialTab: 0,
                      ),
                    ),
                  )
              : null,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.paperLine)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MEMBER NAME',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.inkFaded,
                      ),
                    ),
                    Text(
                      'B  /  L  /  D',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.inkFaded,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'TOTAL',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.inkFaded,
                      ),
                    ),
                  ],
                ),
              ),
              for (var i = 0; i < teaser.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.paperLine),
                _memberMealRow(teaser[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _memberMealRow(DailyMemberMealModel item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  item.room,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.inkFaded,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _mealPill(item.b),
              const SizedBox(width: 6),
              _mealPill(item.l),
              const SizedBox(width: 6),
              _mealPill(item.d),
            ],
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 32,
            child: Text(
              item.total.toStringAsFixed(1),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.brandDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mealPill(int val) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: val > 0 ? AppColors.brandSoft : AppColors.paper,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: val > 0 ? AppColors.brandDark : AppColors.paperLine,
        ),
      ),
      child: Text(
        '$val',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: val > 0 ? AppColors.brandDark : AppColors.inkFaded,
        ),
      ),
    );
  }

  // --- 6. YOUR MANAGED & MEMBER MESSES GRID ---
  Widget _buildMyMessesGrid(
    BuildContext context,
    List<MyMessModel> messes,
    ActiveMessModel? activeMess,
  ) {
    return Column(
      children: [
        for (int i = 0; i < messes.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MessDetailScreen(messId: messes[i].id),
                ),
              ),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.paperRaised,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: messes[i].id == activeMess?.id
                        ? AppColors.brandDark
                        : AppColors.paperLine,
                    width: messes[i].id == activeMess?.id ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'NO. ${strPad(i + 1)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppColors.inkFaded,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.paper,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.paperLine),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.people_outline_rounded,
                                size: 13,
                                color: AppColors.inkSoft,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${messes[i].membersCount} Members',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            messes[i].name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: messes[i].isManager
                                ? AppColors.brandDark
                                : AppColors.paperLine,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            messes[i].displayRoleLabel.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: messes[i].isManager
                                  ? Colors.white
                                  : AppColors.inkSoft,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (messes[i].location.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.brandDark,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            messes[i].location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.inkFaded,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (messes[i].activeMonthLabel != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.paperLine),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Active Month',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.inkFaded,
                                  ),
                                ),
                                Text(
                                  messes[i].activeMonthLabel!,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Bazar / Meals',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.inkFaded,
                                  ),
                                ),
                                Text(
                                  '৳${messes[i].activeMonthBazar.toInt()} • ${messes[i].activeMonthMeals.toInt()} meals',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.brandDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String strPad(int val) {
    return val < 10 ? '0$val' : '$val';
  }
}
