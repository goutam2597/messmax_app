import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_back_button.dart';

enum PublicNotificationType {
  seatAlert,
  offer,
  inquiry,
  system,
}

class PublicNotificationItem {
  final String id;
  final String title;
  final String message;
  final String timeAgo;
  final PublicNotificationType type;
  final String tag;
  final String? detailHeader;
  final Map<String, String>? metadata;
  final String? primaryActionLabel;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  bool isRead;

  PublicNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.type,
    required this.tag,
    this.detailHeader,
    this.metadata,
    this.primaryActionLabel,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.isRead = false,
  });
}

class PublicNotificationsScreen extends StatefulWidget {
  const PublicNotificationsScreen({super.key});

  @override
  State<PublicNotificationsScreen> createState() =>
      _PublicNotificationsScreenState();
}

class _PublicNotificationsScreenState extends State<PublicNotificationsScreen> {
  String _selectedFilter = 'all';

  late List<PublicNotificationItem> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = [
      PublicNotificationItem(
        id: '1',
        title: 'New Seat Available in Dhanmondi',
        message:
            'A 2-seat master bedroom matching your saved preferences was just posted at Green View Mess (Road 8/A).',
        timeAgo: '12m ago',
        type: PublicNotificationType.seatAlert,
        tag: 'Seat Alert',
        detailHeader: 'Dhanmondi Road 8/A • 2 Seats Available',
        metadata: {
          'Mess': 'Green View Mess',
          'Location': 'Dhanmondi, Dhaka',
          'Rent': '৳4,200 / month',
          'Room Type': 'Master Bed (Attached Bath)',
        },
        primaryActionLabel: 'View Seat Listing',
        icon: Icons.meeting_room_rounded,
        iconBg: const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF2E7D32),
        isRead: false,
      ),
      PublicNotificationItem(
        id: '2',
        title: 'Special Student Discount! 🎉',
        message:
            'Get 15% cashback on your first month mess deposit when booking through MessMax verification.',
        timeAgo: '2h ago',
        type: PublicNotificationType.offer,
        tag: '15% Promo',
        detailHeader: 'Back to Campus Welcome Voucher',
        metadata: {
          'Promo Code': 'MESSMAX15',
          'Valid Until': '31 August 2026',
          'Eligible For': 'All verified student users',
        },
        primaryActionLabel: 'Claim Promo Code',
        icon: Icons.local_offer_rounded,
        iconBg: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFE65100),
        isRead: false,
      ),
      PublicNotificationItem(
        id: '3',
        title: 'Owner Replied to Your Inquiry',
        message:
            'Manager from "Padma Student Hostel" replied: "Yes, 1 seat in shared room is available immediately for students."',
        timeAgo: '5h ago',
        type: PublicNotificationType.inquiry,
        tag: 'Inquiry',
        detailHeader: 'Direct Response from Padma Hostel',
        metadata: {
          'Hostel': 'Padma Student Hostel',
          'Sender': 'Manager Rafiqul',
          'Contact': '01711-223344',
        },
        primaryActionLabel: 'Open Conversation',
        icon: Icons.chat_bubble_outline_rounded,
        iconBg: const Color(0xFFE1F5FE),
        iconColor: const Color(0xFF0288D1),
        isRead: true,
      ),
      PublicNotificationItem(
        id: '4',
        title: 'MessMax 2.0 Feature Update 🚀',
        message:
            'Now manage daily bazar duties, live meal calculations, and deposit receipts faster with our redesigned interface.',
        timeAgo: '1d ago',
        type: PublicNotificationType.system,
        tag: 'Update',
        detailHeader: 'What\'s New in Version 2.0',
        metadata: {
          'Features': 'Bazar Roster, Live Meals, Dialogs',
          'Performance': '2x Faster Sheet Sync',
        },
        primaryActionLabel: 'Explore Features',
        icon: Icons.rocket_launch_rounded,
        iconBg: const Color(0xFFF3E5F5),
        iconColor: const Color(0xFF7B1FA2),
        isRead: true,
      ),
      PublicNotificationItem(
        id: '5',
        title: 'Price Drop Alert in Mirpur 10',
        message:
            'A single room seat listing dropped from ৳4,500 to ৳3,900 / month.',
        timeAgo: '2d ago',
        type: PublicNotificationType.seatAlert,
        tag: 'Price Drop',
        detailHeader: 'Mirpur 10 Block C • Rent Reduced',
        metadata: {
          'Previous Rent': '৳4,500 / month',
          'New Rent': '৳3,900 / month',
          'Savings': '৳600 / month',
        },
        primaryActionLabel: 'View Listing',
        icon: Icons.trending_down_rounded,
        iconBg: const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF2E7D32),
        isRead: true,
      ),
      PublicNotificationItem(
        id: '6',
        title: 'Security & Student Verification',
        message:
            'Verify your NID / Student ID to get the Trusted Badge and unlock instant booking privileges.',
        timeAgo: '3d ago',
        type: PublicNotificationType.system,
        tag: 'Security',
        detailHeader: 'Trusted Student Verification',
        metadata: {
          'Status': 'Pending Documents',
          'Benefit': 'Fast-track deposit approval',
        },
        primaryActionLabel: 'Start Verification',
        icon: Icons.verified_user_rounded,
        iconBg: const Color(0xFFECEFF1),
        iconColor: const Color(0xFF455A64),
        isRead: true,
      ),
    ];
  }

  List<PublicNotificationItem> get _filteredNotifications {
    if (_selectedFilter == 'alerts') {
      return _notifications
          .where((n) => n.type == PublicNotificationType.seatAlert)
          .toList();
    } else if (_selectedFilter == 'offers') {
      return _notifications
          .where((n) => n.type == PublicNotificationType.offer)
          .toList();
    } else if (_selectedFilter == 'inquiries') {
      return _notifications
          .where((n) => n.type == PublicNotificationType.inquiry)
          .toList();
    } else if (_selectedFilter == 'system') {
      return _notifications
          .where((n) => n.type == PublicNotificationType.system)
          .toList();
    }
    return _notifications;
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _markAllAsRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showNotificationDetailDialog(PublicNotificationItem item) {
    setState(() => item.isRead = true);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.paperRaised,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.paperLine),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header with Category Icon, Tag & Close Button
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: item.iconBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, color: item.iconColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7.5, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: item.iconBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.tag,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: item.iconColor,
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
                        borderRadius: BorderRadius.circular(16),
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
                const SizedBox(height: 8),

                // Message
                Text(
                  item.message,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.inkSoft,
                    height: 1.45,
                  ),
                ),

                // Metadata Details Box if available
                if (item.metadata != null && item.metadata!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.paperLine),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: item.metadata!.entries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${e.key}: ',
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
                ],

                const SizedBox(height: 22),

                // Primary Action Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Opening ${item.title}...'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: AppColors.brandDark,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.primaryActionLabel ?? 'View Details',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredNotifications;

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paperRaised,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: const AppBackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                if (_unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.brandDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_unreadCount new',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const Text(
              'Alerts, seat updates & announcements',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.inkFaded,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: TextButton(
                  onPressed: _markAllAsRead,
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Mark read',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandDark,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter categories horizontal bar
            _buildFilterBar(),

            // Notification cards list
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      itemCount: filtered.length,
                      separatorBuilder: (_, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return _buildNotificationCard(item);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = [
      {'id': 'all', 'label': 'All'},
      {'id': 'alerts', 'label': 'Seat Alerts'},
      {'id': 'offers', 'label': 'Offers'},
      {'id': 'inquiries', 'label': 'Inquiries'},
      {'id': 'system', 'label': 'System'},
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
          children: filters.map((f) {
            final isSelected = _selectedFilter == f['id'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => setState(() => _selectedFilter = f['id']!),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.brandDark : AppColors.paper,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.brandDark
                          : AppColors.paperLine,
                    ),
                  ),
                  child: Text(
                    f['label']!,
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
  }

  Widget _buildNotificationCard(PublicNotificationItem item) {
    return InkWell(
      onTap: () => _showNotificationDetailDialog(item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead
              ? AppColors.paperRaised
              : AppColors.paperRaised.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isRead
                ? AppColors.paperLine
                : AppColors.brandDark.withValues(alpha: 0.35),
            width: item.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: item.isRead ? 0.02 : 0.04),
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
                color: item.iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 20),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with tag and time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6.5, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.iconBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.tag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: item.iconColor,
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
                      if (!item.isRead) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.brandDark,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Title
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          item.isRead ? FontWeight.w700 : FontWeight.w900,
                      color: AppColors.ink,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Message snippet
                  Text(
                    item.message,
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

            // Arrow chevron icon indicator
            const Padding(
              padding: EdgeInsets.only(top: 14),
              child: Icon(
                Icons.chevron_right_rounded,
                color: AppColors.inkFaded,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
                  Icons.notifications_none_rounded,
                  size: 36,
                  color: AppColors.inkFaded,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Notifications',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'You\'re all caught up! Updates regarding seat availability and alerts will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.inkFaded,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
