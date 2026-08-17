import 'package:equatable/equatable.dart';
import '../../data/models/member_model.dart';

sealed class MemberState extends Equatable {
  const MemberState();

  @override
  List<Object?> get props => [];
}

final class MemberInitial extends MemberState {}

final class MemberLoading extends MemberState {}

final class MemberLoaded extends MemberState {
  final MemberResponseModel response;
  final String? message;

  const MemberLoaded({
    required this.response,
    this.message,
  });

  @override
  List<Object?> get props => [response, message];
}

final class MemberError extends MemberState {
  final String message;

  const MemberError(this.message);

  @override
  List<Object?> get props => [message];
}
