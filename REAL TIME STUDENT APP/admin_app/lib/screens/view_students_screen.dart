import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'assign_task_screen.dart';
import 'student_task_detail_screen.dart';

class ViewStudentsScreen extends StatefulWidget {
  const ViewStudentsScreen({Key? key}) : super(key: key);

  @override
  State<ViewStudentsScreen> createState() => _ViewStudentsScreenState();
}

class _ViewStudentsScreenState extends State<ViewStudentsScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> _students = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedStudentId;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _selectedStudentId = null;
    });

    try {
      final response = await supabase.from('users').select().eq('role', 'student');
      setState(() {
        _students = response;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading students: $e';
        _students = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteStudent(String uuid) async {
    if (uuid.isEmpty || !RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false).hasMatch(uuid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ Invalid student ID'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.red[400],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded,
                size: 48,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete Student?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This will permanently remove the student and all their data.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Delete', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    try {
      await supabase.from('tasks').delete().eq('assigned_to', uuid);
      await supabase.from('messages').delete().or('sender_id.eq.$uuid,receiver_id.eq.$uuid');
      await supabase.from('badges').delete().eq('user_id', uuid);
      await supabase.from('reports').delete().eq('user_id', uuid);
      await supabase.from('users').delete().eq('id', uuid);

      setState(() {
        _students.removeWhere((student) => student['id'] == uuid);
        _selectedStudentId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Student deleted successfully'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.green[400],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error deleting student: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.red[400],
        ),
      );
    }
  }

  Future<void> _editStudent(Map<String, dynamic> student) async {
    final nameController = TextEditingController(text: student['name']);
    final emailController = TextEditingController(text: student['email']);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Edit Student',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
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
                    onPressed: () async {
                      final updatedName = nameController.text.trim();
                      final updatedEmail = emailController.text.trim();

                      if (updatedName.isEmpty || updatedEmail.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Name and Email cannot be empty'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      try {
                        await supabase.from('users').update({
                          'name': updatedName,
                          'email': updatedEmail,
                        }).eq('id', student['id']);

                        Navigator.pop(context);

                        setState(() {
                          final index = _students.indexWhere((s) => s['id'] == student['id']);
                          if (index != -1) {
                            _students[index]['name'] = updatedName;
                            _students[index]['email'] = updatedEmail;
                          }
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Student updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Error updating: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[400],
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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

  void _toggleStudentSelection(String studentId) {
    setState(() {
      _selectedStudentId = _selectedStudentId == studentId ? null : studentId;
    });
  }

  // ... [Keep all your existing imports and class declarations unchanged] ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Student Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchStudents,
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            _error!,
            style: TextStyle(
              color: Colors.red[400],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      )
          : _students.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_off_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No students found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: fetchStudents,
              child: const Text(
                'Refresh',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListView.builder(
          itemCount: _students.length,
          itemBuilder: (context, index) {
            final student = _students[index];
            final name = student['name'] ?? 'Unnamed';
            final email = student['email'] ?? 'No Email';
            final uuid = student['id'];
            final isSelected = _selectedStudentId == uuid;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isSelected
                      ? Colors.blue.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.1),
                  width: 1.5,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _toggleStudentSelection(uuid),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue[400]!,
                                  Colors.purple[400]!,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : "?",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? Colors.blue[50]
                                  : Colors.transparent,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                isSelected
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: isSelected
                                    ? Colors.blue[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 12,
                          right: 12,
                          bottom: 16,
                        ),
                        child: Column(
                          children: [
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildActionButton(
                                  icon: Icons.task_outlined,
                                  color: Colors.blue[400]!,
                                  label: 'Assign Task',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AssignTaskScreen(student: student),
                                      ),
                                    );
                                  },
                                ),
                                _buildActionButton(
                                  icon: Icons.list_alt_outlined,
                                  color: Colors.green[400]!,
                                  label: 'View Tasks',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StudentTaskDetailScreen(student: student),
                                      ),
                                    );
                                  },
                                ),
                                _buildActionButton(
                                  icon: Icons.edit_outlined,
                                  color: Colors.orange[400]!,
                                  label: 'Edit',
                                  onPressed: () => _editStudent(student),
                                ),
                                _buildActionButton(
                                  icon: Icons.delete_outline,
                                  color: Colors.red[400]!,
                                  label: 'Delete',
                                  onPressed: () => _deleteStudent(uuid),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
          ),
          child: IconButton(
            icon: Icon(icon, color: color, size: 22),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}