
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://emoevufpoeuqfychejgl.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVtb2V2dWZwb2V1cWZ5Y2hlamdsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc1NjQ4MTEsImV4cCI6MjA2MzE0MDgxMX0.RkmXgnC4zCogZFI5l8pJONd7TYJZxoTRJsujiGM6FuA',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Task App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const StudentLoginScreen(),
    );
  }
}