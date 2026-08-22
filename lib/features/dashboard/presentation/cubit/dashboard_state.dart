import 'package:equatable/equatable.dart';
import '../../data/models/dashboard_model.dart';

sealed class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final DashboardModel dashboard;
  const DashboardLoaded(this.dashboard);

  @override
  List<Object?> get props => [dashboard];
}

class DashboardError extends DashboardState {
  final String message;
  final String code;
  const DashboardError(this.message, {this.code = 'ERR-NET-0000'});

  @override
  List<Object?> get props => [message, code];
}
