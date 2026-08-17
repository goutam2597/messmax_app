import 'package:equatable/equatable.dart';

class BazarScheduleResponseModel extends Equatable {
  final MessInfoModel mess;
  final bool canManage;
  final int year;
  final int month;
  final int daysInMonth;
  final String monthLabel;
  final int assignedCount;
  final int unassignedCount;
  final List<BazarMemberModel> members;
  final List<BazarDayItemModel> schedules;

  const BazarScheduleResponseModel({
    required this.mess,
    required this.canManage,
    required this.year,
    required this.month,
    required this.daysInMonth,
    required this.monthLabel,
    required this.assignedCount,
    required this.unassignedCount,
    required this.members,
    required this.schedules,
  });

  factory BazarScheduleResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final messJson = data['mess'] as Map<String, dynamic>? ?? {};
    final membersList = data['members'] as List<dynamic>? ?? [];
    final schedulesList = data['schedules'] as List<dynamic>? ?? [];

    return BazarScheduleResponseModel(
      mess: MessInfoModel.fromJson(messJson),
      canManage: data['can_manage'] as bool? ?? false,
      year: data['year'] as int? ?? DateTime.now().year,
      month: data['month'] as int? ?? DateTime.now().month,
      daysInMonth: data['days_in_month'] as int? ?? 30,
      monthLabel: data['month_label'] as String? ?? '',
      assignedCount: data['assigned_count'] as int? ?? 0,
      unassignedCount: data['unassigned_count'] as int? ?? 0,
      members: membersList.map((e) => BazarMemberModel.fromJson(e as Map<String, dynamic>)).toList(),
      schedules: schedulesList.map((e) => BazarDayItemModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  @override
  List<Object?> get props => [mess, canManage, year, month, daysInMonth, monthLabel, assignedCount, unassignedCount, members, schedules];
}

class MessInfoModel extends Equatable {
  final int id;
  final String name;
  final String slug;
  final String code;
  final String location;

  const MessInfoModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.code,
    required this.location,
  });

  factory MessInfoModel.fromJson(Map<String, dynamic> json) {
    return MessInfoModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      code: json['code'] as String? ?? '',
      location: json['location'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, slug, code, location];
}

class BazarMemberModel extends Equatable {
  final int id;
  final String name;
  final String? email;
  final String? bazarDay;
  final String role;

  const BazarMemberModel({
    required this.id,
    required this.name,
    this.email,
    this.bazarDay,
    required this.role,
  });

  factory BazarMemberModel.fromJson(Map<String, dynamic> json) {
    return BazarMemberModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      bazarDay: json['bazar_day'] as String?,
      role: json['role'] as String? ?? 'member',
    );
  }

  @override
  List<Object?> get props => [id, name, email, bazarDay, role];
}

class BazarDayItemModel extends Equatable {
  final int? id;
  final int day;
  final String dateLabel;
  final bool isToday;
  final bool isPast;
  final int? messMemberId;
  final String? memberName;
  final String? staffName;
  final String? displayName;
  final String? note;

  const BazarDayItemModel({
    this.id,
    required this.day,
    required this.dateLabel,
    required this.isToday,
    required this.isPast,
    this.messMemberId,
    this.memberName,
    this.staffName,
    this.displayName,
    this.note,
  });

  bool get isAssigned => messMemberId != null || (staffName != null && staffName!.isNotEmpty);

  factory BazarDayItemModel.fromJson(Map<String, dynamic> json) {
    return BazarDayItemModel(
      id: json['id'] as int?,
      day: json['day'] as int? ?? 1,
      dateLabel: json['date_label'] as String? ?? '',
      isToday: json['is_today'] as bool? ?? false,
      isPast: json['is_past'] as bool? ?? false,
      messMemberId: json['mess_member_id'] as int?,
      memberName: json['member_name'] as String?,
      staffName: json['staff_name'] as String?,
      displayName: json['display_name'] as String?,
      note: json['note'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, day, dateLabel, isToday, isPast, messMemberId, memberName, staffName, displayName, note];
}
