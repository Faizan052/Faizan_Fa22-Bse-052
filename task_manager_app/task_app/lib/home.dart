import 'dart:io';
import 'package:flutter/material.dart';
import 'package:task_app/repeated_task.dart';
import 'package:task_app/today_task.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'add_task.dart';
import 'completed_task.dart';
import 'database.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  late VideoPlayerController _controller;
  bool _isDarkMode = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _controllerInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeVideoController();
  }

  void _initializeVideoController() {
    _controller = VideoPlayerController.asset('videos/hometasks.mp4')
      ..addListener(_onControllerUpdate)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _controllerInitialized = true;
            _controller.setLooping(true);
            _controller.play();
            debugPrint('🎥 Video initialized and playing');
          });
        }
      }).catchError((error) {
        debugPrint('❌ Video initialization error: $error');
        setState(() {
          _controllerInitialized = false;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && !_controllerInitialized) {
            debugPrint('🔄 Attempting to reinitialize video controller');
            _initializeVideoController();
          }
        });
      });
  }

  void _onControllerUpdate() {
    if (_controller.value.hasError && _controllerInitialized) {
      debugPrint('❌ Video playback error: ${_controller.value.errorDescription}');
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
          debugPrint('▶️ Resumed video playback');
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureVideoPlaying();
  }

  @override
  void deactivate() {
    if (_controllerInitialized && _controller.value.isPlaying) {
      _controller.pause();
      debugPrint('⏸️ Paused video in deactivate');
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    if (_controllerInitialized) {
      _controller.dispose();
      debugPrint('🗑️ Disposed VideoPlayerController');
    }
    super.dispose();
  }

  void _toggleTheme() {
    if (mounted) {
      setState(() {
        _isDarkMode = !_isDarkMode;
      });
    }
  }

  Future<void> _shareTodayTasks() async {
    try {
      final db = TaskDatabase.instance;
      final tasks = await db.readTodayTasks();
      debugPrint('📤 Fetching ${tasks.length} today\'s tasks for sharing');

      if (tasks.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No tasks available to share'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Generate CSV
      final buffer = StringBuffer();
      buffer.writeln('ID,Title,Description,Due Date,Is Completed,Is Repeated,Repeat Days,Repeat Time,Instance Date,Parent ID');
      for (var task in tasks) {
        final fields = [
          task['id']?.toString() ?? '',
          '"${task['title']?.replaceAll('"', '""') ?? ''}"',
          '"${task['description']?.replaceAll('"', '""') ?? ''}"',
          task['dueDate']?.toString() ?? '',
          task['isCompleted']?.toString() ?? '0',
          task['isRepeated']?.toString() ?? '0',
          '"${task['repeatDays']?.replaceAll('"', '""') ?? ''}"',
          task['repeatTime']?.toString() ?? '',
          task['instanceDate']?.toString() ?? '',
          task['parentId']?.toString() ?? '',
        ];
        buffer.writeln(fields.join(','));
      }

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/today_tasks_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(buffer.toString());
      debugPrint('📄 CSV file created at: ${file.path}');

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Today\'s Tasks Export',
        text: 'Here are today\'s tasks exported as a CSV file.',
      );
      debugPrint('📤 Shared today\'s tasks CSV');

      // Clean up
      await file.delete();
      debugPrint('🗑️ Deleted temporary CSV file');
    } catch (e, stackTrace) {
      debugPrint('❌ Error sharing tasks: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share tasks: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureVideoPlaying();
    });

    return Theme(
      data: _isDarkMode
          ? ThemeData.dark().copyWith(
        primaryColor: Colors.indigo[900],
        scaffoldBackgroundColor: Colors.grey[900],
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      )
          : ThemeData.light().copyWith(
        primaryColor: Colors.blue[800],
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      child: Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
          width: 200,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isDarkMode
                        ? [Colors.indigo[900]!, Colors.teal[800]!]
                        : [Colors.blue[800]!, Colors.teal[600]!],
                  ),
                ),
                child: const Text(
                  'Task Manager Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black45,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              ListTile(
                leading: Icon(Icons.home,
                    color: _isDarkMode ? Colors.white70 : Colors.blue[800]),
                title: Text(
                  'Home',
                  style: TextStyle(
                      color: _isDarkMode ? Colors.white70 : Colors.blue[800],
                      fontSize: 18),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.settings,
                    color: _isDarkMode ? Colors.white70 : Colors.blue[800]),
                title: Text(
                  'Settings',
                  style: TextStyle(
                      color: _isDarkMode ? Colors.white70 : Colors.blue[800],
                      fontSize: 18),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.3,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      color: _isDarkMode ? Colors.grey[900] : Colors.white,
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
                      const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.menu,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                onPressed: () {
                                  _scaffoldKey.currentState?.openDrawer();
                                },
                              ),
                              Text(
                                'Task Manager',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  shadows: const [
                                    Shadow(
                                      blurRadius: 10.0,
                                      color: Colors.black45,
                                      offset: Offset(2.0, 2.0),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                onPressed: _toggleTheme,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isDarkMode
                          ? [
                        Colors.grey[900]!,
                        Colors.grey[800]!,
                        Colors.grey[700]!,
                      ]
                          : [
                        Colors.blue[50]!,
                        Colors.teal[50]!,
                        Colors.white,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TaskButton(
                            title: 'Today Tasks',
                            icon: Icons.today,
                            isDarkMode: _isDarkMode,
                            onTap: () async {
                              final db = TaskDatabase.instance;
                              final tasks = await db.readTodayTasks();
                              await Navigator.push(
                                context,
                                PageRouteBuilder(
                                  transitionDuration: const Duration(milliseconds: 800),
                                  pageBuilder: (context, animation, secondaryAnimation) => TodayTaskPage(
                                    isDarkMode: _isDarkMode,
                                    tasks: tasks.where((t) => t['isCompleted'] == 0).toList(),
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
                              _ensureVideoPlaying();
                            },
                          ),
                          const SizedBox(height: 20),
                          TaskButton(
                            title: 'Completed Tasks',
                            icon: Icons.check_circle,
                            isDarkMode: _isDarkMode,
                            onTap: () async {
                              final db = TaskDatabase.instance;
                              final tasks = await db.readTasksByType('Completed');
                              await Navigator.push(
                                context,
                                PageRouteBuilder(
                                  transitionDuration: const Duration(milliseconds: 800),
                                  pageBuilder: (context, animation, secondaryAnimation) => CompletedTaskPage(
                                    isDarkMode: _isDarkMode,
                                    tasks: tasks.where((t) => t['isCompleted'] == 1).toList(),
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
                              _ensureVideoPlaying();
                            },
                          ),
                          const SizedBox(height: 20),
                          TaskButton(
                            title: 'Repeated Tasks',
                            icon: Icons.repeat,
                            isDarkMode: _isDarkMode,
                            onTap: () async {
                              final db = TaskDatabase.instance;
                              final tasks = await db.readRepeatedTasks();
                              await Navigator.push(
                                context,
                                PageRouteBuilder(
                                  transitionDuration: const Duration(milliseconds: 800),
                                  pageBuilder: (context, animation, secondaryAnimation) => RepeatedTaskPage(
                                    isDarkMode: _isDarkMode,
                                    tasks: tasks,
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
                              _ensureVideoPlaying();
                            },
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: _isDarkMode
                                        ? [Colors.indigo[800]!, Colors.teal[700]!]
                                        : [Colors.blue[600]!, Colors.teal[500]!],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.add, size: 30, color: Colors.white),
                                  tooltip: 'Add Task',
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        transitionDuration: const Duration(milliseconds: 800),
                                        pageBuilder: (context, animation, secondaryAnimation) => AddTaskPage(
                                          isDarkMode: _isDarkMode,
                                          onTaskAdded: (task) async {
                                            final db = TaskDatabase.instance;
                                            await db.createTask(task);
                                            setState(() {}); // Refresh the UI
                                          },
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
                                    _ensureVideoPlaying();
                                  },
                                ),
                              ),
                              const SizedBox(width: 20),
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: _isDarkMode
                                        ? [Colors.indigo[800]!, Colors.teal[700]!]
                                        : [Colors.blue[600]!, Colors.teal[500]!],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.share, size: 30, color: Colors.white),
                                  tooltip: 'Share Today\'s Tasks',
                                  onPressed: _shareTodayTasks,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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

class TaskButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDarkMode;
  final VoidCallback onTap;

  const TaskButton({
    super.key,
    required this.title,
    required this.icon,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.indigo[800]!, Colors.teal[700]!]
                : [Colors.blue[600]!, Colors.teal[500]!],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title Page')),
    );
  }
}