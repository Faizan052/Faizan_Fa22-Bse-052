import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import 'login_screen.dart';
import '../student/student_dashboard.dart';
import '../batch_advisor/advisor_dashboard.dart';
import '../hod/hod_dashboard.dart';
import '../admin/admin_dashboard.dart';

class SplashScreen extends StatefulWidget {
  final NotificationService notificationService;

  const SplashScreen({Key? key, required this.notificationService}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  Future<void> _checkUser() async {
    await Provider.of<AuthProvider>(context, listen: false).loadCurrentUser();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      widget.notificationService.setupRealtimeNotifications(user.id);
      switch (user.role) {
        case 'student':
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const StudentDashboard()));
          break;
        case 'batch_advisor':
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const AdvisorDashboard()));
          break;
        case 'hod':
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const HodDashboard()));
          break;
        case 'admin':
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
          break;
        default:
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade300, Colors.blue.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }
}