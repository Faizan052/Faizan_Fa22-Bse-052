import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/complaint.dart';
import '../services/database_service.dart';
import '../widgets/status_chip.dart';
import '../widgets/timeline_view.dart';
import '../utils/theme.dart';

class ComplaintDetailsScreen extends StatefulWidget {
  final Complaint complaint;

  const ComplaintDetailsScreen({Key? key, required this.complaint}) : super(key: key);

  @override
  _ComplaintDetailsScreenState createState() => _ComplaintDetailsScreenState();
}

class _ComplaintDetailsScreenState extends State<ComplaintDetailsScreen> {
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

  Future<void> _launchUrl(String? url) async {
    if (url != null && await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complaint Details')),
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
                  StatusChip(status: widget.complaint.status),
                  const SizedBox(height: 10),
                  Text(
                    widget.complaint.description,
                    style: TextStyle(color: Colors.white.withOpacity(0.8)),
                  ),
                  if (widget.complaint.imageUrl != null) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _launchUrl(widget.complaint.imageUrl),
                      child: Text(
                        'View Image',
                        style: TextStyle(color: Colors.blue.shade300, decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                  if (widget.complaint.videoUrl != null) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _launchUrl(widget.complaint.videoUrl),
                      child: Text(
                        'View Video',
                        style: TextStyle(color: Colors.blue.shade300, decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
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