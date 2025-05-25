
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_student_screen.dart';
import 'view_students_screen.dart';
import 'messaging_screen.dart';
import 'leaderboard_screen.dart';
import 'student_tasks_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
const DashboardScreen({super.key});

@override
State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
late AnimationController _titleController;
late AnimationController _buttonController;
late Animation<double> _titleFadeAnimation;
late Animation<Offset> _titleSlideAnimation;
late Animation<double> _buttonFadeAnimation;
List<Map<String, dynamic>> _topStudents = [];
bool _isLoadingTopStudents = false;
String? _topStudentsError;

final supabase = Supabase.instance.client;

@override
void initState() {
super.initState();
// Title animations
_titleController = AnimationController(
duration: const Duration(milliseconds: 800),
vsync: this,
);
_titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
CurvedAnimation(parent: _titleController, curve: Curves.easeInOut),
);
_titleSlideAnimation = Tween<Offset>(
begin: const Offset(0, -0.5),
end: Offset.zero,
).animate(
CurvedAnimation(parent: _titleController, curve: Curves.easeOutCubic),
);

// Button animations
_buttonController = AnimationController(
duration: const Duration(milliseconds: 700),
vsync: this,
);
_buttonFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
);

// Start animations
_titleController.forward();
Future.delayed(const Duration(milliseconds: 200), () => _buttonController.forward());

// Fetch top students
_fetchTopStudents();
}

@override
void dispose() {
_titleController.dispose();
_buttonController.dispose();
super.dispose();
}

Future<void> _fetchTopStudents() async {
setState(() {
_isLoadingTopStudents = true;
_topStudentsError = null;
});

try {
// Query tasks to count completed tasks per student
final response = await supabase
    .from('tasks')
    .select('assigned_to, users!inner(name)')
    .eq('status', 'Completed')
    .then((data) async {
// Aggregate completed tasks by user
Map<String, Map<String, dynamic>> studentTasks = {};
for (var task in data) {
final userId = task['assigned_to'];
final name = task['users']['name'];
if (studentTasks[userId] == null) {
studentTasks[userId] = {'name': name, 'completed_tasks': 0};
}
studentTasks[userId]!['completed_tasks']++;
}

// Convert to list and sort
var students = studentTasks.entries
    .map((e) => {
'user_id': e.key,
'name': e.value['name'],
'completed_tasks': e.value['completed_tasks'],
})
    .toList()
..sort((a, b) => b['completed_tasks'].compareTo(a['completed_tasks']));

// Take top 3
return students.take(3).toList();
});

setState(() {
_topStudents = response;
});
} catch (e) {
setState(() {
_topStudentsError = 'Error loading top students: $e';
});
} finally {
setState(() {
_isLoadingTopStudents = false;
});
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
colorScheme: ColorScheme.dark(
primary: const Color(0xFF3B82F6),
onPrimary: Colors.white,
surface: const Color(0xFF1E3A8A).withOpacity(0.9),
onSurface: Colors.white,
),
dialogBackgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
textButtonTheme: TextButtonThemeData(
style: TextButton.styleFrom(
foregroundColor: const Color(0xFF3B82F6),
),
),
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

void _logout(BuildContext context) {
// Basic logout functionality: navigate back to LoginScreen
Navigator.pushReplacement(
context,
MaterialPageRoute(builder: (_) => const LoginScreen()),
);
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('Admin Dashboard'),
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
Padding(
padding: const EdgeInsets.only(right: 16.0),
child: GlassmorphicIconButton(
icon: Icons.logout,
onPressed: () => _logout(context),
),
),
],
),
floatingActionButton: FloatingActionButton(
onPressed: () => _showCalendar(context),
backgroundColor: const Color(0xFF3B82F6).withOpacity(0.8),
child: const Icon(Icons.calendar_today_outlined, color: Colors.white),
),
body: Container(
decoration: const BoxDecoration(
gradient: LinearGradient(
colors: [Color(0xFF1E3A8A), Color(0xFF6B21A8)],
begin: Alignment.topCenter,
end: Alignment.bottomCenter,
),
),
child: SafeArea(
child: SingleChildScrollView(
padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.center,
children: [
FadeTransition(
opacity: _titleFadeAnimation,
child: SlideTransition(
position: _titleSlideAnimation,
child: const Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
Icons.dashboard_outlined,
color: Colors.white,
size: 34,
),
SizedBox(width: 12),
Text(
'Admin Dashboard',
style: TextStyle(
fontSize: 30,
fontWeight: FontWeight.w700,
color: Colors.white,
letterSpacing: 1.2,
),
),
],
),
),
),
const SizedBox(height: 24),
_buildTopStudentsGraph(),
const SizedBox(height: 48),
FadeTransition(
opacity: _buttonFadeAnimation,
child: Wrap(
spacing: 16.0,
runSpacing: 16.0,
alignment: WrapAlignment.center,
children: [
GlassmorphicButton(
text: 'Add New Student',
icon: Icons.person_add_outlined,
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(builder: (_) => const AddStudentScreen()),
);
},
),
GlassmorphicButton(
text: 'View Students',
icon: Icons.group_outlined,
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(builder: (_) => const ViewStudentsScreen()),
);
},
),
GlassmorphicButton(
text: 'Messages',
icon: Icons.chat_outlined,
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(builder: (_) => const MessagingScreen()),
);
},
),
GlassmorphicButton(
text: 'Student Tasks',
icon: Icons.task_outlined,
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(builder: (_) => const StudentTasksScreen()),
);
},
),
GlassmorphicButton(
text: 'Leaderboard',
icon: Icons.leaderboard_outlined,
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
);
},
),
],
),
),
],
),
),
),
),
);
}

