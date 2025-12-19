import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase/supabase.dart' as sb;
import '../models/batch.dart';

class BatchService {
  static final _client = Supabase.instance.client;
  // Service role client (never expose in production client apps!)
  static final _adminClient = sb.SupabaseClient(
    'https://vgxztzhbiljfgewfokkj.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZneHp0emhiaWxqZmdld2Zva2tqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0OTk3NjE2MCwiZXhwIjoyMDY1NTUyMTYwfQ.20e21Ck9qszbJ3XT1nhG4IRheW4anXOTRKVdtt5JibY',
  );

  static Future<List<Batch>> getBatches() async {
    final data = await _client.from('batches').select();
    return List<Map<String, dynamic>>.from(data)
        .map((b) => Batch.fromMap(b))
        .toList();
  }

  static Future<void> addBatch(String name, String departmentId, String advisorId) async {
    await _adminClient.from('batches').insert({'name': name, 'department_id': departmentId, 'advisor_id': advisorId});
  }

  static Future<void> updateBatch(String id, String name, String departmentId, String advisorId) async {
    await _adminClient.from('batches').update({'name': name, 'department_id': departmentId, 'advisor_id': advisorId}).eq('id', id);
  }

  static Future<void> deleteBatch(String id) async {
    await _adminClient.from('batches').delete().eq('id', id);
  }
}
