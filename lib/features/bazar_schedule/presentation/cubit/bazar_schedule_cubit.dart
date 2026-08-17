import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/logger/app_logger.dart';
import '../../data/repositories/bazar_schedule_repository.dart';
import 'bazar_schedule_state.dart';

class BazarScheduleCubit extends Cubit<BazarScheduleState> {
  final BazarScheduleRepository _repository;
  int? _currentMessId;
  int? _currentYear;
  int? _currentMonth;

  BazarScheduleCubit({BazarScheduleRepository? repository})
      : _repository = repository ?? BazarScheduleRepository(),
        super(const BazarScheduleInitial());

  Future<void> loadSchedule({int? messId, int? year, int? month}) async {
    emit(const BazarScheduleLoading());
    try {
      final data = await _repository.fetchSchedule(
        messId: messId ?? _currentMessId,
        year: year ?? _currentYear,
        month: month ?? _currentMonth,
      );
      _currentMessId = data.mess.id;
      _currentYear = data.year;
      _currentMonth = data.month;

      emit(BazarScheduleLoaded(schedule: data));
    } catch (e) {
      AppLogger.w('BazarScheduleCubit.loadSchedule failed: $e');
      emit(BazarScheduleError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> changeMonth(int delta) async {
    if (_currentYear == null || _currentMonth == null) return;

    var year = _currentYear!;
    var month = _currentMonth! + delta;

    if (month > 12) {
      month = 1;
      year += 1;
    } else if (month < 1) {
      month = 12;
      year -= 1;
    }

    await loadSchedule(messId: _currentMessId, year: year, month: month);
  }

  Future<void> assignSchedule({
    int? fromDay,
    int? toDay,
    List<int>? days,
    int? messMemberId,
    String? staffName,
    String? note,
  }) async {
    if (_currentMessId == null || _currentYear == null || _currentMonth == null) return;

    try {
      final msg = await _repository.assignSchedule(
        messId: _currentMessId!,
        year: _currentYear!,
        month: _currentMonth!,
        fromDay: fromDay,
        toDay: toDay,
        days: days,
        messMemberId: messMemberId,
        staffName: staffName,
        note: note,
      );

      final data = await _repository.fetchSchedule(
        messId: _currentMessId,
        year: _currentYear,
        month: _currentMonth,
      );
      emit(BazarScheduleLoaded(schedule: data, successMessage: msg));
    } catch (e) {
      AppLogger.w('BazarScheduleCubit.assignSchedule failed: $e');
      emit(BazarScheduleError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> notifyAssignee({
    required int day,
    String? notes,
    String? emailOverride,
  }) async {
    if (_currentMessId == null || _currentYear == null || _currentMonth == null) return;

    try {
      final msg = await _repository.notifyAssignee(
        messId: _currentMessId!,
        year: _currentYear!,
        month: _currentMonth!,
        day: day,
        notes: notes,
        emailOverride: emailOverride,
      );

      final data = await _repository.fetchSchedule(
        messId: _currentMessId,
        year: _currentYear,
        month: _currentMonth,
      );
      emit(BazarScheduleLoaded(schedule: data, successMessage: msg));
    } catch (e) {
      AppLogger.w('BazarScheduleCubit.notifyAssignee failed: $e');
      emit(BazarScheduleError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> notifyBulk({
    int? fromDay,
    int? toDay,
    List<int>? days,
    String? notes,
  }) async {
    if (_currentMessId == null || _currentYear == null || _currentMonth == null) return;

    try {
      final msg = await _repository.notifyBulk(
        messId: _currentMessId!,
        year: _currentYear!,
        month: _currentMonth!,
        fromDay: fromDay,
        toDay: toDay,
        days: days,
        notes: notes,
      );

      final data = await _repository.fetchSchedule(
        messId: _currentMessId,
        year: _currentYear,
        month: _currentMonth,
      );
      emit(BazarScheduleLoaded(schedule: data, successMessage: msg));
    } catch (e) {
      AppLogger.w('BazarScheduleCubit.notifyBulk failed: $e');
      emit(BazarScheduleError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> broadcastAnnouncement({
    String? subject,
    required String message,
  }) async {
    if (_currentMessId == null || _currentYear == null || _currentMonth == null) return;

    try {
      final msg = await _repository.broadcastAnnouncement(
        messId: _currentMessId!,
        year: _currentYear!,
        month: _currentMonth!,
        subject: subject,
        message: message,
      );

      final data = await _repository.fetchSchedule(
        messId: _currentMessId,
        year: _currentYear,
        month: _currentMonth,
      );
      emit(BazarScheduleLoaded(schedule: data, successMessage: msg));
    } catch (e) {
      AppLogger.w('BazarScheduleCubit.broadcastAnnouncement failed: $e');
      emit(BazarScheduleError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> deleteAssignment(int id) async {
    if (_currentMessId == null || _currentYear == null || _currentMonth == null) return;

    try {
      await _repository.deleteAssignment(id);
      final data = await _repository.fetchSchedule(
        messId: _currentMessId,
        year: _currentYear,
        month: _currentMonth,
      );
      emit(BazarScheduleLoaded(schedule: data, successMessage: 'Assignment removed'));
    } catch (e) {
      AppLogger.w('BazarScheduleCubit.deleteAssignment failed: $e');
      emit(BazarScheduleError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> clearMonth() async {
    if (_currentMessId == null || _currentYear == null || _currentMonth == null) return;

    try {
      await _repository.clearMonth(
        messId: _currentMessId!,
        year: _currentYear!,
        month: _currentMonth!,
      );
      final data = await _repository.fetchSchedule(
        messId: _currentMessId,
        year: _currentYear,
        month: _currentMonth,
      );
      emit(BazarScheduleLoaded(schedule: data, successMessage: 'Month schedule cleared'));
    } catch (e) {
      AppLogger.w('BazarScheduleCubit.clearMonth failed: $e');
      emit(BazarScheduleError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
