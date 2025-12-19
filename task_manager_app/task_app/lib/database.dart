import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

class TaskDatabase {
  static final TaskDatabase instance = TaskDatabase._init();
  static Database? _database;

  TaskDatabase._init();

  Future<void> verifyDatabaseStructure() async {
    final db = await database;
    try {
      final columns = await db.rawQuery('PRAGMA table_info(tasks)');
      debugPrint('Database columns:');
      for (var col in columns) {
        debugPrint('- ${col['name']}: ${col['type']}');
      }

      final repeatedTasks = await db.query(
        'tasks',
        where: 'isRepeated = 1 AND instanceDate IS NULL',
      );
      debugPrint('Main repeated tasks count: ${repeatedTasks.length}');

      for (var task in repeatedTasks) {
        final instances = await db.query(
          'tasks',
          where: 'parentId = ?',
          whereArgs: [task['id']],
        );
        debugPrint('Task ${task['id']} (${task['title']}) has ${instances.length} instances');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Database verification error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> debugDatabaseContents() async {
    final db = await database;
    debugPrint('====== DATABASE DEBUG INFO ======');

    // Check schema
    final columns = await db.rawQuery('PRAGMA table_info(tasks)');
    debugPrint('Table columns:');
    for (var col in columns) {
      debugPrint('- ${col['name']}: ${col['type']}');
    }

    // Check all tasks
    final allTasks = await db.query('tasks');
    debugPrint('\nAll tasks (${allTasks.length}):');
    for (var task in allTasks) {
      debugPrint('''
    ID: ${task['id']}
    Title: ${task['title']}
    Type: ${task['type']}
    IsRepeated: ${task['isRepeated']}
    RepeatDays: ${task['repeatDays']}
    RepeatTime: ${task['repeatTime']}
    DueDate: ${task['dueDate']}
    InstanceDate: ${task['instanceDate']}
    ParentId: ${task['parentId']}
    IsCompleted: ${task['isCompleted']}
    ''');
    }

    debugPrint('=================================');
  }

  Future<void> cleanupDuplicateMainTasks() async {
    final db = await database;
    debugPrint('🧹 Starting cleanup of duplicate main tasks');

    // Get all main repeated tasks
    final mainTasks = await db.query(
      'tasks',
      where: 'isRepeated = 1 AND instanceDate IS NULL',
    );

    // Group tasks by title, repeatDays, repeatTime, dueDate
    final taskGroups = <String, List<Map<String, dynamic>>>{};
    for (var task in mainTasks) {
      final key = '${task['title']}_${task['repeatDays']}_${task['repeatTime']}_${task['dueDate']}';
      taskGroups.putIfAbsent(key, () => []).add(task);
    }

    // Process each group
    for (var group in taskGroups.values) {
      if (group.length <= 1) continue; // No duplicates

      // Keep the task with the lowest ID
      final keepTask = group.reduce((a, b) => (a['id'] as int) < (b['id'] as int) ? a : b);
      final keepId = keepTask['id'] as int;
      final deleteIds = group.where((t) => t['id'] != keepId).map((t) => t['id'] as int).toList();

      debugPrint('🧹 Consolidating ${group.length} tasks for ${keepTask['title']} (keep ID: $keepId, delete IDs: $deleteIds)');

      await db.transaction((txn) async {
        // Update instances to point to the kept task
        for (var deleteId in deleteIds) {
          final instanceCount = await txn.update(
            'tasks',
            {'parentId': keepId},
            where: 'parentId = ?',
            whereArgs: [deleteId],
          );
          debugPrint('🔄 Updated $instanceCount instances from parentId $deleteId to $keepId');
        }

        // Delete duplicate main tasks
        for (var deleteId in deleteIds) {
          final deleteCount = await txn.delete(
            'tasks',
            where: 'id = ?',
            whereArgs: [deleteId],
          );
          debugPrint('🗑️ Deleted duplicate main task ID: $deleteId (count: $deleteCount)');
        }
      });
    }

    debugPrint('🧹 Cleanup completed');
  }

  Future<void> repairRepeatedTasks() async {
    final db = await database;
    debugPrint('🛠️ Starting database repair for repeated tasks');

    // Clean up duplicate main tasks first
    await cleanupDuplicateMainTasks();

    final mainTasks = await db.query(
      'tasks',
      where: 'isRepeated = 1 AND instanceDate IS NULL',
    );

    for (var task in mainTasks) {
      debugPrint('🔧 Repairing task ${task['id']}: ${task['title']}');

      // Delete existing instances
      await db.delete(
        'tasks',
        where: 'parentId = ?',
        whereArgs: [task['id']],
      );

      // Recreate instances
      await _createTaskInstances(db, task['id'] as int, task);
    }
  }

  Future<void> updateRepeatedTask(Map<String, dynamic> task) async {
    final db = await database;
    final id = task['id'] as int;

    await db.transaction((txn) async {
      // Update the main task
      final updateCount = await txn.update(
        'tasks',
        task,
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('🔄 Updated main task ID: $id (count: $updateCount)');

      // If the task is repeated, regenerate instances
      if (task['isRepeated'] == 1 && task['instanceDate'] == null) {
        // Delete existing instances
        final instanceCount = await txn.delete(
          'tasks',
          where: 'parentId = ?',
          whereArgs: [id],
        );
        debugPrint('🗑️ Deleted $instanceCount instances for task ID: $id');

        // Recreate instances
        await _createTaskInstances(txn, id, task);
      }
    });
  }

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
      version: 3,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE tasks ADD COLUMN instanceDate TEXT");
        }
        if (oldVersion < 3) {
          await db.execute("ALTER TABLE tasks ADD COLUMN parentId INTEGER");
        }
        if (oldVersion < 4) {
          await db.execute("UPDATE tasks SET type = 'single' WHERE type IS NULL");
          await db.execute("UPDATE tasks SET type = 'repeated' WHERE isRepeated = 1");
        }
      },
    );
  }

