// lib/main.dart
import 'package:flutter/material.dart';
import 'package:admin_app/constants/supabase_config.dart';
import 'package:admin_app/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin App',
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}
