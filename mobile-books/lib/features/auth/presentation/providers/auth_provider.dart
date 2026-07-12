import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_books/features/auth/data/models/user.dart';
import 'package:mobile_books/features/auth/data/services/auth_service.dart';
import 'package:mobile_books/features/settings/data/services/users_service.dart';
import 'package:mobile_books/core/navigation/router.dart';
import 'package:mobile_books/core/network/api_client.dart';
import 'package:flutter/widgets.dart';

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

  SharedPreferences? _getPrefs() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      User.prefs = prefs;
      return prefs;
    } catch (_) {
      return null;
    }
  }

  /// Verifies if a valid session exists on startup.
  Future<void> bootstrap() async {
    final authService = ref.read(authServiceProvider);
    final storage = ref.read(secureStorageProvider);
    final prefs = _getPrefs();
    
    bool hasToken = true;
    if (WidgetsBinding.instance != null) {
      final token = await storage.read(key: 'auth_token');
      hasToken = token != null && token.isNotEmpty;
    }
    
    if (!hasToken) {
      await _clearCache();
      state = const AuthUnauthenticated();
      return;
    }
    
    // Attempt to load from offline cache first (only until first backend response)
    if (prefs != null) {
      final cachedUserJson = prefs.getString('cached_user_json');
      if (cachedUserJson != null) {
        try {
          final decoded = jsonDecode(cachedUserJson) as Map<String, dynamic>;
          final cachedUser = User.fromJson(decoded);
          state = AuthAuthenticated(cachedUser);
        } catch (_) {
          // Ignore cache corruption
        }
      }
    }

    try {
      final user = await authService.getProfile();
      await _cacheUser(user);
      state = AuthAuthenticated(user);
      _syncTrialStartDate();
    } catch (_) {
      bool stillHasToken = true;
      if (WidgetsBinding.instance != null) {
        final currentToken = await storage.read(key: 'auth_token');
        stillHasToken = currentToken != null && currentToken.isNotEmpty;
      }
      if (!stillHasToken) {
        await _clearCache();
        state = const AuthUnauthenticated();
      } else {
        // If we failed to get the profile but we had a cached user, we keep it as fallback (until next request)
        if (state is! AuthAuthenticated) {
          state = const AuthUnauthenticated();
        }
      }
    }
  }

  /// Helper to cache user and subscription to SharedPreferences
  Future<void> _cacheUser(User user) async {
    final prefs = _getPrefs();
    if (prefs == null) return;
    await prefs.setString('cached_user_json', jsonEncode(user.toJson()));
    await prefs.setString('cached_plan_id', user.planId);
    await prefs.setString('cached_subscription_status', user.subscriptionStatus);
    if (user.subscriptionExpiresAt != null) {
      await prefs.setString('cached_subscription_expires_at', user.subscriptionExpiresAt!.toIso8601String());
    } else {
      await prefs.remove('cached_subscription_expires_at');
    }
  }

  /// Helper to clear cached user
  Future<void> _clearCache() async {
    final prefs = _getPrefs();
    if (prefs == null) return;
    await prefs.remove('cached_user_json');
    await prefs.remove('cached_plan_id');
    await prefs.remove('cached_subscription_status');
    await prefs.remove('cached_subscription_expires_at');
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
      await _cacheUser(user);
      state = AuthAuthenticated(user);
      _syncTrialStartDate();
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
    String planId = 'free',
    String? razorpayOrderId,
    String? razorpayPaymentId,
    String? razorpaySignature,
  }) async {
    state = const AuthLoading();
    final authService = ref.read(authServiceProvider);
    try {
      final user = await authService.register(
        email: email,
        password: password,
        companyName: companyName,
        fullName: fullName,
        planId: planId,
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpaySignature: razorpaySignature,
      );
      await _cacheUser(user);
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
      await _clearCache();
      state = const AuthUnauthenticated();
    } on AuthException catch (e) {
      state = AuthUnauthenticated(errorMessage: e.message);
    } catch (e) {
      state = AuthUnauthenticated(errorMessage: e.toString());
    }
  }

  /// Refreshes the user profile and subscription status.
  Future<void> refreshProfile() async {
    final authService = ref.read(authServiceProvider);
    try {
      final user = await authService.getProfile();
      await _cacheUser(user);
      state = AuthAuthenticated(user);
    } catch (_) {
      // Keep existing state on refresh failure
    }
  }

  /// Marks subscription as expired (triggered by HTTP 402 handler)
  Future<void> markSubscriptionExpired() async {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      final updatedUser = currentState.user.copyWith(
        subscriptionStatus: 'expired',
      );
      await _cacheUser(updatedUser);
      state = AuthAuthenticated(updatedUser);
    }
  }

  /// Downgrades the subscription to free (triggered by trial expiration)
  Future<void> downgradeToFree() async {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      final updatedUser = currentState.user.copyWith(
        planId: 'free',
        subscriptionStatus: 'active',
      );
      await _cacheUser(updatedUser);
      state = AuthAuthenticated(updatedUser);
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
      _cacheUser(updatedUser);
      state = AuthAuthenticated(updatedUser);
    }
  }

  Future<void> _syncTrialStartDate() async {
    try {
      final usersService = ref.read(usersServiceProvider);
      final members = await usersService.getTeamMembers();
      final currentUser = state is AuthAuthenticated ? (state as AuthAuthenticated).user : null;
      if (currentUser != null) {
        final match = members.firstWhere((u) => u.email.trim().toLowerCase() == currentUser.email.trim().toLowerCase());
        if (state is AuthAuthenticated) {
          state = AuthAuthenticated(match);
          await _cacheUser(match);
        }
      }
    } catch (_) {
      // Ignore background sync errors
    }
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
