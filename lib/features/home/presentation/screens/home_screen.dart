import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../ads/data/models/ad_model.dart';
import '../../../ads/presentation/screens/ad_detail_screen.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HomeCubit>().fetchHomeData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.brandDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'MessMax',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading || state is HomeInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.brandDark),
            );
          }

          if (state is HomeError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off_rounded,
                        size: 48, color: AppColors.inkFaded),
                    const SizedBox(height: 12),
                    const Text(
                      'Failed to load home data',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkFaded,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandDark,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () =>
                          context.read<HomeCubit>().fetchHomeData(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is HomeLoaded) {
            final data = state.data;
            return RefreshIndicator(
              color: AppColors.brandDark,
              onRefresh: () => context.read<HomeCubit>().fetchHomeData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Unified Tagline Strip
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: const BoxDecoration(
                        color: AppColors.brandSoft,
                        border: Border(
                          top: BorderSide(color: AppColors.paperLine),
                          bottom: BorderSide(color: AppColors.paperLine),
                        ),
                      ),
                      child: Text(
                        data.tagline,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandDark,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Stats summary card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.paperLine),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statItem('Messes', '${data.totalMesses}'),
                            _divider(),
                            _statItem('Seats Open', '${data.totalSeatsAvailable}'),
                            _divider(),
                            _statItem('Listings', '${data.publishedAds}'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Featured section — Find Mess near you (Horizontal slider)
                    if (data.featuredAds.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Find Mess near you',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                                letterSpacing: -0.4,
                              ),
                            ),
                            Text(
                              'Featured',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 240,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: data.featuredAds.length,
                          itemBuilder: (context, index) {
                            final ad = data.featuredAds[index];
                            return _FeaturedAdCard(
                              ad: ad,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdDetailScreen(ad: ad),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // New Listings Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'New Seat Listings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (data.newAds.isEmpty)
                            const Text(
                              'No new seat listings posted yet.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.inkFaded,
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: data.newAds.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final ad = data.newAds[index];
                                return _AdListItemCard(
                                  ad: ad,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AdDetailScreen(ad: ad),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.brandDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.inkFaded,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.paperLine,
    );
  }
}

/// Horizontal slider card for Featured seats
class _FeaturedAdCard extends StatelessWidget {
  final AdModel ad;
  final VoidCallback onTap;

  const _FeaturedAdCard({required this.ad, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.paperLine),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image cover
            Stack(
              children: [
                if (ad.coverImageUrl != null)
                  Image.network(
                    ad.coverImageUrl!,
                    height: 125,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 125,
                      color: AppColors.brandSoft,
                      child: const Icon(Icons.home_rounded,
                          color: AppColors.inkFaded, size: 36),
                    ),
                  )
                else
                  Container(
                    height: 125,
                    color: AppColors.brandSoft,
                    child: const Center(
                      child: Icon(Icons.home_rounded,
                          color: AppColors.inkFaded, size: 36),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brandDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '৳${ad.rentPerSeat.toInt()}/mo',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 13, color: AppColors.inkFaded),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          ad.areaLabel ?? ad.city ?? 'Dhaka',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.inkFaded,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.brandSoft,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          ad.roomType.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ),
                      Text(
                        '${ad.seatsAvailable} seat${ad.seatsAvailable == 1 ? '' : 's'} left',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vertical List Item Card for Ad listings
class _AdListItemCard extends StatelessWidget {
  final AdModel ad;
  final VoidCallback onTap;

  const _AdListItemCard({required this.ad, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.paperLine),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Thumbnail
            SizedBox(
              width: 100,
              height: 95,
              child: ad.coverImageUrl != null
                  ? Image.network(
                      ad.coverImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.brandSoft,
                        child: const Icon(Icons.home_rounded,
                            color: AppColors.inkFaded),
                      ),
                    )
                  : Container(
                      color: AppColors.brandSoft,
                      child: const Icon(Icons.home_rounded,
                          color: AppColors.inkFaded),
                    ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ad.areaLabel ?? ad.city ?? 'Dhaka',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkFaded,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '৳${ad.rentPerSeat.toInt()} /mo',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.brandDark,
                          ),
                        ),
                        Text(
                          '${ad.seatsAvailable} seat${ad.seatsAvailable == 1 ? '' : 's'} available',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
