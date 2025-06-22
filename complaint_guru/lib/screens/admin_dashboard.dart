import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/complaint_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/excel_service.dart';
import 'complaint_history.dart';
import '../providers/auth_provider.dart';
import '../services/user_lookup_service.dart';

class AdminDashboard extends StatefulWidget {
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ExcelService excelService = ExcelService();
  String _selectedStatus = 'All';
  static const List<String> _statusOptions = [
    'All',
    'Pending',
    'Resolved',
    'Rejected',
    'Escalated to HOD',
  ];

  @override
  void initState() {
    super.initState();
    Provider.of<ComplaintProvider>(context, listen: false).fetchComplaints('', 'admin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
      body: Consumer<ComplaintProvider>(
        builder: (context, provider, _) {
          final complaints = provider.complaints.where((c) {
            if (_selectedStatus == 'All') return true;
            if (_selectedStatus == 'Pending') return c.status == 'Submitted' || c.status == 'In Progress';
            return c.status == _selectedStatus;
          }).toList();
          final total = provider.complaints.length;
          final resolved = provider.complaints.where((c) => c.status == 'Resolved').length;
          final pending = provider.complaints.where((c) => c.status == 'Submitted' || c.status == 'In Progress').length;
          final escalated = provider.complaints.where((c) => c.status == 'Escalated to HOD').length;
          final rejected = provider.complaints.where((c) => c.status == 'Rejected').length;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statCard('Total', total, Colors.blue),
                      _statCard('Resolved', resolved, Colors.green),
                      _statCard('Pending', pending, Colors.orange),
                      _statCard('Escalated', escalated, Colors.purple),
                      _statCard('Rejected', rejected, Colors.red),
                    ],
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: Icon(Icons.upload_file),
                    label: Text("Upload Students via Excel"),
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['xlsx', 'csv'],
                      );
                      if (result != null) {
                        final file = result.files.single;
                        final success = await excelService.uploadStudentExcel(file);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(success ? 'Upload Successful' : 'Upload Failed')),
                        );
                      }
                    },
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownButton<String>(
                      value: _selectedStatus,
                      items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) => setState(() => _selectedStatus = val!),
                    ),
                  ),
                  Text("Complaints List", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Divider(),
                  provider.isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: complaints.length,
                          itemBuilder: (_, i) => ListTile(
                            title: Text(complaints[i].title),
                            trailing: IconButton(
                              icon: Icon(Icons.history),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ComplaintHistory(complaintId: complaints[i].id!),
                                ),
                              ),
                            ),
                            isThreeLine: true,
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                (complaints[i].status == 'Resolved' || complaints[i].status == 'Rejected')
                                    ? Text(
                                        complaints[i].status == 'Resolved'
                                            ? 'This complaint is resolved.'
                                            : 'This complaint is rejected.',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: complaints[i].status == 'Resolved' ? Colors.green : Colors.red,
                                        ),
                                      )
                                    : Text(complaints[i].status),
                                FutureBuilder<String>(
                                  future: UserLookupService.getUserName(complaints[i].studentId),
                                  builder: (context, studentSnap) => Text("Student: "+(studentSnap.data ?? complaints[i].studentId)),
                                ),
                                FutureBuilder<String>(
                                  future: UserLookupService.getUserName(complaints[i].advisorId),
                                  builder: (context, advisorSnap) => Text("Advisor: "+(advisorSnap.data ?? complaints[i].advisorId)),
                                ),
                                complaints[i].hodId != null && complaints[i].hodId!.isNotEmpty
                                  ? FutureBuilder<String>(
                                      future: UserLookupService.getUserName(complaints[i].hodId!),
                                      builder: (context, hodSnap) => Text("HOD: "+(hodSnap.data ?? complaints[i].hodId!)),
                                    )
                                  : SizedBox.shrink(),
                              ],
                            ),
                          ),
                        ),
                  SizedBox(height: 24),
                  Text("Department/Batch/User Management", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Divider(),
                  Text("- Add/Edit/Delete Departments (TODO)"),
                  Text("- Assign Advisors to Batches (TODO)"),
                  Text("- Create HOD Accounts (TODO)"),
                  Text("- Manage Users (TODO)"),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(String label, int value, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(value.toString(), style: TextStyle(fontSize: 18, color: color)),
          ],
        ),
      ),
    );
  }
}
