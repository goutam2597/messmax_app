import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/mess_repository.dart';
import '../cubit/mess_cubit.dart';
import '../cubit/mess_state.dart';

class MessSheetScreen extends StatelessWidget {
  final int messId;
  final int monthId;
  final String monthLabel;
  const MessSheetScreen({
    super.key,
    required this.messId,
    required this.monthId,
    this.monthLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MessCubit()..loadSheet(messId, monthId),
      child: _SheetView(
        messId: messId,
        monthId: monthId,
        monthLabel: monthLabel,
      ),
    );
  }
}

class _SheetView extends StatefulWidget {
  final int messId;
  final int monthId;
  final String monthLabel;
  const _SheetView({
    required this.messId,
    required this.monthId,
    required this.monthLabel,
  });
  @override
  State<_SheetView> createState() => _SheetViewState();
}

class _SheetViewState extends State<_SheetView> {
  final _repo = MessRepository();
  bool _expandPassedDays = false;

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

  // Keys from PHP json are always strings ("15","9") — handle both
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paperRaised,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.monthLabel.isNotEmpty
                  ? widget.monthLabel
                  : 'Monthly Sheet',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
                fontSize: 16,
              ),
            ),
            const Text(
              'Daily Entries — Ledger Matrix',
              style: TextStyle(fontSize: 11, color: AppColors.inkFaded),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.ink,
              size: 20,
            ),
            onPressed: _refresh,
          ),
        ],
      ),
      body: BlocConsumer<MessCubit, MessState>(
        listener: (c, s) {
          if (s is MessSheetLoaded && s.message != null) {
            ScaffoldMessenger.of(
              c,
            ).showSnackBar(SnackBar(content: Text(s.message!)));
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
                      size: 40,
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
                      icon: const Icon(Icons.refresh_rounded, size: 15),
                      label: const Text('Try Again'),
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

          final mealRate = _toD(s['mealRate']);
          final totalGiven = _toD(s['totalGiven']);
          final restMoney = _toD(s['restMoney']);
          final totalMeals = _toD(s['totalMeals']);
          final extraCost = _toD(s['extraCost'] ?? monthRaw['extra_cost']);

          return RefreshIndicator(
            color: AppColors.brandDark,
            onRefresh: () async => _refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1) STAT CARDS — 2x2 like web (web has 5, we show 4; extra cost inside member area note)
                  _statRow(
                    mealRate: mealRate,
                    totalGiven: totalGiven,
                    restMoney: restMoney,
                    totalMeals: totalMeals,
                  ),

                  const SizedBox(height: 18),

                  // 2) MEMBER SUMMARY — each member card with edit button (manager only)
                  _memberSummary(
                    members: members,
                    summary: summary,
                    canManage: canManage,
                    extraCost: extraCost,
                    sheet: s,
                  ),

                  // 3) DEPOSIT CHITS
                  if (deposits.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _depositChits(deposits, canEdit),
                  ],

                  const SizedBox(height: 18),

                  // 4) DAILY ENTRIES header — hidden start notice + duplicate/add-guest buttons
                  _dailyEntriesHeader(
                    sheet: s,
                    canEdit: canEdit,
                    canManage: canManage,
                    startDay: startDay,
                    passedDays: passedDays,
                    members: members,
                  ),

                  // 5) Pending manager approvals
                  if (canManage)
                    _PendingSection(
                      messId: widget.messId,
                      monthId: widget.monthId,
                      sheet: s,
                      onHandled: _refresh,
                    ),

                  const SizedBox(height: 10),

                  // 6) Collapsed passed-days cards — manager can Edit, member sees lock
                  _dailyCards(
                    context: context,
                    startDay: startDay,
                    passedDays: passedDays,
                    days: days,
                    sheet: s,
                    canEdit: canEdit,
                    canAddBazar: canAddBazar,
                    members: members,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statRow({
    required double mealRate,
    required double totalGiven,
    required double restMoney,
    required double totalMeals,
  }) {
    Widget card(String label, String value, String sub, Color color) =>
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.paperRaised,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.paperLine),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkFaded,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: const TextStyle(fontSize: 10, color: AppColors.inkFaded),
              ),
            ],
          ),
        );
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: card(
                'MEAL RATE',
                '${mealRate.toStringAsFixed(2)} ৳',
                'SUM(Bazar)/SUM(Meals)',
                AppColors.ink,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: card(
                'TOTAL MONEY',
                '${totalGiven.toStringAsFixed(0)} ৳',
                'SUM(Given)',
                AppColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: card(
                'REST MONEY',
                '${restMoney.toStringAsFixed(0)} ৳',
                'Given − Bazar',
                restMoney >= 0 ? AppColors.emerald : AppColors.danger,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: card(
                'TOTAL MEALS',
                totalMeals % 1 == 0
                    ? totalMeals.toInt().toString()
                    : totalMeals.toStringAsFixed(1),
                'Σ meals (passed)',
                AppColors.ink,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _memberSummary({
    required List<dynamic> members,
    required List<dynamic> summary,
    required bool canManage,
    required double extraCost,
    required Map sheet,
  }) {
    final memberById = {for (final m in members) (m['id'].toString()): m};
    String fmtBld(dynamic v) {
      if (v == null) return '—';
      final d = _toD(v);
      if (d == 0) return 'OFF';
      return d % 1 == 0
          ? d.toInt().toString()
          : d.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'MEMBER SUMMARY — SPEND / GIVEN / REST',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppColors.inkFaded,
                letterSpacing: 0.6,
              ),
            ),
            if (canManage)
              InkWell(
                onTap: () => _showAddDepositModal(members),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandDark,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '+ Add deposit',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.paperRaised,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.paperLine),
          ),
          child: Column(
            children: [
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
                    final extraShare = members.isEmpty
                        ? 0
                        : extraCost / members.length;
                    final spend = _toD(row['spend']);
                    final given = _toD(row['given']);
                    final balance = _toD(row['balance']);
                    final isPositive = balance >= 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        border: i == 0
                            ? null
                            : const Border(
                                top: BorderSide(color: AppColors.paperLine),
                              ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: _hex(colorHex),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'M',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12.5,
                                          color: AppColors.ink,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: role == 'manager'
                                            ? AppColors.brandSoft
                                            : AppColors.paper,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: role == 'manager'
                                              ? AppColors.brandDark.withValues(
                                                  alpha: 0.15,
                                                )
                                              : AppColors.paperLine,
                                        ),
                                      ),
                                      child: Text(
                                        role.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w800,
                                          color: role == 'manager'
                                              ? AppColors.brandDark
                                              : AppColors.inkFaded,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                // web: Default B·L·D line + Meals | mealSpend | extra | SPEND | GIVEN | REST
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    if (hasBld)
                                      Text(
                                        '${fmtBld(memberRaw['default_breakfast'])} · ${fmtBld(memberRaw['default_lunch'])} · ${fmtBld(memberRaw['default_dinner'])}',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              (fmtBld(
                                                        memberRaw['default_breakfast'],
                                                      ) ==
                                                      'OFF' ||
                                                  fmtBld(
                                                        memberRaw['default_lunch'],
                                                      ) ==
                                                      'OFF' ||
                                                  fmtBld(
                                                        memberRaw['default_dinner'],
                                                      ) ==
                                                      'OFF')
                                              ? AppColors.danger
                                              : AppColors.inkFaded,
                                        ),
                                      ),
                                    Text(
                                      '${meals % 1 == 0 ? meals.toInt() : meals.toStringAsFixed(1)} meals',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.inkSoft,
                                      ),
                                    ),
                                    Text(
                                      'Spend ${spend.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    Text(
                                      'Extra ${extraShare.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.inkFaded,
                                      ),
                                    ),
                                    Text(
                                      'Given ${given.toStringAsFixed(0)} ৳',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.emerald,
                                      ),
                                    ),
                                    Text(
                                      '${isPositive ? '+' : ''}${balance.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: isPositive
                                            ? AppColors.emerald
                                            : AppColors.danger,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (canManage)
                            InkWell(
                              onTap: () => _showEditMemberModal(memberRaw),
                              borderRadius: BorderRadius.circular(7),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.paper,
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: AppColors.paperLine,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  size: 14,
                                  color: AppColors.inkSoft,
                                ),
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
      ],
    );
  }

  Widget _depositChits(List<dynamic> deposits, bool canEdit) {
    double totalDeposits = 0;
    for (final d in deposits) {
      totalDeposits += _toD(d['amount']);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.paperLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 16,
                color: AppColors.brandDark,
              ),
              const SizedBox(width: 6),
              const Text(
                'DEPOSIT CHITS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.emeraldSoft,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.emerald.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Total: ৳${totalDeposits.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.emerald,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in deposits)
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 5, 6, 5),
                  decoration: BoxDecoration(
                    color: AppColors.paperRaised,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.emerald.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: _hex(
                          (d['member']?['color'] ?? '#3b82f6').toString(),
                        ),
                        child: Text(
                          ((d['member']?['name'] ?? 'M')
                                  .toString()
                                  .isNotEmpty
                              ? (d['member']?['name'] ?? 'M')
                                    .toString()[0]
                                    .toUpperCase()
                              : 'M'),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        (d['member']?['name'] ?? 'Member').toString(),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldSoft,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '৳${_toD(d['amount']).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.emerald,
                          ),
                        ),
                      ),
                      if (canEdit && d['id'] != null) ...[
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _confirmDeleteDeposit(d['id'] as int),
                          borderRadius: BorderRadius.circular(10),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(
                              Icons.close_rounded,
                              size: 15,
                              color: AppColors.inkFaded,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteDeposit(int depositId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete deposit?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.deleteDeposit(
        widget.messId,
        widget.monthId,
        depositId,
      );
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  Widget _dailyEntriesHeader({
    required Map sheet,
    required bool canEdit,
    required bool canManage,
    required int startDay,
    required int passedDays,
    required List<dynamic> members,
  }) {
    final monthRaw = _asMap(sheet['month']);
    final label = (monthRaw['label'] ?? '').toString();
    final cycleLabel = (monthRaw['cycle_label'] ?? label).toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'DAILY ENTRIES — $cycleLabel',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (canManage)
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await _repo.duplicateMonth(widget.messId, widget.monthId);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Next month duplicated')),
                      );
                    } 
                    _refresh();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Duplicate failed: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.file_copy_outlined, size: 14),
                label: const Text(
                  'Duplicate',
                  style: TextStyle(fontSize: 11.5),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  minimumSize: const Size(0, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        if (startDay > 1) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.paperRaised,
              borderRadius: BorderRadius.circular(10),
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
                    'Showing from day $startDay — ${startDay - 1} day${startDay > 2 ? 's' : ''} before start hidden.',
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
        const SizedBox(height: 10),
        // Role-gated buttons row — exactly like web
        Row(
          children: [
            if (!canEdit) ...[
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _showMealOffModal(sheet),
                  icon: const Icon(Icons.event_busy_rounded, size: 16),
                  label: const Text(
                    'Request meal off',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _showGuestRequestModal(sheet),
                  icon: const Icon(Icons.person_add_rounded, size: 16),
                  label: const Text(
                    'Request guest',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandDark,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      _showAddGuestModal(members, passedDays, sheet),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                  label: const Text(
                    'Add guest meal',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _dailyCards({
    required BuildContext context,
    required int startDay,
    required int passedDays,
    required int days,
    required Map sheet,
    required bool canEdit,
    required bool canAddBazar,
    required List<dynamic> members,
  }) {
    final passedList = <int>[for (int d = startDay; d < passedDays; d++) d];
    final todayDay = passedDays > 0 ? passedDays : startDay;
    // All remaining days till 31 — no Add button needed
    final futureDays = <int>[for (int d = passedDays + 1; d <= days; d++) d];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (passedList.isNotEmpty) ...[
          Material(
            color: AppColors.paperRaised,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.paperLine),
            ),
            clipBehavior: Clip.antiAlias,
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                listTileTheme: const ListTileThemeData(
                  tileColor: Colors.transparent,
                  selectedTileColor: Colors.transparent,
                ),
              ),
              child: ExpansionTile(
                initiallyExpanded: _expandPassedDays,
                onExpansionChanged: (v) =>
                    setState(() => _expandPassedDays = v),
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                title: Text(
                  'Passed · $startDay – ${passedDays - 1}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                subtitle: Text(
                  '${passedList.length} days · tap to expand',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.inkFaded,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: Column(
                      children: [
                        for (final day in passedList)
                          _dayCard(
                            day: day,
                            sheet: sheet,
                            canEdit: canEdit,
                            canAddBazar: canAddBazar,
                            members: members,
                            isToday: false,
                            isPast: true,
                            isFuture: false,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Today's card (always)
        _dayCard(
          day: todayDay,
          sheet: sheet,
          canEdit: canEdit,
          canAddBazar: canAddBazar,
          members: members,
          isToday: true,
          isPast: false,
          isFuture: false,
        ),
        // Future manually-added cards
        for (final day in futureDays) ...[
          const SizedBox(height: 12),
          _dayCard(
            day: day,
            sheet: sheet,
            canEdit: canEdit,
            canAddBazar: canAddBazar,
            members: members,
            isToday: false,
            isPast: false,
            isFuture: true,
          ),
        ],
        const SizedBox(height: 14),
        // No Add next day — sheet renders all days till 31 (manager edits any day via Edit)
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.paperRaised,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.paperLine),
          ),
          child: const Text(
            'Each day has an Edit — change meals and bazar items together in one modal. Meals default from member settings · Bazar = Σ qty×price',
            style: TextStyle(fontSize: 10.5, color: AppColors.inkFaded),
          ),
        ),
      ],
    );
  }

  Widget _dayCard({
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

    Color borderColor = AppColors.paperLine;
    double borderW = 1;
    Color headerBg = AppColors.paper;
    if (isPast) headerBg = AppColors.paper.withValues(alpha: 0.75);
    if (isToday) {
      borderColor = AppColors.brandDark;
      borderW = 1.5;
      headerBg = AppColors.brandSoft.withValues(alpha: 0.35);
    }
    if (isFuture) {
      borderColor = AppColors.brandDark.withValues(alpha: 0.35);
      headerBg = AppColors.brandSoft.withValues(alpha: 0.18);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: borderW),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              border: const Border(
                bottom: BorderSide(color: AppColors.paperLine),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppColors.brandDark
                        : (isFuture
                              ? AppColors.brandDark.withValues(alpha: 0.85)
                              : AppColors.paperRaised),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isToday || isFuture
                          ? AppColors.brandDark
                          : AppColors.paperLine,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: isToday || isFuture
                            ? Colors.white
                            : AppColors.ink,
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
                            dateStr,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: AppColors.ink,
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.emeraldSoft,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'TODAY',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.emerald,
                                ),
                              ),
                            ),
                          ],
                          if (isFuture) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.brandSoft,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: AppColors.brandDark.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'FUTURE',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brandDark,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${dayTotal % 1 == 0 ? dayTotal.toInt() : dayTotal.toStringAsFixed(1)} meals · ${members.length} members',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.inkFaded,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canEdit)
                  OutlinedButton.icon(
                    onPressed: () => _openDayEdit(day, members, sheet),
                    icon: const Icon(Icons.edit_outlined, size: 13),
                    label: const Text('Edit', style: TextStyle(fontSize: 11.5)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: const Size(0, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: const BorderSide(color: AppColors.paperLine),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                else if (canAddBazar && isToday)
                  FilledButton.icon(
                    onPressed: () =>
                        _openDayEdit(day, members, sheet, bazarOnly: true),
                    icon: const Icon(Icons.shopping_basket_outlined, size: 13),
                    label: const Text(
                      'Bazar',
                      style: TextStyle(fontSize: 11.5),
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
                  )
                else
                  Row(
                    children: const [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 12,
                        color: AppColors.inkFaded,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'View only',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.inkFaded,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dayBazarBox(
                  day: day,
                  bazarTotal: bazarTotal,
                  items: items,
                  receipts: receipts,
                  canAddBazar: canAddBazar,
                  isToday: isToday,
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.paperLine),
                const SizedBox(height: 10),
                _dayMealsBox(
                  day: day,
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
      ),
    );
  }

  Widget _dayBazarBox({
    required int day,
    required double bazarTotal,
    required List<dynamic> items,
    required List<dynamic> receipts,
    required bool canAddBazar,
    required bool isToday,
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
                  Icons.shopping_basket_outlined,
                  size: 13,
                  color: AppColors.brandDark,
                ),
                SizedBox(width: 4),
                Text(
                  'BAZAR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkFaded,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
            if (bazarTotal > 0)
              Text(
                '${bazarTotal.toStringAsFixed(2)} ৳',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (bazarTotal == 0 && items.isEmpty)
          const Text(
            'No bazar yet.',
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.inkFaded,
              fontStyle: FontStyle.italic,
            ),
          )
        else ...[
          for (final it in items)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      (it['name'] ?? 'Item').toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkSoft,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(it['qty'] ?? '').toString()} × ${(it['price'] ?? '').toString()} = ${(_toD(it['qty']) * _toD(it['price'])).toStringAsFixed(2)} ৳',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkFaded,
                    ),
                  ),
                ],
              ),
            ),
          if (receipts.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final r in receipts)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft.withValues(alpha: 0.4),
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
                            fontWeight: FontWeight.w600,
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

  Widget _dayMealsBox({
    required int day,
    required List<dynamic> members,
    required Map mealsMap,
    required Map mealsBMap,
    required Map mealsLMap,
    required Map mealsDMap,
    required List<dynamic> guestList,
  }) {
    String fmt(dynamic v) {
      if (v == null) return '—';
      final d = _toD(v);
      if (d == 0) return '0';
      return d % 1 == 0 ? d.toInt().toString() : d.toStringAsFixed(1);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(
              Icons.restaurant_menu_rounded,
              size: 13,
              color: AppColors.brandDark,
            ),
            SizedBox(width: 4),
            Text(
              'MEALS — B · L · D',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.inkFaded,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
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
              // B/L/D
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
              final countStr = count % 1 == 0
                  ? count.toInt().toString()
                  : count.toStringAsFixed(1);
              final isOff = count == 0 && hasParts;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: _hex(colorHex),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'M',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isOff)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.dangerSoft,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Text(
                          'OFF',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.danger,
                          ),
                        ),
                      )
                    else if (hasParts)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.paperLine),
                        ),
                        child: Text(
                          '${fmt(bRaw)} · ${fmt(lRaw)} · ${fmt(dRaw)} = $countStr',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      )
                    else
                      Text(
                        '$countStr meals',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
        if (guestList.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.brandSoft.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
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
                    SizedBox(width: 4),
                    Text(
                      'GUESTS (with host)',
                      style: TextStyle(
                        fontSize: 9,
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
                            '${g['guest_name'] ?? 'Guest'} ×${g['guest_count'] ?? 1} · ${(g['slots'] as List?)?.join(' + ') ?? ''}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.inkSoft,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _toD(g['count']).toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11,
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
        ],
      ],
    );
  }

  // --- Modals (web parity) ---

  void _showAddDepositModal(List<dynamic> members) {
    if (members.isEmpty) return;
    int selectedId = _toI(members.first['id']);
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final dateCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().split('T')[0],
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: AppColors.paperRaised,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Add deposit — manager only',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                initialValue: selectedId,
                decoration: const InputDecoration(labelText: 'Member'),
                items: [
                  for (final m in members)
                    DropdownMenuItem<int>(
                      value: _toI(m['id']),
                      child: Text((m['name'] ?? 'Member').toString()),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) selectedId = v;
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount ৳ *',
                  hintText: '2000',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: dateCtrl,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Date'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2027),
                  );
                  if (picked != null) {
                    dateCtrl.text = picked.toIso8601String().split('T')[0];
                  }
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  hintText: 'e.g. cash',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final amt = _toD(amountCtrl.text);
                        if (amt <= 0) return;
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
                            Navigator.pop(ctx);
                            _refresh();
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Deposit failed: $e')),
                            );
                          }
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.ink,
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditMemberModal(Map memberRaw) {
    final name = (memberRaw['name'] ?? 'Member').toString();
    final memberId = _toI(memberRaw['id']);
    final bfCtrl = TextEditingController(
      text: memberRaw['default_breakfast'] != null
          ? _toD(memberRaw['default_breakfast']).toStringAsFixed(2)
          : '',
    );
    final lCtrl = TextEditingController(
      text: memberRaw['default_lunch'] != null
          ? _toD(memberRaw['default_lunch']).toStringAsFixed(2)
          : '',
    );
    final dCtrl = TextEditingController(
      text: memberRaw['default_dinner'] != null
          ? _toD(memberRaw['default_dinner']).toStringAsFixed(2)
          : '',
    );
    final legacyCtrl = TextEditingController(
      text: memberRaw['default_meal'] != null
          ? _toD(memberRaw['default_meal']).toStringAsFixed(2)
          : '',
    );
    final depAmountCtrl = TextEditingController();
    final depNoteCtrl = TextEditingController();
    bool showLegacy = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx2).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: AppColors.paperRaised,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Edit member',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Editing: $name',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Set a default meal, or add a deposit — manager only.',
                    style: TextStyle(fontSize: 11, color: AppColors.inkFaded),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: bfCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: "B'FAST (0=OFF)",
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: lCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'LUNCH (0=OFF)',
                            filled: lCtrl.text == '0.00',
                            fillColor: lCtrl.text == '0.00'
                                ? AppColors.dangerSoft
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: dCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'DINNER (0=OFF)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => setS(() => showLegacy = !showLegacy),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.paperLine),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'LEGACY TOTAL — DEFAULT MEAL',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.inkFaded,
                            ),
                          ),
                          Icon(
                            showLegacy
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: AppColors.inkFaded,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (showLegacy) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: legacyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Legacy total',
                        hintText: 'e.g. 2.00',
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Text(
                    '0 = OFF for that slot (red mark on cards). Empty = no default for that slot. If any B/L/D is set (even 0), B·L·D is used; else legacy total is used.',
                    style: TextStyle(fontSize: 10.5, color: AppColors.inkFaded),
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.paperLine),
                  const SizedBox(height: 12),
                  const Text(
                    'ADD DEPOSIT (OPTIONAL)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.inkFaded,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: depAmountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Amount ৳',
                            hintText: 'e.g. 2000',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: depNoteCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Note',
                            hintText: 'e.g. cash',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx2),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            double? bf = bfCtrl.text.trim().isEmpty
                                ? null
                                : _toD(bfCtrl.text);
                            double? ln = lCtrl.text.trim().isEmpty
                                ? null
                                : _toD(lCtrl.text);
                            double? dn = dCtrl.text.trim().isEmpty
                                ? null
                                : _toD(dCtrl.text);
                            double? legacy = legacyCtrl.text.trim().isEmpty
                                ? null
                                : _toD(legacyCtrl.text);
                            double? depAmt = depAmountCtrl.text.trim().isEmpty
                                ? null
                                : _toD(depAmountCtrl.text);
                            try {
                              await _repo.updateMemberDetails(
                                widget.messId,
                                memberId,
                                breakfast: bf,
                                lunch: ln,
                                dinner: dn,
                                defaultMeal: legacy,
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
                                  SnackBar(content: Text('Save failed: $e')),
                                );
                              }
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.ink,
                          ),
                          child: const Text('Save changes ✓'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMealOffModal(Map sheet) {
    int selectedDay = _toI(sheet['todayDay'] ?? sheet['passedDays'] ?? 1);
    // Prefill from sheet myMealB/L/D and myDefaults
    final myB = _asMap(sheet['myMealB']);
    final myL = _asMap(sheet['myMealL']);
    final myD = _asMap(sheet['myMealD']);
    // For simplicity show day picker + 3 toggles (web: calendar + breakfast_on etc.)
    bool bOn = true, lOn = true, dOn = true;
    final noteCtrl = TextEditingController();
    final monthRaw = _asMap(sheet['month']);
    final days = _toI(monthRaw['days']) > 0 ? _toI(monthRaw['days']) : 31;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) {
          void applyDayPrefill() {
            final k = selectedDay.toString();
            bOn = !(_toD(myB[k] ?? myB[selectedDay]) == 0);
            lOn = !(_toD(myL[k] ?? myL[selectedDay]) == 0);
            dOn = !(_toD(myD[k] ?? myD[selectedDay]) == 0);
          }

          applyDayPrefill();
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx2).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppColors.paperRaised,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.event_busy_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Request meal off',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Day $selectedDay in Asia/Dhaka — ${monthRaw['label'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.inkFaded,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Simple day grid
                    _guestDateGrid(
                      days: days,
                      selectedDay: selectedDay,
                      onTap: (d) => setS(() {
                        selectedDay = d;
                        applyDayPrefill();
                      }),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            title: const Text(
                              'Breakfast',
                              style: TextStyle(fontSize: 13),
                            ),
                            value: bOn,
                            onChanged: (v) => setS(() => bOn = v ?? false),
                          ),
                        ),
                        Expanded(
                          child: CheckboxListTile(
                            title: const Text(
                              'Lunch',
                              style: TextStyle(fontSize: 13),
                            ),
                            value: lOn,
                            onChanged: (v) => setS(() => lOn = v ?? false),
                          ),
                        ),
                        Expanded(
                          child: CheckboxListTile(
                            title: const Text(
                              'Dinner',
                              style: TextStyle(fontSize: 13),
                            ),
                            value: dOn,
                            onChanged: (v) => setS(() => dOn = v ?? false),
                          ),
                        ),
                      ],
                    ),
                    TextField(
                      controller: noteCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                        hintText: 'e.g. Not home',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx2),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
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
                                    SnackBar(
                                      content: Text('Request failed: $e'),
                                    ),
                                  );
                                }
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.ink,
                            ),
                            child: const Text('Send request'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showGuestRequestModal(Map sheet) {
    int selectedDay = _toI(sheet['todayDay'] ?? sheet['passedDays'] ?? 1);
    final monthRaw = _asMap(sheet['month']);
    final days = _toI(monthRaw['days']) > 0 ? _toI(monthRaw['days']) : 31;
    final label = (monthRaw['label'] ?? monthRaw['cycle_label'] ?? '')
        .toString();
    final nameCtrl = TextEditingController();
    int guestCount = 1;
    bool b = false, l = false, dn = false;
    final noteCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) {
          bool canSubmit =
              nameCtrl.text.trim().isNotEmpty &&
              guestCount > 0 &&
              (b || l || dn);
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx2).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.paperRaised,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 10, 0),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(
                              Icons.person_add_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 11),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Request guest meal',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.ink,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Manager will approve — then it counts',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.inkFaded,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx2),
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: AppColors.inkFaded,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Pick a date — $label',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.inkFaded,
                              letterSpacing: 0.7,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _guestDateGrid(
                            days: days,
                            selectedDay: selectedDay,
                            onTap: (d) => setS(() => selectedDay = d),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: nameCtrl,
                            onChanged: (_) => setS(() {}),
                            decoration: InputDecoration(
                              labelText: 'GUEST NAME *',
                              hintText: 'e.g. Mother / Friend',
                              prefixIcon: const Icon(
                                Icons.badge_outlined,
                                size: 18,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 11,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text(
                                'GUESTS *',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.inkFaded,
                                  letterSpacing: 0.7,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.paper,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.paperLine,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        if (guestCount > 1) {
                                          setS(() => guestCount--);
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Icon(
                                          Icons.remove_rounded,
                                          size: 18,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      child: Text(
                                        '$guestCount',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => setS(() => guestCount++),
                                      borderRadius: BorderRadius.circular(8),
                                      child: const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Icon(
                                          Icons.add_rounded,
                                          size: 18,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'MEAL SLOTS *',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.inkFaded,
                              letterSpacing: 0.7,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              for (final e in [
                                {
                                  'k': 'b',
                                  'label': 'Breakfast',
                                  'icon': Icons.free_breakfast_outlined,
                                  'v': b,
                                },
                                {
                                  'k': 'l',
                                  'label': 'Lunch',
                                  'icon': Icons.lunch_dining_outlined,
                                  'v': l,
                                },
                                {
                                  'k': 'd',
                                  'label': 'Dinner',
                                  'icon': Icons.dinner_dining_outlined,
                                  'v': dn,
                                },
                              ])
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: (e['k'] as String) == 'd' ? 0 : 8,
                                    ),
                                    child: InkWell(
                                      onTap: () => setS(() {
                                        if (e['k'] == 'b') b = !b;
                                        if (e['k'] == 'l') l = !l;
                                        if (e['k'] == 'd') dn = !dn;
                                      }),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: (e['v'] as bool)
                                              ? AppColors.ink
                                              : AppColors.paper,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: (e['v'] as bool)
                                                ? AppColors.ink
                                                : AppColors.paperLine,
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              e['icon'] as IconData,
                                              size: 18,
                                              color: (e['v'] as bool)
                                                  ? Colors.white
                                                  : AppColors.inkFaded,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              e['label'] as String,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: (e['v'] as bool)
                                                    ? Colors.white
                                                    : AppColors.ink,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (!b && !l && !dn)
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text(
                                'Select at least one slot — host pays for checked slots.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.danger,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: noteCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'NOTE (optional)',
                              hintText: 'e.g. Guest staying 2 days',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(ctx2),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton(
                                  onPressed: !canSubmit
                                      ? null
                                      : () async {
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
                                              ScaffoldMessenger.of(
                                                ctx2,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Request failed: $e',
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.ink,
                                    disabledBackgroundColor:
                                        AppColors.paperLine,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Send request',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
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
    final noteCtrl = TextEditingController();
    final sheetLabel =
        (sheet['month'] is Map
                ? (sheet['month']['label'] ?? sheet['month']['cycle_label'])
                : '')
            ?.toString() ??
        '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) {
          bool canSubmit = nameCtrl.text.trim().isNotEmpty && (b || l || dn);
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx2).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.paperRaised,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 10, 0),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Add guest meal',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Color(0xFFFFE8D6),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.fromBorderSide(
                                          BorderSide(color: Color(0xFFFFAB78)),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        child: Text(
                                          'MANAGER',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFFE65100),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Manager creates directly — no approval needed.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.inkFaded,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx2),
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: AppColors.inkFaded,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pick a date — $sheetLabel',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.inkFaded,
                              letterSpacing: 0.7,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _guestDateGrid(
                            days: days,
                            selectedDay: selectedDay,
                            onTap: (d) => setS(() => selectedDay = d),
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<int>(
                            initialValue: hostId,
                            decoration: InputDecoration(
                              labelText: 'HOST MEMBER *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 11,
                              ),
                            ),
                            items: [
                              for (final m in members)
                                DropdownMenuItem<int>(
                                  value: _toI(m['id']),
                                  child: Text(
                                    '${m['name']} — ${m['member_role'] ?? 'member'}',
                                  ),
                                ),
                            ],
                            onChanged: (v) {
                              if (v != null) hostId = v;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: nameCtrl,
                            onChanged: (_) => setS(() {}),
                            decoration: InputDecoration(
                              labelText: 'GUEST NAME *',
                              hintText: 'e.g. Mother / Friend',
                              prefixIcon: const Icon(
                                Icons.badge_outlined,
                                size: 18,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 11,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text(
                                'GUESTS *',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.inkFaded,
                                  letterSpacing: 0.7,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.paper,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.paperLine,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        if (guestCount > 1) {
                                          setS(() => guestCount--);
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Icon(
                                          Icons.remove_rounded,
                                          size: 18,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      child: Text(
                                        '$guestCount',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => setS(() => guestCount++),
                                      borderRadius: BorderRadius.circular(8),
                                      child: const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Icon(
                                          Icons.add_rounded,
                                          size: 18,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'MEAL SLOTS *',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.inkFaded,
                              letterSpacing: 0.7,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              for (final e in [
                                {
                                  'k': 'b',
                                  'label': 'Breakfast',
                                  'icon': Icons.free_breakfast_outlined,
                                  'v': b,
                                },
                                {
                                  'k': 'l',
                                  'label': 'Lunch',
                                  'icon': Icons.lunch_dining_outlined,
                                  'v': l,
                                },
                                {
                                  'k': 'd',
                                  'label': 'Dinner',
                                  'icon': Icons.dinner_dining_outlined,
                                  'v': dn,
                                },
                              ])
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: (e['k'] as String) == 'd' ? 0 : 8,
                                    ),
                                    child: InkWell(
                                      onTap: () => setS(() {
                                        if (e['k'] == 'b') b = !b;
                                        if (e['k'] == 'l') l = !l;
                                        if (e['k'] == 'd') dn = !dn;
                                      }),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: (e['v'] as bool)
                                              ? AppColors.ink
                                              : AppColors.paper,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: (e['v'] as bool)
                                                ? AppColors.ink
                                                : AppColors.paperLine,
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              e['icon'] as IconData,
                                              size: 18,
                                              color: (e['v'] as bool)
                                                  ? Colors.white
                                                  : AppColors.inkFaded,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              e['label'] as String,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: (e['v'] as bool)
                                                    ? Colors.white
                                                    : AppColors.ink,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (!b && !l && !dn)
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text(
                                'Select at least one slot — creates a future card if beyond today.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.danger,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: noteCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'NOTE (optional)',
                              hintText: 'e.g. Guest staying 2 days',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Creates a FUTURE card if the day is beyond today. Counts toward host immediately.',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: AppColors.inkFaded,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(ctx2),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton(
                                  onPressed: !canSubmit
                                      ? null
                                      : () async {
                                          if (nameCtrl.text.trim().isEmpty) {
                                            return;
                                          }
                                          final cnt = guestCount;
                                          try {
                                            await _repo.addGuestDirect(
                                              widget.messId,
                                              widget.monthId,
                                              memberId: hostId,
                                              day: selectedDay,
                                              guestName: nameCtrl.text.trim(),
                                              guestCount: cnt > 0 ? cnt : 1,
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
                                              ScaffoldMessenger.of(
                                                ctx2,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Add guest failed: $e',
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.ink,
                                    disabledBackgroundColor:
                                        AppColors.paperLine,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Add guest ✓',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
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
            ),
          );
        },
      ),
    );
  }

  Widget _guestDateGrid({
    required int days,
    required int selectedDay,
    required ValueChanged<int> onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(12),
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
          return InkWell(
            onTap: () => onTap(d),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? AppColors.ink : AppColors.paperRaised,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.ink : AppColors.paperLine,
                ),
              ),
              child: Center(
                child: Text(
                  '$d',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : AppColors.ink,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

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
    final Set<int> removedReceiptIds = {};
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx2).viewInsets.bottom,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx2).size.height * 0.88,
              ),
              decoration: const BoxDecoration(
                color: AppColors.paperRaised,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.paperLine,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: AppColors.brandDark,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: Colors.white,
                            size: 20,
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
                                    bazarOnly ? 'Bazar Log' : 'Bazar & Meals',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandSoft,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Day $day',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.brandDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                bazarOnly
                                    ? 'Record daily bazar market costs'
                                    : 'Update daily meals and market expenses',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.inkFaded,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx2),
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 22,
                            color: AppColors.inkFaded,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.paperLine),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1) BAZAR ITEMS SECTION
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.paper,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.paperLine),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.shopping_bag_outlined,
                                      size: 16,
                                      color: AppColors.brandDark,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'BAZAR ITEMS',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.ink,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (bazarTotal > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.emeraldSoft,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: AppColors.emerald.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'Total: ৳${bazarTotal.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.emerald,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
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
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          flex: 1,
                                          child: TextField(
                                            controller: rows[i]['qty']!,
                                            keyboardType:
                                                TextInputType.number,
                                            onChanged: (_) => setS(() {}),
                                            textAlign: TextAlign.center,
                                            decoration: InputDecoration(
                                              hintText: 'Qty',
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 9,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          flex: 2,
                                          child: TextField(
                                            controller: rows[i]['price']!,
                                            keyboardType:
                                                TextInputType.number,
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
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(4),
                                          icon: const Icon(
                                            Icons.remove_circle_outline_rounded,
                                            size: 18,
                                            color: AppColors.danger,
                                          ),
                                          onPressed: rows.length == 1
                                              ? null
                                              : () => setS(
                                                    () => rows.removeAt(i),
                                                  ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                OutlinedButton.icon(
                                  onPressed: () => setS(
                                    () => rows.add({
                                      'name': TextEditingController(),
                                      'qty': TextEditingController(text: '1'),
                                      'price': TextEditingController(),
                                    }),
                                  ),
                                  icon: const Icon(Icons.add_rounded, size: 16),
                                  label: const Text(
                                    'Add Item Row',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 38),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // 2) RECEIPTS ATTACHMENT CARD
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.paper,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.paperLine),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.receipt_long_outlined,
                                      size: 15,
                                      color: AppColors.brandDark,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'RECEIPTS & VOUCHERS',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.ink,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (existingReceipts.isNotEmpty) ...[
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      for (final r in existingReceipts)
                                        Builder(
                                          builder: (_) {
                                            final rid = _toI(r['id']);
                                            final removed =
                                                removedReceiptIds.contains(rid);
                                            return InkWell(
                                              onTap: () => setS(() {
                                                if (removed) {
                                                  removedReceiptIds.remove(rid);
                                                } else {
                                                  removedReceiptIds.add(rid);
                                                }
                                              }),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: removed
                                                      ? AppColors.dangerSoft
                                                      : AppColors.brandSoft
                                                            .withValues(
                                                              alpha: 0.35,
                                                            ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: removed
                                                        ? AppColors.danger
                                                              .withValues(
                                                                alpha: 0.3,
                                                              )
                                                        : AppColors.brandDark
                                                              .withValues(
                                                                alpha: 0.15,
                                                              ),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      removed
                                                          ? Icons.close_rounded
                                                          : Icons
                                                                .receipt_outlined,
                                                      size: 12,
                                                      color: removed
                                                          ? AppColors.danger
                                                          : AppColors.brandDark,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      (r['name'] ??
                                                              r['original_name'] ??
                                                              'Receipt')
                                                          .toString()
                                                          .split('/')
                                                          .last,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: removed
                                                            ? AppColors.danger
                                                            : AppColors.ink,
                                                        decoration: removed
                                                            ? TextDecoration
                                                                  .lineThrough
                                                            : null,
                                                      ),
                                                    ),
                                                    if (removed)
                                                      const Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                              left: 4,
                                                            ),
                                                        child: Text(
                                                          'undo',
                                                          style: TextStyle(
                                                            fontSize: 9,
                                                            color:
                                                                AppColors
                                                                    .danger,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                if (pickedReceipts.isNotEmpty) ...[
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      for (final f in pickedReceipts)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.emeraldSoft,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: AppColors.emerald
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.check_circle_rounded,
                                                size: 12,
                                                color: AppColors.emerald,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                f.name,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.ink,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              InkWell(
                                                onTap: () => setS(
                                                  () => pickedReceipts.remove(
                                                    f,
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.close_rounded,
                                                  size: 14,
                                                  color: AppColors.inkFaded,
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
                                          final files =
                                              await picker.pickMultiImage(
                                                imageQuality: 80,
                                              );
                                          if (files.isNotEmpty) {
                                            setS(
                                              () =>
                                                  pickedReceipts.addAll(files),
                                            );
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.photo_library_outlined,
                                          size: 15,
                                        ),
                                        label: const Text(
                                          'Pick Images',
                                          style: TextStyle(fontSize: 12),
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
                                          Icons.photo_camera_outlined,
                                          size: 15,
                                        ),
                                        label: const Text(
                                          'Camera',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // 3) DAILY MEALS SECTION (if !bazarOnly)
                          if (!bazarOnly) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.paper,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.paperLine),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.restaurant_menu_rounded,
                                        size: 16,
                                        color: AppColors.brandDark,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'DAILY MEALS (B · L · D)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.ink,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    '0 = OFF (red pill). Empty = keep existing.',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.inkFaded,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  for (final m in members) ...[
                                    Builder(
                                      builder: (_) {
                                        final mid = _toI(m['id']);
                                        final ctrls = mealCtrls[mid]!;
                                        return Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppColors.paperRaised,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color: AppColors.paperLine,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  (m['name'] ?? 'Member')
                                                      .toString(),
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.ink,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: TextField(
                                                  controller: ctrls['b']!,
                                                  keyboardType:
                                                      const TextInputType.numberWithOptions(
                                                        decimal: true,
                                                      ),
                                                  textAlign: TextAlign.center,
                                                  decoration: InputDecoration(
                                                    labelText: 'B',
                                                    hintText: '—',
                                                    isDense: true,
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 7,
                                                        ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              Expanded(
                                                child: TextField(
                                                  controller: ctrls['l']!,
                                                  keyboardType:
                                                      const TextInputType.numberWithOptions(
                                                        decimal: true,
                                                      ),
                                                  textAlign: TextAlign.center,
                                                  decoration: InputDecoration(
                                                    labelText: 'L',
                                                    hintText: '—',
                                                    isDense: true,
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 7,
                                                        ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              Expanded(
                                                child: TextField(
                                                  controller: ctrls['d']!,
                                                  keyboardType:
                                                      const TextInputType.numberWithOptions(
                                                        decimal: true,
                                                      ),
                                                  textAlign: TextAlign.center,
                                                  decoration: InputDecoration(
                                                    labelText: 'D',
                                                    hintText: '—',
                                                    isDense: true,
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 7,
                                                        ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
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
                          ],

                          // 4) APPROVED GUESTS (IF ANY)
                          Builder(
                            builder: (_) {
                              final guestListForDay =
                                  (_byDay(_asMap(sheet['guestByDay']), day)
                                      is List)
                                  ? (_byDay(_asMap(sheet['guestByDay']), day)
                                        as List)
                                  : <dynamic>[];
                              final passedForGuest = _toI(
                                sheet['passedDays'] ??
                                    _asMap(sheet['month'])['passed_days'],
                              );
                              final isFutureGuestDay = day > passedForGuest;
                              if (guestListForDay.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 14),
                                  const Text(
                                    'APPROVED GUESTS ON THIS DAY',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.inkFaded,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  for (final g in guestListForDay)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.emeraldSoft.withValues(
                                          alpha: 0.3,
                                        ),
                                        borderRadius: BorderRadius.circular(9),
                                        border: Border.all(
                                          color: AppColors.emerald.withValues(
                                            alpha: 0.2,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${g['guest_name'] ?? 'Guest'} ×${g['guest_count'] ?? 1} · ${(g['slots'] is List ? (g['slots'] as List).join(' + ') : (g['count'] ?? '').toString())}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.ink,
                                              ),
                                            ),
                                          ),
                                          if (isFutureGuestDay)
                                            TextButton(
                                              onPressed: () async {
                                                final ok =
                                                    await showDialog<bool>(
                                                      context: context,
                                                      builder: (c) =>
                                                          AlertDialog(
                                                            title: Text(
                                                              'Remove guest ${g['guest_name'] ?? ''}?',
                                                            ),
                                                            content: const Text(
                                                              'This cannot be undone.',
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                      c,
                                                                      false,
                                                                    ),
                                                                child:
                                                                    const Text(
                                                                      'Cancel',
                                                                    ),
                                                              ),
                                                              FilledButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                      c,
                                                                      true,
                                                                    ),
                                                                style: FilledButton.styleFrom(
                                                                  backgroundColor:
                                                                      AppColors
                                                                          .danger,
                                                                ),
                                                                child:
                                                                    const Text(
                                                                      'Remove',
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                    );
                                                if (ok != true) return;
                                                try {
                                                  await _repo.removeGuestMeal(
                                                    widget.messId,
                                                    widget.monthId,
                                                    _toI(g['id']),
                                                  );
                                                  if (context.mounted) {
                                                    Navigator.pop(ctx2);
                                                    _refresh();
                                                  }
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                      ctx2,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Remove failed: $e',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                              child: const Text(
                                                'Remove',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.danger,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            )
                                          else
                                            const Text(
                                              'past/today',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.inkFaded,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
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
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Cancel'),
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
                                if (items.isNotEmpty) {
                                  await _repo.saveBazarItems(
                                    messId: widget.messId,
                                    monthId: widget.monthId,
                                    day: day,
                                    items: items,
                                  );
                                } else if (bazarOnly) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(ctx2).showSnackBar(
                                    const SnackBar(
                                      content: Text('Add at least one item'),
                                    ),
                                  );
                                  return;
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
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text(
                              'Save Entry',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.ink,
                              minimumSize: const Size(double.infinity, 44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
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
}

class _PendingSection extends StatelessWidget {
  final int messId;
  final int monthId;
  final Map sheet;
  final VoidCallback onHandled;
  const _PendingSection({
    required this.messId,
    required this.monthId,
    required this.sheet,
    required this.onHandled,
  });
  @override
  Widget build(BuildContext context) {
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
      return const SizedBox.shrink();
    }
    final repo = MessRepository();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(
              Icons.pending_actions_rounded,
              size: 14,
              color: AppColors.brandDark,
            ),
            SizedBox(width: 6),
            Text(
              'PENDING MANAGER APPROVALS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.brandDark,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final r in pendingOff)
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.brandSoft.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: AppColors.brandDark.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandDark,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Day ${r['day']}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (r['member_name'] ?? r['member']?['name'] ?? 'Member')
                            .toString(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        '${r['label'] ?? (r['is_reenable'] == true ? 'Meal ON' : 'Meal OFF')}${r['note'] != null && r['note'].toString().isNotEmpty ? ' · "${r['note']}"' : ''}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  onPressed: () async {
                    await repo.handleMealOff(
                      messId,
                      monthId,
                      r['id'] as int,
                      'deny',
                    );
                    onHandled();
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.danger,
                    size: 20,
                  ),
                ),
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  onPressed: () async {
                    await repo.handleMealOff(
                      messId,
                      monthId,
                      r['id'] as int,
                      'approve',
                    );
                    onHandled();
                  },
                  icon: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.emerald,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        for (final gr in pendingGuest)
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.emeraldSoft.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.emerald,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Day ${gr['day']}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${gr['member_name'] ?? gr['member']?['name'] ?? 'Member'} · ${gr['guest_name'] ?? 'Guest'} ×${gr['guest_count'] ?? 1}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'Guest Meal Request${gr['note'] != null && gr['note'].toString().isNotEmpty ? ' · "${gr['note']}"' : ''}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  onPressed: () async {
                    await repo.handleGuestMeal(
                      messId,
                      monthId,
                      gr['id'] as int,
                      'deny',
                    );
                    onHandled();
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.danger,
                    size: 20,
                  ),
                ),
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  onPressed: () async {
                    await repo.handleGuestMeal(
                      messId,
                      monthId,
                      gr['id'] as int,
                      'approve',
                    );
                    onHandled();
                  },
                  icon: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.emerald,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
