import 'package:equatable/equatable.dart';
import '../../../ads/data/models/ad_model.dart';

class HomeDataModel extends Equatable {
  final String tagline;
  final String heroTitle;
  final String heroSubtitle;
  final int totalMesses;
  final int publishedAds;
  final int totalSeatsAvailable;
  final List<AdModel> featuredAds;
  final List<AdModel> newAds;

  const HomeDataModel({
    required this.tagline,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.totalMesses,
    required this.publishedAds,
    required this.totalSeatsAvailable,
    required this.featuredAds,
    required this.newAds,
  });

  factory HomeDataModel.fromJson(Map<String, dynamic> json) {
    final hero = json['hero'] as Map<String, dynamic>? ?? {};
    final stats = json['stats'] as Map<String, dynamic>? ?? {};

    final featuredList = (json['featured_ads'] as List<dynamic>?)
            ?.map((e) => AdModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    final newList = (json['new_ads'] as List<dynamic>?)
            ?.map((e) => AdModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return HomeDataModel(
      tagline: json['tagline'] as String? ??
          'Find & manage your mess · meals, seats and bazar in one place',
      heroTitle: hero['title'] as String? ??
          'Your mess, searched & settled in one place.',
      heroSubtitle: hero['subtitle'] as String? ??
          'Search seats posted by real mess managers, or manage daily meals and bazar.',
      totalMesses: stats['total_messes'] as int? ?? 0,
      publishedAds: stats['published_ads'] as int? ?? 0,
      totalSeatsAvailable: stats['total_seats_available'] as int? ?? 0,
      featuredAds: featuredList,
      newAds: newList,
    );
  }

  @override
  List<Object?> get props => [
        tagline,
        heroTitle,
        totalMesses,
        publishedAds,
        totalSeatsAvailable,
        featuredAds,
        newAds,
      ];
}
