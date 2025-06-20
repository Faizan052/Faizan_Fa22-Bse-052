import 'package:flutter/material.dart';
import 'models.dart' as models;

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const CustomButton({Key? key, required this.text, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        textStyle: const TextStyle(fontSize: 16),
      ),
      child: Text(text),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Pending':
        color = Colors.orange;
        break;
      case 'Resolved':
        color = Colors.green;
        break;
      case 'Escalated to HOD':
        color = Colors.blue;
        break;
      case 'Rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Chip(
      label: Text(status, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }
}

class ComplaintCard extends StatelessWidget {
  final models.Complaint complaint;
  final VoidCallback onTap;

  const ComplaintCard({Key? key, required this.complaint, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white.withOpacity(0.1),
      child: ListTile(
        title: Text(complaint.title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          complaint.description,
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: StatusChip(status: complaint.status),
        onTap: onTap,
      ),
    );
  }
}

class TimelineView extends StatelessWidget {
  final List<Map<String, dynamic>> history;

  const TimelineView({Key? key, required this.history}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final entry = history[index];
        return ListTile(
          leading: const Icon(Icons.history, color: Colors.white),
          title: Text(
            '${entry['status']} by ${entry['updated_by']}',
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            entry['comment'] ?? '',
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),
        );
      },
    );
  }
}