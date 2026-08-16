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

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
