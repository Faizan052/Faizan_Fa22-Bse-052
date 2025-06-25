import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/auth_provider.dart';
import 'providers/complaint_provider.dart';
import 'routes/app_routes.dart';
import 'screens/admin/department_management.dart';
import 'screens/admin/batch_management.dart';

import 'screens/admin/user_management.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://vgxztzhbiljfgewfokkj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZneHp0emhiaWxqZmdld2Zva2tqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk5NzYxNjAsImV4cCI6MjA2NTU1MjE2MH0.yBWDxXOH5qdOIezTnZLUFfy4tQ6PZ3X4uJE-sazM2DY',
  );
  final authProvider = AuthProvider();
  await authProvider.autoLogin();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authProvider),
        ChangeNotifierProvider(create: (_) => ComplaintProvider()),
      ],
      child: ComplaintGuruApp(),
    ),
  );
}

class ComplaintGuruApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Complaint Guru',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      onGenerateRoute: AppRoutes.generate,
      debugShowCheckedModeBanner: false,
      routes: {
        '/admin/department-management': (context) => DepartmentManagementScreen(),
        '/admin/batch-management': (context) => BatchManagementScreen(),
        
        '/admin/user-management': (context) => UserManagementScreen(),
      },
    );
  }
}

// TODO: Initialize notification services
// TODO: Set up deep linking
// TODO: Implement global error handling