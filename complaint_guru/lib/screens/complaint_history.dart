import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/user_lookup_service.dart';

class ComplaintHistory extends StatelessWidget {
  final String complaintId;

  const ComplaintHistory({required this.complaintId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final client = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Complaint History",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<List>(
        future: client
            .from('complaint_history')
            .select()
            .eq('complaint_id', complaintId)
            .order('created_at')
            .then((value) => value as List),
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.primaryColor,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load history',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                ],
              ),
            );
          }

          final history = snapshot.data ?? [];
          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No history available',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: history.length,
            separatorBuilder: (_, __) => Divider(height: 24),
            itemBuilder: (_, index) {
              final entry = history[index];
              final isStatusChange = entry['action'] == 'Status Changed';
              final isResolution = entry['action'] == 'Resolved' || entry['action'] == 'Rejected';

              return FutureBuilder<String>(
                future: UserLookupService.getUserName(entry['user_id'] ?? ''),
                builder: (context, userSnap) {
                  final userName = userSnap.data ?? (entry['user_id'] ?? 'System');

                  return Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with action and date
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                entry['action'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isResolution
                                      ? (entry['action'] == 'Resolved'
                                      ? Colors.green
                                      : Colors.red)
                                      : theme.primaryColor,
                                ),
                              ),
                            ),
                            Text(
                              _formatDate(entry['created_at']),
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 12),

                        // Comment section
                        if ((entry['comment'] ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              entry['comment'],
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),

                        // User info
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 16,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'By: $userName',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),

                        // Special status for resolutions
                        if (isResolution)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (entry['action'] == 'Resolved'
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    entry['action'] == 'Resolved'
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: entry['action'] == 'Resolved'
                                        ? Colors.green
                                        : Colors.red,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    entry['action'] == 'Resolved'
                                        ? 'This complaint was resolved'
                                        : 'This complaint was rejected',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: entry['action'] == 'Resolved'
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    final dateStr = date.toString();
    return dateStr.split('T').first;
  }
}