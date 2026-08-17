import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ad_cards.dart';
import '../../../../core/widgets/filter_pill_bar.dart';
import '../../../../core/widgets/messmax_app_bar.dart';
import '../../../../core/widgets/search_filter_bar.dart';
import '../../../ads/data/models/ad_model.dart';
import '../../../ads/presentation/cubit/ads_cubit.dart';
import '../../../main/presentation/screens/main_shell_screen.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../../data/models/home_data_model.dart';
import '../widgets/home_filter_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _categories = [
    'All',
    'Single',
    'Shared',
    'Bunk',
    'Semi-private',
  ];

  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<HomeCubit>().fetchHomeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterDialog(BuildContext context, HomeDataModel data) {
    HomeFilterDialog.show(
      context,
      cities: data.availableCities,
      areas: data.availableAreas,
      roomTypes: data.availableRoomTypes,
      initialQuery: _searchController.text.trim(),
      onApply: ({city, area, roomType, query}) {
        _applyFilterAndNavigate(
          context,
          city: city,
          area: area,
          roomType: roomType,
          query: query,
        );
      },
    );
  }

  void _applyFilterAndNavigate(
    BuildContext context, {
    String? city,
    String? area,
    String? roomType,
    String? query,
  }) {
    context.read<AdsCubit>().fetchAds(
      search: query,
      city: city,
      area: area,
      roomType: roomType,
    );
    MainShellScope.of(context)?.selectTab(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: BlocBuilder<HomeCubit, HomeState>(
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
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: AppColors.brandSoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cloud_off_rounded,
                            size: 44,
                            color: AppColors.inkFaded,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Unable to connect to MessMax server',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.inkFaded,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandDark,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () =>
                              context.read<HomeCubit>().fetchHomeData(),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is HomeLoaded) {
                final data = state.data;
                final filteredNewAds = _filterAds(data.newAds);

                return Column(
                  children: [
                    _buildHeader(),

                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.accent,
                        backgroundColor: Colors.white,
                        onRefresh: () =>
                            context.read<HomeCubit>().fetchHomeData(),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),

                              if (data.featuredAds.isNotEmpty) ...[
                                _buildFeaturedSection(data, data.featuredAds),
                                const SizedBox(height: 12),
                              ],

                              _buildCategoryFilterBar(),

                              const SizedBox(height: 16),

                              _buildNewListingsSection(filteredNewAds),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  List<AdModel> _filterAds(List<AdModel> ads) {
    if (_selectedCategory == 'All') return ads;
    final cat = _selectedCategory.toLowerCase();
    return ads.where((a) => a.roomType.toLowerCase() == cat).toList();
  }

  Widget _buildHeader() {
    return const MessMaxAppBar(
      title: 'MessMax',
      subtitle: 'Seats & Meals Hub',
      leading: BrandMark(),
      actions: [
        LocationChip(label: 'Dhaka'),
        AppBarActionButton(
          icon: Icons.notifications_none_rounded,
          svgAsset: 'assets/icons/bell.svg',
          showDot: true,
        ),
      ],
    );
  }

  Widget _buildFeaturedSection(HomeDataModel data, List<AdModel> ads) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Searchbar with filter button embedded inside, replacing top titles
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SearchFilterBar(
            controller: _searchController,
            hintText: 'Search seats, area, city or mess name…',
            onSubmitted: (query) =>
                _applyFilterAndNavigate(context, query: query),
            onFilterTap: () => _openFilterDialog(context, data),
            onClearTap: () {
              _searchController.clear();
              _applyFilterAndNavigate(context, query: '');
            },
          ),
        ),

        const SizedBox(height: 14),

        // Single slide full screen width slider with 12px padding
        CarouselSlider.builder(
          itemCount: ads.length,
          options: CarouselOptions(
            height: 260,
            viewportFraction: 1.0,
            padEnds: false,
            enlargeCenterPage: false,
            enableInfiniteScroll: true,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 600),
          ),
          itemBuilder: (context, index, _) {
            final ad = ads[index % ads.length];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: AdFeaturedCard(
                ad: ad,
                onTap: () => openAdDetail(context, ad),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryFilterBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Explore Seat Types',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 10),
        FilterPillBar(
          labels: _categories,
          selectedIndex: _categories.indexOf(_selectedCategory),
          onSelected: (index) =>
              setState(() => _selectedCategory = _categories[index]),
        ),
      ],
    );
  }

  Widget _buildNewListingsSection(List<AdModel> ads) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedCategory == 'All'
                    ? 'New Seat Listings'
                    : '$_selectedCategory Seats',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                '${ads.length} available',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkFaded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (ads.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.paperRaised,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.paperLine),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.search_off_rounded,
                    size: 40,
                    color: AppColors.inkFaded,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No $_selectedCategory seats currently listed.',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            )
          else
            MasonryGridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              itemCount: ads.length,
              itemBuilder: (context, index) {
                final ad = ads[index];
                return AdGridCard(
                  ad: ad,
                  imageHeight: index % 3 == 0 ? 150 : 120,
                  onTap: () => openAdDetail(context, ad),
                );
              },
            ),
        ],
      ),
    );
  }
}
