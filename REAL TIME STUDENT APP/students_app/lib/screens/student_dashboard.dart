
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_messaging_screen.dart';
import '../student_login_screen.dart';

class StudentDashboard extends StatefulWidget {
final String userId;
const StudentDashboard({super.key, required this.userId});

@override
State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> with TickerProviderStateMixin {
final supabase = Supabase.instance.client;
List<Map<String, dynamic>> tasks = [];
Map<String, int> taskStats = {'Completed': 0, 'Pending': 0};
bool isLoading = false;
String? error;
StreamSubscription<List<Map<String, dynamic>>>? taskSubscription;

bool _sortByPriority = false; // Toggle for priority sorting
bool _sortByDeadline = false; // Toggle for deadline sorting

late AnimationController _controller;
late Animation<double> _fadeAnimation;

@override
void initState() {
super.initState();
_controller = AnimationController(
duration: const Duration(milliseconds: 800),
vsync: this,
);
_fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
);
_controller.forward();
_fetchTasks();
}

@override
void dispose() {
taskSubscription?.cancel();
_controller.dispose();
super.dispose();
}

Future<void> _fetchTasks() async {
setState(() {
isLoading = true;
error = null;
});

try {
final response = await supabase
    .from('tasks')
    .select()
    .eq('assigned_to', widget.userId);

final taskList = List<Map<String, dynamic>>.from(response);
final stats = {'Completed': 0, 'Pending': 0};
for (var task in taskList) {
stats[task['status']] = (stats[task['status']] ?? 0) + 1;
}

setState(() {
tasks = taskList;
taskStats = stats;
_applySorting();
});

taskSubscription?.cancel();
taskSubscription = supabase
    .from('tasks')
    .stream(primaryKey: ['id'])
    .eq('assigned_to', widget.userId)
    .listen((List<Map<String, dynamic>> updatedTasks) {
final stats = {'Completed': 0, 'Pending': 0};
for (var task in updatedTasks) {
stats[task['status']] = (stats[task['status']] ?? 0) + 1;
}
setState(() {
tasks = updatedTasks;
taskStats = stats;
_applySorting();
});
});
} catch (e) {
setState(() => error = 'Error fetching tasks: $e');
} finally {
setState(() => isLoading = false);
}
}

void _applySorting() {
List<Map<String, dynamic>> sortedTasks = List.from(tasks);

// Sort by deadline (nearest first) if enabled
if (_sortByDeadline) {
sortedTasks.sort((a, b) {
final deadlineA = a['deadline'] != null ? DateTime.parse(a['deadline']).toLocal() : DateTime(9999);
final deadlineB = b['deadline'] != null ? DateTime.parse(b['deadline']).toLocal() : DateTime(9999);
return deadlineA.compareTo(deadlineB);
});
}

// Sort by priority (High > Medium > Low) if enabled
if (_sortByPriority) {
sortedTasks.sort((a, b) {
// If sorting by deadline as well, only sort by priority if deadlines are equal
if (_sortByDeadline) {
final deadlineA = a['deadline'] != null ? DateTime.parse(a['deadline']).toLocal() : DateTime(9999);
final deadlineB = b['deadline'] != null ? DateTime.parse(b['deadline']).toLocal() : DateTime(9999);
final deadlineComparison = deadlineA.compareTo(deadlineB);
if (deadlineComparison != 0) return deadlineComparison;
}
final priorityA = _getPriorityValue(a['priority']?.toString() ?? 'N/A');
final priorityB = _getPriorityValue(b['priority']?.toString() ?? 'N/A');
return priorityB.compareTo(priorityA); // Descending order (High first)
});
}

setState(() {
tasks = sortedTasks;
});
}

int _getPriorityValue(String priority) {
switch (priority.toLowerCase()) {
case 'high':
return 3;
case 'medium':
return 2;
case 'low':
return 1;
default:
return 0;
}
}

Future<void> _showFilterDialog() async {
bool tempSortByPriority = _sortByPriority;
bool tempSortByDeadline = _sortByDeadline;

await showDialog(
context: context,
builder: (context) => AlertDialog(
backgroundColor: Colors.grey[900],
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
title: const Text(
'Sort Tasks',
style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
),
content: Column(
mainAxisSize: MainAxisSize.min,
children: [
SwitchListTile(
title: const Text(
'Sort by Priority (High to Low)',
style: TextStyle(color: Colors.white, fontSize: 14),
),
value: tempSortByPriority,
activeColor: const Color(0xFF3B82F6),
onChanged: (value) {
tempSortByPriority = value;
},
),
SwitchListTile(
title: const Text(
'Sort by Deadline (Nearest First)',
style: TextStyle(color: Colors.white, fontSize: 14),
),
value: tempSortByDeadline,
activeColor: const Color(0xFF3B82F6),
onChanged: (value) {
tempSortByDeadline = value;
},
),
],
),
actions: [
TextButton(
onPressed: () => Navigator.pop(context),
child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
),
ElevatedButton(
onPressed: () {
setState(() {
_sortByPriority = tempSortByPriority;
_sortByDeadline = tempSortByDeadline;
_applySorting();
});
Navigator.pop(context);
},
style: ElevatedButton.styleFrom(
backgroundColor: const Color(0xFF3B82F6),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
elevation: 4,
),
child: const Text('Apply', style: TextStyle(color: Colors.white)),
),
],
),
);
}

Future<void> markAsCompleted(String taskId) async {
try {
await supabase.from('tasks').update({'status': 'Completed'}).eq('id', taskId);
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: const Text('✅ Task marked as completed'),
backgroundColor: const Color(0xFF3B82F6).withOpacity(0.8),
),
);
} catch (e) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('❌ Error: $e'),
backgroundColor: const Color(0xFF3B82F6).withOpacity(0.8),
),
);
}
}

