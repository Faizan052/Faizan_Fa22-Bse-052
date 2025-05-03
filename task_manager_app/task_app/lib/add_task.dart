import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'database.dart';

class AddTaskPage extends StatefulWidget {
  final bool isDarkMode;
  final Function(Map<String, dynamic>) onTaskAdded;

  const AddTaskPage({
    super.key,
    required this.isDarkMode,
    required this.onTaskAdded,
  });

  @override
  _AddTaskPageState createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  late VideoPlayerController _controller;
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  bool _isRepeated = false;
  TimeOfDay _repeatTime = TimeOfDay.now();
  final Map<String, bool> _repeatDays = {
    'Monday': false,
    'Tuesday': false,
    'Wednesday': false,
    'Thursday': false,
    'Friday': false,
    'Saturday': false,
    'Sunday': false,
  };

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('videos/add_task.mp4')
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _controller.setLooping(true);
            _controller.play();
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: widget.isDarkMode
              ? ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.teal[700]!,
              onPrimary: Colors.white,
              onSurface: Colors.white,
            ),
          )
              : ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[600]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _repeatTime,
      builder: (context, child) {
        return Theme(
          data: widget.isDarkMode
              ? ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.teal[700]!,
              onPrimary: Colors.white,
              onSurface: Colors.white,
            ),
          )
              : ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[600]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _repeatTime) {
      setState(() {
        _repeatTime = picked;
      });
    }
  }

  void _showConfirmationDialog() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_isRepeated && !_repeatDays.containsValue(true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one day for repeating')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: widget.isDarkMode ? Colors.grey[900] : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Confirm Save',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to save this task?',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            Tooltip(
              message: 'Cancel and go back',
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ),
            Tooltip(
              message: 'Save this task',
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _submitTask();
                },
                child: Text(
                  'Save',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.teal[400] : Colors.blue[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _submitTask() async {
    final task = {
      'title': _title,
      'description': _description,
      'dueDate': _dueDate.toIso8601String(),
      'isCompleted': 0,
      'createdAt': DateTime.now().toIso8601String(),
      'isRepeated': _isRepeated ? 1 : 0,
      'type': _isRepeated ? 'repeated' : 'today',
      if (_isRepeated)
        'repeatDays': _repeatDays.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .join(','),
      if (_isRepeated) 'repeatTime': '${_repeatTime.hour}:${_repeatTime.minute}',
    };

    try {
      debugPrint('🚀 Saving task: $task');
      final db = TaskDatabase.instance;
      final id = await db.createTask(task);
      debugPrint('✅ Task saved with ID: $id');

      widget.onTaskAdded(task); // Notify callback

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error saving task: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
            // Video Header Section
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.3,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Video Background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.isDarkMode
                            ? [Colors.indigo[900]!, Colors.teal[800]!]
                            : [Colors.blue[800]!, Colors.teal[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),

                  // Video Player
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
                    const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),

                  // App Bar Overlay
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: AppBar(
                      title: const Text('Add New Task'),
                      centerTitle: true,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      actions: [
                        Tooltip(
                          message: 'Save Task',
                          child: IconButton(
                            icon: const Icon(Icons.save),
                            onPressed: _showConfirmationDialog,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Form Section
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Task Title Card
                        Tooltip(
                          message: 'Enter your task title',
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            color: widget.isDarkMode ? Colors.grey[800] : Colors.grey[100],
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Title',
                                  labelStyle: TextStyle(
                                    color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                                    fontSize: 16,
                                  ),
                                  border: InputBorder.none,
                                ),
                                style: TextStyle(
                                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                                  fontSize: 18,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a task title';
                                  }
                                  return null;
                                },
                                onSaved: (value) => _title = value!,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Task Description Card
                        Tooltip(
                          message: 'Enter task details (optional)',
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            color: widget.isDarkMode ? Colors.grey[800] : Colors.grey[100],
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: TextFormField(
                                decoration: InputDecoration(
                                  hintText: 'Enter task description here...',
                                  hintStyle: TextStyle(
                                    color: widget.isDarkMode ? Colors.white54 : Colors.black54,
                                    fontSize: 16,
                                  ),
                                  border: InputBorder.none,
                                ),
                                style: TextStyle(
                                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                                maxLines: 5,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                                onSaved: (value) => _description = value ?? '',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Due Date Card
                        Tooltip(
                          message: 'Set due date for your task',
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            color: widget.isDarkMode ? Colors.grey[800] : Colors.grey[100],
                            child: ListTile(
                              leading: Icon(
                                Icons.calendar_today,
                                color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                              title: Text(
                                'Due Date',
                                style: TextStyle(
                                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                DateFormat.yMMMd().format(_dueDate),
                                style: TextStyle(
                                  color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              trailing: const Icon(Icons.arrow_drop_down),
                              onTap: () => _selectDate(context),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Repeat Toggle
                        Tooltip(
                          message: 'Enable to make this task repeat',
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            color: widget.isDarkMode ? Colors.grey[800] : Colors.grey[100],
                            child: SwitchListTile(
                              title: Text(
                                'Repeat Task',
                                style: TextStyle(
                                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              value: _isRepeated,
                              onChanged: (value) {
                                setState(() {
                                  _isRepeated = value;
                                });
                              },
                              activeColor: widget.isDarkMode ? Colors.teal[400] : Colors.blue[600],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Repeat Options (only shown if _isRepeated is true)
                        if (_isRepeated) ...[
                          // Repeat Time
                          Tooltip(
                            message: 'Set time for repeated task',
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              color: widget.isDarkMode ? Colors.grey[800] : Colors.grey[100],
                              child: ListTile(
                                leading: Icon(
                                  Icons.access_time,
                                  color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                                ),
                                title: Text(
                                  'Repeat Time',
                                  style: TextStyle(
                                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                                subtitle: Text(
                                  _repeatTime.format(context),
                                  style: TextStyle(
                                    color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                                trailing: const Icon(Icons.arrow_drop_down),
                                onTap: () => _selectTime(context),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Repeat Days
                          Tooltip(
                            message: 'Select days to repeat',
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              color: widget.isDarkMode ? Colors.grey[800] : Colors.grey[100],
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Repeat Days',
                                      style: TextStyle(
                                        color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _repeatDays.entries.map((entry) {
                                        return FilterChip(
                                          label: Text(entry.key),
                                          selected: entry.value,
                                          onSelected: (selected) {
                                            setState(() {
                                              _repeatDays[entry.key] = selected;
                                            });
                                          },
                                          selectedColor: widget.isDarkMode
                                              ? Colors.teal[700]
                                              : Colors.blue[600],
                                          checkmarkColor: Colors.white,
                                          labelStyle: TextStyle(
                                            color: entry.value
                                                ? Colors.white
                                                : (widget.isDarkMode ? Colors.white70 : Colors.black87),
                                          ),
                                          backgroundColor: widget.isDarkMode
                                              ? Colors.grey[700]
                                              : Colors.grey[300],
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Save Button
                        Tooltip(
                          message: 'Save this task',
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.isDarkMode
                                  ? Colors.teal[700]
                                  : Colors.blue[600],
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            onPressed: _showConfirmationDialog,
                            child: Text(
                              'Save Task',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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
    );
  }
}