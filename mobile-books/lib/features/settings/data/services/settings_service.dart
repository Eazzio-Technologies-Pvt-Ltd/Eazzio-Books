import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/settings/data/models/organization_settings.dart';
import 'package:mobile_books/features/settings/data/models/tax.dart';

class SettingsService {
  final NetworkClient _networkClient;

  SettingsService(this._networkClient);

  /// Fetches the organization settings for the current user
  Future<OrganizationSettings> getOrganizationSettings() async {
    try {
      final response = await _networkClient.get('/organization-settings');
      final data = response.data as Map<String, dynamic>;
      if (data['settings'] != null) {
        return OrganizationSettings.fromJson(data['settings'] as Map<String, dynamic>);
      }
      throw Exception('Organization settings data not found in response');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch organization settings.';
      throw Exception(message);
    }
  }

  /// Updates the organization settings
  Future<OrganizationSettings> updateOrganizationSettings(OrganizationSettings settings) async {
    try {
      final response = await _networkClient.put('/organization-settings', data: settings.toJson());
      final data = response.data as Map<String, dynamic>;
      if (data['settings'] != null) {
        return OrganizationSettings.fromJson(data['settings'] as Map<String, dynamic>);
      }
      throw Exception('Updated organization settings data not found in response');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to update organization settings.';
      throw Exception(message);
    }
  }

  /// Fetches all active taxes
  Future<List<Tax>> getTaxes() async {
    try {
      final response = await _networkClient.get('/taxes');
      final data = response.data as Map<String, dynamic>;
      final list = data['taxes'] as List? ?? [];
      return list.map((e) => Tax.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch taxes.';
      throw Exception(message);
    }
  }

  /// Fetches a single tax by ID
  Future<Tax> getTaxById(int id) async {
    try {
      final response = await _networkClient.get('/taxes/$id');
      final data = response.data as Map<String, dynamic>;
      if (data['tax'] != null) {
        return Tax.fromJson(data['tax'] as Map<String, dynamic>);
      }
      throw Exception('Tax record not found in response');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch tax by ID.';
      throw Exception(message);
    }
  }

  /// Creates a new tax record
  Future<Tax> createTax(Tax tax) async {
    try {
      final response = await _networkClient.post('/taxes', data: tax.toJson());
      final data = response.data as Map<String, dynamic>;
      if (data['tax'] != null) {
        return Tax.fromJson(data['tax'] as Map<String, dynamic>);
      }
      throw Exception('Created tax record not found in response');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to create tax.';
      throw Exception(message);
    }
  }

  /// Updates an existing tax record
  Future<Tax> updateTax(int id, Map<String, dynamic> updates) async {
    try {
      final response = await _networkClient.put('/taxes/$id', data: updates);
      final data = response.data as Map<String, dynamic>;
      if (data['tax'] != null) {
        return Tax.fromJson(data['tax'] as Map<String, dynamic>);
      }
      throw Exception('Updated tax record not found in response');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to update tax.';
      throw Exception(message);
    }
  }

  /// Deletes a tax record (soft delete)
  Future<void> deleteTax(int id) async {
    try {
      await _networkClient.delete('/taxes/$id');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to delete tax.';
      throw Exception(message);
    }
  }
}

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService(ref.watch(networkClientProvider));
});
