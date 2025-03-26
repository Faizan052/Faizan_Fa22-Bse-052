import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/settings_provider.dart';

class TaskList extends ConsumerWidget {
  final List<Task> tasks;
  final String title;
  final bool showProgress;

  const TaskList({
    Key? key,
    required this.tasks,
    required this.title,
    this.showProgress = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      data: (settings) {
        if (tasks.isEmpty) {
          return Center(
            child: Text(
              'No tasks available',
              style: TextStyle(fontSize: settings.fontSize),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: settings.fontSize * 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (showProgress && tasks.isNotEmpty)
              Consumer(
                builder: (context, ref, child) {
                  final tasksAsync = ref.watch(tasksProvider);
                  return tasksAsync.when(
                    data: (taskState) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: LinearProgressIndicator(
                        value: taskState.overallProgress,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: LinearProgressIndicator(),
                    ),
                    error: (_, __) => const SizedBox(),
                  );
                },
              ),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Consumer(
                    builder: (context, ref, child) {
                      final tasksAsync = ref.watch(tasksProvider);
                      return tasksAsync.when(
                        data: (taskState) {
                          final progress = task.id != null
                              ? taskState.taskProgress[task.id] ?? 0.0
                              : 0.0;

                          return Slidable(
                            endActionPane: ActionPane(
                              motion: const ScrollMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (_) {
                                    if (task.id != null) {
                                      ref
                                          .read(tasksProvider.notifier)
                                          .deleteTask(task);
                                    }
                                  },
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete,
                                  label: 'Delete',
                                ),
                              ],
                            ),
                            child: ListTile(
                              leading: Checkbox(
                                value: task.isCompleted,
                                onChanged: (value) {
                                  if (value != null) {
                                    ref.read(tasksProvider.notifier).updateTask(
                                      task.copyWith(isCompleted: value),
                                    );
                                  }
                                },
                              ),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: settings.fontSize,
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              subtitle: task.description != null
                                  ? Text(
                                task.description!,
                                style: TextStyle(
                                  fontSize: settings.fontSize * 0.9,
                                ),
                              )
                                  : null,
                              trailing: showProgress
                                  ? SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey[200],
                                  valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).primaryColor,
                                  ),
                                ),
                              )
                                  : null,
                            ),
                          );
                        },
                        loading: () => const ListTile(
                          leading: CircularProgressIndicator(),
                          title: Text('Loading...'),
                        ),
                        error: (_, __) => ListTile(
                          title: Text(task.title),
                          subtitle: const Text('Error loading task state'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}
