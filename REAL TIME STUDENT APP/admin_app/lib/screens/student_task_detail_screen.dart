import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentTaskDetailScreen extends StatefulWidget {
  final Map<String, dynamic> student;

  const StudentTaskDetailScreen({super.key, required this.student});

  @override
  State<StudentTaskDetailScreen> createState() => _StudentTaskDetailScreenState();
}

class _StudentTaskDetailScreenState extends State<StudentTaskDetailScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> _tasks = [];
  bool _loading = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchTasks();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchTasks() async {
    setState(() => _loading = true);
    try {
      final response = await supabase
          .from('tasks')
          .select()
          .eq('assigned_to', widget.student['id'])
          .order('due_date', ascending: true);

      setState(() => _tasks = response);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error loading tasks: $e'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete(String taskId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await deleteTask(taskId);
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await supabase.from('tasks').delete().eq('id', taskId);
      fetchTasks();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Task deleted successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to delete: $e'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> editTaskDialog(Map<String, dynamic> task) async {
    final titleController = TextEditingController(text: task['title']);
    final descController = TextEditingController(text: task['description']);
    final dueDateController = TextEditingController(text: task['due_date'] ?? '');

    final statusOptions = ['Pending', 'In Progress', 'Completed'];
    final priorityOptions = ['Low', 'Medium', 'High'];

    String selectedStatus = statusOptions.contains(task['status']) ? task['status'] : 'Pending';
    String selectedPriority = priorityOptions.contains(task['priority']) ? task['priority'] : 'Medium';

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '✏️ Edit Task',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 20),
              _buildStyledInputField(titleController, 'Title'),
              _buildStyledInputField(descController, 'Description'),
              _buildStyledInputField(dueDateController, 'Due Date (YYYY-MM-DD)'),
              const SizedBox(height: 16),
              _buildStyledDropdown(
                items: statusOptions,
                value: selectedStatus,
                label: 'Status',
                icon: Icons.flag_outlined,
                onChanged: (val) => selectedStatus = val!,
              ),
              _buildStyledDropdown(
                items: priorityOptions,
                value: selectedPriority,
                label: 'Priority',
                icon: Icons.priority_high_outlined,
                onChanged: (val) => selectedPriority = val!,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        await supabase.from('tasks').update({
                          'title': titleController.text,
                          'description': descController.text,
                          'due_date': dueDateController.text,
                          'status': selectedStatus,
                          'priority': selectedPriority,
                        }).eq('id', task['id']);

                        Navigator.pop(context);
                        fetchTasks();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Task updated successfully'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Failed to update: $e'),
                            backgroundColor: Colors.red[400],
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Save', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyledInputField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.deepPurple),
          ),
        ),
      ),
    );
  }

  Widget _buildStyledDropdown({
    required List<String> items,
    required String value,
    required String label,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.deepPurple),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.deepPurple),
          ),
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green[400]!;
      case 'In Progress':
        return Colors.blue[400]!;
      case 'Pending':
      default:
        return Colors.orange[400]!;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red[400]!;
      case 'Medium':
        return Colors.amber[600]!;
      case 'Low':
      default:
        return Colors.green[400]!;
    }
  }

  List<dynamic> get filteredTasks {
    if (_searchQuery.isEmpty) return _tasks;
    return _tasks.where((task) {
      final title = task['title']?.toString().toLowerCase() ?? '';
      final desc = task['description']?.toString().toLowerCase() ?? '';
      final status = task['status']?.toString().toLowerCase() ?? '';
      return title.contains(_searchQuery) ||
          desc.contains(_searchQuery) ||
          status.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final filtered = filteredTasks;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '${student['name']}\'s Tasks',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.pinkAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchTasks,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search, color: Colors.pinkAccent),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blueAccent),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.task_outlined,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'No tasks assigned yet'
                        : 'No matching tasks found',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final task = filtered[index];
                return Dismissible(
                  key: Key(task['id'].toString()),
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.red[400],
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  secondaryBackground: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.red[400],
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Task'),
                        content: const Text('Are you sure you want to delete this task?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[400],
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    deleteTask(task['id'].toString());
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Colors.blueAccent, Colors.pinkAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pinkAccent.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Card(
                      color: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => editTaskDialog(task),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      task['title'] ?? 'No Title',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          task['status'] ?? 'Pending',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (task['description'] != null && task['description'].toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    task['description'],
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_outlined,
                                          size: 16,
                                          color: Colors.white70,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          task['due_date'] ?? 'No due date',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined),
                                          color: Colors.white,
                                          iconSize: 20,
                                          onPressed: () => editTaskDialog(task),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline),
                                          color: Colors.white,
                                          iconSize: 20,
                                          onPressed: () => _confirmDelete(task['id'].toString()),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
