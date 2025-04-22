import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'database.dart';

class CompletedTaskPage extends StatefulWidget {
  final bool isDarkMode;
  final List<Map<String, dynamic>> tasks;

  const CompletedTaskPage({
    super.key,
    required this.isDarkMode,
    required this.tasks,
  });

  @override
  _CompletedTaskPageState createState() => _CompletedTaskPageState();
}

class _CompletedTaskPageState extends State<CompletedTaskPage> {
  late VideoPlayerController _controller;
  late List<Map<String, dynamic>> _tasks;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('videos/completed_task.mp4')
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _controller.setLooping(true);
            _controller.play();
          });
        }
      });
    _tasks = widget.tasks;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
      final db = TaskDatabase.instance;
      await db.deleteTask(id);
      setState(() {
        _tasks.removeWhere((task) => task['id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task deleted')),
      );
    }
  }

  Future<void> _undoComplete(Map<String, dynamic> task) async {
    final shouldUndo = await showDialog<bool>(
      context: context,
      builder: (context) => _buildConfirmationDialog(
        title: 'Undo Completion',
        content: 'Move this task back to Today\'s tasks?',
        confirmText: 'Undo',
      ),
    );

    if (shouldUndo == true) {
      final db = TaskDatabase.instance;
      final updatedTask = Map<String, dynamic>.from(task);
      updatedTask['isCompleted'] = 0;
      updatedTask['type'] = 'Today';
      await db.updateTask(updatedTask);
      setState(() {
        _tasks.removeWhere((t) => t['id'] == task['id']);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task moved back to Today')),
      );
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

  @override
  Widget build(BuildContext context) {
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
                      title: const Text('Completed Tasks',style: TextStyle(color: Colors.white),),
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
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return Card(
                      elevation: 4,
                      color: widget.isDarkMode ? Colors.grey[800] : Colors.white,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          task['title'],
                          style: TextStyle(
                            color: widget.isDarkMode ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Completed on: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(task['dueDate']))}',
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
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Tooltip(
                              message: 'Undo Completion',
                              child: IconButton(
                                icon: Icon(
                                  Icons.undo,
                                  color: widget.isDarkMode ? Colors.teal[400] : Colors.blue[600],
                                ),
                                onPressed: () => _undoComplete(task),
                              ),
                            ),
                            Tooltip(
                              message: 'Delete Task',
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => _deleteTask(task['id']),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
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