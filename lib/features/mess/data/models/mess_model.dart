import 'package:equatable/equatable.dart';
import '../../../../core/config/app_config.dart';

class MessModel extends Equatable {
  final int id;
  final String name;
  final String slug;
  final String location;
  final String timezone;
  final int billingStartDay;
  final String? billingStartDate;
  final String? billingEndDate;
  final bool isIndividualMess;
  final String? myRole;
  final String? myRoleLabel;
  final bool canManage;
  final bool isMember;
  final bool isOwner;
  final int membersCount;
  final int monthsCount;

  const MessModel({
    required this.id,
    required this.name,
    required this.slug,
    this.location = '',
    this.timezone = 'Asia/Dhaka',
    this.billingStartDay = 1,
    this.billingStartDate,
    this.billingEndDate,
    this.isIndividualMess = false,
    this.myRole,
    this.myRoleLabel,
    this.canManage = false,
    this.isMember = false,
    this.isOwner = false,
    this.membersCount = 0,
    this.monthsCount = 0,
  });

  String get displayRole {
    final r = (myRole ?? '').toLowerCase();
    if (r == 'owner') return 'manager';
    return r.isEmpty ? 'member' : r;
  }

  String get displayRoleLabel {
    final r = (myRoleLabel ?? '').toLowerCase();
    if (r == 'owner') return 'Manager';
    return myRoleLabel ?? 'Member';
  }

