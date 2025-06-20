import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart' as models;

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<models.User?> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) return null;

      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .single();

      return models.User.fromJson(userData);
    } catch (e) {
      throw 'Login failed: $e';
    }
  }

  Future<models.User?> getCurrentUser() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return null;

    final userData = await _supabase
        .from('users')
        .select()
        .eq('id', session.user.id)
        .maybeSingle();

    if (userData == null) return null;
    return models.User.fromJson(userData);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> addUser({
    required String email,
    required String name,
    required String role,
    String? batchId,
    String? departmentId,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true,
        ),
      );

      await _supabase.from('users').insert({
        'id': response.user!.id,
        'email': email,
        'name': name,
        'role': role,
        if (batchId != null) 'batch_id': batchId,
        if (departmentId != null) 'department_id': departmentId,
      });
    } catch (e) {
      throw 'Error creating user: $e';
    }
  }

  bool isValidUuid(String? uuid) {
    if (uuid == null) return true;
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(uuid);
  }
}

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

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
      'status': 'Pending',
    });
  }

  Future<List<models.Complaint>> getComplaints(String userId, String role) async {
    final query = _supabase.from('complaints').select();

    if (role == 'student') {
      query.eq('student_id', userId);
    } else if (role == 'batch_advisor') {
      query.eq('advisor_id', userId);
    } else if (role == 'hod') {
      query.eq('hod_id', userId);
    }

    final response = await query;
    return response.map((e) => models.Complaint.fromJson(e)).toList();
  }

  Future<List<models.ComplaintHistory>> getComplaintHistory(String complaintId) async {
    final response = await _supabase
        .from('complaint_history')
        .select()
        .eq('complaint_id', complaintId)
        .order('updated_at', ascending: false);

    return response.map((e) => models.ComplaintHistory.fromJson(e)).toList();
  }

  Future<void> updateComplaintStatus(
      String complaintId,
      String status,
      String comment,
      String userId,
      ) async {
    await _supabase
        .from('complaints')
        .update({'status': status})
        .eq('id', complaintId);

    await _supabase.from('complaint_history').insert({
      'complaint_id': complaintId,
      'status': status,
      'comment': comment,
      'user_id': userId,
    });
  }

  Future<void> escalateComplaint(
      String complaintId,
      String hodId,
      String comment,
      String userId,
      ) async {
    await _supabase.from('complaints').update({
      'status': 'Escalated to HOD',
      'hod_id': hodId,
    }).eq('id', complaintId);

    await _supabase.from('complaint_history').insert({
      'complaint_id': complaintId,
      'status': 'Escalated to HOD',
      'comment': comment,
      'user_id': userId,
    });
  }

  Future<List<models.Department>> getDepartments() async {
    final response = await _supabase.from('departments').select();
    return response.map((e) => models.Department.fromJson(e)).toList();
  }

  Future<void> addDepartment(String name, String hodId) async {
    await _supabase.from('departments').insert({
      'name': name,
      'hod_id': hodId,
    });
  }

  Future<List<models.Batch>> getBatches() async {
    final response = await _supabase.from('batches').select();
    return response.map((e) => models.Batch.fromJson(e)).toList();
  }

  Future<void> addBatch(String name, String departmentId, String advisorId) async {
    await _supabase.from('batches').insert({
      'name': name,
      'department_id': departmentId,
      'advisor_id': advisorId,
    });
  }
}

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  void setupRealtimeNotifications(String userId) {
    _supabase
        .channel('complaint_updates')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'complaints',
      callback: (payload) {
        // Handle real-time updates here
        print('Complaint update: $payload');
      },
    )
        .subscribe();
  }
}