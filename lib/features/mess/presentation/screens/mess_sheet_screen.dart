import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/mess_cubit.dart';
import '../cubit/mess_state.dart';
import '../../data/repositories/mess_repository.dart';

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

  void _refresh() =>
      context.read<MessCubit>().loadSheet(widget.messId, widget.monthId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paperRaised,
        elevation: 0,
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
              '31-day ledger • role-gated actions',
              style: TextStyle(fontSize: 11, color: AppColors.inkFaded),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.ink),
            onPressed: _refresh,
          ),
        ],
      ),
      body: BlocConsumer<MessCubit, MessState>(
        listener: (context, state) {
          if (state is MessSheetLoaded && state.message != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        builder: (context, state) {
          if (state is MessLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.brandDark),
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
                      size: 42,
                      color: AppColors.danger,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.inkFaded),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _refresh,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandDark,
                      ),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is MessSheetLoaded) {
            final s = state.sheet;
            double toDouble(dynamic v) {
              if (v == null) return 0;
              if (v is num) return v.toDouble();
              if (v is String) return double.tryParse(v) ?? 0;
              return 0;
            }

            int toInt(dynamic v) {
              if (v == null) return 0;
              if (v is num) return v.toInt();
              if (v is String) return int.tryParse(v) ?? 0;
              return 0;
            }

            final canEdit = s['canEdit'] as bool? ?? false;
            final canManage = s['canManage'] as bool? ?? false;
            final canAddBazar = s['canAddBazar'] as bool? ?? false;
            final members = (s['members'] as List<dynamic>? ?? []);
            final summary = s['summary'] as List<dynamic>? ?? [];
            final totalBazar = toDouble(s['totalBazar']);
            final totalMeals = toDouble(s['totalMeals']);
            final mealRate = toDouble(s['mealRate']);
            final restMoney = toDouble(s['restMoney']);
            final days = toInt(s['month']?['days']);
            final passedDays = toInt(s['passedDays']);
            final meals = s['meals'] as Map<String, dynamic>? ?? {};
            final rowTotals = s['rowTotals'] as Map<String, dynamic>? ?? {};
            final deposits = s['deposits'] as List<dynamic>? ?? [];

            return RefreshIndicator(
              color: AppColors.brandDark,
              onRefresh: () async => _refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // stat pills
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _pill('Meals', '$totalMeals', AppColors.brandDark),
                          const SizedBox(width: 8),
                          _pill(
                            'Bazar',
                            '৳${totalBazar.toStringAsFixed(0)}',
                            AppColors.emerald,
                          ),
                          const SizedBox(width: 8),
                          _pill(
                            'Rate',
                            '৳${mealRate.toStringAsFixed(2)}',
                            AppColors.amber,
                          ),
                          const SizedBox(width: 8),
                          _pill(
                            'Rest',
                            '৳${restMoney.toStringAsFixed(0)}',
                            restMoney >= 0
                                ? AppColors.emerald
                                : AppColors.danger,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // role-gated action bar — wrap to avoid infinite-width inside SingleChildScrollView
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (canManage) ...[
                          FilledButton.icon(
                            onPressed: () => _autofill(context),
                            icon: const Icon(
                              Icons.auto_fix_high_rounded,
                              size: 16,
                            ),
                            label: const Text('Autofill Defaults'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.brandDark,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _addNextDay(context),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Next Day'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _showDepositSheet(context, members),
                            icon: const Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 16,
                            ),
                            label: const Text('Deposit'),
                          ),
                        ],
                        if (!canManage) ...[
                          FilledButton.icon(
                            onPressed: () =>
                                _showMealOffRequest(context, passedDays),
                            icon: const Icon(
                              Icons.event_busy_rounded,
                              size: 16,
                            ),
                            label: const Text('Request Meal Off'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.brandDark,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _showGuestRequest(context, passedDays),
                            icon: const Icon(
                              Icons.person_add_rounded,
                              size: 16,
                            ),
                            label: const Text('Guest Meal'),
                          ),
                        ],
                        if (canManage)
                          OutlinedButton.icon(
                            onPressed: () => _showGuestDirectSheet(
                              context,
                              members,
                              passedDays,
                            ),
                            icon: const Icon(
                              Icons.person_add_alt_1_rounded,
                              size: 16,
                            ),
                            label: const Text('Add Guest'),
                          ),
                        if (canAddBazar)
                          OutlinedButton.icon(
                            onPressed: () =>
                                _showBazarSheet(context, passedDays),
                            icon: const Icon(
                              Icons.shopping_basket_rounded,
                              size: 16,
                            ),
                            label: const Text('Bazar'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // pending requests (manager sees approve/deny)
                    if (canManage)
                      _PendingSection(
                        messId: widget.messId,
                        monthId: widget.monthId,
                        sheet: s,
                        onHandled: _refresh,
                      ),

                    // 31-day grid (read for members, editable via tap for managers)
                    const SizedBox(height: 14),
                    const Text(
                      'DAILY MEALS GRID',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.inkFaded,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.paperRaised,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.paperLine),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            AppColors.paper,
                          ),
                          columns: [
                            const DataColumn(
                              label: Text(
                                'Day',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            for (final m in members)
                              DataColumn(
                                label: Text(
                                  (m['name'] as String? ?? 'M')
                                      .split(' ')
                                      .first,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            const DataColumn(
                              label: Text(
                                'Total',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                          rows: _buildMealRows(
                            days,
                            members,
                            meals,
                            rowTotals,
                            passedDays,
                            canEdit,
                            context,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // settlement summary
                    const Text(
                      'SETTLEMENT',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.inkFaded,
                        letterSpacing: 0.8,
                      ),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AppColors.paperLine),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'MEMBER',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.inkFaded,
                                  ),
                                ),
                                Text(
                                  'MEALS / SPEND / BALANCE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.inkFaded,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          for (final row in summary)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      (row['member']?['name'] ??
                                              row['member_name'] ??
                                              'Member')
                                          .toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${toDouble(row['meals']).toStringAsFixed(1)} • ৳${toDouble(row['spend']).toStringAsFixed(0)} • ',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.inkFaded,
                                    ),
                                  ),
                                  Text(
                                    '৳${toDouble(row['balance']).toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: toDouble(row['balance']) >= 0
                                          ? AppColors.emerald
                                          : AppColors.danger,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // deposits
                    if (deposits.isNotEmpty) ...[
                      const Text(
                        'DEPOSITS',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.inkFaded,
                          letterSpacing: 0.8,
                        ),
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
                            for (final dep in deposits)
                              ListTile(
                                dense: true,
                                title: Text(
                                  '৳${toDouble(dep['amount']).toStringAsFixed(0)} — ${dep['member']?['name'] ?? ''}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Text(
                                  '${dep['note'] as String? ?? ''} • ${dep['deposit_date']?.toString() ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.inkFaded,
                                  ),
                                ),
                                trailing: canManage
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          size: 18,
                                          color: AppColors.inkFaded,
                                        ),
                                        onPressed: () async {
                                          await _repo.deleteDeposit(
                                            widget.messId,
                                            widget.monthId,
                                            dep['id'] as int,
                                          );
                                          _refresh();
                                        },
                                      )
                                    : null,
                              ),
                          ],
                        ),
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
  }

  List<DataRow> _buildMealRows(
    int days,
    List<dynamic> members,
    Map<String, dynamic> meals,
    Map<String, dynamic> rowTotals,
    int passedDays,
    bool canEdit,
    BuildContext context,
  ) {
    return [
      for (var d = 1; d <= days; d++)
        DataRow(
          cells: [
            DataCell(
              Text(
                '$d',
                style: TextStyle(
                  fontWeight: d == passedDays
                      ? FontWeight.w900
                      : FontWeight.w600,
                  color: d == passedDays ? AppColors.emerald : AppColors.ink,
                ),
              ),
            ),
            for (final m in members)
              DataCell(
                Text(
                  _mealCell(meals, m['id'], d),
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: canEdit ? () => _editMealCell(context, m, d) : null,
              ),
            DataCell(
              Text(
                (rowTotals['$d'] ?? 0).toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
    ];
  }

  String _mealCell(Map<String, dynamic> meals, dynamic memberId, int day) {
    final byMember =
        meals['$memberId'] ?? meals[memberId] ?? meals[memberId.toString()];
    if (byMember is Map) {
      final v = byMember['$day'] ?? byMember[day] ?? byMember[day.toString()];
      if (v != null) return v.toString();
    }
    return '—';
  }

  Widget _pill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _editMealCell(BuildContext context, dynamic member, int day) {
    final bCtrl = TextEditingController();
    final lCtrl = TextEditingController();
    final dCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: AppColors.paperRaised,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Edit Meal (B / L / D)',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: bCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Breakfast'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: lCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Lunch'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: dCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Dinner'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  try {
                    await _repo.saveMeal(
                      messId: widget.messId,
                      monthId: widget.monthId,
                      memberId: member['id'] as int,
                      day: day,
                      breakfast: double.tryParse(bCtrl.text),
                      lunch: double.tryParse(lCtrl.text),
                      dinner: double.tryParse(dCtrl.text),
                    );
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Meal saved')),
                      );
                      _refresh();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString().replaceAll('Exception: ', ''),
                          ),
                        ),
                      );
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandDark,
                ),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _autofill(BuildContext context) async {
    try {
      await _repo.autofillDefaults(widget.messId, widget.monthId);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Defaults filled')));
        _refresh();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  void _addNextDay(BuildContext context) async {
    try {
      await _repo.addNextDay(widget.messId, widget.monthId);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Next day added')));
        _refresh();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  void _showDepositSheet(BuildContext context, List<dynamic> members) {
    int? selId = members.isNotEmpty ? members.first['id'] as int? : null;
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setS) => Container(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: AppColors.paperRaised,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Deposit (manager only)',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: selId,
                items: members
                    .map(
                      (m) => DropdownMenuItem<int>(
                        value: m['id'] as int,
                        child: Text(m['name'] as String),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setS(() => selId = v),
                decoration: const InputDecoration(labelText: 'Member'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount ৳'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (selId == null) return;
                    final amt = double.tryParse(amountCtrl.text);
                    if (amt == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter amount')),
                      );
                      return;
                    }
                    try {
                      await _repo.addDeposit(
                        widget.messId,
                        widget.monthId,
                        selId!,
                        amt,
                        note: noteCtrl.text.trim(),
                      );
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Deposit added')),
                        );
                        _refresh();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceAll('Exception: ', ''),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandDark,
                  ),
                  child: const Text('Add Deposit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMealOffRequest(BuildContext context, int passedDays) {
    int? selDay;
    bool bOn = true, lOn = true, dOn = true;
    bool sheetLoaded = false;
    final noteCtrl = TextEditingController();
    int daysInMonth = 31;
    // Flat maps like web's window.mealOffInfo.myMealB (keyed by day, already filtered to myMember)
    Map<String, dynamic> myMealB = {}, myMealL = {}, myMealD = {};
    Map<String, dynamic> myPendingByDay = {};
    Map<String, dynamic>? myDefaults;
    void hydrateFromSheet(Map<String, dynamic> sheet) {
      daysInMonth = (sheet['month']?['days'] as int?) ?? 31;
      // Prefer new flat keys (web parity) — fall back to nested mealsB[memberId][day] for old payloads
      final flatB = sheet['myMealB'],
          flatL = sheet['myMealL'],
          flatD = sheet['myMealD'];
      if (flatB is Map) myMealB = flatB.cast<String, dynamic>();
      if (flatL is Map) myMealL = flatL.cast<String, dynamic>();
      if (flatD is Map) myMealD = flatD.cast<String, dynamic>();
      final flatPend = sheet['myPendingByDay'];
      if (flatPend is Map) myPendingByDay = flatPend.cast<String, dynamic>();
      myDefaults = (sheet['myDefaults'] as Map?)?.cast<String, dynamic>();
      if (myDefaults == null) {
        final myMemberId = sheet['myMemberId'];
        if (myMemberId != null) {
          final members = sheet['members'] as List<dynamic>? ?? [];
          final me = members.cast<Map<String, dynamic>?>().firstWhere(
            (m) => m != null && '${m['id']}' == '$myMemberId',
            orElse: () => null,
          );
          if (me != null) {
            myDefaults = {
              'default_breakfast': me['default_breakfast'],
              'default_lunch': me['default_lunch'],
              'default_dinner': me['default_dinner'],
              'hasBld':
                  me['default_breakfast'] != null ||
                  me['default_lunch'] != null ||
                  me['default_dinner'] != null,
            };
          }
        }
      }
      // If flat maps are empty (old payload or no daily meals yet), try nested mealsB[myMemberId]
      if (myMealB.isEmpty && myMealL.isEmpty && myMealD.isEmpty) {
        final rawB = sheet['mealsB'],
            rawL = sheet['mealsL'],
            rawD = sheet['mealsD'];
        final myId = '${sheet['myMemberId'] ?? ''}';
        if (myId.isNotEmpty) {
          if (rawB is Map && rawB[myId] is Map) {
            myMealB = (rawB[myId] as Map).cast<String, dynamic>();
          }
          if (rawL is Map && rawL[myId] is Map) {
            myMealL = (rawL[myId] as Map).cast<String, dynamic>();
          }
          if (rawD is Map && rawD[myId] is Map) {
            myMealD = (rawD[myId] as Map).cast<String, dynamic>();
          }
        }
      }
      // Initial checked state = user's default (Cartpa 1·0·1 → B✓ L☐ D✓)
      if (myDefaults != null && myDefaults!['hasBld'] == true) {
        bool on(dynamic v) => v is num
            ? v.toDouble() != 0
            : (v == null || double.tryParse('$v') != 0);
        bOn = on(myDefaults!['default_breakfast']);
        lOn = on(myDefaults!['default_lunch']);
        dOn = on(myDefaults!['default_dinner']);
      } else {
        bOn = true;
        lOn = true;
        dOn = true;
      }
    }

    try {
      final st = context.read<MessCubit>().state;
      if (st is MessSheetLoaded) {
        hydrateFromSheet(st.sheet);
        sheetLoaded = true;
      }
    } catch (_) {}
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setS) {
          Widget buildCalendar() {
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.paperLine),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandDark,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          selDay == null ? 'Pick a date' : 'Day $selDay',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Future only (after $passedDays)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.inkFaded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: 1,
                        ),
                    itemCount: daysInMonth,
                    itemBuilder: (context, idx) {
                      final d = idx + 1;
                      final isPast = d <= passedDays;
                      final isSelected = selDay == d;
                      return InkWell(
                        onTap: isPast
                            ? null
                            : () {
                                final pending = myPendingByDay['$d'];
                                if (pending is Map) {
                                  bOn = !(pending['breakfast_off'] == true);
                                  lOn = !(pending['lunch_off'] == true);
                                  dOn = !(pending['dinner_off'] == true);
                                  noteCtrl.text =
                                      (pending['note'] as String?) ?? '';
                                } else {
                                  // Flat myMealB/L/D keyed by day (web: myMealB[String(d)])
                                  final hasDaily =
                                      myMealB.containsKey('$d') ||
                                      myMealL.containsKey('$d') ||
                                      myMealD.containsKey('$d');
                                  if (hasDaily) {
                                    final bVal = myMealB['$d'],
                                        lVal = myMealL['$d'],
                                        dVal = myMealD['$d'];
                                    bOn =
                                        !((bVal is num
                                                ? bVal.toDouble()
                                                : double.tryParse('$bVal') ??
                                                      1) ==
                                            0);
                                    lOn =
                                        !((lVal is num
                                                ? lVal.toDouble()
                                                : double.tryParse('$lVal') ??
                                                      1) ==
                                            0);
                                    dOn =
                                        !((dVal is num
                                                ? dVal.toDouble()
                                                : double.tryParse('$dVal') ??
                                                      1) ==
                                            0);
                                  } else {
                                    final def = myDefaults;
                                    if (def != null && def['hasBld'] == true) {
                                      final db = def['default_breakfast'],
                                          dl = def['default_lunch'],
                                          dd = def['default_dinner'];
                                      bOn =
                                          !((db is num
                                                  ? db.toDouble()
                                                  : double.tryParse('$db') ??
                                                        1) ==
                                              0);
                                      lOn =
                                          !((dl is num
                                                  ? dl.toDouble()
                                                  : double.tryParse('$dl') ??
                                                        1) ==
                                              0);
                                      dOn =
                                          !((dd is num
                                                  ? dd.toDouble()
                                                  : double.tryParse('$dd') ??
                                                        1) ==
                                              0);
                                    } else {
                                      bOn = true;
                                      lOn = true;
                                      dOn = true;
                                    }
                                  }
                                  noteCtrl.text = '';
                                }
                                // Refresh from server so next open isn't stale (web reloads page; app re-fetches sheet)
                                if (!sheetLoaded) {
                                  try {
                                    context.read<MessCubit>().loadSheet(
                                      widget.messId,
                                      widget.monthId,
                                    );
                                  } catch (_) {}
                                }
                                setS(() => selDay = d);
                              },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.brandDark
                                : (isPast
                                      ? AppColors.paperLine.withValues(
                                          alpha: 0.5,
                                        )
                                      : AppColors.paperRaised),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.brandDark
                                  : AppColors.paperLine,
                            ),
                          ),
                          child: Text(
                            '$d',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? Colors.white
                                  : (isPast
                                        ? AppColors.inkFaded
                                        : AppColors.ink),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }

          return Container(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: AppColors.paperRaised,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.brandSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.event_busy_rounded,
                          color: AppColors.brandDark,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Request Meal Off',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              'Uncheck to turn OFF — shows your default for that day',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.inkFaded,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  buildCalendar(),
                  const SizedBox(height: 14),
                  const Text(
                    'MEALS (checked = ON)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.inkFaded,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _mealCheckTile(
                          label: 'Breakfast',
                          value: bOn,
                          onChanged: (v) => setS(() => bOn = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _mealCheckTile(
                          label: 'Lunch',
                          value: lOn,
                          onChanged: (v) => setS(() => lOn = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _mealCheckTile(
                          label: 'Dinner',
                          value: dOn,
                          onChanged: (v) => setS(() => dOn = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'NOTE (optional)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.inkFaded,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Not home that day',
                      prefixIcon: Icon(
                        Icons.notes_rounded,
                        size: 18,
                        color: AppColors.inkFaded,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        if (selDay == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pick a date on the calendar'),
                            ),
                          );
                          return;
                        }
                        if (selDay! <= passedDays) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Pick a future day — needs 1 day notice',
                              ),
                            ),
                          );
                          return;
                        }
                        try {
                          await _repo.requestMealOff(
                            widget.messId,
                            widget.monthId,
                            selDay!,
                            bOn: bOn,
                            lOn: lOn,
                            dOn: dOn,
                            note: noteCtrl.text.trim(),
                          );
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Meal-off requested — manager will review',
                                ),
                              ),
                            );
                            _refresh();
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceAll('Exception: ', ''),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Send Request',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Saving sends an email to the manager. OFF shows red on cards.',
                    style: TextStyle(fontSize: 11, color: AppColors.inkFaded),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _mealCheckTile({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: value ? AppColors.brandSoft : const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value
                ? AppColors.brandDark.withValues(alpha: 0.2)
                : const Color(0xFFFCA5A5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 16,
              color: value ? AppColors.brandDark : const Color(0xFFDC2626),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: value ? AppColors.brandDark : const Color(0xFF991B1B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGuestRequest(BuildContext context, int passedDays) {
    int? selDay;
    final nameCtrl = TextEditingController();
    final countCtrl = TextEditingController(text: '1');
    final noteCtrl = TextEditingController();
    bool b = false, l = false, d = false;
    int daysInMonth = 31;
    try {
      final st = context.read<MessCubit>().state;
      if (st is MessSheetLoaded) {
        daysInMonth = (st.sheet['month']?['days'] as int?) ?? 31;
      }
    } catch (_) {}
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setS) {
          Widget buildCalendar() {
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.paperLine),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandDark,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          selDay == null ? 'Pick a date' : 'Day $selDay',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Future day only (after $passedDays)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.inkFaded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: 1,
                        ),
                    itemCount: daysInMonth,
                    itemBuilder: (context, idx) {
                      final day = idx + 1;
                      final isPast = day <= passedDays;
                      final isSelected = selDay == day;
                      return InkWell(
                        onTap: isPast ? null : () => setS(() => selDay = day),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.brandDark
                                : (isPast
                                      ? AppColors.paperLine.withValues(
                                          alpha: 0.5,
                                        )
                                      : AppColors.paperRaised),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.brandDark
                                  : AppColors.paperLine,
                            ),
                          ),
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? Colors.white
                                  : (isPast
                                        ? AppColors.inkFaded
                                        : AppColors.ink),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }

          return Container(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: AppColors.paperRaised,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.brandSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.person_add_rounded,
                          color: AppColors.brandDark,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Request Guest Meal',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              'Guest stays with you — counts toward your bill',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.inkFaded,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  buildCalendar(),
                  const SizedBox(height: 14),
                  const Text(
                    'GUEST NAME *',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.inkFaded,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Mother / Friend',
                      prefixIcon: Icon(
                        Icons.badge_outlined,
                        size: 18,
                        color: AppColors.inkFaded,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'HOW MANY GUESTS *',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.inkFaded,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: countCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '1',
                      prefixIcon: Icon(
                        Icons.group_outlined,
                        size: 18,
                        color: AppColors.inkFaded,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'MEALS FOR GUEST',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.inkFaded,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _mealCheckTile(
                          label: 'Breakfast',
                          value: b,
                          onChanged: (v) => setS(() => b = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _mealCheckTile(
                          label: 'Lunch',
                          value: l,
                          onChanged: (v) => setS(() => l = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _mealCheckTile(
                          label: 'Dinner',
                          value: d,
                          onChanged: (v) => setS(() => d = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'NOTE (optional)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.inkFaded,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Guest staying 2 days',
                      prefixIcon: Icon(
                        Icons.notes_rounded,
                        size: 18,
                        color: AppColors.inkFaded,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        if (selDay == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pick a date on the calendar'),
                            ),
                          );
                          return;
                        }
                        if (selDay! <= passedDays) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Pick a future day')),
                          );
                          return;
                        }
                        if (nameCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Enter guest name')),
                          );
                          return;
                        }
                        if (!b && !l && !d) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pick at least one meal for guest'),
                            ),
                          );
                          return;
                        }
                        try {
                          await _repo.requestGuestMeal(
                            widget.messId,
                            widget.monthId,
                            day: selDay!,
                            guestName: nameCtrl.text.trim(),
                            guestCount: int.tryParse(countCtrl.text) ?? 1,
                            breakfast: b,
                            lunch: l,
                            dinner: d,
                            note: noteCtrl.text.trim(),
                          );
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Guest request sent — manager will review',
                                ),
                              ),
                            );
                            _refresh();
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceAll('Exception: ', ''),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Send Guest Request',
                        style: TextStyle(fontWeight: FontWeight.w800),
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

  void _showGuestDirectSheet(
    BuildContext context,
    List<dynamic> members,
    int passedDays,
  ) {
    int? selMemberId = members.isNotEmpty ? members.first['id'] as int : null;
    int? selDay;
    final nameCtrl = TextEditingController();
    final countCtrl = TextEditingController(text: '1');
    final noteCtrl = TextEditingController();
    bool b = false, l = true, d = false;
    int daysInMonth = 31;
    try {
      final st = context.read<MessCubit>().state;
      if (st is MessSheetLoaded) {
        daysInMonth = (st.sheet['month']?['days'] as int?) ?? 31;
      }
    } catch (_) {}
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setS) {
          Widget buildCalendar() {
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.paperLine),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandDark,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          selDay == null ? 'Pick a date' : 'Day $selDay',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Today or future',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.inkFaded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: 1,
                        ),
                    itemCount: daysInMonth,
                    itemBuilder: (context, idx) {
                      final day = idx + 1;
                      final isPast = day < passedDays;
                      final isSelected = selDay == day;
                      return InkWell(
                        onTap: isPast ? null : () => setS(() => selDay = day),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.brandDark
                                : (isPast
                                      ? AppColors.paperLine.withValues(
                                          alpha: 0.5,
                                        )
                                      : AppColors.paperRaised),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.brandDark
                                  : AppColors.paperLine,
                            ),
                          ),
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? Colors.white
                                  : (isPast
                                        ? AppColors.inkFaded
                                        : AppColors.ink),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }

          return Container(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: AppColors.paperRaised,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.brandSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1_rounded,
                          color: AppColors.brandDark,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Guest Meal',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              'Manager — creates immediately',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.inkFaded,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF0F9F59,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'MANAGER',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F9F59),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'HOST MEMBER *',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.inkFaded,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: selMemberId,
                    items: members
                        .map(
                          (m) => DropdownMenuItem<int>(
                            value: m['id'] as int,
                            child: Text(m['name'] as String),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setS(() => selMemberId = v),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.person_outline_rounded,
                        size: 18,
                        color: AppColors.inkFaded,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  buildCalendar(),
                  const SizedBox(height: 12),
                  const Text(
                    'GUEST NAME *',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.inkFaded,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Mother / Friend',
                      prefixIcon: Icon(
                        Icons.badge_outlined,
                        size: 18,
                        color: AppColors.inkFaded,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'HOW MANY GUESTS *',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.inkFaded,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: countCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '1',
                      prefixIcon: Icon(
                        Icons.group_outlined,
                        size: 18,
                        color: AppColors.inkFaded,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'MEALS FOR GUEST',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.inkFaded,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _mealCheckTile(
                          label: 'Breakfast',
                          value: b,
                          onChanged: (v) => setS(() => b = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _mealCheckTile(
                          label: 'Lunch',
                          value: l,
                          onChanged: (v) => setS(() => l = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _mealCheckTile(
                          label: 'Dinner',
                          value: d,
                          onChanged: (v) => setS(() => d = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'NOTE (optional)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.inkFaded,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Guest staying 2 days',
                      prefixIcon: Icon(
                        Icons.notes_rounded,
                        size: 18,
                        color: AppColors.inkFaded,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        if (selMemberId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Pick host member')),
                          );
                          return;
                        }
                        if (selDay == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pick a date on the calendar'),
                            ),
                          );
                          return;
                        }
                        if (nameCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Enter guest name')),
                          );
                          return;
                        }
                        if (!b && !l && !d) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pick at least one meal for guest'),
                            ),
                          );
                          return;
                        }
                        try {
                          await _repo.addGuestDirect(
                            widget.messId,
                            widget.monthId,
                            memberId: selMemberId!,
                            day: selDay!,
                            guestName: nameCtrl.text.trim(),
                            guestCount: int.tryParse(countCtrl.text) ?? 1,
                            breakfast: b,
                            lunch: l,
                            dinner: d,
                          );
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Guest added')),
                            );
                            _refresh();
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceAll('Exception: ', ''),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Add Guest',
                        style: TextStyle(fontWeight: FontWeight.w800),
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

  double _bazarRowTotal(List<Map<String, TextEditingController>> rows) {
    double sum = 0;
    for (final r in rows) {
      final q = double.tryParse(r['qty']!.text.trim()) ?? 0;
      final p = double.tryParse(r['price']!.text.trim()) ?? 0;
      sum += q * p;
    }
    return sum;
  }

  Future<List<String>> _pickReceiptImages() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1600,
      );
      return picked.map((x) => x.path).toList();
    } catch (_) {
      return [];
    }
  }

  void _showBazarSheet(BuildContext context, int passedDays) {
    final amountCtrl = TextEditingController();
    final List<Map<String, TextEditingController>> itemRows = [
      {
        'name': TextEditingController(),
        'qty': TextEditingController(text: '1'),
        'price': TextEditingController(),
      },
    ];
    final List<String> pickedReceiptPaths = [];
    int? selDay = passedDays > 0 ? passedDays : 1;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setS) => Container(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: AppColors.paperRaised,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.brandSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.shopping_basket_rounded,
                        color: AppColors.brandDark,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bazar — Day',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            'Items qty × price → day total + optional receipt',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.inkFaded,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035, 12, 31),
                    );
                    if (picked != null) setS(() => selDay = picked.day);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.paperLine),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: AppColors.brandDark,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          selDay == null ? 'Pick day' : 'Day $selDay',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AppColors.ink,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Today is $passedDays for members',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.inkFaded,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'BAZAR ITEMS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.inkFaded,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.paperLine),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Item name',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkFaded,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 56,
                            child: Text(
                              'Qty',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkFaded,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 72,
                            child: Text(
                              'Price',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkFaded,
                              ),
                            ),
                          ),
                          const SizedBox(width: 28),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...List.generate(itemRows.length, (idx) {
                        final row = itemRows[idx];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: row['name']!,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. Rice',
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: 56,
                                child: TextField(
                                  controller: row['qty']!,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(
                                    hintText: '1',
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: 72,
                                child: TextField(
                                  controller: row['price']!,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(
                                    hintText: '0',
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () {
                                  if (itemRows.length == 1) {
                                    row['name']!.clear();
                                    row['qty']!.text = '1';
                                    row['price']!.clear();
                                  } else {
                                    setS(() => itemRows.removeAt(idx));
                                  }
                                  setS(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => setS(
                                () => itemRows.add({
                                  'name': TextEditingController(),
                                  'qty': TextEditingController(text: '1'),
                                  'price': TextEditingController(),
                                }),
                              ),
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Add row'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                side: const BorderSide(
                                  color: AppColors.paperLine,
                                  style: BorderStyle.solid,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _bazarRowTotal(itemRows)
                                .toStringAsFixed(2)
                                .replaceAll(RegExp(r'\.?0+$'), ''),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: AppColors.brandDark,
                            ),
                          ),
                          const Text(
                            ' ৳',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.inkFaded,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16, color: AppColors.paperLine),
                      Row(
                        children: [
                          const Icon(
                            Icons.receipt_long_rounded,
                            size: 14,
                            color: AppColors.inkFaded,
                          ),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'Receipts — tap to add (jpg/png/pdf, up to 8 per save)',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.inkFaded,
                              ),
                            ),
                          ),
                          Text(
                            '${pickedReceiptPaths.length} picked',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brandDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (int i = 0; i < pickedReceiptPaths.length; i++)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.brandSoft,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.paperLine),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.attach_file_rounded,
                                    size: 12,
                                    color: AppColors.brandDark,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    pickedReceiptPaths[i].split('/').last,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () => setS(
                                      () => pickedReceiptPaths.removeAt(i),
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
                          InkWell(
                            onTap: () async {
                              final picked = await _pickReceiptImages();
                              if (picked.isNotEmpty) {
                                setS(() => pickedReceiptPaths.addAll(picked));
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.paperRaised,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.paperLine,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 14,
                                    color: AppColors.brandDark,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Add receipts',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.brandDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Or quick total (web fallback):',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkFaded,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText:
                              'Total amount ৳ (quick) — leave empty if using rows above',
                          isDense: true,
                          prefixIcon: Icon(
                            Icons.payments_outlined,
                            size: 16,
                            color: AppColors.inkFaded,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (selDay == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pick a day')),
                        );
                        return;
                      }
                      final hasRows = itemRows.any(
                        (r) =>
                            r['name']!.text.trim().isNotEmpty ||
                            r['price']!.text.trim().isNotEmpty,
                      );
                      final quickAmt = double.tryParse(amountCtrl.text.trim());
                      if (!hasRows &&
                          quickAmt == null &&
                          pickedReceiptPaths.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Add at least one item, amount, or receipt',
                            ),
                          ),
                        );
                        return;
                      }
                      try {
                        if (hasRows || pickedReceiptPaths.isNotEmpty) {
                          final items = itemRows
                              .where(
                                (r) =>
                                    r['name']!.text.trim().isNotEmpty ||
                                    double.tryParse(r['price']!.text.trim()) !=
                                        null,
                              )
                              .map(
                                (r) => {
                                  'name': r['name']!.text.trim().isEmpty
                                      ? 'Item'
                                      : r['name']!.text.trim(),
                                  'qty': r['qty']!.text.trim().isEmpty
                                      ? '1'
                                      : r['qty']!.text.trim(),
                                  'price': r['price']!.text.trim().isEmpty
                                      ? '0'
                                      : r['price']!.text.trim(),
                                },
                              )
                              .toList();
                          if (items.isEmpty && pickedReceiptPaths.isNotEmpty) {
                            // Receipt-only: send one dummy row that backend will skip but validation needs items
                            items.add({'name': '', 'qty': '0', 'price': '0'});
                          }
                          await _repo.saveBazarItems(
                            messId: widget.messId,
                            monthId: widget.monthId,
                            day: selDay!,
                            items: items,
                            receiptPaths: pickedReceiptPaths.isEmpty
                                ? null
                                : pickedReceiptPaths,
                          );
                        } else {
                          await _repo.saveBazar(
                            messId: widget.messId,
                            monthId: widget.monthId,
                            day: selDay!,
                            amount: quickAmt!,
                          );
                        }
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Bazar saved')),
                          );
                          _refresh();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                e.toString().replaceAll('Exception: ', ''),
                              ),
                            ),
                          );
                        }
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandDark,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Save Bazar',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingSection extends StatelessWidget {
  final int messId;
  final int monthId;
  final Map<String, dynamic> sheet;
  final VoidCallback onHandled;
  const _PendingSection({
    required this.messId,
    required this.monthId,
    required this.sheet,
    required this.onHandled,
  });

  @override
  Widget build(BuildContext context) {
    final offReqByDay = sheet['offReqByDay'] as Map<String, dynamic>? ?? {};
    final guestPending =
        sheet['guestReqPending'] as Map<String, dynamic>? ?? {};
    final repo = MessRepository();
    final hasOff = offReqByDay.isNotEmpty;
    final hasGuest = guestPending.isNotEmpty;
    if (!hasOff && !hasGuest) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PENDING REQUESTS (manager)',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            color: AppColors.inkFaded,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        if (hasOff)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.paperRaised,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.paperLine),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Meal-off requests',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
                const SizedBox(height: 8),
                for (final entry in offReqByDay.entries)
                  for (final r in (entry.value as List<dynamic>))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Day ${r['day']} — ${(r['member']?['name'] ?? 'Member')} • ${r['note'] ?? ''}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              await repo.handleMealOff(
                                messId,
                                monthId,
                                r['id'] as int,
                                'deny',
                              );
                              onHandled();
                            },
                            child: const Text('Deny'),
                          ),
                          FilledButton(
                            onPressed: () async {
                              await repo.handleMealOff(
                                messId,
                                monthId,
                                r['id'] as int,
                                'approve',
                              );
                              onHandled();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.emerald,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Approve'),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        if (hasOff && hasGuest) const SizedBox(height: 8),
        if (hasGuest)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.paperRaised,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.paperLine),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Guest meal requests',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
                const SizedBox(height: 8),
                for (final entry in guestPending.entries)
                  for (final r in (entry.value as List<dynamic>))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Day ${r['day']} — ${r['guest_name']} ×${r['guest_count']} • ${r['member']?['name'] ?? ''}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              await repo.handleGuestMeal(
                                messId,
                                monthId,
                                r['id'] as int,
                                'deny',
                              );
                              onHandled();
                            },
                            child: const Text('Deny'),
                          ),
                          FilledButton(
                            onPressed: () async {
                              await repo.handleGuestMeal(
                                messId,
                                monthId,
                                r['id'] as int,
                                'approve',
                              );
                              onHandled();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.emerald,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Approve'),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}
