import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/timesheets/data/models/timesheet.dart';

class TimesheetException implements Exception {
  final String message;
  TimesheetException(this.message);

  @override
  String toString() => message;
}

class TimesheetService {
  final NetworkClient _networkClient;

  TimesheetService(this._networkClient);

  Future<List<Timesheet>> getTimesheets() async {
    try {
      final response = await _networkClient.get('/timesheets');
      final data = response.data as Map<String, dynamic>;
      final list = data['timesheets'] as List? ?? [];
      return list.map((e) => Timesheet.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch timesheets.';
      throw TimesheetException(message);
    } catch (e) {
      throw TimesheetException(e.toString());
    }
  }

  Future<Timesheet> getTimesheetById(int id) async {
    try {
      final response = await _networkClient.get('/timesheets/$id');
      final data = response.data as Map<String, dynamic>;
      if (data['timesheet'] != null) {
        return Timesheet.fromJson(data['timesheet'] as Map<String, dynamic>);
      } else {
        throw TimesheetException('Invalid timesheet response structure.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch timesheet details.';
      throw TimesheetException(message);
    } catch (e) {
      throw TimesheetException(e.toString());
    }
  }

  Future<Timesheet> createTimesheet(Timesheet timesheet) async {
    try {
      final body = timesheet.toJson();
      body.remove('id'); // ID is serial
      final response = await _networkClient.post('/timesheets', data: body);
      final data = response.data as Map<String, dynamic>;
      if (data['timesheet'] != null) {
        return Timesheet.fromJson(data['timesheet'] as Map<String, dynamic>);
      } else {
        throw TimesheetException('Failed to parse created timesheet.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to create timesheet.';
      throw TimesheetException(message);
    } catch (e) {
      throw TimesheetException(e.toString());
    }
  }

  Future<Timesheet> updateTimesheet(int id, Map<String, dynamic> updates) async {
    try {
      final response = await _networkClient.put('/timesheets/$id', data: updates);
      final data = response.data as Map<String, dynamic>;
      if (data['timesheet'] != null) {
        return Timesheet.fromJson(data['timesheet'] as Map<String, dynamic>);
      } else {
        throw TimesheetException('Failed to parse updated timesheet.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to update timesheet.';
      throw TimesheetException(message);
    } catch (e) {
      throw TimesheetException(e.toString());
    }
  }

  Future<Timesheet> cancelTimesheet(int id) async {
    try {
      final response = await _networkClient.patch('/timesheets/$id/cancel');
      final data = response.data as Map<String, dynamic>;
      if (data['timesheet'] != null) {
        return Timesheet.fromJson(data['timesheet'] as Map<String, dynamic>);
      } else {
        throw TimesheetException('Failed to parse cancelled timesheet.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to cancel timesheet.';
      throw TimesheetException(message);
    } catch (e) {
      throw TimesheetException(e.toString());
    }
  }

  Future<Timesheet> approveTimesheet(int id) async {
    try {
      final response = await _networkClient.patch('/timesheets/$id/approve');
      final data = response.data as Map<String, dynamic>;
      if (data['timesheet'] != null) {
        return Timesheet.fromJson(data['timesheet'] as Map<String, dynamic>);
      } else {
        throw TimesheetException('Failed to parse approved timesheet.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to approve timesheet.';
      throw TimesheetException(message);
    } catch (e) {
      throw TimesheetException(e.toString());
    }
  }

  Future<Map<String, dynamic>> convertToInvoice(int id) async {
    try {
      final response = await _networkClient.post('/timesheets/$id/convert-to-invoice');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to convert timesheet to invoice.';
      throw TimesheetException(message);
    } catch (e) {
      throw TimesheetException(e.toString());
    }
  }
}

final timesheetServiceProvider = Provider<TimesheetService>((ref) {
  final networkClient = ref.watch(networkClientProvider);
  return TimesheetService(networkClient);
});
