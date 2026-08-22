import '../../../../core/locale/app_translations.dart';
import '../../../../core/utils/bn_digits.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/cache_manager.dart';
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
import '../../../dashboard/presentation/widgets/dash_ui.dart';

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

class _MessDetailView extends StatefulWidget {
  final int messId;
  const _MessDetailView({required this.messId});

  @override
  State<_MessDetailView> createState() => _MessDetailViewState();
}

class _MessDetailViewState extends State<_MessDetailView> with RouteAware {
  int get messId => widget.messId;

  RouteObserver<PageRoute<dynamic>>? _observer;
  PageRoute<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final obs = ModalRoute.of(context)?.navigator?.widget.observers
        .whereType<RouteObserver<PageRoute<dynamic>>>()
        .firstOrNull;
    // Fallback: try to locate the observer via the app's navigator if exposed as a singleton.
    // If not found, we still get coverage via the didPop re-entry below; observer is bonus for sheet→detail back without pop.
    _observer = obs;
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && _observer != null) {
      if (_route != route) {
        if (_route != null) {
          try {
            _observer!.unsubscribe(this);
          } catch (_) {}
        }
        _route = route;
        _observer!.subscribe(this, route);
      }
    }
  }

  @override
  void didPopNext() {
    if (!mounted) return;
    context.read<MessCubit>().loadMess(messId, forceRefresh: true);
  }

  @override
  void dispose() {
    if (_observer != null && _route != null) {
      try {
        _observer!.unsubscribe(this);
      } catch (_) {}
    }
    super.dispose();
  }

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
                  : 'ui.mess_details'.tr2;
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
                    onTap: () => context.read<MessCubit>().loadMess(
                      messId,
                      forceRefresh: true,
                    ),
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
                          onPressed: () => context.read<MessCubit>().loadMess(
                            messId,
                            forceRefresh: true,
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 15),
                          label: Text('ui.try_again'.tr2),
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
                  onRefresh: () async {
                    CacheManager.clearAll();
                    await context.read<MessCubit>().loadMess(
                      messId,
                      forceRefresh: true,
                    );
                  },
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
  // 1. HEADER HERO CARD (Polished Modern Look)
  // ==========================================
  Widget _buildHeaderCard(
    BuildContext context,
    MessModel mess,
    bool canManage,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(DashUI.rCard),
        border: Border.all(color: AppColors.paperLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar icon + Name/Location + Role badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.brandDark, AppColors.brand],
                        ),
                        borderRadius: BorderRadius.circular(DashUI.rCard),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brandDark.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.apartment_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mess.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: mess.location.isNotEmpty
                                    ? AppColors.inkFaded
                                    : AppColors.inkFaded.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  mess.location.isNotEmpty
                                      ? mess.location
                                      : 'ui.mess_no_location'.tr2,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: mess.location.isNotEmpty
                                        ? AppColors.inkFaded
                                        : AppColors.inkFaded.withValues(
                                            alpha: 0.6,
                                          ),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: canManage
                            ? AppColors.brandDark
                            : AppColors.paper,
                        borderRadius: BorderRadius.circular(DashUI.rBtn),
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
                          letterSpacing: 0.6,
                          color: canManage ? Colors.white : AppColors.inkFaded,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Quick Stat Chips Row
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(DashUI.rCard),
                    border: Border.all(color: AppColors.paperLine),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildHeaderStatPill(
                          icon: Icons.group_outlined,
                          value: bnDigits(mess.membersCount),
                          label: 'ui.mess_members'.tr2,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 26,
                        color: AppColors.paperLine,
                      ),
                      Expanded(
                        child: _buildHeaderStatPill(
                          icon: Icons.calendar_month_outlined,
                          value: bnDigits(mess.monthsCount),
                          label: 'ui.mess_sheets'.tr2,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 26,
                        color: AppColors.paperLine,
                      ),
                      Expanded(
                        child: _buildHeaderStatPill(
                          icon: Icons.repeat_rounded,
                          value:
                              '${'ui.mess_day'.tr2} ${bnDigits(mess.billingStartDay)}',
                          label: 'ui.mess_billing_cycle'.tr2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Manager Action Buttons
                if (canManage || (!mess.isIndividualMess && mess.isOwner)) ...[
                  const SizedBox(height: 14),
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
                                CacheManager.clearAll();
                                context.read<MessCubit>().loadMess(
                                  messId,
                                  forceRefresh: true,
                                );
                              }
                            },
                            icon: const Icon(Icons.edit_outlined, size: 14),
                            label: Text(
                              'ui.mess_edit'.tr2,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.ink,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              minimumSize: const Size(0, 36),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              side: const BorderSide(
                                color: AppColors.paperLine,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(DashUI.rBtn),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () =>
                                _showInviteMemberModal(context, messId),
                            icon: const Icon(
                              Icons.person_add_alt_1_rounded,
                              size: 14,
                            ),
                            label: Text(
                              'ui.mess_invite'.tr2,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.brandDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              minimumSize: const Size(0, 36),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(DashUI.rBtn),
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (!mess.isIndividualMess && mess.isOwner) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _confirmDeleteMess(context, mess),
                          borderRadius: BorderRadius.circular(DashUI.rBtn),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.dangerSoft.withValues(
                                alpha: 0.4,
                              ),
                              borderRadius: BorderRadius.circular(DashUI.rBtn),
                              border: Border.all(color: AppColors.dangerSoft),
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
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStatPill({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: AppColors.brandDark),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.inkFaded,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ==========================================
  // 2. ACTIVE MONTHLY SHEET SECTION (Modern Redesign)
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
              Text(
                'ui.mess_monthly_sheet'.tr2,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkFaded,
                  letterSpacing: 0.8,
                ),
              ),
              InkWell(
                onTap: () => _showCreateMonthModal(context, messId),
                borderRadius: BorderRadius.circular(DashUI.rBtn),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(DashUI.rBtn),
                    border: Border.all(color: AppColors.paperLine),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        size: 14,
                        color: AppColors.brandDark,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ui.mess_open_month'.tr2,
                        style: const TextStyle(
                          fontSize: 11.5,
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.paperRaised,
              borderRadius: BorderRadius.circular(DashUI.rCard),
              border: Border.all(color: AppColors.paperLine),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(DashUI.rCard),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    size: 26,
                    color: AppColors.brandDark,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'ui.mess_no_sheets'.tr2,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  canManage
                      ? 'ui.mess_no_sheets_manager'.tr2
                      : 'ui.mess_no_sheets_member'.tr2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.inkFaded,
                    height: 1.4,
                  ),
                ),
                if (canManage) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showCreateMonthModal(context, messId),
                    icon: const Icon(Icons.add_task_rounded, size: 16),
                    label: Text('ui.mess_open_first_sheet'.tr2),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DashUI.rTile),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    // Active month selection
    final activeMonth = months.firstWhere(
      (m) => m.isActive,
      orElse: () => months[0],
    );
    final pastMonths = months.where((m) => m.id != activeMonth.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ui.mess_active_sheet'.tr2,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.inkFaded,
                letterSpacing: 0.8,
              ),
            ),
            if (canManage)
              InkWell(
                onTap: () => _showCreateMonthModal(context, messId),
                borderRadius: BorderRadius.circular(DashUI.rBtn),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(DashUI.rBtn),
                    border: Border.all(color: AppColors.paperLine),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        size: 13,
                        color: AppColors.brandDark,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'ui.mess_new_month'.tr2,
                        style: const TextStyle(
                          fontSize: 11,
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

        // Featured Active Sheet Card (Premium Hero Container)
        Container(
          decoration: BoxDecoration(
            color: AppColors.paperRaised,
            borderRadius: BorderRadius.circular(DashUI.rCard),
            border: Border.all(color: AppColors.brandSoft, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandDark.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar: Custom Month Switcher Button + Delete icon
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(DashUI.rCard)),
                  border: Border(
                    bottom: BorderSide(color: AppColors.paperLine),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldSoft,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.emerald.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 10,
                            color: AppColors.emerald,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'ui.mess_current_active'.tr2,
                            style: const TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                              color: AppColors.emerald,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (canManage && months.length > 1)
                      InkWell(
                        onTap: () =>
                            _showMonthPickerSheet(context, months, activeMonth),
                        borderRadius: BorderRadius.circular(DashUI.rBtn),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.paperRaised,
                            borderRadius: BorderRadius.circular(DashUI.rBtn),
                            border: Border.all(color: AppColors.paperLine),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.swap_horiz_rounded,
                                size: 13,
                                color: AppColors.brandDark,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ui.mess_switch_month'.tr2,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brandDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (canManage) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () =>
                            _confirmDeleteMonth(context, messId, activeMonth),
                        borderRadius: BorderRadius.circular(DashUI.rBtn),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.dangerSoft.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(DashUI.rBtn),
                            border: Border.all(color: AppColors.dangerSoft),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            size: 14,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Main Body of Active Sheet Card
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.brandSoft,
                            borderRadius: BorderRadius.circular(DashUI.rCard),
                            border: Border.all(color: AppColors.paperLine),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: AppColors.brandDark,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeMonth.label,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.ink,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.timelapse_rounded,
                                    size: 13,
                                    color: AppColors.inkFaded,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      activeMonth.cycleLabel.isNotEmpty
                                          ? activeMonth.cycleLabel.replaceAll(
                                              r'\u2192',
                                              '→',
                                            )
                                          : '${bnDigits(activeMonth.daysInMonth)} ${'ui.mess_days_cycle'.tr2}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
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
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Primary Button to Enter Matrix
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
                        icon: const Icon(Icons.table_chart_rounded, size: 16),
                        label: Text(
                          'ui.mess_open_matrix'.tr2,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brandDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DashUI.rTile),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Past Sheets Collapsed Accordion (Card Style)
        if (pastMonths.isNotEmpty) ...[
          const SizedBox(height: 14),
          Material(
            color: AppColors.paperRaised,
            borderRadius: BorderRadius.circular(DashUI.rCard),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DashUI.rCard),
              side: const BorderSide(color: AppColors.paperLine),
            ),
            elevation: 0,
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                leading: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(DashUI.rBtn),
                    border: Border.all(color: AppColors.paperLine),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    size: 18,
                    color: AppColors.inkFaded,
                  ),
                ),
                title: Text(
                  '${'ui.mess_past_sheets'.tr2} (${bnDigits(pastMonths.length)})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                subtitle: Text(
                  'ui.mess_past_sheets_sub'.tr2,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.inkFaded,
                  ),
                ),
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pastMonths.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final m = pastMonths[i];
                      return Material(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(DashUI.rCard),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DashUI.rCard),
                          side: const BorderSide(color: AppColors.paperLine),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(DashUI.rCard),
                          onTap: () =>
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MessSheetScreen(
                                    messId: messId,
                                    monthId: m.id,
                                    monthLabel: m.label,
                                  ),
                                ),
                              ).then((_) {
                                if (context.mounted) {
                                  CacheManager.clearAll();
                                  context.read<MessCubit>().loadMess(
                                    messId,
                                    forceRefresh: true,
                                  );
                                }
                              }),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.paperRaised,
                                    borderRadius: BorderRadius.circular(DashUI.rBtn),
                                    border: Border.all(
                                      color: AppColors.paperLine,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.calendar_today_outlined,
                                      size: 17,
                                      color: AppColors.inkSoft,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.label,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        m.cycleLabel.isNotEmpty
                                            ? m.cycleLabel
                                            : '${bnDigits(m.daysInMonth)} ${'ui.mess_days_cycle'.tr2}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.inkFaded,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (canManage) ...[
                                  InkWell(
                                    onTap: () async {
                                      final ok = await context
                                          .read<MessCubit>()
                                          .activateMonth(messId, m.id);
                                      if (ok && context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'ui.mess_now_active'.tr2
                                                  .replaceAll(
                                                    '{label}',
                                                    m.label,
                                                  ),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(DashUI.rBtn),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.brandSoft,
                                        borderRadius: BorderRadius.circular(DashUI.rBtn),
                                        border: Border.all(
                                          color: AppColors.paperLine,
                                        ),
                                      ),
                                      child: Text(
                                        'ui.mess_set_active'.tr2,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.brandDark,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () =>
                                        _confirmDeleteMonth(context, messId, m),
                                    borderRadius: BorderRadius.circular(DashUI.rBtn),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.dangerSoft.withValues(
                                          alpha: 0.4,
                                        ),
                                        borderRadius: BorderRadius.circular(DashUI.rBtn),
                                        border: Border.all(
                                          color: AppColors.dangerSoft,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 14,
                                        color: AppColors.danger,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: AppColors.inkFaded,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ==========================================
  // CUSTOM MONTH PICKER BOTTOM SHEET MODAL
  // ==========================================
  void _showMonthPickerSheet(
    BuildContext context,
    List<MessMonthLite> months,
    MessMonthLite activeMonth,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.paperRaised,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ui.mess_select_active_month'.tr2,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ui.mess_select_active_month_sub'.tr2,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.inkFaded,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(ctx),
                    borderRadius: BorderRadius.circular(DashUI.rCard),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.paper,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: months.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final m = months[i];
                  final isCurrentlyActive = m.id == activeMonth.id;
                  return InkWell(
                    onTap: () async {
                      Navigator.pop(ctx);
                      if (isCurrentlyActive) return;
                      final ok = await context.read<MessCubit>().activateMonth(
                        messId,
                        m.id,
                      );
                      if (ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'ui.mess_now_active'.tr2.replaceAll(
                                '{label}',
                                m.label,
                              ),
                            ),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(DashUI.rCard),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrentlyActive
                            ? AppColors.brandSoft
                            : AppColors.paper,
                        borderRadius: BorderRadius.circular(DashUI.rCard),
                        border: Border.all(
                          color: isCurrentlyActive
                              ? AppColors.brandDark
                              : AppColors.paperLine,
                          width: isCurrentlyActive ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isCurrentlyActive
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            color: isCurrentlyActive
                                ? AppColors.brandDark
                                : AppColors.inkFaded,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isCurrentlyActive
                                        ? FontWeight.w900
                                        : FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                if (m.cycleLabel.isNotEmpty) ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    m.cycleLabel,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.inkFaded,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isCurrentlyActive)
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
                                'ui.mess_active_badge'.tr2,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  color: AppColors.emerald,
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
        );
      },
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
              '${'ui.mess_settlement_header'.tr2} — ${monthLabel.toUpperCase()}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.inkFaded,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              '${bnDigits(settlements.length)} ${'ui.mess_members_count'.tr2}',
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
    final balanceValStr = '${s.balance.abs().toStringAsFixed(0)} ৳';
    final balancePrefix = isPositive ? '+' : '-';
    final avatarColor = _hexColor(s.color);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(DashUI.rCard),
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
        borderRadius: BorderRadius.circular(DashUI.rCard),
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
                                        ? 'ui.role_owner'.tr2
                                        : isManager
                                        ? 'ui.role_manager'.tr2
                                        : 'ui.role_member'.tr2,
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
                          borderRadius: BorderRadius.circular(DashUI.rBtn),
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
                              isPositive
                                  ? 'ui.mess_surplus'.tr2
                                  : 'ui.mess_due'.tr2,
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
                      borderRadius: BorderRadius.circular(DashUI.rBtn),
                      border: Border.all(color: AppColors.paperLine),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTileStat(
                            icon: Icons.restaurant_menu_rounded,
                            iconColor: AppColors.brandDark,
                            label: 'ui.mess_stat_meals'.tr2,
                            value: bnDigits(mealsStr),
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
                            label: 'ui.mess_stat_spend'.tr2,
                            value: '৳${bnDigits(s.spend.toStringAsFixed(0))}',
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
                            label: 'ui.mess_stat_given'.tr2,
                            value: '৳${bnDigits(s.given.toStringAsFixed(0))}',
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
            Text(
              'ui.mess_members_label'.tr2,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.inkFaded,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              '${bnDigits(members.length)} ${'ui.mess_total'.tr2}',
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
            borderRadius: BorderRadius.circular(DashUI.rCard),
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
              parts[i].toBnNum(),
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
    final now = DateTime.now();
    final yearCtrl = TextEditingController(text: '${now.year}');
    int selectedMonth = now.month;
    DateTime? startDate;
    DateTime? endDate;

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

    String formatIsoDate(DateTime d) {
      return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }

    String formatDisplayDate(DateTime d) {
      return '${d.day} ${monthNames[d.month - 1].substring(0, 3)} ${d.year}';
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx2, setS) {
            final nextMonthDate = DateTime(now.year, now.month + 1, 1);

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
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
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
                                Icons.calendar_month_rounded,
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
                                    'ui.mess_open_month_title'.tr2,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    'ui.mess_open_month_sub'.tr2,
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
                                    borderRadius: BorderRadius.circular(DashUI.rBtn),
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
                                          selectedMonth ==
                                                  nextMonthDate.month &&
                                              yearCtrl.text ==
                                                  '${nextMonthDate.year}'
                                          ? Colors.white
                                          : AppColors.ink,
                                    ),
                                  ),
                                  backgroundColor:
                                      selectedMonth == nextMonthDate.month &&
                                          yearCtrl.text ==
                                              '${nextMonthDate.year}'
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
                                    borderRadius: BorderRadius.circular(DashUI.rBtn),
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
                                      labelText: 'ui.mess_month_label'.tr2,
                                      filled: true,
                                      fillColor: AppColors.paper,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(DashUI.rTile),
                                        borderSide: const BorderSide(
                                          color: AppColors.paperLine,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(DashUI.rTile),
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
                                      labelText: 'ui.mess_year_label'.tr2,
                                      filled: true,
                                      fillColor: AppColors.paper,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(DashUI.rTile),
                                        borderSide: const BorderSide(
                                          color: AppColors.paperLine,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(DashUI.rTile),
                                        borderSide: const BorderSide(
                                          color: AppColors.paperLine,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // --- Period Start & End Date Pickers (Two Individual Date Pickers) ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'ui.mess_billing_cycle_optional'.tr2,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: AppColors.inkSoft,
                                  ),
                                ),
                                if (startDate != null || endDate != null)
                                  InkWell(
                                    onTap: () {
                                      setS(() {
                                        startDate = null;
                                        endDate = null;
                                      });
                                    },
                                    child: Text(
                                      'ui.mess_reset_default'.tr2,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.brandDark,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Row with 2 clean date selector boxes (Period Start & Period End)
                            Row(
                              children: [
                                // 1. Period Start Date Picker Box
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final initialDate =
                                          startDate ??
                                          DateTime(
                                            int.tryParse(yearCtrl.text) ??
                                                now.year,
                                            selectedMonth,
                                            1,
                                          );
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: initialDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2035),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme:
                                                  const ColorScheme.light(
                                                    primary:
                                                        AppColors.brandDark,
                                                    onPrimary: Colors.white,
                                                    surface:
                                                        AppColors.paperRaised,
                                                    onSurface: AppColors.ink,
                                                  ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      if (picked != null) {
                                        setS(() {
                                          startDate = picked;
                                          if (endDate != null &&
                                              endDate!.isBefore(picked)) {
                                            endDate = picked.add(
                                              const Duration(days: 29),
                                            );
                                          }
                                        });
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(DashUI.rTile),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 11,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.paper,
                                        borderRadius: BorderRadius.circular(DashUI.rTile),
                                        border: Border.all(
                                          color: startDate != null
                                              ? AppColors.brandDark
                                              : AppColors.paperLine,
                                          width: startDate != null ? 1.4 : 1.0,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today_rounded,
                                                size: 13,
                                                color: AppColors.brandDark,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                'ui.mess_period_start'.tr2,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.inkFaded,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            startDate != null
                                                ? formatDisplayDate(startDate!)
                                                : '${1} ${monthNames[selectedMonth - 1].substring(0, 3)} ${yearCtrl.text}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: startDate != null
                                                  ? AppColors.ink
                                                  : AppColors.inkSoft,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // 2. Period End Date Picker Box
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final defaultEnd = DateTime(
                                        int.tryParse(yearCtrl.text) ?? now.year,
                                        selectedMonth + 1,
                                        0,
                                      );
                                      final initialDate =
                                          endDate ??
                                          (startDate != null
                                              ? startDate!.add(
                                                  const Duration(days: 29),
                                                )
                                              : defaultEnd);
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: initialDate,
                                        firstDate: startDate ?? DateTime(2020),
                                        lastDate: DateTime(2035),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme:
                                                  const ColorScheme.light(
                                                    primary:
                                                        AppColors.brandDark,
                                                    onPrimary: Colors.white,
                                                    surface:
                                                        AppColors.paperRaised,
                                                    onSurface: AppColors.ink,
                                                  ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      if (picked != null) {
                                        setS(() {
                                          endDate = picked;
                                        });
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(DashUI.rTile),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 11,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.paper,
                                        borderRadius: BorderRadius.circular(DashUI.rTile),
                                        border: Border.all(
                                          color: endDate != null
                                              ? AppColors.brandDark
                                              : AppColors.paperLine,
                                          width: endDate != null ? 1.4 : 1.0,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.event_available_rounded,
                                                size: 13,
                                                color: AppColors.brandDark,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                'ui.mess_period_end'.tr2,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.inkFaded,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            endDate != null
                                                ? formatDisplayDate(endDate!)
                                                : '${DateTime(int.tryParse(yearCtrl.text) ?? now.year, selectedMonth + 1, 0).day} ${monthNames[selectedMonth - 1].substring(0, 3)} ${yearCtrl.text}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: endDate != null
                                                  ? AppColors.ink
                                                  : AppColors.inkSoft,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (startDate != null && endDate != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    size: 13,
                                    color: AppColors.brandDark,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${endDate!.difference(startDate!).inDays + 1} days in custom billing period (${formatIsoDate(startDate!)} → ${formatIsoDate(endDate!)})',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.inkFaded,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: saving
                                    ? null
                                    : () async {
                                        setS(() => saving = true);
                                        try {
                                          final payload = <String, dynamic>{
                                            'year':
                                                int.tryParse(yearCtrl.text) ??
                                                DateTime.now().year,
                                            'month': selectedMonth,
                                          };
                                          if (startDate != null &&
                                              endDate != null) {
                                            payload['cycle_start_date'] =
                                                formatIsoDate(startDate!);
                                            payload['cycle_end_date'] =
                                                formatIsoDate(endDate!);
                                          }
                                          await MessRepository().createMonth(
                                            messId,
                                            payload,
                                          );
                                          if (context.mounted) {
                                            Navigator.pop(ctx2);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'ui.mess_sheet_opened'.tr2,
                                                ),
                                              ),
                                            );
                                            context.read<MessCubit>().loadMess(
                                              messId,
                                              forceRefresh: true,
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
                                  saving
                                      ? 'ui.mess_opening'.tr2
                                      : 'ui.mess_create_sheet'.tr2,
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
                                    borderRadius: BorderRadius.circular(DashUI.rTile),
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
                borderRadius: BorderRadius.circular(DashUI.rCard),
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
                                  'ui.mess_invite_title'.tr2,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'ui.mess_invite_sub'.tr2,
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
                              onTap: () => Navigator.pop(ctx),
                              borderRadius: BorderRadius.circular(DashUI.rCard),
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
                      Text(
                        'ui.mess_invite_email'.tr2,
                        style: const TextStyle(
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
                          hintText: 'ui.mess_invite_email_hint'.tr2,
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

                      const SizedBox(height: 12),

                      // Display Name Field
                      Text(
                        'ui.mess_invite_name'.tr2,
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
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.ink,
                        ),
                        decoration: InputDecoration(
                          hintText: 'ui.mess_invite_name_hint'.tr2,
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

                      const SizedBox(height: 14),

                      // Role Selector Cards
                      Text(
                        'ui.mess_invite_role'.tr2,
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
                            child: _buildRoleSelectCard(
                              title: 'ui.role_member'.tr2,
                              subtitle: 'ui.mess_role_regular'.tr2,
                              icon: Icons.person_outline_rounded,
                              isSelected: selectedRole == 'member',
                              onTap: () => setS(() => selectedRole = 'member'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildRoleSelectCard(
                              title: 'ui.role_manager'.tr2,
                              subtitle: 'ui.mess_role_admin'.tr2,
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
                                  borderRadius: BorderRadius.circular(DashUI.rBtn),
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
                                      final email = emailCtrl.text.trim();
                                      if (email.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'ui.mess_invite_email_required'
                                                  .tr2,
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
                                            SnackBar(
                                              content: Text(
                                                'ui.mess_invite_sent'.tr2,
                                              ),
                                            ),
                                          );
                                          context.read<MessCubit>().loadMess(
                                            messId,
                                            forceRefresh: true,
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
                                  : Text(
                                      'ui.mess_send_invite'.tr2,
                                      style: const TextStyle(
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
                                  borderRadius: BorderRadius.circular(DashUI.rBtn),
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
      borderRadius: BorderRadius.circular(DashUI.rTile),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandSoft : AppColors.paper,
          borderRadius: BorderRadius.circular(DashUI.rTile),
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
      title: 'ui.confirm_delete_mess_title'.tr2,
      itemName: mess.name,
      message: 'ui.confirm_delete_mess_message'.tr2,
      confirmLabel: 'ui.confirm_delete_mess_label'.tr2,
      icon: Icons.apartment_rounded,
    );

    if (confirm == true && context.mounted) {
      final ok = await context.read<MessCubit>().deleteMess(mess.id);
      if (ok && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ui.mess_deleted'.tr2)));
        Navigator.pop(context);
      }
    }
  }

  void _confirmDeleteMonth(
    BuildContext context,
    int messId,
    MessMonthLite month,
  ) async {
    final confirm = await ConfirmDeleteDialog.show(
      context,
      title: 'ui.confirm_delete_sheet_title'.tr2,
      itemName: month.label,
      message: 'ui.confirm_delete_sheet_message'.tr2,
      confirmLabel: 'ui.confirm_delete_sheet_label'.tr2,
      icon: Icons.calendar_month_rounded,
    );

    if (confirm == true && context.mounted) {
      final ok = await context.read<MessCubit>().deleteMonth(messId, month.id);
      if (ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ui.mess_sheet_deleted'.tr2.replaceAll('{label}', month.label),
            ),
          ),
        );
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
