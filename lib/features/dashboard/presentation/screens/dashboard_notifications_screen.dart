import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/locale/app_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/bn_digits.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../widgets/dash_ui.dart';
import '../cubit/notification_cubit.dart';
import '../cubit/notification_state.dart';
import '../../data/models/app_notification_model.dart';

enum DashboardActivityType {
  mealOff,
  deposit,
  bazarDuty,
  memberJoin,
  monthClose,
  system,
}

enum ActivityStatus {
  pending,
  approved,
  declined,
  info,
}

class DashboardActivityItem {
  final String id;
  final int? notificationId;
  final String title;
  final String description;
  final String timeAgo;
  final String memberName;
  final String memberPhone;
  final String memberRoom;
  final DashboardActivityType type;
  final String? highlightValue;
  final Map<String, String>? details;
  final String tag;
  ActivityStatus status;
  String? resolvedAt;
  bool isRead;

  DashboardActivityItem({
    required this.id,
    this.notificationId,
    required this.title,
    required this.description,
    required this.timeAgo,
    required this.memberName,
    required this.memberPhone,
    required this.memberRoom,
    required this.type,
    this.highlightValue,
    this.details,
    required this.tag,
    this.status = ActivityStatus.pending,
    this.resolvedAt,
    this.isRead = false,
  });

  String get displayTag {
    switch (tag) {
      case 'Meal ON': return 'ui.dash_notif_tag_meal_on'.tr2;
      case 'Meal OFF': return 'ui.dash_notif_tag_meal_off'.tr2;
      case 'Guest Meal': return 'ui.dash_notif_tag_guest_meal'.tr2;
      case 'Deposit': return 'ui.dash_notif_tag_deposit'.tr2;
      case 'Bazar Expense': return 'ui.dash_notif_tag_bazar_expense'.tr2;
      case 'Bazar Duty': return 'ui.dash_notif_tag_bazar_duty'.tr2;
      case 'Join Request': return 'ui.dash_notif_tag_join_req'.tr2;
      case 'New Member': return 'ui.dash_notif_tag_new_member'.tr2;
      case 'Join Result': return 'ui.dash_notif_tag_join_res'.tr2;
      case 'Manager': return 'ui.dash_notif_tag_manager'.tr2;
      case 'Announcement': return 'ui.dash_notif_tag_announcement'.tr2;
      case 'Notice': return 'ui.dash_notif_tag_notice'.tr2;
      default: return tag;
    }
  }

  static String getLocalizedDetailKey(String key) {
    switch (key) {
      case 'Day': return 'ui.dash_notif_lbl_day'.tr2;
      case 'Meal Slot': return 'ui.dash_notif_lbl_meal_slot'.tr2;
      case 'Requester': return 'ui.dash_notif_lbl_requester'.tr2;
      case 'Guest': return 'ui.dash_notif_lbl_guest'.tr2;
      case 'Amount': return 'ui.dash_notif_lbl_amount'.tr2;
      case 'TrxID': return 'ui.dash_notif_lbl_trxid'.tr2;
      case 'Gateway': return 'ui.dash_notif_lbl_gateway'.tr2;
      case 'Budget': return 'ui.dash_notif_lbl_budget'.tr2;
      case 'Notes': return 'ui.dash_notif_lbl_notes'.tr2;
      case 'Applicant': return 'ui.dash_notif_lbl_applicant'.tr2;
      case 'Action': return 'ui.dash_notif_lbl_action'.tr2;
      default: return key;
    }
  }

  String get displayHighlightValue {
    if (highlightValue == null) return '';
    if (highlightValue == 'Turn ON') return 'ui.dash_notif_tag_turn_on'.tr2;
    if (highlightValue == 'Turn OFF') return 'ui.dash_notif_tag_turn_off'.tr2;
    if (highlightValue == 'Deposit') return 'ui.dash_notif_tag_deposit'.tr2;
    if (highlightValue == 'Applicant') return 'ui.dash_notif_tag_applicant'.tr2;
    return highlightValue!;
  }

