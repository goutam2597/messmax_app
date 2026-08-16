import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/ads_cubit.dart';
import '../cubit/ads_state.dart';
import 'ad_detail_screen.dart';

class AdsScreen extends StatefulWidget {
  const AdsScreen({super.key});

  @override
  State<AdsScreen> createState() => _AdsScreenState();
}

class _AdsScreenState extends State<AdsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AdsCubit>().fetchAds();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Find Mess & Seats',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search & Filters Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onSubmitted: (value) {
                    context.read<AdsCubit>().updateSearch(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search mess name, area, city…',
                    hintStyle: const TextStyle(
                      color: AppColors.inkFaded,
                      fontSize: 13.5,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.inkFaded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 18, color: AppColors.inkFaded),
                            onPressed: () {
                              _searchController.clear();
                              context.read<AdsCubit>().updateSearch('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.paperLine),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.paperLine),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.brandDark, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Room Type Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _roomTypeChip('All Types', null),
                      const SizedBox(width: 6),
                      _roomTypeChip('Single', 'single'),
                      const SizedBox(width: 6),
                      _roomTypeChip('Shared', 'shared'),
                      const SizedBox(width: 6),
                      _roomTypeChip('Bunk', 'bunk'),
                      const SizedBox(width: 6),
                      _roomTypeChip('Semi-private', 'semi-private'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Ads List
          Expanded(
            child: BlocBuilder<AdsCubit, AdsState>(
              builder: (context, state) {
                if (state is AdsLoading || state is AdsInitial) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.brandDark),
                  );
                }

                if (state is AdsError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 44, color: AppColors.inkFaded),
                        const SizedBox(height: 10),
                        const Text(
                          'Could not load listings',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandDark,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () =>
                              context.read<AdsCubit>().fetchAds(),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is AdsLoaded) {
                  final ads = state.response.ads;

                  if (ads.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_rounded,
                                size: 54, color: AppColors.inkFaded),
                            const SizedBox(height: 12),
                            const Text(
                              'No mess seats found',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Try clearing filters or searching for a different area.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.inkFaded,
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () {
                                _searchController.clear();
                                context.read<AdsCubit>().clearFilters();
                              },
                              child: const Text('Reset All Filters'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.brandDark,
                    onRefresh: () => context.read<AdsCubit>().fetchAds(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: ads.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final ad = ads[index];
                        return _AdCard(
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
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _roomTypeChip(String label, String? typeValue) {
    final state = context.watch<AdsCubit>().state;
    final isSelected = (state is AdsLoaded && state.selectedRoomType == typeValue) ||
        (state is AdsLoaded && state.selectedRoomType == null && typeValue == null);

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? Colors.white : AppColors.inkSoft,
      ),
      selectedColor: AppColors.brandDark,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.brandDark : AppColors.paperLine,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) {
        context.read<AdsCubit>().filterRoomType(typeValue);
      },
    );
  }
}

class _AdCard extends StatelessWidget {
  final dynamic ad;
  final VoidCallback onTap;

  const _AdCard({required this.ad, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.paperLine),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            Stack(
              children: [
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: ad.coverImageUrl != null
                      ? Image.network(
                          ad.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: AppColors.brandSoft,
                            child: const Icon(Icons.home_rounded,
                                color: AppColors.inkFaded, size: 40),
                          ),
                        )
                      : Container(
                          color: AppColors.brandSoft,
                          child: const Icon(Icons.home_rounded,
                              color: AppColors.inkFaded, size: 40),
                        ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${ad.seatsAvailable} Seat${ad.seatsAvailable == 1 ? '' : 's'} Available',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brandDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '৳${ad.rentPerSeat.toInt()} /mo',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 14, color: AppColors.brandDark),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          ad.areaLabel ?? ad.city ?? 'Dhaka',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ),
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
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandDark,
                          ),
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
