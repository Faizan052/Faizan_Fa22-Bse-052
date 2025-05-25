
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'assign_task_screen.dart';
import 'student_task_detail_screen.dart';

class ViewStudentsScreen extends StatefulWidget {
const ViewStudentsScreen({Key? key}) : super(key: key);

@override
State<ViewStudentsScreen> createState() => _ViewStudentsScreenState();
}

class _ViewStudentsScreenState extends State<ViewStudentsScreen> {
final supabase = Supabase.instance.client;
List<dynamic> _students = [];
bool _isLoading = false;
String? _error;

@override
void initState() {
super.initState();
fetchStudents();
}

Future<void> fetchStudents() async {
setState(() {
_isLoading = true;
_error = null;
});

try {
final response = await supabase.from('users').select().eq('role', 'student');
setState(() {
_students = response;
});
} catch (e) {
setState(() {
_error = 'Error loading students: $e';
_students = [];
});
} finally {
setState(() {
_isLoading = false;
});
}
}

Future<void> _deleteStudent(String uuid) async {
if (uuid.isEmpty || !RegExp(
r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
caseSensitive: false).hasMatch(uuid)) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('❌ Invalid student ID')),
);
return;
}

final confirm = await showDialog<bool>(
context: context,
builder: (_) => AlertDialog(
backgroundColor: Colors.grey[900],
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
title: const Text(
'Confirm Delete',
style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
),
content: const Text(
'Are you sure you want to delete this student?',
style: TextStyle(color: Colors.black87),
),
actions: [
TextButton(
onPressed: () => Navigator.pop(context, false),
child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
),
ElevatedButton(
onPressed: () => Navigator.pop(context, true),
style: ElevatedButton.styleFrom(
backgroundColor: Colors.red,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
elevation: 4,
),
child: const Text('Delete', style: TextStyle(color: Colors.black)),
),
],
),
);

if (confirm != true) return;

try {
await supabase.from('tasks').delete().eq('assigned_to', uuid);
await supabase.from('messages').delete().or('sender_id.eq.$uuid,receiver_id.eq.$uuid');
await supabase.from('badges').delete().eq('user_id', uuid);
await supabase.from('reports').delete().eq('user_id', uuid);
await supabase.from('users').delete().eq('id', uuid);

setState(() {
_students.removeWhere((student) => student['id'] == uuid);
});

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('✅ Student deleted successfully')),
);
} catch (e) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('❌ Error deleting student: $e')),
);
}
}

Future<void> _editStudent(Map<String, dynamic> student) async {
final nameController = TextEditingController(text: student['name']);
final emailController = TextEditingController(text: student['email']);

showDialog(
context: context,
builder: (_) => AlertDialog(
backgroundColor: Colors.grey[900],
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
title: const Text(
'Edit Student',
style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
),
content: Column(
mainAxisSize: MainAxisSize.min,
children: [
TextField(
controller: nameController,
style: const TextStyle(color: Colors.black),
decoration: InputDecoration(
labelText: 'Name',
labelStyle: TextStyle(color: Colors.black87),
filled: true,
fillColor: Colors.black.withOpacity(0.1),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: BorderSide.none,
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
),
),
),
const SizedBox(height: 16),
TextField(
controller: emailController,
style: const TextStyle(color: Colors.black),
decoration: InputDecoration(
labelText: 'Email',
labelStyle: TextStyle(color: Colors.black87),
filled: true,
fillColor: Colors.black.withOpacity(0.1),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: BorderSide.none,
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
),
),
),
],
),
actions: [
TextButton(
onPressed: () => Navigator.pop(context),
child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
),
ElevatedButton(
onPressed: () async {
final updatedName = nameController.text.trim();
final updatedEmail = emailController.text.trim();

if (updatedName.isEmpty || updatedEmail.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Name and Email cannot be empty')),
);
return;
}

try {
await supabase.from('users').update({
'name': updatedName,
'email': updatedEmail,
}).eq('id', student['id']);

Navigator.pop(context);

setState(() {
final index = _students.indexWhere((s) => s['id'] == student['id']);
if (index != -1) {
_students[index]['name'] = updatedName;
_students[index]['email'] = updatedEmail;
}
});

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('✅ Student updated')),
);
} catch (e) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('❌ Error updating: $e')),
);
}
},
style: ElevatedButton.styleFrom(
backgroundColor: const Color(0xFF3B82F6),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
elevation: 4,
),
child: const Text('Save', style: TextStyle(color: Colors.black)),
),
],
),
);
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text(
'All Students',
style: TextStyle(
color: Colors.black,
fontWeight: FontWeight.bold,
fontSize: 22,
shadows: [
Shadow(color: Colors.black26, offset: Offset(2, 2), blurRadius: 4),
],
),
),
elevation: 8,
flexibleSpace: Container(
decoration: const BoxDecoration(
gradient: LinearGradient(
colors: [Color(0xFF1E3A8A), Color(0xFF6B21A8)],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
),
),
),
body: Container(
decoration: BoxDecoration(
gradient: LinearGradient(
colors: [const Color(0xFF1E3A8A), const Color(0xFF6B21A8)],
begin: Alignment.topCenter,
end: Alignment.bottomCenter,
),
),
child: _isLoading
? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
    : _error != null
? Center(
child: Text(
_error!,
style: const TextStyle(
color: Colors.redAccent,
fontSize: 16,
shadows: [
Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 3),
],
),
),
)
    : _students.isEmpty
