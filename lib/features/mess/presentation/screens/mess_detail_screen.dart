import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
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

  void _backToDashboard(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _backToDashboard(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.paper,
        appBar: AppBar(
          backgroundColor: AppColors.paperRaised,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          leading: AppBackButton(onPressed: () => _backToDashboard(context)),
          title: BlocBuilder<MessCubit, MessState>(
            builder: (context, state) {
              final name = state is MessDetailLoaded
                  ? state.detail.mess.name
                  : 'Mess Details';
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
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.read<MessCubit>().loadMess(messId),
                    borderRadius: BorderRadius.circular(20),
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
              ),
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
                          onPressed: () =>
                              context.read<MessCubit>().loadMess(messId),
                          icon: const Icon(Icons.refresh_rounded, size: 15),
                          label: const Text('Try Again'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.brandDark,
                            side: const BorderSide(color: AppColors.paperLine),
                            minimumSize: const Size(120, 38),
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
                  onRefresh: () async =>
                      context.read<MessCubit>().loadMess(messId),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Header Summary Card
                            _buildHeaderCard(context, mess, canManage),

                            const SizedBox(height: 18),

                            // 2. Active Month Sheet Card
                            _buildSheetsSection(context, months, canManage),

                            const SizedBox(height: 20),

                            // 3. Member Settlement Section
                            _buildMemberSettlementsSection(d),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 1. HEADER CARD (Minimal & Clean)
  // ==========================================
  Widget _buildHeaderCard(
    BuildContext context,
    MessModel mess,
    bool canManage,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.paperLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                    color: canManage
                        ? AppColors.brandDark
                        : AppColors.paperLine,
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

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.paperLine),
          const SizedBox(height: 10),

          // Meta Info Row
          Row(
            children: [
              _buildMetaItem(
                Icons.people_outline_rounded,
                '${mess.membersCount} members',
              ),
              _buildDotDivider(),
              _buildMetaItem(
                Icons.calendar_month_outlined,
                '${mess.monthsCount} sheets',
              ),
              _buildDotDivider(),
              _buildMetaItem(
                Icons.schedule_rounded,
                'Day ${mess.billingStartDay} Cycle',
              ),
            ],
          ),

          // Manager Action Buttons
          if (canManage || mess.isOwner) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (canManage) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final ok = await MessFormScreen.showAsDialog(
                          context,
                          mess: mess,
                          cubit: context.read<MessCubit>(),
                        );
                        if (ok == true && context.mounted) {
                          context.read<MessCubit>().loadMess(messId);
                        }
                      },
                      icon: const Icon(Icons.edit_outlined, size: 13),
                      label: const Text(
                        'Edit Details',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showInviteMemberModal(context, messId),
                      icon: const Icon(
                        Icons.person_add_alt_1_outlined,
                        size: 13,
                      ),
                      label: const Text(
                        'Invite Member',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.brandDark,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: const BorderSide(color: AppColors.paperLine),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
                if (mess.isOwner) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _confirmDeleteMess(context, mess),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.dangerSoft.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.dangerSoft),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
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
          Icon(icon, size: 13, color: AppColors.brandDark),
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
      child: Text(
        '·',
        style: TextStyle(
          color: AppColors.paperLine,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ==========================================
  // 2. ACTIVE MONTHLY SHEET SECTION
  // ==========================================
  Widget _buildSheetsSection(
    BuildContext context,
    List<MessMonthLite> months,
    bool canManage,
  ) {
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
                  onTap: () => _showCreateMonthModal(context, messId),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_rounded,
                          size: 14,
                          color: AppColors.brandDark,
                        ),
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
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.inkFaded,
                  ),
                ),
                if (canManage) ...[
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => _showCreateMonthModal(context, messId),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandDark,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Open First Month',
                      style: TextStyle(fontSize: 12),
                    ),
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
                onTap: () => _showCreateMonthModal(context, messId),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: 14,
                        color: AppColors.brandDark,
                      ),
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
        const SizedBox(height: 8),

        // Featured Active Sheet Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.paperRaised,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.paperLine),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
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
                                fontWeight: FontWeight.w800,
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
                              : '${activeMonth.daysInMonth} Days cycle',
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
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Past Sheets Accordion
        if (pastMonths.isNotEmpty) ...[
          const SizedBox(height: 10),
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
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: AppColors.paperLine),
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
                      leading: const Icon(
                        Icons.history_rounded,
                        size: 18,
                        color: AppColors.inkFaded,
                      ),
                      title: Text(
                        m.label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      subtitle: Text(
                        m.cycleLabel.isNotEmpty
                            ? m.cycleLabel
                            : '${m.daysInMonth} days',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.inkFaded,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.inkFaded,
                      ),
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

  // ==========================================
  // 3. MEMBER SETTLEMENT SECTION (Clean Cards)
  // ==========================================
  Widget _buildMemberSettlementsSection(MessDetailModel d) {
    final settlements = d.memberSettlements;
    final monthLabel = d.currentMonthLabel.isNotEmpty
        ? d.currentMonthLabel
        : 'Active Month';

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
          separatorBuilder: (_, _) => const SizedBox(height: 10),
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
    final isOwner = s.role.toLowerCase() == 'owner';
    final isManager = s.role.toLowerCase() == 'manager';
    final mealsStr = s.meals % 1 == 0
        ? s.meals.toInt().toString()
        : s.meals.toStringAsFixed(1);
    final spendStr = '${s.spend.toStringAsFixed(0)} ৳';
    final givenStr = '${s.given.toStringAsFixed(0)} ৳';
    final balanceValStr = '${s.balance.abs().toStringAsFixed(0)} ৳';
    final balancePrefix = isPositive ? '+' : '-';
    final avatarColor = _hexColor(s.color);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.paperLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(height: 3, color: avatarColor),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Avatar, Name/Role, Balance
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: avatarColor,
                        child: Text(
                          s.name.isNotEmpty ? s.name[0].toUpperCase() : 'M',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
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
                                    s.name,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
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
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isOwner
                                        ? const Color(0xFFEDE7F6)
                                        : isManager
                                        ? AppColors.brandSoft
                                        : AppColors.paper,
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: isOwner
                                          ? const Color(
                                              0xFF5E35B1,
                                            ).withValues(alpha: 0.3)
                                          : isManager
                                          ? AppColors.brandDark.withValues(
                                              alpha: 0.2,
                                            )
                                          : AppColors.paperLine,
                                    ),
                                  ),
                                  child: Text(
                                    isOwner
                                        ? 'OWNER'
                                        : isManager
                                        ? 'MANAGER'
                                        : 'MEMBER',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      color: isOwner
                                          ? const Color(0xFF5E35B1)
                                          : isManager
                                          ? AppColors.brandDark
                                          : AppColors.inkFaded,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (s.email.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                s.email,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.inkFaded,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Balance Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isPositive
                              ? AppColors.emeraldSoft
                              : AppColors.dangerSoft,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isPositive
                                ? AppColors.emerald.withValues(alpha: 0.25)
                                : AppColors.danger.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              isPositive ? 'SURPLUS' : 'DUE',
                              style: TextStyle(
                                fontSize: 7.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: isPositive
                                    ? AppColors.emerald
                                    : AppColors.danger,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '$balancePrefix$balanceValStr',
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
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Stat Tiles (Meals, Spend, Given)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(10),
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
                        Container(
                          width: 1,
                          height: 24,
                          color: AppColors.paperLine,
                        ),
                        Expanded(
                          child: _buildTileStat(
                            icon: Icons.shopping_bag_outlined,
                            iconColor: AppColors.inkSoft,
                            label: 'Spend',
                            value: spendStr,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: AppColors.paperLine,
                        ),
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
            Icon(icon, size: 11, color: iconColor),
            const SizedBox(width: 3),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                color: AppColors.inkFaded,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ==========================================
  // FALLBACK MEMBERS SECTION
  // ==========================================
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
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: AppColors.paperLine),
            itemBuilder: (context, i) {
              final member = members[i];
              final isManager =
                  member.memberRole == 'manager' ||
                  member.memberRole == 'owner';
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: _hexColor(member.color),
                      child: Text(
                        member.name.isNotEmpty
                            ? member.name[0].toUpperCase()
                            : 'M',
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
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.inkFaded,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isManager
                            ? AppColors.brandSoft
                            : AppColors.paper,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isManager
                              ? AppColors.brandDark.withValues(alpha: 0.15)
                              : AppColors.paperLine,
                        ),
                      ),
                      child: Text(
                        member.memberRole.toUpperCase(),
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: isManager
                              ? AppColors.brandDark
                              : AppColors.inkFaded,
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

    final parts = raw.split('·').map((e) => e.trim()).toList();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < parts.length; i++) ...[
          if (i > 0)
            const Text(
              '·',
              style: TextStyle(
                fontSize: 9,
                color: AppColors.inkFaded,
                fontWeight: FontWeight.bold,
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: parts[i] == '0' ? AppColors.dangerSoft : AppColors.paper,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: parts[i] == '0'
                    ? AppColors.danger.withValues(alpha: 0.3)
                    : AppColors.paperLine,
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

  // ==========================================
  // MODALS: OPEN MONTH SHEET
  // ==========================================
  void _showCreateMonthModal(BuildContext context, int messId) {
    final yearCtrl = TextEditingController(text: '${DateTime.now().year}');
    int selectedMonth = DateTime.now().month;

    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx2, setS) {
            final now = DateTime.now();
            final nextMonthDate = DateTime(now.year, now.month + 1, 1);

            return Dialog(
              backgroundColor: AppColors.paperRaised,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: const BorderSide(color: AppColors.paperLine),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              color: AppColors.brandDark,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Open New Monthly Sheet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.ink,
                                  ),
                                ),
                                SizedBox(height: 1),
                                Text(
                                  'Create 1–31 daily roster & ledger matrix',
                                  style: TextStyle(
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
                              borderRadius: BorderRadius.circular(20),
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

                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quick Preset Chips
                          Row(
                            children: [
                              ActionChip(
                                label: Text(
                                  'Current: ${monthNames[now.month - 1]} ${now.year}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        selectedMonth == now.month &&
                                            yearCtrl.text == '${now.year}'
                                        ? Colors.white
                                        : AppColors.ink,
                                  ),
                                ),
                                backgroundColor:
                                    selectedMonth == now.month &&
                                        yearCtrl.text == '${now.year}'
                                    ? AppColors.brandDark
                                    : AppColors.paper,
                                side: BorderSide(
                                  color:
                                      selectedMonth == now.month &&
                                          yearCtrl.text == '${now.year}'
                                      ? AppColors.brandDark
                                      : AppColors.paperLine,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                onPressed: () {
                                  setS(() {
                                    selectedMonth = now.month;
                                    yearCtrl.text = '${now.year}';
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              ActionChip(
                                label: Text(
                                  'Next: ${monthNames[nextMonthDate.month - 1]} ${nextMonthDate.year}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        selectedMonth == nextMonthDate.month &&
                                            yearCtrl.text ==
                                                '${nextMonthDate.year}'
                                        ? Colors.white
                                        : AppColors.ink,
                                  ),
                                ),
                                backgroundColor:
                                    selectedMonth == nextMonthDate.month &&
                                        yearCtrl.text == '${nextMonthDate.year}'
                                    ? AppColors.brandDark
                                    : AppColors.paper,
                                side: BorderSide(
                                  color:
                                      selectedMonth == nextMonthDate.month &&
                                          yearCtrl.text ==
                                              '${nextMonthDate.year}'
                                      ? AppColors.brandDark
                                      : AppColors.paperLine,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                onPressed: () {
                                  setS(() {
                                    selectedMonth = nextMonthDate.month;
                                    yearCtrl.text = '${nextMonthDate.year}';
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Month Dropdown & Year Input
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<int>(
                                  initialValue: selectedMonth,
                                  decoration: InputDecoration(
                                    labelText: 'Month',
                                    filled: true,
                                    fillColor: AppColors.paper,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.paperLine,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.paperLine,
                                      ),
                                    ),
                                  ),
                                  items: List.generate(12, (index) {
                                    return DropdownMenuItem<int>(
                                      value: index + 1,
                                      child: Text(
                                        monthNames[index],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    );
                                  }),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setS(() => selectedMonth = val);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: yearCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Year',
                                    filled: true,
                                    fillColor: AppColors.paper,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.paperLine,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.paperLine,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: saving
                                  ? null
                                  : () async {
                                      setS(() => saving = true);
                                      try {
                                        await MessRepository()
                                            .createMonth(messId, {
                                              'year':
                                                  int.tryParse(yearCtrl.text) ??
                                                  DateTime.now().year,
                                              'month': selectedMonth,
                                            });
                                        if (context.mounted) {
                                          Navigator.pop(ctx2);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Monthly sheet opened successfully',
                                              ),
                                            ),
                                          );
                                          context.read<MessCubit>().loadMess(
                                            messId,
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
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
                              icon: saving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.add_task_rounded,
                                      size: 18,
                                    ),
                              label: Text(
                                saving ? 'Opening...' : 'Create Monthly Sheet',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.brandDark,
                                foregroundColor: Colors.white,
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
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // MODALS: INVITE MEMBER (Modern & Polished)
  // ==========================================
  // ==========================================
  // MODALS: INVITE MEMBER (Centered Dialog Modal)
  // ==========================================
  void _showInviteMemberModal(BuildContext context, int messId) {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String selectedRole = 'member';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (context, setS) {
            return Dialog(
              backgroundColor: AppColors.paperRaised,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.paperLine),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.brandSoft,
                              borderRadius: BorderRadius.circular(12),
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
                              children: const [
                                Text(
                                  'Invite New Member',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: AppColors.ink,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Send an invite to join this mess group.',
                                  style: TextStyle(
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
                              onTap: () => Navigator.pop(ctx),
                              borderRadius: BorderRadius.circular(20),
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

                      const SizedBox(height: 18),

                      // Email Input Field
                      const Text(
                        'EMAIL ADDRESS',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.inkFaded,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.ink,
                        ),
                        decoration: InputDecoration(
                          hintText: 'member@example.com',
                          hintStyle: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.inkFaded,
                          ),
                          prefixIcon: const Icon(
                            Icons.alternate_email_rounded,
                            size: 16,
                            color: AppColors.brandDark,
                          ),
                          filled: true,
                          fillColor: AppColors.paper,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.paperLine,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.paperLine,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.brandDark,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Display Name Field
                      const Text(
                        'DISPLAY NAME (OPTIONAL)',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.inkFaded,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameCtrl,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.ink,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. Alex Johnson',
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
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.paperLine,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.paperLine,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.brandDark,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Role Selector Cards
                      const Text(
                        'ASSIGN ROLE',
                        style: TextStyle(
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
                            child: _buildRoleSelectCard(
                              title: 'Member',
                              subtitle: 'Regular tracker',
                              icon: Icons.person_outline_rounded,
                              isSelected: selectedRole == 'member',
                              onTap: () => setS(() => selectedRole = 'member'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildRoleSelectCard(
                              title: 'Manager',
                              subtitle: 'Admin access',
                              icon: Icons.shield_outlined,
                              isSelected: selectedRole == 'manager',
                              onTap: () => setS(() => selectedRole = 'manager'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Action Buttons Row
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.ink,
                                side: const BorderSide(
                                  color: AppColors.paperLine,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                minimumSize: const Size(0, 38),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
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
                                      final email = emailCtrl.text.trim();
                                      if (email.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please enter an email address',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      setS(() => saving = true);
                                      try {
                                        await MessRepository().storeInvite(
                                          messId,
                                          email,
                                          selectedRole,
                                          memberName:
                                              nameCtrl.text.trim().isNotEmpty
                                              ? nameCtrl.text.trim()
                                              : null,
                                        );
                                        if (context.mounted) {
                                          Navigator.pop(ctx);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Invitation sent successfully',
                                              ),
                                            ),
                                          );
                                          context.read<MessCubit>().loadMess(
                                            messId,
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
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
                                  : const Text(
                                      'Send Invite',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12.5,
                                      ),
                                    ),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.brandDark,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                minimumSize: const Size(0, 38),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
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
        );
      },
    );
  }

  Widget _buildRoleSelectCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandSoft : AppColors.paper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.brandDark : AppColors.paperLine,
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.brandDark : AppColors.inkFaded,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? AppColors.brandDark : AppColors.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.inkFaded,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: AppColors.brandDark,
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // CONFIRM DELETE MESS
  // ==========================================
  void _confirmDeleteMess(BuildContext context, MessModel mess) async {
    final confirm = await ConfirmDeleteDialog.show(
      context,
      title: 'Delete Mess?',
      itemName: mess.name,
      message:
          'Are you sure you want to delete this mess? All data, member accounts, sheets, and bazar records will be permanently removed. This action cannot be undone.',
      confirmLabel: 'Delete Mess',
      icon: Icons.apartment_rounded,
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
}