Future<void> _showCalendar(BuildContext context) async {
final DateTime? picked = await showDatePicker(
context: context,
initialDate: DateTime.now(),
firstDate: DateTime(2020),
lastDate: DateTime(2030),
builder: (context, child) {
return Theme(
data: ThemeData.dark().copyWith(
colorScheme: const ColorScheme.dark(
primary: Color(0xFF3B82F6),
onPrimary: Colors.white,
surface: Color(0xFF1E3A8A),
onSurface: Colors.white,
),
dialogBackgroundColor: const Color(0xFF1E3A8A).withOpacity(0.9),
),
child: child!,
);
},
);
if (picked != null) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('Selected date: ${picked.toString().split(' ')[0]}'),
backgroundColor: const Color(0xFF3B82F6).withOpacity(0.8),
),
);
}
}

Future<void> _logout() async {
await supabase.auth.signOut();
Navigator.pushReplacement(
context,
MaterialPageRoute(builder: (_) => const StudentLoginScreen()),
);
}

String _formatDeadline(String? deadline) {
if (deadline == null) return 'No Deadline';
final dateTime = DateTime.parse(deadline).toLocal();
return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
}

@override
Widget build(BuildContext context) {
final size = MediaQuery.of(context).size;

return Scaffold(
appBar: AppBar(
title: const Text('Student Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
flexibleSpace: Container(
decoration: const BoxDecoration(
gradient: LinearGradient(
colors: [Color(0xFF1E3A8A), Color(0xFF6B21A8)],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
),
),
actions: [
IconButton(
icon: const Icon(Icons.logout, color: Colors.white),
onPressed: _logout,
tooltip: 'Logout',
),
],
),
floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
floatingActionButton: Column(
mainAxisAlignment: MainAxisAlignment.end,
children: [
Padding(
padding: const EdgeInsets.all(8.0),
child: FloatingActionButton(
heroTag: 'filter',
onPressed: _showFilterDialog,
backgroundColor: const Color(0xFF3B82F6).withOpacity(0.8),
elevation: 6,
child: const Icon(Icons.filter_list, color: Colors.white),
),
),
Padding(
padding: const EdgeInsets.all(8.0),
child: FloatingActionButton(
heroTag: 'calendar',
onPressed: () => _showCalendar(context),
backgroundColor: const Color(0xFF3B82F6).withOpacity(0.8),
elevation: 6,
child: const Icon(Icons.calendar_today, color: Colors.white),
),
),
Padding(
padding: const EdgeInsets.all(8.0),
child: FloatingActionButton(
heroTag: 'message',
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => MessagingScreen(userId: widget.userId),
),
);
},
backgroundColor: const Color(0xFFD946EF).withOpacity(0.8),
elevation: 6,
child: const Icon(Icons.message, color: Colors.white),
),
),
],
),
body: Container(
decoration: const BoxDecoration(
gradient: LinearGradient(
colors: [Color(0xFF1E3A8A), Color(0xFF6B21A8)],
begin: Alignment.topCenter,
end: Alignment.bottomCenter,
),
),
child: FadeTransition(
opacity: _fadeAnimation,
child: Center(
child: SingleChildScrollView(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
child: Container(
width: size.width * 0.9,
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(30),
gradient: LinearGradient(
colors: [
Colors.white.withOpacity(0.05),
Colors.white.withOpacity(0.15),
],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.2),
blurRadius: 20,
offset: const Offset(0, 10),
),
],
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Dashboard Overview',
style: TextStyle(
fontSize: 24,
fontWeight: FontWeight.w700,
color: Colors.white,
letterSpacing: 1.2,
shadows: [
Shadow(
color: Colors.black26,
offset: Offset(2, 2),
blurRadius: 4,
),
],
),
),
const SizedBox(height: 24),
_buildProgressGraph(),
const SizedBox(height: 24),
const Text(
'Your Tasks',
style: TextStyle(
fontSize: 22,
fontWeight: FontWeight.w600,
color: Colors.white,
shadows: [
Shadow(
color: Colors.black26,
offset: Offset(1, 1),
blurRadius: 3,
),
],
),
),
const SizedBox(height: 16),
isLoading
? const Center(child: CircularProgressIndicator(color: Colors.white))
    : error != null
? Padding(
padding: const EdgeInsets.only(top: 8),
child: Text(
error!,
style: const TextStyle(color: Colors.redAccent, fontSize: 14),
),
)
    : tasks.isEmpty
? const Center(
child: Text(
'No tasks found.',
style: TextStyle(color: Colors.white70, fontSize: 16),
),
)
    : ListView.builder(
shrinkWrap: true,
physics: const NeverScrollableScrollPhysics(),
itemCount: tasks.length,
itemBuilder: (context, index) {
final task = tasks[index];
final priority = task['priority']?.toString() ?? 'N/A';
final description = task['description']?.toString() ?? 'No description';
final deadline = task['deadline']?.toString();

Color priorityColor;
switch (priority.toLowerCase()) {
case 'high':
priorityColor = Colors.redAccent;
break;
case 'medium':
priorityColor = Colors.orange;
break;
case 'low':
priorityColor = Colors.green;
break;
default:
priorityColor = Colors.grey;
}

return Card(
color: Colors.white.withOpacity(0.1),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(15),
),
elevation: 6,
margin: const EdgeInsets.symmetric(vertical: 8),
child: Padding(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Expanded(
child: Text(
task['title'],
style: const TextStyle(
color: Colors.white,
fontWeight: FontWeight.w500,
fontSize: 16,
),
overflow: TextOverflow.ellipsis,
),
),
const SizedBox(width: 8),
Container(
padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
decoration: BoxDecoration(
color: priorityColor.withOpacity(0.2),
borderRadius: BorderRadius.circular(8),
border: Border.all(color: priorityColor, width: 1),
),
child: Text(
priority,
style: TextStyle(
color: priorityColor,
fontSize: 12,
fontWeight: FontWeight.bold,
),
),
),
],
),
const SizedBox(height: 6),
Text(
'Status: ${task['status']}',
style: TextStyle(color: Colors.white70, fontSize: 13),
),
const SizedBox(height: 6),
Text(
'Description: $description',
style: TextStyle(color: Colors.white70, fontSize: 13),
maxLines: 3,
overflow: TextOverflow.ellipsis,
),
const SizedBox(height: 6),
Row(
children: [
Icon(
Icons.calendar_today,
color: Colors.white70,
size: 14,
),
const SizedBox(width: 4),
Expanded(
child: Text(
'Due: ${_formatDeadline(deadline)}',
style: TextStyle(
color: Colors.white70,
fontSize: 13,
fontStyle: FontStyle.italic,
),
overflow: TextOverflow.ellipsis,
),
),
],
),
],
),
),
const SizedBox(width: 12),
ElevatedButton(
style: ElevatedButton.styleFrom(
backgroundColor: task['status'] == 'Completed'
? Colors.grey.withOpacity(0.5)
    : const Color(0xFF3B82F6),
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(10),
),
elevation: 4,
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
),
onPressed: task['status'] == 'Completed'
? null
    : () => markAsCompleted(task['id']),
child: const Text('Complete', style: TextStyle(fontSize: 14)),
),
],
),
),
);
},
),
],
),
),
),
),
),
),
);
}

