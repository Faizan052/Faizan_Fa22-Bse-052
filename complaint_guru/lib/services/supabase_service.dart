import 'package:supabase/supabase.dart';
import '../models/user.dart';

class SupabaseService {
  static final _client = SupabaseClient(
    'https://vgxztzhbiljfgewfokkj.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZneHp0emhiaWxqZmdld2Zva2tqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk5NzYxNjAsImV4cCI6MjA2NTU1MjE2MH0.yBWDxXOH5qdOIezTnZLUFfy4tQ6PZ3X4uJE-sazM2DY',
  );

  static Future<UserModel?> signIn(String email, String password) async {
    final res = await _client.auth.signInWithPassword(email: email, password: password);
    if (res.user == null) throw Exception('Login failed');
    final userData = await _client.from('users').select().eq('id', res.user!.id).single();
    return UserModel.fromMap(userData);
  }

  static Future<List<Map<String, dynamic>>> getComplaintsByStudent(String studentId) async {
    final data = await _client.from('complaints').select().eq('student_id', studentId).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> getComplaintsForAdvisor(String advisorId) async {
    final data = await _client.from('complaints').select().eq('advisor_id', advisorId).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> getAllComplaints() async {
    final data = await _client.from('complaints').select().order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> createComplaint(Map<String, dynamic> complaint) async {
    await _client.from('complaints').insert(complaint);
  }

  static Future<void> updateComplaintStatus(String complaintId, String status) async {
    await _client.from('complaints').update({'status': status}).eq('id', complaintId);
  }

  static Future<String?> getAdvisorIdForBatch(String batchId) async {
    final data = await _client.from('batches').select('advisor_id').eq('id', batchId).single();
    return data['advisor_id'] as String?;
  }

  static Future<void> addComplaintHistory({
    required String complaintId,
    required String action,
    required String comment,
    required String userId,
  }) async {
    await _client.from('complaint_history').insert({
      'complaint_id': complaintId,
      'action': action,
      'comment': comment,
      'user_id': userId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<String?> getHodId() async {
    final data = await _client.from('users').select('id').eq('role', 'hod').maybeSingle();
    return data != null ? data['id'] as String? : null;
  }

  static Future<String?> getHodIdForDepartment(String departmentId) async {
    // Get the department row
    final dept = await _client.from('departments').select('hod_id').eq('id', departmentId).maybeSingle();
    if (dept == null || dept['hod_id'] == null) return null;
    return dept['hod_id'] as String?;
  }

  static Future<void> escalateToHod(String complaintId) async {
    final hodId = await getHodId();
    if (hodId == null) throw Exception('No HOD found in the system.');
    await _client.from('complaints').update({'status': 'Escalated to HOD', 'hod_id': hodId}).eq('id', complaintId);
  }

  static Future<String?> getBatchDepartmentId(String batchId) async {
    final batch = await _client.from('batches').select('department_id').eq('id', batchId).maybeSingle();
    if (batch == null || batch['department_id'] == null) return null;
    return batch['department_id'] as String?;
  }

  static Future<void> escalateToHodWithDepartment(String complaintId, String batchId) async {
    final departmentId = await getBatchDepartmentId(batchId);
    if (departmentId == null) throw Exception('No department found for this batch.');
    final hodId = await getHodIdForDepartment(departmentId);
    if (hodId == null) throw Exception('No HOD found for this department.');
    await _client.from('complaints').update({'status': 'Escalated to HOD', 'hod_id': hodId}).eq('id', complaintId);
  }

  // User CRUD
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final data = await _client.from('users').select();
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> createUser(Map<String, dynamic> user) async {
    await _client.from('users').insert(user);
  }

  static Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    await _client.from('users').update(updates).eq('id', userId);
  }

  static Future<void> deleteUser(String userId) async {
    await _client.from('users').delete().eq('id', userId);
  }

  // HOD CRUD (users with role 'hod')
  static Future<List<Map<String, dynamic>>> getAllHods() async {
    final data = await _client.from('users').select().eq('role', 'hod');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> createHod(Map<String, dynamic> hod) async {
    hod['role'] = 'hod';
    await _client.from('users').insert(hod);
  }

  static Future<void> updateHod(String hodId, Map<String, dynamic> updates) async {
    updates['role'] = 'hod';
    await _client.from('users').update(updates).eq('id', hodId);
  }

  static Future<void> deleteHod(String hodId) async {
    await _client.from('users').delete().eq('id', hodId).eq('role', 'hod');
  }

  // TODO: Implement real-time updates for complaints using Supabase Realtime.
  // TODO: Add notification triggers on complaint status change.
  // TODO: Explore advanced queries for filtering and searching complaints.
}
