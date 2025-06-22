import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/complaint_provider.dart';
import '../models/complaint.dart';
import 'complaint_history.dart';
import '../services/user_lookup_service.dart';

class HodDashboard extends StatefulWidget {
  @override
  State<HodDashboard> createState() => _HodDashboardState();
}

class _HodDashboardState extends State<HodDashboard> {
  String _selectedStatus = 'All';
  static const List<String> _statusOptions = [
    'All',
    'Pending',
    'Resolved',
    'Rejected',
    'Escalated to HOD',
  ];
  bool _showAll = false;

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
          final allComplaints = provider.complaints;
          final escalatedComplaints = allComplaints.where((c) => c.status == 'Escalated to HOD').toList();
          final complaints = _showAll
              ? allComplaints.where((c) {
                  if (_selectedStatus == 'All') return true;
                  if (_selectedStatus == 'Pending') return c.status == 'Submitted' || c.status == 'In Progress';
                  return c.status == _selectedStatus;
                }).toList()
              : escalatedComplaints.where((c) {
                  if (_selectedStatus == 'All') return true;
                  if (_selectedStatus == 'Pending') return c.status == 'Escalated to HOD';
                  return c.status == _selectedStatus;
                }).toList();
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setState(() => _selectedStatus = val!),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => _showAll = !_showAll),
                      child: Text(_showAll ? 'Show Escalated Only' : 'Show All Complaints'),
                    ),
                  ],
                ),
              ),
              if (!_showAll)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Escalated Pending: '
                      + escalatedComplaints.length.toString(),
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                ),
              Expanded(
                child: complaints.isEmpty
                    ? Center(child: Text('No complaints found.'))
                    : ListView.builder(
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
                                          color: complaints[i].status == 'Resolved'
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.bold,
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
                            onTap: (!_showAll && complaints[i].status == 'Escalated to HOD') ? () => _showActions(context, complaints[i], user.id) : null,
                            trailing: IconButton(
                              icon: Icon(Icons.history),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ComplaintHistory(complaintId: complaints[i].id!),
                                ),
                              ),
                            ),
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

  void _showActions(BuildContext context, Complaint c, String userId) {
    final commentCtrl = TextEditingController();
    final isResolvedOrRejected = c.status == 'Resolved' || c.status == 'Rejected';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Complaint Details"),
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
            SizedBox(height: 8),
            if (isResolvedOrRejected)
              Text(
                c.status == 'Resolved' ? 'This complaint is resolved.' : 'This complaint is rejected.',
                style: TextStyle(fontWeight: FontWeight.bold, color: c.status == 'Resolved' ? Colors.green : Colors.red),
              ),
            if (!isResolvedOrRejected)
              TextField(controller: commentCtrl, decoration: InputDecoration(labelText: "Comment")),
            SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ComplaintHistory(complaintId: c.id!),
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history),
                  SizedBox(width: 4),
                  Text('View History'),
                ],
              ),
            ),
          ],
        ),
        actions: isResolvedOrRejected
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
