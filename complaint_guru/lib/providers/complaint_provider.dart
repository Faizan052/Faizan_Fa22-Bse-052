import 'package:flutter/material.dart';
import 'package:complaint_guru/models/complaint.dart';
import 'package:complaint_guru/services/supabase_service.dart';

class ComplaintProvider with ChangeNotifier {
  List<Complaint> _complaints = [];
  bool _isLoading = false;

  List<Complaint> get complaints => _complaints;
  bool get isLoading => _isLoading;

  Future<void> fetchComplaints(String userId, String role) async {
    _isLoading = true;
    notifyListeners();

    try {
      List<Map<String, dynamic>> complaintsData;

      if (role == 'student') {
        complaintsData = await SupabaseService.getComplaintsByStudent(userId);
      } else if (role == 'advisor') {
        complaintsData = await SupabaseService.getComplaintsForAdvisor(userId);
      } else {
        complaintsData = await SupabaseService.getAllComplaints();
      }

      _complaints = complaintsData.map((data) => Complaint.fromMap(data)).toList();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addComplaint(Complaint complaint) async {
    await SupabaseService.createComplaint(complaint.toMap());
    await fetchComplaints(complaint.studentId, 'student');
  }

  Future<void> updateStatus(String complaintId, String status) async {
    await SupabaseService.updateComplaintStatus(complaintId, status);
    notifyListeners();
  }

  Future<void> addHistory({
    required String complaintId,
    required String action,
    required String comment,
    required String userId,
  }) async {
    await SupabaseService.addComplaintHistory(
      complaintId: complaintId,
      action: action,
      comment: comment,
      userId: userId,
    );
    notifyListeners();
  }

  // TODO: Implement real-time updates for complaints using Supabase subscriptions
  // Example: Listen for complaint changes, filter by status/date/student, and notify users on updates.

  // TODO: Add advanced filtering options for complaints
  // Example: Filter complaints by status, date range, or specific keywords.

  // TODO: Implement notification triggers for status changes
  // Example: Notify users when their complaint status changes via email or in-app notifications.
}