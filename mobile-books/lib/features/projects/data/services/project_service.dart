import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/projects/data/models/project.dart';

class ProjectException implements Exception {
  final String message;
  ProjectException(this.message);

  @override
  String toString() => message;
}

class ProjectService {
  final NetworkClient _networkClient;

  ProjectService(this._networkClient);

  Future<List<Project>> getProjects() async {
    try {
      final response = await _networkClient.get('/projects');
      final data = response.data as Map<String, dynamic>;
      final list = data['projects'] as List? ?? [];
      return list.map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch projects.';
      throw ProjectException(message);
    } catch (e) {
      throw ProjectException(e.toString());
    }
  }

  Future<Project> getProjectById(int id) async {
    try {
      final response = await _networkClient.get('/projects/$id');
      final data = response.data as Map<String, dynamic>;
      if (data['project'] != null) {
        return Project.fromJson(data['project'] as Map<String, dynamic>);
      } else {
        throw ProjectException('Invalid project response structure.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch project details.';
      throw ProjectException(message);
    } catch (e) {
      throw ProjectException(e.toString());
    }
  }

  Future<Project> createProject(Project project) async {
    try {
      final body = project.toJson();
      body.remove('id'); // ID is serial
      final response = await _networkClient.post('/projects', data: body);
      final data = response.data as Map<String, dynamic>;
      if (data['project'] != null) {
        return Project.fromJson(data['project'] as Map<String, dynamic>);
      } else {
        throw ProjectException('Failed to parse created project.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to create project.';
      throw ProjectException(message);
    } catch (e) {
      throw ProjectException(e.toString());
    }
  }

  Future<Project> updateProject(int id, Map<String, dynamic> updates) async {
    try {
      final response = await _networkClient.put('/projects/$id', data: updates);
      final data = response.data as Map<String, dynamic>;
      if (data['project'] != null) {
        return Project.fromJson(data['project'] as Map<String, dynamic>);
      } else {
        throw ProjectException('Failed to parse updated project.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to update project.';
      throw ProjectException(message);
    } catch (e) {
      throw ProjectException(e.toString());
    }
  }

  Future<void> deleteProject(int id) async {
    try {
      await _networkClient.delete('/projects/$id');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to delete project.';
      throw ProjectException(message);
    } catch (e) {
      throw ProjectException(e.toString());
    }
  }

  Future<List<Map<String, dynamic>>> getProjectInvoices(int id) async {
    try {
      final response = await _networkClient.get('/projects/$id/invoices');
      final data = response.data as Map<String, dynamic>;
      final list = data['invoices'] as List? ?? [];
      return list.map((e) => e as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch project invoices.';
      throw ProjectException(message);
    } catch (e) {
      throw ProjectException(e.toString());
    }
  }

  Future<List<Map<String, dynamic>>> getProjectExpenses(int id) async {
    try {
      final response = await _networkClient.get('/projects/$id/expenses');
      final data = response.data as Map<String, dynamic>;
      final list = data['expenses'] as List? ?? [];
      return list.map((e) => e as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch project expenses.';
      throw ProjectException(message);
    } catch (e) {
      throw ProjectException(e.toString());
    }
  }

  Future<Map<String, dynamic>> getProjectProfitability(int id) async {
    try {
      final response = await _networkClient.get('/projects/$id/profitability');
      final data = response.data as Map<String, dynamic>;
      if (data['profitability'] != null) {
        return data['profitability'] as Map<String, dynamic>;
      } else {
        throw ProjectException('Invalid profitability response structure.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch project profitability.';
      throw ProjectException(message);
    } catch (e) {
      throw ProjectException(e.toString());
    }
  }

  Future<List<Map<String, dynamic>>> getProjectTimesheets(int id) async {
    try {
      final response = await _networkClient.get('/projects/$id/timesheets');
      final data = response.data as Map<String, dynamic>;
      final list = data['timesheets'] as List? ?? [];
      return list.map((e) => e as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch project timesheets.';
      throw ProjectException(message);
    } catch (e) {
      throw ProjectException(e.toString());
    }
  }
}

final projectServiceProvider = Provider<ProjectService>((ref) {
  final networkClient = ref.watch(networkClientProvider);
  return ProjectService(networkClient);
});
