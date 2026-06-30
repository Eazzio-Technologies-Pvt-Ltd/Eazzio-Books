import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/auth/data/models/user.dart';

class UsersService {
  final NetworkClient _networkClient;

  UsersService(this._networkClient);

  /// Fetches organization team members
  Future<List<User>> getTeamMembers() async {
    try {
      final response = await _networkClient.get('/users');
      final data = response.data as Map<String, dynamic>;
      final list = data['users'] as List? ?? [];
      return list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch team members.';
      throw Exception(message);
    }
  }

  /// Creates a new staff/team member account
  Future<User> createTeamMember({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _networkClient.post(
        '/users',
        data: {
          'email': email,
          'password': password,
          'role': role,
        },
      );
      final data = response.data as Map<String, dynamic>;
      if (data['user'] != null) {
        return User.fromJson(data['user'] as Map<String, dynamic>);
      }
      throw Exception('Created user data not found in response');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to create team member.';
      throw Exception(message);
    }
  }

  /// Updates a team member's role
  Future<void> updateMemberRole(int userId, String newRole) async {
    try {
      await _networkClient.put(
        '/users/$userId/role',
        data: {'role': newRole},
      );
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to update user role.';
      throw Exception(message);
    }
  }

  /// Deletes/deactivates a team member
  Future<void> deleteTeamMember(int userId) async {
    try {
      await _networkClient.delete('/users/$userId');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to remove team member.';
      throw Exception(message);
    }
  }
}

final usersServiceProvider = Provider<UsersService>((ref) {
  return UsersService(ref.watch(networkClientProvider));
});
