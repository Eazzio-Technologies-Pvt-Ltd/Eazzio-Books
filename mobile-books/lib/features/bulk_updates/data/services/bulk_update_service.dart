import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/bulk_updates/data/models/bulk_update_log.dart';

class BulkUpdateException implements Exception {
  final String message;
  BulkUpdateException(this.message);

  @override
  String toString() => message;
}

class BulkUpdateService {
  final NetworkClient _networkClient;

  BulkUpdateService(this._networkClient);

  Future<List<Map<String, dynamic>>> getModules() async {
    try {
      final response = await _networkClient.get('/bulk-updates/modules');
      final data = response.data as Map<String, dynamic>;
      final modules = data['modules'] as List? ?? [];
      return modules.map((e) => e as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch bulk update modules.';
      throw BulkUpdateException(message);
    } catch (e) {
      throw BulkUpdateException(e.toString());
    }
  }

  Future<List<BulkUpdateLog>> getLogs() async {
    try {
      final response = await _networkClient.get('/bulk-updates/logs');
      final data = response.data as Map<String, dynamic>;
      final logs = data['logs'] as List? ?? [];
      return logs.map((e) => BulkUpdateLog.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch bulk update logs.';
      throw BulkUpdateException(message);
    } catch (e) {
      throw BulkUpdateException(e.toString());
    }
  }

  Future<List<Map<String, dynamic>>> getRecordsForModule(String moduleName) async {
    try {
      final endpoint = '/${moduleName.toLowerCase()}';
      final response = await _networkClient.get(endpoint);
      final data = response.data as Map<String, dynamic>;
      
      // Mirroring react: res[endpoint] || res.items || res.customers || res.invoices || res.expenses || []
      final listName = moduleName.toLowerCase();
      final records = data[listName] as List? ??
                      data['items'] as List? ??
                      data['customers'] as List? ??
                      data['invoices'] as List? ??
                      data['expenses'] as List? ??
                      [];
      return records.map((e) => e as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch records for $moduleName.';
      throw BulkUpdateException(message);
    } catch (e) {
      throw BulkUpdateException(e.toString());
    }
  }

  Future<Map<String, dynamic>> previewBulkUpdate({
    required String moduleName,
    required String actionType,
    required List<int> records,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final response = await _networkClient.post(
        '/bulk-updates/preview',
        data: {
          'module_name': moduleName,
          'action_type': actionType,
          'records': records,
          'payload': payload,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return data['results'] as Map<String, dynamic>? ?? {};
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to preview bulk update.';
      throw BulkUpdateException(message);
    } catch (e) {
      throw BulkUpdateException(e.toString());
    }
  }

  Future<Map<String, dynamic>> applyBulkUpdate({
    required String moduleName,
    required String actionType,
    required List<int> records,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final response = await _networkClient.post(
        '/bulk-updates/apply',
        data: {
          'module_name': moduleName,
          'action_type': actionType,
          'records': records,
          'payload': payload,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return data['results'] as Map<String, dynamic>? ?? {};
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to apply bulk update.';
      throw BulkUpdateException(message);
    } catch (e) {
      throw BulkUpdateException(e.toString());
    }
  }
}

final bulkUpdateServiceProvider = Provider<BulkUpdateService>((ref) {
  final networkClient = ref.watch(networkClientProvider);
  return BulkUpdateService(networkClient);
});
