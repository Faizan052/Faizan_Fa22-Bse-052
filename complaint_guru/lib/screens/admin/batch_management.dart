import 'package:flutter/material.dart';
import '../../services/batch_service.dart';
import '../../models/batch.dart';
import '../../services/supabase_service.dart';
import '../../services/department_service.dart';
import '../../models/department.dart';

class BatchManagementScreen extends StatefulWidget {
  @override
  State<BatchManagementScreen> createState() => _BatchManagementScreenState();
}

class _BatchManagementScreenState extends State<BatchManagementScreen> {
  List<Batch> batches = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

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

  List<Batch> get filteredBatches {
    if (_searchController.text.isEmpty) return batches;
    final search = _searchController.text.toLowerCase();
    return batches.where((b) => b.name.toLowerCase().contains(search)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final Color mainBlue = const Color(0xFF4F8FFF);
    final Color accentBlue = const Color(0xFF1CB5E0);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final double topPad = isMobile ? 110.0 : 130.0; // More space from header
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
                      'Batch Management',
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
            : batches.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.groups_rounded, size: 64, color: Colors.white.withOpacity(0.18)),
                        const SizedBox(height: 16),
                        Text(
                          'No batches found',
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
                                hintText: 'Search batches...',
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            itemCount: filteredBatches.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 18),
                            itemBuilder: (ctx, i) {
                              final batch = filteredBatches[i];
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  gradient: LinearGradient(
                                    colors: [mainBlue.withOpacity(0.10), accentBlue.withOpacity(0.08), Colors.white.withOpacity(0.95)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: mainBlue.withOpacity(0.10),
                                      blurRadius: 18,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Card(
                                  elevation: 10,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                                  color: Colors.white,
                                  shadowColor: accentBlue.withOpacity(0.16),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [mainBlue.withOpacity(0.18), accentBlue.withOpacity(0.13)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: CircleAvatar(
                                            radius: 30,
                                            backgroundColor: Colors.transparent,
                                            child: Icon(Icons.groups_rounded, color: mainBlue, size: 34),
                                          ),
                                        ),
                                        const SizedBox(width: 18),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                batch.name,
                                                style: const TextStyle(
                                                  fontSize: 21,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.1,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              const SizedBox(height: 7),
                                              FutureBuilder(
                                                future: _getBatchSubtitle(batch),
                                                builder: (context, snapshot) {
                                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                                    return Text('Loading...', style: TextStyle(fontSize: 14, color: Colors.grey[700]));
                                                  }
                                                  return Text(
                                                    snapshot.data ?? '',
                                                    style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.edit_rounded, color: mainBlue, size: 26),
                                              tooltip: 'Edit',
                                              onPressed: () => _showAddEditDialog(batch: batch),
                                            ),
                                            const SizedBox(height: 6),
                                            IconButton(
                                              icon: Icon(Icons.delete_forever_rounded, color: Colors.red[300], size: 26),
                                              tooltip: 'Delete',
                                              onPressed: () async {
                                                final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (_) => AlertDialog(
                                                    backgroundColor: Colors.white,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                    title: const Text('Delete Batch'),
                                                    content: const Text('Are you sure you want to delete this batch?'),
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
                                                  await BatchService.deleteBatch(batch.id);
                                                  _fetchBatches();
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
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
        label: const Text('Add Batch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: 0.6)),
        backgroundColor: mainBlue,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        extendedPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      ),
    );
  }

  Future<String> _getBatchSubtitle(Batch batch) async {
    final departments = await DepartmentService.getDepartments();
    final advisors = await SupabaseService.getAllUsers();
    Department deptObj = departments.firstWhere((d) => d.id == batch.departmentId, orElse: () => Department(id: '', name: 'Unknown', hodId: ''));
    final advisor = advisors.firstWhere((a) => a['id'] == batch.advisorId, orElse: () => {'name': 'Unknown', 'email': ''});
    return 'Department: ${deptObj.name}\nAdvisor: ${advisor['name'] ?? advisor['email'] ?? advisor['id']}';
  }

  void _showAddEditDialog({Batch? batch}) async {
    final Color mainBlue = const Color(0xFF4F8FFF);
    final Color accentBlue = const Color(0xFF1CB5E0);
    final nameCtrl = TextEditingController(text: batch?.name ?? '');
    String? selectedDeptId = batch?.departmentId;
    String? selectedAdvisorId = batch?.advisorId;
    final departments = await DepartmentService.getDepartments();
    final advisors = (await SupabaseService.getAllUsers())
        .where((u) => u['role'] == 'batch_advisor' || u['role'] == 'advisor')
        .toList();
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.groups_rounded, color: mainBlue, size: 30),
                        const SizedBox(width: 12),
                        ShaderMask(
                          shaderCallback: (rect) => LinearGradient(
                            colors: [mainBlue, accentBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(rect),
                          child: Text(
                            batch == null ? 'Add Batch' : 'Edit Batch',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Batch Name',
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
                      validator: (val) => val == null || val.isEmpty ? 'Enter batch name' : null,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedDeptId?.isNotEmpty == true ? selectedDeptId : null,
                      items: departments
                          .map((d) => DropdownMenuItem<String>(
                                value: d.id,
                                child: Text(d.name, style: TextStyle(color: mainBlue, fontWeight: FontWeight.w600)),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => selectedDeptId = val),
                      decoration: InputDecoration(
                        labelText: 'Department',
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
                      validator: (val) => val == null || val.isEmpty ? 'Select department' : null,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedAdvisorId?.isNotEmpty == true ? selectedAdvisorId : null,
                      items: advisors
                          .map((a) => DropdownMenuItem<String>(
                                value: a['id'] as String,
                                child: Text(a['name'] ?? a['email'] ?? a['id'], style: TextStyle(color: mainBlue, fontWeight: FontWeight.w600)),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => selectedAdvisorId = val),
                      decoration: InputDecoration(
                        labelText: 'Advisor',
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
                      validator: (val) => val == null || val.isEmpty ? 'Select advisor' : null,
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
                                    if (batch == null) {
                                      await BatchService.addBatch(
                                          nameCtrl.text, selectedDeptId ?? '', selectedAdvisorId ?? '');
                                    } else {
                                      await BatchService.updateBatch(batch.id, nameCtrl.text,
                                          selectedDeptId ?? '', selectedAdvisorId ?? '');
                                    }
                                    Navigator.pop(context);
                                    _fetchBatches();
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
      ));
  }
}
