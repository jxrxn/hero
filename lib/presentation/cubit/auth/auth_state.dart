import 'package:equatable/equatable.dart';

enum AuthStatus { idle, loading, success, failure }

class AuthState extends Equatable {
  const AuthState({
    required this.loggedIn,
    this.status = AuthStatus.idle,
    this.message,
  });

  final bool loggedIn;
  final AuthStatus status;
  final String? message;

  AuthState copyWith({
    bool? loggedIn,
    AuthStatus? status,
    String? message,
  }) {
    return AuthState(
      loggedIn: loggedIn ?? this.loggedIn,
      status: status ?? this.status,
      message: message,
    );
  }

  @override
  List<Object?> get props => [loggedIn, status, message];
}