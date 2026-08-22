import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/network_error.dart';
import '../../data/repositories/home_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _repository;

  HomeCubit({HomeRepository? repository})
      : _repository = repository ?? HomeRepository(),
        super(
          HomeRepository.getCached() != null
              ? HomeLoaded(HomeRepository.getCached()!)
              : const HomeInitial(),
        );

  Future<void> fetchHomeData({bool forceRefresh = false}) async {
    final cached = HomeRepository.getCached();
    if (!forceRefresh && cached != null) {
      emit(HomeLoaded(cached));
      return;
    }
    if (state is! HomeLoaded) {
      emit(const HomeLoading());
    }
    try {
      final data = await _repository.getHomeData(forceRefresh: forceRefresh);
      emit(HomeLoaded(data));
    } catch (e) {
      if (state is! HomeLoaded) {
        final serverDown = NetworkError.isServerUnreachable(e);
        emit(
          HomeError(
            NetworkError.subtleMessage(e),
            code: NetworkError.codeFor(e),
            isServerDown: serverDown,
          ),
        );
      }
    }
  }
}
