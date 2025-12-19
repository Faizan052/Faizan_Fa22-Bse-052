import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        isCompleted INTEGER NOT NULL,
        isRepeatable INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        parentId INTEGER,
        FOREIGN KEY (parentId) REFERENCES tasks (id)
      )
    ''');
  }

  Future<int> insertTask(Map<String, dynamic> task) async {
    final db = await database;
    return await db.insert('tasks', task);
  }

  Future<List<Map<String, dynamic>>> getTasks(
      {bool? isCompleted, bool? isRepeatable}) async {
    final db = await database;
    String whereClause = '';
    List<String> conditions = [];

    if (isCompleted != null) {
      conditions.add('isCompleted = ${isCompleted ? 1 : 0}');
    }
    if (isRepeatable != null) {
      conditions.add('isRepeatable = ${isRepeatable ? 1 : 0}');
    }

    if (conditions.isNotEmpty) {
      whereClause = 'WHERE ${conditions.join(' AND ')}';
    }

    return await db.query('tasks', where: whereClause);
  }

  Future<int> updateTask(Map<String, dynamic> task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task,
      where: 'id = ?',
      whereArgs: [task['id']],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getSubtasks(int parentId) async {
    final db = await database;
    return await db.query(
      'tasks',
      where: 'parentId = ?',
      whereArgs: [parentId],
    );
  }

  Future<double> getTaskProgress(int taskId) async {
    final db = await database;
    final subtasks = await getSubtasks(taskId);

    if (subtasks.isEmpty) {
      final task = await db.query(
        'tasks',
        where: 'id = ?',
        whereArgs: [taskId],
      );
      if (task.isEmpty) return 0.0;
      return task.first['isCompleted'] == 1 ? 1.0 : 0.0;
    }

    final completedSubtasks =
        subtasks.where((subtask) => subtask['isCompleted'] == 1).length;
    return subtasks.isEmpty ? 0.0 : completedSubtasks / subtasks.length;
  }

  Future<double> getOverallProgress() async {
    final db = await database;
    final tasks = await getTasks(isCompleted: false);

    if (tasks.isEmpty) return 1.0;

    double totalProgress = 0;
    for (var task in tasks) {
      if (task['id'] != null) {
        totalProgress += await getTaskProgress(task['id']);
      }
    }

    return tasks.isEmpty ? 1.0 : totalProgress / tasks.length;
  }
}