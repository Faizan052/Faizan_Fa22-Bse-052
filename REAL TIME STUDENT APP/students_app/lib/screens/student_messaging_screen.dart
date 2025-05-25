
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessagingScreen extends StatefulWidget {
final String userId;
const MessagingScreen({super.key, required this.userId});

@override
State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
final supabase = Supabase.instance.client;
List<Map<String, dynamic>> messages = [];
bool isLoading = false;
String? error;
final TextEditingController messageController = TextEditingController();
StreamSubscription<List<Map<String, dynamic>>>? messageSubscription;
final ScrollController scrollController = ScrollController();

@override
void initState() {
super.initState();
_fetchMessages();
}

@override
void dispose() {
messageSubscription?.cancel();
messageController.dispose();
scrollController.dispose();
super.dispose();
}

Future<void> _fetchMessages() async {
setState(() {
isLoading = true;
error = null;
});

try {
final adminResponse = await supabase.from('users').select('id').eq('role', 'admin').single();
final adminId = adminResponse['id'];

final response = await supabase
    .from('messages')
    .select()
    .or('and(sender_id.eq.${widget.userId},receiver_id.eq.$adminId),and(sender_id.eq.$adminId,receiver_id.eq.${widget.userId})')
    .order('sent_at', ascending: true);

setState(() {
messages = List<Map<String, dynamic>>.from(response);
});

messageSubscription?.cancel();
messageSubscription = supabase
    .from('messages')
    .stream(primaryKey: ['id'])
    .listen((List<Map<String, dynamic>> updatedMessages) {
setState(() {
messages = updatedMessages
    .where((msg) =>
(msg['sender_id'] == widget.userId && msg['receiver_id'] == adminId) ||
(msg['sender_id'] == adminId && msg['receiver_id'] == widget.userId))
    .toList()
..sort((a, b) => a['sent_at'].compareTo(b['sent_at']));
});
WidgetsBinding.instance.addPostFrameCallback((_) {
scrollController.animateTo(
scrollController.position.maxScrollExtent,
duration: const Duration(milliseconds: 300),
curve: Curves.easeOut,
);
});
});
} catch (e) {
setState(() => error = 'Error loading messages: $e');
} finally {
setState(() => isLoading = false);
}
}

Future<void> _sendMessage() async {
final content = messageController.text.trim();
if (content.isEmpty) return;

try {
final adminResponse = await supabase.from('users').select('id').eq('role', 'admin').single();
final adminId = adminResponse['id'];

await supabase.from('messages').insert({
'sender_id': widget.userId,
'receiver_id': adminId,
'content': content,
'sent_at': DateTime.now().toIso8601String(),
});

messageController.clear();
WidgetsBinding.instance.addPostFrameCallback((_) {
scrollController.animateTo(
scrollController.position.maxScrollExtent,
duration: const Duration(milliseconds: 300),
curve: Curves.easeOut,
);
});

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: const Text('✅ Message sent'),
backgroundColor: const Color(0xFF3B82F6).withOpacity(0.8),
),
);
} catch (e) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('❌ Error sending message: $e'),
backgroundColor: const Color(0xFF3B82F6).withOpacity(0.8),
),
);
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('Chat with Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
elevation: 6,
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
padding: const EdgeInsets.all(8.0),
child: ShaderMask(
blendMode: BlendMode.srcATop,
shaderCallback: (bounds) => const LinearGradient(
colors: [Color(0xFF3B82F6), Color(0xFFD946EF)],
).createShader(bounds),
child: const Icon(Icons.admin_panel_settings, size: 28, color: Colors.white),
),
),
],
),
body: Container(
decoration: BoxDecoration(
gradient: LinearGradient(
colors: [const Color(0xFF1E3A8A), const Color(0xFF6B21A8)],
begin: Alignment.topCenter,
end: Alignment.bottomCenter,
),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.1),
blurRadius: 20,
spreadRadius: 5,
),
],
),
child: Column(
children: [
Expanded(
child: isLoading
? const Center(child: CircularProgressIndicator(color: Colors.white))
    : error != null
? Center(
child: Text(
error!,
style: const TextStyle(color: Colors.redAccent, fontSize: 16, shadows: [
Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 3),
]),
),
)
    : messages.isEmpty
? const Center(
child: Text(
'No messages yet.',
style: TextStyle(color: Colors.white70, fontSize: 18, fontStyle: FontStyle.italic),
),
)
    : ListView.builder(
controller: scrollController,
itemCount: messages.length,
itemBuilder: (context, index) {
final message = messages[index];
final isSentByStudent = message['sender_id'] == widget.userId;

return Align(
alignment: isSentByStudent ? Alignment.centerRight : Alignment.centerLeft,
child: Container(
margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
padding: const EdgeInsets.all(14.0),
decoration: BoxDecoration(
gradient: isSentByStudent
? LinearGradient(
colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
)
    : LinearGradient(
colors: [Colors.grey.shade700, Colors.grey.shade800],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
borderRadius: BorderRadius.circular(16),
boxShadow: [
BoxShadow(
color: isSentByStudent ? Color(0xFF3B82F6).withOpacity(0.3) : Colors.grey.shade900.withOpacity(0.3),
blurRadius: 10,
offset: const Offset(0, 4),
),
],
),
child: Column(
crossAxisAlignment: isSentByStudent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
children: [
Text(
message['content'],
style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
),
const SizedBox(height: 6),
Text(
_formatTimestamp(message['sent_at']),
style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w400),
),
],
),
),
);
},
),
),
_buildMessageInput(),
],
),
),
);
}

Widget _buildMessageInput() {
return Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
gradient: LinearGradient(
colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.15)],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
border: Border(top: BorderSide(color: Colors.white.withOpacity(0.3), width: 1.5)),
),
child: Row(
children: [
Expanded(
child: TextField(
controller: messageController,
style: const TextStyle(color: Colors.white, fontSize: 16),
decoration: InputDecoration(
hintText: 'Type a message...',
hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
filled: true,
fillColor: Colors.white.withOpacity(0.1),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(20),
borderSide: BorderSide.none,
),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(20),
borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(20),
borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
),
),
onSubmitted: (_) => _sendMessage(),
),
),
const SizedBox(width: 12),
ElevatedButton(
style: ElevatedButton.styleFrom(
backgroundColor: const Color(0xFF3B82F6),
shape: const CircleBorder(),
padding: const EdgeInsets.all(12),
elevation: 8,
),
onPressed: _sendMessage,
child: const Icon(Icons.send, color: Colors.white, size: 24),
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