? const Center(
child: Text(
'No students found.',
style: TextStyle(
color: Colors.black87,
fontSize: 18,
fontStyle: FontStyle.italic,
),
),
)
    : ListView.builder(
padding: const EdgeInsets.all(12),
itemCount: _students.length,
itemBuilder: (context, index) {
final student = _students[index];
final name = student['name'] ?? 'Unnamed';
final email = student['email'] ?? 'No Email';
final uuid = student['id'];

return Card(
elevation: 8,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
),
margin: const EdgeInsets.only(bottom: 12),
child: Container(
decoration: BoxDecoration(
gradient: LinearGradient(
colors: [
Colors.black.withOpacity(0.05),
Colors.black.withOpacity(0.15),
],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
borderRadius: BorderRadius.circular(16),
border: Border.all(
color: Colors.black.withOpacity(0.2),
width: 1,
),
),
child: ListTile(
contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
leading: CircleAvatar(
radius: 24,
backgroundColor: Colors.transparent,
child: Container(
decoration: BoxDecoration(
shape: BoxShape.circle,
gradient: const LinearGradient(
colors: [Color(0xFF3B82F6), Color(0xFFD946EF)],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
),
child: Center(
child: Text(
name.isNotEmpty ? name[0].toUpperCase() : "?",
style: const TextStyle(
color: Colors.black,
fontSize: 20,
fontWeight: FontWeight.bold,
),
),
),
),
),
title: Text(
name,
style: const TextStyle(
fontWeight: FontWeight.bold,
fontSize: 16,
color: Colors.black,
shadows: [
Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2),
],
),
),
subtitle: Text(
email,
style: const TextStyle(
color: Colors.black87,
fontSize: 14,
fontStyle: FontStyle.italic,
),
),
isThreeLine: true,
trailing: Wrap(
spacing: 4,
children: [
IconButton(
icon: const Icon(Icons.assignment_turned_in, color: Color(0xFF3B82F6)),
tooltip: 'Assign Task',
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => AssignTaskScreen(student: student),
),
);
},
style: IconButton.styleFrom(
backgroundColor: Colors.black.withOpacity(0.1),
padding: const EdgeInsets.all(8),
),
),
IconButton(
icon: const Icon(Icons.list_alt, color: Colors.black),
tooltip: 'View Tasks',
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => StudentTaskDetailScreen(student: student),
),
);
},
style: IconButton.styleFrom(
backgroundColor: Colors.grey[700],
padding: const EdgeInsets.all(8),
),
),
IconButton(
icon: const Icon(Icons.edit, color: Colors.orange),
tooltip: 'Edit',
onPressed: () => _editStudent(student),
style: IconButton.styleFrom(
backgroundColor: Colors.black.withOpacity(0.1),
padding: const EdgeInsets.all(8),
),
),
IconButton(
icon: const Icon(Icons.delete, color: Colors.red),
tooltip: 'Delete',
onPressed: () => _deleteStudent(uuid),
style: IconButton.styleFrom(
backgroundColor: Colors.black.withOpacity(0.1),
padding: const EdgeInsets.all(8),
),
),
],
),
),
),
);
},
),
),
);
}
}
