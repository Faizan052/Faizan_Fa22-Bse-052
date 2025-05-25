
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class MessagingScreen extends StatefulWidget {
const MessagingScreen({Key? key}) : super(key: key);

@override
State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
final supabase = Supabase.instance.client;
List<dynamic> _students = [];
Map<String, dynamic>? _selectedStudent;
List<dynamic> _messages = [];
bool _isLoadingStudents = false;
bool _isLoadingMessages = false;
String? _error;
final TextEditingController _messageController = TextEditingController();
StreamSubscription? _messageSubscription;
final ScrollController _scrollController = ScrollController();

@override
void initState() {
super.initState();
_fetchStudents();
}

@override
void dispose() {
_messageSubscription?.cancel();
_messageController.dispose();
_scrollController.dispose();
super.dispose();
}

Future<void> _fetchStudents() async {
setState(() {
_isLoadingStudents = true;
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
});
} finally {
setState(() {
_isLoadingStudents = false;
});
}
}

Future<void> _selectStudent(Map<String, dynamic> student) async {
setState(() {
_selectedStudent = student;
_messages = [];
_isLoadingMessages = true;
_error = null;
});

_messageSubscription?.cancel();

try {
final userId = supabase.auth.currentUser?.id;
if (userId == null) {
throw Exception('No authenticated user. Please log in.');
}

final response = await supabase
    .from('messages')
    .select()
    .or('sender_id.eq.$userId,receiver_id.eq.$userId')
    .eq('receiver_id', student['id'])
    .order('sent_at', ascending: true);

setState(() {
_messages = response;
});

_messageSubscription = supabase
    .from('messages')
    .stream(primaryKey: ['id'])
    .listen((List<Map<String, dynamic>> messages) {
setState(() {
_messages = messages
    .where((msg) =>
(msg['sender_id'] == userId && msg['receiver_id'] == student['id']) ||
(msg['sender_id'] == student['id'] && msg['receiver_id'] == userId))
    .toList()
..sort((a, b) => a['sent_at'].compareTo(b['sent_at']));
});
WidgetsBinding.instance.addPostFrameCallback((_) {
_scrollController.animateTo(
_scrollController.position.maxScrollExtent,
duration: const Duration(milliseconds: 300),
curve: Curves.easeOut,
);
});
});
} catch (e) {
setState(() {
_error = 'Error loading messages: $e';
_messages = [];
});
} finally {
setState(() {
_isLoadingMessages = false;
});
}
}

Future<void> _sendMessage() async {
final content = _messageController.text.trim();
if (content.isEmpty || _selectedStudent == null) return;

try {
final userId = supabase.auth.currentUser?.id;
if (userId == null) {
throw Exception('No authenticated user. Please log in.');
}

await supabase.from('messages').insert({
'sender_id': userId,
'receiver_id': _selectedStudent!['id'],
'content': content,
'sent_at': DateTime.now().toIso8601String(),
});

_messageController.clear();
WidgetsBinding.instance.addPostFrameCallback((_) {
_scrollController.animateTo(
_scrollController.position.maxScrollExtent,
duration: const Duration(milliseconds: 300),
curve: Curves.easeOut,
);
});

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('✅ Message sent')),
);
} catch (e) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('❌ Error sending message: $e')),
);
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: Text(
_selectedStudent == null ? 'Messages' : 'Chat with ${_selectedStudent!['name']}',
style: const TextStyle(
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
child: _selectedStudent == null
? _buildStudentList()
    : _buildChatInterface(),
),
);
}

Widget _buildStudentList() {
return _isLoadingStudents
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
    : ListView.builder(
itemCount: _students.length,
itemBuilder: (context, index) {
final student = _students[index];
final name = student['name'] ?? 'No Name';
final email = student['email'] ?? 'No Email';

return Card(
margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
elevation: 8,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
borderRadius: BorderRadius.circular(12),
border: Border.all(
color: Colors.black.withOpacity(0.2),
width: 1,
),
),
child: InkWell(
onTap: () => _selectStudent(student),
child: Padding(
padding: const EdgeInsets.all(12.0),
child: Row(
children: [
CircleAvatar(
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
name[0].toUpperCase(),
style: const TextStyle(
color: Colors.black,
fontSize: 20,
fontWeight: FontWeight.bold,
),
),
),
),
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
name,
style: const TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
color: Colors.black,
shadows: [
Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2),
],
),
),
Text(
email,
style: TextStyle(
fontSize: 14,
color: Colors.black87,
fontStyle: FontStyle.italic,
),
),
],
),
),
const Icon(
Icons.chat,
color: Color(0xFF3B82F6),
size: 28,
),
],
),
),
),
),
);
},
);
}

Widget _buildChatInterface() {
return Column(
children: [
Expanded(
child: Container(
decoration: BoxDecoration(
gradient: LinearGradient(
colors: [Colors.black.withOpacity(0.05), Colors.black.withOpacity(0.15)],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
),
child: _isLoadingMessages
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
    : ListView.builder(
controller: _scrollController,
itemCount: _messages.length,
itemBuilder: (context, index) {
final message = _messages[index];
final isSentByAdmin = message['sender_id'] == supabase.auth.currentUser?.id;

return Align(
alignment: isSentByAdmin ? Alignment.centerRight : Alignment.centerLeft,
child: Container(
margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
gradient: isSentByAdmin
? const LinearGradient(
colors: [Color(0xFF3B82F6), Color(0xFFD946EF)],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
)
    : const LinearGradient(
colors: [Colors.grey, Colors.grey],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
borderRadius: BorderRadius.circular(12),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.2),
blurRadius: 8,
offset: const Offset(0, 2),
),
],
),
child: Column(
crossAxisAlignment: isSentByAdmin
? CrossAxisAlignment.end
    : CrossAxisAlignment.start,
children: [
Text(
message['content'],
style: const TextStyle(color: Colors.black, fontSize: 16),
),
const SizedBox(height: 4),
Text(
_formatTimestamp(message['sent_at']),
style: TextStyle(
color: Colors.grey.shade300,
fontSize: 12,
fontStyle: FontStyle.italic,
),
),
],
),
),
);
},
),
),
),
_buildMessageInput(),
],
);
}

Widget _buildMessageInput() {
return Container(
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(
gradient: const LinearGradient(
colors: [Colors.black, Colors.black],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
border: Border(top: BorderSide(color: Colors.grey.shade600)),
),
child: Row(
children: [
Expanded(
child: TextField(
controller: _messageController,
decoration: InputDecoration(
hintText: 'Type a message...',
hintStyle: TextStyle(color: Colors.grey.shade400),
filled: true,
fillColor: Colors.white.withOpacity(0.2),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: BorderSide.none,
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
),
),
style: const TextStyle(color: Colors.white),
onSubmitted: (_) => _sendMessage(),
),
),
const SizedBox(width: 8),
IconButton(
icon: const Icon(Icons.send, color: Colors.black),
onPressed: _sendMessage,
splashRadius: 24,
style: IconButton.styleFrom(
backgroundColor: const Color(0xFF3B82F6),
padding: const EdgeInsets.all(12),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
elevation: 4,
),
),
],
),
);
}

String _formatTimestamp(String timestamp) {
final dateTime = DateTime.parse(timestamp).toLocal();
return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}';
}
}
