import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/network_image_cover.dart';
import '../../../ads/data/models/ad_model.dart';
import '../../../ads/data/repositories/ads_repository.dart';
import '../../../ads/presentation/screens/ad_detail_screen.dart';

class PublicNotificationItem {
  final int id;
  final String title;
  final String message;
  final String timeAgo;
  final String tag;
  final String? imageUrl;
  final String? itemType;
  final int? itemId;
  final String? itemSlug;
  final String? actionUrl;
  final Map<String, dynamic>? adSummary;
  final String? createdAt;
  bool isRead;

  PublicNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.tag,
    this.imageUrl,
    this.itemType,
    this.itemId,
    this.itemSlug,
    this.actionUrl,
    this.adSummary,
    this.createdAt,
    this.isRead = false,
  });

  factory PublicNotificationItem.fromJson(Map<String, dynamic> json) {
    return PublicNotificationItem(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Announcement',
      message: json['body'] as String? ?? '',
      timeAgo: json['time_ago'] as String? ?? 'Just now',
      tag: json['tag'] as String? ?? 'Announcement',
      imageUrl: json['image_url'] as String?,
      itemType: json['item_type'] as String?,
      itemId: json['item_id'] as int?,
      itemSlug: json['item_slug'] as String?,
      actionUrl: json['action_url'] as String?,
      adSummary: json['ad'] as Map<String, dynamic>?,
      createdAt: json['created_at'] as String?,
      isRead: false,
    );
  }
}

class PublicNotificationsScreen extends StatefulWidget {
  const PublicNotificationsScreen({super.key});

  @override
  State<PublicNotificationsScreen> createState() =>
      _PublicNotificationsScreenState();
}

