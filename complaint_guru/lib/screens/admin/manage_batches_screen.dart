import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/helpers.dart';
import '../utils/theme.dart';
import '../widgets/custom_button.dart';

class ManageDepartmentsScreen extends StatefulWidget {
  const ManageDepartmentsScreen({Key? key}) : super(key: key);

  @override
  _ManageDepartmentsScreenState createState() => _ManageDepartmentsScreenState();
}

class _ManageDepartmentsScreenState extends State<ManageDepartmentsScreen> {
  final _nameController = TextEditingController();
  final _hodIdController = TextEditingController();
  List<Map<String, dynamic>> _departments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  Future<void> _fetchDepartments() async {
    try {
      final departments = await DatabaseService().getDepartments();
      setState(() {
        _departments = departments.map((d) => d.toJson()).toList();
        _isLoading = false;
      });
    } catch (e) {
      Helpers.showSnackBar(context, 'Failed to load departments: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addDepartment() async {
    try {
      await DatabaseService().addDepartment(
        _nameController.text,
        _hodIdController.text,
      );
      _nameController.clear();
      _hodIdController.clear();
      _fetchDepartments();
      Helpers.showSnackBar(context, 'Department added successfully');
    } catch (e) {
      Helpers.showSnackBar(context, 'Failed to add department: $e');
    }
  }

  Future<void> _deleteDepartment(String id) async {
    try {
      await DatabaseService().deleteDepartment(id);
      _fetchDepartments();
      Helpers.showSnackBar(context, 'Department deleted successfully');
    } catch (e) {
      Helpers.showSnackBar(context, 'Failed to delete department: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Departments')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                decoration: AppTheme.glassDecoration(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Department Name',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _hodIdController,
                      decoration: InputDecoration(
                        labelText: 'HOD User ID',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomButton(text: 'Add Department', onPressed: _addDepartment),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : Expanded(
                child: ListView.builder(
                  itemCount: _departments.length,
                  itemBuilder: (context, index) {
                    final dept = _departments[index];
                    return ListTile(
                      title: Text(dept['name'], style: const TextStyle(color: Colors.white)),
                      subtitle: Text('HOD ID: ${dept['hod_id']}',
                          style: TextStyle(color: Colors.white.withOpacity(0.8))),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteDepartment(dept['id']),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}