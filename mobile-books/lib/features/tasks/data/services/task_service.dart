import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/tasks/data/models/task.dart';

class TaskException implements Exception {
  final String message;
  TaskException(this.message);

  @override
  String toString() => message;
}

class TaskService {
  final NetworkClient _networkClient;

  TaskService(this._networkClient);

  /// Fetches all tasks for the logged in user
  Future<List<Task>> getTasks() async {
    try {
      final response = await _networkClient.get('/tasks');
      final data = response.data as List? ?? [];
      return data.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch tasks list.';
      throw TaskException(message);
    } catch (e) {
      throw TaskException(e.toString());
    }
  }

  /// Creates a new task
  Future<Task> createTask(String title) async {
    try {
      final response = await _networkClient.post(
        '/tasks',
        data: {'title': title},
      );
      return Task.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to create task.';
      throw TaskException(message);
    } catch (e) {
      throw TaskException(e.toString());
    }
  }

  /// Updates an existing task title
  Future<Task> updateTask(int id, String title) async {
    try {
      final response = await _networkClient.put(
        '/tasks/$id',
        data: {'title': title},
      );
      return Task.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to update task.';
      throw TaskException(message);
    } catch (e) {
      throw TaskException(e.toString());
    }
  }

  /// Deletes a task
  Future<void> deleteTask(int id) async {
    try {
      await _networkClient.delete('/tasks/$id');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to delete task.';
      throw TaskException(message);
    } catch (e) {
      throw TaskException(e.toString());
    }
  }
}

final taskServiceProvider = Provider<TaskService>((ref) {
  final networkClient = ref.watch(networkClientProvider);
  return TaskService(networkClient);
});