  factory MessModel.fromJson(Map<String, dynamic> json) {
    return MessModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      location: json['location'] as String? ?? '',
      timezone: json['timezone'] as String? ?? 'Asia/Dhaka',
      billingStartDay: (json['billing_start_day'] as num?)?.toInt() ?? 1,
      billingStartDate: json['billing_start_date'] as String?,
      billingEndDate: json['billing_end_date'] as String?,
      isIndividualMess: json['is_individual_mess'] as bool? ?? false,
      myRole: json['my_role'] as String?,
      myRoleLabel: json['my_role_label'] as String?,
      canManage: json['can_manage'] as bool? ?? false,
      isMember: json['is_member'] as bool? ?? false,
      isOwner: json['is_owner'] as bool? ?? false,
      membersCount: (json['members_count'] as num?)?.toInt() ?? 0,
      monthsCount: (json['months_count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, name, slug, location, timezone, billingStartDay, myRole, canManage, membersCount];
}

class MessMemberLite extends Equatable {
  final int id;
  final String name;
  final String email;
  final String color;
  final String bazarDay;
  final String memberRole;
  final int? userId;
  final String? avatarUrl;
  final double? defaultMeal;
  final double? defaultBreakfast;
  final double? defaultLunch;
  final double? defaultDinner;
  final String defaultDisplay;

  const MessMemberLite({
    required this.id,
    required this.name,
    this.email = '',
    this.color = '#3b82f6',
    this.bazarDay = '1',
    this.memberRole = 'member',
    this.userId,
    this.avatarUrl,
    this.defaultMeal,
    this.defaultBreakfast,
    this.defaultLunch,
    this.defaultDinner,
    this.defaultDisplay = '',
  });

  factory MessMemberLite.fromJson(Map<String, dynamic> json) {
    return MessMemberLite(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      color: json['color'] as String? ?? '#3b82f6',
      bazarDay: (json['bazar_day'] ?? json['bazarDay'] ?? '1').toString(),
      memberRole: json['member_role'] as String? ?? 'member',
      userId: (json['user_id'] as num?)?.toInt(),
      avatarUrl: AppConfig.sanitizeImageUrl(json['avatar_url'] as String?),
      defaultMeal: (json['default_meal'] as num?)?.toDouble(),
      defaultBreakfast: (json['default_breakfast'] as num?)?.toDouble(),
      defaultLunch: (json['default_lunch'] as num?)?.toDouble(),
      defaultDinner: (json['default_dinner'] as num?)?.toDouble(),
      defaultDisplay: json['default_display'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, email, memberRole, color];
}

class MessMonthLite extends Equatable {
  final int id;
  final int year;
  final int month;
  final String label;
  final String cycleLabel;
  final bool isClosed;
  final String managerLabel;
  final int daysInMonth;

  const MessMonthLite({
    required this.id,
    required this.year,
    required this.month,
    required this.label,
    this.cycleLabel = '',
    this.isClosed = false,
    this.managerLabel = '',
    this.daysInMonth = 31,
  });

  factory MessMonthLite.fromJson(Map<String, dynamic> json) {
    return MessMonthLite(
      id: (json['id'] as num?)?.toInt() ?? 0,
      year: (json['year'] as num?)?.toInt() ?? 0,
      month: (json['month'] as num?)?.toInt() ?? 0,
      label: json['label'] as String? ?? '',
      cycleLabel: (json['cycle_label'] as String? ?? '')
          .replaceAll(r'\u2192', '→')
          .replaceAll('\\u2192', '→'),
      isClosed: json['is_closed'] as bool? ?? false,
      managerLabel: json['manager_label'] as String? ?? '',
      daysInMonth: (json['days_in_month'] as num?)?.toInt() ?? 31,
    );
  }

  @override
  List<Object?> get props => [id, year, month, label];
}

class MessDetailModel extends Equatable {
  final MessModel mess;
  final String? myRole;
  final bool canManage;
  final List<MessMemberLite> members;
  final List<MessMonthLite> months;
  final Map<String, dynamic>? currentMonth;
  final Map<String, dynamic>? sheetSummary;
  final List<dynamic> pendingInvites;
  final bool canCreateMonth;

  const MessDetailModel({
    required this.mess,
    this.myRole,
    this.canManage = false,
    this.members = const [],
    this.months = const [],
    this.currentMonth,
    this.sheetSummary,
    this.pendingInvites = const [],
    this.canCreateMonth = false,
  });

  factory MessDetailModel.fromJson(Map<String, dynamic> json) {
    final messJson = json['mess'] as Map<String, dynamic>? ?? json;
    final membersList = (json['members'] as List<dynamic>?) ?? [];
    final monthsList = (json['months'] as List<dynamic>?) ?? [];
    return MessDetailModel(
      mess: MessModel.fromJson(messJson),
      myRole: json['my_role'] as String? ?? messJson['my_role'] as String?,
      canManage: json['can_manage'] as bool? ?? false,
      members: membersList.map((e) => MessMemberLite.fromJson(e as Map<String, dynamic>)).toList(),
      months: monthsList.map((e) => MessMonthLite.fromJson(e as Map<String, dynamic>)).toList(),
      currentMonth: json['current_month'] as Map<String, dynamic>?,
      sheetSummary: json['sheet_summary'] as Map<String, dynamic>?,
      pendingInvites: (json['pending_invites'] as List<dynamic>?) ?? const [],
      canCreateMonth: json['can_create_month'] as bool? ?? false,
    );
  }

  List<MemberSettlementModel> get memberSettlements {
    if (sheetSummary == null) return [];
    final summaryList = sheetSummary!['summary'] as List<dynamic>?;
    if (summaryList == null) return [];
    return summaryList
        .map((e) => MemberSettlementModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String get currentMonthLabel {
    if (sheetSummary == null) return '';
    final m = sheetSummary!['month'] as Map<String, dynamic>?;
    return m?['label'] as String? ?? '';
  }

  @override
  List<Object?> get props => [mess, myRole, canManage, members, months];
}

class MemberSettlementModel extends Equatable {
  final int memberId;
  final String name;
  final String email;
  final String color;
  final String role;
  final String defaultDisplay;
  final double meals;
  final double spend;
  final double given;
  final double balance;

  const MemberSettlementModel({
    required this.memberId,
    required this.name,
    this.email = '',
    this.color = '#3b82f6',
    this.role = 'member',
    this.defaultDisplay = '',
    this.meals = 0.0,
    this.spend = 0.0,
    this.given = 0.0,
    this.balance = 0.0,
  });

  factory MemberSettlementModel.fromJson(Map<String, dynamic> json) {
    final memberObj = json['member'] is Map<String, dynamic>
        ? json['member'] as Map<String, dynamic>
        : json;

    return MemberSettlementModel(
      memberId: (memberObj['id'] ?? json['member_id'] as num?)?.toInt() ?? 0,
      name: memberObj['name'] as String? ?? json['name'] as String? ?? '',
      email: memberObj['email'] as String? ?? json['email'] as String? ?? '',
      color: memberObj['color'] as String? ?? json['color'] as String? ?? '#3b82f6',
      role: memberObj['member_role'] as String? ??
          memberObj['role'] as String? ??
          json['role'] as String? ??
          'member',
      defaultDisplay: memberObj['default_display'] as String? ??
          json['default_display'] as String? ??
          '',
      meals: (json['meals'] as num?)?.toDouble() ?? 0.0,
      spend: (json['spend'] as num?)?.toDouble() ?? 0.0,
      given: (json['given'] as num?)?.toDouble() ?? 0.0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [memberId, name, meals, spend, given, balance];
}
