import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/ad_model.dart';

class AdDetailScreen extends StatelessWidget {
  final AdModel ad;

  const AdDetailScreen({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          ad.city != null ? '${ad.areaLabel ?? ad.city}' : 'Seat Details',
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel / Cover
            if (ad.imageUrls.isNotEmpty)
              SizedBox(
                height: 220,
                child: PageView.builder(
                  itemCount: ad.imageUrls.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.paperLine),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        ad.imageUrls[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.brandSoft,
                          child: const Icon(Icons.image_not_supported_rounded,
                              color: AppColors.inkFaded, size: 48),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.paperLine),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.house_rounded, color: AppColors.inkFaded, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'MessMax Verified Listing',
                      style: TextStyle(color: AppColors.inkFaded, fontSize: 13),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Title & Featured badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    ad.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      height: 1.25,
                    ),
                  ),
                ),
                if (ad.isFeatured)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brandDark,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'FEATURED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Rent & Seats Banner Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.paperLine),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
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
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkFaded,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '৳${ad.rentPerSeat.toInt()} /mo',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.brandDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.paperLine,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SEATS OPEN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkFaded,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ad.seatsAvailable} seat${ad.seatsAvailable == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Details section
            const Text(
              'Listing Overview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),

            _detailRow(Icons.meeting_room_rounded, 'Room Type', ad.roomType.toUpperCase()),
            if (ad.messName != null)
              _detailRow(Icons.apartment_rounded, 'Mess Name', ad.messName!),
            _detailRow(
              Icons.location_on_rounded,
              'Address',
              ad.hasVisibleAddress
                  ? (ad.location ?? ad.areaLabel ?? 'Address visible')
                  : 'Address hidden by poster (Area: ${ad.areaLabel ?? "Dhaka"})',
            ),

            const SizedBox(height: 20),

            // Description
            if (ad.description != null && ad.description!.isNotEmpty) ...[
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ad.description!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Amenities
            if (ad.amenities.isNotEmpty) ...[
              const Text(
                'Amenities & Facilities',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ad.amenities.map((item) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandDark,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Contact Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Mess Manager',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Contact directly to visit the mess or confirm your seat.',
                    style: TextStyle(
                      color: AppColors.paperLine,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (ad.contactPhone != null)
                    Row(
                      children: [
                        const Icon(Icons.phone_rounded,
                            color: AppColors.brand, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          ad.contactPhone!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  if (ad.contactWhatsapp != null &&
                      ad.contactWhatsapp != ad.contactPhone) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.chat_bubble_rounded,
                            color: Colors.greenAccent, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'WhatsApp: ${ad.contactWhatsapp}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.brandDark),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.inkFaded,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
