import 'dart:io';
import 'package:excel/excel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase/supabase.dart' as sb;

class ExcelService {
  final _client = Supabase.instance.client;
  // Admin client for service role operations (never expose this in production client apps!)
  static final _adminClient = sb.SupabaseClient(
    'https://vgxztzhbiljfgewfokkj.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZneHp0emhiaWxqZmdld2Zva2tqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0OTk3NjE2MCwiZXhwIjoyMDY1NTUyMTYwfQ.20e21Ck9qszbJ3XT1nhG4IRheW4anXOTRKVdtt5JibY',
  );

  Future<String> uploadStudentExcel(PlatformFile file) async {
    try {
      final bytes = file.bytes ?? (file.path != null ? File(file.path!).readAsBytesSync() : null);
      if (bytes == null) {
        return "Upload Failed: No file data found (check file selection).";
      }
      final excel = Excel.decodeBytes(bytes);
      int added = 0;
      for (final table in excel.tables.keys) {
        final sheet = excel.tables[table]!;
        for (var row in sheet.rows.skip(1)) {
          final name = row[0]?.value?.toString() ?? '';
          final email = row[1]?.value?.toString() ?? '';
          final password = row[2]?.value?.toString() ?? 'student123'; // default password if not provided
          final batch = row.length > 3 ? row[3]?.value?.toString() : null;
          final dept = row.length > 4 ? row[4]?.value?.toString() : null;

          if (email.isEmpty) {
            return 'Email is missing in the Excel row.';
          }
          // Check for duplicate
          final existing = await _client.from('users').select('id').eq('email', email).maybeSingle();
          if (existing != null) continue; // skip duplicate

          String? deptId;
          if (dept != null && dept.isNotEmpty) {
            try {
              deptId = await _lookupId('departments', 'name', dept);
            } catch (_) {
              deptId = null;
            }
          }
          String? batchId;
          if (batch != null && batch.isNotEmpty && deptId != null) {
            batchId = await _ensureBatch(batch, deptId);
          }

          // Register in Supabase Auth (auto-verify) using admin client
          final res = await _adminClient.auth.admin.createUser(
            sb.AdminUserAttributes(email: email, password: password, emailConfirm: true),
          );
          final userId = res.user?.id;
          if (userId == null) continue;

          final user = {
            'id': userId,
            'name': name,
            'email': email,
            'role': 'student',
            'department_id': deptId,
            'batch_id': batchId,
          };
          await _client.from('users').insert(user);
          added++;
        }
      }
      return 'Upload Successful: $added students added.';
    } catch (e) {
      print("Excel error: $e");
      return 'Upload Failed: \\${e.toString()}';
    }
  }

  Future<String> _lookupId(String table, String field, String value) async {
    final data = await _client.from(table).select('id').eq(field, value).maybeSingle();
    if (data == null) throw Exception("Not found in $table");
    return data['id'];
  }

  Future<String> _ensureBatch(String name, String deptId) async {
    final existing = await _client
        .from('batches')
        .select('id')
        .eq('name', name)
        .eq('department_id', deptId)
        .maybeSingle();
    if (existing != null) return existing['id'];

    final insert = await _client.from('batches').insert({
      'name': name,
      'department_id': deptId,
    }).select().single();
    return insert['id'];
  }
}

// TODO: Provide a summary of the upload results to the admin (e.g., number of records added, skipped, etc.)
