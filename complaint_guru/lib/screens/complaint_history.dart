import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/user_lookup_service.dart';

class ComplaintHistory extends StatelessWidget {
  final String complaintId;

  ComplaintHistory({required this.complaintId});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(title: Text("Complaint History")),
      body: FutureBuilder<List>(
        future: client
            .from('complaint_history')
            .select()
            .eq('complaint_id', complaintId)
            .order('created_at')
            .then((value) => value as List),
        builder: (_, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final history = snapshot.data!;
          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (_, i) {
              final entry = history[i];
              return FutureBuilder<String>(
                future: UserLookupService.getUserName(entry['user_id'] ?? ''),
                builder: (context, userSnap) {
                  final userName = userSnap.data ?? (entry['user_id'] ?? '');
                  return ListTile(
                    title: Text(entry['action']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((entry['comment'] ?? '').isNotEmpty)
                          Text('Comment: ' + entry['comment']),
                        if (userName.isNotEmpty)
                          Text('By: ' + userName, style: TextStyle(fontSize: 12, color: Colors.grey)),
                        if (entry['action'] == 'Resolved' || entry['action'] == 'Rejected')
                          Text(
                            entry['action'] == 'Resolved'
                                ? 'This complaint is resolved.'
                                : 'This complaint is rejected.',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: entry['action'] == 'Resolved' ? Colors.green : Colors.red,
                            ),
                          ),
                      ],
                    ),
                    trailing: Text(entry['created_at'].toString().split('T').first),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// TODO: Highlight escalation/resolution actions in the history list
// TODO: Implement functionality to show escalation history
// TODO: Implement functionality to show status change logs
