import 'package:dio/dio.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/mess_model.dart';

class MessRepository {
  final Dio _dio;
  static List<MessModel>? _messesCache;
  static final Map<int, MessDetailModel> _messDetailCache = {};

  MessRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  static void clearCache() {
    _messesCache = null;
    _messDetailCache.clear();
  }

  List<MessModel>? getCachedMesses() => _messesCache;
  MessDetailModel? getCachedMess(int id) => _messDetailCache[id];

  Future<List<MessModel>> fetchMesses({bool forceRefresh = false}) async {
    if (!forceRefresh && _messesCache != null) {
      return _messesCache!;
    }
    try {
      final res = await _dio.get(ApiEndpoints.messes);
      final data = res.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final list = (data['data']['messes'] as List<dynamic>? ?? []);
        final parsed = list
            .map((e) => MessModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _messesCache = parsed;
        return parsed;
      }
      throw Exception(data['message'] ?? 'Failed to load messes');
    } catch (e) {
      if (_messesCache != null) return _messesCache!;
      AppLogger.w('fetchMesses failed: $e');
      rethrow;
    }
  }

  Future<MessDetailModel> fetchMess(int id, {bool forceRefresh = false}) async {
    if (!forceRefresh && _messDetailCache.containsKey(id)) {
      return _messDetailCache[id]!;
    }
    try {
      final res = await _dio.get('${ApiEndpoints.messes}/$id');
      final data = res.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final model = MessDetailModel.fromJson(
          data['data'] as Map<String, dynamic>,
        );
        _messDetailCache[id] = model;
        return model;
      }
      throw Exception(data['message'] ?? 'Failed to load mess');
    } catch (e) {
      if (_messDetailCache.containsKey(id)) return _messDetailCache[id]!;
      AppLogger.w('fetchMess failed: $e');
      rethrow;
    }
  }

  Future<MessModel> createMess(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post(ApiEndpoints.messes, data: payload);
      final data = res.data as Map<String, dynamic>;
      if (data['success'] == true) {
        return MessModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw Exception(data['message'] ?? 'Failed to create mess');
    } catch (e) {
      AppLogger.w('createMess failed: $e');
      rethrow;
    }
  }

  Future<String> joinMess(String code, {String? note}) async {
    try {
      final res = await _dio.post(
        '${ApiEndpoints.messes}/join',
        data: {
          'code': code.trim(),
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        },
      );
      final data = res.data as Map<String, dynamic>;
      if (data['success'] == true) {
        return (data['message'] as String?) ?? 'Join request sent to managers for approval.';
      }
      throw Exception(data['message'] ?? 'Failed to submit join request');
    } catch (e) {
      AppLogger.w('joinMess failed: $e');
      rethrow;
    }
  }

  Future<void> handleJoinRequest(int requestId, bool approve) async {
    try {
      final res = await _dio.post(
        '${ApiEndpoints.messes}/join-requests/$requestId/handle',
        data: {'action': approve ? 'approve' : 'reject'},
      );
      final data = res.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to handle join request');
      }
    } catch (e) {
      AppLogger.w('handleJoinRequest failed: $e');
      rethrow;
    }
  }

  Future<MessModel> updateMess(int id, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post('${ApiEndpoints.messes}/$id', data: payload);
      final data = res.data as Map<String, dynamic>;
      if (data['success'] == true) {
        return MessModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw Exception(data['message'] ?? 'Failed to update mess');
    } catch (e) {
      AppLogger.w('updateMess failed: $e');
      rethrow;
    }
  }

  Future<void> deleteMess(int id) async {
    try {
      final res = await _dio.delete('${ApiEndpoints.messes}/$id');
      final data = res.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to delete');
      }
    } catch (e) {
      AppLogger.w('deleteMess failed: $e');
      rethrow;
    }
  }

  // months & sheet
  Future<List<MessMonthLite>> fetchMonths(int messId) async {
    final res = await _dio.get('${ApiEndpoints.messes}/$messId/months');
    final data = res.data as Map<String, dynamic>;
    if (data['success'] == true) {
      final list = (data['data']['months'] as List<dynamic>? ?? []);
      return list
          .map((e) => MessMonthLite.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(data['message'] ?? 'Failed to load months');
  }

  Future<void> createMonth(int messId, Map<String, dynamic> payload) async {
    final res = await _dio.post(
      '${ApiEndpoints.messes}/$messId/months',
      data: payload,
    );
    final data = res.data as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to create month');
    }
    _messDetailCache.remove(messId);
    _messesCache = null;
  }

  Future<void> activateMonth(int messId, int monthId) async {
    try {
      final res = await _dio.patch(
        '${ApiEndpoints.messes}/$messId/months/$monthId/activate',
      );
      final data = res.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to activate month');
      }
      // Bust detail cache so the next fetchMess picks up the new active_month_id
      _messDetailCache.remove(messId);
      _messesCache = null;
    } catch (e) {
      AppLogger.w('activateMonth failed: $e');
      rethrow;
    }
  }

  Future<void> deleteMonth(int messId, int monthId) async {
    try {
      final res = await _dio.delete(
        '${ApiEndpoints.messes}/$messId/months/$monthId',
      );
      final data = res.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to delete monthly sheet');
      }
      _messDetailCache.remove(messId);
      _messesCache = null;
    } catch (e) {
      AppLogger.w('deleteMonth failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchSheet(int messId, int monthId) async {
    final res = await _dio.get(
      '${ApiEndpoints.messes}/$messId/months/$monthId',
    );
    final data = res.data as Map<String, dynamic>;
    if (data['success'] == true) return data['data'] as Map<String, dynamic>;
    throw Exception(data['message'] ?? 'Failed to load sheet');
  }

  Future<void> saveMeal({
    required int messId,
    required int monthId,
    required int memberId,
    required int day,
    double? count,
    double? breakfast,
    double? lunch,
    double? dinner,
  }) async {
    final payload = <String, dynamic>{'member_id': memberId, 'day': day};
    if (breakfast != null) payload['breakfast'] = breakfast;
    if (lunch != null) payload['lunch'] = lunch;
    if (dinner != null) payload['dinner'] = dinner;
    if (count != null && breakfast == null && lunch == null && dinner == null) {
      payload['count'] = count;
    }
    final res = await _dio.post(
      '${ApiEndpoints.messes}/$messId/months/$monthId/meal',
      data: payload,
    );
    if ((res.data as Map)['success'] != true) {
      throw Exception((res.data as Map)['message'] ?? 'Failed');
    }
  }

  Future<void> saveBazar({
    required int messId,
    required int monthId,
    required int day,
    required double amount,
  }) async {
    final res = await _dio.post(
      '${ApiEndpoints.messes}/$messId/months/$monthId/bazar',
      data: {'day': day, 'amount': amount},
    );
    if ((res.data as Map)['success'] != true) {
      throw Exception((res.data as Map)['message'] ?? 'Failed');
    }
  }

  Future<void> saveBazarItems({
    required int messId,
    required int monthId,
    required int day,
    required List<Map<String, dynamic>> items,
    bool clearItems = false,
    int? buyerMemberId,
    List<String>? receiptPaths,
    String? receiptRemoveIds,
    bool removeAll = false,
  }) async {
    if (receiptPaths != null && receiptPaths.isNotEmpty) {
      final files = <MultipartFile>[];
      for (final p in receiptPaths) {
        files.add(await MultipartFile.fromFile(p, filename: p.split('/').last));
      }
      final formData = FormData.fromMap(<String, dynamic>{
        'day': day,
        'items': items.map((e) => e.toString()).toList().toString(),
        if (clearItems) 'clear_items': true,
        if (buyerMemberId != null) 'buyer_member_id': buyerMemberId,
        'receipt_remove_ids': ?receiptRemoveIds,
        if (removeAll) 'receipt_remove': true,
        'receipts': files,
      });
      // Need JSON string for items when multipart — override
      formData.fields.removeWhere((f) => f.key == 'items');
      formData.fields.add(MapEntry('items', _jsonEncode(items)));
      final res = await _dio.post(
        '${ApiEndpoints.messes}/$messId/months/$monthId/bazar/$day/items',
        data: formData,
      );
      if ((res.data as Map)['success'] != true &&
          (res.data as Map)['ok'] != true) {
        throw Exception((res.data as Map)['message'] ?? 'Failed');
      }
      return;
    }
    // no files — send as JSON
    final res = await _dio.post(
      '${ApiEndpoints.messes}/$messId/months/$monthId/bazar/$day/items',
      data: {
        'day': day,
        'items': items,
        if (clearItems) 'clear_items': true,
        if (buyerMemberId != null) 'buyer_member_id': buyerMemberId,
        'receipt_remove_ids': ?receiptRemoveIds,
        if (removeAll) 'receipt_remove': true,
      },
    );
    if ((res.data as Map)['success'] != true && (res.data as Map)['ok'] != true) {
      throw Exception((res.data as Map)['message'] ?? 'Failed');
    }
  }

  String _jsonEncode(List<Map<String, dynamic>> items) {
    final buf = StringBuffer('[');
    for (var i = 0; i < items.length; i++) {
      if (i > 0) buf.write(',');
      buf.write('{');
      var first = true;
      items[i].forEach((k, v) {
        if (!first) buf.write(',');
        first = false;
        buf.write('"$k":');
        if (v is String) {
          buf.write('"${v.replaceAll('"', '\\"')}"');
        } else {
          buf.write('$v');
        }
      });
      buf.write('}');
    }
    buf.write(']');
    return buf.toString();
  }

  Future<void> addNextDay(int messId, int monthId) async {
    final res = await _dio.post(
      '${ApiEndpoints.messes}/$messId/months/$monthId/next-day',
    );
    if ((res.data as Map)['success'] != true) {
      throw Exception((res.data as Map)['message'] ?? 'Failed');
    }
  }

  Future<void> addDeposit(
    int messId,
    int monthId,
    int memberId,
    double amount, {
    String? date,
    String? note,
  }) async {
    final res = await _dio.post(
      '${ApiEndpoints.messes}/$messId/months/$monthId/deposit',
      data: {
        'mess_member_id': memberId,
        'amount': amount,
        'deposit_date': date,
        'note': note,
      },
    );
    if ((res.data as Map)['success'] != true) {
      throw Exception((res.data as Map)['message'] ?? 'Failed');
    }
  }

  Future<void> deleteDeposit(int messId, int monthId, int depositId) async {
    final res = await _dio.delete(
      '${ApiEndpoints.messes}/$messId/months/$monthId/deposits/$depositId',
    );
    if ((res.data as Map)['success'] != true) {
      throw Exception((res.data as Map)['message'] ?? 'Failed');
    }
  }

  Future<void> updateExtra(int messId, int monthId, double extra) async {
    final res = await _dio.patch(
      '${ApiEndpoints.messes}/$messId/months/$monthId/extra',
      data: {'extra_cost': extra},
    );
    if ((res.data as Map)['success'] != true) {
      throw Exception((res.data as Map)['message'] ?? 'Failed');
    }
  }

  Future<void> duplicateMonth(int messId, int monthId) async {
    final res = await _dio.post(
      '${ApiEndpoints.messes}/$messId/months/$monthId/duplicate',
    );
    if ((res.data as Map)['success'] != true) {
      throw Exception((res.data as Map)['message'] ?? 'Failed');
    }
  }

  Future<void> assignManager(
    int messId,
    int monthId,
    int? memberId, {
    String action = 'keep',
  }) async {
    final res = await _dio.patch(
      '${ApiEndpoints.messes}/$messId/months/$monthId/manager',
      data: {'manager_member_id': memberId, 'action': action},
    );
    if ((res.data as Map)['success'] != true) {
      throw Exception((res.data as Map)['message'] ?? 'Failed');
    }
  }

  Future<void> updateMemberDetails(
    int messId,
    int memberId, {
    double? defaultMeal,
    double? breakfast,
    double? lunch,
    double? dinner,
    double? depositAmount,
    String? depositNote,
  }) async {
    final payload = <String, dynamic>{};
    if (defaultMeal != null) payload['default_meal'] = defaultMeal;
    if (breakfast != null) payload['default_breakfast'] = breakfast;
    if (lunch != null) payload['default_lunch'] = lunch;
    if (dinner != null) payload['default_dinner'] = dinner;
    if (depositAmount != null) payload['deposit_amount'] = depositAmount;
    if (depositNote != null) payload['deposit_note'] = depositNote;
    final res = await _dio.patch(
      '${ApiEndpoints.messes}/$messId/members/$memberId/details',
      data: payload,
    );
    if ((res.data as Map)['success'] != true) {
      throw Exception((res.data as Map)['message'] ?? 'Failed');
    }
  }

  Future<void> autofillDefaults(int messId, int monthId) async {
    final res = await _dio.post(
      '${ApiEndpoints.messes}/$messId/months/$monthId/autofill-defaults',
    );
    if ((res.data as Map)['success'] != true) {
      throw Exception((res.data as Map)['message'] ?? 'Failed');
    }
  }

  Future<void> requestMealOff(
    int messId,
    int monthId,
    int day, {
    bool? bOn,
    bool? lOn,
    bool? dOn,
    String? note,
  }) async {
    final payload = <String, dynamic>{
      'day': day,
    };
    if (bOn != null) {
      payload['b_on'] = bOn;
      payload['breakfast_on'] = bOn;
      payload['b_off'] = !bOn;
      payload['breakfast_off'] = !bOn;
    }
    if (lOn != null) {
      payload['l_on'] = lOn;
      payload['lunch_on'] = lOn;
      payload['l_off'] = !lOn;
      payload['lunch_off'] = !lOn;
    }
    if (dOn != null) {
      payload['d_on'] = dOn;
      payload['dinner_on'] = dOn;
      payload['d_off'] = !dOn;
      payload['dinner_off'] = !dOn;
    }
    if (note != null) payload['note'] = note;
    final res = await _dio.post(
      '${ApiEndpoints.messes}/$messId/months/$monthId/meal-off',
      data: payload,
    );
    if ((res.data as Map)['success'] != true) {
      throw Exception((res.data as Map)['message'] ?? 'Failed');
    }
  }

  Future<void> handleMealOff(
    int messId,
    int monthId,
    int reqId,
    String action,
  ) async {
    final res = await _dio.post(
      '${ApiEndpoints.messes}/$messId/months/$monthId/meal-off/$reqId/handle',
      data: {'action': action},
    );
    if ((res.data as Map)['success'] != true) {
      throw Exception((res.data as Map)['message'] ?? 'Failed');
    }
  }

  Future<void> requestGuestMeal(
    int messId,
    int monthId, {
    required int day,
    required String guestName,
    required int guestCount,
    bool breakfast = false,
    bool lunch = false,
    bool dinner = false,
    String? note,
  }) async {
    final res = await _dio.post(
      '${ApiEndpoints.messes}/$messId/months/$monthId/guest-meal',
      data: {
        'day': day,
        'guest_name': guestName,
        'guest_count': guestCount,
        'breakfast': breakfast,
        'lunch': lunch,
        'dinner': dinner,
        'note': note,
      },
    );
    if ((res.data as Map)['success'] != true) {
      throw Exception((res.data as Map)['message'] ?? 'Failed');
    }
  }

  Future<void> addGuestDirect(
    int messId,
    int monthId, {
    required int memberId,
    required int day,
    required String guestName,
    required int guestCount,
    bool breakfast = false,
    bool lunch = false,
    bool dinner = false,
  }) async {
    final res = await _dio.post(
      '${ApiEndpoints.messes}/$messId/months/$monthId/guest-meal/direct',
      data: {
        'mess_member_id': memberId,
        'day': day,
        'guest_name': guestName,
        'guest_count': guestCount,
        'breakfast': breakfast,
        'lunch': lunch,
        'dinner': dinner,
      },
    );
    if ((res.data as Map)['success'] != true) {
      throw Exception((res.data as Map)['message'] ?? 'Failed');
    }
  }

  Future<void> handleGuestMeal(
    int messId,
    int monthId,
    int reqId,
    String action,
  ) async {
    final res = await _dio.post(
      '${ApiEndpoints.messes}/$messId/months/$monthId/guest-meal/$reqId/handle',
      data: {'action': action},
    );
    if ((res.data as Map)['success'] != true) {
      throw Exception((res.data as Map)['message'] ?? 'Failed');
    }
  }

  Future<void> removeGuestMeal(int messId, int monthId, int guestId) async {
    final res = await _dio.delete('${ApiEndpoints.messes}/$messId/months/$monthId/guest-meals/$guestId');
    if ((res.data as Map)['success'] != true) throw Exception((res.data as Map)['message'] ?? 'Failed');
  }

  Future<void> removeGuestMealRequest(int messId, int monthId, int reqId) async {
    final res = await _dio.delete('${ApiEndpoints.messes}/$messId/months/$monthId/guest-meal-requests/$reqId');
    if ((res.data as Map)['success'] != true) throw Exception((res.data as Map)['message'] ?? 'Failed');
  }

  Future<void> requestGuestCancel(
    int messId,
    int monthId,
    int guestMealId, {
    String? note,
  }) async {
    final res = await _dio.post(
      '${ApiEndpoints.messes}/$messId/months/$monthId/guest-cancel',
      data: {'guest_meal_id': guestMealId, 'note': note},
    );
    if ((res.data as Map)['success'] != true) {
      throw Exception((res.data as Map)['message'] ?? 'Failed');
    }
  }

  Future<void> storeInvite(
    int messId,
    String email,
    String role, {
    String? memberName,
  }) async {
    final res = await _dio.post(
      '${ApiEndpoints.messes}/$messId/invites',
      data: {'email': email, 'role': role, 'member_name': memberName},
    );
    if ((res.data as Map)['success'] != true) {
      throw Exception((res.data as Map)['message'] ?? 'Failed');
    }
  }
}