  Future<int> insertTask(Map<String, dynamic> task) async {
    final db = await database;
    return await db.insert('tasks', task);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE tasks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT,
      dueDate TEXT NOT NULL,
      type TEXT NOT NULL,
      isCompleted INTEGER NOT NULL,
      isRepeated INTEGER NOT NULL,
      repeatDays TEXT,
      repeatTime TEXT,
      createdAt TEXT NOT NULL,
      parentId INTEGER,
      instanceDate TEXT
    )
    ''');
  }

  Future<int> createTask(Map<String, dynamic> task) async {
    final db = await database;
    debugPrint('🚀 Creating task: ${task['title']}');

    // Ensure required fields are present
    if (!task.containsKey('type')) {
      task['type'] = task['isRepeated'] == 1 ? 'repeated' : 'single';
    }

    // Check for existing task to prevent duplicates
    final existingTasks = await db.query(
      'tasks',
      where: 'title = ? AND dueDate = ? AND isRepeated = ?',
      whereArgs: [task['title'], task['dueDate'], task['isRepeated']],
    );

    if (task['isRepeated'] == 1) {
      // For repeated tasks, also check repeatDays and repeatTime
      final matchingTask = existingTasks.firstWhere(
            (t) =>
        t['repeatDays'] == task['repeatDays'] &&
            t['repeatTime'] == task['repeatTime'] &&
            t['instanceDate'] == null,
        orElse: () => <String, dynamic>{},
      );

      if (matchingTask.isNotEmpty) {
        debugPrint('⚠️ Task already exists with ID: ${matchingTask['id']}');
        return matchingTask['id'] as int;
      }

      // Insert main task without ID
      final mainTask = Map<String, dynamic>.from(task);
      mainTask.remove('instanceDate');
      mainTask.remove('id');

      final id = await db.insert('tasks', mainTask);
      debugPrint('✅ Main task created with ID: $id');

      // Create instances
      await _createTaskInstances(db, id, task);
      return id;
    } else {
      // For non-repeated tasks
      if (existingTasks.isNotEmpty) {
        debugPrint('⚠️ Non-repeated task already exists with ID: ${existingTasks.first['id']}');
        return existingTasks.first['id'] as int;
      }

      task.remove('id');
      return await db.insert('tasks', task);
    }
  }

  Future<void> _createTaskInstances(DatabaseExecutor dbExecutor, int parentId, Map<String, dynamic> parentTask) async {
    final repeatDays = (parentTask['repeatDays']?.toString().split(',') ?? [])
        .map((day) => day.trim())
        .where((day) => day.isNotEmpty)
        .toList();

    final repeatTime = parentTask['repeatTime'] ?? '00:00';
    final now = DateTime.now();
    int createdCount = 0;

    debugPrint('🔁 Creating instances for task ID: $parentId, days: $repeatDays');

    for (int i = 0; i < 30; i++) {
      final date = now.add(Duration(days: i));
      final dayName = DateFormat('EEEE').format(date);
      final normalizedDayName = dayName.toLowerCase();

      if (repeatDays.any((d) => d.trim().toLowerCase() == normalizedDayName)) {
        final instanceDate = DateFormat('yyyy-MM-dd').format(date);

        // Check for existing instance
        final existingInstances = await dbExecutor.query(
          'tasks',
          where: 'parentId = ? AND instanceDate = ?',
          whereArgs: [parentId, instanceDate],
        );

        if (existingInstances.isNotEmpty) {
          debugPrint('⚠️ Skipping instance for $instanceDate (already exists for parentId: $parentId)');
          continue;
        }

        try {
          await dbExecutor.insert('tasks', {
            'title': parentTask['title'],
            'description': parentTask['description'],
            'dueDate': instanceDate,
            'type': parentTask['type'] ?? 'repeated',
            'isCompleted': 0,
            'isRepeated': 1,
            'repeatDays': parentTask['repeatDays'],
            'repeatTime': repeatTime,
            'createdAt': DateFormat('yyyy-MM-dd HH:mm:ss').format(now),
            'parentId': parentId,
            'instanceDate': instanceDate,
          });
          createdCount++;
          debugPrint('   ➕ Created instance for $dayName on $instanceDate');
        } catch (e, stackTrace) {
          debugPrint('❌ Error creating instance for $instanceDate: $e');
          debugPrint('Stack trace: $stackTrace');
        }
      }
    }

    debugPrint('🎉 Created $createdCount instances for task $parentId');
  }

  bool equalsIgnoreCase(String a, String b) {
    return a.toLowerCase() == b.toLowerCase();
  }

  Future<List<Map<String, dynamic>>> readAllTasks() async {
    final db = await database;
    return await db.query('tasks');
  }

  Future<List<Map<String, dynamic>>> readTodayTasks() async {
    final db = await database;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return await db.query(
      'tasks',
      where: '((isRepeated = 0 AND date(dueDate) = date(?)) OR '
          '(isRepeated = 1 AND date(instanceDate) = date(?))) '
          'AND isCompleted = 0',
      whereArgs: [today, today],
    );
  }

  Future<List<Map<String, dynamic>>> readRepeatedTasks() async {
    final db = await database;
    return await db.query(
      'tasks',
      where: 'isRepeated = 1 AND instanceDate IS NULL',
    );
  }

  Future<List<Map<String, dynamic>>> readCompletedTasks() async {
    final db = await database;
    return await db.query(
      'tasks',
      where: 'isCompleted = 1',
    );
  }

  Future<List<Map<String, dynamic>>> readTasksByType(String type) async {
    final db = await database;
    if (type == 'Completed') {
      return db.query('tasks', where: 'isCompleted = 1');
    } else if (type == 'Pending') {
      return db.query('tasks', where: 'isCompleted = 0');
    } else {
      return db.query('tasks');
    }
  }

  Future<List<Map<String, dynamic>>> query(
      String table, {
        List<String>? columns,
        String? where,
        List<Object?>? whereArgs,
        String? orderBy,
        int? limit,
      }) async {
    final db = await database;
    return db.query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
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
    int totalDeleted = 0;

    await db.transaction((txn) async {
      // Delete all instances first
      final instanceCount = await txn.delete(
        'tasks',
        where: 'parentId = ?',
        whereArgs: [id],
      );
      debugPrint('🗑️ Deleted $instanceCount instances for task ID: $id');
      totalDeleted += instanceCount;

      // Delete the main task
      final mainTaskCount = await txn.delete(
        'tasks',
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('🗑️ Deleted main task ID: $id (count: $mainTaskCount)');
      totalDeleted += mainTaskCount;
    });

    return totalDeleted;
  }

  Future<int> delete(String table, {required String where, required List<Object> whereArgs}) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }
}