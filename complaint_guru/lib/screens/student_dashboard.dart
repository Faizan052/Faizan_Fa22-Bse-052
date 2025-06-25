import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Student Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
            shadows: [
            Shadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(1, 1),
            )],
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withOpacity(0.8),
                primaryColor.withOpacity(0.4),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
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
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.add, color: Colors.white, size: 28),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ComplaintForm()),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ]
                : [
              Color(0xFF4F8FFF),
              Color(0xFF1CB5E0),
              Color(0xFF0F2027),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.1, 0.5, 0.9],
          ),
        ),
        child: Consumer<ComplaintProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              );
            }

            final complaints = provider.complaints;
            final total = complaints.length;
            final resolved = complaints.where((c) => c.status == 'Resolved').length;
            final pending = complaints.where((c) => c.status == 'Submitted' || c.status == 'In Progress').length;
            final rejected = complaints.where((c) => c.status == 'Rejected').length;

            final filteredComplaints = complaints.where((c) {
              if (_selectedStatus == 'All') return true;
              if (_selectedStatus == 'Pending') return c.status == 'Submitted' || c.status == 'In Progress';
              return c.status == _selectedStatus;
            }).toList();

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 100, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Cards - Responsive layout
                  if (isMobile)
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                icon: Icons.list_alt,
                                value: total,
                                label: 'Total',
                                color: Color(0xFF4285F4),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: StatCard(
                                icon: Icons.check_circle,
                                value: resolved,
                                label: 'Resolved',
                                color: Color(0xFF0F9D58),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                icon: Icons.hourglass_bottom,
                                value: pending,
                                label: 'Pending',
                                color: Color(0xFFF4B400),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: StatCard(
                                icon: Icons.cancel,
                                value: rejected,
                                label: 'Rejected',
                                color: Color(0xFFDB4437),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    GridView.count(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      childAspectRatio: 1.4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        StatCard(
                          icon: Icons.list_alt,
                          value: total,
                          label: 'Total',
                          color: Color(0xFF4285F4),
                        ),
                        StatCard(
                          icon: Icons.check_circle,
                          value: resolved,
                          label: 'Resolved',
                          color: Color(0xFF0F9D58),
                        ),
                        StatCard(
                          icon: Icons.hourglass_bottom,
                          value: pending,
                          label: 'Pending',
                          color: Color(0xFFF4B400),
                        ),
                        StatCard(
                          icon: Icons.cancel,
                          value: rejected,
                          label: 'Rejected',
                          color: Color(0xFFDB4437),
                        ),
                      ],
                    ),

                  SizedBox(height: 24),

                  // Filter Section
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          spreadRadius: 2,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.filter_alt, color: primaryColor),
                        SizedBox(width: 12),
                        Expanded(
                          child: DropdownButton<String>(
                            value: _selectedStatus,
                            items: _statusOptions.map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s,
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )).toList(),
                            onChanged: (val) => setState(() => _selectedStatus = val!),
                            underline: SizedBox(),
                            isExpanded: true,
                            dropdownColor: isDarkMode ? Colors.grey[900] : Colors.white,
                            icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Complaints List Header
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Icon(Icons.report_problem, color: Colors.white, size: 26),
                        SizedBox(width: 10),
                        Text(
                          "Your Complaints",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(
                    color: Colors.white.withOpacity(0.3),
                    thickness: 1,
                    height: 24,
                    endIndent: 8,
                  ),

                  // Complaints List
                  if (filteredComplaints.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.inbox, size: 48, color: Colors.white.withOpacity(0.5)),
                            SizedBox(height: 16),
                            Text(
                              _selectedStatus == 'All'
                                  ? "You haven't filed any complaints yet"
                                  : "No ${_selectedStatus.toLowerCase()} complaints",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap the + button to create a new complaint',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: filteredComplaints.length,
                      itemBuilder: (_, index) {
                        return FutureBuilder<Map<String, String?>>(
                          future: _getUserNames(filteredComplaints[index]),
                          builder: (context, snapshot) {
                            final advisorName = snapshot.data?['advisor'] ?? filteredComplaints[index].advisorId;
                            final hodName = snapshot.data?['hod'];
                            return ComplaintCard(
                              complaint: filteredComplaints[index],
                              isDarkMode: isDarkMode,
                              primaryColor: primaryColor,
                              advisorName: advisorName,
                              hodName: hodName,
                            );
                          },
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

  Future<Map<String, String?>> _getUserNames(dynamic complaint) async {
    final advisorName = await UserLookupService.getUserName(complaint.advisorId);
    String? hodName;
    if (complaint.hodId != null && complaint.hodId!.isNotEmpty) {
      hodName = await UserLookupService.getUserName(complaint.hodId!);
    }
    return {
      'advisor': advisorName,
      'hod': hodName,
    };
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  const StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.2),
                    color.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            SizedBox(height: 12),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ComplaintCard extends StatelessWidget {
  final dynamic complaint;
  final bool isDarkMode;
  final Color primaryColor;
  final String advisorName;
  final String? hodName;

  const ComplaintCard({
    required this.complaint,
    required this.isDarkMode,
    required this.primaryColor,
    required this.advisorName,
    this.hodName,
  });

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

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(complaint.status);
    final isResolved = complaint.status == 'Resolved';
    final isRejected = complaint.status == 'Rejected';

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ComplaintHistory(complaintId: complaint.id!),
            ),
          );
        },
        splashColor: primaryColor.withOpacity(0.1),
        highlightColor: primaryColor.withOpacity(0.05),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      complaint.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    complaint.createdAt.toLocal().toString().split(" ").first,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Status badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withOpacity(0.1),
                      statusColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  complaint.status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

              SizedBox(height: 12),

              // Resolution status if applicable
              if (isResolved || isRejected)
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isResolved ? Icons.check_circle : Icons.cancel,
                        color: statusColor,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        isResolved ? 'Resolved successfully' : 'Complaint rejected',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 12),

              // User information
              UserInfoRow(
                icon: Icons.school,
                label: 'Advisor',
                name: advisorName,
              ),
              if (hodName != null)
                UserInfoRow(
                  icon: Icons.engineering,
                  label: 'HOD',
                  name: hodName!,
                ),

              SizedBox(height: 8),

              // View History button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: Icon(Icons.history, size: 16),
                  label: Text('View History'),
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ComplaintHistory(complaintId: complaint.id!),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String name;

  const UserInfoRow({
    required this.icon,
    required this.label,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}