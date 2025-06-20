import 'package:flutter/material.dart';
import '../models/complaint.dart';
import '../services/database_service.dart';

class ComplaintProvider with ChangeNotifier {
  List<Complaint> _complaints = [];
  final DatabaseService _databaseService = DatabaseService();

  List<Complaint> get complaints => _complaints;

  Future<void> fetchComplaints(String userId, String role) async {
    try {
      if (role == 'student') {
        _complaints = await _databaseService.getStudentComplaints(userId);
      } else if (role == 'batch_advisor') {
        _complaints = await _databaseService.getAdvisorComplaints(userId);
      } else if (role == 'hod') {
        _complaints = await _databaseService.getHodComplaints(userId);
      }
      notifyListeners();
    } catch (e) {
      print('Error fetching complaints: $e');
    }
  }
}