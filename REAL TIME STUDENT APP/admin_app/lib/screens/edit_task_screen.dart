import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditTaskScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _categoryController;
  late String _priority;
  late String _status;
  DateTime? _dueDate;
  bool isLoading = false;

  final List<String> _priorityOptions = ['Low', 'Medium', 'High'];
  final List<String> _statusOptions = ['pending', 'in_progress', 'completed'];

  @override
  void initState() {
    super.initState();
    final task = widget.task;

    _titleController = TextEditingController(text: task['title']);
    _descController = TextEditingController(text: task['description']);
    _categoryController = TextEditingController(text: task['category']);

    _priority = _priorityOptions.contains(task['priority']) ? task['priority'] : _priorityOptions[0];
    _status = _statusOptions.contains(task['status']) ? task['status'] : _statusOptions[0];
    _dueDate = DateTime.tryParse(task['due_date'] ?? '');
  }

  Future<void> _updateTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await supabase.from('tasks').update({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'category': _categoryController.text.trim(),
        'priority': _priority,
        'status': _status,
        'due_date': _dueDate?.toIso8601String(),
      }).eq('id', widget.task['id']);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Task updated!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to update: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  Future<void> _pickDueDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Task')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Task Title'),
                validator: (value) => value!.isEmpty ? 'Title is required' : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Priority'),
                value: _priorityOptions.contains(_priority) ? _priority : _priorityOptions[0],
                items: _priorityOptions
                    .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                    .toList(),
                onChanged: (val) => setState(() => _priority = val!),
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Status'),
                value: _statusOptions.contains(_status) ? _status : _statusOptions[0],
                items: _statusOptions
                    .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                    .toList(),
                onChanged: (val) => setState(() => _status = val!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _dueDate == null
                          ? 'No deadline'
                          : 'Due: ${_dueDate!.toLocal().toString().split(' ')[0]}',
                    ),
                  ),
                  TextButton(
                    onPressed: () => _pickDueDate(context),
                    child: const Text('Pick Deadline'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _updateTask,
                child: const Text('Update Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
