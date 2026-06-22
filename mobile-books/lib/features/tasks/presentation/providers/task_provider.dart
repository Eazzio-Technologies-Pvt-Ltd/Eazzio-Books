import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/tasks/data/models/task.dart';
import 'package:mobile_books/features/tasks/data/services/task_service.dart';

class TasksNotifier extends AsyncNotifier<List<Task>> {
  @override
  Future<List<Task>> build() async {
    return ref.watch(taskServiceProvider).getTasks();
  }

  /// Refreshes tasks list from the backend
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(taskServiceProvider).getTasks();
    });
  }

  /// Adds a new task
  Future<Task> createTask(String title) async {
    final service = ref.read(taskServiceProvider);
    final result = await service.createTask(title);
    ref.invalidateSelf();
    return result;
  }

  /// Updates an existing task's title
  Future<Task> updateTask(int id, String title) async {
    final service = ref.read(taskServiceProvider);
    final result = await service.updateTask(id, title);
    ref.invalidateSelf();
    return result;
  }

  /// Deletes a task
  Future<void> deleteTask(int id) async {
    final service = ref.read(taskServiceProvider);
    await service.deleteTask(id);
    ref.invalidateSelf();
  }
}

final tasksProvider = AsyncNotifierProvider<TasksNotifier, List<Task>>(() {
  return TasksNotifier();
});
