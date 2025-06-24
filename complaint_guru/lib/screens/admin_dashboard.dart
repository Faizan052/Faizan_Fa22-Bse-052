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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Admin Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
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
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)]
                : [Color(0xFF4F8FFF), Color(0xFF1CB5E0), Color(0xFF0F2027)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Consumer<ComplaintProvider>(
          builder: (context, provider, _) {
            final complaints = provider.complaints.where((c) {
              if (_selectedStatus == 'All') return true;
              if (_selectedStatus == 'Pending') return c.status == 'Submitted' || c.status == 'In Progress';
              return c.status == _selectedStatus;
            }).toList();

            // Statistics data
            final total = provider.complaints.length;
            final resolved = provider.complaints.where((c) => c.status == 'Resolved').length;
            final pending = provider.complaints.where((c) => c.status == 'Submitted' || c.status == 'In Progress').length;
            final escalated = provider.complaints.where((c) => c.status == 'Escalated to HOD').length;
            final rejected = provider.complaints.where((c) => c.status == 'Rejected').length;

            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 100, 16, 32),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 100,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Cards Grid - Responsive layout
                        if (isMobile)
                          Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: _StatCard(
                                    icon: Icons.list_alt,
                                    value: total,
                                    label: 'Total',
                                    color: Color(0xFF4285F4),
                                  )),
                                  SizedBox(width: 12),
                                  Expanded(child: _StatCard(
                                    icon: Icons.check_circle,
                                    value: resolved,
                                    label: 'Resolved',
                                    color: Color(0xFF0F9D58),
                                  )),
                                ],
                              ),
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _StatCard(
                                    icon: Icons.hourglass_bottom,
                                    value: pending,
                                    label: 'Pending',
                                    color: Color(0xFFF4B400),
                                  )),
                                  SizedBox(width: 12),
                                  Expanded(child: _StatCard(
                                    icon: Icons.trending_up,
                                    value: escalated,
                                    label: 'Escalated',
                                    color: Color(0xFFDB4437),
                                  )),
                                ],
                              ),
                              SizedBox(height: 12),
                              _StatCard(
                                icon: Icons.cancel,
                                value: rejected,
                                label: 'Rejected',
                                color: Color(0xFF9E9E9E),
                                isFullWidth: true,
                              ),
                            ],
                          )
                        else
                          GridView.count(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            crossAxisCount: 5,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            children: [
                              _StatCard(
                                icon: Icons.list_alt,
                                value: total,
                                label: 'Total',
                                color: Color(0xFF4285F4),
                              ),
                              _StatCard(
                                icon: Icons.check_circle,
                                value: resolved,
                                label: 'Resolved',
                                color: Color(0xFF0F9D58),
                              ),
                              _StatCard(
                                icon: Icons.hourglass_bottom,
                                value: pending,
                                label: 'Pending',
                                color: Color(0xFFF4B400),
                              ),
                              _StatCard(
                                icon: Icons.trending_up,
                                value: escalated,
                                label: 'Escalated',
                                color: Color(0xFFDB4437),
                              ),
                              _StatCard(
                                icon: Icons.cancel,
                                value: rejected,
                                label: 'Rejected',
                                color: Color(0xFF9E9E9E),
                              ),
                            ],
                          ),

                        SizedBox(height: 24),

                        // Excel Upload Button
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 400),
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.upload_file, size: 22),
                              label: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  "Upload Students via Excel",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF1976D2),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                                shadowColor: Colors.black26,
                                minimumSize: Size(double.infinity, 50),
                              ),
                              onPressed: () async {
                                final result = await FilePicker.platform.pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: ['xlsx', 'csv'],
                                );
                                if (result != null) {
                                  final file = result.files.single;
                                  final message = await excelService.uploadStudentExcel(file);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(message),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ),

                        SizedBox(height: 28),

                        // Filter Section
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 400),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey[800] : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: Offset(0, 2)),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.filter_alt, color: Color(0xFF4F8FFF)),
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
                                        ),
                                      ),
                                    )).toList(),
                                    onChanged: (val) => setState(() => _selectedStatus = val!),
                                    underline: SizedBox(),
                                    isExpanded: true,
                                    dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                                    icon: Icon(Icons.arrow_drop_down, color: Color(0xFF4F8FFF)),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 32),

                        // Complaints List Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              Icon(Icons.report_problem, color: Colors.white, size: 26),
                              SizedBox(width: 10),
                              Text(
                                "Complaints List",
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
                        provider.isLoading
                            ? Center(child: CircularProgressIndicator(color: Colors.white))
                            : complaints.isEmpty
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
                          itemCount: complaints.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ComplaintCard(
                              complaint: complaints[i],
                              isDarkMode: isDarkMode,
                            ),
                          ),
                        ),

                        SizedBox(height: 36),

                        // Management Section Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              Icon(Icons.settings, color: Colors.white, size: 26),
                              SizedBox(width: 10),
                              Text(
                                "Management",
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

                        // Management Options - Responsive grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          crossAxisCount: isMobile ? 1 : 2,
                          childAspectRatio: isMobile ? 1.8 : 2.2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          children: [
                            _ManagementOptionCard(
                              icon: Icons.apartment,
                              title: 'Departments',
                              subtitle: 'Add/Edit/Delete Departments',
                              color: Color(0xFF4285F4),
                              route: '/admin/department-management',
                            ),
                            _ManagementOptionCard(
                              icon: Icons.group,
                              title: 'Batches',
                              subtitle: 'Assign Advisors to Batches',
                              color: Color(0xFF0F9D58),
                              route: '/admin/batch-management',
                            ),

                            _ManagementOptionCard(
                              icon: Icons.people,
                              title: 'Users',
                              subtitle: 'Manage User Accounts',
                              color: Color(0xFFDB4437),
                              route: '/admin/user-management',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;
  final bool isFullWidth;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Theme.of(context).cardColor,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
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

// Keep the _ComplaintCard, _UserInfoRow, and _ManagementOptionCard classes the same as in previous code

class _ComplaintCard extends StatelessWidget {
  final dynamic complaint;
  final bool isDarkMode;

  const _ComplaintCard({
    required this.complaint,
    required this.isDarkMode,
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
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          childrenPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: _getStatusColor(complaint.status).withOpacity(0.1),
            child: Icon(Icons.report, color: _getStatusColor(complaint.status)),
          ),
          title: Text(
            complaint.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.black87 : Colors.black87,
              fontSize: 16,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(complaint.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    complaint.status,
                    style: TextStyle(
                      color: _getStatusColor(complaint.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          trailing: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _getStatusColor(complaint.status),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _UserInfoRow(
                    icon: Icons.person,
                    label: 'Student',
                    id: complaint.studentId,
                  ),
                  _UserInfoRow(
                    icon: Icons.school,
                    label: 'Advisor',
                    id: complaint.advisorId,
                  ),
                  if (complaint.hodId != null && complaint.hodId!.isNotEmpty)
                    _UserInfoRow(
                      icon: Icons.engineering,
                      label: 'HOD',
                      id: complaint.hodId!,
                    ),
                  SizedBox(height: 16),
                  if (complaint.status == 'Resolved' || complaint.status == 'Rejected')
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getStatusColor(complaint.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            complaint.status == 'Resolved'
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: _getStatusColor(complaint.status),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              complaint.status == 'Resolved'
                                  ? 'This complaint has been resolved'
                                  : 'This complaint has been rejected',
                              style: TextStyle(
                                color: _getStatusColor(complaint.status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.history, size: 20),
                      label: Text('View History'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getStatusColor(complaint.status).withOpacity(0.1),
                        foregroundColor: _getStatusColor(complaint.status),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ComplaintHistory(complaintId: complaint.id!),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String id;

  const _UserInfoRow({
    required this.icon,
    required this.label,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 2),
                FutureBuilder<String>(
                  future: UserLookupService.getUserName(id),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? id,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagementOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String route;

  const _ManagementOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(context, route),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
                ),
              ),
              Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  Icons.arrow_forward,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}