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

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    setState(() => _loading = true);

    try {
      final response = await supabase
          .from('tasks')
          .select()
          .eq('assigned_to', widget.student['id']);

      setState(() {
        _tasks = response;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error loading tasks: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> editTaskDialog(Map<String, dynamic> task) async {
    final titleController = TextEditingController(text: task['title']);
    final descController = TextEditingController(text: task['description']);
    final dueDateController = TextEditingController(text: task['due_date'] ?? '');

    final statusOptions = ['Pending', 'In Progress', 'Completed'];
    final priorityOptions = ['Low', 'Normal', 'High'];

    String selectedStatus = statusOptions.contains(task['status']) ? task['status'] : 'Pending';
    String selectedPriority = priorityOptions.contains(task['priority']) ? task['priority'] : 'Normal';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Task'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: dueDateController,
                decoration: const InputDecoration(labelText: 'Due Date (YYYY-MM-DD)'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                items: statusOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) => selectedStatus = value!,
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                items: priorityOptions
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (value) => selectedPriority = value!,
                decoration: const InputDecoration(labelText: 'Priority'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
                fetchTasks(); // Refresh
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;

    return Scaffold(
      appBar: AppBar(title: Text('${student['name']} - Tasks')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
          ? const Center(child: Text('No tasks assigned.'))
          : ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(task['title'] ?? 'No Title'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (task['description'] != null && task['description'].toString().isNotEmpty)
                    Text(task['description']),
                  Text('Due: ${task['due_date'] ?? 'N/A'}'),
                  Text('Status: ${task['status'] ?? 'Pending'}'),
                  Text('Priority: ${task['priority'] ?? 'Normal'}'),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => editTaskDialog(task),
              ),
            ),
          );
        },
      ),
    );
  }
}
