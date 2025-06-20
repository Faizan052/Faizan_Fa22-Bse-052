import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/complaint.dart';
import '../services/database_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/timeline_view.dart';
import '../utils/theme.dart';

class ComplaintActionScreen extends StatefulWidget {
  final Complaint complaint;

  const ComplaintActionScreen({Key? key, required this.complaint}) : super(key: key);

  @override
  _ComplaintActionScreenState createState() => _ComplaintActionScreenState();
}

class _ComplaintActionScreenState extends State<ComplaintActionScreen> {
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

  Future<void> _escalateComplaint() async {
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user!;
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
        user.id,
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to escalate complaint: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complaint Action')),
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
                        fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
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
                  CustomButton(text: 'Escalate to HOD', onPressed: _escalateComplaint),
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