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
        backgroundColor: AppColors.paper,
        elevation: 0,
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
                  activeMess?.name ?? 'Mess Dashboard',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  activeMess != null ? 'Active Ledger • ${activeMess.code}' : 'Live Mess Management',
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
                        decoration: BoxDecoration(
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
              final stats = dashboard.ledgerStats;
              final pending = dashboard.pendingRequests;

              return RefreshIndicator(
                color: AppColors.brandDark,
                onRefresh: () => context.read<DashboardCubit>().loadDashboard(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMessBannerCard(context, activeMess),
                      const SizedBox(height: 18),
                      _buildSectionTitle('MONTHLY LEDGER STATS'),
                      const SizedBox(height: 10),
                      _buildLedgerGrid(stats),
                      const SizedBox(height: 18),
                      if (pending.total > 0) ...[
                        _buildPendingApprovalCard(context, pending),
                        const SizedBox(height: 20),
                      ],
                      if (dashboard.dailySheetTeaser.isNotEmpty) ...[
                        _buildSectionTitle('TODAY\'S MEAL SHEET TEASER'),
                        const SizedBox(height: 10),
                        _buildDailyMealSheetCard(dashboard.dailySheetTeaser),
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

  Widget _buildMessBannerCard(BuildContext context, ActiveMessModel? activeMess) {
    final messName = activeMess?.name ?? 'My Mess';
    final messCode = activeMess?.code ?? '#MX-0000';
    final location = activeMess?.location.isNotEmpty == true ? activeMess!.location : 'Dhaka';
    final membersCount = activeMess?.membersCount ?? 1;
    final seatsAvailable = activeMess?.seatsAvailable ?? 0;

    return InkWell(
      onTap: activeMess != null ? () => _showMessDetailsModal(context, activeMess) : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        messName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$location • Code: $messCode',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _BannerMiniStat(label: 'MEMBERS', value: '$membersCount Active'),
                  const _BannerDivider(),
                  _BannerMiniStat(label: 'OPEN SEATS', value: '$seatsAvailable Seats'),
                  const _BannerDivider(),
                  const _BannerMiniStat(label: 'STATUS', value: 'Active Month', isHighlight: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildPendingApprovalCard(BuildContext context, PendingRequestsModel pending) {
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
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening Meal Off Requests review')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentDark,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Review', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'MEMBER NAME',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppColors.inkFaded),
                ),
                Text(
                  'B  /  L  /  D',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppColors.inkFaded, letterSpacing: 1),
                ),
                Text(
                  'TOTAL',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppColors.inkFaded),
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
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink),
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
              _mealPill('B', item.b == 1),
              const SizedBox(width: 4),
              _mealPill('L', item.l == 1, isOff: item.isLunchOff),
              const SizedBox(width: 4),
              _mealPill('D', item.d == 1),
            ],
          ),
          const SizedBox(width: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: item.isAllOff
                  ? AppColors.paper
                  : (item.total >= 3 ? const Color(0xFFE6F4EA) : AppColors.brandSoft),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              item.isAllOff ? 'OFF' : '${item.total.toInt()} Meals',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: item.isAllOff
                    ? AppColors.inkFaded
                    : (item.total >= 3 ? const Color(0xFF137333) : AppColors.brandDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mealPill(String label, bool isOn, {bool isOff = false}) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOn
            ? const Color(0xFF137333)
            : (isOff ? AppColors.accent.withValues(alpha: 0.15) : AppColors.paper),
        border: Border.all(
          color: isOn
              ? const Color(0xFF137333)
              : (isOff ? AppColors.accent : AppColors.paperLine),
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: isOn ? Colors.white : (isOff ? AppColors.accentDark : AppColors.inkFaded),
          ),
        ),
      ),
    );
  }
}

class _BannerMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _BannerMiniStat({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.6),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: isHighlight ? const Color(0xFFFFD700) : Colors.white,
          ),
        ),
      ],
    );
  }
}

class _BannerDivider extends StatelessWidget {
  const _BannerDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}
