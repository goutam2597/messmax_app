import 'package:equatable/equatable.dart';
import '../../../ads/data/models/ad_model.dart';

class RoomTypeOption extends Equatable {
  final String value;
  final String label;

  const RoomTypeOption({required this.value, required this.label});

  factory RoomTypeOption.fromJson(Map<String, dynamic> json) {
    return RoomTypeOption(
      value: json['value'] as String? ?? '',
      label: json['label'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [value, label];
}

class HomeDataModel extends Equatable {
  final String tagline;
  final String heroTitle;
  final String heroSubtitle;
  final int totalMesses;
  final int publishedAds;
  final int totalSeatsAvailable;
  final List<AdModel> featuredAds;
  final List<AdModel> newAds;
  final List<String> availableCities;
  final List<String> availableAreas;
  final List<RoomTypeOption> availableRoomTypes;

  const HomeDataModel({
    required this.tagline,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.totalMesses,
    required this.publishedAds,
    required this.totalSeatsAvailable,
    required this.featuredAds,
    required this.newAds,
    this.availableCities = const [],
    this.availableAreas = const [],
    this.availableRoomTypes = const [],
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

    final filters = json['filters'] as Map<String, dynamic>? ?? {};
    final available = filters['available'] as Map<String, dynamic>? ?? {};

    final cities = (available['cities'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];

    final areas = (available['areas'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];

    final roomTypes = (available['room_types'] as List<dynamic>?)
            ?.map((e) => RoomTypeOption.fromJson(e as Map<String, dynamic>))
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
      availableCities: cities,
      availableAreas: areas,
      availableRoomTypes: roomTypes,
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
        availableCities,
        availableAreas,
        availableRoomTypes,
      ];
}
