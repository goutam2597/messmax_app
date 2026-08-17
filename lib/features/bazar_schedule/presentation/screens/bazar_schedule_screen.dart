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
  void _showAssignBottomSheet(
    BuildContext context,
    BazarScheduleResponseModel data, {
    int? prefilledDay,
    int? prefilledMemberId,
    String? prefilledStaff,
    String? prefilledNote,
  }) {
    int fromDay = prefilledDay ?? 1;
    int toDay = prefilledDay ?? 1;
    int? selectedMemberId = prefilledMemberId;
    String staffName = prefilledStaff ?? '';
    String note = prefilledNote ?? '';
    bool isStaffMode = prefilledStaff != null && prefilledStaff.isNotEmpty;

    final staffController = TextEditingController(text: staffName);
    final noteController = TextEditingController(text: note);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                    Text(
                      prefilledDay != null
                          ? 'Assign Duty for Day $prefilledDay'
                          : 'Assign Shopping Duty',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select a mess member or enter outside staff name',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date Range Pickers
                    if (prefilledDay == null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'FROM DAY (1..${31})',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.inkSoft,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<int>(
                                  initialValue: fromDay,
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                  ),
                                  items: List.generate(
                                    data.daysInMonth,
                                    (i) => DropdownMenuItem(
                                      value: i + 1,
                                      child: Text('Day ${i + 1}'),
                                    ),
                                  ),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setSheetState(() {
                                        fromDay = val;
                                        if (toDay < fromDay) toDay = fromDay;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'TO DAY',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.inkSoft,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<int>(
                                  initialValue: toDay,
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                  ),
                                  items: List.generate(
                                    data.daysInMonth,
                                    (i) => DropdownMenuItem(
                                      value: i + 1,
                                      child: Text('Day ${i + 1}'),
                                    ),
                                  ),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setSheetState(() {
                                        toDay = val;
                                        if (fromDay > toDay) fromDay = toDay;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Assignee Type Toggle
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Mess Member'),
                          selected: !isStaffMode,
                          selectedColor: AppColors.brandDark,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: !isStaffMode
                                ? Colors.white
                                : AppColors.inkSoft,
                          ),
                          onSelected: (val) {
                            if (val) setSheetState(() => isStaffMode = false);
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Outside Staff / Maid'),
                          selected: isStaffMode,
                          selectedColor: AppColors.brandDark,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isStaffMode
                                ? Colors.white
                                : AppColors.inkSoft,
                          ),
                          onSelected: (val) {
                            if (val) setSheetState(() => isStaffMode = true);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (!isStaffMode) ...[
                      const Text(
                        'SELECT MESS MEMBER *',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        initialValue: selectedMemberId,
                        hint: const Text('Select a member'),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 14),
                        ),
                        items: data.members.map((m) {
                          final dayBadge = m.bazarDay != null
                              ? ' (${m.bazarDay})'
                              : '';
                          return DropdownMenuItem<int>(
                            value: m.id,
                            child: Text('${m.name}$dayBadge'),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setSheetState(() => selectedMemberId = val),
                      ),
                    ] else ...[
                      const Text(
                        'STAFF NAME *',
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
                          hintText: 'e.g. Bua / Karim Bhai',
                          prefixIcon: Icon(
                            Icons.badge_outlined,
                            size: 20,
                            color: AppColors.inkFaded,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),
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

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.read<BazarScheduleCubit>().assignSchedule(
                                fromDay: fromDay,
                                toDay: toDay,
                                messMemberId: isStaffMode
                                    ? null
                                    : selectedMemberId,
                                staffName: isStaffMode
                                    ? staffController.text.trim()
                                    : null,
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
                        child: const Text(
                          'Save Assignment',
                          style: TextStyle(
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

  void _showNotifyDialog(
    BuildContext context,
    BazarScheduleResponseModel data, {
    BazarDayItemModel? singleDay,
  }) {
    final notesController = TextEditingController();
    final emailController = TextEditingController(
      text: singleDay?.memberName != null
          ? data.members
              .firstWhere(
                (m) => m.id == singleDay?.messMemberId,
                orElse: () => const BazarMemberModel(id: 0, name: '', role: ''),
              )
              .email
          : '',
    );
    int selectedDay = singleDay?.day ?? 1;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                          'Send Email Notification',
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
                      'Sends an SMTP email with bazar duty schedule & notes to assignee',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (singleDay == null) ...[
                      const Text(
                        'SELECT DAY TO NOTIFY *',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        initialValue: selectedDay,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 14),
                        ),
                        items: data.schedules.map((s) {
                          final label = s.displayName != null
                              ? 'Day ${s.day}: ${s.displayName}'
                              : 'Day ${s.day}: Unassigned';
                          return DropdownMenuItem<int>(
                            value: s.day,
                            child: Text(label),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => selectedDay = val);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                    ],

                    const Text(
                      'RECIPIENT EMAIL (OVERRIDE)',
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
                        hintText: 'assignee@example.com',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          size: 20,
                          color: AppColors.inkFaded,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      'ADDITIONAL NOTES / SHOPPING LIST',
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
                            'e.g. Please buy 5kg Ruhi fish, onions, and oil',
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.read<BazarScheduleCubit>().notifyAssignee(
                                day: singleDay?.day ?? selectedDay,
                                notes: notesController.text.trim(),
                                emailOverride: emailController.text.trim(),
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
      },
    );
  }

  void _showBroadcastDialog(
    BuildContext context,
    BazarScheduleResponseModel data,
  ) {
    final subjectController = TextEditingController(
      text: 'Announcement — ${data.mess.name} · ${data.monthLabel} — MessMax',
    );
    final messageController = TextEditingController();

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
                      Icons.campaign_rounded,
                      color: AppColors.brandDark,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Broadcast Announcement',
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
                  'Sends an SMTP broadcast email to all ${data.members.length} members',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'EMAIL SUBJECT',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.title_rounded,
                      size: 20,
                      color: AppColors.inkFaded,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                const Text(
                  'ANNOUNCEMENT MESSAGE *',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText:
                        'Write important mess announcement for all members...',
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      final msg = messageController.text.trim();
                      if (msg.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please write an announcement message'),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      context.read<BazarScheduleCubit>().broadcastAnnouncement(
                            subject: subjectController.text.trim(),
                            message: msg,
                          );
                    },
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Send Broadcast to All Members'),
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
                  'Bazar Schedule',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  mess != null ? mess.name : 'Shopping Roster',
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
            onPressed: () =>
                context.read<BazarScheduleCubit>().loadSchedule(),
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

              return Column(
                children: [
                  // --- MONTH SELECTOR STRIP ---
                  _buildMonthSelectorStrip(context, data),

                  // --- METRICS & ACTION TOOLBAR ---
                  _buildActionToolbar(context, data),

                  // --- SCHEDULE LIST ---
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                      itemCount: data.schedules.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = data.schedules[index];
                        return _buildScheduleDayCard(context, data, item);
                      },
                    ),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildMonthSelectorStrip(
    BuildContext context,
    BazarScheduleResponseModel data,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.paperRaised,
        border: Border(bottom: BorderSide(color: AppColors.paperLine)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.ink,
              size: 26,
            ),
            onPressed: () =>
                context.read<BazarScheduleCubit>().changeMonth(-1),
          ),
          Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: AppColors.brandDark,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                data.monthLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.ink,
              size: 26,
            ),
            onPressed: () =>
                context.read<BazarScheduleCubit>().changeMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _buildActionToolbar(
    BuildContext context,
    BazarScheduleResponseModel data,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.paper,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4EA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                        color: Color(0xFF0F9F59),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Assigned: ${data.assignedCount} days',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F9F59),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.paperRaised,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.paperLine),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event_outlined,
                        size: 16,
                        color: AppColors.inkFaded,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Unassigned: ${data.unassignedCount} days',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (data.canManage) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilledButton.icon(
                    onPressed: () => _showAssignBottomSheet(context, data),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                    label: const Text('Assign Duty'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandDark,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showNotifyDialog(context, data),
                    icon: const Icon(Icons.mail_outline_rounded, size: 16),
                    label: const Text('Send Email'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showBroadcastDialog(context, data),
                    icon: const Icon(Icons.campaign_outlined, size: 16),
                    label: const Text('Announce'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          title: const Text('Clear Month Schedule?'),
                          content: Text(
                            'Are you sure you want to remove all bazar assignments for ${data.monthLabel}?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx),
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
                                'Clear All',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.delete_sweep_outlined,
                      color: AppColors.accentDark,
                      size: 20,
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

  Widget _buildScheduleDayCard(
    BuildContext context,
    BazarScheduleResponseModel data,
    BazarDayItemModel item,
  ) {
    final isToday = item.isToday;
    final isAssigned = item.isAssigned;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isToday
            ? const Color(0xFFE6F4EA)
            : (item.isPast ? AppColors.paper : AppColors.paperRaised),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday
              ? const Color(0xFF0F9F59).withValues(alpha: 0.5)
              : AppColors.paperLine,
          width: isToday ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isToday ? const Color(0xFF0F9F59) : AppColors.paper,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday
                      ? null
                      : Border.all(color: AppColors.paperLine),
                ),
                child: Text(
                  item.dateLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isToday ? Colors.white : AppColors.ink,
                  ),
                ),
              ),
              if (isToday) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F9F59),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'TODAY',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
              const Spacer(),

              if (data.canManage && isAssigned) ...[
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.mail_outline_rounded,
                    size: 18,
                    color: AppColors.brandDark,
                  ),
                  onPressed: () =>
                      _showNotifyDialog(context, data, singleDay: item),
                ),
                const SizedBox(width: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppColors.inkSoft,
                  ),
                  onPressed: () => _showAssignBottomSheet(
                    context,
                    data,
                    prefilledDay: item.day,
                    prefilledMemberId: item.messMemberId,
                    prefilledStaff: item.staffName,
                    prefilledNote: item.note,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: AppColors.inkFaded,
                  ),
                  onPressed: () {
                    if (item.id != null) {
                      context
                          .read<BazarScheduleCubit>()
                          .deleteAssignment(item.id!);
                    }
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          if (isAssigned) ...[
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(0xFF0F9F59)
                        : AppColors.brandDark,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      item.displayName != null && item.displayName!.isNotEmpty
                          ? item.displayName![0].toUpperCase()
                          : 'B',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
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
                            item.displayName ?? 'Assigned',
                            style: const TextStyle(
                              fontSize: 14,
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
                              color: item.staffName != null
                                  ? AppColors.paperLine
                                  : AppColors.brandSoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.staffName != null ? 'Staff' : 'Member',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: item.staffName != null
                                    ? AppColors.inkSoft
                                    : AppColors.brandDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (item.note != null && item.note!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            item.note!,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.inkFaded,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                const Text(
                  'No duty assigned for this day',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.inkFaded,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Spacer(),
                if (data.canManage)
                  TextButton.icon(
                    onPressed: () => _showAssignBottomSheet(
                      context,
                      data,
                      prefilledDay: item.day,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Assign'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
