import 'package:supabase_flutter/supabase_flutter.dart';

class UserLookupService {
  static final _client = Supabase.instance.client;

  static Future<String> getUserName(String userId) async {
    if (userId.isEmpty) return '';
    final data = await _client.from('users').select('name').eq('id', userId).maybeSingle();
    return data != null && data['name'] != null ? data['name'] as String : userId;
  }
}
