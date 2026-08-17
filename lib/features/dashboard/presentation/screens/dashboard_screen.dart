import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import '../../data/models/dashboard_model.dart';
import '../widgets/mess_drawer.dart';

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

  void _showMessDetailsModal(BuildContext context, ActiveMessModel activeMess) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: const BoxDecoration(
          color: AppColors.paperRaised,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.paperLine,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.apartment_rounded, color: AppColors.brandDark, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeMess.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Join Code: ${activeMess.code}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    activeMess.role.toUpperCase(),
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
            const SizedBox(height: 20),
            const Divider(color: AppColors.paperLine),
            const SizedBox(height: 14),
            _modalDetailRow(Icons.map_rounded, 'Location', activeMess.location.isNotEmpty ? activeMess.location : 'Dhaka'),
            const SizedBox(height: 12),
            _modalDetailRow(Icons.group_rounded, 'Total Members', '${activeMess.membersCount} Active Members'),
            const SizedBox(height: 12),
            _modalDetailRow(Icons.event_seat_rounded, 'Open Seat Ads', '${activeMess.seatsAvailable} Seats Available'),
            const SizedBox(height: 12),
            _modalDetailRow(
              Icons.verified_user_rounded,
              'Manager Permissions',
              activeMess.isManager ? 'Full Manager & Ledger Access' : 'Member View-Only Access',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modalDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.brandDark),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.inkFaded),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
          ],
        ),
      ],
    );
  }

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
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppColors.ink, size: 24),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            final activeMess = state is DashboardLoaded ? state.dashboard.activeMess : null;
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
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.ink, size: 22),
            onPressed: () => context.read<DashboardCubit>().loadDashboard(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.brandDark),
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
                        child: const Icon(Icons.wifi_off_rounded, color: AppColors.accentDark, size: 36),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Unable to load dashboard',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: AppColors.inkFaded),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () => context.read<DashboardCubit>().loadDashboard(),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Try Again'),
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
                  onRefresh: () => context.read<DashboardCubit>().loadDashboard(),
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
                            child: const Icon(Icons.apartment_rounded, color: AppColors.brandDark, size: 48),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No Mess Joined Yet',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.ink),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Create your first mess or ask your manager for an invite link to start tracking daily meals and expenses.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppColors.inkFaded, height: 1.4),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Create Mess coming soon')),
                              );
                            },
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: const Text('Create New Mess'),
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
                onRefresh: () => context.read<DashboardCubit>().loadDashboard(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- 1. HEADER OVERVIEW BANNER CARD (Clean White) ---
                      _buildOverviewBannerCard(context, summary, activeMess),
                      const SizedBox(height: 18),

                      // --- 2. MAIN LEDGER 4-GRID STATS ---
                      _buildSectionTitle('MONTHLY LEDGER STATS'),
                      const SizedBox(height: 10),
                      _buildLedgerGrid(stats),
                      const SizedBox(height: 20),

                      // --- 3. PENDING REQUESTS ALERT & DETAILED LIST ---
                      if (pending.total > 0) ...[
                        _buildPendingApprovalBanner(pending),
                        const SizedBox(height: 12),
                      ],

                      if (dashboard.pendingItems.isNotEmpty) ...[
                        _buildSectionTitle('PENDING MEAL & GUEST REQUESTS'),
                        const SizedBox(height: 10),
                        _buildPendingItemsCard(dashboard.pendingItems),
                        const SizedBox(height: 20),
                      ],

                      // --- 4. BAZAR DUTY SCHEDULE LIST ---
                      if (dashboard.bazarDuties.isNotEmpty) ...[
                        _buildSectionTitle('BAZAR SHOPPING DUTY SCHEDULE'),
                        const SizedBox(height: 10),
                        _buildBazarDutyCard(dashboard.bazarDuties),
                        const SizedBox(height: 20),
                      ],

                      // --- 5. TODAY'S MEAL SHEET TEASER ---
                      if (dashboard.dailySheetTeaser.isNotEmpty) ...[
                        _buildSectionTitle('TODAY\'S MEAL SHEET TEASER'),
                        const SizedBox(height: 10),
                        _buildDailyMealSheetCard(dashboard.dailySheetTeaser),
                        const SizedBox(height: 20),
                      ],

                      // --- 6. YOUR MANAGED & MEMBER MESSES GRID ---
                      if (dashboard.myMesses.isNotEmpty) ...[
                        _buildSectionTitle('YOUR MANAGED & MEMBER MESSES (${dashboard.myMesses.length})'),
                        const SizedBox(height: 10),
                        _buildMyMessesGrid(context, dashboard.myMesses, activeMess),
                      ],
                    ],
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w900,
        color: AppColors.inkFaded,
        letterSpacing: 0.8,
      ),
    );
  }

  // --- 1. OVERVIEW BANNER CARD ---
  Widget _buildOverviewBannerCard(
    BuildContext context,
    SummaryStatsModel summary,
    ActiveMessModel? activeMess,
  ) {
    return InkWell(
      onTap: activeMess != null ? () => _showMessDetailsModal(context, activeMess) : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.paperRaised,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.paperLine),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.dashboard_outlined,
                  color: AppColors.brandDark,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Mess Console',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandSoft,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.brandDark.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Text(
                            'ACTIVE LEDGER',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: AppColors.brandDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Daily meals, bazar roster & instant settlements',
                      style: TextStyle(fontSize: 11.5, color: AppColors.inkFaded),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.paperLine),
          const SizedBox(height: 14),

          // 4-Grid Mini Summary Stats
          Row(
            children: [
              Expanded(
                child: _miniSummaryChip(
                  label: 'MESSES',
                  val: '${summary.totalMesses}',
                  sub: '(${summary.ownedMesses} owned)',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniSummaryChip(
                  label: 'MEMBERS',
                  val: '${summary.totalMembers}',
                  sub: 'Active',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniSummaryChip(
                  label: 'CURRENT BAZAR',
                  val: '৳${summary.currentBazar.toInt()}',
                  sub: 'Spent',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniSummaryChip(
                  label: 'MEALS',
                  val: '${summary.currentMeals.toInt()}',
                  sub: 'Total',
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _miniSummaryChip({
    required String label,
    required String val,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.paperLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: AppColors.inkFaded,
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
              color: AppColors.ink,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 9.5,
              color: AppColors.inkFaded,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- 2. LEDGER GRID STATS ---
  Widget _buildLedgerGrid(LedgerStatsModel stats) {
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
      childAspectRatio: 1.45,
      children: [
        _statTile(
          icon: Icons.restaurant_rounded,
          iconColor: AppColors.brandDark,
          bgColor: AppColors.brandSoft,
          title: 'Total Meals',
          value: '$totalMeals',
          subtitle: 'Today: ${stats.todayMeals} meals',
        ),
        _statTile(
          icon: Icons.shopping_bag_rounded,
          iconColor: const Color(0xFF0F9F59),
          bgColor: const Color(0xFFE6F4EA),
          title: 'Total Bazar',
          value: '$totalBazar ৳',
          subtitle: 'Current month spend',
        ),
        _statTile(
          icon: Icons.analytics_rounded,
          iconColor: AppColors.accentDark,
          bgColor: AppColors.accentSoft,
          title: 'Current Rate',
          value: '$mealRate ৳',
          subtitle: 'Calculated per meal',
        ),
        _statTile(
          icon: Icons.account_balance_wallet_rounded,
          iconColor: const Color(0xFF1A73E8),
          bgColor: const Color(0xFFE8F0FE),
          title: 'Cash Deposit',
          value: '$totalDeposits ৳',
          subtitle: 'Rest: +$restMoney ৳',
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
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkFaded,
                ),
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
    );
  }

  // --- 3. PENDING REQUESTS ALERT BANNER ---
  Widget _buildPendingApprovalBanner(PendingRequestsModel pending) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
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
                  '${pending.total} Pending Requests',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${pending.mealOffCount} Meal Off & ${pending.guestCount} Guest requests awaiting review',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.inkFaded,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingItemsCard(List<PendingItemModel> items) {
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
            Padding(
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
                      color: AppColors.accentDark,
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
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- 4. BAZAR DUTY SCHEDULE LIST CARD ---
  Widget _buildBazarDutyCard(List<BazarDutyItemModel> duties) {
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
            Padding(
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
                        Text(
                          duties[i].memberName,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
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
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- 5. TODAY'S MEAL SHEET TEASER CARD ---
  Widget _buildDailyMealSheetCard(List<DailyMemberMealModel> teaser) {
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
                  style: const TextStyle(fontSize: 11, color: AppColors.inkFaded),
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
          Container(
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
                        messes[i].roleLabel.toUpperCase(),
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
        ],
      ],
    );
  }

  String strPad(int val) {
    return val < 10 ? '0$val' : '$val';
  }
}
