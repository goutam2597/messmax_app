import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/member_repository.dart';
import 'member_state.dart';

class MemberCubit extends Cubit<MemberState> {
  final MemberRepository _repository;
  int? _currentMessId;

  MemberCubit({MemberRepository? repository})
      : _repository = repository ?? MemberRepository(),
        super(MemberInitial());

  int? get currentMessId => _currentMessId;

  Future<void> loadMembers({int? messId}) async {
    if (messId != null) {
      _currentMessId = messId;
    }
    emit(MemberLoading());
    try {
      final response = await _repository.fetchMembers(messId: _currentMessId);
      _currentMessId = response.messId;
      emit(MemberLoaded(response: response));
    } catch (e) {
      emit(MemberError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<bool> saveMember({
    int? id,
    required Map<String, dynamic> data,
    String? avatarPath,
  }) async {
    try {
      await _repository.saveMember(
        id: id,
        data: data,
        avatarPath: avatarPath,
      );
      await loadMembers(messId: _currentMessId);
      return true;
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (state is MemberLoaded) {
        emit(MemberLoaded(
          response: (state as MemberLoaded).response,
          message: 'Error: $errorMsg',
        ));
      } else {
        emit(MemberError(errorMsg));
      }
      return false;
    }
  }

  Future<bool> deleteMember(int id) async {
    try {
      await _repository.deleteMember(id);
      await loadMembers(messId: _currentMessId);
      return true;
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (state is MemberLoaded) {
        emit(MemberLoaded(
          response: (state as MemberLoaded).response,
          message: 'Error: $errorMsg',
        ));
      } else {
        emit(MemberError(errorMsg));
      }
      return false;
    }
  }
}
