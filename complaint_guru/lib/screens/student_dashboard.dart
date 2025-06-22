import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/complaint_provider.dart';
import 'complaint_form.dart';
import 'complaint_history.dart';
import '../services/user_lookup_service.dart';

class StudentDashboard extends StatefulWidget {
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
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
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      Provider.of<ComplaintProvider>(context, listen: false)
          .fetchComplaints(user.id, 'batch_advisor');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Student Dashboard"),
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
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => ComplaintForm())),
      ),
      body: Consumer<ComplaintProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          if (provider.complaints.isEmpty) {
            return Center(child: Text('No complaints found.'));
          }
          // Filter logic
          List complaints = provider.complaints.where((c) {
            if (_selectedStatus == 'All') return true;
            if (_selectedStatus == 'Pending') return c.status == 'Submitted' || c.status == 'In Progress';
            return c.status == _selectedStatus;
          }).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButton<String>(
                  value: _selectedStatus,
                  items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => setState(() => _selectedStatus = val!),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: complaints.length,
                  itemBuilder: (_, i) {
                    return ListTile(
                      title: Text(complaints[i].title),
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
                      trailing: Text(complaints[i].createdAt
                          .toLocal()
                          .toString()
                          .split(" ").first),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ComplaintHistory(complaintId: complaints[i].id!),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
