import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/auth/data/models/user.dart';
import 'package:mobile_books/features/settings/data/services/users_service.dart';

class TeamMembersNotifier extends AsyncNotifier<List<User>> {
  @override
  Future<List<User>> build() {
    return ref.watch(usersServiceProvider).getTeamMembers();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(usersServiceProvider).getTeamMembers();
    });
  }

  Future<void> createMember({
    required String email,
    required String password,
    required String role,
  }) async {
    final service = ref.read(usersServiceProvider);
    await service.createTeamMember(
      email: email,
      password: password,
      role: role,
    );
    ref.invalidateSelf();
  }

  Future<void> updateRole(int userId, String newRole) async {
    final service = ref.read(usersServiceProvider);
    await service.updateMemberRole(userId, newRole);
    ref.invalidateSelf();
  }

  Future<void> deleteMember(int userId) async {
    final service = ref.read(usersServiceProvider);
    await service.deleteTeamMember(userId);
    ref.invalidateSelf();
  }
}

final teamMembersProvider = AsyncNotifierProvider<TeamMembersNotifier, List<User>>(() {
  return TeamMembersNotifier();
});
