import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import 'database.dart';
import 'edit_task.dart';

class RepeatedTaskPage extends StatefulWidget {
  final bool isDarkMode;
  final List<Map<String, dynamic>> tasks;

  const RepeatedTaskPage({
    super.key,
    required this.isDarkMode,
    required this.tasks,
  });

  @override
  _RepeatedTaskPageState createState() => _RepeatedTaskPageState();
}

class _RepeatedTaskPageState extends State<RepeatedTaskPage> {
  late VideoPlayerController _controller;
  late Future<List<Map<String, dynamic>>> _tasksFuture;
  Map<int, bool> _expandedTasks = {};

  @override
  void initState() {
    super.initState();
    _initializeController();
    _loadTasks();
  }

  void _initializeController() {
    _controller = VideoPlayerController.asset('videos/repeated_task.mp4')
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _controller.setLooping(true);
            _controller.play();
          });
        }
      });
  }

  void _loadTasks() {
    setState(() {
      _tasksFuture = _loadMainTasks();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _deleteTask(int id) async {
    final db = TaskDatabase.instance;
    final task = (await db.query('tasks', where: 'id = ?', whereArgs: [id])).firstOrNull;
    if (task == null) {
      debugPrint('⚠️ Task ID: $id not found');
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDeleteTaskDialog(id),
    );

    if (shouldDelete != true) return;

    try {
      debugPrint('🗑️ Attempting to delete task ID: $id and its instances');

      // Verify database state before deletion
      await db.debugDatabaseContents();

      // Delete tasks with matching attributes to handle duplicates
      await db.transaction((txn) async {
        // Delete all instances for this task
        final instanceCount = await txn.delete(
          'tasks',
          where: 'parentId = ?',
          whereArgs: [id],
        );
        debugPrint('🗑️ Deleted $instanceCount instances for task ID: $id');

        // Delete the main task
        final mainTaskCount = await txn.delete(
          'tasks',
          where: 'id = ?',
          whereArgs: [id],
        );
        debugPrint('🗑️ Deleted main task ID: $id (count: $mainTaskCount)');

        // Delete any duplicate main tasks with the same attributes
        final duplicateCount = await txn.delete(
          'tasks',
          where: 'title = ? AND repeatDays = ? AND repeatTime = ? AND dueDate = ? AND isRepeated = 1 AND instanceDate IS NULL AND id != ?',
          whereArgs: [
            task['title'],
            task['repeatDays'] ?? '',
            task['repeatTime'] ?? '',
            task['dueDate'],
            id,
          ],
        );
        debugPrint('🗑️ Deleted $duplicateCount duplicate main tasks for ${task['title']}');
      });

      // Verify database state after deletion
      await db.debugDatabaseContents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task and all instances deleted successfully')),
        );
        _loadTasks(); // Refresh the task list
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error deleting task: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete task. Please try again.')),
        );
      }
    }
  }

  Future<void> _deleteTaskInstance(int taskId, String instanceDate) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => _buildConfirmationDialog(
        title: 'Delete Instance',
        content: 'Are you sure you want to delete this task instance?',
        confirmText: 'Delete',
        isDelete: true,
      ),
    );

    if (shouldDelete != true) return;

    try {
      final db = TaskDatabase.instance;
      final deleteCount = await db.delete(
        'tasks',
        where: 'parentId = ? AND instanceDate = ?',
        whereArgs: [taskId, instanceDate],
      );
      debugPrint('🗑️ Deleted $deleteCount instance(s) for task ID: $taskId on $instanceDate');

      if (mounted) {
        setState(() {
          _expandedTasks[taskId] = true; // Refresh the expanded state
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Instance deleted successfully')),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error deleting instance: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete instance')),
        );
      }
    }
  }

  Widget _buildDeleteTaskDialog(int taskId) {
    return AlertDialog(
      backgroundColor: widget.isDarkMode ? Colors.grey[850] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Delete Repeated Task',
        style: TextStyle(
          color: widget.isDarkMode ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This will permanently delete:',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• The main repeated task',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          Text(
            '• All future instances',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            'Delete All',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    bool isDelete = false,
  }) {
    return AlertDialog(
      backgroundColor: widget.isDarkMode ? Colors.grey[850] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: TextStyle(
          color: widget.isDarkMode ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        content,
        style: TextStyle(
          color: widget.isDarkMode ? Colors.white70 : Colors.black54,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            confirmText,
            style: TextStyle(
              color: isDelete ? Colors.redAccent : Colors.blue[600]!,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  String _formatRepeatDays(String? repeatDays) {
    if (repeatDays == null || repeatDays.isEmpty) return 'No days selected';
    final days = repeatDays.split(',');
    if (days.length == 7) return 'Every day';
    return days.join(', ');
  }

  Future<List<Map<String, dynamic>>> _loadMainTasks() async {
    try {
      final db = TaskDatabase.instance;
      final mainTasks = await db.readRepeatedTasks();

      // Deduplicate tasks based on title, repeatDays, repeatTime, dueDate
      final seen = <String>{};
      final uniqueTasks = mainTasks.where((task) {
        final key = '${task['title']}_${task['repeatDays']}_${task['repeatTime']}_${task['dueDate']}';
        return seen.add(key);
      }).toList();

      // Initialize expanded state for new tasks
      final newExpandedTasks = <int, bool>{};
      for (var task in uniqueTasks) {
        newExpandedTasks[task['id'] as int] = _expandedTasks[task['id'] as int] ?? false;
      }

      if (mounted) {
        setState(() {
          _expandedTasks = newExpandedTasks;
        });
      }

      debugPrint('📋 Loaded ${uniqueTasks.length} main repeated tasks');
      return uniqueTasks;
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading main tasks: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadTaskInstances(int parentId) async {
    try {
      final db = TaskDatabase.instance;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final instances = await db.query(
        'tasks',
        where: 'parentId = ? AND instanceDate >= ?',
        whereArgs: [parentId, today],
        orderBy: 'instanceDate ASC',
        limit: TextField.noMaxLength,
      );

      debugPrint('📋 Loaded ${instances.length} instances for parentId: $parentId');
      return instances;
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading instances for parentId $parentId: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  Widget _buildTaskItem(Map<String, dynamic> task) {
    final taskId = task['id'] as int;
    final isExpanded = _expandedTasks[taskId] ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: widget.isDarkMode ? Colors.grey[900] : Colors.grey[100],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _expandedTasks[taskId] = !isExpanded;
                  });
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.repeat,
                      color: widget.isDarkMode ? Colors.amber : Colors.blue[600],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task['title'] ?? 'Untitled',
                        style: TextStyle(
                          color: widget.isDarkMode ? Colors.white : Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.arrow_drop_down,
                        color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Repeats: ${_formatRepeatDays(task['repeatDays'])}',
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 16,
                ),
              ),
              if (task['description'] != null && task['description'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    task['description'],
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white60 : Colors.black45,
                      fontSize: 14,
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: widget.isDarkMode ? Colors.teal[400] : Colors.blue[600],
                    ),
                    tooltip: 'Edit Task',
                    onPressed: () async {
                      final editedTask = await Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 800),
                          pageBuilder: (context, animation, secondaryAnimation) => EditTaskPage(
                            isDarkMode: widget.isDarkMode,
                            task: task,
                          ),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.easeInOut;
                            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                            var offsetAnimation = animation.drive(tween);
                            return SlideTransition(position: offsetAnimation, child: child);
                          },
                        ),
                      );
                      if (editedTask != null && mounted) {
                        _loadTasks();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.redAccent,
                    ),
                    tooltip: 'Delete Task and All Instances',
                    onPressed: () => _deleteTask(taskId),
                  ),
                ],
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                firstChild: const SizedBox(),
                secondChild: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _loadTaskInstances(taskId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Error loading instances', style: TextStyle(color: Colors.red)),
                      );
                    }
                    final instances = snapshot.data ?? [];
                    if (instances.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No upcoming instances found', style: TextStyle(fontStyle: FontStyle.italic)),
                      );
                    }
                    return Column(
                      children: instances.map((instance) {
                        final dueDate = DateTime.parse(instance['instanceDate']);
                        return Dismissible(
                          key: Key('$taskId-${dueDate.millisecondsSinceEpoch}'),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (context) => _buildConfirmationDialog(
                                title: 'Delete Instance',
                                content: 'Delete instance for "${task['title']}" on ${DateFormat('EEE, MMM dd, HH:mm').format(dueDate)}?',
                                confirmText: 'Delete',
                                isDelete: true,
                              ),
                            );
                          },
                          onDismissed: (direction) async {
                            await _deleteTaskInstance(taskId, instance['instanceDate']);
                          },
                          background: Container(
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: widget.isDarkMode ? Colors.amber : Colors.blue[600]!,
                                  width: 4,
                                ),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              leading: Icon(
                                Icons.circle,
                                size: 12,
                                color: widget.isDarkMode ? Colors.amber : Colors.blue[600],
                              ),
                              title: Text(
                                DateFormat('EEE, MMM dd, HH:mm').format(dueDate),
                                style: TextStyle(
                                  color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                'Time: ${instance['repeatTime'] ?? 'N/A'}',
                                style: TextStyle(
                                  color: widget.isDarkMode ? Colors.white60 : Colors.black45,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => _deleteTaskInstance(taskId, instance['instanceDate']),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = widget.isDarkMode
        ? [Colors.grey[900]!, Colors.grey[800]!]
        : [Colors.blue[50]!, Colors.teal[50]!];

    return Theme(
      data: widget.isDarkMode
          ? ThemeData.dark().copyWith(
        primaryColor: Colors.indigo[900],
        scaffoldBackgroundColor: Colors.grey[900],
      )
          : ThemeData.light().copyWith(
        primaryColor: Colors.blue[800],
        scaffoldBackgroundColor: Colors.white,
      ),
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await TaskDatabase.instance.repairRepeatedTasks();
            if (mounted) {
              _loadTasks();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Database repaired')),
              );
            }
          },
          child: const Icon(Icons.build),
          tooltip: 'Repair Tasks',
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.3,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_controller.value.isInitialized)
                      SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _controller.value.size.width,
                            height: _controller.value.size.height,
                            child: VideoPlayer(_controller),
                          ),
                        ),
                      )
                    else
                      const Center(child: CircularProgressIndicator()),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: AppBar(
                        title: const Text('Repeated Tasks'),
                        centerTitle: true,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        leading: IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: widget.isDarkMode ? Colors.white : Colors.black87,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    _loadTasks();
                  },
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _tasksFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text('Error loading tasks'));
                      }
                      final tasks = snapshot.data ?? [];
                      if (tasks.isEmpty) {
                        return const Center(child: Text('No repeated tasks found'));
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return _buildTaskItem(task);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}