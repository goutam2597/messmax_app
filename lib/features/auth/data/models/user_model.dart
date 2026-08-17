import 'package:equatable/equatable.dart';

import '../../../../core/config/app_config.dart';

class UserModel extends Equatable {
  final int id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String accountType; // hostel_owner | individual
  final bool isAdmin;
  final String? emailVerifiedAt;
  final String? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.accountType,
    this.isAdmin = false,
    this.emailVerifiedAt,
    this.createdAt,
  });

  bool get isHostelOwner => accountType == 'hostel_owner';
  bool get isIndividual => accountType == 'individual';

  String get initials {
    final p = name.trim().isEmpty ? email.trim() : name.trim();
    return p.isEmpty ? 'M' : p[0].toUpperCase();
  }

  String get roleLabel {
    if (isAdmin) return 'ADMIN';
    return isIndividual ? 'INDIVIDUAL' : 'HOSTEL OWNER';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: AppConfig.sanitizeImageUrl(json['avatar_url'] as String?),
      accountType: json['account_type'] as String? ?? 'individual',
      isAdmin: json['is_admin'] as bool? ?? false,
      emailVerifiedAt: json['email_verified_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatar_url': avatarUrl,
        'account_type': accountType,
        'is_admin': isAdmin,
        'email_verified_at': emailVerifiedAt,
        'created_at': createdAt,
      };

  @override
  List<Object?> get props => [id, name, email, avatarUrl, accountType, isAdmin, emailVerifiedAt, createdAt];
}
