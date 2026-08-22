import 'package:flutter/material.dart';
import '../../../../core/locale/app_translations.dart';
import '../../../../core/utils/bn_digits.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ad_cards.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/dot_indicator_row.dart';
import '../../../../core/widgets/network_image_cover.dart';
import '../../data/models/ad_model.dart';
import '../../data/repositories/ads_repository.dart';
import '../../../dashboard/presentation/widgets/dash_ui.dart';

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
  bool _isLoading = true;
  bool _isLoadingRelated = true;
  bool _fetching = false;
  final PageController _galleryController = PageController();

  final AdsRepository _repository = AdsRepository();

  @override
  void initState() {
    super.initState();
    _ad = widget.ad;
    final cached = AdsRepository.getDetailCached(_ad.slug);
    if (cached != null) {
      _ad = cached.ad;
      _relatedAds = cached.relatedAds;
      _isLoading = false;
      _isLoadingRelated = false;
      _fetchDetailAndRelated(forceRefresh: false);
    } else {
      _isLoading = true;
      _fetchDetailAndRelated(forceRefresh: true);
    }
  }

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetailAndRelated({bool forceRefresh = false}) async {
    if (_fetching) return;
    _fetching = true;
    try {
      final res = await _repository.getAdDetail(
        _ad.slug,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _ad = res.ad;
        _relatedAds = res.relatedAds;
        _isLoading = false;
        _isLoadingRelated = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingRelated = false;
        });
      }
    } finally {
      _fetching = false;
    }
  }

  AdModel get ad => _ad;

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
    if (_isLoading) {
      return _SeatDetailSkeleton(onBack: () => Navigator.of(context).pop());
    }

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.brandDark,
            backgroundColor: Colors.white,
            onRefresh: () => _fetchDetailAndRelated(forceRefresh: true),
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
                        // Price Banner Card
                        _buildRentBanner(),

                        const SizedBox(height: 18),

                        // Title & Date
                        _buildTitleBlock(),

                        const SizedBox(height: 18),

                        // Highlights row pills
                        _buildHighlightBadges(),

                        const SizedBox(height: 20),

                        // Manager / Poster Card
                        _buildManagerCard(),

                        const SizedBox(height: 16),

                        // Location Card
                        _buildLocationCard(),

                        const SizedBox(height: 20),

                        // Listing details (spec tiles)
                        ValueListenableBuilder<int>(
                          valueListenable: AppTranslations.notifier,
                          builder: (context, _, _) => _sectionHeader(
                            icon: Icons.grid_view_rounded,
                            title: 'ui.ad_detail_room_rent'.tr2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildSpecsGrid(),

                        const SizedBox(height: 20),

                        // Description
                        if (ad.description != null &&
                            ad.description!.isNotEmpty) ...[
                          ValueListenableBuilder<int>(
                            valueListenable: AppTranslations.notifier,
                            builder: (context, _, _) => _sectionHeader(
                              icon: Icons.subject_rounded,
                              title: 'ui.ad_detail_description'.tr2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.paperRaised,
                              borderRadius: BorderRadius.circular(DashUI.rCard),
                              border: Border.all(color: AppColors.paperLine),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
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
                          const SizedBox(height: 20),
                        ],

                        // Amenities
                        if (ad.amenities.isNotEmpty) ...[
                          ValueListenableBuilder<int>(
                            valueListenable: AppTranslations.notifier,
                            builder: (context, _, _) => _sectionHeader(
                              icon: Icons.checklist_rounded,
                              title: 'ui.ad_detail_amenities'.tr2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildAmenitiesWrap(),
                          const SizedBox(height: 24),
                        ],

                        // Related seats
                        if (_isLoadingRelated)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.brandDark,
                                ),
                              ),
                            ),
                          )
                        else if (_relatedAds.isNotEmpty) ...[
                          ValueListenableBuilder<int>(
                            valueListenable: AppTranslations.notifier,
                            builder: (context, _, _) {
                              final area =
                                  ad.areaLabel ??
                                  ad.area ??
                                  ad.city ??
                                  'the same area';
                              final sub = 'ui.ad_detail_nearby_sub'.tr2
                                  .replaceAll('{area}', area);
                              return _sectionHeader(
                                icon: Icons.explore_rounded,
                                title: 'ui.ad_detail_nearby'.tr2,
                                subtitle: sub,
                              );
                            },
                          ),
                          const SizedBox(height: 14),
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
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Top App Bar (Back button + Share)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () => _shareAd(context),
                    child: const Icon(
                      Icons.share_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(DashUI.rBtn),
          ),
          child: Icon(icon, size: 18, color: AppColors.brandDark),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17.5,
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
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE2701C), Color(0xFFC75911)],
                  ),
                  borderRadius: BorderRadius.circular(DashUI.rCard),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFE2701C).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ValueListenableBuilder<int>(
                  valueListenable: AppTranslations.notifier,
                  builder: (context, _, _) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ui.featured_label'.tr2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        if (ad.publishedAt != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: AppColors.inkFaded,
              ),
              const SizedBox(width: 5),
              ValueListenableBuilder<int>(
                valueListenable: AppTranslations.notifier,
                builder: (context, _, _) => Text(
                  'ui.ad_detail_posted'.tr2.replaceAll(
                    '{date}',
                    bnDigits(ad.publishedAt),
                  ),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.inkFaded,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildHighlightBadges() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          ValueListenableBuilder<int>(
            valueListenable: AppTranslations.notifier,
            builder: (context, _, _) => _badgeChip(
              icon: Icons.meeting_room_rounded,
              label:
                  '${ad.roomType.toUpperCase()} ${'ui.ad_detail_room_suffix'.tr2}',
              bgColor: AppColors.brandSoft,
              textColor: AppColors.brandDark,
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<int>(
            valueListenable: AppTranslations.notifier,
            builder: (context, _, _) {
              final seatsLabel = ad.seatsAvailable == 1
                  ? 'ui.card_seats_open'.tr2.replaceAll(
                      '{count}',
                      bnDigits(ad.seatsAvailable),
                    )
                  : 'ui.card_seats_open_plural'.tr2.replaceAll(
                      '{count}',
                      bnDigits(ad.seatsAvailable),
                    );
              return _badgeChip(
                icon: Icons.event_seat_rounded,
                label: seatsLabel,
                bgColor: const Color(0xFFE6F4EA),
                textColor: const Color(0xFF137333),
              );
            },
          ),
          const SizedBox(width: 8),
          if (ad.areaLabel != null || ad.city != null)
            _badgeChip(
              icon: Icons.location_on_rounded,
              label: ad.areaLabel ?? ad.city!,
              bgColor: AppColors.paperRaised,
              textColor: AppColors.inkSoft,
              borderColor: AppColors.paperLine,
            ),
        ],
      ),
    );
  }

  Widget _badgeChip({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(DashUI.rTile),
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroGallery(BuildContext context) {
    if (ad.imageUrls.isNotEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        child: Stack(
          children: [
            SizedBox(
              height: 310,
              width: double.infinity,
              child: PageView.builder(
                controller: _galleryController,
                itemCount: ad.imageUrls.length,
                onPageChanged: (index) => setState(() => _galleryIndex = index),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _openPhotoViewer(index),
                    child: NetworkImageCover(
                      url: ad.imageUrls[index],
                      height: 310,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      iconSize: 52,
                    ),
                  );
                },
              ),
            ),
            // Gradient Overlay at top for back button visibility
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 90,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            if (ad.imageUrls.length > 1) ...[
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(DashUI.rCard),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.photo_library_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      ValueListenableBuilder<int>(
                        valueListenable: AppTranslations.notifier,
                        builder: (context, _, _) => Text(
                          '${bnDigits(_galleryIndex + 1)}/${bnDigits(ad.imageUrls.length)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
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
                    activeIndex: _galleryIndex,
                    light: true,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      height: 240,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: ValueListenableBuilder<int>(
        valueListenable: AppTranslations.notifier,
        builder: (context, _, _) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.house_rounded,
              color: AppColors.inkFaded,
              size: 54,
            ),
            const SizedBox(height: 8),
            Text(
              'ui.ad_detail_verified_listing'.tr2,
              style: const TextStyle(
                color: AppColors.inkFaded,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
        borderRadius: BorderRadius.circular(DashUI.rCard),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandDark.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: AppTranslations.notifier,
                  builder: (context, _, _) => Text(
                    'ui.ad_detail_price_label'.tr2,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.65),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    ValueListenableBuilder<int>(
                      valueListenable: AppTranslations.notifier,
                      builder: (context, _, _) => Text(
                        'à§³${bnDigits(ad.rentPerSeat.toInt())}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    ValueListenableBuilder<int>(
                      valueListenable: AppTranslations.notifier,
                      builder: (context, _, _) => Text(
                        'ui.ad_detail_price_month'.tr2,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 42,
            color: Colors.white.withValues(alpha: 0.18),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ValueListenableBuilder<int>(
                valueListenable: AppTranslations.notifier,
                builder: (context, _, _) => Text(
                  'ui.ad_detail_availability'.tr2,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.65),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: ad.seatsAvailable > 0
                      ? AppColors.emerald
                      : AppColors.accent,
                  borderRadius: BorderRadius.circular(DashUI.rCard),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ValueListenableBuilder<int>(
                  valueListenable: AppTranslations.notifier,
                  builder: (context, _, _) {
                    final seatsText = ad.seatsAvailable == 1
                        ? 'ui.card_seats_open'.tr2.replaceAll(
                            '{count}',
                            bnDigits(ad.seatsAvailable),
                          )
                        : 'ui.card_seats_open_plural'.tr2.replaceAll(
                            '{count}',
                            bnDigits(ad.seatsAvailable),
                          );
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          seatsText,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    );
                  },
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
        borderRadius: BorderRadius.circular(DashUI.rCard),
        border: Border.all(color: AppColors.paperLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brandSoft,
            ),
            clipBehavior: Clip.antiAlias,
            child: ad.posterAvatarUrl != null
                ? NetworkImageCover(url: ad.posterAvatarUrl, iconSize: 22)
                : const Icon(
                    Icons.person_rounded,
                    color: AppColors.brandDark,
                    size: 24,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: AppTranslations.notifier,
                  builder: (context, _, _) => Text(
                    'ui.ad_detail_host'.tr2,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.inkFaded,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ad.posterName ?? (ad.messName ?? 'Mess Manager'),
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
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
              borderRadius: BorderRadius.circular(DashUI.rCard),
            ),
            child: ValueListenableBuilder<int>(
              valueListenable: AppTranslations.notifier,
              builder: (context, _, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    size: 14,
                    color: AppColors.emerald,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ui.ad_detail_verified'.tr2,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.emerald,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(DashUI.rCard),
        border: Border.all(color: AppColors.paperLine),
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
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(DashUI.rTile),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.accentDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.areaLabel ?? ad.city ?? 'Dhaka',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    if (ad.city != null)
                      Text(
                        ad.city!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.inkFaded,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (ad.hasVisibleAddress)
            Text(
              ad.location!,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.inkSoft,
                height: 1.45,
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(DashUI.rTile),
              ),
              child: ValueListenableBuilder<int>(
                valueListenable: AppTranslations.notifier,
                builder: (context, _, _) => Row(
                  children: [
                    const Icon(
                      Icons.security_rounded,
                      size: 18,
                      color: AppColors.brandDark,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ui.ad_detail_street_hidden'.tr2,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.brandDark,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpecsGrid() {
    return ValueListenableBuilder<int>(
      valueListenable: AppTranslations.notifier,
      builder: (context, _, _) {
        final specs = <(IconData, String, String)>[
          (
            Icons.meeting_room_rounded,
            'ui.ad_detail_room_type'.tr2,
            ad.roomType.toUpperCase(),
          ),
          if (ad.messName != null)
            (
              Icons.apartment_rounded,
              'ui.ad_detail_mess_name'.tr2,
              ad.messName!,
            ),
          (
            Icons.groups_rounded,
            'ui.ad_detail_room_capacity'.tr2,
            ad.roomCapacity != null
                ? '${bnDigits(ad.roomCapacity)} ${'ui.ad_detail_persons'.tr2}'
                : 'ui.ad_detail_flexible'.tr2,
          ),
          (
            Icons.payments_rounded,
            'ui.ad_detail_rent_period'.tr2,
            'ui.ad_detail_monthly'.tr2,
          ),
        ];

        return GridView.count(
          padding: EdgeInsets.zero,
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.8,
          children: specs.map((spec) {
            final (icon, label, value) = spec;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.paperRaised,
                borderRadius: BorderRadius.circular(DashUI.rCard),
                border: Border.all(color: AppColors.paperLine),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(DashUI.rBtn),
                    ),
                    child: Icon(icon, size: 18, color: AppColors.brandDark),
                  ),
                  const SizedBox(width: 10),
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
                        const SizedBox(height: 2),
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
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
      },
    );
  }

  IconData _getAmenityIcon(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('wifi') || lower.contains('internet')) {
      return Icons.wifi_rounded;
    }
    if (lower.contains('bath') || lower.contains('washroom')) {
      return Icons.bathtub_rounded;
    }
    if (lower.contains('gas') || lower.contains('kitchen')) {
      return Icons.soup_kitchen_rounded;
    }
    if (lower.contains('generator') || lower.contains('power')) {
      return Icons.power_rounded;
    }
    if (lower.contains('lift') || lower.contains('elevator')) {
      return Icons.elevator_rounded;
    }
    if (lower.contains('meal') || lower.contains('food')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('security') || lower.contains('cc')) {
      return Icons.security_rounded;
    }
    if (lower.contains('balcony')) return Icons.balcony_rounded;
    return Icons.check_circle_rounded;
  }

  Widget _buildAmenitiesWrap() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ad.amenities.map((item) {
        final icon = _getAmenityIcon(item);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.emeraldSoft,
            borderRadius: BorderRadius.circular(DashUI.rCard),
            border: Border.all(
              color: AppColors.emerald.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: AppColors.emerald),
              const SizedBox(width: 6),
              Text(
                item,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _shareAd(BuildContext context) async {
    final webUrl = 'http://${AppConfig.baseDomain}/ads/${ad.slug}';
    final text =
        '${ad.title} â€” à§³${ad.rentPerSeat.toInt()} /mo â€¢ ${ad.areaLabel ?? ad.city ?? 'Dhaka'}\n$webUrl';
    try {
      await SharePlus.instance.share(
        ShareParams(text: text, subject: ad.title),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ui.share_failed'.tr2)));
    }
  }

  Future<void> _makePhoneCall(BuildContext context) async {
    final rawPhone = ad.contactPhone?.trim();
    if (rawPhone == null || rawPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ui.ad_detail_phone_missing'.tr2),
          backgroundColor: AppColors.ink,
        ),
      );
      return;
    }

    final clean = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: clean);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'ui.ad_detail_phone_open_fail'.tr2} $rawPhone'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final rawWhatsapp =
        (ad.contactWhatsapp != null && ad.contactWhatsapp!.trim().isNotEmpty)
        ? ad.contactWhatsapp!.trim()
        : ad.contactPhone?.trim();

    if (rawWhatsapp == null || rawWhatsapp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ui.ad_detail_whatsapp_missing'.tr2),
          backgroundColor: AppColors.ink,
        ),
      );
      return;
    }

    // Extract digits only
    String digits = rawWhatsapp.replaceAll(RegExp(r'[^0-9]'), '');

    // Format Bangladeshi local 11-digit number 01xxxxxxxxx to international 8801xxxxxxxxx
    if (digits.startsWith('01') && digits.length == 11) {
      digits = '88$digits';
    } else if (digits.startsWith('1') && digits.length == 10) {
      digits = '880$digits';
    }

    final message =
        'Hi, I am interested in your seat listing on MessMax: "${ad.title}"';
    final whatsappUrl = Uri.parse(
      'https://wa.me/$digits?text=${Uri.encodeComponent(message)}',
    );

    try {
      final launched = await launchUrl(
        whatsappUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(whatsappUrl, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${'ui.ad_detail_whatsapp_open_fail'.tr2} $rawWhatsapp',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Widget _buildBottomContactBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        border: const Border(
          top: BorderSide(color: AppColors.paperLine, width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 1. Phone Call Action Button
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandDark,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                  fixedSize: const Size.fromHeight(48),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DashUI.rCard),
                  ),
                  elevation: 0,
                ),
                onPressed: () => _makePhoneCall(context),
                icon: SvgPicture.asset(
                  'assets/icons/phone_call.svg',
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                label: ValueListenableBuilder<int>(
                  valueListenable: AppTranslations.notifier,
                  builder: (context, _, _) => Text(
                    'ui.ad_detail_call_phone'.tr2,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // 2. WhatsApp Action Button (same height, official WhatsApp branding)
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                  fixedSize: const Size.fromHeight(48),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DashUI.rCard),
                  ),
                  elevation: 0,
                  shadowColor: const Color(0xFF25D366).withValues(alpha: 0.35),
                ),
                onPressed: () => _openWhatsApp(context),
                icon: SvgPicture.asset(
                  'assets/icons/whatsapp.svg',
                  width: 19,
                  height: 19,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                label: ValueListenableBuilder<int>(
                  valueListenable: AppTranslations.notifier,
                  builder: (context, _, _) => Text(
                    'ui.ad_detail_whatsapp'.tr2,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
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
                borderRadius: BorderRadius.circular(DashUI.rCard),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: ValueListenableBuilder<int>(
                valueListenable: AppTranslations.notifier,
                builder: (context, _, _) => Text(
                  '${bnDigits(_currentIndex + 1)} / ${bnDigits(widget.imageUrls.length)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
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
                  borderRadius: BorderRadius.circular(DashUI.rCard),
                ),
                child: ValueListenableBuilder<int>(
                  valueListenable: AppTranslations.notifier,
                  builder: (context, _, _) => Text(
                    'ui.ad_detail_pinch_hint'.tr2,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
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

/// Preloader skeleton shown exclusively on the first load of a seat ad.
class _SeatDetailSkeleton extends StatefulWidget {
  final VoidCallback onBack;

  const _SeatDetailSkeleton({required this.onBack});

  @override
  State<_SeatDetailSkeleton> createState() => _SeatDetailSkeletonState();
}

class _SeatDetailSkeletonState extends State<_SeatDetailSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    double radius = 10,
  }) {
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (context, _) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(_shimmerAnim.value - 1, 0),
              end: Alignment(_shimmerAnim.value + 1, 0),
              colors: const [
                Color(0xFFEAEAE6),
                Color(0xFFF7F7F4),
                Color(0xFFEAEAE6),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Gallery Skeleton
                Stack(
                  children: [
                    _shimmerBox(width: double.infinity, height: 310, radius: 0),
                    Positioned(
                      top: topPadding + 10,
                      left: 16,
                      child: AppBackButton(
                        color: Colors.black.withValues(alpha: 0.35),
                        iconColor: Colors.white,
                        onPressed: widget.onBack,
                      ),
                    ),
                    Positioned(
                      top: topPadding + 10,
                      right: 16,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.share_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(DashUI.rCard),
                          ),
                          child: ValueListenableBuilder<int>(
                            valueListenable: AppTranslations.notifier,
                            builder: (context, _, _) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'ui.ad_detail_loading'.tr2,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. Price Banner Skeleton Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.paperRaised,
                          borderRadius: BorderRadius.circular(DashUI.rCard),
                          border: Border.all(color: AppColors.paperLine),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _shimmerBox(width: 60, height: 10, radius: 4),
                                const SizedBox(height: 6),
                                _shimmerBox(width: 140, height: 24, radius: 6),
                              ],
                            ),
                            _shimmerBox(width: 90, height: 32, radius: 10),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // 3. Title Skeleton
                      _shimmerBox(
                        width: double.infinity,
                        height: 20,
                        radius: 6,
                      ),
                      const SizedBox(height: 8),
                      _shimmerBox(width: 220, height: 16, radius: 6),

                      const SizedBox(height: 16),

                      // 4. Highlight Badges Skeleton
                      Row(
                        children: [
                          _shimmerBox(width: 80, height: 28, radius: 8),
                          const SizedBox(width: 8),
                          _shimmerBox(width: 70, height: 28, radius: 8),
                          const SizedBox(width: 8),
                          _shimmerBox(width: 90, height: 28, radius: 8),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // 5. Manager / Host Card Skeleton
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.paperRaised,
                          borderRadius: BorderRadius.circular(DashUI.rCard),
                          border: Border.all(color: AppColors.paperLine),
                        ),
                        child: Row(
                          children: [
                            _shimmerBox(width: 44, height: 44, radius: 12),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _shimmerBox(
                                    width: 120,
                                    height: 14,
                                    radius: 4,
                                  ),
                                  const SizedBox(height: 6),
                                  _shimmerBox(
                                    width: 180,
                                    height: 11,
                                    radius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 6. Specs 2x2 Grid Skeleton
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        shrinkWrap: true,
                        childAspectRatio: 1.8,
                        physics: const NeverScrollableScrollPhysics(),
                        children: List.generate(
                          4,
                          (_) => Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.paperRaised,
                              borderRadius: BorderRadius.circular(DashUI.rCard),
                              border: Border.all(color: AppColors.paperLine),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _shimmerBox(width: 24, height: 24, radius: 6),
                                const SizedBox(height: 8),
                                _shimmerBox(width: 70, height: 10, radius: 4),
                              ],
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

          // 7. Sticky Bottom Action Bar Skeleton
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: const BoxDecoration(
                color: AppColors.paperRaised,
                border: Border(top: BorderSide(color: AppColors.paperLine)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _shimmerBox(
                      width: double.infinity,
                      height: 48,
                      radius: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _shimmerBox(
                      width: double.infinity,
                      height: 48,
                      radius: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
