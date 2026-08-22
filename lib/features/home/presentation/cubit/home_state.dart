import 'package:equatable/equatable.dart';
import '../../data/models/home_data_model.dart';

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

final class HomeInitial extends HomeState {
  const HomeInitial();
}

final class HomeLoading extends HomeState {
  const HomeLoading();
}

final class HomeLoaded extends HomeState {
  final HomeDataModel data;

  const HomeLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

final class HomeError extends HomeState {
  final String message;

  /// Stable machine-friendly code (e.g. ERR-NET-1001) shown in the UI.
  final String code;

  /// True when the whole backend is unreachable (timeout / no connection).
  /// Callers show the full backend message; other errors stay subtle.
  final bool isServerDown;

  const HomeError(
    this.message, {
    this.code = 'ERR-NET-0000',
    this.isServerDown = false,
  });

  @override
  List<Object?> get props => [message, code, isServerDown];
}
