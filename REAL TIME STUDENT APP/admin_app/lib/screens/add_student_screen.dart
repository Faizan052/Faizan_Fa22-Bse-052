import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_config.dart';

class AddStudentScreen extends StatefulWidget {
const AddStudentScreen({super.key});

@override
State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> with TickerProviderStateMixin {
final TextEditingController _nameController = TextEditingController();
final TextEditingController _emailController = TextEditingController();
final TextEditingController _passwordController = TextEditingController();

bool _isLoading = false;

late AnimationController _titleController;
late AnimationController _fieldController;
late AnimationController _buttonController;
late Animation<double> _titleFadeAnimation;
late Animation<Offset> _titleSlideAnimation;
late Animation<double> _fieldFadeAnimation;
late Animation<Offset> _fieldSlideAnimation;
late Animation<double> _buttonFadeAnimation;

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

// Field animations
_fieldController = AnimationController(
duration: const Duration(milliseconds: 700),
vsync: this,
);
_fieldFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
CurvedAnimation(parent: _fieldController, curve: Curves.easeInOut),
);
_fieldSlideAnimation = Tween<Offset>(
begin: const Offset(-0.3, 0),
end: Offset.zero,
).animate(
CurvedAnimation(parent: _fieldController, curve: Curves.easeOutCubic),
);

// Button animation
_buttonController = AnimationController(
duration: const Duration(milliseconds: 600),
vsync: this,
);
_buttonFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
);

// Start animations with slight delays for staggered effect
_titleController.forward();
Future.delayed(const Duration(milliseconds: 200), () => _fieldController.forward());
Future.delayed(const Duration(milliseconds: 400), () => _buttonController.forward());
}

@override
void dispose() {
_titleController.dispose();
_fieldController.dispose();
_buttonController.dispose();
_nameController.dispose();
_emailController.dispose();
_passwordController.dispose();
super.dispose();
}

Future<void> _addStudent() async {
setState(() {
_isLoading = true;
});

final name = _nameController.text.trim();
final email = _emailController.text.trim();
final password = _passwordController.text.trim();

if (name.isEmpty || email.isEmpty || password.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: const Text('❌ Please fill all fields'),
backgroundColor: const Color(0xFF3B82F6).withOpacity(0.8),
),
);
setState(() {
_isLoading = false;
});
return;
}

try {
// Check if admin is authenticated
final adminUser = supabase.auth.currentUser;
if (adminUser == null) {
throw Exception('Admin not authenticated. Please log in.');
}

// Check if email already exists in users table
final existingUsers = await supabase.from('users').select('email').eq('email', email);
if (existingUsers.isNotEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: const Text('❌ Email already exists'),
backgroundColor: const Color(0xFF3B82F6).withOpacity(0.8),
),
);
setState(() {
_isLoading = false;
});
return;
}

// Create user with auto-confirmation using service role
final adminClient = SupabaseClient(supabaseUrl, supabaseServiceRoleKey);
final userResponse = await adminClient.auth.admin.createUser(
AdminUserAttributes(
email: email,
password: password,
emailConfirm: true, // Auto-confirm email
userMetadata: {
'name': name,
'role': 'student',
},
),
);

final newUser = userResponse.user;
if (newUser == null) {
throw Exception('Failed to create user');
}

// Insert into users table
await supabase.from('users').insert({
'id': newUser.id,
'name': name,
'email': email,
'role': 'student',
});

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: const Text('✅ Student added and authenticated successfully!'),
backgroundColor: const Color(0xFF3B82F6).withOpacity(0.8),
),
);

