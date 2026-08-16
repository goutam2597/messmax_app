import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/home_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _repository;

  HomeCubit({HomeRepository? repository})
      : _repository = repository ?? HomeRepository(),
        super(const HomeInitial());

  Future<void> fetchHomeData() async {
    emit(const HomeLoading());
    try {
      final data = await _repository.getHomeData();
      emit(HomeLoaded(data));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}
