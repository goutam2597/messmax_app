import 'package:flutter/material.dart';
import '../../../../core/locale/app_translations.dart';
import '../../../../core/utils/bn_digits.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../../data/repositories/mess_repository.dart';
import '../cubit/mess_cubit.dart';
import '../cubit/mess_state.dart';
import '../../../dashboard/presentation/widgets/dash_ui.dart';

class MessSheetScreen extends StatelessWidget {
  final int messId;
  final int monthId;
  final String monthLabel;
  final int initialTab;
  const MessSheetScreen({
    super.key,
    required this.messId,
    required this.monthId,
    this.monthLabel = '',
    this.initialTab = 0,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MessCubit()..loadSheet(messId, monthId),
      child: _SheetView(
        messId: messId,
        monthId: monthId,
        monthLabel: monthLabel,
        initialTab: initialTab,
      ),
    );
  }
}

class _SheetView extends StatefulWidget {
  final int messId;
  final int monthId;
  final String monthLabel;
  final int initialTab;
  const _SheetView({
    required this.messId,
    required this.monthId,
    required this.monthLabel,
    this.initialTab = 0,
  });

  @override
  State<_SheetView> createState() => _SheetViewState();
}

class _SheetViewState extends State<_SheetView>
    with SingleTickerProviderStateMixin {
  final _repo = MessRepository();
  late TabController _tabController;

  // Day filter: 0 = Today, 1 = All, 2 = Upcoming, 3 = Passed
  int _dayFilter = 0;
  final Set<int> _expandedDays = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() =>
      context.read<MessCubit>().loadSheet(widget.messId, widget.monthId);

  double _toD(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  int _toI(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  dynamic _byDay(Map? m, int day) {
    if (m == null) return null;
    if (m.containsKey(day)) return m[day];
    final s = day.toString();
    if (m.containsKey(s)) return m[s];
    return null;
  }

  Map _asMap(dynamic v) => v is Map ? v : <dynamic, dynamic>{};

  Color _hex(String h) {
    try {
      final v = h.replaceAll('#', '');
      return Color(int.parse('FF$v', radix: 16));
    } catch (_) {
      return AppColors.brandDark;
    }
  }

  String _fmtNumber(double val, {bool isCurrency = false}) {
    final str = val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(2);
    return isCurrency ? '৳$str' : str;
  }

  Future<void> _confirmDeleteMonth(BuildContext ctx) async {
    final label = widget.monthLabel.isNotEmpty
        ? widget.monthLabel
        : 'this sheet';
    final ok = await ConfirmDeleteDialog.show(
      ctx,
      title: 'ui.confirm_delete_sheet_title'.tr2,
      itemName: widget.monthLabel,
      message: 'ui.confirm_delete_sheet_message_dynamic'.tr2.replaceAll(
        '{label}',
        label,
      ),
      confirmLabel: 'ui.confirm_delete_sheet_label'.tr2,
      icon: Icons.calendar_month_rounded,
    );
    if (ok != true || !ctx.mounted) return;
    try {
      await _repo.deleteMonth(widget.messId, widget.monthId);
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('ui.sheet_deleted'.tr2.replaceAll('{label}', label)),
        ),
      );
      Navigator.of(ctx).pop(true);
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(
        ctx,
      ).showSnackBar(SnackBar(content: Text(_friendlySheetErr(e))));
    }
  }

  String _friendlySheetErr(Object e) {
    final m = e.toString();
    if (m.contains('404') || m.contains('Not found')) {
      return 'ui.sheet_not_found'.tr2;
    }
    if (m.contains('403') || m.contains('Only manager')) {
      return 'ui.sheet_delete_forbidden'.tr2;
    }
    if (m.contains('Failed to delete')) return 'ui.sheet_delete_failed'.tr2;
    return m.replaceAll('Exception: ', '').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paperRaised,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: const AppBackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.monthLabel.isNotEmpty
                  ? widget.monthLabel
                  : 'ui.sheet_title'.tr2,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
                fontSize: 16,
              ),
            ),
            Text(
              'ui.sheet_subtitle'.tr2,
              style: const TextStyle(fontSize: 11, color: AppColors.inkFaded),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: BlocBuilder<MessCubit, MessState>(
                builder: (c, s) {
                  final canManage = s is MessSheetLoaded
                      ? s.sheet['canManage'] == true
                      : false;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (canManage)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _confirmDeleteMonth(c),
                            borderRadius: BorderRadius.circular(DashUI.rCard),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.dangerSoft.withValues(
                                  alpha: 0.3,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.dangerSoft),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.danger,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (canManage) const SizedBox(width: 6),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _refresh,
                          borderRadius: BorderRadius.circular(DashUI.rCard),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.paper,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.paperLine),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.refresh_rounded,
                                color: AppColors.ink,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: BlocConsumer<MessCubit, MessState>(
        listener: (c, s) {
          if (s is MessSheetLoaded && s.message != null) {
            ScaffoldMessenger.of(c).showSnackBar(
              SnackBar(
                content: Text(s.message!),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is MessLoading) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.brandDark,
              ),
            );
          }
          if (state is MessError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 44,
                      color: AppColors.danger,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.inkFaded,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: Text('ui.try_again'.tr2),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.brandDark,
                        side: const BorderSide(color: AppColors.paperLine),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is! MessSheetLoaded) return const SizedBox.shrink();

          final s = state.sheet;
          final canEdit = s['canEdit'] as bool? ?? false;
          final canManage = s['canManage'] as bool? ?? false;
          final canAddBazar = s['canAddBazar'] as bool? ?? false;
          final members = (s['members'] as List<dynamic>? ?? []);
          final summary = (s['summary'] as List<dynamic>? ?? []);
          final deposits = (s['deposits'] as List<dynamic>? ?? []);
          final monthRaw = _asMap(s['month']);
          final days = _toI(monthRaw['days']) > 0 ? _toI(monthRaw['days']) : 31;
          final startDay = _toI(monthRaw['start_day']) > 0
              ? _toI(monthRaw['start_day'])
              : 1;
          final passedDays = _toI(s['passedDays']) > 0
              ? _toI(s['passedDays'])
              : _toI(monthRaw['passed_days']);
          final todayDay = passedDays > 0 ? passedDays : startDay;

          final mealRate = _toD(s['mealRate']);
          final totalGiven = _toD(s['totalGiven']);
          final restMoney = _toD(s['restMoney']);
          final totalMeals = _toD(s['totalMeals']);
          final extraCost = _toD(s['extraCost'] ?? monthRaw['extra_cost']);

          // Count pending requests
          int pendingCount = 0;
          if (s['pendingOffRequests'] is List) {
            pendingCount += (s['pendingOffRequests'] as List).length;
          }
          if (s['pendingGuestRequests'] is List) {
            pendingCount += (s['pendingGuestRequests'] as List).length;
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Hero Stat Banner
                          _buildHeroStatBanner(
                            mealRate: mealRate,
                            totalGiven: totalGiven,
                            restMoney: restMoney,
                            totalMeals: totalMeals,
                          ),
                          const SizedBox(height: 12),

                          // 2. Role Action Buttons Bar
                          _buildActionShortcuts(
                            sheet: s,
                            canEdit: canEdit,
                            canManage: canManage,
                            members: members,
                            todayDay: todayDay,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverCustomTabBarDelegate(
                  _CustomSegmentedTabBar(
                    controller: _tabController,
                    pendingCount: pendingCount,
                    depositCount: deposits.length,
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Daily Matrix
                _buildDailyLogsTab(
                  startDay: startDay,
                  passedDays: passedDays,
                  todayDay: todayDay,
                  days: days,
                  sheet: s,
                  canEdit: canEdit,
                  canAddBazar: canAddBazar,
                  members: members,
                ),

                // Tab 2: Member Ledger
                _buildMembersTab(
                  members: members,
                  summary: summary,
                  canManage: canManage,
                  extraCost: extraCost,
                  sheet: s,
                ),

                // Tab 3: Deposits Tab
                _buildDepositsTab(
                  deposits: deposits,
                  canManage: canManage,
                  canEdit: canEdit,
                  members: members,
                ),

                // Tab 4: Approvals Tab
                _buildApprovalsTab(sheet: s, canManage: canManage),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // HERO STATS BANNER
  // ==========================================
  Widget _buildHeroStatBanner({
    required double mealRate,
    required double totalGiven,
    required double restMoney,
    required double totalMeals,
  }) {
    final isPositiveBalance = restMoney >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandDark,
        borderRadius: BorderRadius.circular(DashUI.rCard),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandDark.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ui.sheet_meal_rate'.tr2,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ui.sheet_formula'.tr2,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      text: bnDigits(mealRate.toStringAsFixed(2)),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      children: [
                        const TextSpan(
                          text: ' ৳',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                          ),
                        ),
                        TextSpan(
                          text: ' ${'ui.sheet_per_meal'.tr2}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isPositiveBalance
                      ? AppColors.emerald.withValues(alpha: 0.25)
                      : AppColors.danger.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(DashUI.rBtn),
                  border: Border.all(
                    color: isPositiveBalance
                        ? AppColors.emerald.withValues(alpha: 0.5)
                        : AppColors.danger.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'ui.sheet_rest_money'.tr2,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: isPositiveBalance
                            ? const Color(0xFF75F8A9)
                            : const Color(0xFFFF9494),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${isPositiveBalance ? '+' : ''}${_fmtNumber(restMoney, isCurrency: true)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: isPositiveBalance
                            ? const Color(0xFF75F8A9)
                            : const Color(0xFFFF9494),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(DashUI.rTile),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ui.sheet_total_given'.tr2,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white60,
                            ),
                          ),
                          Text(
                            _fmtNumber(totalGiven, isCurrency: true),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 26, color: Colors.white12),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.restaurant_menu_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ui.sheet_total_meals'.tr2,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white60,
                            ),
                          ),
                          Text(
                            totalMeals % 1 == 0
                                ? '${bnDigits(totalMeals.toInt())} ${'ui.sheet_meals_unit'.tr2}'
                                : '${bnDigits(totalMeals.toStringAsFixed(1))} ${'ui.sheet_meals_unit'.tr2}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ACTION SHORTCUTS (Role-Gated)
  // ==========================================
  Widget _buildActionShortcuts({
    required Map sheet,
    required bool canEdit,
    required bool canManage,
    required List<dynamic> members,
    required int todayDay,
  }) {
    if (canManage) {
      return Row(
        children: [
          Expanded(
            child: _buildActionChip(
              icon: Icons.add_circle_outline_rounded,
              label: 'ui.sheet_deposit'.tr2,
              color: AppColors.emerald,
              onTap: () => _showAddDepositModal(members),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionChip(
              icon: Icons.person_add_alt_1_rounded,
              label: 'ui.sheet_guest_meal'.tr2,
              color: AppColors.brandDark,
              onTap: () => _showAddGuestModal(members, todayDay, sheet),
            ),
          ),
        ],
      );
    }

    // Member view actions
    return Row(
      children: [
        Expanded(
          child: _buildActionChip(
            icon: Icons.event_busy_rounded,
            label: 'ui.sheet_request_off'.tr2,
            color: AppColors.ink,
            onTap: () => _showMealOffModal(sheet),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionChip(
            icon: Icons.person_add_rounded,
            label: 'ui.sheet_request_guest'.tr2,
            color: AppColors.brandDark,
            onTap: () => _showGuestRequestModal(sheet),
          ),
        ),
      ],
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isOutlined = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DashUI.rTile),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isOutlined ? AppColors.paperRaised : color,
          borderRadius: BorderRadius.circular(DashUI.rTile),
          border: Border.all(color: isOutlined ? AppColors.paperLine : color),
          boxShadow: isOutlined
              ? null
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isOutlined ? AppColors.ink : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isOutlined ? AppColors.ink : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: DAILY MATRIX & LOGS
  // ==========================================
  Widget _buildDailyLogsTab({
    required int startDay,
    required int passedDays,
    required int todayDay,
    required int days,
    required Map sheet,
    required bool canEdit,
    required bool canAddBazar,
    required List<dynamic> members,
  }) {
    // Generate day lists
    final allDays = <int>[for (int d = startDay; d <= days; d++) d];
    final passedDaysList = <int>[for (int d = startDay; d < passedDays; d++) d];
    final futureDaysList = <int>[
      for (int d = passedDays + 1; d <= days; d++) d,
    ];

    List<int> displayedDays;
    switch (_dayFilter) {
      case 0: // Today
        displayedDays = [todayDay];
        break;
      case 1: // All
        displayedDays = allDays;
        break;
      case 2: // Upcoming
        displayedDays = [todayDay, ...futureDaysList];
        break;
      case 3: // Passed
        displayedDays = passedDaysList.reversed.toList();
        break;
      default:
        displayedDays = allDays;
    }

    return RefreshIndicator(
      color: AppColors.brandDark,
      onRefresh: () async => _refresh(),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 16, 32),
            children: [
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip(
                      'ui.sheet_filter_today'.tr2,
                      0,
                      icon: Icons.wb_sunny_rounded,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      '${'ui.sheet_filter_all'.tr2} (${bnDigits(allDays.length)})',
                      1,
                      icon: Icons.calendar_view_day_rounded,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      '${'ui.sheet_filter_upcoming'.tr2} (${bnDigits(futureDaysList.length)})',
                      2,
                      icon: Icons.arrow_forward_rounded,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      '${'ui.sheet_filter_passed'.tr2} (${bnDigits(passedDaysList.length)})',
                      3,
                      icon: Icons.history_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Start day notification
              if (startDay > 1) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.paperRaised,
                    borderRadius: BorderRadius.circular(DashUI.rBtn),
                    border: Border.all(color: AppColors.paperLine),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: AppColors.inkFaded,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${'ui.sheet_cycle_start'.tr2} ${'ui.sheet_day'.tr2} ${bnDigits(startDay)}. (${bnDigits(startDay - 1)} ${'ui.sheet_days_hidden'.tr2}).',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Render Day Cards
              if (displayedDays.isEmpty) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'ui.sheet_no_days'.tr2,
                      style: const TextStyle(color: AppColors.inkFaded),
                    ),
                  ),
                ),
              ] else ...[
                for (final day in displayedDays)
                  _buildModernDayCard(
                    day: day,
                    sheet: sheet,
                    canEdit: canEdit,
                    canAddBazar: canAddBazar,
                    members: members,
                    isToday: day == todayDay,
                    isPast: day < todayDay,
                    isFuture: day > todayDay,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, int index, {IconData? icon}) {
    final isSelected = _dayFilter == index;
    return InkWell(
      onTap: () => setState(() => _dayFilter = index),
      borderRadius: BorderRadius.circular(DashUI.rBtn),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandDark : AppColors.paperRaised,
          borderRadius: BorderRadius.circular(DashUI.rBtn),
          border: Border.all(
            color: isSelected ? AppColors.brandDark : AppColors.paperLine,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : AppColors.inkFaded,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modern Day Card with Glanceable Summary & Collapsible Details
  Widget _buildModernDayCard({
    required int day,
    required Map sheet,
    required bool canEdit,
    required bool canAddBazar,
    required List<dynamic> members,
    required bool isToday,
    required bool isPast,
    required bool isFuture,
  }) {
    final monthRaw = _asMap(sheet['month']);
    final year = _toI(monthRaw['year']) > 0
        ? _toI(monthRaw['year'])
        : DateTime.now().year;
    final monthNum = _toI(monthRaw['month']) > 0
        ? _toI(monthRaw['month'])
        : DateTime.now().month;
    DateTime date;
    try {
      date = DateTime(year, monthNum, day);
    } catch (_) {
      date = DateTime.now();
    }
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dateStr =
        '${weekDays[date.weekday - 1]}, $day ${monthNames[date.month - 1]}';

    final bazarTotal = _toD(
      _byDay(_asMap(sheet['bazarTotalsByDay']), day) ??
          _byDay(_asMap(sheet['bazars']), day),
    );
    final rawItems = _byDay(_asMap(sheet['bazarItemsByDay']), day);
    final List<dynamic> items = rawItems is List ? rawItems : <dynamic>[];
    final rawReceipts = _byDay(_asMap(sheet['bazarReceiptsMulti']), day);
    final List<dynamic> receipts = rawReceipts is List
        ? rawReceipts
        : <dynamic>[];

    final mealsMap = _asMap(sheet['meals']);
    final mealsBMap = _asMap(sheet['mealsB']);
    final mealsLMap = _asMap(sheet['mealsL']);
    final mealsDMap = _asMap(sheet['mealsD']);
    final dayTotal = _toD(_byDay(_asMap(sheet['rowTotals']), day));
    final guestList = (_byDay(_asMap(sheet['guestByDay']), day) is List)
        ? (_byDay(_asMap(sheet['guestByDay']), day) as List)
        : <dynamic>[];

    final hasPendingReq = () {
      final offReqs = sheet['offReqByDay'];
      if (offReqs is Map &&
          (offReqs[day.toString()] != null || offReqs[day] != null)) {
        return true;
      }
      final myOff = sheet['myOffReqByDay'];
      if (myOff is Map &&
          (myOff[day.toString()] != null || myOff[day] != null)) {
        return true;
      }
      return false;
    }();

    final isExpanded = _expandedDays.contains(day) || isToday;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(DashUI.rCard),
        border: Border.all(
          color: isToday
              ? AppColors.brandDark
              : (isFuture ? AppColors.brandSoft : AppColors.paperLine),
          width: isToday ? 1.8 : 1,
        ),
        boxShadow: isToday
            ? [
                BoxShadow(
                  color: AppColors.brandDark.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row (Tap to toggle expand)
          InkWell(
            onTap: () {
              setState(() {
                if (_expandedDays.contains(day)) {
                  _expandedDays.remove(day);
                } else {
                  _expandedDays.add(day);
                }
              });
            },
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(15),
              bottom: isExpanded ? Radius.zero : const Radius.circular(15),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isToday
                    ? AppColors.brandSoft.withValues(alpha: 0.4)
                    : (isFuture
                          ? AppColors.paper.withValues(alpha: 0.6)
                          : AppColors.paperRaised),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(15),
                  bottom: isExpanded ? Radius.zero : const Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  // Day Badge
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.brandDark
                          : (isFuture ? AppColors.brandSoft : AppColors.paper),
                      borderRadius: BorderRadius.circular(DashUI.rBtn),
                      border: Border.all(
                        color: isToday
                            ? AppColors.brandDark
                            : AppColors.paperLine,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: isToday ? Colors.white : AppColors.ink,
                        ),
                      ),
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
                              dateStr,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                color: isToday
                                    ? AppColors.brandDark
                                    : AppColors.ink,
                              ),
                            ),
                            if (isToday) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.emerald,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'ui.sheet_today_badge'.tr2,
                                  style: const TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                            if (hasPendingReq) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: const Color(0xFFF59E0B),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.hourglass_top_rounded,
                                      size: 9,
                                      color: Color(0xFFD97706),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      AppTranslations.locale == 'bn'
                                          ? 'আবেদন পেন্ডিং'
                                          : 'PENDING REQ',
                                      style: const TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFB45309),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              '${bnDigits(dayTotal % 1 == 0 ? dayTotal.toInt() : dayTotal.toStringAsFixed(1))} ${'ui.sheet_meals_unit'.tr2}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.inkSoft,
                              ),
                            ),
                            if (bazarTotal > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.emeraldSoft,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '৳${bnDigits(bazarTotal.toStringAsFixed(0))} ${'ui.sheet_bazar'.tr2}',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.emerald,
                                  ),
                                ),
                              ),
                            ],
                            if (receipts.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.receipt_long_rounded,
                                size: 13,
                                color: AppColors.brandDark,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Edit / Action button
                  if (canEdit) ...[
                    OutlinedButton.icon(
                      onPressed: () => _openDayEdit(day, members, sheet),
                      icon: const Icon(Icons.edit_outlined, size: 13),
                      label: Text(
                        'ui.sheet_edit'.tr2,
                        style: const TextStyle(fontSize: 11.5),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: const BorderSide(color: AppColors.paperLine),
                      ),
                    ),
                  ] else if (canAddBazar && isToday) ...[
                    FilledButton.icon(
                      onPressed: () =>
                          _openDayEdit(day, members, sheet, bazarOnly: true),
                      icon: const Icon(
                        Icons.shopping_basket_outlined,
                        size: 13,
                      ),
                      label: Text(
                        'ui.sheet_bazar'.tr2,
                        style: const TextStyle(fontSize: 11.5),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandDark,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.inkFaded,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expandable Body Details
          if (isExpanded) ...[
            const Divider(height: 1, color: AppColors.paperLine),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Bazar items breakdown
                  _buildDayBazarBreakdown(
                    bazarTotal: bazarTotal,
                    items: items,
                    receipts: receipts,
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.paperLine),
                  const SizedBox(height: 12),

                  // 2. Member Meals Breakdown
                  _buildDayMealsBreakdown(
                    day: day,
                    sheet: sheet,
                    members: members,
                    mealsMap: mealsMap,
                    mealsBMap: mealsBMap,
                    mealsLMap: mealsLMap,
                    mealsDMap: mealsDMap,
                    guestList: guestList,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDayBazarBreakdown({
    required double bazarTotal,
    required List<dynamic> items,
    required List<dynamic> receipts,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 14,
                  color: AppColors.brandDark,
                ),
                SizedBox(width: 5),
                Text(
                  'BAZAR ENTRIES',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkFaded,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            if (bazarTotal > 0)
              Text(
                '৳${bazarTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (bazarTotal == 0 && items.isEmpty)
          Text(
            'ui.sheet_no_bazar'.tr2,
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.inkFaded,
              fontStyle: FontStyle.italic,
            ),
          )
        else ...[
          for (final it in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.inkFaded,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (it['name'] ?? 'Item').toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  Text(
                    '${it['qty']} × ৳${it['price']} = ৳${(_toD(it['qty']) * _toD(it['price'])).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          if (receipts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final r in receipts)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.brandDark.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          size: 12,
                          color: AppColors.brandDark,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (r['name'] ?? r['original_name'] ?? 'Receipt')
                              .toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandDark,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildDayMealsBreakdown({
    required int day,
    required Map sheet,
    required List<dynamic> members,
    required Map mealsMap,
    required Map mealsBMap,
    required Map mealsLMap,
    required Map mealsDMap,
    required List<dynamic> guestList,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    Icons.restaurant_menu_rounded,
                    size: 14,
                    color: AppColors.brandDark,
                  ),
                  const SizedBox(width: 5),
                  ValueListenableBuilder<int>(
                    valueListenable: AppTranslations.notifier,
                    builder: (context, _, _) => Text(
                      'ui.sheet_tab_logs'.tr2 == 'Daily Log'
                          ? 'MEAL ATTENDANCE'
                          : 'দৈনিক মিল',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.inkFaded,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 78,
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Center(
                      child: ValueListenableBuilder<int>(
                        valueListenable: AppTranslations.notifier,
                        builder: (context, _, _) => Text(
                          AppTranslations.locale == 'bn' ? 'স' : 'B',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.inkFaded,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 22,
                    child: Center(
                      child: ValueListenableBuilder<int>(
                        valueListenable: AppTranslations.notifier,
                        builder: (context, _, _) => Text(
                          AppTranslations.locale == 'bn' ? 'দু' : 'L',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.inkFaded,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 22,
                    child: Center(
                      child: ValueListenableBuilder<int>(
                        valueListenable: AppTranslations.notifier,
                        builder: (context, _, _) => Text(
                          AppTranslations.locale == 'bn' ? 'রা' : 'D',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.inkFaded,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 28,
              child: ValueListenableBuilder<int>(
                valueListenable: AppTranslations.notifier,
                builder: (context, _, _) => Text(
                  'ui.dash_total'.tr2,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.inkFaded,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final m in members) ...[
          Builder(
            builder: (_) {
              final mid = (m['id']).toString();
              final name = (m['name'] ?? 'Member').toString();
              final colorHex = (m['color'] ?? '#3b82f6').toString();
              final count = _toD(
                (mealsMap[mid] is Map
                        ? (mealsMap[mid] as Map)[day.toString()] ??
                              (mealsMap[mid] as Map)[day]
                        : null) ??
                    (mealsMap[mid.toString()] is Map
                        ? (mealsMap[mid.toString()] as Map)[day.toString()]
                        : null),
              );

              dynamic bRaw, lRaw, dRaw;
              if (mealsBMap[mid] is Map) {
                bRaw =
                    (mealsBMap[mid] as Map)[day.toString()] ??
                    (mealsBMap[mid] as Map)[day];
              }
              if (mealsLMap[mid] is Map) {
                lRaw =
                    (mealsLMap[mid] as Map)[day.toString()] ??
                    (mealsLMap[mid] as Map)[day];
              }
              if (mealsDMap[mid] is Map) {
                dRaw =
                    (mealsDMap[mid] as Map)[day.toString()] ??
                    (mealsDMap[mid] as Map)[day];
              }
              final hasParts = bRaw != null || lRaw != null || dRaw != null;
              final isOff = count == 0 && hasParts;

              dynamic memberPendingReq;
              final offReqs = sheet['offReqByDay'];
              if (offReqs is Map) {
                final list = offReqs[day.toString()] ?? offReqs[day];
                if (list is List) {
                  for (final item in list) {
                    final rMemberId =
                        (item['mess_member_id'] ??
                                item['member_id'] ??
                                item['member']?['id'])
                            ?.toString();
                    if (rMemberId == mid) {
                      memberPendingReq = item;
                      break;
                    }
                  }
                }
              }
              if (memberPendingReq == null && sheet['myOffReqByDay'] is Map) {
                final myMemberId = (sheet['myMemberId'])?.toString();
                if (myMemberId == mid) {
                  final myReq =
                      (sheet['myOffReqByDay'] as Map)[day.toString()] ??
                      (sheet['myOffReqByDay'] as Map)[day];
                  if (myReq != null) memberPendingReq = myReq;
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: _hex(colorHex),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'M',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (memberPendingReq != null) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFFF59E0B),
                                ),
                              ),
                              child: Text(
                                '⏳ ${memberPendingReq['label'] ?? (memberPendingReq['is_reenable'] == true ? 'ON Req' : 'OFF Req')}',
                                style: const TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isOff)
                      Container(
                        width: 78,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.dangerSoft,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Text(
                          'OFF',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.danger,
                          ),
                        ),
                      )
                    else if (hasParts)
                      Builder(
                        builder: (_) {
                          bool pendingB = false,
                              pendingL = false,
                              pendingD = false;
                          if (memberPendingReq is Map) {
                            final tb = memberPendingReq['breakfast_off'];
                            final tl = memberPendingReq['lunch_off'];
                            final td = memberPendingReq['dinner_off'];
                            final cb = bRaw != null ? _toD(bRaw) == 0 : false;
                            final cl = lRaw != null ? _toD(lRaw) == 0 : false;
                            final cd = dRaw != null ? _toD(dRaw) == 0 : false;
                            if (tb is bool) pendingB = (tb != cb);
                            if (tl is bool) pendingL = (tl != cl);
                            if (td is bool) pendingD = (td != cd);
                          }
                          Widget pill(double v, bool isPending) {
                            final isZero = v == 0;
                            if (isPending) {
                              return Container(
                                width: 22,
                                height: 22,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFF59E0B),
                                  ),
                                ),
                                child: const Text(
                                  'P',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              );
                            }
                            final s =
                                (v % 1 == 0
                                        ? v.toInt().toString()
                                        : v.toStringAsFixed(1))
                                    .toBnNum();
                            return Container(
                              width: 22,
                              height: 22,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: !isZero
                                    ? AppColors.brandSoft
                                    : AppColors.paper,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: !isZero
                                      ? AppColors.brandDark
                                      : AppColors.paperLine,
                                ),
                              ),
                              child: Text(
                                s,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: !isZero
                                      ? AppColors.brandDark
                                      : AppColors.inkFaded,
                                ),
                              ),
                            );
                          }

                          return SizedBox(
                            width: 78,
                            child: Row(
                              children: [
                                pill(_toD(bRaw), pendingB),
                                const SizedBox(width: 6),
                                pill(_toD(lRaw), pendingL),
                                const SizedBox(width: 6),
                                pill(_toD(dRaw), pendingD),
                              ],
                            ),
                          );
                        },
                      )
                    else
                      SizedBox(
                        width: 78,
                        child: Center(
                          child: Text(
                            (count % 1 == 0
                                    ? count.toInt().toString()
                                    : count.toStringAsFixed(1))
                                .toBnNum(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 14),
                    SizedBox(
                      width: 28,
                      child: Text(
                        (count % 1 == 0
                                ? count.toInt().toString()
                                : count.toStringAsFixed(1))
                            .toBnNum(),
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.brandDark,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],

        // Guests List
        if (guestList.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.brandSoft.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(DashUI.rBtn),
              border: Border.all(
                color: AppColors.brandDark.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 12,
                      color: AppColors.brandDark,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'GUEST MEALS',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                for (final g in guestList)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${g['guest_name'] ?? 'Guest'} .${g['guest_count'] ?? 1} (${(g['slots'] as List?)?.join(' + ') ?? ''})',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ),
                        Text(
                          '+${_toD(g['count']).toStringAsFixed(1).toBnNum()} ${'ui.sheet_meals_unit'.tr2}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandDark,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        Builder(
          builder: (_) {
            final pendingGuests = <dynamic>[];
            final mgm = sheet['myGuestReqByDay'];
            if (mgm is Map) {
              final v = mgm[day.toString()] ?? mgm[day];
              if (v is Map) pendingGuests.add(v);
              if (v is List) pendingGuests.addAll(v);
            }
            if (pendingGuests.isEmpty &&
                sheet['pendingGuestRequests'] is List) {
              for (final r in sheet['pendingGuestRequests'] as List) {
                if (r is Map && _toI(r['day']) == day) pendingGuests.add(r);
              }
            }
            if (pendingGuests.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(DashUI.rBtn),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.hourglass_top_rounded,
                          size: 12,
                          color: Color(0xFFD97706),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'PENDING GUEST',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    for (final pg in pendingGuests)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${pg['is_cancellation'] == true ? 'Cancel: ' : ''}${pg['guest_name'] ?? 'Guest'} x${pg['guest_count'] ?? 1}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFFF59E0B),
                                ),
                              ),
                              child: const Text(
                                'PENDING',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: MEMBERS & LEDGER
  // ==========================================
  Widget _buildMembersTab({
    required List<dynamic> members,
    required List<dynamic> summary,
    required bool canManage,
    required double extraCost,
    required Map sheet,
  }) {
    final memberById = {for (final m in members) (m['id'].toString()): m};
    final extraPerMember = members.isNotEmpty
        ? extraCost / members.length
        : 0.0;

    String fmtBld(dynamic v) {
      if (v == null) return '.';
      final d = _toD(v);
      if (d == 0) return 'OFF';
      return d % 1 == 0 ? d.toInt().toString() : d.toStringAsFixed(1);
    }

    return RefreshIndicator(
      color: AppColors.brandDark,
      onRefresh: () async => _refresh(),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
            children: [
              // Extra shared cost banner
              if (extraCost > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.amberSoft,
                    borderRadius: BorderRadius.circular(DashUI.rTile),
                    border: Border.all(
                      color: AppColors.amber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.receipt_outlined,
                        color: AppColors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Shared Extra Cost: ৳${extraCost.toStringAsFixed(0)} (৳${extraPerMember.toStringAsFixed(1)}/member)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              for (int i = 0; i < summary.length; i++) ...[
                Builder(
                  builder: (_) {
                    final row = summary[i] as Map;
                    final mm = row['member'] is Map
                        ? row['member'] as Map
                        : row;
                    final idStr = (mm['id'] ?? row['member_id'] ?? '')
                        .toString();
                    final memberRaw = memberById[idStr] ?? mm;
                    final name = (memberRaw['name'] ?? mm['name'] ?? 'Member')
                        .toString();
                    final colorHex =
                        (memberRaw['color'] ?? mm['color'] ?? '#3b82f6')
                            .toString();
                    final role =
                        (memberRaw['member_role'] ??
                                mm['member_role'] ??
                                mm['role'] ??
                                'member')
                            .toString();
                    final hasBld =
                        memberRaw['default_breakfast'] != null ||
                        memberRaw['default_lunch'] != null ||
                        memberRaw['default_dinner'] != null;
                    final meals = _toD(row['meals']);
                    final spend = _toD(row['spend']);
                    final given = _toD(row['given']);
                    final balance = _toD(row['balance']);
                    final isPositive = balance >= 0;
                    final mealsStr = meals % 1 == 0
                        ? meals.toInt().toString()
                        : meals.toStringAsFixed(1);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.paperRaised,
                        borderRadius: BorderRadius.circular(DashUI.rCard),
                        border: Border.all(color: AppColors.paperLine),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brandDark.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row: Avatar, Name, Role, Manage Edit
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: _hex(colorHex),
                                  child: Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : 'M',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14.5,
                                            color: AppColors.ink,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: role == 'manager'
                                              ? AppColors.brandSoft
                                              : AppColors.paper,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: role == 'manager'
                                                ? AppColors.brandDark
                                                      .withValues(alpha: 0.15)
                                                : AppColors.paperLine,
                                          ),
                                        ),
                                        child: Text(
                                          role.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w800,
                                            color: role == 'manager'
                                                ? AppColors.brandDark
                                                : AppColors.inkFaded,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (canManage) ...[
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () =>
                                          _showEditMemberModal(memberRaw),
                                      borderRadius: BorderRadius.circular(
                                        DashUI.rCard,
                                      ),
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: AppColors.paper,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.paperLine,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.tune_rounded,
                                            size: 16,
                                            color: AppColors.inkSoft,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // 2. Clear Meals Consumption Banner
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 2,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.paper,
                              borderRadius: BorderRadius.circular(DashUI.rTile),
                              border: Border.all(color: AppColors.paperLine),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandSoft,
                                    borderRadius: BorderRadius.circular(
                                      DashUI.rBtn,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.restaurant_rounded,
                                    size: 16,
                                    color: AppColors.brandDark,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ui.sheet_total_meals_consumed'.tr2,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.inkFaded,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      '${mealsStr.toBnNum()} ${'ui.sheet_meals_unit'.tr2}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.brandDark,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                if (hasBld)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.paperRaised,
                                      borderRadius: BorderRadius.circular(
                                        DashUI.rBtn,
                                      ),
                                      border: Border.all(
                                        color: AppColors.paperLine,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'ui.sheet_daily_default'.tr2,
                                          style: const TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.inkFaded,
                                          ),
                                        ),
                                        Text(
                                          AppTranslations.locale == 'bn'
                                              ? '${fmtBld(memberRaw['default_breakfast']).toBnNum()}? . ${fmtBld(memberRaw['default_lunch']).toBnNum()}?? . ${fmtBld(memberRaw['default_dinner']).toBnNum()}??'
                                              : '${fmtBld(memberRaw['default_breakfast'])}B . ${fmtBld(memberRaw['default_lunch'])}L . ${fmtBld(memberRaw['default_dinner'])}D',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // 3. Financial Metrics Row (Spend, Given, Balance)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 2, 12, 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.paper,
                                      borderRadius: BorderRadius.circular(
                                        DashUI.rBtn,
                                      ),
                                      border: Border.all(
                                        color: AppColors.paperLine,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'ui.sheet_total_spent'.tr2,
                                          style: const TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.inkFaded,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '৳${spend.toStringAsFixed(0).toBnNum()}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.emerald.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        DashUI.rBtn,
                                      ),
                                      border: Border.all(
                                        color: AppColors.emerald.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'ui.sheet_deposited'.tr2,
                                          style: const TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.emerald,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '৳${given.toStringAsFixed(0).toBnNum()}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.emerald,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isPositive
                                          ? AppColors.emerald.withValues(
                                              alpha: 0.12,
                                            )
                                          : AppColors.dangerSoft,
                                      borderRadius: BorderRadius.circular(
                                        DashUI.rBtn,
                                      ),
                                      border: Border.all(
                                        color: isPositive
                                            ? AppColors.emerald.withValues(
                                                alpha: 0.3,
                                              )
                                            : AppColors.danger.withValues(
                                                alpha: 0.3,
                                              ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isPositive
                                              ? 'ui.sheet_refund_bal'.tr2
                                              : 'ui.sheet_due_balance'.tr2,
                                          style: TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w800,
                                            color: isPositive
                                                ? AppColors.emerald
                                                : AppColors.danger,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${isPositive ? '+' : ''}৳${balance.toStringAsFixed(0).toBnNum()}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                            color: isPositive
                                                ? AppColors.emerald
                                                : AppColors.danger,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 3: DEPOSITS
  // ==========================================
  Widget _buildDepositsTab({
    required List<dynamic> deposits,
    required bool canManage,
    required bool canEdit,
    required List<dynamic> members,
  }) {
    double totalDeposits = 0;
    for (final d in deposits) {
      totalDeposits += _toD(d['amount']);
    }

    return RefreshIndicator(
      color: AppColors.brandDark,
      onRefresh: () async => _refresh(),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            children: [
              // Total Collected Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.paperRaised,
                  borderRadius: BorderRadius.circular(DashUI.rCard),
                  border: Border.all(color: AppColors.paperLine),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldSoft,
                        borderRadius: BorderRadius.circular(DashUI.rTile),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: AppColors.emerald,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ui.sheet_total_deposits_collected'.tr2,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.inkFaded,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '৳${totalDeposits.toInt().toBnNum()}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.emerald,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (canManage)
                      FilledButton.icon(
                        onPressed: () => _showAddDepositModal(members),
                        icon: const Icon(Icons.add, size: 16),
                        label: Text('ui.add'.tr2),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brandDark,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 36),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (deposits.isEmpty) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'ui.no_deposits_yet'.tr2,
                      style: const TextStyle(color: AppColors.inkFaded),
                    ),
                  ),
                ),
              ] else ...[
                for (final d in deposits)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.paperRaised,
                      borderRadius: BorderRadius.circular(DashUI.rCard),
                      border: Border.all(color: AppColors.paperLine),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: _hex(
                            (d['member']?['color'] ?? '#3b82f6').toString(),
                          ),
                          child: Text(
                            ((d['member']?['name'] ?? 'M').toString().isNotEmpty
                                ? (d['member']?['name'] ?? 'M')
                                      .toString()[0]
                                      .toUpperCase()
                                : 'M'),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (d['member']?['name'] ?? 'Member').toString(),
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              if (d['note'] != null &&
                                  d['note'].toString().isNotEmpty)
                                Text(
                                  d['note'].toString(),
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
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.emeraldSoft,
                            borderRadius: BorderRadius.circular(DashUI.rBtn),
                          ),
                          child: Text(
                            '৳${_toD(d['amount']).toInt().toBnNum()}',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: AppColors.emerald,
                            ),
                          ),
                        ),
                        if (canEdit && d['id'] != null) ...[
                          const SizedBox(width: 8),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _confirmDeleteDeposit(
                                d['id'] as int,
                                memberName:
                                    (d['member_name'] ??
                                            (d['member'] is Map
                                                ? d['member']['name']
                                                : null))
                                        ?.toString(),
                                amount: _toD(d['amount']),
                              ),
                              borderRadius: BorderRadius.circular(DashUI.rCard),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.dangerSoft,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.danger.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 16,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 4: APPROVALS (Manager & Member Requests)
  // ==========================================
  Widget _buildApprovalsTab({required Map sheet, required bool canManage}) {
    List<dynamic> pendingOff = [];
    if (sheet['pendingOffRequests'] is List) {
      pendingOff = sheet['pendingOffRequests'] as List;
    } else if (sheet['offReqByDay'] is Map) {
      for (final v in (sheet['offReqByDay'] as Map).values) {
        if (v is List) pendingOff.addAll(v);
      }
    }

    List<dynamic> pendingGuest = [];
    if (sheet['pendingGuestRequests'] is List) {
      pendingGuest = sheet['pendingGuestRequests'] as List;
    } else if (sheet['guestReqPending'] is Map) {
      for (final v in (sheet['guestReqPending'] as Map).values) {
        if (v is List) pendingGuest.addAll(v);
      }
    }

    if (pendingOff.isEmpty && pendingGuest.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 48,
                color: AppColors.emerald,
              ),
              const SizedBox(height: 12),
              Text(
                'ui.sheet_all_caught_up'.tr2,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ui.sheet_no_requests'.tr2,
                style: const TextStyle(fontSize: 12, color: AppColors.inkFaded),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
          children: [
            if (pendingOff.isNotEmpty) ...[
              const Text(
                'MEAL OFF REQUESTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkFaded,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              for (final r in pendingOff)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.paperRaised,
                    borderRadius: BorderRadius.circular(DashUI.rCard),
                    border: Border.all(
                      color: AppColors.brandDark.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandDark,
                          borderRadius: BorderRadius.circular(DashUI.rBtn),
                        ),
                        child: Text(
                          'Day ${r['day']}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (r['member_name'] ??
                                      r['member']?['name'] ??
                                      'Member')
                                  .toString(),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              '${r['label'] ?? (r['is_reenable'] == true ? 'Meal ON' : 'Meal OFF')}${r['note'] != null && r['note'].toString().isNotEmpty ? ' . "${r['note']}"' : ''}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (canManage) ...[
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              await _repo.handleMealOff(
                                widget.messId,
                                widget.monthId,
                                r['id'] as int,
                                'deny',
                              );
                              _refresh();
                            },
                            borderRadius: BorderRadius.circular(DashUI.rCard),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.dangerSoft,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.danger.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: AppColors.danger,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              await _repo.handleMealOff(
                                widget.messId,
                                widget.monthId,
                                r['id'] as int,
                                'approve',
                              );
                              _refresh();
                            },
                            borderRadius: BorderRadius.circular(DashUI.rCard),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.emeraldSoft,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.emerald.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: AppColors.emerald,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(DashUI.rBtn),
                            border: Border.all(color: const Color(0xFFF59E0B)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.hourglass_top_rounded,
                                size: 10,
                                color: Color(0xFFD97706),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                AppTranslations.locale == 'bn'
                                    ? 'পেন্ডিং'
                                    : 'Pending',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 16),
            ],

            if (pendingGuest.isNotEmpty) ...[
              const Text(
                'GUEST MEAL REQUESTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkFaded,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              for (final gr in pendingGuest)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.paperRaised,
                    borderRadius: BorderRadius.circular(DashUI.rCard),
                    border: Border.all(
                      color: AppColors.emerald.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.emerald,
                          borderRadius: BorderRadius.circular(DashUI.rBtn),
                        ),
                        child: Text(
                          'Day ${gr['day']}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${gr['member_name'] ?? gr['member']?['name'] ?? 'Member'} . ${gr['guest_name'] ?? 'Guest'} .${gr['guest_count'] ?? 1}',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            Row(
                              children: [
                                if (gr['is_cancellation'] == true)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: const Color(0xFFF59E0B),
                                      ),
                                    ),
                                    child: const Text(
                                      'CANCEL',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFB45309),
                                      ),
                                    ),
                                  ),
                                if (gr['is_cancellation'] == true)
                                  const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${gr['is_cancellation'] == true ? 'Cancel: ' : ''}Guest Meal Request${gr['note'] != null && gr['note'].toString().isNotEmpty ? ' . "${gr['note']}"' : ''}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.inkSoft,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (canManage) ...[
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              await _repo.handleGuestMeal(
                                widget.messId,
                                widget.monthId,
                                gr['id'] as int,
                                'deny',
                              );
                              _refresh();
                            },
                            borderRadius: BorderRadius.circular(DashUI.rCard),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.dangerSoft,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.danger.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: AppColors.danger,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              await _repo.handleGuestMeal(
                                widget.messId,
                                widget.monthId,
                                gr['id'] as int,
                                'approve',
                              );
                              _refresh();
                            },
                            borderRadius: BorderRadius.circular(DashUI.rCard),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.emeraldSoft,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.emerald.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: AppColors.emerald,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // MODALS: ADD DEPOSIT (Modern Dialog)
  // ==========================================
  void _showAddDepositModal(List<dynamic> members) {
    if (members.isEmpty) return;
    int selectedId = _toI(members.first['id']);
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final dateCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().split('T')[0],
    );
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) {
          return Dialog(
            backgroundColor: AppColors.paperRaised,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DashUI.rCard),
              side: const BorderSide(color: AppColors.paperLine),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 480,
                maxHeight: MediaQuery.of(ctx2).size.height * 0.88,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 14, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.emeraldSoft,
                            borderRadius: BorderRadius.circular(DashUI.rTile),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: AppColors.emerald,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ui.sheet_add_deposit_title'.tr2,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'ui.sheet_add_deposit_sub'.tr2,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.inkFaded,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(ctx2),
                            borderRadius: BorderRadius.circular(DashUI.rCard),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.paper,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.paperLine),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.paperLine),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Select Member
                          Text(
                            'ui.sheet_select_member'.tr2,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.inkFaded,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<int>(
                            initialValue: selectedId,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.paper,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  DashUI.rBtn,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.paperLine,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  DashUI.rBtn,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.paperLine,
                                ),
                              ),
                            ),
                            items: [
                              for (final m in members)
                                DropdownMenuItem<int>(
                                  value: _toI(m['id']),
                                  child: Text(
                                    (m['name'] ?? 'Member').toString(),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                            ],
                            onChanged: (v) {
                              if (v != null) selectedId = v;
                            },
                          ),
                          const SizedBox(height: 14),

                          // 2. Deposit Amount
                          Text(
                            'ui.sheet_deposit_amount'.tr2,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.inkFaded,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: amountCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.ink,
                            ),
                            decoration: InputDecoration(
                              hintText: 'ui.sheet_deposit_hint'.tr2,
                              hintStyle: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.inkFaded,
                              ),
                              prefixIcon: const Icon(
                                Icons.payments_outlined,
                                size: 16,
                                color: AppColors.emerald,
                              ),
                              filled: true,
                              fillColor: AppColors.paper,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  DashUI.rBtn,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.paperLine,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  DashUI.rBtn,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.paperLine,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  DashUI.rBtn,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.emerald,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Preset Amount Quick Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [500, 1000, 2000, 3000, 5000].map((
                                amt,
                              ) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: InkWell(
                                    onTap: () {
                                      amountCtrl.text = amt.toString();
                                      setS(() {});
                                    },
                                    borderRadius: BorderRadius.circular(
                                      DashUI.rBtn,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.paper,
                                        borderRadius: BorderRadius.circular(
                                          DashUI.rBtn,
                                        ),
                                        border: Border.all(
                                          color: AppColors.paperLine,
                                        ),
                                      ),
                                      child: Text(
                                        '+৳$amt',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.inkSoft,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // 3. Deposit Date
                          Text(
                            'ui.sheet_deposit_date'.tr2,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.inkFaded,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: dateCtrl,
                            readOnly: true,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.ink,
                            ),
                            decoration: InputDecoration(
                              suffixIcon: const Icon(
                                Icons.calendar_today_rounded,
                                size: 16,
                                color: AppColors.inkFaded,
                              ),
                              filled: true,
                              fillColor: AppColors.paper,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  DashUI.rBtn,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.paperLine,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  DashUI.rBtn,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.paperLine,
                                ),
                              ),
                            ),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2024),
                                lastDate: DateTime(2027),
                              );
                              if (picked != null) {
                                dateCtrl.text = picked.toIso8601String().split(
                                  'T',
                                )[0];
                              }
                            },
                          ),

                          const SizedBox(height: 14),

                          // 4. Note
                          Text(
                            'ui.sheet_note_optional'.tr2,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.inkFaded,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: noteCtrl,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.ink,
                            ),
                            decoration: InputDecoration(
                              hintText: 'ui.sheet_deposit_note_hint'.tr2,
                              hintStyle: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.inkFaded,
                              ),
                              prefixIcon: const Icon(
                                Icons.note_alt_outlined,
                                size: 16,
                                color: AppColors.inkFaded,
                              ),
                              filled: true,
                              fillColor: AppColors.paper,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  DashUI.rBtn,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.paperLine,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  DashUI.rBtn,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.paperLine,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  DashUI.rBtn,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.emerald,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.paperLine),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx2),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.ink,
                              side: const BorderSide(
                                color: AppColors.paperLine,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              minimumSize: const Size(0, 38),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  DashUI.rBtn,
                                ),
                              ),
                            ),
                            child: Text(
                              'ui.cancel'.tr2,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: FilledButton.icon(
                            onPressed: saving
                                ? null
                                : () async {
                                    final amt = _toD(amountCtrl.text);
                                    if (amt <= 0) {
                                      ScaffoldMessenger.of(ctx2).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'ui.sheet_invalid_deposit'.tr2,
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    setS(() => saving = true);
                                    try {
                                      await _repo.addDeposit(
                                        widget.messId,
                                        widget.monthId,
                                        selectedId,
                                        amt,
                                        date: dateCtrl.text,
                                        note: noteCtrl.text,
                                      );
                                      if (context.mounted) {
                                        Navigator.pop(ctx2);
                                        _refresh();
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(ctx2).showSnackBar(
                                          SnackBar(content: Text('Failed: $e')),
                                        );
                                      }
                                    } finally {
                                      setS(() => saving = false);
                                    }
                                  },
                            icon: saving
                                ? const SizedBox.shrink()
                                : const Icon(Icons.check_rounded, size: 14),
                            label: saving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'ui.sheet_save_deposit'.tr2,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                    ),
                                  ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.emerald,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              minimumSize: const Size(0, 38),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  DashUI.rBtn,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteDeposit(
    int depositId, {
    String? memberName,
    double? amount,
  }) async {
    final ok = await ConfirmDeleteDialog.show(
      context,
      title: 'ui.confirm_delete_deposit_title'.tr2,
      itemName: memberName != null && amount != null && amount > 0
          ? '$memberName . ?${amount.toStringAsFixed(0)}'
          : memberName,
      message: 'ui.confirm_delete_deposit_message'.tr2,
      confirmLabel: 'ui.confirm_delete_deposit_label'.tr2,
      icon: Icons.account_balance_wallet_outlined,
    );
    if (ok != true) return;
    try {
      await _repo.deleteDeposit(widget.messId, widget.monthId, depositId);
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  // ==========================================
  // MODALS: EDIT MEMBER DEFAULTS (Modern Dialog)
  // ==========================================
  void _showEditMemberModal(Map memberRaw) {
    final name = (memberRaw['name'] ?? 'Member').toString();
    final memberId = _toI(memberRaw['id']);
    final email = (memberRaw['email'] ?? '').toString();

    final bfCtrl = TextEditingController(
      text: memberRaw['default_breakfast'] != null
          ? _toD(memberRaw['default_breakfast']).toString()
          : '1',
    );
    final lCtrl = TextEditingController(
      text: memberRaw['default_lunch'] != null
          ? _toD(memberRaw['default_lunch']).toString()
          : '1',
    );
    final dCtrl = TextEditingController(
      text: memberRaw['default_dinner'] != null
          ? _toD(memberRaw['default_dinner']).toString()
          : '1',
    );

    final depAmountCtrl = TextEditingController();
    final depNoteCtrl = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) {
          Widget buildMealInputRow({
            required String title,
            required IconData icon,
            required TextEditingController controller,
            required String hint,
          }) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(DashUI.rCard),
                border: Border.all(color: AppColors.paperLine),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(DashUI.rBtn),
                    ),
                    child: Icon(icon, size: 18, color: AppColors.brandDark),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 1),
                        const Text(
                          'Daily meal count (0 = OFF)',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: AppColors.inkFaded,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 86,
                    child: TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppColors.inkFaded,
                        ),
                        filled: true,
                        fillColor: AppColors.paperRaised,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DashUI.rBtn),
                          borderSide: const BorderSide(
                            color: AppColors.paperLine,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DashUI.rBtn),
                          borderSide: const BorderSide(
                            color: AppColors.paperLine,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DashUI.rBtn),
                          borderSide: const BorderSide(
                            color: AppColors.brandDark,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Dialog(
            backgroundColor: AppColors.paperRaised,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DashUI.rCard),
              side: const BorderSide(color: AppColors.paperLine),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 480,
                maxHeight: MediaQuery.of(ctx2).size.height * 0.88,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Profile Banner Row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 14, 14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.brandDark,
                          child: Text(
                            name.isNotEmpty
                                ? name.substring(0, 1).toUpperCase()
                                : 'M',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.ink,
                                ),
                              ),
                              Text(
                                email.isNotEmpty ? email : 'Member Settings',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.inkFaded,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(ctx2),
                            borderRadius: BorderRadius.circular(DashUI.rCard),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.paper,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.paperLine),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.paperLine),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Daily Meal Defaults
                          Row(
                            children: [
                              Text(
                                'ui.daily_meal_defaults'.tr2,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.inkFaded,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'ui.auto_applied_daily'.tr2,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.inkFaded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // 3 Meal Input Rows
                          buildMealInputRow(
                            title: 'ui.breakfast'.tr2,
                            icon: Icons.free_breakfast_outlined,
                            controller: bfCtrl,
                            hint: '1.0',
                          ),
                          buildMealInputRow(
                            title: 'ui.lunch'.tr2,
                            icon: Icons.lunch_dining_outlined,
                            controller: lCtrl,
                            hint: '1.0',
                          ),
                          buildMealInputRow(
                            title: 'ui.dinner'.tr2,
                            icon: Icons.dinner_dining_outlined,
                            controller: dCtrl,
                            hint: '1.0',
                          ),
                          const SizedBox(height: 14),

                          // 2. Add Quick Deposit Card
                          Text(
                            'ui.sheet_quick_deposit_optional'.tr2,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.inkFaded,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.paper,
                              borderRadius: BorderRadius.circular(DashUI.rCard),
                              border: Border.all(color: AppColors.paperLine),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: depAmountCtrl,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'ui.deposit_amount_label'.tr2,
                                    hintText: 'ui.deposit_amount_hint'.tr2,
                                    prefixIcon: const Icon(
                                      Icons.payments_outlined,
                                      size: 17,
                                      color: AppColors.emerald,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.paperRaised,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        DashUI.rBtn,
                                      ),
                                      borderSide: const BorderSide(
                                        color: AppColors.paperLine,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        DashUI.rBtn,
                                      ),
                                      borderSide: const BorderSide(
                                        color: AppColors.paperLine,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        DashUI.rBtn,
                                      ),
                                      borderSide: const BorderSide(
                                        color: AppColors.brandDark,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Preset chips
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [500, 1000, 2000, 3000, 5000].map(
                                      (amt) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            right: 6,
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              depAmountCtrl.text = amt
                                                  .toString();
                                              setS(() {});
                                            },
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.paperRaised,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      DashUI.rBtn,
                                                    ),
                                                border: Border.all(
                                                  color: AppColors.paperLine,
                                                ),
                                              ),
                                              child: Text(
                                                '+৳${amt.toBnNum()}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.inkSoft,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ).toList(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: depNoteCtrl,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: AppColors.ink,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'ui.deposit_note_label'.tr2,
                                    hintText: 'ui.deposit_note_hint'.tr2,
                                    prefixIcon: const Icon(
                                      Icons.note_alt_outlined,
                                      size: 17,
                                      color: AppColors.inkFaded,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.paperRaised,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        DashUI.rBtn,
                                      ),
                                      borderSide: const BorderSide(
                                        color: AppColors.paperLine,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        DashUI.rBtn,
                                      ),
                                      borderSide: const BorderSide(
                                        color: AppColors.paperLine,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        DashUI.rBtn,
                                      ),
                                      borderSide: const BorderSide(
                                        color: AppColors.brandDark,
                                        width: 1.5,
                                      ),
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
                  const Divider(height: 1, color: AppColors.paperLine),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx2),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.ink,
                              side: const BorderSide(
                                color: AppColors.paperLine,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              minimumSize: const Size(0, 38),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  DashUI.rBtn,
                                ),
                              ),
                            ),
                            child: Text(
                              'ui.cancel'.tr2,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: FilledButton.icon(
                            onPressed: saving
                                ? null
                                : () async {
                                    double? bf = bfCtrl.text.trim().isEmpty
                                        ? null
                                        : _toD(bfCtrl.text);
                                    double? ln = lCtrl.text.trim().isEmpty
                                        ? null
                                        : _toD(lCtrl.text);
                                    double? dn = dCtrl.text.trim().isEmpty
                                        ? null
                                        : _toD(dCtrl.text);
                                    double? depAmt =
                                        depAmountCtrl.text.trim().isEmpty
                                        ? null
                                        : _toD(depAmountCtrl.text);

                                    setS(() => saving = true);
                                    try {
                                      await _repo.updateMemberDetails(
                                        widget.messId,
                                        memberId,
                                        breakfast: bf,
                                        lunch: ln,
                                        dinner: dn,
                                        depositAmount: depAmt,
                                        depositNote: depNoteCtrl.text.isEmpty
                                            ? null
                                            : depNoteCtrl.text,
                                      );
                                      if (context.mounted) {
                                        Navigator.pop(ctx2);
                                        _refresh();
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(ctx2).showSnackBar(
                                          SnackBar(
                                            content: Text('Save failed: $e'),
                                          ),
                                        );
                                      }
                                    } finally {
                                      setS(() => saving = false);
                                    }
                                  },
                            icon: saving
                                ? const SizedBox.shrink()
                                : const Icon(Icons.check_rounded, size: 14),
                            label: saving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                    ),
                                  ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.brandDark,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              minimumSize: const Size(0, 38),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  DashUI.rBtn,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // MODALS: MEAL OFF REQUEST
  // ==========================================
  void _showMealOffModal(Map sheet) {
    // Web parity: members need 1-day notice � earliest selectable day is tomorrow
    final int todayD = _toI(sheet['todayDay'] ?? sheet['passedDays'] ?? 0);
    final monthRaw0 = _asMap(sheet['month']);
    final days0 = _toI(monthRaw0['days']) > 0 ? _toI(monthRaw0['days']) : 31;
    int selectedDay = (todayD + 1).clamp(1, days0);
    final myB = _asMap(sheet['myMealB']);
    final myL = _asMap(sheet['myMealL']);
    final myD = _asMap(sheet['myMealD']);
    bool bOn = true, lOn = true, dOn = true;
    int? lastLoadedDay;
    final noteCtrl = TextEditingController();
    final days = days0;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) {
          void applyDayPrefill(int d) {
            if (lastLoadedDay == d) return;
            lastLoadedDay = d;
            final k = d.toString();
            // If this day has a pending request, prefill from pending target so member sees PENDING
            final pendingForDay =
                _asMap(sheet['myPendingByDay'])[k] ??
                _asMap(sheet['myPendingByDay'])[d];
            if (pendingForDay is Map) {
              final bOff = pendingForDay['breakfast_off'];
              final lOff = pendingForDay['lunch_off'];
              final dOff = pendingForDay['dinner_off'];
              if (bOff is bool) bOn = !bOff;
              if (lOff is bool) lOn = !lOff;
              if (dOff is bool) dOn = !dOff;
              final note = pendingForDay['note'];
              if (note is String && note.isNotEmpty) {
                // Preserve pending note in text field
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (noteCtrl.text.isEmpty) noteCtrl.text = note;
                });
              }
            } else {
              bOn = !(_toD(myB[k] ?? myB[d]) == 0);
              lOn = !(_toD(myL[k] ?? myL[d]) == 0);
              dOn = !(_toD(myD[k] ?? myD[d]) == 0);
            }
          }

          applyDayPrefill(selectedDay);

          Widget buildMealToggleCard({
            required String label,
            required IconData icon,
            required bool isOn,
            required VoidCallback onTap,
          }) {
            final isBn = AppTranslations.locale == 'bn';
            final statusText = isOn
                ? (isBn ? 'অন' : 'ON')
                : (isBn ? 'অফ' : 'OFF');

            return InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(DashUI.rTile),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: isOn
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(DashUI.rTile),
                  border: Border.all(
                    color: isOn
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isOn
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFFEF4444))
                              .withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOn
                          ? Icons.check_circle_rounded
                          : Icons.do_not_disturb_on_rounded,
                      size: 22,
                      color: isOn
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isOn
                            ? const Color(0xFF14532D)
                            : const Color(0xFF7F1D1D),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isOn
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(DashUI.rCard),
                      ),
                      child: Text(
                        statusText,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Dialog(
            backgroundColor: AppColors.paperRaised,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DashUI.rCard),
              side: const BorderSide(color: AppColors.paperLine),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 480,
                maxHeight: MediaQuery.of(ctx2).size.height * 0.88,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 14, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.brandSoft,
                            borderRadius: BorderRadius.circular(DashUI.rTile),
                          ),
                          child: const Icon(
                            Icons.event_busy_rounded,
                            color: AppColors.brandDark,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ui.sheet_request_off'.tr2,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'ui.sheet_request_off_sub'.tr2,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.inkFaded,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(ctx2),
                            borderRadius: BorderRadius.circular(DashUI.rCard),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.paper,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.paperLine),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.paperLine),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ui.sheet_select_day'.tr2,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.inkFaded,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _guestDateGrid(
                            days: days,
                            selectedDay: selectedDay,
                            pendingMap: _asMap(sheet['myOffReqByDay']),
                            todayDay: _toI(sheet['todayDay'] ?? 0),
                            minDay: _toI(sheet['todayDay'] ?? 0) + 1,
                            onTap: (d) => setS(() {
                              selectedDay = d;
                              applyDayPrefill(d);
                            }),
                          ),
                          const SizedBox(height: 16),
                          Builder(
                            builder: (_) {
                              final myPendingMap = _asMap(
                                sheet['myOffReqByDay'],
                              );
                              final pend =
                                  myPendingMap[selectedDay.toString()] ??
                                  myPendingMap[selectedDay];
                              if (pend is Map) {
                                final labelStr = (pend['label'] ?? '')
                                    .toString();
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(
                                      DashUI.rBtn,
                                    ),
                                    border: Border.all(
                                      color: const Color(0xFFF59E0B),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.hourglass_top_rounded,
                                        size: 16,
                                        color: Color(0xFFD97706),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          AppTranslations.locale == 'bn'
                                              ? ' ${selectedDay.toString().toBnNum()}-আবেদন পেন্ডিং: ${labelStr.isNotEmpty ? labelStr : 'আবেদন পেন্ডিং'}'
                                              : 'Pending request for Day $selectedDay: ${labelStr.isNotEmpty ? labelStr : 'Meal request'}',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFB45309),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ui.sheet_select_meal_slots'.tr2,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.inkFaded,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                '${'ui.sheet_day'.tr2} ${selectedDay.toString().toBnNum()}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brandDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: buildMealToggleCard(
                                  label: 'ui.breakfast'.tr2,
                                  icon: Icons.free_breakfast_outlined,
                                  isOn: bOn,
                                  onTap: () => setS(() => bOn = !bOn),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: buildMealToggleCard(
                                  label: 'ui.lunch'.tr2,
                                  icon: Icons.lunch_dining_outlined,
                                  isOn: lOn,
                                  onTap: () => setS(() => lOn = !lOn),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: buildMealToggleCard(
                                  label: 'ui.dinner'.tr2,
                                  icon: Icons.wb_twilight_rounded,
                                  isOn: dOn,
                                  onTap: () => setS(() => dOn = !dOn),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: noteCtrl,
                            decoration: InputDecoration(
                              labelText: 'ui.sheet_note_optional'.tr2,
                              hintText: 'e.g. Traveling home',
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(ctx2),
                                  child: Text('ui.cancel'.tr2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () async {
                                    try {
                                      await _repo.requestMealOff(
                                        widget.messId,
                                        widget.monthId,
                                        selectedDay,
                                        bOn: bOn,
                                        lOn: lOn,
                                        dOn: dOn,
                                        note: noteCtrl.text,
                                      );
                                      if (context.mounted) {
                                        Navigator.pop(ctx2);
                                        _refresh();
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(ctx2).showSnackBar(
                                          SnackBar(content: Text('Failed: $e')),
                                        );
                                      }
                                    }
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.brandDark,
                                  ),
                                  child: Text('ui.sheet_save_entry'.tr2),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // MODALS: GUEST MEAL REQUEST / ADD (Modern Dialogs)
  // ==========================================
  void _showGuestRequestModal(Map sheet) {
    // Web parity: guest requests need 1-day notice � earliest day is tomorrow
    final int todayD = _toI(sheet['todayDay'] ?? sheet['passedDays'] ?? 0);
    final monthRaw = _asMap(sheet['month']);
    final days = _toI(monthRaw['days']) > 0 ? _toI(monthRaw['days']) : 31;
    int selectedDay = (todayD + 1).clamp(1, days);
    final nameCtrl = TextEditingController();
    int guestCount = 1;
    bool b = false, l = false, dn = false;
    final noteCtrl = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) {
          bool canSubmit =
              nameCtrl.text.trim().isNotEmpty &&
              guestCount > 0 &&
              (b || l || dn);

          return Dialog(
            backgroundColor: AppColors.paperRaised,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DashUI.rCard),
              side: const BorderSide(color: AppColors.paperLine),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 480,
                maxHeight: MediaQuery.of(ctx2).size.height * 0.88,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 14, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.brandSoft,
                            borderRadius: BorderRadius.circular(DashUI.rTile),
                          ),
                          child: const Icon(
                            Icons.person_add_rounded,
                            color: AppColors.brandDark,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ui.sheet_request_guest_title'.tr2,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '${'ui.dash_day_prefix'.tr2} ${selectedDay.toBnNum()} . ${'ui.sheet_select_meal_slots'.tr2}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.inkFaded,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(ctx2),
                            borderRadius: BorderRadius.circular(DashUI.rCard),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.paper,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.paperLine),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.paperLine),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Target Day
                          Text(
                            'ui.sheet_select_day'.tr2,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.inkFaded,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _guestDateGrid(
                            days: days,
                            selectedDay: selectedDay,
                            todayDay: _toI(sheet['todayDay'] ?? 0),
                            minDay: _toI(sheet['todayDay'] ?? 0) + 1,
                            onTap: (d) => setS(() => selectedDay = d),
                          ),
                          const SizedBox(height: 14),

                          // 2. Guest Name & Count Row
                          Text(
                            'ui.guest_details'.tr2,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.inkFaded,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: nameCtrl,
                            onChanged: (_) => setS(() {}),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.ink,
                            ),
                            decoration: InputDecoration(
                              hintText: 'ui.guest_name_hint'.tr2,
                              hintStyle: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.inkFaded,
                              ),
                              prefixIcon: const Icon(
                                Icons.badge_outlined,
                                size: 16,
                                color: AppColors.inkFaded,
                              ),
                              filled: true,
                              fillColor: AppColors.paper,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  DashUI.rBtn,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.paperLine,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  DashUI.rBtn,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.paperLine,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  DashUI.rBtn,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.brandDark,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Guest Counter Card
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.paper,
                              borderRadius: BorderRadius.circular(DashUI.rBtn),
                              border: Border.all(color: AppColors.paperLine),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.people_outline_rounded,
                                  size: 16,
                                  color: AppColors.inkSoft,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'ui.guest_count'.tr2,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const Spacer(),
                                InkWell(
                                  onTap: guestCount > 1
                                      ? () => setS(() => guestCount--)
                                      : null,
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: guestCount > 1
                                          ? AppColors.paperRaised
                                          : AppColors.paper,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.paperLine,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.remove_rounded,
                                      size: 16,
                                      color: guestCount > 1
                                          ? AppColors.ink
                                          : AppColors.inkFaded,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    guestCount.toBnNum(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      color: AppColors.brandDark,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => setS(() => guestCount++),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.paperRaised,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.paperLine,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.add_rounded,
                                      size: 16,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // 3. Meal Slot Selectors
                          Text(
                            'ui.sheet_select_meal_slots'.tr2,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.inkFaded,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMealSlotChip(
                                  label: 'ui.breakfast'.tr2,
                                  icon: Icons.free_breakfast_outlined,
                                  isSelected: b,
                                  onTap: () => setS(() => b = !b),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildMealSlotChip(
                                  label: 'ui.lunch'.tr2,
                                  icon: Icons.lunch_dining_outlined,
                                  isSelected: l,
                                  onTap: () => setS(() => l = !l),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildMealSlotChip(
                                  label: 'ui.dinner'.tr2,
                                  icon: Icons.dinner_dining_outlined,
                                  isSelected: dn,
                                  onTap: () => setS(() => dn = !dn),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // 4. Optional Note
                          Text(
                            'ui.note_optional'.tr2,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.inkFaded,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: noteCtrl,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.ink,
                            ),
                            decoration: InputDecoration(
                              hintText: 'ui.guest_note_hint'.tr2,
                              hintStyle: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.inkFaded,
                              ),
                              prefixIcon: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 16,
                                color: AppColors.inkFaded,
                              ),
                              filled: true,
                              fillColor: AppColors.paper,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  DashUI.rBtn,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.paperLine,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  DashUI.rBtn,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.paperLine,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  DashUI.rBtn,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.brandDark,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.paperLine),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx2),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.ink,
                              side: const BorderSide(
                                color: AppColors.paperLine,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              minimumSize: const Size(0, 38),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  DashUI.rBtn,
                                ),
                              ),
                            ),
                            child: Text(
                              'ui.cancel'.tr2,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: FilledButton.icon(
                            onPressed: !canSubmit || saving
                                ? null
                                : () async {
                                    setS(() => saving = true);
                                    try {
                                      await _repo.requestGuestMeal(
                                        widget.messId,
                                        widget.monthId,
                                        day: selectedDay,
                                        guestName: nameCtrl.text.trim(),
                                        guestCount: guestCount,
                                        breakfast: b,
                                        lunch: l,
                                        dinner: dn,
                                        note: noteCtrl.text,
                                      );
                                      if (context.mounted) {
                                        Navigator.pop(ctx2);
                                        _refresh();
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(ctx2).showSnackBar(
                                          SnackBar(content: Text('Failed: $e')),
                                        );
                                      }
                                    } finally {
                                      setS(() => saving = false);
                                    }
                                  },
                            icon: saving
                                ? const SizedBox.shrink()
                                : const Icon(Icons.send_rounded, size: 14),
                            label: saving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'ui.sheet_send_request'.tr2,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                    ),
                                  ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.brandDark,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              minimumSize: const Size(0, 38),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  DashUI.rBtn,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddGuestModal(List<dynamic> members, int todayDay, Map sheet) {
    if (members.isEmpty) return;
    int hostId = _toI(members.first['id']);
    final monthRaw = _asMap(sheet['month']);
    final days = _toI(monthRaw['days']) > 0 ? _toI(monthRaw['days']) : 31;
    int selectedDay = todayDay > 0 ? todayDay : 1;
    final nameCtrl = TextEditingController();
    int guestCount = 1;
    bool b = false, l = false, dn = false;
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) {
          bool canSubmit = nameCtrl.text.trim().isNotEmpty && (b || l || dn);

          return Dialog(
            backgroundColor: AppColors.paperRaised,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DashUI.rCard),
              side: const BorderSide(color: AppColors.paperLine),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 480,
                maxHeight: MediaQuery.of(ctx2).size.height * 0.88,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 14, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.brandSoft,
                            borderRadius: BorderRadius.circular(DashUI.rTile),
                          ),
                          child: const Icon(
                            Icons.person_add_alt_1_rounded,
                            color: AppColors.brandDark,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ui.sheet_add_guest'.tr2,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '${'ui.dash_day_prefix'.tr2} ${selectedDay.toString().toBnNum()} . ${'ui.sheet_direct_entry'.tr2}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.inkFaded,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(ctx2),
                            borderRadius: BorderRadius.circular(DashUI.rCard),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.paper,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.paperLine),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.paperLine),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Host Member Dropdown
                          Text(
                            'ui.sheet_host_member_required'.tr2,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.inkFaded,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<int>(
                            initialValue: hostId,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.paper,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  DashUI.rBtn,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.paperLine,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  DashUI.rBtn,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.paperLine,
                                ),
                              ),
                            ),
                            items: [
                              for (final m in members)
                                DropdownMenuItem<int>(
                                  value: _toI(m['id']),
                                  child: Text(
                                    (m['name'] ?? 'Member').toString(),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                            ],
                            onChanged: (v) {
                              if (v != null) setS(() => hostId = v);
                            },
                          ),
                          const SizedBox(height: 14),

                          // 2. Target Day Picker
                          Text(
                            'ui.sheet_select_day'.tr2,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.inkFaded,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _guestDateGrid(
                            days: days,
                            selectedDay: selectedDay,
                            todayDay: todayDay,
                            minDay: 1,
                            onTap: (d) => setS(() => selectedDay = d),
                          ),
                          const SizedBox(height: 14),

                          // 3. Guest Name
                          Text(
                            'ui.sheet_guest_name_label'.tr2,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.inkFaded,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: nameCtrl,
                            onChanged: (_) => setS(() {}),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.ink,
                            ),
                            decoration: InputDecoration(
                              hintText: 'ui.guest_name_hint'.tr2,
                              hintStyle: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.inkFaded,
                              ),
                              prefixIcon: const Icon(
                                Icons.badge_outlined,
                                size: 16,
                                color: AppColors.inkFaded,
                              ),
                              filled: true,
                              fillColor: AppColors.paper,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  DashUI.rBtn,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.paperLine,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  DashUI.rBtn,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.paperLine,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  DashUI.rBtn,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.brandDark,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Guest Counter Card
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.paper,
                              borderRadius: BorderRadius.circular(DashUI.rBtn),
                              border: Border.all(color: AppColors.paperLine),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.people_outline_rounded,
                                  size: 16,
                                  color: AppColors.inkSoft,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'ui.guest_count'.tr2,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const Spacer(),
                                InkWell(
                                  onTap: guestCount > 1
                                      ? () => setS(() => guestCount--)
                                      : null,
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: guestCount > 1
                                          ? AppColors.paperRaised
                                          : AppColors.paper,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.paperLine,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.remove_rounded,
                                      size: 16,
                                      color: guestCount > 1
                                          ? AppColors.ink
                                          : AppColors.inkFaded,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    guestCount.toBnNum(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      color: AppColors.brandDark,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => setS(() => guestCount++),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.paperRaised,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.paperLine,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.add_rounded,
                                      size: 16,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // 4. Meal Slot Selection
                          Text(
                            'ui.sheet_select_meal_slots'.tr2,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.inkFaded,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMealSlotChip(
                                  label: 'ui.breakfast'.tr2,
                                  icon: Icons.free_breakfast_outlined,
                                  isSelected: b,
                                  onTap: () => setS(() => b = !b),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildMealSlotChip(
                                  label: 'ui.lunch'.tr2,
                                  icon: Icons.lunch_dining_outlined,
                                  isSelected: l,
                                  onTap: () => setS(() => l = !l),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildMealSlotChip(
                                  label: 'ui.dinner'.tr2,
                                  icon: Icons.dinner_dining_outlined,
                                  isSelected: dn,
                                  onTap: () => setS(() => dn = !dn),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.paperLine),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx2),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.ink,
                              side: const BorderSide(
                                color: AppColors.paperLine,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              minimumSize: const Size(0, 38),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  DashUI.rBtn,
                                ),
                              ),
                            ),
                            child: Text(
                              'ui.cancel'.tr2,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: FilledButton.icon(
                            onPressed: !canSubmit || saving
                                ? null
                                : () async {
                                    setS(() => saving = true);
                                    try {
                                      await _repo.addGuestDirect(
                                        widget.messId,
                                        widget.monthId,
                                        memberId: hostId,
                                        day: selectedDay,
                                        guestName: nameCtrl.text.trim(),
                                        guestCount: guestCount,
                                        breakfast: b,
                                        lunch: l,
                                        dinner: dn,
                                      );
                                      if (context.mounted) {
                                        Navigator.pop(ctx2);
                                        _refresh();
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(ctx2).showSnackBar(
                                          SnackBar(content: Text('Failed: $e')),
                                        );
                                      }
                                    } finally {
                                      setS(() => saving = false);
                                    }
                                  },
                            icon: saving
                                ? const SizedBox.shrink()
                                : const Icon(Icons.check_rounded, size: 14),
                            label: saving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Add Guest',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                    ),
                                  ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.brandDark,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              minimumSize: const Size(0, 38),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  DashUI.rBtn,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMealSlotChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isBn = AppTranslations.locale == 'bn';
    final badgeText = isSelected
        ? (isBn ? 'এড' : '? ADD')
        : (isBn ? 'অফ' : 'OFF');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DashUI.rTile),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandSoft : AppColors.paper,
          borderRadius: BorderRadius.circular(DashUI.rTile),
          border: Border.all(
            color: isSelected ? AppColors.brandDark : AppColors.paperLine,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.brandDark.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.brandDark : AppColors.inkFaded,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.brandDark : AppColors.inkSoft,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.brandDark
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(DashUI.rCard),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : AppColors.inkFaded,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // MODALS: DAY EDIT (Bazar & Member Meals)
  // ==========================================
  void _openDayEdit(
    int day,
    List<dynamic> members,
    Map sheet, {
    bool bazarOnly = false,
  }) {
    final receiptsRaw = _byDay(_asMap(sheet['bazarReceiptsMulti']), day);
    final List<dynamic> existingReceipts = receiptsRaw is List
        ? receiptsRaw
        : <dynamic>[];
    final List<XFile> pickedReceipts = [];
    final itemsRaw = _byDay(_asMap(sheet['bazarItemsByDay']), day);
    final List<dynamic> existingItems = itemsRaw is List
        ? itemsRaw
        : <dynamic>[];
    final List<Map<String, TextEditingController>> rows = [];

    for (final it in existingItems) {
      rows.add({
        'name': TextEditingController(text: (it['name'] ?? '').toString()),
        'qty': TextEditingController(text: (it['qty'] ?? '').toString()),
        'price': TextEditingController(text: (it['price'] ?? '').toString()),
      });
    }
    if (rows.isEmpty) {
      rows.add({
        'name': TextEditingController(),
        'qty': TextEditingController(text: '1'),
        'price': TextEditingController(),
      });
    }

    final mealCtrls = <int, Map<String, TextEditingController>>{};
    for (final m in members) {
      final mid = _toI(m['id']).toString();
      dynamic getMeal(Map mp) => (mp[mid] is Map
          ? (mp[mid] as Map)[day.toString()] ?? (mp[mid] as Map)[day]
          : null);
      final bVal = getMeal(_asMap(sheet['mealsB']));
      final lVal = getMeal(_asMap(sheet['mealsL']));
      final dVal = getMeal(_asMap(sheet['mealsD']));
      mealCtrls[_toI(m['id'])] = {
        'b': TextEditingController(
          text: bVal != null ? _toD(bVal).toString() : '',
        ),
        'l': TextEditingController(
          text: lVal != null ? _toD(lVal).toString() : '',
        ),
        'd': TextEditingController(
          text: dVal != null ? _toD(dVal).toString() : '',
        ),
      };
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) {
          double calcTotal() {
            double sum = 0;
            for (final r in rows) {
              final q = _toD(r['qty']!.text);
              final p = _toD(r['price']!.text);
              sum += (q * p);
            }
            return sum;
          }

          final bazarTotal = calcTotal();

          return Dialog(
            backgroundColor: AppColors.paperRaised,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DashUI.rCard),
              side: const BorderSide(color: AppColors.paperLine),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 580,
                maxHeight: MediaQuery.of(ctx2).size.height * 0.88,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 14, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.brandDark,
                            borderRadius: BorderRadius.circular(DashUI.rBtn),
                          ),
                          child: const Icon(
                            Icons.edit_calendar_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bazarOnly
                                    ? 'Log Day $day Bazar'
                                    : 'Edit Day $day (Bazar & Meals)',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.ink,
                                ),
                              ),
                              const Text(
                                'Update market items and daily meals',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.inkFaded,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(ctx2),
                            borderRadius: BorderRadius.circular(DashUI.rCard),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.paper,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.paperLine),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.paperLine),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Bazar Items Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'BAZAR ITEMS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.inkFaded,
                                ),
                              ),
                              if (bazarTotal > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.emeraldSoft,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Total: ৳${bazarTotal.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.emerald,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          for (int i = 0; i < rows.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      controller: rows[i]['name']!,
                                      onChanged: (_) => setS(() {}),
                                      decoration: InputDecoration(
                                        hintText: 'Item name',
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 9,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    flex: 1,
                                    child: TextField(
                                      controller: rows[i]['qty']!,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      onChanged: (_) => setS(() {}),
                                      decoration: InputDecoration(
                                        hintText: 'Qty',
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 9,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: rows[i]['price']!,
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setS(() {}),
                                      decoration: InputDecoration(
                                        hintText: 'Price ৳',
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 9,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: rows.length == 1
                                          ? null
                                          : () => setS(() => rows.removeAt(i)),
                                      borderRadius: BorderRadius.circular(
                                        DashUI.rCard,
                                      ),
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: rows.length == 1
                                              ? AppColors.paper
                                              : AppColors.dangerSoft,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: rows.length == 1
                                                ? AppColors.paperLine
                                                : AppColors.danger.withValues(
                                                    alpha: 0.2,
                                                  ),
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.remove_rounded,
                                            size: 14,
                                            color: rows.length == 1
                                                ? AppColors.inkFaded
                                                : AppColors.danger,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          OutlinedButton.icon(
                            onPressed: () => setS(() {
                              rows.add({
                                'name': TextEditingController(),
                                'qty': TextEditingController(text: '1'),
                                'price': TextEditingController(),
                              });
                            }),
                            icon: const Icon(Icons.add_rounded, size: 15),
                            label: const Text(
                              'Add Item',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.brandDark,
                              side: const BorderSide(
                                color: AppColors.paperLine,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              minimumSize: const Size(0, 32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  DashUI.rBtn,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Receipts Attachment
                          if (existingReceipts.isNotEmpty) ...[
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final r in existingReceipts)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandSoft,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.receipt_long_outlined,
                                          size: 12,
                                          color: AppColors.brandDark,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          (r['name'] ??
                                                  r['original_name'] ??
                                                  'Receipt')
                                              .toString(),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.brandDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final picker = ImagePicker();
                                    final files = await picker.pickMultiImage(
                                      imageQuality: 80,
                                    );
                                    if (files.isNotEmpty) {
                                      setS(() => pickedReceipts.addAll(files));
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.photo_library_outlined,
                                    size: 15,
                                  ),
                                  label: const Text(
                                    'Gallery',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 40),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    side: const BorderSide(
                                      color: AppColors.paperLine,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final picker = ImagePicker();
                                    final f = await picker.pickImage(
                                      source: ImageSource.camera,
                                      imageQuality: 80,
                                    );
                                    if (f != null) {
                                      setS(() => pickedReceipts.add(f));
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 15,
                                  ),
                                  label: const Text(
                                    'Camera',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 40),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    side: const BorderSide(
                                      color: AppColors.paperLine,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (pickedReceipts.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              '${pickedReceipts.length} new photo(s) selected',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.inkFaded,
                              ),
                            ),
                          ],

                          // 2. Member Meals Section (if not bazarOnly)
                          if (!bazarOnly) ...[
                            const SizedBox(height: 16),
                            const Divider(
                              height: 1,
                              color: AppColors.paperLine,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ValueListenableBuilder<int>(
                                  valueListenable: AppTranslations.notifier,
                                  builder: (context, _, _) => Text(
                                    'ui.members_total'.tr2.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.inkFaded,
                                    ),
                                  ),
                                ),
                                ValueListenableBuilder<int>(
                                  valueListenable: AppTranslations.notifier,
                                  builder: (context, _, _) => Text(
                                    'ui.dash_bld'.tr2,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.inkFaded,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            for (final m in members) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        (m['name'] ?? 'Member').toString(),
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        controller:
                                            mealCtrls[_toI(m['id'])]!['b'],
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        textAlign: TextAlign.center,
                                        decoration: InputDecoration(
                                          hintText: 'B',
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 8,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        controller:
                                            mealCtrls[_toI(m['id'])]!['l'],
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        textAlign: TextAlign.center,
                                        decoration: InputDecoration(
                                          hintText: 'L',
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 8,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        controller:
                                            mealCtrls[_toI(m['id'])]!['d'],
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        textAlign: TextAlign.center,
                                        decoration: InputDecoration(
                                          hintText: 'D',
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 8,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.paperLine),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx2),
                            child: Text('ui.cancel'.tr2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () async {
                              if (!bazarOnly) {
                                for (final m in members) {
                                  final mid = _toI(m['id']);
                                  final ctrls = mealCtrls[mid]!;
                                  final bTxt = ctrls['b']!.text.trim();
                                  final lTxt = ctrls['l']!.text.trim();
                                  final dTxt = ctrls['d']!.text.trim();
                                  if (bTxt.isEmpty &&
                                      lTxt.isEmpty &&
                                      dTxt.isEmpty) {
                                    continue;
                                  }
                                  try {
                                    await _repo.saveMeal(
                                      messId: widget.messId,
                                      monthId: widget.monthId,
                                      memberId: mid,
                                      day: day,
                                      breakfast: bTxt.isEmpty
                                          ? null
                                          : _toD(bTxt),
                                      lunch: lTxt.isEmpty ? null : _toD(lTxt),
                                      dinner: dTxt.isEmpty ? null : _toD(dTxt),
                                    );
                                  } catch (_) {}
                                }
                              }

                              final items = <Map<String, dynamic>>[];
                              for (final r in rows) {
                                final n = r['name']!.text.trim();
                                if (n.isEmpty) continue;
                                items.add({
                                  'name': n,
                                  'qty': _toD(r['qty']!.text),
                                  'price': _toD(r['price']!.text),
                                });
                              }

                              try {
                                if (items.isNotEmpty ||
                                    pickedReceipts.isNotEmpty) {
                                  await _repo.saveBazarItems(
                                    messId: widget.messId,
                                    monthId: widget.monthId,
                                    day: day,
                                    items: items,
                                    receiptPaths: pickedReceipts
                                        .map((e) => e.path)
                                        .toList(),
                                  );
                                }
                                if (context.mounted) {
                                  Navigator.pop(ctx2);
                                  _refresh();
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(ctx2).showSnackBar(
                                    SnackBar(content: Text('Save failed: $e')),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: Text('ui.sheet_save_entry'.tr2),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.brandDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Day Picker Grid Component
  Widget _guestDateGrid({
    required int days,
    required int selectedDay,
    required ValueChanged<int> onTap,
    Map? pendingMap,
    int minDay = 1,
    required int todayDay,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(DashUI.rTile),
        border: Border.all(color: AppColors.paperLine),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: days,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          childAspectRatio: 1.1,
        ),
        itemBuilder: (ctx, index) {
          final d = index + 1;
          final isSelected = selectedDay == d;
          final isLocked = d < minDay;
          final isToday = d == todayDay;
          final hasPend =
              pendingMap != null &&
              (pendingMap[d.toString()] != null || pendingMap[d] != null);

          return InkWell(
            onTap: isLocked ? null : () => onTap(d),
            borderRadius: BorderRadius.circular(DashUI.rBtn),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.brandDark
                        : isLocked
                        ? AppColors.paper
                        : AppColors.paperRaised,
                    borderRadius: BorderRadius.circular(DashUI.rBtn),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.brandDark
                          : AppColors.paperLine,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      d.toBnNum(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? Colors.white
                            : isLocked
                            ? AppColors.inkFaded
                            : AppColors.ink,
                      ),
                    ),
                  ),
                ),
                if (isLocked && !isSelected)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(DashUI.rBtn),
                        ),
                      ),
                    ),
                  ),
                if (hasPend)
                  Positioned(
                    top: 3,
                    right: 3,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.amberAccent
                            : const Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                if (isToday && !isSelected)
                  Positioned(
                    bottom: 3,
                    right: 3,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F9F59),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SliverCustomTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverCustomTabBarDelegate(this.child);

  @override
  double get minExtent => 74.0;
  @override
  double get maxExtent => 74.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.paper,
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_SliverCustomTabBarDelegate oldDelegate) {
    return false;
  }
}

class _CustomSegmentedTabBar extends StatelessWidget {
  final TabController controller;
  final int pendingCount;
  final int depositCount;

  const _CustomSegmentedTabBar({
    required this.controller,
    required this.pendingCount,
    required this.depositCount,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.paperRaised,
                borderRadius: BorderRadius.circular(DashUI.rCard),
                border: Border.all(color: AppColors.paperLine),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandDark.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: controller.animation ?? controller,
                builder: (context, _) {
                  final currentIndex = controller.index;

                  return Row(
                    children: [
                      _buildTabItem(
                        index: 0,
                        currentIndex: currentIndex,
                        icon: Icons.calendar_month_rounded,
                        label: 'ui.sheet_tab_logs'.tr2,
                      ),
                      _buildTabItem(
                        index: 1,
                        currentIndex: currentIndex,
                        icon: Icons.people_alt_rounded,
                        label: 'ui.sheet_tab_members'.tr2,
                      ),
                      _buildTabItem(
                        index: 2,
                        currentIndex: currentIndex,
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'ui.sheet_tab_deposits'.tr2,
                        countBadge: depositCount > 0 ? depositCount : null,
                      ),
                      _buildTabItem(
                        index: 3,
                        currentIndex: currentIndex,
                        icon: Icons.rule_folder_rounded,
                        label: 'ui.sheet_tab_approvals'.tr2,
                        isApproval: true,
                        countBadge: pendingCount > 0 ? pendingCount : null,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabItem({
    required int index,
    required int currentIndex,
    required IconData icon,
    required String label,
    int? countBadge,
    bool isApproval = false,
  }) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => controller.animateTo(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brandDark : Colors.transparent,
            borderRadius: BorderRadius.circular(DashUI.rTile),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.brandDark.withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with badge
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    icon,
                    size: 17.5,
                    color: isSelected ? Colors.white : AppColors.inkFaded,
                  ),
                  if (countBadge != null)
                    Positioned(
                      top: -3,
                      right: -10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 0.5,
                        ),
                        decoration: BoxDecoration(
                          color: isApproval
                              ? AppColors.accent
                              : (isSelected
                                    ? Colors.white.withValues(alpha: 0.28)
                                    : AppColors.emerald),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$countBadge',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: isApproval
                                ? Colors.white
                                : (isSelected ? Colors.white : Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2.5),
              // Text label
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.inkFaded,
                  letterSpacing: isSelected ? 0.2 : 0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
