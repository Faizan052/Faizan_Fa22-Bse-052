import 'dart:ui';
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
  String _complaintSearch = '';
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.08),
        elevation: 0,
        title: Text(
          "Advisor Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 24,
            letterSpacing: 1.1,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
        flexibleSpace: ClipRRect(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4F8FFF), Color(0xFF1CB5E0), Color(0xFF0F2027)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Consumer<ComplaintProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
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

            final _filteredComplaints = complaints.where((c) {
              return c.title.toLowerCase().contains(_complaintSearch.toLowerCase()) ||
                  c.description.toLowerCase().contains(_complaintSearch.toLowerCase());
            }).toList();

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 100, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter and Search Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: Row(
                      children: [
                        // Search bar
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                )],
                            ),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search complaints...',
                                prefixIcon: Icon(Icons.search, color: Color(0xFF4F8FFF)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                              style: TextStyle(
                                  color: Color(0xFF4F8FFF),
                                  fontWeight: FontWeight.w500),
                              onChanged: (val) => setState(() => _complaintSearch = val),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        // Filter dropdown
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              )],
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          child: DropdownButton<String>(
                            value: _selectedStatus,
                            items: _statusOptions.map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s,
                                style: TextStyle(
                                    color: Color(0xFF4F8FFF),
                                    fontWeight: FontWeight.w600),
                              ),
                            )).toList(),
                            onChanged: (val) => setState(() => _selectedStatus = val!),
                            underline: SizedBox(),
                            isExpanded: false,
                            dropdownColor: Colors.white,
                            icon: Icon(Icons.arrow_drop_down, color: Color(0xFF4F8FFF)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Center(
                      child: Container(
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
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Complaints List Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.report_problem, color: Colors.white, size: 26),
                        SizedBox(width: 10),
                        Text(
                          "Complaints",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(
                    color: Colors.white54,
                    thickness: 1,
                    height: 24,
                    endIndent: 8,
                  ),

                  // Complaints List
                  _filteredComplaints.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.inbox, size: 48, color: Colors.white54),
                                SizedBox(height: 16),
                                Text(
                                  "No complaints found",
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _filteredComplaints.length,
                          itemBuilder: (_, i) {
                            final isResolvedOrRejected = _filteredComplaints[i].status == 'Resolved' ||
                                _filteredComplaints[i].status == 'Rejected';
                            final isEscalated = _filteredComplaints[i].status == 'Escalated to HOD';
                            final user = Provider.of<AuthProvider>(context).user!;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    )],
                                ),
                                child: Card(
                                  elevation: 0,
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _showActions(context, _filteredComplaints[i], user.id),
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  shape: BoxShape.circle,
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  'C',
                                                  style: TextStyle(
                                                    color: Colors.blue.shade800,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      _filteredComplaints[i].title,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                    SizedBox(height: 8),
                                                    Container(
                                                      padding: EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: _getStatusColor(_filteredComplaints[i].status)
                                                            .withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(20),
                                                        border: Border.all(
                                                          color: _getStatusColor(_filteredComplaints[i].status)
                                                              .withOpacity(0.3),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        _filteredComplaints[i].status.replaceAll(' to HOD', ''),
                                                        style: TextStyle(
                                                          color: _getStatusColor(_filteredComplaints[i].status),
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 12),
                                          if (isResolvedOrRejected || isEscalated)
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 8),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    isEscalated
                                                        ? Icons.trending_up
                                                        : (_filteredComplaints[i].status == 'Resolved'
                                                            ? Icons.check_circle
                                                            : Icons.cancel),
                                                    color: isEscalated
                                                        ? Colors.orange
                                                        : (_filteredComplaints[i].status == 'Resolved'
                                                            ? Colors.green
                                                            : Colors.red),
                                                    size: 16,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    isEscalated
                                                        ? 'Escalated to HOD'
                                                        : (_filteredComplaints[i].status == 'Resolved'
                                                            ? 'Resolution confirmed'
                                                            : 'Complaint declined'),
                                                    style: TextStyle(
                                                      color: isEscalated
                                                          ? Colors.orange
                                                          : (_filteredComplaints[i].status == 'Resolved'
                                                              ? Colors.green
                                                              : Colors.red),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          Divider(height: 24, thickness: 1),
                                          _buildUserRow(
                                            icon: Icons.person,
                                            label: 'Student',
                                            id: _filteredComplaints[i].studentId,
                                          ),
                                          _buildUserRow(
                                            icon: Icons.school,
                                            label: 'Advisor',
                                            id: _filteredComplaints[i].advisorId,
                                          ),
                                          if (_filteredComplaints[i].hodId != null &&
                                              _filteredComplaints[i].hodId!.isNotEmpty)
                                            _buildUserRow(
                                              icon: Icons.engineering,
                                              label: 'HOD',
                                              id: _filteredComplaints[i].hodId!,
                                            ),
                                          SizedBox(height: 8),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton.icon(
                                              icon: Icon(Icons.visibility, size: 16),
                                              label: Text('View Details'),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.blue.shade700,
                                              ),
                                              onPressed: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => ComplaintHistory(
                                                      complaintId: _filteredComplaints[i].id!),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserRow({required IconData icon, required String label, required String id}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: FutureBuilder<String>(
              future: UserLookupService.getUserName(id),
              builder: (context, snapshot) {
                return Text(
                  snapshot.data ?? id,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
        ],
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
        return Colors.purple;
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
          "Complaint Details",
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
                        ? 'This complaint has been escalated to HOD'
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
        actions: (isResolvedOrRejected || isEscalated)
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to resolve: $e'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            child: Text("Resolve"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to escalate: $e'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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