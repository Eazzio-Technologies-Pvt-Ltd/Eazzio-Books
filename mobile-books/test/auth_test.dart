import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile_books/features/auth/data/services/auth_service.dart';
import 'package:mobile_books/features/auth/data/models/user.dart';

class FakeAuthService implements AuthService {
  User? mockUser;
  bool shouldFail = false;
  bool logoutCalled = false;

  @override
  Future<User> login({required String email, required String password, bool rememberMe = false}) async {
    if (shouldFail) throw AuthException('Invalid credentials');
    return mockUser!;
  }

  @override
  Future<User> register({required String email, required String password, required String companyName, required String fullName}) async {
    if (shouldFail) throw AuthException('Registration failed');
    return mockUser!;
  }

  @override
  Future<User> getProfile() async {
    if (shouldFail) throw AuthException('No session');
    return mockUser!;
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }

  @override
  Future<String> forgotPassword({required String email}) async {
    return 'Reset link sent';
  }

  @override
  Future<String> resetPassword({required String token, required String newPassword}) async {
    return 'Password reset success';
  }
}

void main() {
  late FakeAuthService fakeAuthService;
  late ProviderContainer container;

  setUp(() {
    fakeAuthService = FakeAuthService();
    container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(fakeAuthService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Authentication Flow Provider Tests (Mock-Free)', () {
    final testUser = User(
      id: 1,
      email: 'test@eazzio.com',
      fullName: 'Test User',
      role: 'Admin',
      organizationId: 10,
      organizationName: 'Eazzio Corp',
      businessType: 'Retail',
    );

    test('Initial state of AuthNotifier is AuthInitial', () {
      fakeAuthService.mockUser = testUser;
      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthInitial>());
    });

    test('login success updates state to AuthAuthenticated and stores user', () async {
      fakeAuthService.mockUser = testUser;

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.login(email: 'test@eazzio.com', password: 'password123');

      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthAuthenticated>());
      expect((state as AuthAuthenticated).user.email, 'test@eazzio.com');
      expect(state.user.fullName, 'Test User');
    });

    test('login failure updates state to AuthUnauthenticated with error message', () async {
      fakeAuthService.shouldFail = true;

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.login(email: 'bad@eazzio.com', password: 'wrongpassword');

      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthUnauthenticated>());
      expect((state as AuthUnauthenticated).errorMessage, 'Invalid credentials');
    });

    test('logout updates state to AuthUnauthenticated and clears profile', () async {
      fakeAuthService.mockUser = testUser;

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.login(email: 'test@eazzio.com', password: 'password123');
      expect(container.read(authNotifierProvider), isA<AuthAuthenticated>());

      await notifier.logout();

      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthUnauthenticated>());
      expect(fakeAuthService.logoutCalled, isTrue);
    });

    test('bootstrap session restore successfully sets state to AuthAuthenticated', () async {
      fakeAuthService.mockUser = testUser;

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.bootstrap();

      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthAuthenticated>());
      expect((state as AuthAuthenticated).user.fullName, 'Test User');
    });

    test('bootstrap session restore fails sets state to AuthUnauthenticated', () async {
      fakeAuthService.shouldFail = true;

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.bootstrap();

      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthUnauthenticated>());
    });
  });
}