Widget _buildTopStudentsGraph() {
return Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.1),
borderRadius: BorderRadius.circular(16),
border: Border.all(color: Colors.white.withOpacity(0.3)),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.2),
blurRadius: 12,
offset: const Offset(0, 6),
),
],
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Top 3 Students by Completed Tasks',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.w600,
color: Colors.white,
),
),
const SizedBox(height: 16),
_isLoadingTopStudents
? const Center(child: CircularProgressIndicator(color: Colors.white))
    : _topStudentsError != null
? Text(
_topStudentsError!,
style: const TextStyle(color: Colors.red),
)
    : _topStudents.isEmpty
? const Text(
'No completed tasks yet.',
style: TextStyle(color: Colors.white),
)
    : Column(
children: _topStudents.asMap().entries.map((entry) {
final index = entry.key;
final student = entry.value;
final name = student['name'] ?? 'Unknown';
final tasks = student['completed_tasks'] ?? 0;
final maxTasks = _topStudents.isNotEmpty
? (_topStudents[0]['completed_tasks'] as int? ?? 1)
    : 1;

return Padding(
padding: const EdgeInsets.only(bottom: 12),
child: Row(
children: [
SizedBox(
width: 100,
child: Text(
name,
style: const TextStyle(
color: Colors.white,
fontSize: 14,
fontWeight: FontWeight.w500,
),
overflow: TextOverflow.ellipsis,
),
),
const SizedBox(width: 8),
Expanded(
child: Stack(
children: [
Container(
height: 20,
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.2),
borderRadius: BorderRadius.circular(10),
),
),
AnimatedContainer(
duration: const Duration(milliseconds: 1000),
curve: Curves.easeOut,
height: 20,
width: MediaQuery.of(context).size.width *
0.5 *
(tasks / maxTasks),
decoration: BoxDecoration(
gradient: LinearGradient(
colors: [
Colors.blue.shade600,
Colors.purple.shade600,
],
),
borderRadius: BorderRadius.circular(10),
),
),
],
),
),
const SizedBox(width: 8),
Text(
'$tasks',
style: const TextStyle(
color: Colors.white,
fontSize: 14,
fontWeight: FontWeight.w500,
),
),
],
),
);
}).toList(),
),
],
),
);
}
}

class GlassmorphicButton extends StatefulWidget {
final String text;
final IconData icon;
final VoidCallback onPressed;
final bool isSmall;

const GlassmorphicButton({
Key? key,
required this.text,
required this.icon,
required this.onPressed,
this.isSmall = false,
}) : super(key: key);

@override
_GlassmorphicButtonState createState() => _GlassmorphicButtonState();
}

class _GlassmorphicButtonState extends State<GlassmorphicButton> with SingleTickerProviderStateMixin {
late AnimationController _controller;
late Animation<double> _scaleAnimation;
late Animation<double> _borderAnimation;
bool _isTapped = false;

@override
void initState() {
super.initState();
_controller = AnimationController(
duration: const Duration(milliseconds: 200),
vsync: this,
);
_scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
);
_borderAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
);
}

