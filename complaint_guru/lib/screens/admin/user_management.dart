import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/supabase_service.dart';
import '../../services/batch_service.dart';
import '../../services/department_service.dart';
import '../../models/batch.dart';
import '../../models/department.dart';

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
    final Color mainBlue = const Color(0xFF4F8FFF);
    final Color accentBlue = const Color(0xFF1CB5E0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'User Management',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 24,
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [mainBlue, accentBlue, const Color(0xFF0F2027)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 90),
            // Search and Filter Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        prefixIcon: Icon(Icons.search, color: mainBlue.withOpacity(0.7)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      style: TextStyle(color: mainBlue, fontWeight: FontWeight.w500),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        Icon(Icons.filter_list, color: accentBlue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<String>(
                            value: _roleFilter,
                            items: _roles.map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(
                                r == 'All' ? 'All Roles' : r.capitalize(),
                                style: TextStyle(color: mainBlue, fontWeight: FontWeight.w600),
                              ),
                            )).toList(),
                            onChanged: (val) => setState(() => _roleFilter = val!),
                            isExpanded: true,
                            underline: const SizedBox(),
                            icon: Icon(Icons.arrow_drop_down, color: accentBlue),
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // User List
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : filteredUsers.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_alt_outlined, size: 64, color: Colors.white.withOpacity(0.18)),
                    const SizedBox(height: 16),
                    Text(
                      _roleFilter == 'All'
                          ? 'No users found'
                          : 'No ${_roleFilter.capitalize()} users found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                itemCount: filteredUsers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showUserDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
        backgroundColor: Colors.white,
        foregroundColor: mainBlue,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
    final Color mainBlue = const Color(0xFF4F8FFF);
    final Color accentBlue = const Color(0xFF1CB5E0);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: Colors.white,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [mainBlue.withOpacity(0.08), accentBlue.withOpacity(0.08), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: accentBlue.withOpacity(0.08),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(26.0),
            child: Form(
              key: GlobalKey<FormState>(),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: mainBlue, size: 30),
                        const SizedBox(width: 12),
                        ShaderMask(
                          shaderCallback: (rect) => LinearGradient(
                            colors: [mainBlue, accentBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(rect),
                          child: Text(
                            user == null ? 'Add New User' : 'Edit User',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    buildFormField(nameCtrl, 'Name', icon: Icons.person_outline, mainBlue: mainBlue, accentBlue: accentBlue),
                    const SizedBox(height: 14),
                    buildFormField(emailCtrl, 'Email', icon: Icons.email_outlined, mainBlue: mainBlue, accentBlue: accentBlue),
                    if (user == null) ...[
                      const SizedBox(height: 14),
                      buildFormField(passwordCtrl, 'Password', obscureText: true, icon: Icons.lock_outline, mainBlue: mainBlue, accentBlue: accentBlue),
                    ],
                    const SizedBox(height: 14),
                    buildRoleDropdown(roleValue, (val) => roleValue = val!, mainBlue: mainBlue, accentBlue: accentBlue),
                    const SizedBox(height: 14),
                    buildFormField(batchCtrl, 'Batch ID (optional)', icon: Icons.group_outlined, mainBlue: mainBlue, accentBlue: accentBlue),
                    const SizedBox(height: 14),
                    buildFormField(deptCtrl, 'Department ID (optional)', icon: Icons.apartment_outlined, mainBlue: mainBlue, accentBlue: accentBlue),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(foregroundColor: mainBlue),
                          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 18),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 3,
                          ),
                          onPressed: () async {
                            if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty || (user == null && passwordCtrl.text.trim().isEmpty)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Please fill all required fields.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            try {
                              if (user == null) {
                                await SupabaseService.registerUserWithAuthClient(
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('User saved successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              String msg = e.toString();
                              if (msg.contains('not_admin') || msg.contains('statusCode: 403')) {
                                msg = 'You do not have permission to create users. Please contact your Supabase admin or use a service role key.';
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to save user: ' + msg),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: 0.6)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ));
  }

  Widget buildFormField(TextEditingController controller, String label, {bool obscureText = false, IconData? icon, Color? mainBlue, Color? accentBlue}) {
    final theme = Theme.of(context);
    mainBlue ??= const Color(0xFF4F8FFF);
    accentBlue ??= const Color(0xFF1CB5E0);
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(
        color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: mainBlue,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: icon != null ? Icon(icon, color: accentBlue) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: mainBlue.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accentBlue.withOpacity(0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: mainBlue, width: 2),
        ),
        filled: true,
        fillColor: theme.brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget buildRoleDropdown(String value, ValueChanged<String?> onChanged, {Color? mainBlue, Color? accentBlue}) {
    mainBlue ??= const Color(0xFF4F8FFF);
    accentBlue ??= const Color(0xFF1CB5E0);
    return DropdownButtonFormField<String>(
      value: value,
      items: _roles.where((r) => r != 'All').map((r) => DropdownMenuItem(
        value: r,
        child: Text(r.capitalize(), style: TextStyle(color: mainBlue, fontWeight: FontWeight.w600)),
      )).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Role',
        labelStyle: TextStyle(color: mainBlue, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: mainBlue.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accentBlue.withOpacity(0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: mainBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      borderRadius: BorderRadius.circular(16),
      dropdownColor: Colors.white,
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
                      try {
                        await SupabaseService.deleteUserWithAuthClient(user.id);
                        Navigator.pop(ctx);
                        fetchUsers();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('User deleted successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        Navigator.pop(ctx);
                        String msg = e.toString();
                        if (msg.contains('not_admin') || msg.contains('statusCode: 403')) {
                          msg = 'You do not have permission to delete users. Please contact your Supabase admin or use a service role key.';
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to delete user: ' + msg),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
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

class UserCard extends StatefulWidget {
  final UserModel user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const UserCard({
    required this.user,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  bool expanded = false;
  String? batchName;
  String? deptName;
  bool loadingNames = false;

  @override
  void initState() {
    super.initState();
    _fetchNames();
  }

  Future<void> _fetchNames() async {
    setState(() => loadingNames = true);
    String? bName;
    String? dName;
    try {
      if (widget.user.batchId.isNotEmpty) {
        final batches = await BatchService.getBatches();
        final batch = batches.firstWhere(
          (b) => b.id == widget.user.batchId,
          orElse: () => Batch(id: '', name: '', departmentId: '', advisorId: ''),
        );
        bName = batch.id.isNotEmpty ? batch.name : null;
      }
      if (widget.user.departmentId.isNotEmpty) {
        final depts = await DepartmentService.getDepartments();
        final dept = depts.firstWhere(
          (d) => d.id == widget.user.departmentId,
          orElse: () => Department(id: '', name: '', hodId: ''),
        );
        dName = dept.id.isNotEmpty ? dept.name : null;
      }
    } catch (_) {}
    setState(() {
      batchName = bName;
      deptName = dName;
      loadingNames = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color accentBlue = const Color(0xFF1CB5E0);
    final user = widget.user;
    final Color shadowColor = accentBlue.withOpacity(0.10);
    final Color mainBlue = const Color(0xFF4F8FFF);

    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      color: Colors.white,
      shadowColor: shadowColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => setState(() => expanded = !expanded),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: getRoleColor(user.role).withOpacity(0.13),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: getRoleColor(user.role).withOpacity(0.08),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        user.name[0].toUpperCase(),
                        style: TextStyle(
                          color: getRoleColor(user.role),
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontSize: 19,
                              letterSpacing: 1.1,
                            ),
                            softWrap: true,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: getRoleColor(user.role),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: getRoleColor(user.role).withOpacity(0.13),
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                user.role.capitalize(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ],
                ),
                if (expanded)
                  ...[
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey[300], thickness: 1, height: 1),
                    const SizedBox(height: 14),
                    Text(
                      'Email:',
                      style: TextStyle(fontWeight: FontWeight.w600, color: mainBlue, fontSize: 14),
                    ),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (user.batchId.isNotEmpty)
                      (loadingNames)
                        ? Row(children: [SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 8), Text('Loading batch...')])
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Batch:', style: TextStyle(fontWeight: FontWeight.w600, color: mainBlue, fontSize: 14)),
                              Text(batchName ?? user.batchId, style: TextStyle(color: accentBlue, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 10),
                            ],
                          ),
                    if (user.departmentId.isNotEmpty)
                      (loadingNames)
                        ? Row(children: [SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 8), Text('Loading department...')])
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Department:', style: TextStyle(fontWeight: FontWeight.w600, color: mainBlue, fontSize: 14)),
                              Text(deptName ?? user.departmentId, style: TextStyle(color: accentBlue, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 10),
                            ],
                          ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit_rounded, color: mainBlue, size: 26),
                          onPressed: widget.onEdit,
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_forever_rounded, color: Colors.red[300], size: 26),
                          onPressed: widget.onDelete,
                        ),
                      ],
                    ),
                  ],
              ],
            ),
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
  final Color? textColor;

  const UserChip({required this.label, required this.color, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor ?? (color.computeLuminance() > 0.5 ? Colors.black : Colors.white),
          fontSize: 13,
          fontWeight: FontWeight.w600,
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