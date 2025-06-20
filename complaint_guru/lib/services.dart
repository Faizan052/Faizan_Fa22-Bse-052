import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart' as models;

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<models.User?> login(String email, String password) async {
    try {
      print('AuthService: Signing in with email: $email');
      final response = await _supabase.auth.signInWithPassword(email: email, password: password);
      if (response.user == null) {
        print('AuthService: No user returned from auth');
        throw 'Invalid credentials';
      }
      final userData = await _supabase.from('users').select().eq('id', response.user!.id).single();
      print('AuthService: User data fetched: $userData');
      return models.User.fromJson(userData);
    } catch (e) {
      print('AuthService: Login error: $e');
      throw 'Login failed: $e';
    }
  }

  Future<models.User?> getCurrentUser() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        print('AuthService: No current session');
        return null;
      }
      print('AuthService: Fetching user: ${session.user.id}');
      final userData = await _supabase.from('users').select().eq('id', session.user.id).maybeSingle();
      if (userData == null) {
        print('AuthService: No user data found');
        return null;
      }
      print('AuthService: Current user fetched: $userData');
      return models.User.fromJson(userData);
    } catch (e) {
      print('AuthService: Get current user error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      print('AuthService: Signed out');
    } catch (e) {
      print('AuthService: Sign out error: $e');
      throw 'Sign out failed: $e';
    }
  }

  Future<void> addUser({
    required String email,
    required String name,
    required String role,
    String? batchId,
    String? departmentId,
  }) async {
    try {
      print('AuthService: Adding user: $email, role: $role');
      final response = await _supabase.auth.admin.createUser(
        AdminUserAttributes(email: email, password: 'tempPassword123'),
      );
      final userId = response.user!.id;
      final userData = {
        'id': userId,
        'email': email,
        'name': name,
        'role': role,
        if (batchId != null) 'batch_id': batchId,
        if (departmentId != null) 'department_id': departmentId,
      };
      await _supabase.from('users').insert(userData);
      print('AuthService: User added: $userId');
    } catch (e) {
      print('AuthService: Add user error: $e');
      throw 'Failed to add user: $e';
    }
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
    try {
      print('DatabaseService: Submitting complaint by $studentId');
      final batch = await _supabase.from('batches').select().eq('id', batchId).maybeSingle();
      if (batch == null) throw 'Batch not found';
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
      print('DatabaseService: Complaint submitted');
    } catch (e) {
      print('DatabaseService: Submit complaint error: $e');
      throw 'Failed to submit complaint: $e';
    }
  }

  Future<List<models.Complaint>> getComplaints(String userId, String role) async {
    try {
      print('DatabaseService: Fetching complaints for user: $userId, role: $role');
      final query = _supabase.from('complaints').select();
      if (role == 'student') {
        query.eq('student_id', userId);
      } else if (role == 'batch_advisor') {
        query.eq('advisor_id', userId);
      } else if (role == 'hod') {
        query.eq('hod_id', userId);
      } else if (role == 'admin') {
        // Admins can see all complaints
      } else {
        throw 'Invalid role';
      }
      final response = await query;
      final complaints = response.map((e) => models.Complaint.fromJson(e)).toList();
      print('DatabaseService: Fetched ${complaints.length} complaints');
      return complaints;
    } catch (e) {
      print('DatabaseService: Complaint fetch error: $e');
      throw 'Failed to fetch complaints: $e';
    }
  }

  Future<List<Map<String, dynamic>>> getComplaintHistory(String complaintId) async {
    try {
      print('DatabaseService: Fetching history for complaint: $complaintId');
      final response = await _supabase.from('complaint_history').select().eq('complaint_id', complaintId);
      print('DatabaseService: Fetched ${response.length} history entries');
      return response;
    } catch (e) {
      print('DatabaseService: Fetch history error: $e');
      throw 'Failed to fetch complaint history: $e';
    }
  }

  Future<void> updateComplaintStatus(
      String complaintId, String status, String comment, String userId) async {
    try {
      print('DatabaseService: Updating complaint $complaintId to status: $status');
      await _supabase.from('complaints').update({'status': status}).eq('id', complaintId);
      if (comment.isNotEmpty) {
        await _supabase.from('complaint_history').insert({
          'complaint_id': complaintId,
          'status': status,
          'comment': comment,
          'updated_by': userId,
        });
      }
      print('DatabaseService: Complaint status updated');
    } catch (e) {
      print('DatabaseService: Update status error: $e');
      throw 'Failed to update complaint status: $e';
    }
  }

  Future<void> escalateComplaint(String complaintId, String hodId, String comment, String userId) async {
    try {
      print('DatabaseService: Escalating complaint $complaintId to HOD: $hodId');
      await _supabase.from('complaints').update({
        'status': 'Escalated to HOD',
        'hod_id': hodId,
      }).eq('id', complaintId);
      if (comment.isNotEmpty) {
        await _supabase.from('complaint_history').insert({
          'complaint_id': complaintId,
          'status': 'Escalated to HOD',
          'comment': comment,
          'updated_by': userId,
        });
      }
      print('DatabaseService: Complaint escalated');
    } catch (e) {
      print('DatabaseService: Escalate error: $e');
      throw 'Failed to escalate complaint: $e';
    }
  }

  Future<List<models.Department>> getDepartments() async {
    try {
      print('DatabaseService: Fetching departments');
      final response = await _supabase.from('departments').select();
      final departments = response.map((e) => models.Department.fromJson(e)).toList();
      print('DatabaseService: Fetched ${departments.length} departments');
      return departments;
    } catch (e) {
      print('DatabaseService: Fetch departments error: $e');
      throw 'Failed to fetch departments: $e';
    }
  }

  Future<void> addDepartment(String name, String hodId) async {
    try {
      print('DatabaseService: Adding department: $name, hodId: $hodId');
      final hodExists = await _supabase.from('users').select().eq('id', hodId).maybeSingle();
      if (hodExists == null) throw 'HOD ID does not exist';
      await _supabase.from('departments').insert({'name': name, 'hod_id': hodId});
      print('DatabaseService: Department added');
    } catch (e) {
      print('DatabaseService: Add department error: $e');
      throw 'Failed to add department: $e';
    }
  }

  Future<List<models.Batch>> getBatches() async {
    try {
      print('DatabaseService: Fetching batches');
      final response = await _supabase.from('batches').select();
      final batches = response.map((e) => models.Batch.fromJson(e)).toList();
      print('DatabaseService: Fetched ${batches.length} batches');
      return batches;
    } catch (e) {
      print('DatabaseService: Fetch batches error: $e');
      throw 'Failed to fetch batches: $e';
    }
  }

  Future<void> addBatch(String name, String departmentId, String advisorId) async {
    try {
      print('DatabaseService: Adding batch: $name, deptId: $departmentId, advisorId: $advisorId');
      final deptExists = await _supabase.from('departments').select().eq('id', departmentId).maybeSingle();
      final advisorExists = await _supabase.from('users').select().eq('id', advisorId).maybeSingle();
      if (deptExists == null) throw 'Department ID does not exist';
      if (advisorExists == null) throw 'Advisor ID does not exist';
      await _supabase.from('batches').insert({
        'name': name,
        'department_id': departmentId,
        'advisor_id': advisorId,
      });
      print('DatabaseService: Batch added');
    } catch (e) {
      print('DatabaseService: Add batch error: $e');
      throw 'Failed to add batch: $e';
    }
  }
}

class NotificationService {
  void setupRealtimeNotifications(String userId) {
    print('NotificationService: Setting up notifications for user: $userId');
    // Placeholder for real-time subscriptions
  }
}

class ExcelService {
  Future<void> uploadUsersFromExcel() async {
    try {
      print('ExcelService: Uploading users from Excel');
      throw 'Excel upload not implemented';
    } catch (e) {
      print('ExcelService: Upload error: $e');
      throw 'Failed to upload users: $e';
    }
  }
}