  factory DashboardActivityItem.fromModel(AppNotificationModel model) {
    DashboardActivityType type = DashboardActivityType.system;
    String tag = 'Notice';
    String? highlightValue;
    Map<String, String> details = {};

    final data = model.data;
    final statusStr = data['status']?.toString().toLowerCase() ?? '';
    ActivityStatus status = ActivityStatus.info;

    if (model.type == 'meal_off') {
      type = DashboardActivityType.mealOff;
      final isReenable = data['is_reenable'] == '1' ||
          data['is_reenable'] == 1 ||
          data['is_reenable'] == true ||
          model.title.toLowerCase().contains('re-enable') ||
          model.title.toLowerCase().contains('meal on');
      tag = isReenable ? 'Meal ON' : 'Meal OFF';
      highlightValue = data['slots']?.toString() ?? (isReenable ? 'Turn ON' : 'Turn OFF');
      status = statusStr == 'approved'
          ? ActivityStatus.approved
          : statusStr == 'denied'
              ? ActivityStatus.declined
              : ActivityStatus.pending;
      if (data['day'] != null) details['Day'] = 'Day ${data['day']}';
      if (data['slots'] != null) details['Meal Slot'] = data['slots'].toString();
      if (data['member_name'] != null) details['Requester'] = data['member_name'].toString();
    } else if (model.type == 'guest_meal') {
      type = DashboardActivityType.mealOff;
      tag = 'Guest Meal';
      highlightValue = '${data['guest_count'] ?? 1} Guests';
      status = statusStr == 'approved'
          ? ActivityStatus.approved
          : statusStr == 'denied'
              ? ActivityStatus.declined
              : ActivityStatus.pending;
      if (data['day'] != null) details['Day'] = 'Day ${data['day']}';
      if (data['guest_name'] != null) details['Guest'] = data['guest_name'].toString();
      if (data['member_name'] != null) details['Requester'] = data['member_name'].toString();
    } else if (model.type == 'deposit') {
      type = DashboardActivityType.deposit;
      tag = 'Deposit';
      highlightValue = data['amount'] != null ? 'à§³${data['amount']}' : 'Deposit';
      status = statusStr == 'approved'
          ? ActivityStatus.approved
          : ActivityStatus.pending;
      if (data['amount'] != null) details['Amount'] = 'à§³${data['amount']}';
      if (data['trx_id'] != null) details['TrxID'] = data['trx_id'].toString();
      if (data['gateway'] != null) details['Gateway'] = data['gateway'].toString();
    } else if (model.type == 'bazar' || model.type == 'bazar_duty' || model.type == 'bazar_expense') {
      type = DashboardActivityType.bazarDuty;
      final isExpense = model.title.toLowerCase().contains('expense') ||
          model.type == 'bazar';
      tag = isExpense ? 'Bazar Expense' : 'Bazar Duty';
      highlightValue = data['amount'] != null
          ? 'à§³${data['amount']}'
          : (data['days']?.toString() ?? (data['date']?.toString() ?? 'Bazar'));
      status = ActivityStatus.info;
      if (data['day'] != null) details['Day'] = 'Day ${data['day']}';
      if (data['amount'] != null) details['Amount'] = 'à§³${data['amount']}';
      if (data['budget'] != null && data['budget'].toString().isNotEmpty) {
        details['Budget'] = 'à§³${data['budget']}';
      }
      if (data['notes'] != null && data['notes'].toString().isNotEmpty) {
        details['Notes'] = data['notes'].toString();
      }
    } else if (model.type == 'member_join' || model.type == 'join_request') {
      type = DashboardActivityType.memberJoin;
      tag = model.type == 'join_request' ? 'Join Request' : 'New Member';
      highlightValue = data['user_name']?.toString() ?? (data['role'] != null ? data['role'].toString().toUpperCase() : 'Applicant');
      status = statusStr == 'approved' ? ActivityStatus.approved : (statusStr == 'rejected' || statusStr == 'denied' ? ActivityStatus.declined : ActivityStatus.pending);
      if (data['user_name'] != null) details['Applicant'] = data['user_name'].toString();
      if (data['action'] != null) details['Action'] = data['action'].toString();
    } else if (model.type == 'join_decision') {
      type = DashboardActivityType.memberJoin;
      tag = 'Join Result';
      status = ActivityStatus.info;
    } else if (model.type == 'announcement') {
      type = DashboardActivityType.monthClose;
      tag = model.title.toLowerCase().contains('manager') ? 'Manager' : 'Announcement';
      status = ActivityStatus.info;
    }

    final memberName = data['member_name']?.toString() ??
        (model.messName != null ? model.messName! : 'MessMax');

    return DashboardActivityItem(
      id: model.id.toString(),
      notificationId: model.id,
      title: model.title,
      description: model.body,
      timeAgo: model.timeAgo,
      memberName: memberName,
      memberPhone: data['phone']?.toString() ?? '',
      memberRoom: data['room']?.toString() ?? (model.messName ?? 'Mess'),
      type: type,
      highlightValue: highlightValue,
      details: details.isNotEmpty ? details : null,
      tag: tag,
      status: status,
      resolvedAt: data['resolved_at']?.toString(),
      isRead: model.isRead,
    );
  }
}

