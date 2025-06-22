import 'package:flutter/material.dart';
import '../../services/batch_service.dart';
import '../../models/batch.dart';
import '../../services/supabase_service.dart';
import '../../services/department_service.dart';

class BatchManagementScreen extends StatefulWidget {
  @override
  State<BatchManagementScreen> createState() => _BatchManagementScreenState();
}

class _BatchManagementScreenState extends State<BatchManagementScreen> {
  List<Batch> batches = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBatches();
  }

  Future<void> _fetchBatches() async {
    setState(() => isLoading = true);
    batches = await BatchService.getBatches();
    setState(() => isLoading = false);
  }

  void _showAddEditDialog({Batch? batch}) async {
    final nameCtrl = TextEditingController(text: batch?.name ?? '');
    String? selectedDeptId = batch?.departmentId;
    String? selectedAdvisorId = batch?.advisorId;
    final departments = await DepartmentService.getDepartments();
    final advisors = (await SupabaseService.getAllUsers())
        .where((u) => u['role'] == 'advisor')
        .toList();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(batch == null ? 'Add Batch' : 'Edit Batch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: 'Batch Name')),
            DropdownButtonFormField<String>(
              value: selectedDeptId?.isNotEmpty == true ? selectedDeptId : null,
              items: departments
                  .map((d) => DropdownMenuItem<String>(
                        value: d.id,
                        child: Text(d.name),
                      ))
                  .toList(),
              onChanged: (val) => selectedDeptId = val,
              decoration: InputDecoration(labelText: 'Department'),
            ),
            DropdownButtonFormField<String>(
              value: selectedAdvisorId?.isNotEmpty == true ? selectedAdvisorId : null,
              items: advisors
                  .map((a) => DropdownMenuItem<String>(
                        value: a['id'] as String,
                        child: Text(a['name'] ?? a['email'] ?? a['id']),
                      ))
                  .toList(),
              onChanged: (val) => selectedAdvisorId = val,
              decoration: InputDecoration(labelText: 'Advisor'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              if (batch == null) {
                await BatchService.addBatch(
                    nameCtrl.text, selectedDeptId ?? '', selectedAdvisorId ?? '');
              } else {
                await BatchService.updateBatch(batch.id, nameCtrl.text,
                    selectedDeptId ?? '', selectedAdvisorId ?? '');
              }
              Navigator.pop(context);
              _fetchBatches();
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
      appBar: AppBar(title: Text('Batch Management')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: batches.length,
              itemBuilder: (_, i) => ListTile(
                title: Text(batches[i].name),
                subtitle: Text(
                    'Dept ID: ' +
                        batches[i].departmentId +
                        '\nAdvisor ID: ' +
                        batches[i].advisorId,
                    style: TextStyle(fontSize: 14)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _showAddEditDialog(batch: batches[i]),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () async {
                        await BatchService.deleteBatch(batches[i].id);
                        _fetchBatches();
                      },
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: Icon(Icons.add),
        tooltip: 'Add Batch',
      ),
    );
  }
}
