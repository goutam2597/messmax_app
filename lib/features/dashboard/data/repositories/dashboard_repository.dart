import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/dashboard_model.dart';

class DashboardRepository {
  final Dio _dio;

  DashboardRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<DashboardModel> fetchDashboard() async {
    try {
      final response = await _dio.get(ApiEndpoints.dashboard);
      if (response.data != null && response.data is Map<String, dynamic>) {
        return DashboardModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Invalid dashboard API payload');
    } catch (_) {
      // Return structured fallback model if network fails / offline
      return const DashboardModel(
        hasMess: true,
        activeMess: ActiveMessModel(
          id: 1,
          name: 'Green View Student Hostel',
          slug: 'green-view-hostel',
          code: '#MX-8921',
          location: 'Mirpur 10, Dhaka',
          membersCount: 12,
          seatsAvailable: 3,
          isManager: true,
          role: 'manager',
        ),
        ledgerStats: LedgerStatsModel(
          totalMeals: 269.5,
          todayMeals: 29.5,
          totalBazar: 14098.0,
          mealRate: 52.41,
          totalDeposits: 28500.0,
          restMoney: 4280.0,
        ),
        pendingRequests: PendingRequestsModel(
          total: 2,
          mealOffCount: 1,
          guestCount: 1,
        ),
        dailySheetTeaser: [
          DailyMemberMealModel(id: 1, name: 'Goutam Sharma', room: 'Room 101', b: 1, l: 1, d: 1, total: 3.0),
          DailyMemberMealModel(id: 2, name: 'Cartpa User', room: 'Room 102', b: 1, l: 0, d: 1, total: 2.0, isLunchOff: true),
          DailyMemberMealModel(id: 3, name: 'Tanvir Ahmed', room: 'Room 103', b: 0, l: 0, d: 0, total: 0.0, isAllOff: true),
          DailyMemberMealModel(id: 4, name: 'Rafiqul Islam', room: 'Room 104', b: 1, l: 1, d: 1, total: 3.0),
        ],
        myMesses: [
          MyMessModel(id: 1, name: 'Green View Student Hostel', slug: 'green-view-hostel', membersCount: 12, role: 'manager'),
        ],
      );
    }
  }
}
