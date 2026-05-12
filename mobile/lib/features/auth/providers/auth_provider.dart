import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../../../shared/models/user.dart';
import '../data/repositories/auth_repository.dart';

/// Sealed auth state — exhaustive pattern matching.
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  const Authenticated(this.user);
  final User user;
}

class Unauthenticated extends AuthState {
  const Unauthenticated([this.message]);
  final String? message;
}

/// Auth state provider.
final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

/// Auth state notifier using StateNotifier (per skill: riverpod-state.md).
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthInitial());

  final AuthRepository _repo;

  /// Check stored token on app start.
  Future<void> checkAuthStatus() async {
    state = const AuthLoading();
    final token = await _repo.getStoredToken();
    if (token == null) {
      state = const Unauthenticated();
      return;
    }
    // Token exists → validate with /auth/me
    final result = await _repo.me();
    switch (result) {
      case Success(:final data):
        state = Authenticated(data);
      case Failure():
        state = const Unauthenticated();
    }
  }

  /// Login.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    final result = await _repo.login(email: email, password: password);
    switch (result) {
      case Success(:final data):
        state = Authenticated(data);
      case Failure(:final message):
        state = Unauthenticated(message);
    }
  }

  /// Register.
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    state = const AuthLoading();
    final result = await _repo.register(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      phone: phone,
    );
    switch (result) {
      case Success(:final data):
        state = Authenticated(data);
      case Failure(:final message):
        state = Unauthenticated(message);
    }
  }

  /// Refresh user data (e.g. after profile update).
  Future<void> refreshUser() async {
    final result = await _repo.me();
    switch (result) {
      case Success(:final data):
        state = Authenticated(data);
      case Failure():
        break; // Keep current state on failure
    }
  }

  /// Logout.
  Future<void> logout() async {
    await _repo.logout();
    state = const Unauthenticated();
  }
}
