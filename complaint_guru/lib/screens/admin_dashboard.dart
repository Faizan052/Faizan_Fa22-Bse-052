import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/complaint_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/excel_service.dart';
import 'complaint_history.dart';
import '../providers/auth_provider.dart';

class AdminDashboard extends StatefulWidget {
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ExcelService excelService = ExcelService();

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
          final complaints = provider.complaints;
          final total = complaints.length;
          final resolved = complaints.where((c) => c.status == 'Resolved').length;
          final pending = complaints.where((c) => c.status == 'Submitted' || c.status == 'In Progress').length;
          final escalated = complaints.where((c) => c.status == 'Escalated to HOD').length;
          final rejected = complaints.where((c) => c.status == 'Rejected').length;
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
                            subtitle: Text(complaints[i].status),
                            trailing: IconButton(
                              icon: Icon(Icons.history),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ComplaintHistory(complaintId: complaints[i].id!),
                                ),
                              ),
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
