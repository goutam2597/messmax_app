import 'package:equatable/equatable.dart';
import '../../data/models/bazar_schedule_model.dart';

sealed class BazarScheduleState extends Equatable {
  const BazarScheduleState();

  @override
  List<Object?> get props => [];
}

class BazarScheduleInitial extends BazarScheduleState {
  const BazarScheduleInitial();
}

class BazarScheduleLoading extends BazarScheduleState {
  const BazarScheduleLoading();
}

class BazarScheduleLoaded extends BazarScheduleState {
  final BazarScheduleResponseModel schedule;
  final String? successMessage;

  const BazarScheduleLoaded({
    required this.schedule,
    this.successMessage,
  });

  @override
  List<Object?> get props => [schedule, successMessage];
}

class BazarScheduleError extends BazarScheduleState {
  final String message;

  const BazarScheduleError(this.message);

  @override
  List<Object?> get props => [message];
}
