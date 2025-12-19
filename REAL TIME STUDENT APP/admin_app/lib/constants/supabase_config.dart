// lib/constants/supabase_config.dart
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://emoevufpoeuqfychejgl.supabase.co';

// ✅ Use your anon/public key for normal app usage
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVtb2V2dWZwb2V1cWZ5Y2hlamdsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc1NjQ4MTEsImV4cCI6MjA2MzE0MDgxMX0.RkmXgnC4zCogZFI5l8pJONd7TYJZxoTRJsujiGM6FuA';

// 🔐 Temporarily use your service role key here (for development ONLY)
const supabaseServiceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVtb2V2dWZwb2V1cWZ5Y2hlamdsIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0NzU2NDgxMSwiZXhwIjoyMDYzMTQwODExfQ.I95IZcPrDyIB6lkI2xgOhR22fmMBIsrIUcB6eh7GOek';

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
}

final supabase = Supabase.instance.client;
