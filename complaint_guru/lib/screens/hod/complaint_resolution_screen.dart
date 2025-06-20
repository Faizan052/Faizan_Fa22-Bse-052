import 'package:flutter/material.dart';
import '../models/complaint.dart';
import '../services/database_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/timeline_view.dart';
import '../utils/theme.dart';
import 'package:provider/provider.dart';

class ComplaintResolutionScreen extends StatefulWidget {
  final Complaint complaint;

  const ComplaintResolutionScreen({Key? key, required this.complaint}) : super(key: key);

  @override
  _ComplaintResolutionScreenState createState() => _ComplaintResolutionScreenState();
}

class _ComplaintResolutionScreenState extends State<ComplaintResolutionScreen> {
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
      final history = await DatabaseService().getComplaintHistory(widget.complaint.id);
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load history: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resolveComplaint() async {
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user!;
      await DatabaseService().updateComplaintStatus(
        widget.complaint.id,
        'Resolved',
        _commentController.text,
        user.id,
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to resolve complaint: $e')),
      );
    }
  }

  Future<void> _rejectComplaint() async {
    try {
      final user = Provider.of(context, listen: false).userId;
      await _databaseService().updateComplaintStatus(
        widget.complaintId.id,
        'Rejected',
        _commentController.text,
        user.id,
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject complaint: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complaint Resolution')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: AppTheme.glassDecoration(),
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.complaint.title,
                    style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.complaint.description,
                    style: TextStyle(color: Colors.white.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      labelText: 'Add Comment',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  CustomButton(text: 'Resolve', onPressed: _resolveComplaint),
                  const SizedBox(height: 10),
                  CustomButton(text: 'Reject', onPressed: _rejectComplaint),
                  const SizedBox(height: 20),
                  const Text(
                    'Timeline',
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  TimelineView(history: _history),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}