import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;
  final bool isInitialized;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.isInitialized = false,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
    bool? isInitialized,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  bool get isAuthenticated => user != null;
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    final apiClient = ref.read(apiClientProvider);
    apiClient.onUnauthorized = _handleUnauthorized;
    Future.microtask(() => checkAuthStatus());
    return const AuthState();
  }

  void _handleUnauthorized() {
    state = const AuthState(user: null, isInitialized: true);
  }

  Future<void> checkAuthStatus() async {
    final apiClient = ref.read(apiClientProvider);
    final hasToken = await apiClient.hasToken();
    if (!hasToken) {
      state = const AuthState(isInitialized: true);
      return;
    }
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final user = await authRepository.getProfile();
      state = AuthState(user: user, isInitialized: true);
    } catch (_) {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.deleteToken();
      state = const AuthState(isInitialized: true);
    }
  }

  Future<bool> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final user = await authRepository.login(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );
      state = AuthState(user: user, isInitialized: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String companyName,
    String? fullName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.register(
        email: email,
        password: password,
        companyName: companyName,
        fullName: fullName,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    final authRepository = ref.read(authRepositoryProvider);
    await authRepository.logout();
    state = const AuthState(isInitialized: true);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
