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
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar & Search Header
            _buildSearchHeader(context),

            // Main Ads List Content
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
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                size: 48, color: AppColors.inkFaded),
                            const SizedBox(height: 12),
                            const Text(
                              'Could not load mess seats',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 16),
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
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: const BoxDecoration(
                                  color: AppColors.brandSoft,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.search_off_rounded,
                                    size: 48, color: AppColors.inkFaded),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No matching seats found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Try clearing your filters or searching for a broader location.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.inkFaded,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.brandDark,
                                  foregroundColor: Colors.white,
                                ),
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
                      color: AppColors.accent,
                      onRefresh: () => context.read<AdsCubit>().fetchAds(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Result Count Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                            child: Row(
                              children: [
                                Text(
                                  'Showing ${ads.length} seat listing${ads.length == 1 ? '' : 's'}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.inkFaded,
                                  ),
                                ),
                                const Spacer(),
                                if (state.selectedCity != null ||
                                    state.selectedRoomType != null ||
                                    (state.searchQuery != null &&
                                        state.searchQuery!.isNotEmpty))
                                  GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      context.read<AdsCubit>().clearFilters();
                                    },
                                    child: const Text(
                                      'Clear Filters',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.accentDark,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Listings List
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                              itemCount: ads.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final ad = ads[index];
                                return _AdCardItem(
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
                        ],
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: AppColors.paperRaised,
        border: Border(
          bottom: BorderSide(color: AppColors.paperLine),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Row(
            children: [
              Text(
                'Find Mess Seats',
                style: TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
              Spacer(),
              Icon(Icons.tune_rounded, color: AppColors.inkFaded, size: 20),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field
          TextField(
            controller: _searchController,
            onSubmitted: (val) => context.read<AdsCubit>().updateSearch(val),
            decoration: InputDecoration(
              hintText: 'Search area, city or mess name…',
              hintStyle: const TextStyle(
                color: AppColors.inkFaded,
                fontSize: 13.5,
              ),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.inkFaded, size: 20),
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
              fillColor: AppColors.paper,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.paperLine),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.paperLine),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.brandDark, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Room Type Filter Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterPill('All Room Types', null),
                const SizedBox(width: 6),
                _filterPill('Single', 'single'),
                const SizedBox(width: 6),
                _filterPill('Shared', 'shared'),
                const SizedBox(width: 6),
                _filterPill('Bunk', 'bunk'),
                const SizedBox(width: 6),
                _filterPill('Semi-Private', 'semi-private'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterPill(String label, String? typeVal) {
    final state = context.watch<AdsCubit>().state;
    final isSelected =
        (state is AdsLoaded && state.selectedRoomType == typeVal) ||
            (state is AdsLoaded &&
                state.selectedRoomType == null &&
                typeVal == null);

    return GestureDetector(
      onTap: () => context.read<AdsCubit>().filterRoomType(typeVal),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandDark : AppColors.paper,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.brandDark : AppColors.paperLine,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}

/// Modern Ad Item Card with Cover Image, Pricing & Details
class _AdCardItem extends StatelessWidget {
  final dynamic ad;
  final VoidCallback onTap;

  const _AdCardItem({required this.ad, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.paperRaised,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.paperLine),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Stack(
              children: [
                SizedBox(
                  height: 155,
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

                // Available Seats Status Tag
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ad.seatsAvailable > 1
                          ? AppColors.emerald
                          : AppColors.accent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      '${ad.seatsAvailable} SEAT${ad.seatsAvailable == 1 ? '' : 'S'} OPEN',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                // Rent Badge
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.brandDark,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      '৳${ad.rentPerSeat.toInt()} /mo',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 14, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          ad.areaLabel ?? ad.city ?? 'Dhaka',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.brandSoft,
                          borderRadius: BorderRadius.circular(6),
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

                  if (ad.messName != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.apartment_rounded,
                            size: 13, color: AppColors.inkFaded),
                        const SizedBox(width: 4),
                        Text(
                          ad.messName!,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