class _PublicNotificationsScreenState extends State<PublicNotificationsScreen>
    with WidgetsBindingObserver {
  String _selectedFilter = 'all';
  List<PublicNotificationItem> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  late final StreamController<List<PublicNotificationItem>> _notificationsStreamController;
  StreamSubscription<RemoteMessage>? _fcmSubscription;
  Timer? _livePollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notificationsStreamController = StreamController<List<PublicNotificationItem>>.broadcast();

    // 1. Initial fetch
    _fetchNotifications();

    // 2. Real-time FCM stream listener (triggers instant silent sync on incoming broadcast)
    _fcmSubscription = PushNotificationService.onForegroundMessage.listen((RemoteMessage message) {
      if (mounted) {
        _fetchNotifications(isSilent: true);
      }
    });

    // 3. Periodic real-time stream sync while user is on this screen (every 6 seconds)
    _livePollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted) {
        _fetchNotifications(isSilent: true);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _fetchNotifications(isSilent: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fcmSubscription?.cancel();
    _livePollTimer?.cancel();
    _notificationsStreamController.close();
    super.dispose();
  }

  Stream<List<PublicNotificationItem>> get _notificationsStream =>
      _notificationsStreamController.stream;

  Future<void> _fetchNotifications({bool isSilent = false}) async {
    if (!isSilent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await DioClient.instance.get(ApiEndpoints.publicNotifications);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List items = response.data['data']['items'] as List? ?? [];
        if (mounted) {
          final newItems = items
              .map((e) => PublicNotificationItem.fromJson(e as Map<String, dynamic>))
              .toList();

          // Preserve read state of existing items if already marked read locally
          for (final newItem in newItems) {
            final existing = _notifications.firstWhere(
              (n) => n.id == newItem.id,
              orElse: () => newItem,
            );
            if (existing != newItem && existing.isRead) {
              newItem.isRead = true;
            }
          }

          _notifications = newItems;

          if (!_notificationsStreamController.isClosed) {
            _notificationsStreamController.add(_notifications);
          }

          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = null;
            });
          }
        }
      } else {
        if (mounted && !isSilent) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Failed to load notifications.';
          });
        }
      }
    } on DioException catch (e) {
      if (mounted && !isSilent) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.response?.data?['message']?.toString() ??
              'Unable to reach server. Pull down to refresh.';
        });
      }
    } catch (_) {
      if (mounted && !isSilent) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An unexpected error occurred.';
        });
      }
    }
  }

  List<PublicNotificationItem> _filterList(List<PublicNotificationItem> list) {
    if (_selectedFilter == 'all') return list;
    final lowerFilter = _selectedFilter.toLowerCase();
    return list.where((n) {
      final lowerTag = n.tag.toLowerCase();
      if (lowerFilter == 'alerts') {
        return lowerTag.contains('seat') || lowerTag.contains('alert') || lowerTag.contains('room');
      } else if (lowerFilter == 'offers') {
        return lowerTag.contains('promo') || lowerTag.contains('offer') || lowerTag.contains('discount');
      } else if (lowerFilter == 'updates') {
        return lowerTag.contains('update') || lowerTag.contains('feature') || lowerTag.contains('version');
      }
      return true;
    }).toList();
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _markAllAsRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });

    if (!_notificationsStreamController.isClosed) {
      _notificationsStreamController.add(_notifications);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  IconData _getTagIcon(String tag) {
    final lower = tag.toLowerCase();
    if (lower.contains('seat') || lower.contains('room') || lower.contains('alert')) {
      return Icons.meeting_room_rounded;
    }
    if (lower.contains('promo') || lower.contains('offer') || lower.contains('discount')) {
      return Icons.local_offer_rounded;
    }
    if (lower.contains('update') || lower.contains('feature')) {
      return Icons.rocket_launch_rounded;
    }
    return Icons.campaign_rounded;
  }

  Color _getTagColor(String tag) {
    final lower = tag.toLowerCase();
    if (lower.contains('seat') || lower.contains('room') || lower.contains('alert')) {
      return const Color(0xFF2E7D32);
    }
    if (lower.contains('promo') || lower.contains('offer') || lower.contains('discount')) {
      return const Color(0xFFE65100);
    }
    if (lower.contains('update') || lower.contains('feature')) {
      return const Color(0xFF7B1FA2);
    }
    return AppColors.brandDark;
  }

  Color _getTagBg(String tag) {
    final lower = tag.toLowerCase();
    if (lower.contains('seat') || lower.contains('room') || lower.contains('alert')) {
      return const Color(0xFFE8F5E9);
    }
    if (lower.contains('promo') || lower.contains('offer') || lower.contains('discount')) {
      return const Color(0xFFFFF3E0);
    }
    if (lower.contains('update') || lower.contains('feature')) {
      return const Color(0xFFF3E5F5);
    }
    return AppColors.brandSoft;
  }

  Future<void> _handleNotificationTap(PublicNotificationItem item) async {
    setState(() => item.isRead = true);
    if (!_notificationsStreamController.isClosed) {
      _notificationsStreamController.add(_notifications);
    }

    // If notification has attached item (Seat Ad)
    final hasItem = (item.itemType == 'ad' || item.itemId != null || item.itemSlug != null);
    if (hasItem) {
      final slug = item.itemSlug ?? (item.adSummary?['slug'] as String?);
      if (slug != null && slug.isNotEmpty) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: CircularProgressIndicator(color: AppColors.brandDark),
          ),
        );

        try {
          final detail = await AdsRepository().getAdDetail(slug);
          if (mounted) Navigator.pop(context); // Close spinner

          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AdDetailScreen(ad: detail.ad)),
          );
          return;
        } catch (_) {
          if (mounted) Navigator.pop(context); // Close spinner

          // Fallback with summary ad if available
          if (item.adSummary != null) {
            final fallbackAd = AdModel(
              id: item.itemId ?? (item.adSummary!['id'] as int? ?? 0),
              slug: slug,
              title: item.adSummary!['title'] as String? ?? item.title,
              city: item.adSummary!['city'] as String?,
              area: item.adSummary!['area'] as String?,
              seatsAvailable: item.adSummary!['seats_available'] as int? ?? 1,
              rentPerSeat: (item.adSummary!['rent_per_seat'] as num?)?.toDouble() ?? 0.0,
              roomType: item.adSummary!['room_type'] as String? ?? 'shared',
              hideAddress: false,
              hasVisibleAddress: true,
              amenities: const [],
              isFeatured: false,
              imageUrls: item.adSummary!['cover_image_url'] != null
                  ? [item.adSummary!['cover_image_url'] as String]
                  : [],
            );
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AdDetailScreen(ad: fallbackAd)),
            );
            return;
          }
        }
      }
    }

    // Default: Show rich detail dialog
    _showNotificationDetailDialog(item);
  }

  void _showNotificationDetailDialog(PublicNotificationItem item) {
    setState(() => item.isRead = true);
    if (!_notificationsStreamController.isClosed) {
      _notificationsStreamController.add(_notifications);
    }

    final iconColor = _getTagColor(item.tag);
    final iconBg = _getTagBg(item.tag);
    final icon = _getTagIcon(item.tag);

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
                        color: iconBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: iconColor, size: 22),
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
                              color: iconBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.tag,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: iconColor,
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

                if (item.imageUrl != null && item.imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: NetworkImageCover(
                      url: item.imageUrl,
                      height: 140,
                      width: double.infinity,
                    ),
                  ),
                ],

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

                const SizedBox(height: 20),

                // Close / Action Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: AppColors.brandDark,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Got It',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
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
                    letterSpacing: -0.3,
                  ),
                ),
                if (_unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.brandDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_unreadCount',
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
            const SizedBox(height: 1),
            const Text(
              'Seat alerts, promo offers & announcements',
              style: TextStyle(
                fontSize: 11.5,
                color: AppColors.inkFaded,
                fontWeight: FontWeight.w500,
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

            // Reactive StreamBuilder list of notifications
            Expanded(
              child: StreamBuilder<List<PublicNotificationItem>>(
                stream: _notificationsStream,
                initialData: _notifications.isNotEmpty ? _notifications : null,
                builder: (context, snapshot) {
                  if (_isLoading && (!snapshot.hasData || snapshot.data!.isEmpty)) {
                    return _buildSkeletonList();
                  }

                  if (_errorMessage != null && (!snapshot.hasData || snapshot.data!.isEmpty)) {
                    return _buildErrorState();
                  }

                  final currentList = snapshot.data ?? _notifications;
                  final filtered = _filterList(currentList);

                  return RefreshIndicator(
                    color: AppColors.brandDark,
                    onRefresh: _fetchNotifications,
                    child: filtered.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                            itemCount: filtered.length,
                            separatorBuilder: (_, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              return _buildNotificationCard(item);
                            },
                          ),
                  );
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
      {'id': 'updates', 'label': 'Updates'},
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
                onTap: () {
                  setState(() => _selectedFilter = f['id']!);
                  if (!_notificationsStreamController.isClosed) {
                    _notificationsStreamController.add(_notifications);
                  }
                },
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
    final iconColor = _getTagColor(item.tag);
    final iconBg = _getTagBg(item.tag);
    final icon = _getTagIcon(item.tag);
    final hasAttachedAd = (item.itemType == 'ad' || item.itemId != null || item.itemSlug != null);

    return InkWell(
      onTap: () => _handleNotificationTap(item),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
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
                              color: iconBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.tag,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: iconColor,
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

            // Attached Seat Listing snapshot pill if available
            if (hasAttachedAd && item.adSummary != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.paperLine),
                ),
                child: Row(
                  children: [
                    if (item.adSummary!['cover_image_url'] != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: NetworkImageCover(
                          url: item.adSummary!['cover_image_url'] as String?,
                          width: 44,
                          height: 44,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.adSummary!['title'] as String? ?? 'Attached Seat Listing',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '৳${(item.adSummary!['rent_per_seat'] as num?)?.toInt() ?? 0} / month • ${item.adSummary!['area'] ?? item.adSummary!['city'] ?? 'Dhaka'}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.inkFaded,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.brandDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Seat',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
                        ],
                      ),
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

  Widget _buildSkeletonList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: 4,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (_, index) => Container(
        height: 90,
        decoration: BoxDecoration(
          color: AppColors.paperRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.paperLine),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.paperLine.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.paperLine.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.paperLine.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
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
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.inkFaded),
            const SizedBox(height: 14),
            Text(
              _errorMessage ?? 'Failed to load notifications.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _fetchNotifications,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
              'No Marketing Notifications',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Stay tuned! New seat alerts, verified mess announcements, and exclusive student promos will appear here.',
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
