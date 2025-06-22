import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/supabase_service.dart';

class UserManagementScreen extends StatefulWidget {
  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<UserModel> users = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() => loading = true);
    final data = await SupabaseService.getAllUsers();
    setState(() {
      users = data.map((e) => UserModel.fromMap(e)).toList();
      loading = false;
    });
  }

  void showUserDialog({UserModel? user}) {
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final roleCtrl = TextEditingController(text: user?.role ?? '');
    final batchCtrl = TextEditingController(text: user?.batchId ?? '');
    final deptCtrl = TextEditingController(text: user?.departmentId ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(user == null ? 'Add User' : 'Edit User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Name')),
              TextField(controller: emailCtrl, decoration: InputDecoration(labelText: 'Email')),
              TextField(controller: roleCtrl, decoration: InputDecoration(labelText: 'Role')),
              TextField(controller: batchCtrl, decoration: InputDecoration(labelText: 'Batch ID')),
              TextField(controller: deptCtrl, decoration: InputDecoration(labelText: 'Department ID')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final map = {
                'name': nameCtrl.text,
                'email': emailCtrl.text,
                'role': roleCtrl.text,
                'batch_id': batchCtrl.text,
                'department_id': deptCtrl.text,
              };
              if (user == null) {
                await SupabaseService.createUser(map);
              } else {
                await SupabaseService.updateUser(user.id, map);
              }
              Navigator.pop(ctx);
              fetchUsers();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void confirmDelete(UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await SupabaseService.deleteUser(user.id);
              Navigator.pop(ctx);
              fetchUsers();
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
      appBar: AppBar(title: Text('User Management')),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (ctx, i) {
                final user = users[i];
                return ListTile(
                  title: Text(user.name),
                  subtitle: Text('Email: ${user.email}\nRole: ${user.role}\nBatch: ${user.batchId}\nDept: ${user.departmentId}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => showUserDialog(user: user),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => confirmDelete(user),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showUserDialog(),
        child: Icon(Icons.add),
        tooltip: 'Add User',
      ),
    );
  }
}
