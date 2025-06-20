import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/complaint_provider.dart';
import '../widgets/complaint_card.dart';
import 'complaint_details_screen.dart';
import '../utils/theme.dart';

class ComplaintHistoryScreen extends StatelessWidget {
  const ComplaintHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final complaintProvider = Provider.of<ComplaintProvider>(context);
    final complaints = complaintProvider.complaints;

    return Scaffold(
      appBar: AppBar(title: const Text('Complaint History')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: complaints.isEmpty
              ? const Center(child: Text('No complaints found', style: TextStyle(color: Colors.white)))
              : ListView.builder(
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              return ComplaintCard(
                complaint: complaint,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ComplaintDetailsScreen(complaint: complaint),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}