// Clear fields
_nameController.clear();
_emailController.clear();
_passwordController.clear();
} catch (e) {
print('Error adding student: $e');
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('❌ Error: $e'),
backgroundColor: const Color(0xFF3B82F6).withOpacity(0.8),
),
);
} finally {
setState(() {
_isLoading = false;
});
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
body: Container(
decoration: const BoxDecoration(
gradient: LinearGradient(
colors: [Color(0xFF1E3A8A), Color(0xFF6B21A8)],
begin: Alignment.topCenter,
end: Alignment.bottomCenter,
),
),
child: SafeArea(
child: Padding(
padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
FadeTransition(
opacity: _titleFadeAnimation,
child: SlideTransition(
position: _titleSlideAnimation,
child: Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
const Icon(
Icons.person,
color: Colors.white,
size: 34,
),
const SizedBox(width: 12),
Text(
'Add Student',
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
const SizedBox(height: 40),
FadeTransition(
opacity: _fieldFadeAnimation,
child: SlideTransition(
position: _fieldSlideAnimation,
child: GlassmorphicTextField(
controller: _nameController,
labelText: 'Name',
icon: Icons.person_outlined,
),
),
),
const SizedBox(height: 20),
FadeTransition(
opacity: _fieldFadeAnimation,
child: SlideTransition(
position: _fieldSlideAnimation,
child: GlassmorphicTextField(
controller: _emailController,
labelText: 'Email',
icon: Icons.email_outlined,
),
),
),
const SizedBox(height: 20),
FadeTransition(
opacity: _fieldFadeAnimation,
child: SlideTransition(
position: _fieldSlideAnimation,
child: GlassmorphicTextField(
controller: _passwordController,
labelText: 'Password',
icon: Icons.lock_outlined,
obscureText: true,
),
),
),
const SizedBox(height: 36),
_isLoading
? const CircularProgressIndicator(
valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
)
    : FadeTransition(
opacity: _buttonFadeAnimation,
child: AnimatedGradientButton(
text: 'Add Student',
icon: Icons.person_add,
onPressed: _addStudent,
),
),
],
),
),
),
),
);
}
}

class GlassmorphicTextField extends StatelessWidget {
final TextEditingController controller;
final String labelText;
final IconData icon;
final bool obscureText;

const GlassmorphicTextField({
Key? key,
required this.controller,
required this.labelText,
required this.icon,
this.obscureText = false,
}) : super(key: key);

@override
Widget build(BuildContext context) {
return Container(
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.08),
borderRadius: BorderRadius.circular(16),
border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.2),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.1),
blurRadius: 12,
offset: const Offset(0, 6),
spreadRadius: 2,
),
],
),
child: TextField(
controller: controller,
obscureText: obscureText,
style: const TextStyle(
color: Colors.white,
fontSize: 16,
fontWeight: FontWeight.w500,
),
decoration: InputDecoration(
labelText: labelText,
labelStyle: const TextStyle(
color: Colors.white70,
fontSize: 14,
fontWeight: FontWeight.w400,
),
prefixIcon: Icon(
icon,
color: Colors.white70,
size: 22,
),
border: InputBorder.none,
contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
floatingLabelBehavior: FloatingLabelBehavior.auto,
),
),
);
}
}

class AnimatedGradientButton extends StatefulWidget {
final String text;
final IconData icon;
final VoidCallback onPressed;

const AnimatedGradientButton({
Key? key,
required this.text,
required this.icon,
required this.onPressed,
}) : super(key: key);

@override
_AnimatedGradientButtonState createState() => _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<AnimatedGradientButton> with SingleTickerProviderStateMixin {
late AnimationController _controller;
late Animation<double> _scaleAnimation;

@override
void initState() {
super.initState();
_controller = AnimationController(
duration: const Duration(milliseconds: 150),
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
onTapDown: (_) => _controller.forward(),
onTapUp: (_) {
_controller.reverse();
widget.onPressed();
},
onTapCancel: () => _controller.reverse(),
child: ScaleTransition(
scale: _scaleAnimation,
child: Container(
width: double.infinity,
padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
decoration: BoxDecoration(
gradient: const LinearGradient(
colors: [Color(0xFFD946EF), Color(0xFF3B82F6)],
begin: Alignment.centerLeft,
end: Alignment.centerRight,
),
borderRadius: BorderRadius.circular(16),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.25),
blurRadius: 8,
offset: const Offset(0, 4),
spreadRadius: 1,
),
BoxShadow(
color: Colors.white.withOpacity(0.1),
blurRadius: 12,
offset: const Offset(0, -2),
spreadRadius: 1,
),
],
),
child: Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
widget.icon,
color: Colors.white,
size: 22,
),
const SizedBox(width: 10),
Text(
widget.text,
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.w600,
color: Colors.white,
letterSpacing: 0.8,
),
),
],
),
),
),
);
}
}