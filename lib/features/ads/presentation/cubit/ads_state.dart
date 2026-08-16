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

  const AdsLoaded({
    required this.response,
    this.searchQuery,
    this.selectedCity,
    this.selectedArea,
    this.selectedRoomType,
  });

  @override
  List<Object?> get props => [
        response,
        searchQuery,
        selectedCity,
        selectedArea,
        selectedRoomType,
      ];
}

final class AdsError extends AdsState {
  final String message;

  const AdsError(this.message);

  @override
  List<Object?> get props => [message];
}
