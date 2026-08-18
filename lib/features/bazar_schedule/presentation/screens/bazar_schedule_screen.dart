import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
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
  bool _isSendingAnnouncement = false;
  final _announcementSubjectController = TextEditingController();
  final _announcementMessageController = TextEditingController();

  @override
  void dispose() {
    _announcementSubjectController.dispose();
    _announcementMessageController.dispose();
    super.dispose();
  }

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

    showDialog(
      context: context,
      barrierDismissible: true,
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
                constraints: BoxConstraints(
                  maxWidth: 480,
                  maxHeight: MediaQuery.of(context).size.height * 0.88,
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
                              children: [
                                Text(
                                  prefilledSchedule != null
                                      ? 'Edit Duty Assignment'
                                      : 'Assign Bazar Duty',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '${data.monthLabel} · Single day or date range',
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
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- CALENDAR DATE PICKERS ---
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            initialDate:
                                                selectedFromDate ?? firstDate,
                                            firstDate: firstDate,
                                            lastDate: lastDate,
                                          );
                                          if (picked != null) {
                                            setSheetState(() {
                                              selectedFromDate = picked;
                                              if (selectedToDate != null &&
                                                  selectedToDate!.isBefore(
                                                    picked,
                                                  )) {
                                                selectedToDate = null;
                                              }
                                            });
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 11,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.paper,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: selectedFromDate != null
                                                  ? AppColors.brandDark
                                                  : AppColors.paperLine,
                                              width: selectedFromDate != null
                                                  ? 1.5
                                                  : 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.event_rounded,
                                                size: 16,
                                                color: AppColors.brandDark,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  formatDateLabel(
                                                    selectedFromDate,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        selectedFromDate != null
                                                        ? AppColors.ink
                                                        : AppColors.inkFaded,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          final initial =
                                              selectedToDate ??
                                              selectedFromDate ??
                                              firstDate;
                                          final fDate =
                                              selectedFromDate ?? firstDate;
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: initial.isBefore(fDate)
                                                ? fDate
                                                : initial,
                                            firstDate: fDate,
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
                                            vertical: 11,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.paper,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: selectedToDate != null
                                                  ? AppColors.brandDark
                                                  : AppColors.paperLine,
                                              width: selectedToDate != null
                                                  ? 1.5
                                                  : 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.date_range_rounded,
                                                size: 16,
                                                color: AppColors.inkFaded,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  formatDateLabel(
                                                    selectedToDate,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        selectedToDate != null
                                                        ? AppColors.ink
                                                        : AppColors.inkFaded,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (selectedToDate != null)
                                                GestureDetector(
                                                  onTap: () => setSheetState(
                                                    () => selectedToDate = null,
                                                  ),
                                                  child: const Icon(
                                                    Icons.close_rounded,
                                                    size: 16,
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

                            // --- QUICK PRESETS CHIPS ---
                            const Text(
                              'QUICK PRESETS',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.inkSoft,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ActionChip(
                                    label: const Text('Today'),
                                    avatar: const Icon(
                                      Icons.today_rounded,
                                      size: 14,
                                    ),
                                    onPressed: () {
                                      final now = DateTime.now();
                                      if (now.month == data.month &&
                                          now.year == data.year) {
                                        setSheetState(() {
                                          selectedFromDate = DateTime(
                                            data.year,
                                            data.month,
                                            now.day,
                                          );
                                          selectedToDate = null;
                                        });
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Current day is not in this month schedule',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ActionChip(
                                    label: const Text('Tomorrow'),
                                    avatar: const Icon(
                                      Icons.fast_forward_rounded,
                                      size: 14,
                                    ),
                                    onPressed: () {
                                      final tomorrow = DateTime.now().add(
                                        const Duration(days: 1),
                                      );
                                      if (tomorrow.month == data.month &&
                                          tomorrow.year == data.year) {
                                        setSheetState(() {
                                          selectedFromDate = DateTime(
                                            data.year,
                                            data.month,
                                            tomorrow.day,
                                          );
                                          selectedToDate = null;
                                        });
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Tomorrow is outside this schedule month',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ActionChip(
                                    label: const Text('Next 3 Days'),
                                    avatar: const Icon(
                                      Icons.date_range_rounded,
                                      size: 14,
                                    ),
                                    onPressed: () {
                                      final base =
                                          selectedFromDate ??
                                          (DateTime.now().month == data.month
                                              ? DateTime(
                                                  data.year,
                                                  data.month,
                                                  DateTime.now().day,
                                                )
                                              : firstDate);
                                      final toDayNum = (base.day + 2).clamp(
                                        1,
                                        data.daysInMonth,
                                      );
                                      setSheetState(() {
                                        selectedFromDate = base;
                                        selectedToDate = DateTime(
                                          data.year,
                                          data.month,
                                          toDayNum,
                                        );
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ActionChip(
                                    label: const Text('Whole Week (7d)'),
                                    avatar: const Icon(
                                      Icons.view_week_rounded,
                                      size: 14,
                                    ),
                                    onPressed: () {
                                      final base =
                                          selectedFromDate ??
                                          (DateTime.now().month == data.month
                                              ? DateTime(
                                                  data.year,
                                                  data.month,
                                                  DateTime.now().day,
                                                )
                                              : firstDate);
                                      final toDayNum = (base.day + 6).clamp(
                                        1,
                                        data.daysInMonth,
                                      );
                                      setSheetState(() {
                                        selectedFromDate = base;
                                        selectedToDate = DateTime(
                                          data.year,
                                          data.month,
                                          toDayNum,
                                        );
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // --- ASSIGNEE (MEMBER / STAFF) ---
                            const Text(
                              'SELECT MESS MEMBER',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.inkSoft,
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<int?>(
                              initialValue: selectedMemberId,
                              decoration: const InputDecoration(
                                hintText: 'Choose mess member...',
                                prefixIcon: Icon(
                                  Icons.person_rounded,
                                  size: 20,
                                  color: AppColors.inkFaded,
                                ),
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text(
                                    '— None (Use Staff Name Below) —',
                                  ),
                                ),
                                ...data.members.map(
                                  (m) => DropdownMenuItem<int?>(
                                    value: m.id,
                                    child: Text('${m.name} (${m.role})'),
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                setSheetState(() {
                                  selectedMemberId = val;
                                  if (val != null) {
                                    staffController.clear();
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 12),

                            // --- OR STAFF NAME ---
                            const Text(
                              'OR CUSTOM STAFF / BUYER NAME',
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
                                hintText: 'e.g. Bua, Cook Abdul, Manager',
                                prefixIcon: Icon(
                                  Icons.badge_rounded,
                                  size: 20,
                                  color: AppColors.inkFaded,
                                ),
                              ),
                              onChanged: (text) {
                                if (text.isNotEmpty &&
                                    selectedMemberId != null) {
                                  setSheetState(() => selectedMemberId = null);
                                }
                              },
                            ),
                            const SizedBox(height: 14),

                            // --- NOTE / INSTRUCTIONS ---
                            const Text(
                              'DUTY NOTE / SHOPPING LIST (OPTIONAL)',
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
                            const SizedBox(height: 20),

                            // SUBMIT BUTTON
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () {
                                  if (selectedFromDate == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please select From Date',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  final fromDay = selectedFromDate!.day;
                                  final toDay = selectedToDate?.day;
                                  final staff = staffController.text.trim();

                                  if (selectedMemberId == null &&
                                      staff.isEmpty) {
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
                                  context
                                      .read<BazarScheduleCubit>()
                                      .assignSchedule(
                                        fromDay: fromDay,
                                        toDay: toDay,
                                        messMemberId: selectedMemberId,
                                        staffName: staff,
                                        note: noteController.text.trim(),
                                      );
                                },
                                icon: Icon(
                                  prefilledSchedule != null
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.add_task_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  prefilledSchedule != null
                                      ? 'Save Changes'
                                      : 'Add Assignment',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
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
    bool isSendingNotify = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                constraints: BoxConstraints(
                  maxWidth: 480,
                  maxHeight: MediaQuery.of(context).size.height * 0.88,
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.mark_email_read_rounded,
                              color: AppColors.brandDark,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Notify Assignee via Email',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '${item.dateLabel} (${item.displayName})',
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
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: isSendingNotify
                                    ? null
                                    : () async {
                                        final email = emailController.text
                                            .trim();
                                        if (email.isEmpty ||
                                            !email.contains('@')) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Please enter a valid email address',
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        setSheetState(
                                          () => isSendingNotify = true,
                                        );
                                        try {
                                          await context
                                              .read<BazarScheduleCubit>()
                                              .notifyAssignee(
                                                day: item.day,
                                                notes: notesController.text
                                                    .trim(),
                                                emailOverride: email,
                                              );
                                          if (context.mounted) {
                                            Navigator.pop(ctx);
                                          }
                                        } finally {}
                                      },
                                icon: isSendingNotify
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.send_rounded, size: 18),
                                label: Text(
                                  isSendingNotify
                                      ? 'Sending...'
                                      : 'Send SMTP Notification',
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

  void _backToDashboard() {
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
        _backToDashboard();
      },
      child: Scaffold(
        backgroundColor: AppColors.paper,
        appBar: AppBar(
          backgroundColor: AppColors.paperRaised,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          leading: AppBackButton(
            onPressed: _backToDashboard,
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
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context
                      .read<BazarScheduleCubit>()
                      .loadSchedule(forceRefresh: true),
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
        child: BlocConsumer<BazarScheduleCubit, BazarScheduleState>(
          listener: (context, state) {
            if (state is BazarScheduleLoaded && state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: AppColors.brandDark,
                ),
              );
            } else if (state is BazarScheduleError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.danger,
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
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: AppColors.accentSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          size: 36,
                          color: AppColors.accentDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () => context
                            .read<BazarScheduleCubit>()
                            .loadSchedule(forceRefresh: true),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Try Again'),
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

              return RefreshIndicator(
                color: AppColors.brandDark,
                onRefresh: () => context
                    .read<BazarScheduleCubit>()
                    .loadSchedule(forceRefresh: true),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- 1. HERO MONTH HEADER & STATS CARD ---
                      _buildHeroMonthCard(context, data),
                      const SizedBox(height: 20),

                      // --- 2. MANAGER ACTIONS TOOLBAR ---
                      _buildSectionHeader(
                        Icons.list_alt_rounded,
                        'SHOPPING ROTA (${data.assignedCount}/${data.daysInMonth} DAYS ASSIGNED)',
                      ),
                    const SizedBox(height: 10),
                    if (data.canManage)
                      _buildManagerToolbar(context, data, assignedRows),
                    const SizedBox(height: 14),

                    // --- 3. ASSIGNED ROTA DAY CARDS OR ELEGANT EMPTY STATE ---
                    if (assignedRows.isEmpty)
                      _buildEmptyRotaCard(context, data)
                    else
                      Column(
                        children: [
                          for (int i = 0; i < assignedRows.length; i++) ...[
                            if (i > 0) const SizedBox(height: 12),
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

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: AppColors.brandDark),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: AppColors.inkFaded,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }

  // --- 1. HERO MONTH HEADER CARD ---
  Widget _buildHeroMonthCard(
    BuildContext context,
    BazarScheduleResponseModel data,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandDark, AppColors.brandDeep],
        ),
        borderRadius: BorderRadius.circular(22),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.mess.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rota schedule • ${data.mess.code}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Month Navigation Pill Controls
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () =>
                          context.read<BazarScheduleCubit>().changeMonth(-1),
                    ),
                    Text(
                      data.monthLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () =>
                          context.read<BazarScheduleCubit>().changeMonth(1),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Glassmorphism Metrics Summary Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: Color(0xFF0F9F59),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${data.assignedCount} Days Assigned',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 14,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.event_outlined,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${data.unassignedCount} Days Open',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. MANAGER TOOLBAR ACTIONS ---
  Widget _buildManagerToolbar(
    BuildContext context,
    BazarScheduleResponseModel data,
    List<BazarDayItemModel> assignedRows,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilledButton.icon(
            onPressed: () => _showAddEditModal(context, data),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Assign Duty'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandDark,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => _showNotifyModal(
              context,
              data,
              assignedRows.isNotEmpty
                  ? assignedRows.first
                  : const BazarDayItemModel(
                      day: 1,
                      dateLabel: '',
                      isToday: false,
                      isPast: false,
                    ),
            ),
            icon: const Icon(Icons.mail_outline_rounded, size: 16),
            label: const Text('Send Email'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => _showBroadcastModal(context, data),
            icon: const Icon(Icons.campaign_outlined, size: 16),
            label: const Text('Announce'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (assignedRows.isNotEmpty) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () async {
                final confirm = await ConfirmDeleteDialog.show(
                  context,
                  title: 'Clear Entire Month?',
                  itemName: data.monthLabel,
                  message:
                      'Are you sure you want to remove all bazar duties and assignments for ${data.monthLabel}? This cannot be undone.',
                  confirmLabel: 'Clear Month',
                  icon: Icons.delete_sweep_outlined,
                );
                if (confirm == true && context.mounted) {
                  context.read<BazarScheduleCubit>().clearMonth();
                }
              },
              icon: const Icon(
                Icons.delete_sweep_outlined,
                color: AppColors.accentDark,
                size: 22,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- 3. EMPTY ROTA CARD ---
  Widget _buildEmptyRotaCard(
    BuildContext context,
    BazarScheduleResponseModel data,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.paperLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: AppColors.brandDark,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No Assignments Yet for ${data.monthLabel}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add one date or date range at a time using the calendar picker above.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: AppColors.inkFaded),
          ),
          if (data.canManage) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _showAddEditModal(context, data),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Assign First Duty'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandDark,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- 4. ASSIGNED DAY CARD MATCHING WEB ---
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: item.isToday ? const Color(0xFF0F9F59) : AppColors.paperLine,
          width: item.isToday ? 2 : 1,
        ),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: item.isToday
                      ? const Color(0xFF0F9F59)
                      : AppColors.brandDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.dateLabel,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              if (item.isToday) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F9F59).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'TODAY',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F9F59),
                    ),
                  ),
                ),
              ],
              const Spacer(),

              // Actions
              if (data.canManage)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (member != null) ...[
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.mail_outline_rounded,
                          size: 20,
                          color: AppColors.brandDark,
                        ),
                        onPressed: () => _showNotifyModal(context, data, item),
                      ),
                    ],
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: AppColors.inkSoft,
                      ),
                      onPressed: () => _showAddEditModal(
                        context,
                        data,
                        prefilledSchedule: item,
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: AppColors.inkFaded,
                      ),
                      onPressed: () async {
                        if (item.id != null) {
                          final confirm = await ConfirmDeleteDialog.show(
                            context,
                            title: 'Remove Bazar Duty?',
                            itemName:
                                member?.name ?? item.memberName ?? 'Member',
                            message:
                                'Are you sure you want to remove this assigned duty on day ${item.day}?',
                            confirmLabel: 'Remove Duty',
                            icon: Icons.assignment_late_outlined,
                          );
                          if (confirm == true && context.mounted) {
                            context.read<BazarScheduleCubit>().deleteAssignment(
                              item.id!,
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              ClipOval(
                child: member != null && member.avatarUrl != null
                    ? Image.network(
                        member.avatarUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _memberCircleAvatarFallback(item, member),
                      )
                    : _memberCircleAvatarFallback(item, member),
              ),
              const SizedBox(width: 12),
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
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
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
                            color: member != null
                                ? AppColors.brandSoft
                                : AppColors.paperLine,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            member != null ? member.role : 'staff',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: member != null
                                  ? AppColors.brandDark
                                  : AppColors.inkSoft,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (mail.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        mail,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.inkFaded,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Notes / Instructions block
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.paperLine),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.sticky_note_2_outlined,
                      size: 14,
                      color: AppColors.brandDark,
                    ),
                    SizedBox(width: 6),
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
                    fontSize: 12,
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

  void _showBroadcastModal(
    BuildContext context,
    BazarScheduleResponseModel data,
  ) {
    final subjectController = TextEditingController(
      text: 'Announcement — ${data.mess.name} · ${data.monthLabel} — MessMax',
    );
    final messageController = TextEditingController();
    bool isSendingBroadcast = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                constraints: BoxConstraints(
                  maxWidth: 480,
                  maxHeight: MediaQuery.of(context).size.height * 0.88,
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.campaign_rounded,
                              color: AppColors.brandDark,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Broadcast Announcement',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'SMTP broadcast to all ${data.members.length} members',
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
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: isSendingBroadcast
                                    ? null
                                    : () async {
                                        final msg = messageController.text
                                            .trim();
                                        if (msg.isEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Please write an announcement message',
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        setSheetState(
                                          () => isSendingBroadcast = true,
                                        );
                                        try {
                                          await context
                                              .read<BazarScheduleCubit>()
                                              .broadcastAnnouncement(
                                                subject: subjectController.text
                                                    .trim(),
                                                message: msg,
                                              );
                                          if (context.mounted) {
                                            Navigator.pop(ctx);
                                          }
                                        } finally {}
                                      },
                                icon: isSendingBroadcast
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.campaign_rounded,
                                        size: 18,
                                      ),
                                label: Text(
                                  isSendingBroadcast
                                      ? 'Broadcasting...'
                                      : 'Send Broadcast to All Members',
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

  // --- 5. ANNOUNCEMENT BROADCAST CARD MATCHING WEB ---
  Widget _buildAnnouncementCard(
    BuildContext context,
    BazarScheduleResponseModel data,
  ) {
    if (_announcementSubjectController.text.isEmpty) {
      _announcementSubjectController.text =
          'Announcement — ${data.mess.name} · ${data.monthLabel} — MessMax';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandDark, AppColors.brandDeep],
        ),
        borderRadius: BorderRadius.circular(22),
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
            controller: _announcementSubjectController,
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
            controller: _announcementMessageController,
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
            child: FilledButton(
              onPressed: _isSendingAnnouncement
                  ? null
                  : () async {
                      final msg = _announcementMessageController.text.trim();
                      if (msg.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter an announcement message',
                            ),
                          ),
                        );
                        return;
                      }
                      setState(() => _isSendingAnnouncement = true);
                      try {
                        await context
                            .read<BazarScheduleCubit>()
                            .broadcastAnnouncement(
                              subject: _announcementSubjectController.text
                                  .trim(),
                              message: msg,
                            );
                        _announcementMessageController.clear();
                      } finally {
                        if (mounted) {
                          setState(() => _isSendingAnnouncement = false);
                        }
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSendingAnnouncement
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, size: 16),
                        SizedBox(width: 8),
                        Text('Send announcement to all members'),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _memberCircleAvatarFallback(
    BazarDayItemModel item,
    BazarMemberModel? member,
  ) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: item.isToday ? const Color(0xFF0F9F59) : AppColors.brandDark,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        item.displayName != null && item.displayName!.isNotEmpty
            ? item.displayName![0].toUpperCase()
            : 'S',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
    );
  }
}
