import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/student_dashboard.dart';
import '../screens/advisor_dashboard.dart';
import '../screens/hod_dashboard.dart';
import '../screens/admin_dashboard.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AppRoutes {
  static const login = '/';
  static const studentDash = '/student';
  static const advisorDash = '/advisor';
  static const hodDash = '/hod';
  static const adminDash = '/admin';

  static Route<dynamic> generate(RouteSettings settings) {
    return MaterialPageRoute(builder: (context) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      switch (settings.name) {
        case login:
          return LoginScreen();
        case studentDash:
          if (user != null && user.role == 'student') return StudentDashboard();
          return LoginScreen();
        case advisorDash:
          if (user != null && user.role == 'batch_advisor') return AdvisorDashboard();
          return LoginScreen();
        case hodDash:
          if (user != null && user.role == 'hod') return HodDashboard();
          return LoginScreen();
        case adminDash:
          if (user != null && user.role == 'admin') return AdminDashboard();
          return LoginScreen();
        default:
          return LoginScreen();
      }
    });
  }
}

// TODO: Add navigation to ComplaintHistory screen from dashboards
// TODO: Restrict routes based on user role
