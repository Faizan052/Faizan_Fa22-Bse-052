import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'database.dart';

class EditTaskPage extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> task;

  const EditTaskPage({
    super.key,
    required this.isDarkMode,
    required this.task,
  });

  @override
  _EditTaskPageState createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  late VideoPlayerController _controller;
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _description;
  late DateTime _dueDate;
  late String _taskType;
  late bool _isRepeated;
  late TimeOfDay _repeatTime;
  late Map<String, bool> _repeatDays;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('videos/edit_task.mp4')
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _controller.setLooping(true);
            _controller.play();
          });
        }
      });

    // Initialize fields from task
    _title = widget.task['title'];
    _description = widget.task['description'] ?? '';
    _dueDate = DateTime.parse(widget.task['dueDate']);
    _isRepeated = widget.task['isRepeated'] == 1;

    // Normalize task type for UI
    final dbType = widget.task['type']?.toString().toLowerCase() ?? 'today';
    _taskType = {
      'today': 'Today',
      'repeated': 'Repeated',
      'completed': 'Completed',
    }[dbType] ?? 'Today';

    // Initialize repeat fields
    if (_isRepeated) {
      // Parse repeatTime (e.g., "23:35")
      final repeatTimeStr = widget.task['repeatTime']?.toString() ?? '00:00';
      final timeParts = repeatTimeStr.split(':');
      final hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = int.tryParse(timeParts[1]) ?? 0;
      _repeatTime = TimeOfDay(hour: hour, minute: minute);

      // Parse repeatDays
      _repeatDays = {
        'Monday': false,
        'Tuesday': false,
        'Wednesday': false,
        'Thursday': false,
        'Friday': false,
        'Saturday': false,
        'Sunday': false,
      };
      final repeatDaysStr = widget.task['repeatDays']?.toString() ?? '';
      if (repeatDaysStr.isNotEmpty) {
        final days = repeatDaysStr.split(',').map((d) => d.trim().capitalize()).toList();
        for (var day in days) {
          if (_repeatDays.containsKey(day)) {
            _repeatDays[day] = true;
          }
        }
      }
    } else {
      _repeatTime = TimeOfDay.now();
      _repeatDays = {
        'Monday': false,
        'Tuesday': false,
        'Wednesday': false,
        'Thursday': false,
        'Friday': false,
        'Saturday': false,
        'Sunday': false,
      };
    }
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
            'Confirm Changes',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to save these changes?',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            Tooltip(
              message: 'Cancel changes',
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
              message: 'Save changes',
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _submitChanges();
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

  void _submitChanges() async {
    final dbType = {
      'Today': 'today',
      'Repeated': 'repeated',
      'Completed': 'Completed',
    }[_taskType] ?? 'today';

    final updatedTask = {
      ...widget.task,
      'title': _title,
      'description': _description,
      'dueDate': _dueDate.toIso8601String(),
      'type': dbType,
      'isRepeated': _isRepeated ? 1 : 0,
      'repeatDays': _isRepeated
          ? _repeatDays.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .join(',')
          : '',
      'repeatTime': _isRepeated ? '${_repeatTime.hour}:${_repeatTime.minute}' : '',
    };

    try {
      final db = TaskDatabase.instance;
      if (_isRepeated && updatedTask['instanceDate'] == null) {
        // For main repeated tasks, use updateRepeatedTask to regenerate instances
        await db.updateRepeatedTask(updatedTask);
      } else {
        // For non-repeated tasks or instances, update directly
        await db.updateTask(updatedTask);
      }
      debugPrint('✅ Task updated successfully: ${updatedTask['title']}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, updatedTask);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error updating task: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update task: $e'),
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
                      title: const Text(
                        'Edit Task',
                        style: TextStyle(color: Colors.white),
                      ),
                      centerTitle: true,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      actions: [
                        Tooltip(
                          message: 'Save Changes',
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
                        // Task Title
                        Tooltip(
                          message: 'Edit task title',
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            color: widget.isDarkMode ? Colors.grey[800] : Colors.grey[100],
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: TextFormField(
                                initialValue: _title,
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

                        // Task Description
                        Tooltip(
                          message: 'Edit task description',
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            color: widget.isDarkMode ? Colors.grey[800] : Colors.grey[100],
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: TextFormField(
                                initialValue: _description,
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

                        // Due Date
                        Tooltip(
                          message: 'Edit due date',
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

                        // Task Type
                        Tooltip(
                          message: 'Change task type',
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            color: widget.isDarkMode ? Colors.grey[800] : Colors.grey[100],
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: DropdownButtonFormField<String>(
                                value: _taskType,
                                items: ['Today', 'Completed', 'Repeated'].map((type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(
                                      type,
                                      style: TextStyle(
                                        color: widget.isDarkMode ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _taskType = value!;
                                    _isRepeated = value == 'Repeated';
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Task Type',
                                  labelStyle: TextStyle(
                                    color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                                  ),
                                  border: InputBorder.none,
                                ),
                                dropdownColor: widget.isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                style: TextStyle(
                                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Repeat Toggle
                        Tooltip(
                          message: 'Enable to make this task repeat',
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                  if (value) {
                                    _taskType = 'Repeated';
                                  } else {
                                    _taskType = 'Today';
                                  }
                                });
                              },
                              activeColor: widget.isDarkMode ? Colors.teal[400] : Colors.blue[600],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Repeat Options
                        if (_isRepeated) ...[
                          // Repeat Time
                          Tooltip(
                            message: 'Set time for repeated task',
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                          selectedColor:
                                          widget.isDarkMode ? Colors.teal[700] : Colors.blue[600],
                                          checkmarkColor: Colors.white,
                                          labelStyle: TextStyle(
                                            color: entry.value
                                                ? Colors.white
                                                : (widget.isDarkMode ? Colors.white70 : Colors.black87),
                                          ),
                                          backgroundColor:
                                          widget.isDarkMode ? Colors.grey[700] : Colors.grey[300],
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
                          message: 'Save all changes',
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              widget.isDarkMode ? Colors.teal[700] : Colors.blue[600],
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            onPressed: _showConfirmationDialog,
                            child: Text(
                              'Save Changes',
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

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}