import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/supabase_service.dart';

class HodManagementScreen extends StatefulWidget {
  @override
  State<HodManagementScreen> createState() => _HodManagementScreenState();
}

class _HodManagementScreenState extends State<HodManagementScreen> {
  List<UserModel> hods = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchHods();
  }

  Future<void> fetchHods() async {
    setState(() => loading = true);
    final data = await SupabaseService.getAllHods();
    setState(() {
      hods = data.map((e) => UserModel.fromMap(e)).toList();
      loading = false;
    });
  }

  void showHodDialog({UserModel? hod}) {
    final nameCtrl = TextEditingController(text: hod?.name ?? '');
    final emailCtrl = TextEditingController(text: hod?.email ?? '');
    final deptCtrl = TextEditingController(text: hod?.departmentId ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(hod == null ? 'Add HOD' : 'Edit HOD'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Name')),
            TextField(controller: emailCtrl, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: deptCtrl, decoration: InputDecoration(labelText: 'Department ID')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final map = {
                'name': nameCtrl.text,
                'email': emailCtrl.text,
                'department_id': deptCtrl.text,
                'role': 'hod',
              };
              if (hod == null) {
                await SupabaseService.createHod(map);
              } else {
                await SupabaseService.updateHod(hod.id, map);
              }
              Navigator.pop(ctx);
              fetchHods();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void confirmDelete(UserModel hod) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete HOD'),
        content: Text('Are you sure you want to delete ${hod.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await SupabaseService.deleteHod(hod.id);
              Navigator.pop(ctx);
              fetchHods();
            },
            child: Text('Delete'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('HOD Account Management')),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: hods.length,
              itemBuilder: (ctx, i) {
                final hod = hods[i];
                return ListTile(
                  title: Text(hod.name),
                  subtitle: Text('Email: ${hod.email}\nDept: ${hod.departmentId}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => showHodDialog(hod: hod),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => confirmDelete(hod),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showHodDialog(),
        child: Icon(Icons.add),
        tooltip: 'Add HOD',
      ),
    );
  }
}
