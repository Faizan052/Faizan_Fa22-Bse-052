import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';

class LoginScreen extends StatelessWidget {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: emailCtrl, decoration: InputDecoration(labelText: "Email")),
            TextField(controller: passCtrl, decoration: InputDecoration(labelText: "Password"), obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  await auth.signIn(emailCtrl.text, passCtrl.text);
                  final role = auth.user?.role;
                  print('User role: ' + (role ?? 'null'));
                  switch (role) {
                    case 'student': Navigator.pushReplacementNamed(context, AppRoutes.studentDash); break;
                    case 'batch_advisor': Navigator.pushReplacementNamed(context, AppRoutes.advisorDash); break;
                    case 'hod': Navigator.pushReplacementNamed(context, AppRoutes.hodDash); break;
                    case 'admin': Navigator.pushReplacementNamed(context, AppRoutes.adminDash); break;
                    default: ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Unknown role: "+(role??''))));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login failed: $e")));
                }
              },
              child: Text("Login"),
            ),
            // TODO: Add hooks for complaint history, notifications, and timeline as per requirements.
            // For example, add a button to view complaint history or show notifications on status change.
          ],
        ),
      ),
    );
  }
}
