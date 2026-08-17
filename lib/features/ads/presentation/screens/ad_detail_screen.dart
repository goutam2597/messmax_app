import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ad_cards.dart';
import '../../../../core/widgets/dot_indicator_row.dart';
import '../../../../core/widgets/network_image_cover.dart';
import '../../data/models/ad_model.dart';
import '../../data/repositories/ads_repository.dart';

class AdDetailScreen extends StatefulWidget {
  final AdModel ad;

  const AdDetailScreen({super.key, required this.ad});

  @override
  State<AdDetailScreen> createState() => _AdDetailScreenState();
}

class _AdDetailScreenState extends State<AdDetailScreen> {
  int _galleryIndex = 0;
  late AdModel _ad;
  List<AdModel> _relatedAds = [];
  bool _isLoadingRelated = true;
  bool _fetching = false;
  bool _galleryInitialized = false;
  final PageController _galleryController = PageController();

  final AdsRepository _repository = AdsRepository();

  @override
  void initState() {
    super.initState();
    _ad = widget.ad;
    _fetchDetailAndRelated();
  }

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetailAndRelated() async {
    if (_fetching) return;
    _fetching = true;
    try {
      final res = await _repository.getAdDetail(_ad.slug);
      if (!mounted) return;
      setState(() {
        // Single rebuild only — keeps initial card visible until fresh data arrives,
        // so "Listed By" / gallery don't flicker through an intermediate spinner frame.
        _ad = res.ad;
        _relatedAds = res.relatedAds;
        _isLoadingRelated = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingRelated = false);
    } finally {
      _fetching = false;
    }
  }

  AdModel get ad => _ad;

  /// Opens a fullscreen zoomable photo viewer starting at the given index.
  void _openPhotoViewer(int initialIndex) {
    if (ad.imageUrls.isEmpty) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, _, _) => _PhotoViewerScreen(
          imageUrls: ad.imageUrls,
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.accent,
            backgroundColor: Colors.white,
            onRefresh: _fetchDetailAndRelated,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroGallery(context),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title & badges
                        _buildTitleBlock(),

                        const SizedBox(height: 14),

                        // Gradient rent + status banner
                        _buildRentBanner(),

                        const SizedBox(height: 14),

                        // Manager / poster card
                        _buildManagerCard(),

                        const SizedBox(height: 14),

                        // Location card
                        _buildLocationCard(),

                        const SizedBox(height: 12),

                        // Listing details (spec tiles)
                        _sectionHeader(
                          icon: Icons.info_outline_rounded,
                          title: 'Listing Details',
                        ),
                        const SizedBox(height: 12),

                        _buildSpecsGrid(),

                        const SizedBox(height: 12),

                        // Description
                        if (ad.description != null &&
                            ad.description!.isNotEmpty) ...[
                          _sectionHeader(
                            icon: Icons.notes_rounded,
                            title: 'Description',
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.paperRaised,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.paperLine),
                            ),
                            child: Text(
                              ad.description!,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Amenities
                        if (ad.amenities.isNotEmpty) ...[
                          _sectionHeader(
                            icon: Icons.checklist_rounded,
                            title: 'Amenities & Facilities',
                          ),
                          const SizedBox(height: 10),
                          _buildAmenitiesWrap(),
                          const SizedBox(height: 22),
                        ],

                        // Related seats — own small loader so header/content never flickers
                        if (_isLoadingRelated)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.brandDark),
                              ),
                            ),
                          )
                        else if (_relatedAds.isNotEmpty) ...[
                          _sectionHeader(
                            icon: Icons.explore_rounded,
                            title: 'Related Seats',
                            subtitle:
                                'More options in ${ad.areaLabel ?? ad.area ?? ad.city ?? 'the same area'}',
                          ),
                          const SizedBox(height: 12),
                          MasonryGridView.count(
                            padding: EdgeInsets.zero,
                            clipBehavior: Clip.none,
                            crossAxisCount: 2, 
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _relatedAds.length,
                            itemBuilder: (context, index) {
                              final related = _relatedAds[index];
                              return AdGridCard(
                                ad: related,
                                imageHeight: index % 3 == 0 ? 150 : 120,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AdDetailScreen(ad: related),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),

          // Sticky bottom contact bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomContactBar(context),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: AppColors.brandDark),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
                letterSpacing: -0.3,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.inkFaded,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTitleBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                ad.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                  height: 1.25,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            if (ad.isFeatured) ...[
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'FEATURED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (ad.publishedAt != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 13,
                color: AppColors.inkFaded,
              ),
              const SizedBox(width: 4),
              Text(
                'Posted ${ad.publishedAt}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.inkFaded,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildHeroGallery(BuildContext context) {
    if (ad.imageUrls.isNotEmpty) {
      final isLoop = ad.imageUrls.length > 1;
      final itemCount = isLoop
          ? ad.imageUrls.length * 1000
          : ad.imageUrls.length;

      if (isLoop && !_galleryInitialized) {
        _galleryInitialized = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_galleryController.hasClients) {
            _galleryController.jumpToPage(ad.imageUrls.length * 500);
          }
        });
      }

      final displayIndex = isLoop
          ? _galleryIndex % ad.imageUrls.length
          : _galleryIndex;

      return Stack(
        children: [
          SizedBox(
            height: 300,
            width: double.infinity,
            child: PageView.builder(
              controller: _galleryController,
              itemCount: itemCount,
              onPageChanged: (index) => setState(() => _galleryIndex = index),
              itemBuilder: (context, index) {
                final imageIndex = isLoop ? index % ad.imageUrls.length : index;
                return GestureDetector(
                  onTap: () => _openPhotoViewer(imageIndex),
                  child: Image.network(
                    ad.imageUrls[imageIndex],
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.brandSoft,
                      child: const Icon(
                        Icons.home_rounded,
                        color: AppColors.inkFaded,
                        size: 48,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (ad.imageUrls.length > 1) ...[
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  '${displayIndex + 1}/${ad.imageUrls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 18,
              left: 0,
              right: 0,
              child: Center(
                child: DotIndicatorRow(
                  count: ad.imageUrls.length,
                  activeIndex: displayIndex,
                  light: true,
                ),
              ),
            ),
          ],
        ],
      );
    }

    return Container(
      height: 240,
      width: double.infinity,
      color: AppColors.brandSoft,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.house_rounded, color: AppColors.inkFaded, size: 54),
          SizedBox(height: 8),
          Text(
            'MessMax Verified Listing',
            style: TextStyle(
              color: AppColors.inkFaded,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandDark, AppColors.brandDeep],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandDark.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RENT PER SEAT',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.65),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '৳${ad.rentPerSeat.toInt()}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      ' / month',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            width: 1,
            height: 44,
            color: Colors.white.withValues(alpha: 0.15),
          ),

          const SizedBox(width: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STATUS',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.65),
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: ad.seatsAvailable > 1
                      ? AppColors.emerald
                      : AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${ad.seatsAvailable} Seat${ad.seatsAvailable == 1 ? '' : 's'} Open',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManagerCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.paperLine),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brandSoft,
            ),
            clipBehavior: Clip.antiAlias,
            child: ad.posterAvatarUrl != null
                ? NetworkImageCover(url: ad.posterAvatarUrl, iconSize: 20)
                : const Icon(
                    Icons.person_rounded,
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
                  'LISTED BY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkFaded,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ad.posterName ?? (ad.messName ?? 'Mess Manager'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.emeraldSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 14,
                  color: AppColors.emerald,
                ),
                SizedBox(width: 4),
                Text(
                  'VERIFIED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.emerald,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.paperLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.accentDark,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.areaLabel ?? ad.city ?? 'Dhaka',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    if (ad.city != null)
                      Text(
                        ad.city!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.inkFaded,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (ad.hasVisibleAddress)
            Text(
              ad.location!,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.inkSoft,
                height: 1.4,
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 16,
                    color: AppColors.brandDark,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Street address hidden by manager for privacy. Contact manager to visit.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.brandDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpecsGrid() {
    final specs = <(IconData, String, String)>[
      (Icons.meeting_room_rounded, 'Room Type', ad.roomType.toUpperCase()),
      if (ad.messName != null)
        (Icons.apartment_rounded, 'Mess Name', ad.messName!),
      (
        Icons.people_outline_rounded,
        'Room Capacity',
        ad.roomCapacity != null ? '${ad.roomCapacity} Persons' : 'Flexible',
      ),
      (Icons.attach_money_rounded, 'Rent Type', 'Per Seat'),
    ];

    return GridView.count(
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 3,
      children: specs.map((spec) {
        final (icon, label, value) = spec;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.paperRaised,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.paperLine),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: AppColors.brandDark),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkFaded,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAmenitiesWrap() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ad.amenities.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.emeraldSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.emerald.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 15,
                color: AppColors.emerald,
              ),
              const SizedBox(width: 5),
              Text(
                item,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomContactBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  final phone = ad.contactPhone ?? '01700000000';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Calling Manager at $phone')),
                  );
                },
                icon: const Icon(Icons.phone_rounded, size: 18),
                label: const Text(
                  'Call Manager',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                ),
              ),
            ),

            if (ad.contactWhatsapp != null) ...[
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF25D366).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  padding: const EdgeInsets.all(14),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Opening WhatsApp: ${ad.contactWhatsapp}',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.chat_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Fullscreen zoomable photo gallery. Swipe between images, pinch to zoom,
/// double-tap to toggle zoom, tap background to close.
class _PhotoViewerScreen extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _PhotoViewerScreen({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<_PhotoViewerScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            pageController: _pageController,
            itemCount: widget.imageUrls.length,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            onPageChanged: (index) => setState(() => _currentIndex = index),
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(widget.imageUrls[index]),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3.5,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
              );
            },
          ),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),

          // Image counter
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Text(
                '${_currentIndex + 1} / ${widget.imageUrls.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          // Hint
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Pinch to zoom • Swipe for more',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
