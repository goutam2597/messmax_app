import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_menu_button.dart';
import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../../../dashboard/presentation/widgets/mess_drawer.dart';
import '../../../../core/widgets/network_image_cover.dart';
import '../../data/models/ad_model.dart';
import '../../data/repositories/user_ad_repository.dart';
import 'ad_detail_screen.dart';
import 'ad_form_screen.dart';

class MyAdsScreen extends StatefulWidget {
  const MyAdsScreen({super.key});

  @override
  State<MyAdsScreen> createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends State<MyAdsScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final UserAdRepository _repository = UserAdRepository();
  List<AdModel> _ads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyAds();
  }

  Future<void> _loadMyAds() async {
    try {
      final list = await _repository.fetchMyAds();
      if (!mounted) return;
      setState(() {
        _ads = list;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAd(AdModel ad) async {
    final confirm = await ConfirmDeleteDialog.show(
      context,
      title: 'Delete Seat Ad?',
      itemName: ad.title,
      message:
          'Are you sure you want to delete this seat listing? It will no longer be visible to prospective members.',
      confirmLabel: 'Delete Ad',
      icon: Icons.campaign_rounded,
    );

    if (confirm != true || !mounted) return;

    try {
      await _repository.deleteAd(ad.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seat ad deleted successfully')),
      );
      _loadMyAds();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete ad: $e')),
      );
    }
  }

  void _openForm({AdModel? ad}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdFormScreen(ad: ad),
      ),
    );
    if (result == true) {
      _loadMyAds();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.paper,
      drawer: const MessDrawer(activeSection: 'my_ads'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: AppMenuButton(
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          'My Posted Seat Ads',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.brandDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Post Seat Ad',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.brandDark),
              )
            : RefreshIndicator(
                color: AppColors.brandDark,
                onRefresh: _loadMyAds,
                child: _ads.isEmpty
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 60, 20, 32),
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.brandSoft,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.home_work_rounded, color: AppColors.brandDark, size: 48),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'No Seat Ads Posted Yet',
                                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.ink),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Post your vacant hostel / mess seats on MessMax to reach thousands of students & jobholders looking for mess seats.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: AppColors.inkFaded, height: 1.4),
                              ),
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                onPressed: () => _openForm(),
                                icon: const Icon(Icons.add_rounded, size: 20),
                                label: const Text('Post First Seat Ad'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                        itemCount: _ads.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final ad = _ads[index];
                          return _myAdCard(ad);
                        },
                      ),
              ),
      ),
    );
  }

  Widget _myAdCard(AdModel ad) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.paperLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AdDetailScreen(ad: ad)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 90,
                      height: 80,
                      child: ad.coverImageUrl != null
                          ? NetworkImageCover(url: ad.coverImageUrl, iconSize: 24)
                          : Container(
                              color: AppColors.brandSoft,
                              child: const Icon(Icons.home_rounded, color: AppColors.brandDark, size: 28),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: ad.seatsAvailable > 0 ? const Color(0xFFE6F4EA) : AppColors.accentSoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${ad.seatsAvailable} OPEN',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: ad.seatsAvailable > 0 ? const Color(0xFF137333) : AppColors.accentDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              ad.roomType.toUpperCase(),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.inkFaded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ad.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '৳${ad.rentPerSeat.toInt()} / month • ${ad.areaLabel ?? ad.city ?? "Dhaka"}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.paperLine),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AdDetailScreen(ad: ad)),
                  ),
                  icon: const Icon(Icons.visibility_outlined, size: 16, color: AppColors.inkFaded),
                  label: const Text('View Ad', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.inkFaded)),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _openForm(ad: ad),
                      icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.brandDark),
                      label: const Text('Edit', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.brandDark)),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: () => _deleteAd(ad),
                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                      label: const Text('Delete', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.danger)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
