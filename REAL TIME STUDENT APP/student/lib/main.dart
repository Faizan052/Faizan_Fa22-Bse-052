
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants/api_constants.dart';

void main() async {
WidgetsFlutterBinding.ensureInitialized();
await Supabase.initialize(
url: ApiConstants.supabaseUrl,
anonKey: ApiConstants.supabaseAnonKey,
);
runApp(MyApp());
}

class MyApp extends StatelessWidget {
@override
Widget build(BuildContext context) {
return MaterialApp(
title: 'Student Task Tracker',
theme: ThemeData(primarySwatch: Colors.blue),
home: DatabaseTestScreen(),
);
}
}

class DatabaseTestScreen extends StatefulWidget {
@override
_DatabaseTestScreenState createState() => _DatabaseTestScreenState();
}

class _DatabaseTestScreenState extends State<DatabaseTestScreen> {
String _connectionStatus = 'Testing connection...';

@override
void initState() {
super.initState();
testConnection();
}

Future<void> testConnection() async {
try {
await Supabase.instance.client.from('users').select('id').limit(1);
setState(() {
_connectionStatus = 'Connected to Supabase!';
});
} catch (e) {
setState(() {
_connectionStatus = 'Connection failed: $e';
});
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
body: Center(
child: Text(
_connectionStatus,
style: TextStyle(fontSize: 18),
),
),
);
}
}