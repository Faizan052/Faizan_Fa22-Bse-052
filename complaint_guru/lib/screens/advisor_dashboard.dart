import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/complaint_provider.dart';
import '../models/complaint.dart';
import 'complaint_history.dart';
import '../services/supabase_service.dart';

class AdvisorDashboard extends StatefulWidget {
  @override
  State<AdvisorDashboard> createState() => _AdvisorDashboardState();
}

class _AdvisorDashboardState extends State<AdvisorDashboard> {
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
    final user = Provider.of<AuthProvider>(context).user!;
    return Scaffold(
      appBar: AppBar(
        title: Text("Advisor Dashboard"),
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
              onTap: () => _showActions(context, provider.complaints[i], user.id),
              trailing: IconButton(
                icon: Icon(Icons.history),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ComplaintHistory(complaintId: provider.complaints[i].id!),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showActions(BuildContext context, Complaint c, String userId) {
    final commentCtrl = TextEditingController();
    final isResolved = c.status == 'Resolved';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Update Complaint"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.description),
            if (c.imageUrl.isNotEmpty) Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('Image: ${c.imageUrl}'),
            ),
            if (c.videoUrl.isNotEmpty) Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text('Video: ${c.videoUrl}'),
            ),
            TextField(controller: commentCtrl, decoration: InputDecoration(labelText: "Comment")),
          ],
        ),
        actions: isResolved
            ? [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Close"),
                ),
              ]
            : [
                TextButton(
                  onPressed: () async {
                    if (commentCtrl.text.isEmpty) return;
                    try {
                      await Provider.of<ComplaintProvider>(context, listen: false)
                          .updateStatus(c.id!, 'Resolved');
                      await Provider.of<ComplaintProvider>(context, listen: false)
                          .addHistory(
                            complaintId: c.id!,
                            action: 'Resolved',
                            comment: commentCtrl.text,
                            userId: userId,
                          );
                      final user = Provider.of<AuthProvider>(context, listen: false).user;
                      if (user != null) {
                        await Provider.of<ComplaintProvider>(context, listen: false)
                            .fetchComplaints(user.id, 'batch_advisor');
                      }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Complaint marked as Resolved.')),
                      );
                    } catch (e) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to resolve: $e')),
                      );
                    }
                  },
                  child: Text("Resolve"),
                ),
                TextButton(
                  onPressed: () async {
                    if (commentCtrl.text.isEmpty) return;
                    try {
                      await SupabaseService.escalateToHodWithDepartment(c.id!, c.batchId);
                      await Provider.of<ComplaintProvider>(context, listen: false)
                          .addHistory(
                            complaintId: c.id!,
                            action: 'Escalated to HOD',
                            comment: commentCtrl.text,
                            userId: userId,
                          );
                      final user = Provider.of<AuthProvider>(context, listen: false).user;
                      if (user != null) {
                        await Provider.of<ComplaintProvider>(context, listen: false)
                            .fetchComplaints(user.id, 'batch_advisor');
                      }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Complaint escalated to HOD.')),
                      );
                    } catch (e) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to escalate: $e')),
                      );
                    }
                  },
                  child: Text("Escalate"),
                ),
              ],
      ),
    );
  }
}

// TODO: Implement complaint timeline feature
// TODO: Add filtering options by status, date, and student
// TODO: Integrate notifications for status and handler changes
// TODO: Implement complaint_history updates
