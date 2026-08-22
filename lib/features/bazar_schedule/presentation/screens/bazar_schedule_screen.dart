import 'package:flutter/material.dart';
import '../../../../core/locale/app_translations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/bn_digits.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../data/models/bazar_schedule_model.dart';
import '../cubit/bazar_schedule_cubit.dart';
import '../cubit/bazar_schedule_state.dart';
import '../../../dashboard/presentation/widgets/dash_ui.dart';

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
                borderRadius: BorderRadius.circular(DashUI.rCard),
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
                                  prefilledSchedule != null
                                      ? 'ui.bazar_edit_title'.tr2
                                      : 'ui.bazar_assign_title'.tr2,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '${data.monthLabel} · ${'ui.bazar_single_day_range'.tr2}',
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
                                      Text(
                                        'ui.bazar_from_date'.tr2,
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
                                        borderRadius: BorderRadius.circular(DashUI.rTile),
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
                                      Text(
                                        'ui.bazar_to_date'.tr2,
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
                                        borderRadius: BorderRadius.circular(DashUI.rTile),
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
                            Text(
                              'ui.bazar_quick_presets'.tr2,
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
                                    label: Text('ui.bazar_today'.tr2),
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
                                          SnackBar(
                                            content: Text(
                                              'ui.bazar_current_not_in_month'
                                                  .tr2,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ActionChip(
                                    label: Text('ui.bazar_tomorrow'.tr2),
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
                                          SnackBar(
                                            content: Text(
                                              'ui.bazar_tomorrow_outside'.tr2,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ActionChip(
                                    label: Text('ui.bazar_next3'.tr2),
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
                                    label: Text('ui.bazar_week'.tr2),
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
                            Text(
                              'ui.bazar_select_member'.tr2,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.inkSoft,
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<int?>(
                              initialValue: selectedMemberId,
                              decoration: InputDecoration(
                                hintText: 'ui.bazar_member_hint'.tr2,
                                prefixIcon: Icon(
                                  Icons.person_rounded,
                                  size: 20,
                                  color: AppColors.inkFaded,
                                ),
                              ),
                              items: [
                                DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('ui.bazar_none_staff'.tr2),
                                ),
                                ...data.members.map((m) {
                                  final rLabel = m.role.toLowerCase() == 'owner'
                                      ? 'ui.role_owner'.tr2
                                      : (m.role.toLowerCase() == 'manager'
                                            ? 'ui.role_manager'.tr2
                                            : 'ui.role_member'.tr2);
                                  return DropdownMenuItem<int?>(
                                    value: m.id,
                                    child: Text('${m.name} ($rLabel)'),
                                  );
                                }),
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
                            Text(
                              'ui.bazar_staff_name_label'.tr2,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.inkSoft,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: staffController,
                              decoration: InputDecoration(
                                hintText: 'ui.bazar_staff_hint'.tr2,
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
                            Text(
                              'ui.bazar_note_label'.tr2,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.inkSoft,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: noteController,
                              decoration: InputDecoration(
                                hintText: 'ui.bazar_note_hint'.tr2,
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
                                      SnackBar(
                                        content: Text(
                                          'ui.bazar_select_from_date'.tr2,
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
                                      SnackBar(
                                        content: Text(
                                          'ui.bazar_select_member_or_staff'.tr2,
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
                                      ? 'ui.bazar_save_changes'.tr2
                                      : 'ui.bazar_add_assignment'.tr2,
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
                                    borderRadius: BorderRadius.circular(DashUI.rCard),
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

    // Filter members that have a non-empty email
    final membersWithEmail = data.members
        .where((m) => m.email != null && m.email!.trim().isNotEmpty)
        .toList();

    // Determine initial selected member ID
    int? selectedMemberId = item.messMemberId;
    if (selectedMemberId != null) {
      final exists = membersWithEmail.any((m) => m.id == selectedMemberId);
      if (!exists && membersWithEmail.isNotEmpty) {
        selectedMemberId = membersWithEmail.first.id;
      }
    } else if (membersWithEmail.isNotEmpty) {
      selectedMemberId = membersWithEmail.first.id;
    }

    bool isSendingNotify = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final selectedMember = membersWithEmail.firstWhere(
              (m) => m.id == selectedMemberId,
              orElse: () => const BazarMemberModel(id: 0, name: '', role: ''),
            );
            final targetEmail = selectedMember.email ?? '';

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
                              borderRadius: BorderRadius.circular(DashUI.rTile),
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
                                Text(
                                  'ui.bazar_notify_title'.tr2,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  selectedMember.name,
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
                    ),
                    const Divider(height: 1, color: AppColors.paperLine),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ui.bazar_recipient_email'.tr2,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.inkSoft,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (membersWithEmail.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.paper,
                                  borderRadius: BorderRadius.circular(DashUI.rTile),
                                  border: Border.all(
                                    color: AppColors.paperLine,
                                  ),
                                ),
                                child: Text(
                                  'ui.bazar_no_members_with_email'.tr2,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.inkFaded,
                                  ),
                                ),
                              )
                            else
                              DropdownButtonFormField<int>(
                                initialValue: selectedMemberId,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    size: 20,
                                    color: AppColors.inkFaded,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                items: membersWithEmail.map((m) {
                                  return DropdownMenuItem<int>(
                                    value: m.id,
                                    child: Text(
                                      '${m.name} (${m.email})',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setSheetState(() {
                                      selectedMemberId = val;
                                    });
                                  }
                                },
                              ),
                            const SizedBox(height: 14),

                            Text(
                              'ui.bazar_additional_notes'.tr2,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.inkSoft,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: notesController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'ui.bazar_notify_note_hint'.tr2,
                              ),
                            ),
                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed:
                                    (isSendingNotify || targetEmail.isEmpty)
                                    ? null
                                    : () async {
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
                                                emailOverride: targetEmail,
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
                                      ? 'ui.bazar_sending'.tr2
                                      : 'ui.bazar_send_smtp'.tr2,
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
                                    borderRadius: BorderRadius.circular(DashUI.rCard),
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
          leading: AppBackButton(onPressed: _backToDashboard),
          title: BlocBuilder<BazarScheduleCubit, BazarScheduleState>(
            builder: (context, state) {
              final mess = state is BazarScheduleLoaded
                  ? state.schedule.mess
                  : null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ui.bazar_schedule_title'.tr2,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    mess != null ? mess.name : 'ui.bazar_shopping_rota'.tr2,
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
          child: BlocConsumer<BazarScheduleCubit, BazarScheduleState>(
            listener: (context, state) {
              if (state is BazarScheduleLoaded &&
                  state.successMessage != null) {
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
                return AppErrorView(
                  code: state.code,
                  title: 'ui.bazar_load_error'.tr2,
                  retryLabel: 'ui.try_again'.tr2,
                  onRetry: () => context
                      .read<BazarScheduleCubit>()
                      .loadSchedule(forceRefresh: true),
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
                          '${'ui.bazar_rota_header'.tr2} (${bnDigits(data.assignedCount)}/${bnDigits(data.daysInMonth)} ${'ui.bazar_days_assigned'.tr2})',
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
                        if (data.canManage)
                          _buildAnnouncementCard(context, data),
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
            borderRadius: BorderRadius.circular(DashUI.rBtn),
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
        borderRadius: BorderRadius.circular(DashUI.rCard),
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
                      '${'ui.bazar_rota_subtitle'.tr2} • ${data.mess.code}',
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
                  borderRadius: BorderRadius.circular(DashUI.rCard),
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
              borderRadius: BorderRadius.circular(DashUI.rCard),
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
                      '${bnDigits(data.assignedCount)} ${'ui.bazar_days_assigned'.tr2}',
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
                      '${bnDigits(data.unassignedCount)} ${'ui.bazar_days_open'.tr2}',
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
            label: Text('ui.bazar_assign_duty'.tr2),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandDark,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DashUI.rTile),
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
            label: Text('ui.bazar_send_email'.tr2),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DashUI.rTile),
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => _showBroadcastModal(context, data),
            icon: const Icon(Icons.campaign_outlined, size: 16),
            label: Text('ui.bazar_announce'.tr2),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DashUI.rTile),
              ),
            ),
          ),
          if (assignedRows.isNotEmpty) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () async {
                final confirm = await ConfirmDeleteDialog.show(
                  context,
                  title: 'ui.confirm_clear_month_title'.tr2,
                  itemName: data.monthLabel,
                  message: 'ui.confirm_clear_month_message'.tr2.replaceAll(
                    '{month}',
                    data.monthLabel,
                  ),
                  confirmLabel: 'ui.confirm_clear_month_label'.tr2,
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
        borderRadius: BorderRadius.circular(DashUI.rCard),
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
              borderRadius: BorderRadius.circular(DashUI.rCard),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: AppColors.brandDark,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${'ui.bazar_no_assignments'.tr2} ${data.monthLabel}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ui.bazar_no_assignments_sub'.tr2,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: AppColors.inkFaded),
          ),
          if (data.canManage) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _showAddEditModal(context, data),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('ui.bazar_assign_first'.tr2),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandDark,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DashUI.rTile),
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
        borderRadius: BorderRadius.circular(DashUI.rCard),
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
                  borderRadius: BorderRadius.circular(DashUI.rBtn),
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
                  child: Text(
                    'ui.bazar_today_badge'.tr2,
                    style: const TextStyle(
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
                            title: 'ui.confirm_remove_bazar_title'.tr2,
                            itemName:
                                member?.name ?? item.memberName ?? 'Member',
                            message: 'ui.confirm_remove_bazar_message'.tr2
                                .replaceAll('{day}', item.day.toString()),
                            confirmLabel: 'ui.bazar_remove_duty'.tr2,
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
                            item.displayName ?? 'ui.bazar_staff'.tr2,
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
              borderRadius: BorderRadius.circular(DashUI.rTile),
              border: Border.all(color: AppColors.paperLine),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.sticky_note_2_outlined,
                      size: 14,
                      color: AppColors.brandDark,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ui.bazar_notes_instructions'.tr2,
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
                      : 'ui.bazar_no_instructions'.tr2,
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
                borderRadius: BorderRadius.circular(DashUI.rCard),
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
                              borderRadius: BorderRadius.circular(DashUI.rTile),
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
                                Text(
                                  'ui.bazar_broadcast_title'.tr2,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '${'ui.bazar_broadcast_sub'.tr2} ${bnDigits(data.members.length)} ${'ui.members_total'.tr2}',
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
                    ),
                    const Divider(height: 1, color: AppColors.paperLine),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ui.bazar_email_subject'.tr2,
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

                            Text(
                              'ui.bazar_announcement_msg'.tr2,
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
                              decoration: InputDecoration(
                                hintText: 'ui.bazar_announcement_hint'.tr2,
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
                                            SnackBar(
                                              content: Text(
                                                'ui.bazar_announcement_empty'
                                                    .tr2,
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
                                      ? 'ui.bazar_broadcasting'.tr2
                                      : 'ui.bazar_send_broadcast'.tr2,
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
                                    borderRadius: BorderRadius.circular(DashUI.rCard),
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
        borderRadius: BorderRadius.circular(DashUI.rCard),
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
          Row(
            children: [
              const Icon(
                Icons.campaign_outlined,
                color: Color(0xFFFFD1A3),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'ui.bazar_announce_all'.tr2,
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
            '${'ui.bazar_announce_desc'.tr2} ${data.mess.name} — ${'ui.bazar_announce_desc2'.tr2}',
            style: const TextStyle(fontSize: 11.5, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            '${bnDigits(data.members.length)} ${'ui.members_total'.tr2} · ${bnDigits(data.members.where((m) => m.email != null && m.email!.isNotEmpty).length)} ${'ui.bazar_with_email'.tr2} · ${bnDigits(data.assignedCount)} ${'ui.bazar_days_scheduled'.tr2} ${data.monthLabel}',
            style: const TextStyle(
              fontSize: 10.5,
              color: Colors.white54,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 14),

          // SUBJECT
          Text(
            'ui.bazar_email_subject'.tr2,
            style: const TextStyle(
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
              hintText: '${'ui.bazar_subject_hint'.tr2} ${data.monthLabel}',
              hintStyle: const TextStyle(color: Colors.white38),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DashUI.rBtn),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DashUI.rBtn),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // MESSAGE
          Text(
            'ui.bazar_announcement_msg'.tr2,
            style: const TextStyle(
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
                borderRadius: BorderRadius.circular(DashUI.rBtn),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DashUI.rBtn),
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
                          SnackBar(
                            content: Text('ui.bazar_announcement_empty'.tr2),
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
                  borderRadius: BorderRadius.circular(DashUI.rBtn),
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
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, size: 16),
                        const SizedBox(width: 8),
                        Text('ui.bazar_send_broadcast'.tr2),
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
