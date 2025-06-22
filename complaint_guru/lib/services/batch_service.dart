import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/batch.dart';

class BatchService {
  static final _client = Supabase.instance.client;

  static Future<List<Batch>> getBatches() async {
    final data = await _client.from('batches').select();
    return List<Map<String, dynamic>>.from(data)
        .map((b) => Batch.fromMap(b))
        .toList();
  }

  static Future<void> addBatch(String name, String departmentId, String advisorId) async {
    await _client.from('batches').insert({'name': name, 'department_id': departmentId, 'advisor_id': advisorId});
  }

  static Future<void> updateBatch(String id, String name, String departmentId, String advisorId) async {
    await _client.from('batches').update({'name': name, 'department_id': departmentId, 'advisor_id': advisorId}).eq('id', id);
  }

  static Future<void> deleteBatch(String id) async {
    await _client.from('batches').delete().eq('id', id);
  }
}
