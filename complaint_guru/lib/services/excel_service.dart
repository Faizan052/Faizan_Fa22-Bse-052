import 'dart:io';
import 'package:excel/excel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

class ExcelService {
  final _client = Supabase.instance.client;

  Future<bool> uploadStudentExcel(PlatformFile file) async {
    try {
      final bytes = File(file.path!).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);

      // TODO: Validate Excel format (e.g., check for required columns)
      // TODO: Provide feedback on validation results

      for (final table in excel.tables.keys) {
        final sheet = excel.tables[table]!;
        for (var row in sheet.rows.skip(1)) {
          final name = row[0]?.value.toString();
          final email = row[1]?.value.toString();
          final batch = row[2]?.value.toString();
          final dept = row[3]?.value.toString();
          final advisorEmail = row[4]?.value.toString();

          if (dept == null || advisorEmail == null) {
            throw Exception('Department or Advisor Email is missing in the Excel row.');
          }
          final deptId = await _lookupId('departments', 'name', dept);
          final advisorId = await _lookupId('users', 'email', advisorEmail);

          // TODO: Handle duplicate users (e.g., skip or update existing users)
          final user = {
            'name': name,
            'email': email,
            'role': 'student',
            'department_id': deptId,
            'batch_id': await _ensureBatch(batch!, deptId, advisorId),
          };

          await _client.from('users').insert(user);
        }
      }
      return true;
    } catch (e) {
      print("Excel error: $e");
      return false;
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
