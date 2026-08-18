import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/dashboard_repository.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository _repository;

  DashboardCubit({DashboardRepository? repository})
      : _repository = repository ?? DashboardRepository(),
        super(const DashboardInitial());

  Future<void> loadDashboard({int? messId}) async {
    emit(const DashboardLoading());
    try {
      final dashboard = await _repository.fetchDashboard(messId: messId);
      emit(DashboardLoaded(dashboard));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
