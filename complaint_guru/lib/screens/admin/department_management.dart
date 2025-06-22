import 'package:flutter/material.dart';
import '../../services/department_service.dart';
import '../../models/department.dart';

import '../../services/supabase_service.dart';

class DepartmentManagementScreen extends StatefulWidget {
  @override
  State<DepartmentManagementScreen> createState() => _DepartmentManagementScreenState();
}

class _DepartmentManagementScreenState extends State<DepartmentManagementScreen> {
  List<Department> departments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  Future<void> _fetchDepartments() async {
    setState(() => isLoading = true);
    departments = await DepartmentService.getDepartments();
    setState(() => isLoading = false);
  }

  void _showAddEditDialog({Department? dept}) async {
    final nameCtrl = TextEditingController(text: dept?.name ?? '');
    String? selectedHodId = dept?.hodId;
    List<Map<String, dynamic>> hods = await SupabaseService.getAllHods();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(dept == null ? 'Add Department' : 'Edit Department'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Department Name')),
            DropdownButtonFormField<String>(
              value: selectedHodId?.isNotEmpty == true ? selectedHodId : null,
              items: hods.map((h) => DropdownMenuItem<String>(
                value: h['id'] as String,
                child: Text(h['name'] ?? h['email'] ?? h['id']),
              )).toList(),
              onChanged: (val) => setState(() => selectedHodId = val),
              decoration: InputDecoration(labelText: 'HOD'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              if (dept == null) {
                await DepartmentService.addDepartment(nameCtrl.text, selectedHodId ?? '');
              } else {
                await DepartmentService.updateDepartment(dept.id, nameCtrl.text, selectedHodId ?? '');
              }
              Navigator.pop(context);
              _fetchDepartments();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Department Management')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: departments.length,
              itemBuilder: (_, i) => ListTile(
                title: Text(departments[i].name),
                subtitle: Text('HOD ID: ' + departments[i].hodId),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _showAddEditDialog(dept: departments[i]),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () async {
                        await DepartmentService.deleteDepartment(departments[i].id);
                        _fetchDepartments();
                      },
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: Icon(Icons.add),
        tooltip: 'Add Department',
      ),
    );
  }
}
