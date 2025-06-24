import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/complaint_provider.dart';
import '../models/complaint.dart';
import 'complaint_history.dart';
import '../services/supabase_service.dart';
import '../services/user_lookup_service.dart';

class AdvisorDashboard extends StatefulWidget {
  @override
  State<AdvisorDashboard> createState() => _AdvisorDashboardState();
}

class _AdvisorDashboardState extends State<AdvisorDashboard> {
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final user = Provider.of<AuthProvider>(context).user!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Advisor Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
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
            return Center(
              child: CircularProgressIndicator(
                color: primaryColor,
                strokeWidth: 3,
              ),
            );
          }

          final complaints = provider.complaints.where((c) {
            if (_selectedStatus == 'All') return true;
            if (_selectedStatus == 'Pending') return c.status == 'Submitted' || c.status == 'In Progress';
            return c.status == _selectedStatus;
          }).toList();

          final pendingCount = provider.complaints
              .where((c) => c.status == 'Submitted' || c.status == 'In Progress')
              .length;

          return Column(
            children: [
              // Filter and Status Bar
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[700] : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedStatus,
                          items: _statusOptions
                              .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedStatus = val!),
                          underline: SizedBox(),
                          isExpanded: true,
                          dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                          icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.4)),
                      ),
                      child: Text(
                        'Pending: $pendingCount',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Complaints List
              Expanded(
                child: complaints.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox,
                        size: 48,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No complaints found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: EdgeInsets.all(8),
                  itemCount: complaints.length,
                  itemBuilder: (_, i) => Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      title: Text(
                        complaints[i].title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 8),
                          // Status indicator
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(complaints[i].status)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getStatusColor(complaints[i].status)
                                    .withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              complaints[i].status,
                              style: TextStyle(
                                color: _getStatusColor(complaints[i].status),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          // Resolution status
                          if (complaints[i].status == 'Resolved' ||
                              complaints[i].status == 'Rejected')
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                complaints[i].status == 'Resolved'
                                    ? 'This complaint is resolved.'
                                    : 'This complaint is rejected.',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: complaints[i].status == 'Resolved'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ),
                          // User information
                          FutureBuilder<String>(
                            future: UserLookupService.getUserName(
                                complaints[i].studentId),
                            builder: (context, studentSnap) => Text(
                              "Student: ${studentSnap.data ?? complaints[i].studentId}",
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          FutureBuilder<String>(
                            future: UserLookupService.getUserName(
                                complaints[i].advisorId),
                            builder: (context, advisorSnap) => Text(
                              "Advisor: ${advisorSnap.data ?? complaints[i].advisorId}",
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          if (complaints[i].hodId != null &&
                              complaints[i].hodId!.isNotEmpty)
                            FutureBuilder<String>(
                              future: UserLookupService.getUserName(
                                  complaints[i].hodId!),
                              builder: (context, hodSnap) => Text(
                                "HOD: ${hodSnap.data ?? complaints[i].hodId}",
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                        ],
                      ),
                      onTap: () => _showActions(context, complaints[i], user.id),
                      trailing: IconButton(
                        icon: Icon(Icons.history, color: primaryColor),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ComplaintHistory(complaintId: complaints[i].id!),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Resolved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Escalated to HOD':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showActions(BuildContext context, Complaint c, String userId) {
    final commentCtrl = TextEditingController();
    final isResolvedOrRejected = c.status == 'Resolved' || c.status == 'Rejected';
    final isEscalated = c.status == 'Escalated to HOD';
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          "Update Complaint",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.description,
                style: TextStyle(fontSize: 14),
              ),
              if (c.imageUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Image: ${c.imageUrl}',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
              if (c.videoUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Video: ${c.videoUrl}',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
              SizedBox(height: 12),
              if (isResolvedOrRejected || isEscalated)
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isEscalated
                        ? Colors.orange.withOpacity(0.1)
                        : (c.status == 'Resolved'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isEscalated
                        ? 'This complaint has been escalated to HOD.'
                        : (c.status == 'Resolved'
                        ? 'This complaint is resolved.'
                        : 'This complaint is rejected.'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isEscalated
                          ? Colors.orange
                          : (c.status == 'Resolved' ? Colors.green : Colors.red),
                    ),
                  ),
                ),
              if (!isResolvedOrRejected && !isEscalated)
                TextField(
                  controller: commentCtrl,
                  decoration: InputDecoration(
                    labelText: "Comment",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              SizedBox(height: 12),
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
                    Icon(Icons.history, size: 18),
                    SizedBox(width: 4),
                    Text('View History'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: isResolvedOrRejected || isEscalated
            ? [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ]
            : [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
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
                  SnackBar(
                    content: Text('Complaint marked as Resolved.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to resolve: $e'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text("Resolve"),
          ),
          ElevatedButton(
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
                  SnackBar(
                    content: Text('Complaint escalated to HOD.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to escalate: $e'),
                    behavior: SnackBarBehavior.floating,
                  ),
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