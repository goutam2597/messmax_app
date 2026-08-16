import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dot_indicator_row.dart';
import '../../data/models/ad_model.dart';

class AdDetailScreen extends StatefulWidget {
  final AdModel ad;

  const AdDetailScreen({super.key, required this.ad});

  @override
  State<AdDetailScreen> createState() => _AdDetailScreenState();
}

class _AdDetailScreenState extends State<AdDetailScreen> {
  int _galleryIndex = 0;

  AdModel get ad => widget.ad;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Cover Gallery / Image Stack
                _buildHeroGallery(context),

                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Featured Badge
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
                          if (ad.isFeatured)
                            Container(
                              margin: const EdgeInsets.only(left: 8, top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
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
                      ),

                      const SizedBox(height: 16),

                      // Rent & Seats Banner Card
                      _buildRentBanner(),

                      const SizedBox(height: 20),

                      // Location & Address Card
                      _buildLocationCard(),

                      const SizedBox(height: 20),

                      // Overview Specs
                      const Text(
                        'Listing Details',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSpecsCard(),

                      const SizedBox(height: 20),

                      // Description
                      if (ad.description != null &&
                          ad.description!.isNotEmpty) ...[
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                              height: 1.55,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Amenities Grid
                      if (ad.amenities.isNotEmpty) ...[
                        const Text(
                          'Amenities & Facilities',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ad.amenities.map((item) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.brandSoft,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.paperLine),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_rounded,
                                      size: 16, color: AppColors.brandDark),
                                  const SizedBox(width: 6),
                                  Text(
                                    item,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.brandDark,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Floating Top Back Button
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
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),

          // Sticky Bottom Contact Bar
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

  Widget _buildHeroGallery(BuildContext context) {
    if (ad.imageUrls.isNotEmpty) {
      return Stack(
        children: [
          SizedBox(
            height: 260,
            width: double.infinity,
            child: PageView.builder(
              itemCount: ad.imageUrls.length,
              onPageChanged: (index) =>
                  setState(() => _galleryIndex = index),
              itemBuilder: (context, index) {
                return Image.network(
                  ad.imageUrls[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.brandSoft,
                    child: const Icon(Icons.home_rounded,
                        color: AppColors.inkFaded, size: 48),
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
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_galleryIndex + 1}/${ad.imageUrls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
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
      );
    }

    return Container(
      height: 220,
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
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.paperLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RENT PER SEAT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkFaded,
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
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.accentDark,
                      ),
                    ),
                    const Text(
                      ' / month',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkFaded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(width: 1, height: 44, color: AppColors.paperLine),

          const SizedBox(width: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'STATUS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkFaded,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ad.seatsAvailable > 1
                      ? AppColors.emeraldSoft
                      : AppColors.amberSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${ad.seatsAvailable} Seat${ad.seatsAvailable == 1 ? '' : 's'} Open',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: ad.seatsAvailable > 1
                        ? AppColors.emerald
                        : AppColors.amber,
                  ),
                ),
              ),
            ],
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.paperLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                ad.areaLabel ?? ad.city ?? 'Dhaka',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined,
                      size: 16, color: AppColors.brandDark),
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

  Widget _buildSpecsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.paperLine),
      ),
      child: Column(
        children: [
          _specRow(Icons.meeting_room_rounded, 'Room Type',
              ad.roomType.toUpperCase()),
          const Divider(height: 16, color: AppColors.paperLine),
          if (ad.messName != null) ...[
            _specRow(Icons.apartment_rounded, 'Mess Name', ad.messName!),
            const Divider(height: 16, color: AppColors.paperLine),
          ],
          _specRow(
              Icons.people_outline_rounded,
              'Room Capacity',
              ad.roomCapacity != null
                  ? '${ad.roomCapacity} Persons Room'
                  : 'Flexible'),
        ],
      ),
    );
  }

  Widget _specRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.brandDark),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.inkFaded,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ],
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
                ),
                child: IconButton(
                  padding: const EdgeInsets.all(14),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Opening WhatsApp: ${ad.contactWhatsapp}')),
                    );
                  },
                  icon: const Icon(Icons.chat_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