@override
void dispose() {
_controller.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
final double width = widget.isSmall ? 110.0 : 160.0;
final double height = widget.isSmall ? 40.0 : 120.0;
return GestureDetector(
onTapDown: (_) {
setState(() => _isTapped = true);
_controller.forward();
},
onTapUp: (_) {
setState(() => _isTapped = false);
_controller.reverse();
widget.onPressed();
},
onTapCancel: () {
setState(() => _isTapped = false);
_controller.reverse();
},
child: ScaleTransition(
scale: _scaleAnimation,
child: AnimatedContainer(
duration: const Duration(milliseconds: 200),
width: width,
height: height,
padding: EdgeInsets.symmetric(
vertical: widget.isSmall ? 8 : 16,
horizontal: widget.isSmall ? 12 : 16,
),
decoration: BoxDecoration(
gradient: LinearGradient(
colors: _isTapped
? [const Color(0xFFD946EF).withOpacity(0.4), const Color(0xFF3B82F6).withOpacity(0.4)]
    : [const Color(0xFFD946EF).withOpacity(0.2), const Color(0xFF3B82F6).withOpacity(0.2)],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
borderRadius: BorderRadius.circular(16),
border: Border.all(
color: Colors.white.withOpacity(widget.isSmall ? 0.4 : 0.3),
width: _borderAnimation.value,
),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.2),
blurRadius: 12,
offset: const Offset(0, 6),
spreadRadius: 2,
),
BoxShadow(
color: Colors.white.withOpacity(widget.isSmall ? 0.2 : 0.15),
blurRadius: 16,
offset: const Offset(0, -2),
spreadRadius: 1,
),
],
),
child: widget.isSmall
? Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
widget.icon,
color: Colors.white,
size: 18,
),
const SizedBox(width: 8),
Text(
widget.text,
style: const TextStyle(
fontSize: 14,
fontWeight: FontWeight.w600,
color: Colors.white,
letterSpacing: 0.8,
),
),
],
)
    : Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
widget.icon,
color: Colors.white,
size: 32,
),
const SizedBox(height: 12),
Text(
widget.text,
textAlign: TextAlign.center,
style: const TextStyle(
fontSize: 14,
fontWeight: FontWeight.w600,
color: Colors.white,
letterSpacing: 0.8,
),
maxLines: 2,
overflow: TextOverflow.ellipsis,
),
],
),
),
),
);
}
}

class GlassmorphicIconButton extends StatefulWidget {
final IconData icon;
final VoidCallback onPressed;

const GlassmorphicIconButton({
Key? key,
required this.icon,
required this.onPressed,
}) : super(key: key);

@override
_GlassmorphicIconButtonState createState() => _GlassmorphicIconButtonState();
}

class _GlassmorphicIconButtonState extends State<GlassmorphicIconButton> with SingleTickerProviderStateMixin {
late AnimationController _controller;
late Animation<double> _scaleAnimation;
bool _isTapped = false;

@override
void initState() {
super.initState();
_controller = AnimationController(
duration: const Duration(milliseconds: 200),
vsync: this,
);
_scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
);
}

@override
void dispose() {
_controller.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return GestureDetector(
onTapDown: (_) {
setState(() => _isTapped = true);
_controller.forward();
},
onTapUp: (_) {
setState(() => _isTapped = false);
_controller.reverse();
widget.onPressed();
},
onTapCancel: () {
setState(() => _isTapped = false);
_controller.reverse();
},
child: ScaleTransition(
scale: _scaleAnimation,
child: Container(
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(
shape: BoxShape.circle,
gradient: LinearGradient(
colors: _isTapped
? [const Color(0xFFD946EF).withOpacity(0.4), const Color(0xFF3B82F6).withOpacity(0.4)]
    : [const Color(0xFFD946EF).withOpacity(0.2), const Color(0xFF3B82F6).withOpacity(0.2)],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
border: Border.all(color: Colors.white.withOpacity(0.4)),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.2),
blurRadius: 8,
offset: const Offset(0, 4),
),
],
),
child: Icon(
widget.icon,
color: Colors.white,
size: 24,
),
),
),
);
}
}
