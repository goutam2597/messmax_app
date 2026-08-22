import 'package:equatable/equatable.dart';
import '../../data/models/ads_response_model.dart';

sealed class AdsState extends Equatable {
  const AdsState();

  @override
  List<Object?> get props => [];
}

final class AdsInitial extends AdsState {
  const AdsInitial();
}

final class AdsLoading extends AdsState {
  const AdsLoading();
}

final class AdsLoaded extends AdsState {
  final AdsResponseModel response;
  final String? searchQuery;
  final String? selectedCity;
  final String? selectedArea;
  final String? selectedRoomType;
  final bool isLoadingMore;
  final bool isFiltering;

  const AdsLoaded({
    required this.response,
    this.searchQuery,
    this.selectedCity,
    this.selectedArea,
    this.selectedRoomType,
    this.isLoadingMore = false,
    this.isFiltering = false,
  });

  AdsLoaded copyWith({
    AdsResponseModel? response,
    String? searchQuery,
    String? selectedCity,
    String? selectedArea,
    String? selectedRoomType,
    bool? isLoadingMore,
    bool? isFiltering,
  }) {
    return AdsLoaded(
      response: response ?? this.response,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCity: selectedCity ?? this.selectedCity,
      selectedArea: selectedArea ?? this.selectedArea,
      selectedRoomType: selectedRoomType ?? this.selectedRoomType,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isFiltering: isFiltering ?? this.isFiltering,
    );
  }

  @override
  List<Object?> get props => [
        response,
        searchQuery,
        selectedCity,
        selectedArea,
        selectedRoomType,
        isLoadingMore,
        isFiltering,
      ];
}

final class AdsError extends AdsState {
  final String message;
  final String code;

  const AdsError(this.message, {this.code = 'ERR-NET-0000'});

  @override
  List<Object?> get props => [message, code];
}