class DashboardNotificationsScreen extends StatefulWidget {
  const DashboardNotificationsScreen({super.key});

  @override
  State<DashboardNotificationsScreen> createState() =>
      _DashboardNotificationsScreenState();
}

class _DashboardNotificationsScreenState
    extends State<DashboardNotificationsScreen> {
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    // Always trigger a fresh load when screen opens â€” shows spinner if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationCubit>().loadNotifications(
            filter: _selectedCategory,
            silent: context.read<NotificationCubit>().state
                is NotificationLoaded,
          );
    });
  }

  void _onCategoryChanged(String catId) {
    setState(() => _selectedCategory = catId);
    context.read<NotificationCubit>().changeFilter(catId);
  }

  Future<void> _handleAction(DashboardActivityItem item, bool approve) async {
    final actionText = approve ? 'ui.dash_status_approved'.tr2 : 'ui.dash_status_declined'.tr2;

    if (item.notificationId != null) {
      final success = await context.read<NotificationCubit>().handleAction(
            item.notificationId!,
            approve ? 'approve' : 'deny',
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'ui.dash_notif_action_success'.tr2.replaceAll(':title', item.title).replaceAll(':action', actionText)
              : 'ui.dash_notif_action_failed'.tr2),
          backgroundColor:
              approve ? const Color(0xFF1B5E20) : const Color(0xFFC62828),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      setState(() {
        item.status = approve ? ActivityStatus.approved : ActivityStatus.declined;
        item.resolvedAt = 'Just now';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ui.dash_notif_action_success'.tr2.replaceAll(':title', item.title).replaceAll(':action', actionText)),
          backgroundColor:
              approve ? const Color(0xFF1B5E20) : const Color(0xFFC62828),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showActivityApprovalDialog(DashboardActivityItem item) {
    if (item.notificationId != null) {
      context.read<NotificationCubit>().markAsRead(item.notificationId!);
    }

    final isPending = item.status == ActivityStatus.pending;
    final isApproved = item.status == ActivityStatus.approved;
    final isDeclined = item.status == ActivityStatus.declined;

    Color badgeBg;
    Color badgeColor;
    String statusLabel;

    if (isPending) {
      badgeBg = const Color(0xFFFFF3E0);
      badgeColor = const Color(0xFFE65100);
      statusLabel = 'ui.dash_status_pending'.tr2;
    } else if (isApproved) {
      badgeBg = const Color(0xFFE8F5E9);
      badgeColor = const Color(0xFF2E7D32);
      statusLabel = 'ui.dash_status_approved'.tr2;
    } else if (isDeclined) {
      badgeBg = const Color(0xFFFFEBEE);
      badgeColor = const Color(0xFFC62828);
      statusLabel = 'ui.dash_status_declined'.tr2;
    } else {
      badgeBg = const Color(0xFFEDE7F6);
      badgeColor = const Color(0xFF512DA8);
      statusLabel = 'ui.dash_status_notice'.tr2;
    }

    IconData typeIcon;
    Color typeBg;
    Color typeColor;

    switch (item.type) {
      case DashboardActivityType.mealOff:
        typeIcon = Icons.no_meals_rounded;
        typeBg = const Color(0xFFFBE9E7);
        typeColor = const Color(0xFFD84315);
        break;
      case DashboardActivityType.deposit:
        typeIcon = Icons.payments_rounded;
        typeBg = const Color(0xFFE8F5E9);
        typeColor = const Color(0xFF2E7D32);
        break;
      case DashboardActivityType.bazarDuty:
        typeIcon = Icons.shopping_basket_rounded;
        typeBg = const Color(0xFFFFF8E1);
        typeColor = const Color(0xFFF57F17);
        break;
      case DashboardActivityType.memberJoin:
        typeIcon = Icons.person_add_alt_1_rounded;
        typeBg = const Color(0xFFE1F5FE);
        typeColor = const Color(0xFF0288D1);
        break;
      case DashboardActivityType.monthClose:
      case DashboardActivityType.system:
        typeIcon = Icons.account_balance_wallet_rounded;
        typeBg = const Color(0xFFF3E5F5);
        typeColor = const Color(0xFF7B1FA2);
        break;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            backgroundColor: AppColors.paperRaised,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DashUI.rCard),
              side: const BorderSide(color: AppColors.paperLine),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Category Icon, Status Badge & Close Button
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: typeBg,
                            borderRadius: BorderRadius.circular(DashUI.rTile),
                          ),
                          child: Icon(typeIcon, color: typeColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: badgeBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: ValueListenableBuilder<int>(
                                  valueListenable: AppTranslations.notifier,
                                  builder: (context, _, _) => Text(
                                    statusLabel,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: badgeColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.timeAgo,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.inkFaded,
                                  fontWeight: FontWeight.w500,
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
                                border: Border.all(color: AppColors.paperLine),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 17,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Description
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.inkSoft,
                        height: 1.4,
                      ),
                    ),

                    // Member Profile Card
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(DashUI.rCard),
                        border: Border.all(color: AppColors.paperLine),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color:
                                  AppColors.brandDark.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                item.memberName.isNotEmpty
                                    ? item.memberName[0].toUpperCase()
                                    : 'M',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.brandDark,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.memberName,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                                Text(
                                  item.memberPhone.isNotEmpty
                                      ? '${item.memberRoom} â€¢ ${item.memberPhone}'
                                      : item.memberRoom,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.inkFaded,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Key Request Details List
                    if (item.details != null && item.details!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(DashUI.rCard),
                          border: Border.all(color: AppColors.paperLine),
                        ),
                        child: ValueListenableBuilder<int>(
                          valueListenable: AppTranslations.notifier,
                          builder: (context, _, _) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: item.details!.entries.map((e) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${DashboardActivityItem.getLocalizedDetailKey(e.key)}: ',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.inkFaded,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        e.value,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 22),

                    // Actions Area inside the Dialog
                    if (isPending) ...[
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _handleAction(item, false);
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  side: const BorderSide(
                                    color: Color(0xFFEF9A9A),
                                    width: 1.2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(DashUI.rCard),
                                  ),
                                  foregroundColor: const Color(0xFFC62828),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.close_rounded, size: 18),
                                    const SizedBox(width: 6),
                                    ValueListenableBuilder<int>(
                                      valueListenable: AppTranslations.notifier,
                                      builder: (context, _, _) => Text(
                                        'ui.decline'.tr2,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _handleAction(item, true);
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  backgroundColor: AppColors.brandDark,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(DashUI.rCard),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_rounded, size: 18),
                                    const SizedBox(width: 6),
                                    ValueListenableBuilder<int>(
                                      valueListenable: AppTranslations.notifier,
                                      builder: (context, _, _) => Text(
                                        'ui.approve'.tr2,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: AppColors.paper,
                            foregroundColor: AppColors.ink,
                            elevation: 0,
                            side: const BorderSide(
                              color: AppColors.paperLine,
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(DashUI.rCard),
                            ),
                          ),
                          child: ValueListenableBuilder<int>(
                            valueListenable: AppTranslations.notifier,
                            builder: (context, _, _) => Text(
                              item.resolvedAt != null
                                  ? '${'ui.dash_notif_resolved'.tr2} (${item.resolvedAt == 'Just now' ? 'ui.dash_notif_just_now'.tr2 : item.resolvedAt})'
                                  : 'ui.dash_notif_close_details'.tr2,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
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
        leading: const AppBackButton(),
        title: BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            final unread = state is NotificationLoaded ? state.unreadCount : 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ValueListenableBuilder<int>(
                      valueListenable: AppTranslations.notifier,
                      builder: (context, _, _) => Text(
                        'ui.dash_notif_title'.tr2,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    if (unread > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA02626),
                          borderRadius: BorderRadius.circular(DashUI.rBtn),
                        ),
                        child: ValueListenableBuilder<int>(
                          valueListenable: AppTranslations.notifier,
                          builder: (context, _, _) => Text(
                            "${bnDigits(unread)} ${"ui.dash_notif_new".tr2}",
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                ValueListenableBuilder<int>(
                  valueListenable: AppTranslations.notifier,
                  builder: (context, _, _) => Text(
                    'ui.dash_notif_subtitle'.tr2,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.inkFaded,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              final unread = state is NotificationLoaded ? state.unreadCount : 0;
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.ink),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DashUI.rTile)),
                onSelected: (value) {
                  if (value == 'read_all') {
                    context.read<NotificationCubit>().markAllAsRead();
                  } else if (value == 'clear_read') {
                    context.read<NotificationCubit>().bulkDelete(readOnly: true);
                  } else if (value == 'clear_all') {
                    context.read<NotificationCubit>().clearAll();
                  }
                },
                itemBuilder: (context) => [
                  if (unread > 0)
                    PopupMenuItem(
                      value: 'read_all',
                      child: Row(
                        children: [
                          const Icon(Icons.done_all_rounded, size: 18, color: AppColors.brandDark),
                          const SizedBox(width: 10),
                          ValueListenableBuilder<int>(valueListenable: AppTranslations.notifier, builder: (context, _, _) => Text('ui.dash_notif_mark_all'.tr2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'clear_read',
                    child: Row(
                      children: [
                        const Icon(Icons.cleaning_services_rounded, size: 18, color: AppColors.inkFaded),
                        const SizedBox(width: 10),
                        ValueListenableBuilder<int>(valueListenable: AppTranslations.notifier, builder: (context, _, _) => Text('ui.dash_notif_clear_read'.tr2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_sweep_rounded, size: 18, color: Color(0xFFEF4444)),
                        const SizedBox(width: 10),
                        ValueListenableBuilder<int>(valueListenable: AppTranslations.notifier, builder: (context, _, _) => Text('ui.dash_notif_clear_all'.tr2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFEF4444)))),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            List<DashboardActivityItem> items = [];
            int pendingCount = 0;
            int pendingMealOff = 0;
            int pendingDeposits = 0;

            if (state is NotificationLoaded) {
              items = state.notifications.map((m) => DashboardActivityItem.fromModel(m)).toList();
              pendingCount = items.where((i) => i.status == ActivityStatus.pending).length;
              pendingMealOff = items
                  .where((i) =>
                      i.type == DashboardActivityType.mealOff &&
                      i.status == ActivityStatus.pending)
                  .length;
              pendingDeposits = items
                  .where((i) =>
                      i.type == DashboardActivityType.deposit &&
                      i.status == ActivityStatus.pending)
                  .length;
            }

            return Column(
              children: [
                // Manager summary metrics banner
                _buildMetricsBanner(pendingMealOff, pendingDeposits),

                // Filter horizontal bar
                _buildCategoryBar(pendingCount),

                // Activities list
                Expanded(
                  child: state is NotificationLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.brandDark,
                            strokeWidth: 2.5,
                          ),
                        )
                      : items.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              color: AppColors.brandDark,
                              onRefresh: () => context
                                  .read<NotificationCubit>()
                                  .loadNotifications(filter: _selectedCategory),
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                                itemCount: items.length,
                                separatorBuilder: (_, index) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  return Dismissible(
                                    key: ValueKey('notif_${item.id}'),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        borderRadius: BorderRadius.circular(DashUI.rCard),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                                          const SizedBox(width: 6),
                                          ValueListenableBuilder<int>(
                                            valueListenable: AppTranslations.notifier,
                                            builder: (context, _, _) => Text(
                                              'ui.dash_notif_delete'.tr2,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    onDismissed: (_) {
                                      if (item.notificationId != null) {
                                        context.read<NotificationCubit>().deleteNotification(item.notificationId!);
                                      }
                                    },
                                    child: _buildActivityCard(item),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricsBanner(int pendingMealOff, int pendingDeposits) {
    return ValueListenableBuilder<int>(
      valueListenable: AppTranslations.notifier,
      builder: (context, _, _) => Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.brandDark.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(DashUI.rCard),
          border: Border.all(color: AppColors.brandDark.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.brandDark,
                borderRadius: BorderRadius.circular(DashUI.rBtn),
              ),
              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ui.dash_notif_manager_stream'.tr2,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pendingMealOff > 0 || pendingDeposits > 0
                        ? 'ui.dash_notif_pending_summary'.tr2
                            .replaceAll(':meal_off', bnDigits(pendingMealOff))
                            .replaceAll(':deposits', bnDigits(pendingDeposits))
                        : 'ui.dash_notif_all_updated'.tr2,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.inkFaded,
                      fontWeight: FontWeight.w600,
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

  Widget _buildCategoryBar(int pendingCount) {
    return ValueListenableBuilder<int>(
      valueListenable: AppTranslations.notifier,
      builder: (context, _, _) {
        final categories = [
          {'id': 'all', 'label': 'ui.dash_notif_cat_all'.tr2},
          {'id': 'pending', 'label': 'ui.dash_notif_cat_pending'.tr2.replaceAll(':count', bnDigits(pendingCount))},
          {'id': 'meal_off', 'label': 'ui.dash_notif_cat_meal_off'.tr2},
          {'id': 'deposits', 'label': 'ui.dash_notif_cat_deposits'.tr2},
          {'id': 'bazar', 'label': 'ui.dash_notif_cat_bazar'.tr2},
          {'id': 'members', 'label': 'ui.dash_notif_cat_members'.tr2},
        ];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.paperRaised,
            border: Border(
              bottom: BorderSide(color: AppColors.paperLine, width: 0.8),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: categories.map((c) {
                final isSelected = _selectedCategory == c['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => _onCategoryChanged(c['id']!),
                    borderRadius: BorderRadius.circular(DashUI.rCard),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.brandDark : AppColors.paper,
                        borderRadius: BorderRadius.circular(DashUI.rCard),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.brandDark
                              : AppColors.paperLine,
                        ),
                      ),
                      child: Text(
                        c['label']!,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityCard(DashboardActivityItem item) {
    final isPending = item.status == ActivityStatus.pending;
    final isApproved = item.status == ActivityStatus.approved;
    final isDeclined = item.status == ActivityStatus.declined;

    Color badgeBg;
    Color badgeColor;
    String statusLabel;

    if (isPending) {
      badgeBg = const Color(0xFFFFF3E0);
      badgeColor = const Color(0xFFE65100);
      statusLabel = 'ui.dash_status_pending'.tr2;
    } else if (isApproved) {
      badgeBg = const Color(0xFFE8F5E9);
      badgeColor = const Color(0xFF2E7D32);
      statusLabel = 'ui.dash_status_approved'.tr2;
    } else if (isDeclined) {
      badgeBg = const Color(0xFFFFEBEE);
      badgeColor = const Color(0xFFC62828);
      statusLabel = 'ui.dash_status_declined'.tr2;
    } else {
      badgeBg = const Color(0xFFEDE7F6);
      badgeColor = const Color(0xFF512DA8);
      statusLabel = 'ui.dash_status_notice'.tr2;
    }

    IconData typeIcon;
    Color typeBg;
    Color typeColor;

    switch (item.type) {
      case DashboardActivityType.mealOff:
        if (item.tag == 'Meal ON') {
          typeIcon = Icons.restaurant_rounded;
          typeBg = const Color(0xFFE8F5E9);
          typeColor = const Color(0xFF2E7D32);
        } else if (item.tag == 'Guest Meal') {
          typeIcon = Icons.people_outline_rounded;
          typeBg = const Color(0xFFEDE7F6);
          typeColor = const Color(0xFF5E35B1);
        } else {
          typeIcon = Icons.no_meals_rounded;
          typeBg = const Color(0xFFFBE9E7);
          typeColor = const Color(0xFFD84315);
        }
        break;
      case DashboardActivityType.deposit:
        typeIcon = Icons.payments_rounded;
        typeBg = const Color(0xFFE8F5E9);
        typeColor = const Color(0xFF2E7D32);
        break;
      case DashboardActivityType.bazarDuty:
        typeIcon = Icons.shopping_basket_rounded;
        typeBg = const Color(0xFFFFF8E1);
        typeColor = const Color(0xFFF57F17);
        break;
      case DashboardActivityType.memberJoin:
        typeIcon = Icons.person_add_alt_1_rounded;
        typeBg = const Color(0xFFE1F5FE);
        typeColor = const Color(0xFF0288D1);
        break;
      case DashboardActivityType.monthClose:
      case DashboardActivityType.system:
        typeIcon = Icons.account_balance_wallet_rounded;
        typeBg = const Color(0xFFF3E5F5);
        typeColor = const Color(0xFF7B1FA2);
        break;
    }

    return InkWell(
      onTap: () => _showActivityApprovalDialog(item),
      borderRadius: BorderRadius.circular(DashUI.rCard),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.paperRaised,
          borderRadius: BorderRadius.circular(DashUI.rCard),
          border: Border.all(
            color: isPending
                ? const Color(0xFFE65100).withValues(alpha: 0.35)
                : AppColors.paperLine,
            width: isPending ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isPending ? 0.04 : 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: typeBg,
                borderRadius: BorderRadius.circular(DashUI.rTile),
              ),
              child: Icon(typeIcon, color: typeColor, size: 20),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row with Member name, tag, time
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.memberName,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: typeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: ValueListenableBuilder<int>(
                          valueListenable: AppTranslations.notifier,
                          builder: (context, _, _) => Text(
                            item.displayTag,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: typeColor,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        item.timeAgo,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.inkFaded,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Title & Highlight Value
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.highlightValue != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6.5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.brandDark.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: ValueListenableBuilder<int>(
                            valueListenable: AppTranslations.notifier,
                            builder: (context, _, _) => Text(
                              item.displayHighlightValue,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: AppColors.brandDark,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Snippet description
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.inkFaded,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Status Badge & Arrow
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ValueListenableBuilder<int>(
                    valueListenable: AppTranslations.notifier,
                    builder: (context, _, _) => Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.inkFaded,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ValueListenableBuilder<int>(
      valueListenable: AppTranslations.notifier,
      builder: (context, _, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.paperRaised,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.paperLine),
                ),
                child: const Center(
                  child: Icon(
                    Icons.task_alt_rounded,
                    size: 36,
                    color: AppColors.brandDark,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ui.dash_notif_empty_title'.tr2,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'ui.dash_notif_empty_desc'.tr2,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.inkFaded,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
