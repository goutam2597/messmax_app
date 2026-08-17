import 'package:equatable/equatable.dart';

import '../../data/models/user_model.dart';

enum AuthLoadingType { email, google, general }

sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  final AuthLoadingType type;
  const AuthLoading([this.type = AuthLoadingType.email]);

  @override
  List<Object?> get props => [type];
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}
