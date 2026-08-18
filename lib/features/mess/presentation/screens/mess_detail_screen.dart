import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/mess_model.dart';
import '../../data/repositories/mess_repository.dart';
import '../cubit/mess_cubit.dart';
import '../cubit/mess_state.dart';
import 'mess_form_screen.dart';
import 'mess_sheet_screen.dart';

class MessDetailScreen extends StatelessWidget {
  final int messId;
  const MessDetailScreen({super.key, required this.messId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MessCubit()..loadMess(messId),
      child: _MessDetailView(messId: messId),
    );
  }
}

class _MessDetailView extends StatelessWidget {
  final int messId;
  const _MessDetailView({required this.messId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paperRaised,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: BlocBuilder<MessCubit, MessState>(
          builder: (context, state) {
            final name =
                state is MessDetailLoaded ? state.detail.mess.name : 'Mess Details';
            return Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                fontSize: 16,
              ),
            );
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.ink, size: 20),
            onPressed: () => context.read<MessCubit>().loadMess(messId),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<MessCubit, MessState>(
          listener: (context, state) {
            if (state is MessDetailLoaded && state.message != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message!)));
            }
          },
          builder: (context, state) {
            if (state is MessLoading) {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.brandDark),
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
                        style: const TextStyle(color: AppColors.inkFaded, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => context.read<MessCubit>().loadMess(messId),
                        icon: const Icon(Icons.refresh_rounded, size: 15),
                        label: const Text('Try Again'),
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

            if (state is MessDetailLoaded) {
              final d = state.detail;
              final mess = d.mess;
              final canManage = d.canManage;
              final months = d.months;

              return RefreshIndicator(
                color: AppColors.brandDark,
                onRefresh: () => context.read<MessCubit>().loadMess(messId),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Summary Card
                      _buildHeaderCard(context, mess, canManage),

                      const SizedBox(height: 24),

                      // Monthly Sheets Section
                      _buildSheetsSection(context, months, canManage),

                      const SizedBox(height: 24),

                      // Member Settlement Section (Matches Web Table)
                      _buildMemberSettlementsSection(d),
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

  // --- Header Hero Summary Card ---
  Widget _buildHeaderCard(BuildContext context, MessModel mess, bool canManage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.paperLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: AppColors.brandDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mess.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    if (mess.location.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: AppColors.inkFaded,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              mess.location,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.inkFaded,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: canManage ? AppColors.brandDark : AppColors.paper,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: canManage ? AppColors.brandDark : AppColors.paperLine,
                  ),
                ),
                child: Text(
                  mess.displayRole.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: canManage ? Colors.white : AppColors.inkFaded,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.paperLine),
          const SizedBox(height: 12),

          // Meta Info Items
          Row(
            children: [
              _buildMetaItem(Icons.people_outline_rounded, '${mess.membersCount} members'),
              _buildDotDivider(),
              _buildMetaItem(Icons.calendar_month_outlined, '${mess.monthsCount} sheets'),
              _buildDotDivider(),
              _buildMetaItem(Icons.public_outlined, mess.timezone),
            ],
          ),

          if (canManage || mess.isOwner) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (canManage) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final ok = await MessFormScreen.showAsBottomSheet(
                          context,
                          mess: mess,
                          cubit: context.read<MessCubit>(),
                        );
                        if (ok == true && context.mounted) {
                          context.read<MessCubit>().loadMess(messId);
                        }
                      },
                      icon: const Icon(Icons.edit_outlined, size: 13),
                      label: const Text('Edit Details', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: const BorderSide(color: AppColors.paperLine),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (mess.isOwner)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDeleteMess(context, mess),
                      icon: const Icon(Icons.delete_outline_rounded, size: 13),
                      label: const Text('Delete Mess', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: const BorderSide(color: AppColors.dangerSoft),
                        backgroundColor: AppColors.dangerSoft.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String label) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.inkFaded),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDotDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text('·', style: TextStyle(color: AppColors.paperLine, fontWeight: FontWeight.bold)),
    );
  }

  // --- Monthly Sheets Section (Focused Hero Card) ---
  Widget _buildSheetsSection(BuildContext context, List<MessMonthLite> months, bool canManage) {
    if (months.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MONTHLY SHEET',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkFaded,
                  letterSpacing: 0.8,
                ),
              ),
              if (canManage)
                InkWell(
                  onTap: () => _showCreateMonth(context, messId),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: const [
                        Icon(Icons.add_rounded, size: 14, color: AppColors.brandDark),
                        SizedBox(width: 2),
                        Text(
                          'Open Month',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.paperRaised,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.paperLine),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 28,
                  color: AppColors.inkFaded,
                ),
                const SizedBox(height: 8),
                const Text(
                  'No active sheets',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  canManage
                      ? 'Open a month sheet to start tracking daily meals.'
                      : 'Waiting for manager to open a month sheet.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.inkFaded),
                ),
                if (canManage) ...[
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => _showCreateMonth(context, messId),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandDark,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Open First Month', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    final activeMonth = months[0];
    final pastMonths = months.sublist(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ACTIVE MONTHLY SHEET',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.inkFaded,
                letterSpacing: 0.8,
              ),
            ),
            if (canManage)
              InkWell(
                onTap: () => _showCreateMonth(context, messId),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: const [
                      Icon(Icons.add_rounded, size: 14, color: AppColors.brandDark),
                      SizedBox(width: 2),
                      Text(
                        'New Month',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Featured Active Sheet Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.paperRaised,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.paperLine),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.brandDark,
                      size: 22,
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
                              activeMonth.label,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.emeraldSoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: AppColors.emerald,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activeMonth.cycleLabel.isNotEmpty
                              ? activeMonth.cycleLabel
                              : '${activeMonth.daysInMonth} Days · Daily Meal & Expense Matrix',
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
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MessSheetScreen(
                        messId: messId,
                        monthId: activeMonth.id,
                        monthLabel: activeMonth.label,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.table_chart_outlined, size: 16),
                  label: const Text(
                    'Open Daily Meal Matrix',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandDark,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (pastMonths.isNotEmpty) ...[
          const SizedBox(height: 14),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              'Past Sheets (${pastMonths.length})',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.inkFaded,
              ),
            ),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.paperRaised,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.paperLine),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pastMonths.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.paperLine),
                  itemBuilder: (context, i) {
                    final m = pastMonths[i];
                    return ListTile(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MessSheetScreen(
                            messId: messId,
                            monthId: m.id,
                            monthLabel: m.label,
                          ),
                        ),
                      ),
                      leading: const Icon(Icons.history_rounded, size: 18, color: AppColors.inkFaded),
                      title: Text(
                        m.label,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                      subtitle: Text(
                        m.cycleLabel.isNotEmpty ? m.cycleLabel : '${m.daysInMonth} days',
                        style: const TextStyle(fontSize: 11, color: AppColors.inkFaded),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.inkFaded),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // --- Member Settlement Section (Full-size Cards) ---
  Widget _buildMemberSettlementsSection(MessDetailModel d) {
    final settlements = d.memberSettlements;
    final monthLabel = d.currentMonthLabel.isNotEmpty ? d.currentMonthLabel : 'Active Month';

    if (settlements.isEmpty) {
      return _buildFallbackMembersSection(d.members);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MEMBER SETTLEMENT — ${monthLabel.toUpperCase()}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.inkFaded,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              '${settlements.length} Members',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.inkFaded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: settlements.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final s = settlements[i];
            return _buildMemberSettlementCard(s);
          },
        ),
      ],
    );
  }

  Widget _buildMemberSettlementCard(MemberSettlementModel s) {
    final isPositive = s.balance >= 0;
    final isManager = s.role == 'manager';
    final mealsStr = s.meals % 1 == 0
        ? s.meals.toInt().toString()
        : s.meals.toStringAsFixed(1);
    final spendStr = '${s.spend.toStringAsFixed(2)} ৳';
    final givenStr = '${s.given.toStringAsFixed(0)} ৳';
    final balanceValStr = '${s.balance.abs().toStringAsFixed(2)} ৳';
    final balancePrefix = isPositive ? '+' : '-';
    final avatarColor = _hexColor(s.color);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.paperLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            // Top Accent Bar with Member Color
            Container(height: 3, color: avatarColor),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Avatar + Name/Email/Role + Balance Pill
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar with ring
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: avatarColor.withValues(alpha: 0.3), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: avatarColor,
                          child: Text(
                            s.name.isNotEmpty ? s.name[0].toUpperCase() : 'M',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Member Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    s.name,
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isManager ? AppColors.brandSoft : AppColors.paper,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isManager
                                          ? AppColors.brandDark.withValues(alpha: 0.2)
                                          : AppColors.paperLine,
                                    ),
                                  ),
                                  child: Text(
                                    s.role.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: isManager ? AppColors.brandDark : AppColors.inkFaded,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            if (s.email.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.alternate_email_rounded,
                                    size: 11,
                                    color: AppColors.inkFaded,
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      s.email,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.inkFaded,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Balance Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isPositive ? AppColors.emeraldSoft : AppColors.dangerSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isPositive
                                ? AppColors.emerald.withValues(alpha: 0.3)
                                : AppColors.danger.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              isPositive ? 'SURPLUS' : 'DUE',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: isPositive ? AppColors.emerald : AppColors.danger,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '$balancePrefix$balanceValStr',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: isPositive ? AppColors.emerald : AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Stat Tiles (Meals, Spend, Given)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.paperLine),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTileStat(
                            icon: Icons.restaurant_menu_rounded,
                            iconColor: AppColors.brandDark,
                            label: 'Meals',
                            value: mealsStr,
                          ),
                        ),
                        Container(width: 1, height: 28, color: AppColors.paperLine),
                        Expanded(
                          child: _buildTileStat(
                            icon: Icons.shopping_bag_outlined,
                            iconColor: AppColors.inkSoft,
                            label: 'Spend',
                            value: spendStr,
                          ),
                        ),
                        Container(width: 1, height: 28, color: AppColors.paperLine),
                        Expanded(
                          child: _buildTileStat(
                            icon: Icons.payments_outlined,
                            iconColor: AppColors.emerald,
                            label: 'Given',
                            value: givenStr,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTileStat({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppColors.inkFaded,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // --- Fallback Members Section (when no active month sheet) ---
  Widget _buildFallbackMembersSection(List<MessMemberLite> members) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'MEMBERS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.inkFaded,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              '${members.length} Total',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.inkFaded,
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
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: members.length,
            separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.paperLine),
            itemBuilder: (context, i) {
              final member = members[i];
              final isManager = member.memberRole == 'manager';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: _hexColor(member.color),
                      child: Text(
                        member.name.isNotEmpty ? member.name[0].toUpperCase() : 'M',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
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
                              Flexible(
                                child: Text(
                                  member.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppColors.ink,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              _buildDefaultMealChip(member),
                            ],
                          ),
                          if (member.email.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(
                              member.email,
                              style: const TextStyle(fontSize: 11, color: AppColors.inkFaded),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isManager ? AppColors.brandSoft : AppColors.paper,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isManager ? AppColors.brandDark.withValues(alpha: 0.15) : AppColors.paperLine,
                        ),
                      ),
                      child: Text(
                        member.memberRole.toUpperCase(),
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: isManager ? AppColors.brandDark : AppColors.inkFaded,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultMealChip(MessMemberLite m) {
    final raw = m.defaultDisplay;
    if (raw.isEmpty || raw == '—') return const SizedBox.shrink();

    final isBld = raw.contains('·');
    if (!isBld) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.paperLine),
        ),
        child: Text(
          raw,
          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.inkSoft),
        ),
      );
    }

    final parts = raw.split('·').map((e) => e.trim()).toList();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < parts.length; i++) ...[
          if (i > 0)
            const Text(
              '·',
              style: TextStyle(fontSize: 9, color: AppColors.inkFaded, fontWeight: FontWeight.bold),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: parts[i] == '0' ? AppColors.dangerSoft : AppColors.paper,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: parts[i] == '0' ? AppColors.danger.withValues(alpha: 0.3) : AppColors.paperLine,
              ),
            ),
            child: Text(
              parts[i],
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: parts[i] == '0' ? AppColors.danger : AppColors.ink,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _confirmDeleteMess(BuildContext context, MessModel mess) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Mess?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Text('Are you sure you want to delete "${mess.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final ok = await context.read<MessCubit>().deleteMess(mess.id);
      if (ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mess deleted successfully')),
        );
        Navigator.pop(context);
      }
    }
  }

  Color _hexColor(String hex) {
    try {
      final v = hex.replaceAll('#', '');
      return Color(int.parse('FF$v', radix: 16));
    } catch (_) {
      return AppColors.brandDark;
    }
  }

  void _showCreateMonth(BuildContext context, int messId) {
    final yearCtrl = TextEditingController(text: '${DateTime.now().year}');
    int selectedMonth = DateTime.now().month;

    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      context: context,
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (context, setS) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
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
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.paperLine,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Open New Monthly Sheet',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Select month and year to create the 1–31 daily meal sheet.',
                    style: TextStyle(fontSize: 12, color: AppColors.inkFaded),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<int>(
                          initialValue: selectedMonth,
                          decoration: const InputDecoration(
                            labelText: 'Month',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: List.generate(12, (index) {
                            return DropdownMenuItem<int>(
                              value: index + 1,
                              child: Text(monthNames[index]),
                            );
                          }),
                          onChanged: (val) {
                            if (val != null) setS(() => selectedMonth = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: yearCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Year',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              setS(() => saving = true);
                              try {
                                await MessRepository().createMonth(messId, {
                                  'year':
                                      int.tryParse(yearCtrl.text) ??
                                      DateTime.now().year,
                                  'month': selectedMonth,
                                });
                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Monthly sheet opened successfully'),
                                    ),
                                  );
                                  context.read<MessCubit>().loadMess(messId);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e.toString().replaceAll(
                                          'Exception: ',
                                          '',
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              } finally {
                                setS(() => saving = false);
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandDark,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Create Month Sheet'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
