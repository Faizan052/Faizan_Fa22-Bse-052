import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models.dart' as models;
import 'services.dart';
import 'widgets.dart';
import 'providers.dart';

// Splash Screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Provider.of<AuthProvider>(context, listen: false).loadCurrentUser();
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    await Future.delayed(const Duration(seconds: 2)); // Splash delay

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardScreen(user: user)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.report_problem, size: 80, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                'Smart Complaint System',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

// Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .login(_emailController.text, _passwordController.text, context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade200, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.report_problem, size: 60, color: Colors.blue),
                        const SizedBox(height: 16),
                        const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('LOGIN', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Dashboard Screen
class DashboardScreen extends StatelessWidget {
  final models.User user;

  const DashboardScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${user.role.toUpperCase()} Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      child: Icon(Icons.person, size: 40),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.email,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(
                        user.role.toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (user.role == 'student') ...[
              _buildDashboardButton(
                context,
                'Submit Complaint',
                Icons.add,
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SubmitComplaintScreen(user: user),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildDashboardButton(
                context,
                'My Complaints',
                Icons.list,
                    () {
                  Provider.of<ComplaintProvider>(context, listen: false)
                      .fetchComplaints(user.id, user.role);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ComplaintsScreen(user: user),
                    ),
                  );
                },
              ),
            ],
            if (user.role == 'batch_advisor' || user.role == 'hod') ...[
              _buildDashboardButton(
                context,
                'View Complaints',
                Icons.list,
                    () {
                  Provider.of<ComplaintProvider>(context, listen: false)
                      .fetchComplaints(user.id, user.role);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ComplaintsScreen(user: user),
                    ),
                  );
                },
              ),
            ],
            if (user.role == 'admin') ...[
              _buildDashboardButton(
                context,
                'Manage Departments',
                Icons.business,
                    () {
                  Provider.of<AdminProvider>(context, listen: false).fetchDepartments();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManageDepartmentsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildDashboardButton(
                context,
                'Manage Batches',
                Icons.group,
                    () {
                  Provider.of<AdminProvider>(context, listen: false).fetchBatches();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManageBatchesScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildDashboardButton(
                context,
                'Manage Users',
                Icons.people,
                    () {
                  Provider.of<AdminProvider>(context, listen: false).fetchUsers();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManageUsersScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildDashboardButton(
                context,
                'Upload Excel',
                Icons.upload,
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UploadExcelScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildDashboardButton(
                context,
                'Statistics',
                Icons.analytics,
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StatisticsScreen(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardButton(
      BuildContext context,
      String title,
      IconData icon,
      VoidCallback onPressed,
      ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.centerLeft,
      ),
    );
  }
}

// Submit Complaint Screen
class SubmitComplaintScreen extends StatefulWidget {
  final models.User user;

  const SubmitComplaintScreen({Key? key, required this.user}) : super(key: key);

  @override
  _SubmitComplaintScreenState createState() => _SubmitComplaintScreenState();
}

class _SubmitComplaintScreenState extends State<SubmitComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _videoUrlController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final batch = await Supabase.instance.client
          .from('batches')
          .select('advisor_id')
          .eq('id', widget.user.batchId!)
          .single();

      await DatabaseService().submitComplaint(
        title: _titleController.text,
        description: _descriptionController.text,
        imageUrl: _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
        videoUrl: _videoUrlController.text.isEmpty ? null : _videoUrlController.text,
        studentId: widget.user.id,
        batchId: widget.user.batchId!,
        advisorId: batch['advisor_id'],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint submitted successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting complaint: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Complaint'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL (Google Drive link)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.image),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _videoUrlController,
                decoration: const InputDecoration(
                  labelText: 'Video URL (Google Drive link)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.video_library),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitComplaint,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('SUBMIT COMPLAINT'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Complaints Screen
class ComplaintsScreen extends StatefulWidget {
  final models.User user;

  const ComplaintsScreen({Key? key, required this.user}) : super(key: key);

  @override
  _ComplaintsScreenState createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  final _searchController = TextEditingController();
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ComplaintProvider>(context, listen: false)
          .fetchComplaints(widget.user.id, widget.user.role);
    });
  }

  @override
  Widget build(BuildContext context) {
    final complaintProvider = Provider.of<ComplaintProvider>(context);

    List<models.Complaint> filteredComplaints = complaintProvider.complaints.where((complaint) {
      final matchesSearch = _searchController.text.isEmpty ||
          complaint.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          complaint.description.toLowerCase().contains(_searchController.text.toLowerCase());

      final matchesFilter = _filter == 'all' || complaint.status == _filter;

      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search complaints',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Filter:'),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _filter,
                  items: [
                    'all',
                    'Pending',
                    'In Progress',
                    'Escalated to HOD',
                    'Resolved',
                    'Rejected',
                  ].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value == 'all' ? 'All' : value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _filter = value!);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: complaintProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredComplaints.isEmpty
                ? const Center(child: Text('No complaints found'))
                : RefreshIndicator(
              onRefresh: () => Provider.of<ComplaintProvider>(context, listen: false)
                  .refreshComplaints(widget.user.id, widget.user.role),
              child: ListView.builder(
                itemCount: filteredComplaints.length,
                itemBuilder: (context, index) {
                  final complaint = filteredComplaints[index];
                  return ComplaintCard(
                    complaint: complaint,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ComplaintDetailsScreen(
                          complaint: complaint,
                          user: widget.user,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Complaint Details Screen
class ComplaintDetailsScreen extends StatefulWidget {
  final models.Complaint complaint;
  final models.User user;

  const ComplaintDetailsScreen({
    Key? key,
    required this.complaint,
    required this.user,
  }) : super(key: key);

  @override
  _ComplaintDetailsScreenState createState() => _ComplaintDetailsScreenState();
}

class _ComplaintDetailsScreenState extends State<ComplaintDetailsScreen> {
  final _commentController = TextEditingController();
  List<models.ComplaintHistory> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComplaintHistory();
  }

  Future<void> _loadComplaintHistory() async {
    try {
      final history = await DatabaseService().getComplaintHistory(widget.complaint.id);
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading history: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String status) async {
    try {
      await DatabaseService().updateComplaintStatus(
        widget.complaint.id,
        status,
        _commentController.text,
        widget.user.id,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated successfully')),
      );
      await _loadComplaintHistory();
      Provider.of<ComplaintProvider>(context, listen: false)
          .refreshComplaints(widget.user.id, widget.user.role);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  Future<void> _escalateToHod() async {
    try {
      final batch = await Supabase.instance.client
          .from('batches')
          .select('department_id')
          .eq('id', widget.complaint.batchId)
          .single();

      final department = await Supabase.instance.client
          .from('departments')
          .select('hod_id')
          .eq('id', batch['department_id'])
          .single();

      await DatabaseService().escalateComplaint(
        widget.complaint.id,
        department['hod_id'],
        _commentController.text,
        widget.user.id,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint escalated to HOD')),
      );
      await _loadComplaintHistory();
      Provider.of<ComplaintProvider>(context, listen: false)
          .refreshComplaints(widget.user.id, widget.user.role);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error escalating complaint: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.complaint.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    StatusChip(status: widget.complaint.status),
                    const SizedBox(height: 16),
                    Text(
                      widget.complaint.description,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    if (widget.complaint.imageUrl != null)
                      _buildMediaButton(
                        'View Image',
                        Icons.image,
                        widget.complaint.imageUrl!,
                      ),
                    if (widget.complaint.videoUrl != null)
                      _buildMediaButton(
                        'View Video',
                        Icons.video_library,
                        widget.complaint.videoUrl!,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if ((widget.user.role == 'batch_advisor' &&
                widget.complaint.status != 'Escalated to HOD') ||
                (widget.user.role == 'hod' &&
                    widget.complaint.status == 'Escalated to HOD'))
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.user.role == 'batch_advisor'
                            ? 'Batch Advisor Actions'
                            : 'HOD Actions',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          labelText: 'Add comment',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      if (widget.user.role == 'batch_advisor')
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _updateStatus('Resolved'),
                                icon: const Icon(Icons.check),
                                label: const Text('Resolve'),
                                style: ElevatedButton.styleFrom(
                                  primary: Colors.green,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _escalateToHod,
                                icon: const Icon(Icons.arrow_upward),
                                label: const Text('Escalate to HOD'),
                                style: ElevatedButton.styleFrom(
                                  primary: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (widget.user.role == 'hod')
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _updateStatus('Resolved'),
                                icon: const Icon(Icons.check),
                                label: const Text('Resolve'),
                                style: ElevatedButton.styleFrom(
                                  primary: Colors.green,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _updateStatus('Rejected'),
                                icon: const Icon(Icons.close),
                                label: const Text('Reject'),
                                style: ElevatedButton.styleFrom(
                                  primary: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Complaint Timeline',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_history.isEmpty)
                      const Text('No history available')
                    else
                      TimelineView(history: _history),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaButton(String text, IconData icon, String url) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ElevatedButton.icon(
        onPressed: () async {
          try {
            if (await canLaunch(url)) {
              await launch(url);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not launch URL')),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error opening URL: $e')),
            );
          }
        },
        icon: Icon(icon),
        label: Text(text),
      ),
    );
  }
}

// Manage Departments Screen
class ManageDepartmentsScreen extends StatefulWidget {
  const ManageDepartmentsScreen({Key? key}) : super(key: key);

  @override
  _ManageDepartmentsScreenState createState() => _ManageDepartmentsScreenState();
}

class _ManageDepartmentsScreenState extends State<ManageDepartmentsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hodIdController = TextEditingController();
  bool _isLoading = true;
  List<models.Department> _departments = [];
  List<models.User> _hods = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final departments = await DatabaseService().getDepartments();
      final users = await Supabase.instance.client
          .from('users')
          .select()
          .eq('role', 'hod')
          .then((response) => response.map((e) => models.User.fromJson(e)).toList());

      setState(() {
        _departments = departments;
        _hods = users;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addDepartment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await DatabaseService().addDepartment(
        _nameController.text,
        _hodIdController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Department added successfully')),
      );
      _nameController.clear();
      _hodIdController.clear();
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding department: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Departments'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Add New Department',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Department Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter department name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _hodIdController.text.isEmpty ? null : _hodIdController.text,
                        decoration: const InputDecoration(
                          labelText: 'Head of Department',
                          border: OutlineInputBorder(),
                        ),
                        items: _hods.map((hod) {
                          return DropdownMenuItem<String>(
                            value: hod.id,
                            child: Text('${hod.name} (${hod.email})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _hodIdController.text = value ?? '');
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select HOD';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _addDepartment,
                        child: const Text('ADD DEPARTMENT'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'All Departments',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            if (_departments.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No departments found'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _departments.length,
                itemBuilder: (context, index) {
                  final dept = _departments[index];
                  final hod = _hods.firstWhere(
                        (h) => h.id == dept.hodId,
                    orElse: () => models.User(
                      id: '',
                      email: '',
                      name: 'Unknown',
                      role: '',
                    ),
                  );
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(dept.name),
                      subtitle: Text('HOD: ${hod.name}'),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// Manage Batches Screen
class ManageBatchesScreen extends StatefulWidget {
  const ManageBatchesScreen({Key? key}) : super(key: key);

  @override
  _ManageBatchesScreenState createState() => _ManageBatchesScreenState();
}

class _ManageBatchesScreenState extends State<ManageBatchesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedDepartmentId;
  String? _selectedAdvisorId;
  bool _isLoading = true;
  List<models.Batch> _batches = [];
  List<models.Department> _departments = [];
  List<models.User> _advisors = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final batches = await DatabaseService().getBatches();
      final departments = await DatabaseService().getDepartments();
      final advisors = await Supabase.instance.client
          .from('users')
          .select()
          .eq('role', 'batch_advisor')
          .then((response) => response.map((e) => models.User.fromJson(e)).toList());

      setState(() {
        _batches = batches;
        _departments = departments;
        _advisors = advisors;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addBatch() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDepartmentId == null || _selectedAdvisorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select department and advisor')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await DatabaseService().addBatch(
        _nameController.text,
        _selectedDepartmentId!,
        _selectedAdvisorId!,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Batch added successfully')),
      );
      _nameController.clear();
      setState(() {
        _selectedDepartmentId = null;
        _selectedAdvisorId = null;
      });
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding batch: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Batches'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Add New Batch',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Batch Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter batch name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedDepartmentId,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          border: OutlineInputBorder(),
                        ),
                        items: _departments.map((dept) {
                          return DropdownMenuItem<String>(
                            value: dept.id,
                            child: Text(dept.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedDepartmentId = value);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select department';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedAdvisorId,
                        decoration: const InputDecoration(
                          labelText: 'Batch Advisor',
                          border: OutlineInputBorder(),
                        ),
                        items: _advisors.map((advisor) {
                          return DropdownMenuItem<String>(
                            value: advisor.id,
                            child: Text('${advisor.name} (${advisor.email})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedAdvisorId = value);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select advisor';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _addBatch,
                        child: const Text('ADD BATCH'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'All Batches',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            if (_batches.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No batches found'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _batches.length,
                itemBuilder: (context, index) {
                  final batch = _batches[index];
                  final dept = _departments.firstWhere(
                        (d) => d.id == batch.departmentId,
                    orElse: () => models.Department(
                      id: '',
                      name: 'Unknown',
                      hodId: '',
                    ),
                  );
                  final advisor = _advisors.firstWhere(
                        (a) => a.id == batch.advisorId,
                    orElse: () => models.User(
                      id: '',
                      email: '',
                      name: 'Unknown',
                      role: '',
                    ),
                  );
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(batch.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Department: ${dept.name}'),
                          Text('Advisor: ${advisor.name}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// Manage Users Screen
class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({Key? key}) : super(key: key);

  @override
  _ManageUsersScreenState createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  bool _isLoading = true;
  List<models.User> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await Supabase.instance.client
          .from('users')
          .select()
          .then((response) => response.map((e) => models.User.fromJson(e)).toList());
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading users: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadUsers,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _users.length,
          itemBuilder: (context, index) {
            final user = _users[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(user.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.email),
                    Text('Role: ${user.role.toUpperCase()}'),
                  ],
                ),
                trailing: Chip(
                  label: Text(user.role.toUpperCase()),
                  backgroundColor: Colors.blue,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Upload Excel Screen
class UploadExcelScreen extends StatefulWidget {
  const UploadExcelScreen({Key? key}) : super(key: key);

  @override
  _UploadExcelScreenState createState() => _UploadExcelScreenState();
}

class _UploadExcelScreenState extends State<UploadExcelScreen> {
  bool _isLoading = false;

  Future<void> _uploadExcel() async {
    // In a real app, you would use file_picker to select a file
    // For this example, we'll simulate a successful upload
    setState(() => _isLoading = true);
    try {
      await Future.delayed(const Duration(seconds: 2)); // Simulate upload
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Users uploaded successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading file: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Excel'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Upload Users via Excel',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Format: Student Name | Email | Batch | Department | Advisor Email',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _uploadExcel,
                      icon: const Icon(Icons.upload),
                      label: const Text('SELECT EXCEL FILE'),
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Sample Excel Format',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Ali Raza,ali@example.com,CS-2022,CS,advisor@example.com\n'
                          'Sara Khan,sara@example.com,CS-2023,CS,advisor@example.com\n'
                          'Ahmed Khan,ahmed@example.com,CS-2022,CS,advisor@example.com',
                      style: TextStyle(fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Statistics Screen
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = true;
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final response = await Supabase.instance.client
          .from('complaints')
          .select('status')
          .then((data) {
        final stats = <String, int>{};
        for (var item in data) {
          stats[item['status']] = (stats[item['status']] ?? 0) + 1;
        }
        return stats;
      });
      setState(() {
        _stats = response;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading stats: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Complaint Statistics',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_stats.isEmpty)
                        const Text('No data available')
                      else
                        Column(
                          children: _stats.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(entry.key),
                                  ),
                                  Chip(
                                    label: Text(entry.value.toString()),
                                    backgroundColor: Colors.blue,
                                    labelStyle: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}