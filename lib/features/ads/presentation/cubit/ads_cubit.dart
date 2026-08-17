import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/ads_response_model.dart';
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

    final prev = state;
    final hasPrev = prev is AdsLoaded;

    if (hasPrev) {
      emit(AdsLoaded(
        response: prev.response,
        searchQuery: _searchQuery,
        selectedCity: _selectedCity,
        selectedArea: _selectedArea,
        selectedRoomType: _selectedRoomType,
        isLoadingMore: prev.isLoadingMore,
        isFiltering: true,
      ));
    } else {
      emit(const AdsLoading());
    }

    try {
      final res = await _repository.getAds(
        search: _searchQuery,
        city: _selectedCity,
        area: _selectedArea,
        roomType: _selectedRoomType,
        page: 1,
      );
      emit(AdsLoaded(
        response: res,
        searchQuery: _searchQuery,
        selectedCity: _selectedCity,
        selectedArea: _selectedArea,
        selectedRoomType: _selectedRoomType,
      ));
    } catch (e) {
      if (hasPrev) {
        emit(AdsLoaded(
          response: prev.response,
          searchQuery: _searchQuery,
          selectedCity: _selectedCity,
          selectedArea: _selectedArea,
          selectedRoomType: _selectedRoomType,
          isLoadingMore: prev.isLoadingMore,
        ));
      } else {
        emit(AdsError(e.toString()));
      }
    }
  }

  Future<void> fetchNextPage() async {
    final currentState = state;
    if (currentState is! AdsLoaded ||
        currentState.isLoadingMore ||
        !currentState.response.hasMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final nextPage = currentState.response.currentPage + 1;
      final nextRes = await _repository.getAds(
        search: _searchQuery,
        city: _selectedCity,
        area: _selectedArea,
        roomType: _selectedRoomType,
        page: nextPage,
      );

      final combinedAds = [...currentState.response.ads, ...nextRes.ads];
      final updatedResponse = AdsResponseModel(
        ads: combinedAds,
        total: nextRes.total,
        currentPage: nextRes.currentPage,
        lastPage: nextRes.lastPage,
        hasMore: nextRes.hasMore,
        availableCities: nextRes.availableCities.isNotEmpty
            ? nextRes.availableCities
            : currentState.response.availableCities,
        availableAreas: nextRes.availableAreas.isNotEmpty
            ? nextRes.availableAreas
            : currentState.response.availableAreas,
        availableRoomTypes: nextRes.availableRoomTypes.isNotEmpty
            ? nextRes.availableRoomTypes
            : currentState.response.availableRoomTypes,
      );

      emit(currentState.copyWith(
        response: updatedResponse,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<({List<String> items, bool hasMore})> fetchAreas({
    String? city,
    String? search,
    int page = 1,
  }) {
    return _repository.fetchAreas(city: city, search: search, page: page);
  }

  Future<({List<String> items, bool hasMore})> fetchCities({
    String? search,
    int page = 1,
  }) {
    return _repository.fetchCities(search: search, page: page);
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
