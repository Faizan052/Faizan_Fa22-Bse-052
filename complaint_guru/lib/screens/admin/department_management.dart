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
  final TextEditingController _searchController = TextEditingController();

  List<Department> get filteredDepartments {
    if (_searchController.text.isEmpty) return departments;
    final search = _searchController.text.toLowerCase();
    return departments.where((d) => d.name.toLowerCase().contains(search)).toList();
  }

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

  Future<String> _getHodName(String hodId) async {
    try {
      final hods = await SupabaseService.getAllHods();
      Map<String, dynamic>? hod;
      for (final h in hods) {
        if (h['id'] == hodId) {
          hod = h;
          break;
        }
      }
      hod ??= <String, dynamic>{};
      if (hod['name'] != null && hod['name'].toString().isNotEmpty) {
        return hod['name'];
      } else if (hod['email'] != null) {
        return hod['email'];
      }
      return hodId;
    } catch (_) {
      return hodId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color mainBlue = const Color(0xFF4F8FFF);
    final Color accentBlue = const Color(0xFF1CB5E0);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final double topPad = isMobile ? 110.0 : 130.0; // Increased space from header
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 70 : 90),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [mainBlue.withOpacity(0.95), accentBlue.withOpacity(0.95)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 18),
                    child: Text(
                      'Department Management',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: isMobile ? 22 : 26,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [mainBlue, accentBlue, const Color(0xFF0F2027)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.1, 0.5, 0.9],
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : departments.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.apartment_rounded, size: 64, color: Colors.white.withOpacity(0.18)),
              const SizedBox(height: 16),
              Text(
                'No departments found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        )
            : Padding(
          padding: EdgeInsets.only(top: topPad),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
                child: Container(
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
                      hintText: 'Search departments...',
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
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  itemCount: filteredDepartments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final dept = filteredDepartments[i];
                    return Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      color: Colors.white,
                      shadowColor: accentBlue.withOpacity(0.12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundColor: mainBlue.withOpacity(0.13),
                          child: Icon(Icons.apartment_rounded, color: mainBlue, size: 32),
                        ),
                        title: Text(
                          dept.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: Colors.black,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: FutureBuilder<String>(
                            future: _getHodName(dept.hodId),
                            builder: (context, snapshot) {
                              final hodName = snapshot.data ?? dept.hodId;
                              return Text(
                                'HOD: $hodName',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit_rounded, color: mainBlue, size: 26),
                              tooltip: 'Edit',
                              onPressed: () => _showAddEditDialog(dept: dept),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_forever_rounded, color: Colors.red[300], size: 26),
                              tooltip: 'Delete',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    title: const Text('Delete Department'),
                                    content: const Text('Are you sure you want to delete this department?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: Text('Cancel', style: TextStyle(color: mainBlue)),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400]),
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await DepartmentService.deleteDepartment(dept.id);
                                  _fetchDepartments();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Department', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: 0.6)),
        backgroundColor: mainBlue,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        extendedPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      ),
    );
  }

  void _showAddEditDialog({Department? dept}) async {
    final Color mainBlue = const Color(0xFF4F8FFF);
    final Color accentBlue = const Color(0xFF1CB5E0);
    final nameCtrl = TextEditingController(text: dept?.name ?? '');
    String? selectedHodId = dept?.hodId;
    List<Map<String, dynamic>> hods = await SupabaseService.getAllHods();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;
    String? errorMsg;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => StatefulBuilder(
          builder: (context, setState) => Dialog(
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
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.apartment_rounded, color: mainBlue, size: 30),
                            const SizedBox(width: 12),
                            ShaderMask(
                              shaderCallback: (rect) => LinearGradient(
                                colors: [mainBlue, accentBlue],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(rect),
                              child: Text(
                                dept == null ? 'Add Department' : 'Edit Department',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Department Name',
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
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Enter department name' : null,
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: selectedHodId?.isNotEmpty == true ? selectedHodId : null,
                          items: hods.map((h) => DropdownMenuItem<String>(
                            value: h['id'] as String,
                            child: Text(h['name'] ?? h['email'] ?? h['id'], style: TextStyle(color: mainBlue, fontWeight: FontWeight.w600)),
                          )).toList(),
                          onChanged: (val) => setState(() => selectedHodId = val),
                          decoration: InputDecoration(
                            labelText: 'HOD',
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
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                        if (errorMsg != null) ...[
                          const SizedBox(height: 10),
                          Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                        ],
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: isSaving ? null : () => Navigator.pop(context),
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
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                if (!(formKey.currentState?.validate() ?? false)) return;
                                setState(() { isSaving = true; errorMsg = null; });
                                try {
                                  if (dept == null) {
                                    await DepartmentService.addDepartment(nameCtrl.text, selectedHodId ?? '');
                                  } else {
                                    await DepartmentService.updateDepartment(dept.id, nameCtrl.text, selectedHodId ?? '');
                                  }
                                  Navigator.pop(context);
                                  _fetchDepartments();
                                } catch (e) {
                                  setState(() { errorMsg = 'Failed to save. Please try again.'; });
                                } finally {
                                  setState(() { isSaving = false; });
                                }
                              },
                              child: isSaving
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: 0.6)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ));
  }
}