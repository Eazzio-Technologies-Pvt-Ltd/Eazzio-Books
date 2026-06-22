import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/organizations/data/models/organization.dart';

class OrganizationException implements Exception {
  final String message;
  OrganizationException(this.message);

  @override
  String toString() => message;
}

class OrganizationService {
  final NetworkClient _networkClient;

  OrganizationService(this._networkClient);

  /// Fetch list of organizations that the user owns or belongs to.
  Future<List<Organization>> getMyOrganizations() async {
    try {
      final response = await _networkClient.get('/my-organizations');
      final data = response.data as Map<String, dynamic>;
      final list = data['organizations'] as List? ?? [];
      return list.map((item) => Organization.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to retrieve organizations.';
      throw OrganizationException(message);
    } catch (e) {
      throw OrganizationException(e.toString());
    }
  }

  /// Create a new organization.
  Future<Organization> createOrganization({
    required String name,
    required String businessType,
  }) async {
    try {
      final response = await _networkClient.post(
        '/my-organizations',
        data: {
          'name': name.trim(),
          'business_type': businessType,
        },
      );
      final data = response.data as Map<String, dynamic>;
      if (data['organization'] != null) {
        return Organization.fromJson(data['organization'] as Map<String, dynamic>);
      } else {
        throw OrganizationException('Failed to parse organization from response.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to create organization.';
      throw OrganizationException(message);
    } catch (e) {
      throw OrganizationException(e.toString());
    }
  }

  /// Switch the active organization context on the backend.
  Future<void> switchOrganization(int orgId) async {
    try {
      await _networkClient.post('/switch-organization/$orgId');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to switch organization.';
      throw OrganizationException(message);
    } catch (e) {
      throw OrganizationException(e.toString());
    }
  }
}

final organizationServiceProvider = Provider<OrganizationService>((ref) {
  final networkClient = ref.watch(networkClientProvider);
  return OrganizationService(networkClient);
});
