import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/cache_manager.dart';
import '../../../../core/network/network_error.dart';
import '../../data/repositories/mess_repository.dart';
import 'mess_state.dart';

class MessCubit extends Cubit<MessState> {
  final MessRepository _repo;
  MessCubit({MessRepository? repo})
    : _repo = repo ?? MessRepository(),
      super(MessInitial());

  Future<void> loadMesses({bool forceRefresh = false}) async {
    final cached = _repo.getCachedMesses();
    if (cached != null && !forceRefresh) {
      emit(
        MessListLoaded(messes: cached, canCreate: true, isIndividual: false),
      );
      return;
    }
    if (state is! MessListLoaded) {
      emit(MessLoading());
    }
    try {
      final messes = await _repo.fetchMesses(forceRefresh: forceRefresh);
      emit(
        MessListLoaded(messes: messes, canCreate: true, isIndividual: false),
      );
    } catch (e) {
      if (cached != null) {
        emit(
          MessListLoaded(messes: cached, canCreate: true, isIndividual: false),
        );
      } else {
        emit(
          MessError(
            NetworkError.subtleMessage(e),
            code: NetworkError.codeFor(e),
          ),
        );
      }
    }
  }

  Future<void> loadMess(int id, {bool forceRefresh = false}) async {
    // In forceRefresh mode, bypass in-memory cache and push to loading so the
    // spinner appears instead of instantly re-rendering stale data.
    // The repo will also receive forceRefresh=true so it must skip _messDetailCache.
    if (!forceRefresh) {
      final cachedImmediate = _repo.getCachedMess(id);
      if (cachedImmediate != null) {
        emit(MessDetailLoaded(cachedImmediate));
        return;
      }
    }
    final cachedAtCatch = _repo.getCachedMess(id);
    if (state is! MessDetailLoaded) {
      emit(MessLoading());
    }
    try {
      final d = await _repo.fetchMess(id, forceRefresh: forceRefresh);
      emit(MessDetailLoaded(d));
    } catch (e) {
      if (cachedAtCatch != null) {
        emit(MessDetailLoaded(cachedAtCatch));
      } else {
        emit(
          MessError(
            NetworkError.subtleMessage(e),
            code: NetworkError.codeFor(e),
          ),
        );
      }
    }
  }

  Future<bool> createMess(Map<String, dynamic> payload) async {
    try {
      await _repo.createMess(payload);
      await loadMesses();
      return true;
    } catch (e) {
      emit(MessError(e.toString().replaceAll('Exception: ', '')));
      return false;
    }
  }

  Future<String?> joinMess(String code, {String? note}) async {
    try {
      final msg = await _repo.joinMess(code, note: note);
      await loadMesses();
      return msg;
    } catch (e) {
      final err = e.toString().replaceAll('Exception: ', '');
      emit(MessError(err));
      return null;
    }
  }

  Future<bool> handleJoinRequest(int requestId, bool approve) async {
    try {
      await _repo.handleJoinRequest(requestId, approve);
      await loadMesses();
      return true;
    } catch (e) {
      emit(MessError(e.toString().replaceAll('Exception: ', '')));
      return false;
    }
  }

  Future<bool> updateMess(int id, Map<String, dynamic> payload) async {
    try {
      await _repo.updateMess(id, payload);
      await loadMess(id);
      return true;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      if (state is MessDetailLoaded) {
        emit(
          MessDetailLoaded(
            (state as MessDetailLoaded).detail,
            message: 'Error: $msg',
          ),
        );
      } else {
        emit(MessError(msg));
      }
      return false;
    }
  }

  Future<bool> deleteMess(int id) async {
    try {
      await _repo.deleteMess(id);
      await loadMesses();
      return true;
    } catch (e) {
      emit(MessError(e.toString().replaceAll('Exception: ', '')));
      return false;
    }
  }

  Future<bool> deleteMonth(int messId, int monthId) async {
    try {
      await _repo.deleteMonth(messId, monthId);
      CacheManager.clearAll();
      await loadMess(messId, forceRefresh: true);
      return true;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      emit(MessError(msg));
      return false;
    }
  }

  Future<bool> activateMonth(int messId, int monthId) async {
    try {
      await _repo.activateMonth(messId, monthId);
      CacheManager.clearAll();
      await loadMess(messId, forceRefresh: true);
      return true;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      emit(MessError(msg));
      return false;
    }
  }

  Future<void> loadSheet(int messId, int monthId) async {
    emit(MessLoading());
    try {
      final sheet = await _repo.fetchSheet(messId, monthId);
      emit(MessSheetLoaded(sheet));
    } catch (e) {
      emit(MessError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
