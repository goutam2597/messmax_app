import 'user_model.dart';

class AuthResponse {
  final UserModel user;
  final String token;

  const AuthResponse({required this.user, required this.token});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final userMap = data['user'] as Map<String, dynamic>? ?? data;
    return AuthResponse(
      user: UserModel.fromJson(userMap),
      token: data['token'] as String? ?? '',
    );
  }
}
