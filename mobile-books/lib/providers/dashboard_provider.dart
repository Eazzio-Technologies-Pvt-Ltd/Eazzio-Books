import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/dashboard_model.dart';
import '../data/repositories/dashboard_repository.dart';

class DashboardState {
  final DashboardModel? data;
  final bool isLoading;
  final String? errorMessage;

  const DashboardState({
    this.data,
    this.isLoading = false,
    this.errorMessage,
  });

  DashboardState copyWith({
    DashboardModel? data,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DashboardState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class DashboardNotifier extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    Future.microtask(() => fetchDashboardData());
    return const DashboardState();
  }

  Future<void> fetchDashboardData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = ref.read(dashboardRepositoryProvider);
      final data = await repository.getDashboardData();
      state = state.copyWith(isLoading: false, data: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final dashboardProvider =
    NotifierProvider<DashboardNotifier, DashboardState>(() {
  return DashboardNotifier();
});
