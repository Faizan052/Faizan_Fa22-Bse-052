import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/complaint_provider.dart';
import '../models/complaint.dart';
import 'complaint_history.dart';

class HodDashboard extends StatefulWidget {
  @override
  State<HodDashboard> createState() => _HodDashboardState();
}

class _HodDashboardState extends State<HodDashboard> {
  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      Provider.of<ComplaintProvider>(context, listen: false)
          .fetchComplaints(user.id, 'hod');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user!;
    return Scaffold(
      appBar: AppBar(
        title: Text("HOD Dashboard"),
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
          // Show only complaints escalated to this HOD
          final complaints = provider.complaints.where((c) => c.hodId == user.id && c.status == 'Escalated to HOD').toList();
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          if (complaints.isEmpty) {
            return Center(child: Text('No complaints found.'));
          }
          return Column(
            children: [
              _buildFilterSection(),
              Expanded(
                child: ListView.builder(
                  itemCount: complaints.length,
                  itemBuilder: (_, i) => Card(
                    margin: EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(complaints[i].title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(complaints[i].status),
                          Text("Student: ${complaints[i].studentId}"),
                          Text("Advisor: ${complaints[i].advisorId}"),
                          Text("Batch: ${complaints[i].batchId}"),
                        ],
                      ),
                      onTap: () => _showActions(context, complaints[i], user.id),
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DropdownButton<String>(
            hint: Text("Select Batch"),
            onChanged: (value) {
              // TODO: Implement batch filtering
            },
            items: [], // TODO: Populate with batch options
          ),
          DropdownButton<String>(
            hint: Text("Select Advisor"),
            onChanged: (value) {
              // TODO: Implement advisor filtering
            },
            items: [], // TODO: Populate with advisor options
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement student filtering
            },
            child: Text("Filter by Student"),
          ),
        ],
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
              child: Text('Image: [200b${c.imageUrl}'),
            ),
            if (c.videoUrl.isNotEmpty) Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text('Video: [200b${c.videoUrl}'),
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
                            .fetchComplaints(user.id, 'hod');
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
                      await Provider.of<ComplaintProvider>(context, listen: false)
                          .updateStatus(c.id!, 'Rejected');
                      await Provider.of<ComplaintProvider>(context, listen: false)
                          .addHistory(
                            complaintId: c.id!,
                            action: 'Rejected',
                            comment: commentCtrl.text,
                            userId: userId,
                          );
                      final user = Provider.of<AuthProvider>(context, listen: false).user;
                      if (user != null) {
                        await Provider.of<ComplaintProvider>(context, listen: false)
                            .fetchComplaints(user.id, 'hod');
                      }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Complaint marked as Rejected.')),
                      );
                    } catch (e) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to reject: $e')),
                      );
                    }
                  },
                  child: Text("Reject"),
                ),
              ],
      ),
    );
  }
}
