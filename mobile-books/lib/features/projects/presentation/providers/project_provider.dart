import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/projects/data/models/project.dart';
import 'package:mobile_books/features/projects/data/services/project_service.dart';

class ProjectSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
}

final projectSearchQueryProvider = NotifierProvider<ProjectSearchQueryNotifier, String>(() {
  return ProjectSearchQueryNotifier();
});

class ProjectsNotifier extends AsyncNotifier<List<Project>> {
  @override
  Future<List<Project>> build() {
    return ref.watch(projectServiceProvider).getProjects();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(projectServiceProvider).getProjects();
    });
  }

  Future<Project> createProject(Project project) async {
    final service = ref.read(projectServiceProvider);
    final result = await service.createProject(project);
    ref.invalidateSelf();
    return result;
  }

  Future<Project> updateProject(int id, Map<String, dynamic> updates) async {
    final service = ref.read(projectServiceProvider);
    final result = await service.updateProject(id, updates);
    ref.invalidateSelf();
    ref.invalidate(projectDetailsProvider(id));
    return result;
  }

  Future<void> deleteProject(int id) async {
    final service = ref.read(projectServiceProvider);
    await service.deleteProject(id);
    ref.invalidateSelf();
    ref.invalidate(projectDetailsProvider(id));
  }
}

final projectsProvider = AsyncNotifierProvider<ProjectsNotifier, List<Project>>(() {
  return ProjectsNotifier();
});

final filteredProjectsProvider = Provider<AsyncValue<List<Project>>>((ref) {
  final projectsState = ref.watch(projectsProvider);
  final searchQuery = ref.watch(projectSearchQueryProvider).toLowerCase();

  return projectsState.whenData((list) {
    if (searchQuery.isEmpty) return list;
    return list.where((p) {
      final name = p.projectName.toLowerCase();
      final code = (p.projectCode ?? '').toLowerCase();
      final customerName = (p.customerName ?? '').toLowerCase();
      final customerCompany = (p.customerCompany ?? '').toLowerCase();
      final status = p.status.toLowerCase();
      return name.contains(searchQuery) ||
          code.contains(searchQuery) ||
          customerName.contains(searchQuery) ||
          customerCompany.contains(searchQuery) ||
          status.contains(searchQuery);
    }).toList();
  });
});

final projectDetailsProvider = FutureProvider.family<Project, int>((ref, id) {
  return ref.watch(projectServiceProvider).getProjectById(id);
});

final projectProfitabilityProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, id) {
  return ref.watch(projectServiceProvider).getProjectProfitability(id);
});
