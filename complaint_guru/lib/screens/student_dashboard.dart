import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/complaint_provider.dart';
import 'complaint_form.dart';
import 'complaint_history.dart';

class StudentDashboard extends StatefulWidget {
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
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
          return ListView.builder(
            itemCount: provider.complaints.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(provider.complaints[i].title),
              subtitle: Text(provider.complaints[i].status),
              trailing: Text(provider.complaints[i].createdAt
                  .toLocal()
                  .toString()
                  .split(" ").first),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ComplaintHistory(complaintId: provider.complaints[i].id!),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
