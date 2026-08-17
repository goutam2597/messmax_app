import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ad_cards.dart';
import '../../../../core/widgets/messmax_app_bar.dart';
import '../../../../core/widgets/search_filter_bar.dart';
import '../../../home/data/models/home_data_model.dart';
import '../../../home/presentation/widgets/home_filter_dialog.dart';
import '../cubit/ads_cubit.dart';
import '../cubit/ads_state.dart';

class AdsScreen extends StatefulWidget {
  const AdsScreen({super.key});

  @override
  State<AdsScreen> createState() => _AdsScreenState();
}

class _AdsScreenState extends State<AdsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<AdsCubit>().fetchAds();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<AdsCubit>().fetchNextPage();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterDialog(BuildContext context, AdsLoaded? state) {
    HomeFilterDialog.show(
      context,
      roomTypes: state?.response.availableRoomTypes ?? const [],
      initialCity: state?.selectedCity,
      initialArea: state?.selectedArea,
      initialRoomType: state?.selectedRoomType,
      initialQuery: _searchController.text.trim(),
      loadCities: (search, page) =>
          context.read<AdsCubit>().fetchCities(search: search, page: page),
      loadAreas: (city, search, page) => context.read<AdsCubit>().fetchAreas(
          city: city, search: search, page: page),
      onApply: ({city, area, roomType, query}) {
        if (query != null && query.isNotEmpty) {
          _searchController.text = query;
        } else {
          _searchController.clear();
        }
        context.read<AdsCubit>().fetchAds(
          search: query,
          city: city,
          area: area,
          roomType: roomType,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFiltering = switch (context.watch<AdsCubit>().state) {
      AdsLoaded(:final isFiltering) => isFiltering,
      _ => false,
    };

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchHeader(context),
              if (isFiltering)
                const LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.brandDark,
                  backgroundColor: Colors.transparent,
                ),
              Expanded(
                child: BlocBuilder<AdsCubit, AdsState>(
                  builder: (context, state) {
                    if (state is AdsLoading || state is AdsInitial) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.brandDark,
                        ),
                      );
                    }

                    if (state is AdsError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 48,
                                color: AppColors.inkFaded,
                              ),
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
                                  child: const Icon(
                                    Icons.search_off_rounded,
                                    size: 48,
                                    color: AppColors.inkFaded,
                                  ),
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
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                              child: Row(
                                children: [
                                  Text(
                                    'Showing ${ads.length} of ${state.response.total} seat listing${state.response.total == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.inkFaded,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (state.selectedCity != null ||
                                      state.selectedArea != null ||
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

                            Expanded(
                              child: Column(
                                children: [
                                  Expanded(
                                    child: MasonryGridView.count(
                                      controller: _scrollController,
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        4,
                                        12,
                                        24,
                                      ),
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      itemCount: ads.length,
                                      itemBuilder: (context, index) {
                                        final ad = ads[index];
                                        return AdGridCard(
                                          ad: ad,
                                          imageHeight: index % 3 == 0
                                              ? 150
                                              : 120,
                                          onTap: () =>
                                              openAdDetail(context, ad),
                                        );
                                      },
                                    ),
                                  ),
                                  if (state.isLoadingMore)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.brandDark,
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

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context) {
    final state = context.watch<AdsCubit>().state;
    final loadedState = state is AdsLoaded ? state : null;
    final selectedRoomType = loadedState?.selectedRoomType;
    final roomTypeOptions =
        loadedState?.response.availableRoomTypes ?? const <RoomTypeOption>[];
    final roomTypeLabels = [
      'All Room Types',
      ...roomTypeOptions.map((rt) => rt.label),
    ];
    final roomTypeValues = <String?>[
      null,
      ...roomTypeOptions.map((rt) => rt.value),
    ];
    final selectedIndex = roomTypeValues.indexOf(selectedRoomType);

    // Keep search field controller synced if searchQuery in state changes
    if (loadedState != null &&
        loadedState.searchQuery != _searchController.text &&
        !FocusScope.of(context).hasFocus) {
      _searchController.text = loadedState.searchQuery ?? '';
    }

    return MessMaxAppBar(
      title: 'Find Mess Seats',
      showBorder: true,
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchFilterBar(
            controller: _searchController,
            hintText: 'Search area, city or mess name…',
            onSubmitted: (val) => context.read<AdsCubit>().updateSearch(val),
            onFilterTap: () => _openFilterDialog(context, loadedState),
            onClearTap: () {
              _searchController.clear();
              context.read<AdsCubit>().updateSearch('');
            },
          ),
          if (loadedState != null)
            _buildActiveFilterChips(context, loadedState),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView.separated(
              clipBehavior: Clip.none,
              separatorBuilder: (_, _) => const SizedBox(width: 4),
              padding: EdgeInsets.zero,
              scrollDirection: Axis.horizontal,
              itemCount: roomTypeLabels.length,
              itemBuilder: (context, index) {
                final isSelected = selectedIndex == index;
                return GestureDetector(
                  onTap: () => context.read<AdsCubit>().filterRoomType(
                    roomTypeValues[index],
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.brandDark
                          : AppColors.paperRaised,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.brandDark
                            : AppColors.paperLine,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.brandDark.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        roomTypeLabels[index],
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.inkSoft,
                        ),
                      ),
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

  Widget _buildActiveFilterChips(BuildContext context, AdsLoaded state) {
    final query = state.searchQuery;
    final city = state.selectedCity;
    final area = state.selectedArea;

    final hasActiveFilter =
        (query != null && query.isNotEmpty) || city != null || area != null;

    // Room type alone is already visible via the pill bar below.
    if (!hasActiveFilter) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (query != null && query.isNotEmpty)
              _buildRemovableChip(
                label: 'Query: "$query"',
                onRemove: () {
                  _searchController.clear();
                  context.read<AdsCubit>().updateSearch('');
                },
              ),
            if (city != null)
              _buildRemovableChip(
                label: 'City: $city',
                onRemove: () => context.read<AdsCubit>().filterCity(null),
              ),
            if (area != null)
              _buildRemovableChip(
                label: 'Area: $area',
                onRemove: () => context.read<AdsCubit>().fetchAds(
                  search: state.searchQuery,
                  city: state.selectedCity,
                  area: null,
                  roomType: state.selectedRoomType,
                ),
              ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                _searchController.clear();
                context.read<AdsCubit>().clearFilters();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Clear All',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accentDark,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemovableChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
      decoration: BoxDecoration(
        color: AppColors.brandDark,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandDark.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 13,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
