import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/complaint_provider.dart';
import '../screens/common/login_screen.dart';
import 'complaint_action_screen.dart';
import '../widgets/complaint_card.dart';
import '../utils/theme.dart';

class AdvisorDashboard extends StatelessWidget {
  const AdvisorDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final complaintProvider = Provider.of<ComplaintProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advisor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FutureBuilder(
          future: complaintProvider.fetchComplaints(user!.id, user.role),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final complaints = complaintProvider.complaints;
            return Padding(
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
                          builder: (_) => ComplaintActionScreen(complaint: complaint),
                        ),
                      );
                    },
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