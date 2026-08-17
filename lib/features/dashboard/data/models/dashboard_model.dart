import 'package:equatable/equatable.dart';

class DashboardModel extends Equatable {
  final bool hasMess;
  final ActiveMessModel? activeMess;
  final LedgerStatsModel ledgerStats;
  final PendingRequestsModel pendingRequests;
  final List<DailyMemberMealModel> dailySheetTeaser;
  final List<MyMessModel> myMesses;

  const DashboardModel({
    required this.hasMess,
    this.activeMess,
    required this.ledgerStats,
    required this.pendingRequests,
    required this.dailySheetTeaser,
    required this.myMesses,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final hasMess = data['has_mess'] as bool? ?? false;
    final active = data['active_mess'] as Map<String, dynamic>?;
    final stats = data['ledger_stats'] as Map<String, dynamic>?;
    final pending = data['pending_requests'] as Map<String, dynamic>?;
    final dailyTeaser = data['daily_sheet_teaser'] as List<dynamic>?;
    final messes = data['my_messes'] as List<dynamic>?;

    return DashboardModel(
      hasMess: hasMess,
      activeMess: active != null ? ActiveMessModel.fromJson(active) : null,
      ledgerStats: stats != null
          ? LedgerStatsModel.fromJson(stats)
          : const LedgerStatsModel(
              totalMeals: 0,
              todayMeals: 0,
              totalBazar: 0,
              mealRate: 0,
              totalDeposits: 0,
              restMoney: 0,
            ),
      pendingRequests: pending != null
          ? PendingRequestsModel.fromJson(pending)
          : const PendingRequestsModel(total: 0, mealOffCount: 0, guestCount: 0),
      dailySheetTeaser: dailyTeaser != null
          ? dailyTeaser.map((e) => DailyMemberMealModel.fromJson(e as Map<String, dynamic>)).toList()
          : const [],
      myMesses: messes != null
          ? messes.map((e) => MyMessModel.fromJson(e as Map<String, dynamic>)).toList()
          : const [],
    );
  }

  @override
  List<Object?> get props => [hasMess, activeMess, ledgerStats, pendingRequests];
}

class ActiveMessModel extends Equatable {
  final int id;
  final String name;
  final String slug;
  final String code;
  final String location;
  final int membersCount;
  final int seatsAvailable;
  final bool isManager;
  final String role;

  const ActiveMessModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.code,
    required this.location,
    required this.membersCount,
    required this.seatsAvailable,
    required this.isManager,
    required this.role,
  });

  factory ActiveMessModel.fromJson(Map<String, dynamic> json) {
    return ActiveMessModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'My Mess',
      slug: json['slug'] as String? ?? '',
      code: json['code'] as String? ?? '#MX-0000',
      location: json['location'] as String? ?? '',
      membersCount: json['members_count'] as int? ?? 1,
      seatsAvailable: json['seats_available'] as int? ?? 0,
      isManager: json['is_manager'] as bool? ?? false,
      role: json['role'] as String? ?? 'member',
    );
  }

  @override
  List<Object?> get props => [id, name, slug, code, membersCount];
}

class LedgerStatsModel extends Equatable {
  final double totalMeals;
  final double todayMeals;
  final double totalBazar;
  final double mealRate;
  final double totalDeposits;
  final double restMoney;

  const LedgerStatsModel({
    required this.totalMeals,
    required this.todayMeals,
    required this.totalBazar,
    required this.mealRate,
    required this.totalDeposits,
    required this.restMoney,
  });

  factory LedgerStatsModel.fromJson(Map<String, dynamic> json) {
    return LedgerStatsModel(
      totalMeals: (json['total_meals'] as num?)?.toDouble() ?? 0.0,
      todayMeals: (json['today_meals'] as num?)?.toDouble() ?? 0.0,
      totalBazar: (json['total_bazar'] as num?)?.toDouble() ?? 0.0,
      mealRate: (json['meal_rate'] as num?)?.toDouble() ?? 0.0,
      totalDeposits: (json['total_deposits'] as num?)?.toDouble() ?? 0.0,
      restMoney: (json['rest_money'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [totalMeals, totalBazar, mealRate, totalDeposits, restMoney];
}

class PendingRequestsModel extends Equatable {
  final int total;
  final int mealOffCount;
  final int guestCount;

  const PendingRequestsModel({
    required this.total,
    required this.mealOffCount,
    required this.guestCount,
  });

  factory PendingRequestsModel.fromJson(Map<String, dynamic> json) {
    return PendingRequestsModel(
      total: json['total'] as int? ?? 0,
      mealOffCount: json['meal_off_count'] as int? ?? 0,
      guestCount: json['guest_count'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [total, mealOffCount, guestCount];
}

class DailyMemberMealModel extends Equatable {
  final int id;
  final String name;
  final String room;
  final int b;
  final int l;
  final int d;
  final double total;
  final bool isLunchOff;
  final bool isAllOff;

  const DailyMemberMealModel({
    required this.id,
    required this.name,
    required this.room,
    required this.b,
    required this.l,
    required this.d,
    required this.total,
    this.isLunchOff = false,
    this.isAllOff = false,
  });

  factory DailyMemberMealModel.fromJson(Map<String, dynamic> json) {
    final b = json['breakfast'] as int? ?? 0;
    final l = json['lunch'] as int? ?? 0;
    final d = json['dinner'] as int? ?? 0;
    final total = (json['total'] as num?)?.toDouble() ?? (b + l + d).toDouble();
    return DailyMemberMealModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Member',
      room: json['room'] as String? ?? 'Member',
      b: b,
      l: l,
      d: d,
      total: total,
      isLunchOff: b == 1 && l == 0 && d == 1,
      isAllOff: b == 0 && l == 0 && d == 0,
    );
  }

  @override
  List<Object?> get props => [id, name, room, b, l, d, total];
}

class MyMessModel extends Equatable {
  final int id;
  final String name;
  final String slug;
  final int membersCount;
  final String role;

  const MyMessModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.membersCount,
    required this.role,
  });

  bool get isManager => role.toLowerCase() == 'manager' || role.toLowerCase() == 'owner';

  factory MyMessModel.fromJson(Map<String, dynamic> json) {
    return MyMessModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      membersCount: json['members_count'] as int? ?? 1,
      role: json['role'] as String? ?? 'member',
    );
  }

  @override
  List<Object?> get props => [id, name, slug, membersCount, role];
}
