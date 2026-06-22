import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile_books/features/organizations/data/models/organization.dart';
import 'package:mobile_books/features/organizations/data/services/organization_service.dart';

class OrganizationsState {
  final List<Organization> organizations;
  final bool isLoading;
  final String? errorMessage;

  OrganizationsState({
    this.organizations = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  OrganizationsState copyWith({
    List<Organization>? organizations,
    bool? isLoading,
    String? errorMessage,
  }) {
    return OrganizationsState(
      organizations: organizations ?? this.organizations,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class OrganizationsNotifier extends Notifier<OrganizationsState> {
  @override
  OrganizationsState build() {
    // Fetch organizations on load
    Future.microtask(() => fetchOrganizations());
    return OrganizationsState();
  }

  OrganizationService get _service => ref.read(organizationServiceProvider);

  /// Load user organizations list.
  Future<void> fetchOrganizations() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _service.getMyOrganizations();
      state = state.copyWith(organizations: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Switch user organization.
  Future<bool> switchOrg(int orgId, String orgName) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _service.switchOrganization(orgId);
      
      // Update auth provider state
      ref.read(authNotifierProvider.notifier).updateActiveOrganization(orgId, orgName);
      
      state = state.copyWith(isLoading: false);
      
      // Trigger a reload of organizations list to keep active flags in sync if any
      await fetchOrganizations();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Create new organization and auto-switch.
  Future<bool> createAndSwitchOrg({
    required String name,
    required String businessType,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newOrg = await _service.createOrganization(
        name: name,
        businessType: businessType,
      );
      
      // Switch active organization on backend
      await _service.switchOrganization(newOrg.id);
      
      // Update local session
      ref.read(authNotifierProvider.notifier).updateActiveOrganization(newOrg.id, newOrg.name);
      
      state = state.copyWith(isLoading: false);
      await fetchOrganizations();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final organizationsProvider = NotifierProvider<OrganizationsNotifier, OrganizationsState>(() {
  return OrganizationsNotifier();
});
