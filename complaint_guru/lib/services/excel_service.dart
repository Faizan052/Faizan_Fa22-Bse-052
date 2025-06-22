import 'dart:io';
import 'package:excel/excel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

class ExcelService {
  final _client = Supabase.instance.client;

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
          final name = row[0]?.value.toString();
          final email = row[1]?.value.toString();
          final batch = row[2]?.value.toString();
          final dept = row[3]?.value.toString();
          final advisorEmail = row[4]?.value.toString();

          if (batch == null) {
            return 'Batch is missing in the Excel row.';
          }
          if (dept == null || advisorEmail == null) {
            return 'Department or Advisor Email is missing in the Excel row.';
          }
          if (email == null) {
            return 'Email is missing in the Excel row.';
          }
          final deptId = await _lookupId('departments', 'name', dept);
          final advisorId = await _lookupId('users', 'email', advisorEmail);
          final existing = await _client.from('users').select('id').eq('email', email).maybeSingle();
          if (existing != null) continue; // skip duplicate

          final user = {
            'name': name ?? '',
            'email': email,
            'role': 'student',
            'department_id': deptId,
            'batch_id': await _ensureBatch(batch, deptId, advisorId),
          };

          await _client.from('users').insert(user);
          added++;
        }
      }
      return 'Upload Successful: $added students added.';
    } catch (e) {
      print("Excel error: $e");
      return 'Upload Failed: ${e.toString()}';
    }
  }

  Future<String> _lookupId(String table, String field, String value) async {
    final data = await _client.from(table).select('id').eq(field, value).maybeSingle();
    if (data == null) throw Exception("Not found in $table");
    return data['id'];
  }

  Future<String> _ensureBatch(String name, String deptId, String advisorId) async {
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
      'advisor_id': advisorId,
    }).select().single();
    return insert['id'];
  }
}

// TODO: Provide a summary of the upload results to the admin (e.g., number of records added, skipped, etc.)
