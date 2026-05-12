import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savebite/core/errors/failures.dart';
import 'package:savebite/shared/models/user.dart';
import 'package:savebite/features/auth/data/repositories/auth_repository.dart';
import 'package:savebite/features/auth/providers/auth_provider.dart';

// ─── Fake Repository ──────────────────────────
// WHY fake instead of mockito: no build_runner needed, explicit control
// over success/failure paths, and tests run faster.

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository()
      : super(dio: Dio(), storage: const FlutterSecureStorage());

  bool shouldFail = false;
  String failMessage = 'Test error';
  String? storedToken = 'valid_token';

  static const _testUser = User(
    id: 1,
    name: 'Test User',
    email: 'test@savebite.id',
    tier: 'Mahasiswa Hemat',
  );

  @override
  Future<String?> getStoredToken() async => storedToken;

  @override
  Future<ApiResult<User>> me() async {
    if (shouldFail) return Failure(message: failMessage);
    return const Success(_testUser);
  }

  @override
  Future<ApiResult<User>> login({
    required String email,
    required String password,
  }) async {
    if (shouldFail) return Failure(message: failMessage);
    return const Success(_testUser);
  }

  @override
  Future<ApiResult<User>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    if (shouldFail) return Failure(message: failMessage);
    return const Success(_testUser);
  }

  @override
  Future<ApiResult<void>> logout() async {
    return const Success(null);
  }
}

// ─── Tests ────────────────────────────────────

void main() {
  late FakeAuthRepository fakeRepo;
  late AuthNotifier notifier;

  setUp(() {
    fakeRepo = FakeAuthRepository();
    notifier = AuthNotifier(fakeRepo);
  });

  group('AuthNotifier initial state', () {
    test('starts with AuthInitial', () {
      expect(notifier.state, isA<AuthInitial>());
    });
  });

  group('AuthNotifier.checkAuthStatus', () {
    test('transitions to Authenticated when token exists and me() succeeds', () async {
      await notifier.checkAuthStatus();
      expect(notifier.state, isA<Authenticated>());
      final state = notifier.state as Authenticated;
      expect(state.user.email, 'test@savebite.id');
    });

    test('transitions to Unauthenticated when no token', () async {
      fakeRepo.storedToken = null;
      await notifier.checkAuthStatus();
      expect(notifier.state, isA<Unauthenticated>());
    });

    test('transitions to Unauthenticated when me() fails', () async {
      fakeRepo.shouldFail = true;
      await notifier.checkAuthStatus();
      expect(notifier.state, isA<Unauthenticated>());
    });
  });

  group('AuthNotifier.login', () {
    test('transitions to Authenticated on success', () async {
      await notifier.login(email: 'test@savebite.id', password: 'pass');
      expect(notifier.state, isA<Authenticated>());
    });

    test('transitions to Unauthenticated with message on failure', () async {
      fakeRepo.shouldFail = true;
      fakeRepo.failMessage = 'Email atau password salah';
      await notifier.login(email: 'wrong@test.id', password: 'bad');

      expect(notifier.state, isA<Unauthenticated>());
      final state = notifier.state as Unauthenticated;
      expect(state.message, 'Email atau password salah');
    });
  });

  group('AuthNotifier.register', () {
    test('transitions to Authenticated on success', () async {
      await notifier.register(
        name: 'New User',
        email: 'new@test.id',
        password: 'secret123',
        passwordConfirmation: 'secret123',
      );
      expect(notifier.state, isA<Authenticated>());
    });

    test('transitions to Unauthenticated on failure', () async {
      fakeRepo.shouldFail = true;
      fakeRepo.failMessage = 'Email sudah terdaftar';
      await notifier.register(
        name: 'X',
        email: 'x@test.id',
        password: 'p',
        passwordConfirmation: 'p',
      );
      final state = notifier.state as Unauthenticated;
      expect(state.message, 'Email sudah terdaftar');
    });
  });

  group('AuthNotifier.logout', () {
    test('transitions to Unauthenticated', () async {
      // First login
      await notifier.login(email: 'test@savebite.id', password: 'pass');
      expect(notifier.state, isA<Authenticated>());
      // Then logout
      await notifier.logout();
      expect(notifier.state, isA<Unauthenticated>());
    });
  });
}
