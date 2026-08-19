import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/dashboard_repository.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository _repository;

  DashboardCubit({DashboardRepository? repository})
      : _repository = repository ?? DashboardRepository(),
        super(const DashboardInitial());

  Future<void> loadDashboard({int? messId, bool forceRefresh = false}) async {
    final cached = _repository.getCached(messId: messId);
    if (cached != null && !forceRefresh) {
      emit(DashboardLoaded(cached));
      return;
    }
    if (state is! DashboardLoaded && !forceRefresh) {
      emit(const DashboardLoading());
    }
    try {
      final dashboard = await _repository.fetchDashboard(
        messId: messId,
        forceRefresh: forceRefresh,
      );
      emit(DashboardLoaded(dashboard));
    } catch (e) {
      if (cached != null) {
        emit(DashboardLoaded(cached));
      } else {
        emit(DashboardError(e.toString()));
      }
    }
  }
}
