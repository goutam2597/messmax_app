import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/bazar_schedule_model.dart';
import '../cubit/bazar_schedule_cubit.dart';
import '../cubit/bazar_schedule_state.dart';

class BazarScheduleScreen extends StatelessWidget {
  final int? messId;

  const BazarScheduleScreen({super.key, this.messId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BazarScheduleCubit()..loadSchedule(messId: messId),
      child: const _BazarScheduleView(),
    );
  }
}

class _BazarScheduleView extends StatefulWidget {
  const _BazarScheduleView();

  @override
  State<_BazarScheduleView> createState() => _BazarScheduleViewState();
}

class _BazarScheduleViewState extends State<_BazarScheduleView> {
  // --- ADD / EDIT ASSIGNMENT MODAL WITH CALENDAR DATE PICKERS ---
  void _showAddEditModal(
    BuildContext context,
    BazarScheduleResponseModel data, {
    BazarDayItemModel? prefilledSchedule,
  }) {
    final firstDate = DateTime(data.year, data.month, 1);
    final lastDate = DateTime(data.year, data.month, data.daysInMonth);

    DateTime? selectedFromDate = prefilledSchedule != null
        ? DateTime(data.year, data.month, prefilledSchedule.day)
        : null;
    DateTime? selectedToDate;

    int? selectedMemberId = prefilledSchedule?.messMemberId;
    final staffController = TextEditingController(
      text: prefilledSchedule?.staffName ?? '',
    );
    final noteController = TextEditingController(
      text: prefilledSchedule?.note ?? '',
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            String formatDateLabel(DateTime? dt) {
              if (dt == null) return 'Select date';
              const months = [
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
              return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
            }

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
              child: SingleChildScrollView(
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
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          color: AppColors.brandDark,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          prefilledSchedule != null
                              ? 'Edit Assignment — ${data.monthLabel}'
                              : 'Add Assignment — ${data.monthLabel}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'From date + optional To date. Same person on every day in range.',
                      style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 16),

                    // --- CALENDAR DATE PICKERS ---
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'FROM DATE *',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedFromDate ?? firstDate,
                                    firstDate: firstDate,
                                    lastDate: lastDate,
                                  );
                                  if (picked != null) {
                                    setSheetState(() {
                                      selectedFromDate = picked;
                                      if (selectedToDate != null &&
                                          selectedToDate!.isBefore(picked)) {
                                        selectedToDate = picked;
                                      }
                                    });
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.paper,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.paperLine,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_rounded,
                                        size: 16,
                                        color: AppColors.brandDark,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          formatDateLabel(selectedFromDate),
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: selectedFromDate != null
                                                ? AppColors.ink
                                                : AppColors.inkFaded,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TO DATE (OPTIONAL)',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        selectedToDate ??
                                        selectedFromDate ??
                                        firstDate,
                                    firstDate: selectedFromDate ?? firstDate,
                                    lastDate: lastDate,
                                  );
                                  if (picked != null) {
                                    setSheetState(
                                      () => selectedToDate = picked,
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.paper,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.paperLine,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_month_outlined,
                                        size: 16,
                                        color: AppColors.inkFaded,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          selectedToDate != null
                                              ? formatDateLabel(selectedToDate)
                                              : 'Single day',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: selectedToDate != null
                                                ? AppColors.ink
                                                : AppColors.inkFaded,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (selectedToDate != null)
                                        GestureDetector(
                                          onTap: () => setSheetState(
                                            () => selectedToDate = null,
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
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // MEMBER DROPDOWN
                    const Text(
                      'MEMBER',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      initialValue: selectedMemberId,
                      hint: const Text('— pick member —'),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 14),
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('— pick member —'),
                        ),
                        ...data.members.map((m) {
                          final dayBadge = m.bazarDay != null
                              ? ' (${m.bazarDay})'
                              : '';
                          return DropdownMenuItem<int>(
                            value: m.id,
                            child: Text('${m.name} — ${m.role}$dayBadge'),
                          );
                        }),
                      ],
                      onChanged: (val) =>
                          setSheetState(() => selectedMemberId = val),
                    ),
                    const SizedBox(height: 14),

                    // OR STAFF INPUT
                    const Text(
                      'OR STAFF (OUTSIDE)',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: staffController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Cook Karim / Bua',
                        prefixIcon: Icon(
                          Icons.person_outline_rounded,
                          size: 20,
                          color: AppColors.inkFaded,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // NOTE INPUT
                    const Text(
                      'NOTE / SHOPPING INSTRUCTIONS',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        hintText:
                            'e.g. Buy fish, vegetables, and 5kg Miniket rice',
                        prefixIcon: Icon(
                          Icons.notes_rounded,
                          size: 20,
                          color: AppColors.inkFaded,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SUBMIT BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          if (selectedFromDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select From Date'),
                              ),
                            );
                            return;
                          }
                          final fromDay = selectedFromDate!.day;
                          final toDay = selectedToDate?.day;
                          final staff = staffController.text.trim();

                          if (selectedMemberId == null && staff.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Select a member or enter staff name',
                                ),
                              ),
                            );
                            return;
                          }

                          Navigator.pop(ctx);
                          context.read<BazarScheduleCubit>().assignSchedule(
                            fromDay: fromDay,
                            toDay: toDay,
                            messMemberId: selectedMemberId,
                            staffName: staff,
                            note: noteController.text.trim(),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brandDark,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          prefilledSchedule != null
                              ? 'Save Changes'
                              : 'Add Assignment',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
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

  // --- NOTIFY ASSIGNEE DIALOG SHEET ---
  void _showNotifyModal(
    BuildContext context,
    BazarScheduleResponseModel data,
    BazarDayItemModel item,
  ) {
    final notesController = TextEditingController();
    final member = item.messMemberId != null
        ? data.members.firstWhere(
            (m) => m.id == item.messMemberId,
            orElse: () => const BazarMemberModel(id: 0, name: '', role: ''),
          )
        : null;
    final defaultEmail = member?.email ?? '';
    final emailController = TextEditingController(text: defaultEmail);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
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
          child: SingleChildScrollView(
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
                  children: const [
                    Icon(
                      Icons.mark_email_read_rounded,
                      color: AppColors.brandDark,
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Notify Assignee via Email',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Send SMTP duty notification for ${item.dateLabel} (${item.displayName})',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'RECIPIENT EMAIL *',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'member@example.com',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      size: 20,
                      color: AppColors.inkFaded,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                const Text(
                  'ADDITIONAL NOTES / INSTRUCTIONS',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText:
                        'e.g. Please bring 5kg Ruhi fish, onions, and oil',
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      final email = emailController.text.trim();
                      if (email.isEmpty || !email.contains('@')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid email address'),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      context.read<BazarScheduleCubit>().notifyAssignee(
                        day: item.day,
                        notes: notesController.text.trim(),
                        emailOverride: email,
                      );
                    },
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Send SMTP Notification'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandDark,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: BlocBuilder<BazarScheduleCubit, BazarScheduleState>(
          builder: (context, state) {
            final mess = state is BazarScheduleLoaded
                ? state.schedule.mess
                : null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bazar schedule',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  mess != null ? mess.name : 'Shopping Rota',
                  style: const TextStyle(
                    fontSize: 11.5,
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
            icon: const Icon(Icons.refresh_rounded, color: AppColors.ink),
            onPressed: () => context.read<BazarScheduleCubit>().loadSchedule(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<BazarScheduleCubit, BazarScheduleState>(
          listener: (context, state) {
            if (state is BazarScheduleLoaded && state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: AppColors.brandDark,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is BazarScheduleLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.brandDark),
              );
            }

            if (state is BazarScheduleError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 44,
                        color: AppColors.accentDark,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () =>
                            context.read<BazarScheduleCubit>().loadSchedule(),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is BazarScheduleLoaded) {
              final data = state.schedule;
              final assignedRows = data.schedules
                  .where((s) => s.isAssigned)
                  .toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. MONTH SELECTOR STRIP ---
                    _buildMonthHeaderStrip(context, data),
                    const SizedBox(height: 16),

                    // --- 2. SCHEDULE HEADING & ADD ASSIGNMENT BUTTON ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.list_alt_rounded,
                                    size: 18,
                                    color: AppColors.brandDark,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Schedule Rota',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${data.assignedCount}/${data.daysInMonth} days assigned',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.inkFaded,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (data.canManage)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FilledButton.icon(
                                onPressed: () =>
                                    _showAddEditModal(context, data),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Add assignment'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.brandDark,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              if (assignedRows.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (dCtx) => AlertDialog(
                                        title: const Text(
                                          'Clear Entire Month?',
                                        ),
                                        content: Text(
                                          'Are you sure you want to remove all assignments for ${data.monthLabel}?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(dCtx),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(dCtx);
                                              context
                                                  .read<BazarScheduleCubit>()
                                                  .clearMonth();
                                            },
                                            child: const Text(
                                              'Clear Month',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.delete_sweep_outlined,
                                    color: AppColors.accentDark,
                                  ),
                                ),
                              ],
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // --- 3. SCHEDULED ASSIGNED DAYS LIST OR EMPTY STATE ---
                    if (assignedRows.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 32,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.paperRaised,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.paperLine,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.brandSoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.calendar_month_outlined,
                                color: AppColors.brandDark,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No assignments yet for ${data.monthLabel}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Add one date or date range at a time via the button above.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.inkFaded,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: [
                          for (int i = 0; i < assignedRows.length; i++) ...[
                            if (i > 0) const SizedBox(height: 10),
                            _buildAssignedDayCard(
                              context,
                              data,
                              assignedRows[i],
                            ),
                          ],
                        ],
                      ),
                    const SizedBox(height: 24),

                    // --- 4. ANNOUNCEMENT BROADCAST CARD AT BOTTOM ---
                    if (data.canManage) _buildAnnouncementCard(context, data),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildMonthHeaderStrip(
    BuildContext context,
    BazarScheduleResponseModel data,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.paperLine),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.mess.name} • ${data.monthLabel}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Rota only — does not affect meal rate. All ${data.members.length} members are assignable.',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.inkFaded,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.ink,
                ),
                onPressed: () =>
                    context.read<BazarScheduleCubit>().changeMonth(-1),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brandDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data.monthLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.ink,
                ),
                onPressed: () =>
                    context.read<BazarScheduleCubit>().changeMonth(1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- ASSIGNED DAY CARD MATCHING WEB ---
  Widget _buildAssignedDayCard(
    BuildContext context,
    BazarScheduleResponseModel data,
    BazarDayItemModel item,
  ) {
    final member = item.messMemberId != null
        ? data.members.firstWhere(
            (m) => m.id == item.messMemberId,
            orElse: () => const BazarMemberModel(id: 0, name: '', role: ''),
          )
        : null;

    final mail = member?.email ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isToday ? const Color(0xFF0F9F59) : AppColors.paperLine,
          width: item.isToday ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.isToday
                      ? const Color(0xFF0F9F59)
                      : AppColors.brandDark,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.dateLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Avatar & Name
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: member != null
                            ? AppColors.brandDark
                            : AppColors.inkSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          item.displayName != null &&
                                  item.displayName!.isNotEmpty
                              ? item.displayName![0].toUpperCase()
                              : 'S',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  item.displayName ?? 'Staff',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: member != null
                                      ? AppColors.brandSoft
                                      : AppColors.paperLine,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  member != null ? member.role : 'staff',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: member != null
                                        ? AppColors.brandDark
                                        : AppColors.inkSoft,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (mail.isNotEmpty)
                            Text(
                              mail,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.inkFaded,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              if (data.canManage) ...[
                if (member != null) ...[
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.mail_outline_rounded,
                      size: 18,
                      color: AppColors.brandDark,
                    ),
                    onPressed: () => _showNotifyModal(context, data, item),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppColors.inkSoft,
                  ),
                  onPressed: () =>
                      _showAddEditModal(context, data, prefilledSchedule: item),
                ),
                const SizedBox(width: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.inkFaded,
                  ),
                  onPressed: () {
                    if (item.id != null) {
                      context.read<BazarScheduleCubit>().deleteAssignment(
                        item.id!,
                      );
                    }
                  },
                ),
              ],
            ],
          ),

          // Notes / Instructions block
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.paperLine),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.sticky_note_2_outlined,
                      size: 13,
                      color: AppColors.brandDark,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'NOTES / INSTRUCTIONS',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.inkFaded,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.note != null && item.note!.isNotEmpty
                      ? item.note!
                      : 'No instructions — manager can add what to bring via Edit or Notify.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: item.note != null && item.note!.isNotEmpty
                        ? AppColors.ink
                        : AppColors.inkFaded,
                    fontStyle: item.note != null && item.note!.isNotEmpty
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. ANNOUNCEMENT BROADCAST CARD MATCHING WEB ---
  Widget _buildAnnouncementCard(
    BuildContext context,
    BazarScheduleResponseModel data,
  ) {
    final subjectController = TextEditingController(
      text: 'Announcement — ${data.mess.name} · ${data.monthLabel} — MessMax',
    );
    final messageController = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandDark, AppColors.brandDeep],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandDark.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.campaign_outlined, color: Color(0xFFFFD1A3), size: 22),
              SizedBox(width: 8),
              Text(
                'ANNOUNCEMENT TO ALL MEMBERS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFFD1A3),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'One message to every member of ${data.mess.name} — everyone gets the same email (staff rows skipped).',
            style: const TextStyle(fontSize: 11.5, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            '${data.members.length} members · ${data.members.where((m) => m.email != null && m.email!.isNotEmpty).length} with email · ${data.assignedCount} day(s) scheduled in ${data.monthLabel}',
            style: const TextStyle(
              fontSize: 10.5,
              color: Colors.white54,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 14),

          // SUBJECT
          const Text(
            'SUBJECT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: subjectController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              hintText: 'e.g. Bazar instructions for ${data.monthLabel}',
              hintStyle: const TextStyle(color: Colors.white38),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // MESSAGE
          const Text(
            'MESSAGE *',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: messageController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              hintText:
                  'e.g. Hi all — bazar rota for ${data.monthLabel} is set. Today\'s bazar: … Please bring: chicken, oil, onions. — Manager',
              hintStyle: const TextStyle(color: Colors.white38),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                final msg = messageController.text.trim();
                if (msg.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter an announcement message'),
                    ),
                  );
                  return;
                }
                context.read<BazarScheduleCubit>().broadcastAnnouncement(
                  subject: subjectController.text.trim(),
                  message: msg,
                );
              },
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Send announcement to all members'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
