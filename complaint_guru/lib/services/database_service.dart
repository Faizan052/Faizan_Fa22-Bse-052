import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/complaint.dart';
import '../models/batch.dart';
import '../models/department.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> addDepartment(String name, String hodId) async {
    await _supabase.from('departments').insert({
      'name': name,
      'hod_id': hodId,
    });
  }

  Future<List<Department>> getDepartments() async {
    final response = await _supabase.from('departments').select();
    return response.map((data) => Department.fromJson(data)).toList();
  }

  Future<void> updateDepartment(String id, String name, String hodId) async {
    await _supabase
        .from('departments')
        .update({'name': name, 'hod_id': hodId})
        .eq('id', id);
  }

  Future<void> deleteDepartment(String id) async {
    await _supabase.from('departments').delete().eq('id', id);
  }

  Future<void> addBatch(String name, String departmentId, String advisorId) async {
    await _supabase.from('batches').insert({
      'name': name,
      'department_id': departmentId,
      'advisor_id': advisorId,
    });
  }

  Future<List<Batch>> getBatches() async {
    final response = await _supabase.from('batches').select();
    return response.map((data) => Batch.fromJson(data)).toList();
  }

  Future<void> submitComplaint({
    required String title,
    required String description,
    String? imageUrl,
    String? videoUrl,
    required String studentId,
    required String batchId,
    required String advisorId,
  }) async {
    await _supabase.from('complaints').insert({
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'student_id': studentId,
      'batch_id': batchId,
      'advisor_id': advisorId,
      'status': 'Submitted',
    });
  }

  Future<List<Complaint>> getStudentComplaints(String studentId) async {
    final response = await _supabase
        .from('complaints')
        .select()
        .eq('student_id', studentId);
    return response.map((data) => Complaint.fromJson(data)).toList();
  }

  Future<List<Complaint>> getAdvisorComplaints(String advisorId) async {
    final response = await _supabase
        .from('complaints')
        .select()
        .eq('advisor_id', advisorId);
    return response.map((data) => Complaint.fromJson(data)).toList();
  }

  Future<List<Complaint>> getHodComplaints(String hodId) async {
    final response = await _supabase
        .from('complaints')
        .select()
        .eq('hod_id', hodId)
        .eq('status', 'Escalated to HOD');
    return response.map((data) => Complaint.fromJson(data)).toList();
  }

  Future<void> updateComplaintStatus(
      String complaintId, String status, String comment, String userId) async {
    await _supabase.from('complaints').update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', complaintId);

    await _supabase.from('complaint_history').insert({
      'complaint_id': complaintId,
      'action': 'Status updated to $status',
      'comment': comment,
      'user_id': userId,
    });
  }

  Future<void> escalateComplaint(
      String complaintId, String hodId, String comment, String userId) async {
    await _supabase.from('complaints').update({
      'status': 'Escalated to HOD',
      'hod_id': hodId,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', complaintId);

    await _supabase.from('complaint_history').insert({
      'complaint_id': complaintId,
      'action': 'Escalated to HOD',
      'comment': comment,
      'user_id': userId,
    });
  }

  Future<List<Map<String, dynamic>>> getComplaintHistory(String complaintId) async {
    final response = await _supabase
        .from('complaint_history')
        .select()
        .eq('complaint_id', complaintId);
    return response;
  }
}