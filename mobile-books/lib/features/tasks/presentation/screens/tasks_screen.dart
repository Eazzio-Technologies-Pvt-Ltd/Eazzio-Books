import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/tasks/data/models/task.dart';
import 'package:mobile_books/features/tasks/presentation/providers/task_provider.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  void _showTaskDialog(BuildContext context, WidgetRef ref, {Task? task}) {
    final controller = TextEditingController(text: task?.title);
    final isEdit = task != null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Task' : 'Add Task'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter task title...',
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = controller.text.trim();
                if (title.isEmpty) return;

                Navigator.pop(context);
                try {
                  if (isEdit) {
                    await ref.read(tasksProvider.notifier).updateTask(task.id, title);
                  } else {
                    await ref.read(tasksProvider.notifier).createTask(title);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to save task: $e')),
                    );
                  }
                }
              },
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksState = ref.watch(tasksProvider);

    return ResponsiveScaffold(
      currentRoute: '/tasks',
      appBar: AppBar(
        title: const Text('My Tasks'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.primaryBlueDark : AppColors.primaryBlue,
        onPressed: () => _showTaskDialog(context, ref),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(tasksProvider.notifier).refresh(),
        child: tasksState.when(
          data: (tasks) {
            if (tasks.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_turned_in, size: 64, color: AppColors.textSecondaryLight),
                          SizedBox(height: AppSpacing.m),
                          Text(
                            'All caught up!',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            'Add a task using the button below.',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                final dateStr = DateFormat('MMM dd, yyyy').format(task.createdAt);

                return Dismissible(
                  key: Key('task-${task.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: AppColors.danger,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppSpacing.m),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) async {
                    try {
                      await ref.read(tasksProvider.notifier).deleteTask(task.id);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to delete task: $e'), backgroundColor: AppColors.danger),
                        );
                        ref.read(tasksProvider.notifier).refresh(); // reload to restore
                      }
                    }
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.xs),
                    child: ListTile(
                      title: Text(
                        task.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        'Created on $dateStr',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20, color: AppColors.textSecondaryLight),
                            onPressed: () => _showTaskDialog(context, ref, task: task),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: AppColors.danger),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Task'),
                                  content: const Text('Are you sure you want to delete this task?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                try {
                                  await ref.read(tasksProvider.notifier).deleteTask(task.id);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.danger),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                'Error: $err',
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
