import 'package:equatable/equatable.dart';
import '../../../../core/config/app_config.dart';

class MemberModel extends Equatable {
  final int id;
  final int messId;
  final String name;
  final String email;
  final String role;
  final String bazarDay;
  final String color;
  final int? userId;
  final bool isLinked;
  final String? avatarUrl;
  final double? defaultBreakfast;
  final double? defaultLunch;
  final double? defaultDinner;
  final double? defaultMeal;
  final String defaultDisplay;
  final double? defaultTotal;

  const MemberModel({
    required this.id,
    required this.messId,
    required this.name,
    required this.email,
    required this.role,
    required this.bazarDay,
    required this.color,
    this.userId,
    this.isLinked = false,
    this.avatarUrl,
    this.defaultBreakfast,
    this.defaultLunch,
    this.defaultDinner,
    this.defaultMeal,
    required this.defaultDisplay,
    this.defaultTotal,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    final rawAvatar = json['avatar_url'] as String?;
    return MemberModel(
      id: (json['id'] as num).toInt(),
      messId: (json['mess_id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? 'Member',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
      bazarDay: json['bazar_day'] as String? ?? '1',
      color: json['color'] as String? ?? '#3b82f6',
      userId: (json['user_id'] as num?)?.toInt(),
      isLinked: json['is_linked'] as bool? ?? false,
      avatarUrl: rawAvatar != null ? AppConfig.sanitizeImageUrl(rawAvatar) : null,
      defaultBreakfast: (json['default_breakfast'] as num?)?.toDouble(),
      defaultLunch: (json['default_lunch'] as num?)?.toDouble(),
      defaultDinner: (json['default_dinner'] as num?)?.toDouble(),
      defaultMeal: (json['default_meal'] as num?)?.toDouble(),
      defaultDisplay: json['default_display'] as String? ?? '—',
      defaultTotal: (json['default_total'] as num?)?.toDouble(),
    );
  }

  bool get isOwner => role.toLowerCase() == 'owner';
  bool get isManager => role.toLowerCase() == 'manager';

  @override
  List<Object?> get props => [
        id,
        messId,
        name,
        email,
        role,
        bazarDay,
        color,
        userId,
        isLinked,
        avatarUrl,
        defaultBreakfast,
        defaultLunch,
        defaultDinner,
        defaultMeal,
        defaultDisplay,
        defaultTotal,
      ];
}

class MemberMessOptionModel extends Equatable {
  final int id;
  final String name;
  final bool isManager;

  const MemberMessOptionModel({
    required this.id,
    required this.name,
    required this.isManager,
  });

  factory MemberMessOptionModel.fromJson(Map<String, dynamic> json) {
    return MemberMessOptionModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      isManager: json['is_manager'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, name, isManager];
}

class MemberResponseModel extends Equatable {
  final int messId;
  final String messName;
  final String messCode;
  final String messLocation;
  final bool canManage;
  final List<MemberMessOptionModel> messes;
  final List<MemberModel> members;

  const MemberResponseModel({
    required this.messId,
    required this.messName,
    required this.messCode,
    required this.messLocation,
    required this.canManage,
    required this.messes,
    required this.members,
  });

  factory MemberResponseModel.fromJson(Map<String, dynamic> json) {
    final messJson = json['mess'] as Map<String, dynamic>?;
    final messesList = (json['messes'] as List<dynamic>?)
            ?.map((m) => MemberMessOptionModel.fromJson(m as Map<String, dynamic>))
            .toList() ??
        [];
    final membersList = (json['members'] as List<dynamic>?)
            ?.map((m) => MemberModel.fromJson(m as Map<String, dynamic>))
            .toList() ??
        [];

    return MemberResponseModel(
      messId: (messJson?['id'] as num?)?.toInt() ?? 0,
      messName: messJson?['name'] as String? ?? 'Mess Roster',
      messCode: messJson?['code'] as String? ?? '',
      messLocation: messJson?['location'] as String? ?? '',
      canManage: json['can_manage'] as bool? ?? false,
      messes: messesList,
      members: membersList,
    );
  }

  @override
  List<Object?> get props => [
        messId,
        messName,
        messCode,
        messLocation,
        canManage,
        messes,
        members,
      ];
}
