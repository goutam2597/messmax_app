import 'package:equatable/equatable.dart';
import '../../../home/data/models/home_data_model.dart';
import 'ad_model.dart';

class AdsResponseModel extends Equatable {
  final List<AdModel> ads;
  final int total;
  final int currentPage;
  final int lastPage;
  final bool hasMore;
  final List<String> availableCities;
  final List<String> availableAreas;
  final List<RoomTypeOption> availableRoomTypes;

  const AdsResponseModel({
    required this.ads,
    required this.total,
    required this.currentPage,
    required this.lastPage,
    required this.hasMore,
    required this.availableCities,
    required this.availableAreas,
    this.availableRoomTypes = const [],
  });

  factory AdsResponseModel.fromJson(Map<String, dynamic> json) {
    final adsList = (json['ads'] as List<dynamic>?)
            ?.map((e) => AdModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
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

    return AdsResponseModel(
      ads: adsList,
      total: pagination['total'] as int? ?? adsList.length,
      currentPage: pagination['current_page'] as int? ?? 1,
      lastPage: pagination['last_page'] as int? ?? 1,
      hasMore: pagination['has_more'] as bool? ?? false,
      availableCities: cities,
      availableAreas: areas,
      availableRoomTypes: roomTypes,
    );
  }

  @override
  List<Object?> get props => [
        ads,
        total,
        currentPage,
        lastPage,
        hasMore,
        availableCities,
        availableAreas,
        availableRoomTypes,
      ];
}
