import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'student_messaging_screen.dart';
import '../student_login_screen.dart';

class StudentDashboard extends StatefulWidget {
  final String userId;
  const StudentDashboard({super.key, required this.userId});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> tasks = [];
  Map<String, int> taskStats = {'Completed': 0, 'Pending': 0};
  bool isLoading = false;
  String? error;
  StreamSubscription<List<Map<String, dynamic>>>? taskSubscription;

  bool _sortByPriority = false;
  bool _sortByDeadline = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
    _fetchTasks();
  }

  @override
  void dispose() {
    taskSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await supabase
          .from('tasks')
          .select()
          .eq('assigned_to', widget.userId);

      final taskList = List<Map<String, dynamic>>.from(response);
      final stats = {'Completed': 0, 'Pending': 0};
      for (var task in taskList) {
        stats[task['status']] = (stats[task['status']] ?? 0) + 1;
      }

      setState(() {
        tasks = taskList;
        taskStats = stats;
        _applySorting();
      });

      taskSubscription?.cancel();
      taskSubscription = supabase
          .from('tasks')
          .stream(primaryKey: ['id'])
          .eq('assigned_to', widget.userId)
          .map((snapshot) => List<Map<String, dynamic>>.from(snapshot))
          .listen((List<Map<String, dynamic>> updatedTasks) {
        final stats = {'Completed': 0, 'Pending': 0};
        for (var task in updatedTasks) {
          stats[task['status']] = (stats[task['status']] ?? 0) + 1;
        }
        setState(() {
          tasks = updatedTasks;
          taskStats = stats;
          _applySorting();
        });
      });

    } catch (e) {
      setState(() => error = 'Error fetching tasks: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _applySorting() {
    List<Map<String, dynamic>> sortedTasks = List.from(tasks);

    if (_sortByDeadline) {
      sortedTasks.sort((a, b) {
        final dueDateA = a['due_date'] != null ? DateTime.parse(a['due_date']).toLocal() : DateTime(9999);
        final dueDateB = b['due_date'] != null ? DateTime.parse(b['due_date']).toLocal() : DateTime(9999);
        return dueDateA.compareTo(dueDateB);
      });
    }

    if (_sortByPriority) {
      sortedTasks.sort((a, b) {
        if (_sortByDeadline) {
          final dueDateA = a['due_date'] != null ? DateTime.parse(a['due_date']).toLocal() : DateTime(9999);
          final dueDateB = b['due_date'] != null ? DateTime.parse(b['due_date']).toLocal() : DateTime(9999);
          final dueDateComparison = dueDateA.compareTo(dueDateB);
          if (dueDateComparison != 0) return dueDateComparison;
        }
        final priorityA = _getPriorityValue(a['priority']?.toString() ?? 'N/A');
        final priorityB = _getPriorityValue(b['priority']?.toString() ?? 'N/A');
        return priorityB.compareTo(priorityA);
      });
    }

    setState(() {
      tasks = sortedTasks;
    });
  }

  int _getPriorityValue(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  Future<void> _showFilterDialog() async {
    bool tempSortByPriority = _sortByPriority;
    bool tempSortByDeadline = _sortByDeadline;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Sort Tasks',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text(
                'Sort by Priority (High to Low)',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              value: tempSortByPriority,
              activeColor: const Color(0xFF3B82F6),
              onChanged: (value) {
                tempSortByPriority = value;
              },
            ),
            SwitchListTile(
              title: const Text(
                'Sort by Due Date (Nearest First)',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              value: tempSortByDeadline,
              activeColor: const Color(0xFF3B82F6),
              onChanged: (value) {
                tempSortByDeadline = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('CANCEL'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _sortByPriority = tempSortByPriority;
                _sortByDeadline = tempSortByDeadline;
                _applySorting();
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: const Text('APPLY'),
          ),
        ],
      ),
    );
  }

  Future<void> _showTaskDetails(Map<String, dynamic> task) async {
    final priority = task['priority']?.toString() ?? 'N/A';
    final description = task['description']?.toString() ?? 'No description';
    final dueDate = task['due_date']?.toString();
    final createdAt = task['created_at']?.toString();

    Color priorityColor;
    switch (priority.toLowerCase()) {
      case 'high':
        priorityColor = Colors.redAccent;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      case 'low':
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          task['title'],
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Status: ',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  task['status'],
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Priority: ',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: priorityColor, width: 1),
                  ),
                  child: Text(
                    priority,
                    style: TextStyle(
                      color: priorityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Description: ',
              style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text(
              description,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Due Date: ${_formatDate(dueDate)}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Created: ${_formatDate(createdAt)}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('CLOSE'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: task['status'] == 'Completed'
                  ? Colors.grey.withOpacity(0.5)
                  : const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            onPressed: task['status'] == 'Completed'
                ? null
                : () async {
              await markAsCompleted(task['id']);
              Navigator.pop(context);
            },
            child: const Text('COMPLETE'),
          ),
        ],
      ),
    );
  }

  Future<void> markAsCompleted(String taskId) async {
    try {
      await supabase.from('tasks').update({'status': 'Completed'}).eq('id', taskId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Task marked as completed'),
          backgroundColor: const Color(0xFF3B82F6).withOpacity(0.8),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: const Color(0xFF3B82F6).withOpacity(0.8),
        ),
      );
    }
  }

  Future<void> _showCalendar(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF3B82F6),
              onPrimary: Colors.white,
              surface: Color(0xFF1E3A8A),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1E3A8A).withOpacity(0.9),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected date: ${picked.toString().split(' ')[0]}'),
          backgroundColor: const Color(0xFF3B82F6).withOpacity(0.8),
        ),
      );
    }
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const StudentLoginScreen()),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    final dateTime = DateTime.parse(date).toLocal();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  Future<void> _exportTasks() async {
    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tasks to export'),
          backgroundColor: Color(0xFF3B82F6),
        ),
      );
      return;
    }

    String csv = 'Title,Status,Priority,Description,Due Date,Created\n';
    for (var task in tasks) {
      csv += '"${task['title']}",'
          '"${task['status']}",'
          '"${task['priority'] ?? 'N/A'}",'
          '"${task['description'] ?? 'No description'}",'
          '"${_formatDate(task['due_date'])}",'
          '"${_formatDate(task['created_at'])}"\n';
    }

    try {
      final bytes = utf8.encode(csv);
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/task_report_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsBytes(bytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Tasks exported to $path'),
          backgroundColor: const Color(0xFF3B82F6).withOpacity(0.8),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to export tasks: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }



  void _showActionMenu(BuildContext context) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(
        double.infinity,
        600,
        32,
        48,
      ),

      items: [
        PopupMenuItem<String>(
          value: 'filter',
          child: Row(
            children: const [
              Icon(Icons.filter_list, color: Color(0xFF3B82F6)),
              SizedBox(width: 8),
              Text('Filter', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'export',
          child: Row(
            children: const [
              Icon(Icons.download, color: Color(0xFF3B82F6)),
              SizedBox(width: 8),
              Text('Export', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'calendar',
          child: Row(
            children: const [
              Icon(Icons.calendar_today, color: Color(0xFF3B82F6)),
              SizedBox(width: 8),
              Text('Calendar', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'messages',
          child: Row(
            children: const [
              Icon(Icons.message, color: Color(0xFFD946EF)),
              SizedBox(width: 8),
              Text('Messages', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'filter':
          _showFilterDialog();
          break;
        case 'export':
          _exportTasks();
          break;
        case 'calendar':
          _showCalendar(context);
          break;
        case 'messages':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MessagingScreen(userId: widget.userId),
            ),
          );
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            )
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF6B21A8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3B82F6).withOpacity(0.8),
        elevation: 6,
        child: const Icon(Icons.add_business_outlined, color: Colors.white),
        onPressed: () => _showActionMenu(context),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF6B21A8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Container(
                width: size.width * 0.9,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.05),
                      Colors.white.withOpacity(0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dashboard Overview',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildProgressGraph(),
                    const SizedBox(height: 24),
                    const Text(
                      'Your Tasks',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : error != null
                        ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                      ),
                    )
                        : tasks.isEmpty
                        ? const Center(
                      child: Text(
                        'No tasks found.',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    )
                        : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        final priority = task['priority']?.toString() ?? 'N/A';
                        Color priorityColor;
                        switch (priority.toLowerCase()) {
                          case 'high':
                            priorityColor = Colors.redAccent;
                            break;
                          case 'medium':
                            priorityColor = Colors.orange;
                            break;
                          case 'low':
                            priorityColor = Colors.green;
                            break;
                          default:
                            priorityColor = Colors.grey;
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: Colors.transparent,
                          elevation: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF1E3A8A).withOpacity(0.6),
                                  const Color(0xFF6B21A8).withOpacity(0.4),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              title: Text(
                                task['title'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                'Status: ${task['status']}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: priorityColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: priorityColor, width: 1),
                                ),
                                child: Text(
                                  priority,
                                  style: TextStyle(
                                    color: priorityColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              onTap: () => _showTaskDetails(task),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressGraph() {
    final totalTasks = taskStats['Completed']! + taskStats['Pending']! + 1;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Task Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildProgressBar(
                  label: 'Completed',
                  value: taskStats['Completed']!,
                  total: totalTasks,
                  gradientColors: const [Color(0xFF3B82F6), Color(0xFF6BA8F9)],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProgressBar(
                  label: 'Pending',
                  value: taskStats['Pending']!,
                  total: totalTasks,
                  gradientColors: const [Color(0xFFD946EF), Color(0xFFE77FF3)],
                ),
              ),
            ],
          )


        ],
      ),
    );
  }

  Widget _buildProgressBar({
    required String label,
    required int value,
    required int total,
    required List<Color> gradientColors,
  }) {
    double percentage = total == 0 ? 0 : value / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: $value / $total',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 150, // Adjust width as needed
          height: 20,  // Thickness
          decoration: BoxDecoration(
            color: Colors.grey.shade200, // Background bar color
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade400, // Elegant border
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}