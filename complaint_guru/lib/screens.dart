import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models.dart' as models;
import 'services.dart';
import 'widgets.dart';
import 'providers.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('SplashScreen: Checking user session');
      await Provider.of<AuthProvider>(context, listen: false).loadCurrentUser();
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        print('SplashScreen: User found, navigating to Dashboard');
        NotificationService().setupRealtimeNotifications(user.id);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardScreen(user: user)),
        );
      } else {
        print('SplashScreen: No user, navigating to Login');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blue.shade300, Colors.blue.shade700]),
        ),
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
    );
  }
}

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

  void _login() async {
    if (!_formKey.currentState!.validate()) {
      print('LoginScreen: Form validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in valid email and password')),
      );
      return;
    }
    print('LoginScreen: Form validated successfully');
    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .login(_emailController.text, _passwordController.text, context);
      print('LoginScreen: Login attempt completed');
    } catch (e) {
      print('LoginScreen: Login error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
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
          gradient: LinearGradient(colors: [Colors.blue.shade100, Colors.blue.shade300]),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Smart Complaint System',
                  style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Email is required';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Invalid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Password is required';
                    if (value.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : CustomButton(text: 'Login', onPressed: _login),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final models.User user;

  const DashboardScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final complaintProvider = Provider.of<ComplaintProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('${user.role.capitalize()} Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).signOut();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blue.shade100, Colors.blue.shade300]),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _glassDecoration(),
                child: Text('Welcome, ${user.name}', style: const TextStyle(fontSize: 20, color: Colors.white)),
              ),
              const SizedBox(height: 20),
              if (user.role == 'student' && user.batchId != null) ...[
                CustomButton(
                  text: 'Submit Complaint',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SubmitComplaintScreen(user: user)),
                  ),
                ),
                const SizedBox(height: 10),
                CustomButton(
                  text: 'View Complaints',
                  onPressed: () {
                    complaintProvider.fetchComplaints(user.id, user.role);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ComplaintsScreen(user: user)));
                  },
                ),
              ],
              if (user.role == 'batch_advisor' || user.role == 'hod') ...[
                CustomButton(
                  text: 'View Complaints',
                  onPressed: () {
                    complaintProvider.fetchComplaints(user.id, user.role);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ComplaintsScreen(user: user)));
                  },
                ),
              ],
              if (user.role == 'admin') ...[
                CustomButton(
                  text: 'Manage Departments',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ManageDepartmentsScreen()),
                  ),
                ),
                const SizedBox(height: 10),
                CustomButton(
                  text: 'Manage Batches',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ManageBatchesScreen()),
                  ),
                ),
                const SizedBox(height: 10),
                CustomButton(
                  text: 'Add Users (Excel)',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
                  ),
                ),
                const SizedBox(height: 10),
                CustomButton(
                  text: 'Add Student',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddStudentScreen()),
                  ),
                ),
                const SizedBox(height: 10),
                CustomButton(
                  text: 'View Stats',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ComplaintStatsScreen()),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _glassDecoration() => BoxDecoration(
    color: Colors.white.withOpacity(0.1),
    borderRadius: BorderRadius.circular(15),
    border: Border.all(color: Colors.white.withOpacity(0.2)),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 5)],
  );
}

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      print('SubmitComplaintScreen: Form validation failed');
      return;
    }
    if (widget.user.role != 'student' || widget.user.batchId == null) {
      print('SubmitComplaintScreen: Invalid user role or batchId');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only students with a valid batch can submit complaints')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final batch = await Supabase.instance.client.from('batches').select().eq('id', widget.user.batchId!).single();
      if (batch == null) {
        throw 'Batch not found';
      }
      await DatabaseService().submitComplaint(
        title: _titleController.text,
        description: _descriptionController.text,
        imageUrl: _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
        videoUrl: _videoUrlController.text.isEmpty ? null : _videoUrlController.text,
        studentId: widget.user.id,
        batchId: widget.user.batchId!,
        advisorId: batch['advisor_id'] ?? '',
      );
      print('SubmitComplaintScreen: Complaint submitted');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint submitted')));
      Navigator.pop(context);
    } catch (e) {
      print('SubmitComplaintScreen: Submit error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Complaint')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blue.shade100, Colors.blue.shade300]),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Title is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Description is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(labelText: 'Image URL (Google Drive, optional)'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _videoUrlController,
                    decoration: const InputDecoration(labelText: 'Video URL (Google Drive, optional)'),
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : CustomButton(text: 'Submit', onPressed: _submit),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ComplaintsScreen extends StatelessWidget {
  final models.User user;

  const ComplaintsScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final complaintProvider = Provider.of<ComplaintProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Complaints')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blue.shade100, Colors.blue.shade300]),
        ),
        child: FutureBuilder(
          future: complaintProvider.fetchComplaints(user.id, user.role),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              print('ComplaintsScreen: Fetch error: ${snapshot.error}');
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
            }
            final complaints = complaintProvider.complaints;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: complaints.isEmpty
                  ? const Center(child: Text('No complaints', style: TextStyle(color: Colors.white)))
                  : ListView.builder(
                itemCount: complaints.length,
                itemBuilder: (context, index) {
                  final complaint = complaints[index];
                  return ComplaintCard(
                    complaint: complaint,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ComplaintDetailsScreen(complaint: complaint, user: user),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class ComplaintDetailsScreen extends StatefulWidget {
  final models.Complaint complaint;
  final models.User user;

  const ComplaintDetailsScreen({Key? key, required this.complaint, required this.user}) : super(key: key);

  @override
  _ComplaintDetailsScreenState createState() => _ComplaintDetailsScreenState();
}

class _ComplaintDetailsScreenState extends State<ComplaintDetailsScreen> {
  final _commentController = TextEditingController();
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      _history = await DatabaseService().getComplaintHistory(widget.complaint.id);
      setState(() => _isLoading = false);
    } catch (e) {
      print('ComplaintDetailsScreen: Fetch history error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String status) async {
    try {
      await DatabaseService()
          .updateComplaintStatus(widget.complaint.id, status, _commentController.text, widget.user.id);
      print('ComplaintDetailsScreen: Status updated to $status');
      Navigator.pop(context);
    } catch (e) {
      print('ComplaintDetailsScreen: Update status error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _escalate() async {
    try {
      final batch = await Supabase.instance.client
          .from('batches')
          .select('department_id')
          .eq('id', widget.complaint.batchId)
          .single();
      final department =
      await Supabase.instance.client.from('departments').select('hod_id').eq('id', batch['department_id']).single();
      await DatabaseService()
          .escalateComplaint(widget.complaint.id, department['hod_id'], _commentController.text, widget.user.id);
      print('ComplaintDetailsScreen: Complaint escalated');
      Navigator.pop(context);
    } catch (e) {
      print('ComplaintDetailsScreen: Escalate error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complaint Details')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blue.shade100, Colors.blue.shade300]),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.complaint.title,
                  style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                StatusChip(status: widget.complaint.status),
                const SizedBox(height: 10),
                Text(widget.complaint.description, style: TextStyle(color: Colors.white.withOpacity(0.8))),
                if (widget.complaint.imageUrl != null && widget.complaint.imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final url = Uri.parse(widget.complaint.imageUrl!);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid URL')));
                      }
                    },
                    child: Text(
                      'View Image',
                      style: TextStyle(color: Colors.blue.shade300, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
                if (widget.complaint.videoUrl != null && widget.complaint.videoUrl!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final url = Uri.parse(widget.complaint.videoUrl!);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid URL')));
                      }
                    },
                    child: Text(
                      'View Video',
                      style: TextStyle(color: Colors.blue.shade300, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (widget.user.role == 'batch_advisor' && widget.complaint.status != 'Escalated to HOD') ...[
                  TextFormField(
                    controller: _commentController,
                    decoration: const InputDecoration(labelText: 'Add Comment'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  CustomButton(text: 'Resolve', onPressed: () => _updateStatus('Resolved')),
                  const SizedBox(height: 10),
                  CustomButton(text: 'Escalate to HOD', onPressed: _escalate),
                ],
                if (widget.user.role == 'hod' && widget.complaint.status == 'Escalated to HOD') ...[
                  TextFormField(
                    controller: _commentController,
                    decoration: const InputDecoration(labelText: 'Add Comment'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  CustomButton(text: 'Resolve', onPressed: () => _updateStatus('Resolved')),
                  const SizedBox(height: 10),
                  CustomButton(text: 'Reject', onPressed: () => _updateStatus('Rejected')),
                ],
                const SizedBox(height: 20),
                const Text('Timeline',
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                TimelineView(history: _history),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ManageDepartmentsScreen extends StatefulWidget {
  const ManageDepartmentsScreen({Key? key}) : super(key: key);

  @override
  _ManageDepartmentsScreenState createState() => _ManageDepartmentsScreenState();
}

class _ManageDepartmentsScreenState extends State<ManageDepartmentsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hodIdController = TextEditingController();
  List<models.Department> _departments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  Future<void> _fetchDepartments() async {
    try {
      _departments = await DatabaseService().getDepartments();
      setState(() => _isLoading = false);
    } catch (e) {
      print('ManageDepartmentsScreen: Fetch departments error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addDepartment() async {
    if (!_formKey.currentState!.validate()) {
      print('ManageDepartmentsScreen: Form validation failed');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await DatabaseService().addDepartment(_nameController.text, _hodIdController.text);
      _nameController.clear();
      _hodIdController.clear();
      await _fetchDepartments();
      print('ManageDepartmentsScreen: Department added');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Department added')));
    } catch (e) {
      print('ManageDepartmentsScreen: Add department error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Departments')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blue.shade100, Colors.blue.shade300]),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _glassDecoration(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Department Name'),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Department Name is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _hodIdController,
                        decoration: const InputDecoration(labelText: 'HOD User ID'),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'HOD User ID is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : CustomButton(text: 'Add Department', onPressed: _addDepartment),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : Expanded(
                child: ListView.builder(
                  itemCount: _departments.length,
                  itemBuilder: (context, index) {
                    final dept = _departments[index];
                    return ListTile(
                      title: Text(dept.name, style: const TextStyle(color: Colors.white)),
                      subtitle: Text('HOD ID: ${dept.hodId}',
                          style: TextStyle(color: Colors.white.withOpacity(0.8))),
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

  BoxDecoration _glassDecoration() => BoxDecoration(
    color: Colors.white.withOpacity(0.1),
    borderRadius: BorderRadius.circular(15),
    border: Border.all(color: Colors.white.withOpacity(0.2)),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 5)],
  );
}

class ManageBatchesScreen extends StatefulWidget {
  const ManageBatchesScreen({Key? key}) : super(key: key);

  @override
  _ManageBatchesScreenState createState() => _ManageBatchesScreenState();
}

class _ManageBatchesScreenState extends State<ManageBatchesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _departmentIdController = TextEditingController();
  final _advisorIdController = TextEditingController();
  List<models.Batch> _batches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBatches();
  }

  Future<void> _fetchBatches() async {
    try {
      _batches = await DatabaseService().getBatches();
      setState(() => _isLoading = false);
    } catch (e) {
      print('ManageBatchesScreen: Fetch batches error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addBatch() async {
    if (!_formKey.currentState!.validate()) {
      print('ManageBatchesScreen: Form validation failed');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await DatabaseService()
          .addBatch(_nameController.text, _departmentIdController.text, _advisorIdController.text);
      _nameController.clear();
      _departmentIdController.clear();
      _advisorIdController.clear();
      await _fetchBatches();
      print('ManageBatchesScreen: Batch added');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batch added')));
    } catch (e) {
      print('ManageBatchesScreen: Add batch error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Batches')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blue.shade100, Colors.blue.shade300]),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _glassDecoration(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Batch Name'),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Batch Name is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _departmentIdController,
                        decoration: const InputDecoration(labelText: 'Department ID'),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Department ID is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _advisorIdController,
                        decoration: const InputDecoration(labelText: 'Advisor ID'),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Advisor ID is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : CustomButton(text: 'Add Batch', onPressed: _addBatch),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : Expanded(
                child: ListView.builder(
                  itemCount: _batches.length,
                  itemBuilder: (context, index) {
                    final batch = _batches[index];
                    return ListTile(
                      title: Text(batch.name, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(
                        'Dept ID: ${batch.departmentId}\nAdvisor ID: ${batch.advisorId}',
                        style: TextStyle(color: Colors.white.withOpacity(0.8)),
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

  BoxDecoration _glassDecoration() => BoxDecoration(
    color: Colors.white.withOpacity(0.1),
    borderRadius: BorderRadius.circular(15),
    border: Border.all(color: Colors.white.withOpacity(0.2)),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 5)],
  );
}

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blue.shade100, Colors.blue.shade300]),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Upload Users via Excel',
                style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                'Format: Student Name | Email | Batch | Department | Advisor Email',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Upload Excel',
                onPressed: () async {
                  try {
                    await ExcelService().uploadUsersFromExcel();
                    print('ManageUsersScreen: Users uploaded');
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Users uploaded')));
                  } catch (e) {
                    print('ManageUsersScreen: Upload users error: $e');
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({Key? key}) : super(key: key);

  @override
  _AddStudentScreenState createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedBatchId;
  String? _selectedDepartmentId;
  List<models.Batch> _batches = [];
  List<models.Department> _departments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      print('AddStudentScreen: Fetching batches and departments');
      final batches = await DatabaseService().getBatches();
      final departments = await DatabaseService().getDepartments();
      setState(() {
        _batches = batches;
        _departments = departments;
        _isLoading = false;
      });
      print('AddStudentScreen: Fetched ${batches.length} batches, ${departments.length} departments');
    } catch (e) {
      print('AddStudentScreen: Fetch data error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addStudent() async {
    if (!_formKey.currentState!.validate()) {
      print('AddStudentScreen: Form validation failed');
      return;
    }
    if (_selectedBatchId == null || _selectedDepartmentId == null) {
      print('AddStudentScreen: Batch or department not selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a batch and department')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await AuthService().addUser(
        email: _emailController.text,
        name: _nameController.text,
        role: 'student',
        batchId: _selectedBatchId,
        departmentId: _selectedDepartmentId,
      );
      print('AddStudentScreen: Student added');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student added')));
      Navigator.pop(context);
    } catch (e) {
      print('AddStudentScreen: Add student error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Student')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blue.shade100, Colors.blue.shade300]),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Student Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Student Name is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Email is required';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Invalid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Password is required';
                      if (value.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Batch'),
                    value: _selectedBatchId,
                    items: _batches
                        .map((batch) => DropdownMenuItem(
                      value: batch.id,
                      child: Text(batch.name),
                    ))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedBatchId = value),
                    validator: (value) => value == null ? 'Please select a batch' : null,
                    dropdownColor: Colors.blue.shade700,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Department'),
                    value: _selectedDepartmentId,
                    items: _departments
                        .map((dept) => DropdownMenuItem(
                      value: dept.id,
                      child: Text(dept.name),
                    ))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedDepartmentId = value),
                    validator: (value) => value == null ? 'Please select a department' : null,
                    dropdownColor: Colors.blue.shade700,
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : CustomButton(text: 'Add Student', onPressed: _addStudent),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ComplaintStatsScreen extends StatelessWidget {
  const ComplaintStatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complaint Stats')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blue.shade100, Colors.blue.shade300]),
        ),
        child: FutureBuilder<List<dynamic>>(
          future: Supabase.instance.client.from('complaints').select('status').then((response) {
            final stats = <String, int>{};
            for (var item in response) {
              stats[item['status']] = (stats[item['status']] ?? 0) + 1;
            }
            return stats.entries.map((e) => {'status': e.key, 'count': e.value}).toList();
          }),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              print('ComplaintStatsScreen: Fetch stats error: ${snapshot.error}');
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
            }
            final stats = snapshot.data ?? [];
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: stats.length,
                itemBuilder: (context, index) {
                  final stat = stats[index];
                  return ListTile(
                    title: Text(stat['status'], style: const TextStyle(color: Colors.white)),
                    trailing: Text(stat['count'].toString(), style: const TextStyle(color: Colors.white)),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() => isEmpty ? this : this[0].toUpperCase() + substring(1);
}