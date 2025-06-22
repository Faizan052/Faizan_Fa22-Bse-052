import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/department.dart';

class DepartmentService {
  static final _client = Supabase.instance.client;

  static Future<List<Department>> getDepartments() async {
    final data = await _client.from('departments').select();
    return List<Map<String, dynamic>>.from(data)
        .map((d) => Department.fromMap(d))
        .toList();
  }

  static Future<void> addDepartment(String name, String hodId) async {
    await _client.from('departments').insert({'name': name, 'hod_id': hodId});
  }

  static Future<void> updateDepartment(String id, String name, String hodId) async {
    await _client.from('departments').update({'name': name, 'hod_id': hodId}).eq('id', id);
  }

  static Future<void> deleteDepartment(String id) async {
    await _client.from('departments').delete().eq('id', id);
  }
}
