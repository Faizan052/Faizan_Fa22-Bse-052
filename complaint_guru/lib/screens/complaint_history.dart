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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Complaint History",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
            letterSpacing: 1.1,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4F8FFF), Color(0xFF1CB5E0), Color(0xFF0F2027)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4F8FFF), Color(0xFF1CB5E0), Color(0xFF0F2027)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: FutureBuilder<List>(
              future: client
                  .from('complaint_history')
                  .select()
                  .eq('complaint_id', complaintId)
                  .order('created_at')
                  .then((value) => value as List),
              builder: (_, snapshot) {
                // Loading state - enhanced styling
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: theme.primaryColor,
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading history...',
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Error state - enhanced styling
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load history',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.red[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final history = snapshot.data ?? [];

                // Empty state - enhanced styling
                if (history.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 48,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No history available',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
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

                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: Colors.white,
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header with action and date - enhanced styling
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
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDarkMode ? Colors.grey[700] : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        entry['created_at'].toString().split('T').first,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDarkMode ? Colors.white70 : Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 12),

                                // Comment section - enhanced styling
                                if ((entry['comment'] ?? '').isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDarkMode
                                            ? Colors.grey[800]
                                            : Colors.grey[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        entry['comment'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDarkMode ? Colors.white70 : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),

                                // User info - enhanced styling
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'By: $userName',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),

                                // Special status for resolutions - enhanced styling
                                if (isResolution)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: (entry['action'] == 'Resolved'
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1)),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: (entry['action'] == 'Resolved'
                                              ? Colors.green
                                              : Colors.red)
                                              .withOpacity(0.2),
                                        ),
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
                                            size: 20,
                                          ),
                                          SizedBox(width: 12),
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
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}