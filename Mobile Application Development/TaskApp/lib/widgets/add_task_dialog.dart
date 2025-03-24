import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/settings_provider.dart';

class AddTaskDialog extends ConsumerStatefulWidget {
  final Task? parentTask;

  const AddTaskDialog({Key? key, this.parentTask}) : super(key: key);

  @override
  ConsumerState<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends ConsumerState<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isRepeatable = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      data: (settings) => AlertDialog(
        title: Text(
          widget.parentTask == null ? 'Add New Task' : 'Add Subtask',
          style: TextStyle(fontSize: settings.fontSize * 1.2),
        ),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: const OutlineInputBorder(),
                  ),
                  style: TextStyle(fontSize: settings.fontSize),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    border: const OutlineInputBorder(),
                  ),
                  style: TextStyle(fontSize: settings.fontSize),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                if (widget.parentTask == null)
                  SwitchListTile(
                    title: Text(
                      'Repeatable Task',
                      style: TextStyle(fontSize: settings.fontSize),
                    ),
                    value: _isRepeatable,
                    onChanged: (value) {
                      setState(() {
                        _isRepeatable = value;
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: settings.fontSize),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final task = Task(
                  title: _titleController.text,
                  description: _descriptionController.text.isEmpty
                      ? null
                      : _descriptionController.text,
                  isRepeatable: _isRepeatable,
                  createdAt: DateTime.now(),
                  parentId: widget.parentTask?.id,
                );

                ref.read(tasksProvider.notifier).addTask(task);
                Navigator.pop(context);
              }
            },
            child: Text(
              'Add',
              style: TextStyle(fontSize: settings.fontSize),
            ),
          ),
        ],
      ),
      loading: () => const AlertDialog(
        content: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => AlertDialog(
        content: Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
