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

class _StudentDashboardState extends State<StudentDashboard> with SingleTickerProviderStateMixin {
  String _selectedStatus = 'All';
  static const List<String> _statusOptions = [
    'All',
    'Pending',
    'Resolved',
    'Rejected',
    'Escalated to HOD',
  ];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );
    _animationController.forward();

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      Provider.of<ComplaintProvider>(context, listen: false)
          .fetchComplaints(user.id, 'batch_advisor');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            "Student Dashboard",
            key: ValueKey<String>(isDarkMode ? "dark" : "light"),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(1, 1),
                ),
              ],
            ),
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
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.logout,
                key: ValueKey<String>(isDarkMode ? "dark" : "light"),
                color: Colors.white,
              ),
            ),
            tooltip: 'Logout',
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _scaleAnimation,
        child: FloatingActionButton(
          backgroundColor: primaryColor,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
          onPressed: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => ComplaintForm(),
              transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
            ),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [
                  const Color(0xFF0F2027),
                  const Color(0xFF203A43),
                  const Color(0xFF2C5364),
                ]
                    : [
                  const Color(0xFF4F8FFF),
                  const Color(0xFF1CB5E0),
                  const Color(0xFF0F2027),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.1, 0.5, 0.9],
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
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 100, 16, 100),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 100,
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
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
                                        color: const Color(0xFF4285F4),
                                        animationDelay: 0,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: StatCard(
                                        icon: Icons.check_circle,
                                        value: resolved,
                                        label: 'Resolved',
                                        color: const Color(0xFF0F9D58),
                                        animationDelay: 100,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: StatCard(
                                        icon: Icons.hourglass_bottom,
                                        value: pending,
                                        label: 'Pending',
                                        color: const Color(0xFFF4B400),
                                        animationDelay: 200,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: StatCard(
                                        icon: Icons.cancel,
                                        value: rejected,
                                        label: 'Rejected',
                                        color: const Color(0xFFDB4437),
                                        animationDelay: 300,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          else
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 4,
                              childAspectRatio: 1.4,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              children: [
                                StatCard(
                                  icon: Icons.list_alt,
                                  value: total,
                                  label: 'Total',
                                  color: const Color(0xFF4285F4),
                                  animationDelay: 0,
                                ),
                                StatCard(
                                  icon: Icons.check_circle,
                                  value: resolved,
                                  label: 'Resolved',
                                  color: const Color(0xFF0F9D58),
                                  animationDelay: 100,
                                ),
                                StatCard(
                                  icon: Icons.hourglass_bottom,
                                  value: pending,
                                  label: 'Pending',
                                  color: const Color(0xFFF4B400),
                                  animationDelay: 200,
                                ),
                                StatCard(
                                  icon: Icons.cancel,
                                  value: rejected,
                                  label: 'Rejected',
                                  color: const Color(0xFFDB4437),
                                  animationDelay: 300,
                                ),
                              ],
                            ),

                          const SizedBox(height: 24),

                          // Filter Section
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.filter_alt, color: primaryColor),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
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
                                        underline: const SizedBox(),
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
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Complaints List Header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                Icon(Icons.report_problem, color: Colors.white, size: 26),
                                const SizedBox(width: 10),
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
                                        offset: const Offset(1, 1),
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
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.inbox, size: 48, color: Colors.white.withOpacity(0.5)),
                                      const SizedBox(height: 16),
                                      Text(
                                        _selectedStatus == 'All'
                                            ? "You haven't filed any complaints yet"
                                            : "No ${_selectedStatus.toLowerCase()} complaints",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
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
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
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
                    ),
                  ),
                );
              },
            ),
          );
        },
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

class StatCard extends StatefulWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;
  final int animationDelay;

  const StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.animationDelay,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scale = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: FadeTransition(
        opacity: _opacity,
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Theme.of(context).cardColor,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {},
            splashColor: widget.color.withOpacity(0.1),
            highlightColor: widget.color.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.color.withOpacity(0.2),
                          widget.color.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, size: 24, color: widget.color),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.value.toString(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: widget.color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => ComplaintHistory(complaintId: complaint.id!),
              transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
            ),
          );
        },
        splashColor: primaryColor.withOpacity(0.1),
        highlightColor: primaryColor.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                      style: const TextStyle(
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
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

              const SizedBox(height: 12),

              // Resolution status if applicable
              if (isResolved || isRejected)
                Container(
                  padding: const EdgeInsets.all(10),
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
                      const SizedBox(width: 8),
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

              const SizedBox(height: 12),

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

              const SizedBox(height: 8),

              // View History button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text('View History'),
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => ComplaintHistory(complaintId: complaint.id!),
                        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}