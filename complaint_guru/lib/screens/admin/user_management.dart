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
  String _roleFilter = 'All';
  static const List<String> _roles = ['All', 'student', 'batch_advisor', 'hod', 'admin'];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() => loading = true);
    final data = await SupabaseService.getAllUsers();
    setState(() {
      users = List<UserModel>.from(data.map((e) => UserModel.fromMap(e)));
      loading = false;
    });
  }

  List<UserModel> get filteredUsers {
    List<UserModel> result = List<UserModel>.from(users);
    if (_roleFilter != 'All') {
      result = result.where((u) => u.role == _roleFilter).toList();
    }
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      result = result.where((u) =>
        u.name.toLowerCase().contains(searchTerm) ||
        u.email.toLowerCase().contains(searchTerm)
      ).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withOpacity(0.6)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant.withOpacity(0.4),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Filter:', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.8))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButton<String>(
                          value: _roleFilter,
                          items: _roles.map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(
                              r == 'All' ? 'All Roles' : r.capitalize(),
                              style: TextStyle(color: colorScheme.onSurface),
                            ),
                          )).toList(),
                          onChanged: (val) => setState(() => _roleFilter = val!),
                          isExpanded: true,
                          underline: const SizedBox(),
                          icon: Icon(Icons.filter_list, color: colorScheme.onSurface),
                          dropdownColor: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // User List
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_alt_outlined, size: 64, color: colorScheme.onSurface.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    _roleFilter == 'All'
                        ? 'No users found'
                        : 'No ${_roleFilter.capitalize()} users found',
                    style: TextStyle(
                      fontSize: 18,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredUsers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final user = filteredUsers[i];
                return UserCard(
                  user: user,
                  onEdit: () => showUserDialog(user: user),
                  onDelete: () => confirmDelete(user),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showUserDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
      ),
    );
  }

  void showUserDialog({UserModel? user}) {
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final passwordCtrl = TextEditingController();
    String roleValue = user?.role ?? 'student';
    final batchCtrl = TextEditingController(text: user?.batchId ?? '');
    final deptCtrl = TextEditingController(text: user?.departmentId ?? '');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user == null ? 'Add New User' : 'Edit User',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              buildFormField(nameCtrl, 'Name'),
              const SizedBox(height: 12),
              buildFormField(emailCtrl, 'Email'),
              if (user == null) ...[
                const SizedBox(height: 12),
                buildFormField(passwordCtrl, 'Password', obscureText: true),
              ],
              const SizedBox(height: 12),
              buildRoleDropdown(roleValue, (val) => roleValue = val!),
              const SizedBox(height: 12),
              buildFormField(batchCtrl, 'Batch ID (optional)'),
              const SizedBox(height: 12),
              buildFormField(deptCtrl, 'Department ID (optional)'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (user == null) {
                        await SupabaseService.registerUserWithAuth(
                          name: nameCtrl.text,
                          email: emailCtrl.text,
                          password: passwordCtrl.text,
                          role: roleValue,
                          batchId: batchCtrl.text,
                          departmentId: deptCtrl.text,
                        );
                      } else {
                        await SupabaseService.updateUser(user.id, {
                          'name': nameCtrl.text,
                          'email': emailCtrl.text,
                          'role': roleValue,
                          'batch_id': batchCtrl.text.isNotEmpty ? batchCtrl.text : null,
                          'department_id': deptCtrl.text.isNotEmpty ? deptCtrl.text : null,
                        });
                      }
                      Navigator.pop(ctx);
                      fetchUsers();
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFormField(TextEditingController controller, String label, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget buildRoleDropdown(String value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: _roles.where((r) => r != 'All').map((r) => DropdownMenuItem(
        value: r,
        child: Text(r.capitalize()),
      )).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Role',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      borderRadius: BorderRadius.circular(12),
    );
  }

  void confirmDelete(UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Confirm Deletion',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Delete user ${user.name} (${user.email})? This action cannot be undone.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () async {
                      await SupabaseService.deleteUser(user.id);
                      Navigator.pop(ctx);
                      fetchUsers();
                    },
                    child: Text(
                      'Delete',
                      style: TextStyle(color: Theme.of(context).colorScheme.onError),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const UserCard({
    required this.user,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: getRoleColor(user.role).withOpacity(0.2),
                    child: Text(
                      user.name[0].toUpperCase(),
                      style: TextStyle(
                        color: getRoleColor(user.role),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    icon: Icon(Icons.more_vert, color: colorScheme.onSurface.withOpacity(0.6)),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('Edit'),
                        onTap: onEdit,
                      ),
                      PopupMenuItem(
                        child: Text(
                          'Delete',
                          style: TextStyle(color: colorScheme.error),
                        ),
                        onTap: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  UserChip(
                    label: user.role.capitalize(),
                    color: getRoleColor(user.role),
                  ),
                  if (user.batchId.isNotEmpty)
                    UserChip(
                      label: 'Batch: \\${user.batchId}',
                      color: colorScheme.surfaceVariant,
                    ),
                  if (user.departmentId.isNotEmpty)
                    UserChip(
                      label: 'Dept: \\${user.departmentId}',
                      color: colorScheme.surfaceVariant,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.deepPurple;
      case 'hod':
        return Colors.orange;
      case 'batch_advisor':
        return Colors.blue;
      case 'student':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class UserChip extends StatelessWidget {
  final String label;
  final Color color;

  const UserChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}