Widget _buildProgressGraph() {
final totalTasks = taskStats['Completed']! + taskStats['Pending']! + 1; // Avoid division by zero
return Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(15),
gradient: LinearGradient(
colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.15)],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.2),
blurRadius: 15,
offset: const Offset(0, 8),
),
],
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Task Progress',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.w600,
color: Colors.white,
shadows: [
Shadow(
color: Colors.black26,
offset: Offset(1, 1),
blurRadius: 3,
),
],
),
),
const SizedBox(height: 16),
Row(
mainAxisAlignment: MainAxisAlignment.spaceEvenly,
children: [
_buildProgressBar(
label: 'Completed',
value: taskStats['Completed']!,
total: totalTasks,
color: const Color(0xFF3B82F6),
),
_buildProgressBar(
label: 'Pending',
value: taskStats['Pending']!,
total: totalTasks,
color: const Color(0xFFD946EF),
),
],
),
],
),
);
}

Widget _buildProgressBar({
required String label,
required int value,
required int total,
required Color color,
}) {
final percentage = value / total;
return Expanded(
child: Column(
children: [
Text(
'$label: $value',
style: const TextStyle(color: Colors.white, fontSize: 14),
textAlign: TextAlign.center,
),
const SizedBox(height: 8),
AnimatedContainer(
duration: const Duration(milliseconds: 800),
curve: Curves.easeOut,
height: 20,
width: double.infinity,
child: Stack(
children: [
Container(
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.2),
borderRadius: BorderRadius.circular(10),
),
),
AnimatedContainer(
duration: const Duration(milliseconds: 800),
curve: Curves.easeOut,
height: 20,
width: (MediaQuery.of(context).size.width * 0.4) * percentage,
decoration: BoxDecoration(
gradient: LinearGradient(
colors: [color, color.withOpacity(0.7)],
),
borderRadius: BorderRadius.circular(10),
boxShadow: [
BoxShadow(
color: color.withOpacity(0.3),
blurRadius: 6,
offset: const Offset(0, 3),
),
],
),
),
],
),
),
],
),
);
}
}
