import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/auth/data/models/user.dart';
import 'package:mobile_books/features/auth/data/services/auth_service.dart';

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  final String? errorMessage;
  const AuthUnauthenticated({this.errorMessage});
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    bootstrap();
    return const AuthInitial();
  }

  /// Verifies if a valid session exists on startup.
  Future<void> bootstrap() async {
    final authService = ref.read(authServiceProvider);
    try {
      final user = await authService.getProfile();
      state = AuthAuthenticated(user);
    } catch (_) {
      state = const AuthUnauthenticated();
    }
  }

  /// Logs in the user and updates the auth state.
  Future<void> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    state = const AuthLoading();
    final authService = ref.read(authServiceProvider);
    try {
      final user = await authService.login(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );
      state = AuthAuthenticated(user);
    } on AuthException catch (e) {
      state = AuthUnauthenticated(errorMessage: e.message);
    } catch (e) {
      state = AuthUnauthenticated(errorMessage: e.toString());
    }
  }

  /// Registers a new user/organization and updates the auth state.
  Future<void> register({
    required String email,
    required String password,
    required String companyName,
    required String fullName,
  }) async {
    state = const AuthLoading();
    final authService = ref.read(authServiceProvider);
    try {
      final user = await authService.register(
        email: email,
        password: password,
        companyName: companyName,
        fullName: fullName,
      );
      state = AuthAuthenticated(user);
    } on AuthException catch (e) {
      state = AuthUnauthenticated(errorMessage: e.message);
    } catch (e) {
      state = AuthUnauthenticated(errorMessage: e.toString());
    }
  }

  /// Logs out the user and clears cookie session.
  Future<void> logout() async {
    state = const AuthLoading();
    final authService = ref.read(authServiceProvider);
    try {
      await authService.logout();
      state = const AuthUnauthenticated();
    } on AuthException catch (e) {
      state = AuthUnauthenticated(errorMessage: e.message);
    } catch (e) {
      state = AuthUnauthenticated(errorMessage: e.toString());
    }
  }

  /// Submits email for password reset instruction.
  Future<String> forgotPassword({required String email}) async {
    final authService = ref.read(authServiceProvider);
    return authService.forgotPassword(email: email);
  }

  /// Submits token and new password for reset completion.
  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final authService = ref.read(authServiceProvider);
    return authService.resetPassword(token: token, newPassword: newPassword);
  }

  void updateActiveOrganization(int orgId, String orgName) {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      final updatedUser = currentState.user.copyWith(
        organizationId: orgId,
        organizationName: orgName,
      );
      state = AuthAuthenticated(updatedUser);
    }
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
