import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ad_cards.dart';
import '../../../../core/widgets/filter_pill_bar.dart';
import '../../../../core/widgets/messmax_app_bar.dart';
import '../cubit/ads_cubit.dart';
import '../cubit/ads_state.dart';

class AdsScreen extends StatefulWidget {
  const AdsScreen({super.key});

  @override
  State<AdsScreen> createState() => _AdsScreenState();
}

class _AdsScreenState extends State<AdsScreen> {
  static const _roomTypeLabels = [
    'All Room Types',
    'Single',
    'Shared',
    'Bunk',
    'Semi-Private',
  ];

  static const _roomTypeValues = <String?>[
    null,
    'single',
    'shared',
    'bunk',
    'semi-private',
  ];

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
            _buildSearchHeader(context),

            Expanded(
              child: BlocBuilder<AdsCubit, AdsState>(
                builder: (context, state) {
                  if (state is AdsLoading || state is AdsInitial) {
                    return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.brandDark),
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
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
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

                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                              itemCount: ads.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final ad = ads[index];
                                return AdListCard(
                                  ad: ad,
                                  onTap: () => openAdDetail(context, ad),
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
    final state = context.watch<AdsCubit>().state;
    final selectedRoomType =
        state is AdsLoaded ? state.selectedRoomType : null;
    final selectedIndex = _roomTypeValues.indexOf(selectedRoomType);

    return MessMaxAppBar(
      title: 'Find Mess Seats',
      showBorder: true,
      actions: const [
        AppBarActionButton(icon: Icons.tune_rounded),
      ],
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          FilterPillBar(
            labels: _roomTypeLabels,
            selectedIndex: selectedIndex,
            insetPadding: false,
            onSelected: (index) => context
                .read<AdsCubit>()
                .filterRoomType(_roomTypeValues[index]),
          ),
        ],
      ),
    );
  }
}
