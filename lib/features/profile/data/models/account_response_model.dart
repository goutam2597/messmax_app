import 'package:equatable/equatable.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../features/dashboard/data/models/dashboard_model.dart';

class AccountResponseModel extends Equatable {
  final UserModel user;
  final List<MyMessModel> messes;

  const AccountResponseModel({
    required this.user,
    required this.messes,
  });

  factory AccountResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final userJson = data['user'] as Map<String, dynamic>? ?? {};
    final messesJson = data['messes'] as List<dynamic>? ?? [];

    return AccountResponseModel(
      user: UserModel.fromJson(userJson),
      messes: messesJson.map((e) => MyMessModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  @override
  List<Object?> get props => [user, messes];
}
