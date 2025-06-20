import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class ExcelService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  Future<void> uploadUsersFromExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      if (result == null) return;

      final fileBytes = result.files.first.bytes;
      final excel = Excel.decodeBytes(fileBytes!);
      for (var table in excel.tables.keys) {
        for (var row in excel.tables[table]!.rows.skip(1)) {
          final studentName = row[0]?.value.toString();
          final email = row[1]?.value.toString();
          final batchName = row[2]?.value.toString();
          final departmentName = row[3]?.value.toString();
          final advisorEmail = row[4]?.value.toString();

          if (studentName == null || email == null || batchName == null || departmentName == null || advisorEmail == null) {
            continue;
          }

          // Get or create department
          var department = await _supabase
              .from('departments')
              .select()
              .eq('name', departmentName)
              .maybeSingle();
          if (department == null) {
            final hodResponse = await _supabase
                .from('users')
                .select('id')
                .eq('role', 'hod')
                .eq('department_id', null)
                .single();
            department = await _supabase
                .from('departments')
                .insert({
              'name': departmentName,
              'hod_id': hodResponse['id'],
            })
                .select()
                .single();
          }

          // Get or create batch
          var batch = await _supabase
              .from('batches')
              .select()
              .eq('name', batchName)
              .eq('department_id', department['id'])
              .maybeSingle();
          if (batch == null) {
            final advisor = await _supabase
                .from('users')
                .select('id')
                .eq('email', advisorEmail)
                .single();
            batch = await _supabase
                .from('batches')
                .insert({
              'name': batchName,
              'department_id': department['id'],
              'advisor_id': advisor['id'],
            })
                .select()
                .single();
          }

          // Add student
          await _authService.addUser(
            email: email,
            password: 'default123', // Default password, advise user to change
            name: studentName,
            role: 'student',
            batchId: batch['id'],
            departmentId: department['id'],
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to upload Excel: $e');
    }
  }
}