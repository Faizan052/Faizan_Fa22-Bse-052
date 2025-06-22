import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
            itemBuilder: (_, i) => ListTile(
              title: Text(history[i]['action']),
              subtitle: Text(history[i]['comment']),
              trailing: Text(history[i]['created_at'].toString().split('T').first),
            ),
          );
        },
      ),
    );
  }
}

// TODO: Fetch and display user name/role for each history entry
// TODO: Highlight escalation/resolution actions in the history list
// TODO: Implement functionality to show escalation history
// TODO: Implement functionality to show status change logs
