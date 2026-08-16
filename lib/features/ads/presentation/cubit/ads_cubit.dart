import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/ads_repository.dart';
import 'ads_state.dart';

class AdsCubit extends Cubit<AdsState> {
  final AdsRepository _repository;

  String? _searchQuery;
  String? _selectedCity;
  String? _selectedArea;
  String? _selectedRoomType;

  AdsCubit({AdsRepository? repository})
      : _repository = repository ?? AdsRepository(),
        super(const AdsInitial());

  Future<void> fetchAds({
    String? search,
    String? city,
    String? area,
    String? roomType,
  }) async {
    _searchQuery = search;
    _selectedCity = city;
    _selectedArea = area;
    _selectedRoomType = roomType;

    emit(const AdsLoading());
    try {
      final res = await _repository.getAds(
        search: _searchQuery,
        city: _selectedCity,
        area: _selectedArea,
        roomType: _selectedRoomType,
      );
      emit(AdsLoaded(
        response: res,
        searchQuery: _searchQuery,
        selectedCity: _selectedCity,
        selectedArea: _selectedArea,
        selectedRoomType: _selectedRoomType,
      ));
    } catch (e) {
      emit(AdsError(e.toString()));
    }
  }

  void updateSearch(String query) {
    fetchAds(
      search: query,
      city: _selectedCity,
      area: _selectedArea,
      roomType: _selectedRoomType,
    );
  }

  void filterCity(String? city) {
    fetchAds(
      search: _searchQuery,
      city: city,
      area: null, // reset area when city changes
      roomType: _selectedRoomType,
    );
  }

  void filterRoomType(String? roomType) {
    final newRoom = (_selectedRoomType == roomType) ? null : roomType;
    fetchAds(
      search: _searchQuery,
      city: _selectedCity,
      area: _selectedArea,
      roomType: newRoom,
    );
  }

  void clearFilters() {
    _searchQuery = null;
    _selectedCity = null;
    _selectedArea = null;
    _selectedRoomType = null;
    fetchAds();
  }
}
