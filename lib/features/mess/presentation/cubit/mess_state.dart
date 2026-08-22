import 'package:equatable/equatable.dart';
import '../../data/models/mess_model.dart';

sealed class MessState extends Equatable {
  const MessState();
  @override
  List<Object?> get props => [];
}

final class MessInitial extends MessState {}
final class MessLoading extends MessState {}
final class MessListLoaded extends MessState {
  final List<MessModel> messes;
  final bool canCreate;
  final bool isIndividual;
  final String? message;
  const MessListLoaded({required this.messes, this.canCreate = false, this.isIndividual = false, this.message});
  @override
  List<Object?> get props => [messes, canCreate, isIndividual, message];
}
final class MessDetailLoaded extends MessState {
  final MessDetailModel detail;
  final String? message;
  const MessDetailLoaded(this.detail, {this.message});
  @override
  List<Object?> get props => [detail, message];
}
final class MessSheetLoaded extends MessState {
  final Map<String, dynamic> sheet;
  final String? message;
  const MessSheetLoaded(this.sheet, {this.message});
  @override
  List<Object?> get props => [sheet, message];
}
final class MessError extends MessState {
  final String message;
  final String code;
  const MessError(this.message, {this.code = 'ERR-NET-0000'});
  @override
  List<Object?> get props => [message, code];
}
