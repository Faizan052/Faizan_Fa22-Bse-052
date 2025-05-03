import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import 'database.dart';
import 'edit_task.dart';

class TodayTaskPage extends StatefulWidget {
  final bool isDarkMode;
  final List<Map<String, dynamic>> tasks;

  const TodayTaskPage({
    super.key,
    required this.isDarkMode,
    required this.tasks,
  });

  @override
  _TodayTaskPageState createState() => _TodayTaskPageState();
}

class _TodayTaskPageState extends State<TodayTaskPage> with AutomaticKeepAliveClientMixin {
  late VideoPlayerController _controller;
  late List<Map<String, dynamic>> _tasks;
  bool _controllerInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tasks = widget.tasks;
    _initializeVideoController();
    _loadTasks();
  }

  void _initializeVideoController() {
    _controller = VideoPlayerController.asset('videos/today_task1.mp4')
      ..addListener(_onControllerUpdate)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _controllerInitialized = true;
            _controller.setLooping(true);
            _controller.play();
            debugPrint('🎥 TodayTask video initialized and playing');
          });
        }
      }).catchError((error) {
        debugPrint('❌ TodayTask video initialization error: $error');
        setState(() {
          _controllerInitialized = false;
        });
        // Attempt reinitialization after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && !_controllerInitialized) {
            debugPrint('🔄 Attempting to reinitialize TodayTask video controller');
            _initializeVideoController();
          }
        });
      });
  }

  void _onControllerUpdate() {
    if (_controller.value.hasError && _controllerInitialized) {
      debugPrint('❌ TodayTask video playback error: ${_controller.value.errorDescription}');
      setState(() {
        _controllerInitialized = false;
      });
      _controller.removeListener(_onControllerUpdate);
      _initializeVideoController();
    }
  }

  void _ensureVideoPlaying() {
    if (_controllerInitialized && !_controller.value.isPlaying) {
      Future.microtask(() {
        if (mounted) {
          _controller.play();
          debugPrint('▶️ Resumed TodayTask video playback');
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureVideoPlaying();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTasks(); // Refresh tasks when page regains focus
    });
  }

  @override
  void deactivate() {
    if (_controllerInitialized && _controller.value.isPlaying) {
      _controller.pause();
      debugPrint('⏸️ Paused TodayTask video in deactivate');
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    if (_controllerInitialized) {
      _controller.dispose();
      debugPrint('🗑️ Disposed TodayTask VideoPlayerController');
    }
    super.dispose();
  }

  Future<void> _loadTasks() async {
    final db = TaskDatabase.instance;
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);

    // Query tasks with DISTINCT to avoid duplicates
    final todayTasks = await db.query(
      'tasks',
      columns: ['DISTINCT id', '*'],
      where: '(isRepeated = 0 AND date(dueDate) = date(?)) OR '
          '(isRepeated = 1 AND date(instanceDate) = date(?))',
      whereArgs: [todayStr, todayStr],
      orderBy: 'dueDate ASC',
      limit: TextField.noMaxLength,
    );

    // Deduplicate tasks in code
    final seen = <String>{};
    final uniqueTasks = todayTasks.where((task) {
      final key = '${task['title']}_${task['dueDate']}_${task['instanceDate'] ?? ''}_${task['parentId'] ?? ''}';
      return seen.add(key);
    }).toList();

    debugPrint('📋 Loaded ${uniqueTasks.length} unique tasks for today:');
    for (var task in uniqueTasks) {
      debugPrint(
          '   Task ID: ${task['id']}, Title: ${task['title']}, InstanceDate: ${task['instanceDate']}, DueDate: ${task['dueDate']}, ParentId: ${task['parentId']}');
    }

    if (mounted) {
      setState(() {
        _tasks = uniqueTasks.where((task) => task['isCompleted'] == 0).toList();
      });
    }
  }

  bool _isRepeatedTaskForToday(Map<String, dynamic> task) {
    if (task['isRepeated'] != 1) return false;

    // For main repeated tasks (without instanceDate)
    if (task['instanceDate'] == null) {
      final today = DateFormat('EEEE').format(DateTime.now());
      final repeatDays = task['repeatDays']?.toString().split(',') ?? [];
      return repeatDays.contains(today);
    }

    // For repeated task instances
    return true;
  }

  Future<void> _deleteTask(int id) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => _buildConfirmationDialog(
        title: 'Delete Task',
        content: 'Are you sure you want to delete this task?',
        confirmText: 'Delete',
        isDelete: true,
      ),
    );

    if (shouldDelete == true) {
      try {
        final db = TaskDatabase.instance;
        final deleteCount = await db.deleteTask(id);
        debugPrint('🗑️ Deleted task ID: $id (count: $deleteCount)');

        if (mounted) {
          setState(() {
            _tasks.removeWhere((task) => task['id'] == id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task deleted successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadTasks(); // Refresh tasks after deletion
        }
      } catch (e, stackTrace) {
        debugPrint('❌ Error deleting task: $e');
        debugPrint('Stack trace: $stackTrace');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete task: $e'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleComplete(Map<String, dynamic> task) async {
    final shouldComplete = await showDialog<bool>(
      context: context,
      builder: (context) => _buildConfirmationDialog(
        title: 'Mark as Completed',
        content: 'Mark this task as completed?',
        confirmText: 'Complete',
      ),
    );

    if (shouldComplete == true) {
      final db = TaskDatabase.instance;
      final updatedTask = Map<String, dynamic>.from(task);
      updatedTask['isCompleted'] = 1;
      updatedTask['type'] = 'Completed';
      await db.updateTask(updatedTask);
      if (mounted) {
        setState(() {
          _tasks.removeWhere((t) => t['id'] == task['id']);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task marked as completed'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadTasks(); // Refresh tasks after completion
      }
    }
  }

  Widget _buildConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    bool isDelete = false,
  }) {
    return AlertDialog(
      backgroundColor: widget.isDarkMode ? Colors.grey[900] : Colors.white,
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
          color: widget.isDarkMode ? Colors.white70 : Colors.black87,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            confirmText,
            style: TextStyle(
              color: isDelete ? Colors.red : (widget.isDarkMode ? Colors.teal[400]! : Colors.blue[600]!),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(Map<String, dynamic> task) {
    final isRepeated = _isRepeatedTaskForToday(task);

    return Card(
      elevation: 4,
      color: widget.isDarkMode ? Colors.grey[800] : Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            if (isRepeated)
              Tooltip(
                message: 'Repeating task',
                child: Icon(
                  Icons.repeat,
                  size: 18,
                  color: widget.isDarkMode ? Colors.teal[400] : Colors.blue[600],
                ),
              ),
            if (isRepeated) const SizedBox(width: 8),
            Expanded(
              child: Text(
                task['title'],
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isRepeated && task['repeatTime'] != null)
              Text(
                'Time: ${task['repeatTime']}',
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            Text(
              'Due: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(task['instanceDate'] ?? task['dueDate']))}',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            if (task['description'] != null && task['description'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  task['description'],
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white60 : Colors.black45,
                  ),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: 'Edit Task',
              child: IconButton(
                icon: Icon(
                  Icons.edit,
                  color: widget.isDarkMode ? Colors.teal[400] : Colors.blue[600],
                ),
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
                  if (editedTask != null) {
                    _loadTasks(); // Reload tasks after editing
                    _ensureVideoPlaying(); // Ensure video resumes after returning
                  }
                },
              ),
            ),
            Tooltip(
              message: 'Mark as Completed',
              child: IconButton(
                icon: Icon(
                  Icons.check,
                  color: widget.isDarkMode ? Colors.teal[400] : Colors.blue[600],
                ),
                onPressed: () async {
                  await _toggleComplete(task);
                  _ensureVideoPlaying(); // Ensure video resumes after dialog
                },
              ),
            ),
            Tooltip(
              message: 'Delete Task',
              child: IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: Colors.redAccent,
                ),
                onPressed: () async {
                  await _deleteTask(task['id']);
                  _ensureVideoPlaying(); // Ensure video resumes after dialog
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    // Ensure video resumes after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureVideoPlaying();
    });

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
        body: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.3,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    color: widget.isDarkMode ? Colors.grey[900] : Colors.white,
                  ),
                  if (_controllerInitialized)
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
                      title: const Text(
                        'Today\'s Tasks',
                        style: TextStyle(color: Colors.black),
                      ),
                      centerTitle: true,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.isDarkMode
                        ? [Colors.grey[900]!, Colors.grey[800]!]
                        : [Colors.blue[50]!, Colors.teal[50]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: _tasks.isEmpty
                    ? Center(
                  child: Text(
                    'No tasks for today',
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 18,
                    ),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return _buildTaskItem(task);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}