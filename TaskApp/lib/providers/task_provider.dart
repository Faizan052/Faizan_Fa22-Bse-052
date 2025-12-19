import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../helpers/database_helper.dart';

class TaskState {
  final List<Task> tasks;
  final List<Task> completedTasks;
  final List<Task> repeatableTasks;
  final double overallProgress;
  final Map<int, double> taskProgress;

  const TaskState({
    required this.tasks,
    required this.completedTasks,
    required this.repeatableTasks,
    required this.overallProgress,
    this.taskProgress = const {},
  });

  TaskState copyWith({
    List<Task>? tasks,
    List<Task>? completedTasks,
    List<Task>? repeatableTasks,
    double? overallProgress,
    Map<int, double>? taskProgress,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      completedTasks: completedTasks ?? this.completedTasks,
      repeatableTasks: repeatableTasks ?? this.repeatableTasks,
      overallProgress: overallProgress ?? this.overallProgress,
      taskProgress: taskProgress ?? this.taskProgress,
    );
  }
}

class TaskNotifier extends StateNotifier<TaskState> {
  final DatabaseHelper _db;

  TaskNotifier(this._db)
      : super(const TaskState(
    tasks: [],
    completedTasks: [],
    repeatableTasks: [],
    overallProgress: 0.0,
    taskProgress: {},
  )) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      final tasksData = await _db.getTasks(isCompleted: false);
      final completedData = await _db.getTasks(isCompleted: true);
      final repeatableData = await _db.getTasks(isRepeatable: true);

      final Map<int, double> taskProgress = {};
      for (var taskData in tasksData) {
        if (taskData['id'] != null) {
          final taskId = taskData['id'] as int;
          try {
            taskProgress[taskId] = await _db.getTaskProgress(taskId);
          } catch (e) {
            taskProgress[taskId] = 0.0;
          }
        }
      }

      state = TaskState(
        tasks: tasksData.map((data) => Task.fromMap(data)).toList(),
        completedTasks:
        completedData.map((data) => Task.fromMap(data)).toList(),
        repeatableTasks:
        repeatableData.map((data) => Task.fromMap(data)).toList(),
        overallProgress: await _db.getOverallProgress(),
        taskProgress: taskProgress,
      );
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      state = const TaskState(
        tasks: [],
        completedTasks: [],
        repeatableTasks: [],
        overallProgress: 0.0,
        taskProgress: {},
      );
    }
  }

  Future<void> addTask(Task task) async {
    try {
      final id = await _db.insertTask(task.toMap());
      final newTask = task.copyWith(id: id);

      final updatedTasks = [...state.tasks, newTask];
      final updatedRepeatableTasks = task.isRepeatable
          ? [...state.repeatableTasks, newTask]
          : state.repeatableTasks;

      final updatedProgress = Map<int, double>.from(state.taskProgress);
      if (newTask.id != null) {
        updatedProgress[newTask.id!] = 0.0;
      }

      state = state.copyWith(
        tasks: updatedTasks,
        repeatableTasks: updatedRepeatableTasks,
        overallProgress: await _db.getOverallProgress(),
        taskProgress: updatedProgress,
      );
    } catch (e) {
      debugPrint('Error adding task: $e');
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      if (task.id == null) return;

      await _db.updateTask(task.toMap());

      final updatedTasks =
      state.tasks.map((t) => t.id == task.id ? task : t).toList();
      if (task.isCompleted) {
        updatedTasks.removeWhere((t) => t.id == task.id);
      }

      final updatedProgress = Map<int, double>.from(state.taskProgress);
      updatedProgress[task.id!] = task.isCompleted ? 1.0 : 0.0;

      state = state.copyWith(
        tasks: updatedTasks,
        completedTasks: task.isCompleted
            ? [...state.completedTasks, task]
            : state.completedTasks,
        overallProgress: await _db.getOverallProgress(),
        taskProgress: updatedProgress,
      );
    } catch (e) {
      debugPrint('Error updating task: $e');
    }
  }

  Future<void> deleteTask(Task task) async {
    try {
      if (task.id == null) return;

      await _db.deleteTask(task.id!);

      final updatedProgress = Map<int, double>.from(state.taskProgress);
      updatedProgress.remove(task.id);

      state = state.copyWith(
        tasks: state.tasks.where((t) => t.id != task.id).toList(),
        completedTasks:
        state.completedTasks.where((t) => t.id != task.id).toList(),
        repeatableTasks:
        state.repeatableTasks.where((t) => t.id != task.id).toList(),
        overallProgress: await _db.getOverallProgress(),
        taskProgress: updatedProgress,
      );
    } catch (e) {
      debugPrint('Error deleting task: $e');
    }
  }

  Future<void> regenerateRepeatableTasks() async {
    try {
      for (var task in state.repeatableTasks) {
        if (task.isCompleted && task.id != null) {
          final newTask = task.copyWith(
            id: null,
            isCompleted: false,
            createdAt: DateTime.now(),
          );
          await addTask(newTask);
        }
      }
      await loadTasks();
    } catch (e) {
      debugPrint('Error regenerating repeatable tasks: $e');
    }
  }
}

final databaseProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

final tasksProvider = StateNotifierProvider<TaskNotifier, TaskState>((ref) {
  final db = ref.watch(databaseProvider);
  return TaskNotifier(db);
});