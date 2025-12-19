
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/student_dashboard.dart';

class StudentLoginScreen extends StatefulWidget {
const StudentLoginScreen({super.key});

@override
State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen>
with TickerProviderStateMixin {
final emailController = TextEditingController();
final passwordController = TextEditingController();
final supabase = Supabase.instance.client;

bool isLoading = false;
String? error;
bool _isPasswordVisible = false;

// Animation controllers
late AnimationController _mainController;
late AnimationController _gradientController;
late AnimationController _buttonController;

// Animations
late Animation<double> _fadeAnimation;
late Animation<Offset> _slideAnimation;
late Animation<double> _scaleAnimation;
late Animation<double> _gradientAnimation;
late Animation<double> _buttonScaleAnimation;
late Animation<Color?> _buttonColorAnimation;

// Particle system
final List<Particle> _particles = [];
late AnimationController _particleController;

@override
void initState() {
super.initState();

// Main animation controller
_mainController = AnimationController(
duration: const Duration(milliseconds: 1500),
vsync: this,
);

// Gradient rotation controller
_gradientController = AnimationController(
duration: const Duration(seconds: 15),
vsync: this,
)..repeat();

// Button animation controller
_buttonController = AnimationController(
duration: const Duration(milliseconds: 500),
vsync: this,
);

// Particle animation
_particleController = AnimationController(
duration: const Duration(milliseconds: 2000),
vsync: this,
)..addListener(() {
_updateParticles();
});

// Set up animations
_fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
CurvedAnimation(
parent: _mainController,
curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
),
);

_slideAnimation = Tween<Offset>(
begin: const Offset(0, 0.25),
end: Offset.zero,
).animate(
CurvedAnimation(
parent: _mainController,
curve: const Interval(0.2, 0.7, curve: Curves.easeOutBack),
),
);

_scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
CurvedAnimation(
parent: _mainController,
curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
),
);

_gradientAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
CurvedAnimation(
parent: _gradientController,
curve: Curves.linear,
),
);

_buttonScaleAnimation = TweenSequence<double>(
<TweenSequenceItem<double>>[
TweenSequenceItem<double>(
tween: Tween<double>(begin: 1.0, end: 0.95),
weight: 1.0,
),
TweenSequenceItem<double>(
tween: Tween<double>(begin: 0.95, end: 1.0),
weight: 1.0,
),
],
).animate(_buttonController);

_buttonColorAnimation = ColorTween(
begin: const Color(0xFF9333EA),
end: const Color(0xFF3B82F6),
).animate(_buttonController);

// Start animations
_mainController.forward();
_generateParticles();
}

@override
void dispose() {
_mainController.dispose();
_gradientController.dispose();
_buttonController.dispose();
_particleController.dispose();
emailController.dispose();
passwordController.dispose();
super.dispose();
}

Future<void> login() async {
final email = emailController.text.trim();
final password = passwordController.text.trim();

if (email.isEmpty || password.isEmpty) {
setState(() => error = 'Please fill all fields');
return;
}

setState(() {
isLoading = true;
error = null;
});

// Button press animation
await _buttonController.forward();
await _buttonController.reverse();

try {
final response = await supabase.auth.signInWithPassword(
email: email,
password: password,
);

final user = response.user;
if (user != null) {
// Success particle explosion
_particleController.forward(from: 0);

await Future.delayed(const Duration(milliseconds: 300));

Navigator.pushReplacement(
context,
PageRouteBuilder(
pageBuilder: (_, __, ___) => StudentDashboard(userId: user.id),
transitionsBuilder: (_, animation, __, child) {
return FadeTransition(
opacity: animation,
child: SlideTransition(
position: Tween<Offset>(
begin: const Offset(0, 0.1),
end: Offset.zero,
).animate(animation),
child: child,
),
);
},
transitionDuration: const Duration(milliseconds: 800),
),
);
}
} catch (e) {
setState(() => error = 'Invalid email or password');
} finally {
setState(() => isLoading = false);
}
}

// Particle system methods
void _generateParticles() {
final random = Random();
for (int i = 0; i < 30; i++) {
_particles.add(Particle(
x: random.nextDouble() * 400 - 200,
y: random.nextDouble() * 400 - 200,
size: random.nextDouble() * 4 + 1,
speedX: random.nextDouble() * 2 - 1,
speedY: random.nextDouble() * 2 - 1,
color: Color.lerp(
const Color(0xFF3B82F6),
const Color(0xFF9333EA),
random.nextDouble(),
)!.withOpacity(0.7),
));
}
}

void _updateParticles() {
final random = Random();
for (var particle in _particles) {
particle.x += particle.speedX * 5;
particle.y += particle.speedY * 5;

// Reset particles that go off screen
if (particle.x.abs() > 200 || particle.y.abs() > 200) {
particle.x = random.nextDouble() * 100 - 50;
particle.y = random.nextDouble() * 100 - 50;
particle.speedX = random.nextDouble() * 4 - 2;
particle.speedY = random.nextDouble() * 4 - 2;
}
}
setState(() {});
}

@override
Widget build(BuildContext context) {
final size = MediaQuery.of(context).size;

return Scaffold(
body: Stack(
children: [
// Animated gradient background
AnimatedBuilder(
animation: _gradientAnimation,
builder: (context, child) {
return Container(
width: double.infinity,
height: double.infinity,
decoration: BoxDecoration(
gradient: SweepGradient(
colors: [
const Color(0xFF1E3A8A),
const Color(0xFF6B21A8),
const Color(0xFF1E3A8A),
],
stops: const [0.0, 0.5, 1.0],
center: Alignment.center,
startAngle: 0.0,
endAngle: _gradientAnimation.value * 2 * pi,
transform: GradientRotation(_gradientAnimation.value * pi),
),
),
);
},
),

// Particles
CustomPaint(
painter: ParticlePainter(particles: _particles),
size: size,
),

// Content
SafeArea(
child: Center(
child: SingleChildScrollView(
child: ScaleTransition(
scale: _scaleAnimation,
child: FadeTransition(
opacity: _fadeAnimation,
child: SlideTransition(
position: _slideAnimation,
child: Container(
width: size.width * 0.9,
padding: const EdgeInsets.all(28),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(30),
color: Colors.white.withOpacity(0.08),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.3),
blurRadius: 30,
spreadRadius: 5,
),
],
),
child: ClipRRect(
borderRadius: BorderRadius.circular(30),
child: BackdropFilter(
filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
const SizedBox(height: 10),
// Logo with animated shine
ShaderMask(
blendMode: BlendMode.srcATop,
shaderCallback: (bounds) {
return LinearGradient(
colors: [
Colors.white,
Colors.white.withOpacity(0.7),
],
stops: const [0.5, 1.0],
).createShader(bounds);
},
child: const Icon(
Icons.school_rounded,
size: 60,
color: Colors.white,
),
),
const SizedBox(height: 20),
const Text(
'Student Portal',
style: TextStyle(
fontSize: 28,
fontWeight: FontWeight.w800,
color: Colors.white,
letterSpacing: 1.5,
shadows: [
Shadow(
blurRadius: 10,
color: Colors.black38,
offset: Offset(2, 2),
),
],
),
),
const SizedBox(height: 30),
// Email field without shake animation
_buildTextField(
controller: emailController,
hintText: "University Email",
icon: Icons.email_rounded,
),
const SizedBox(height: 20),
// Password field without shake animation
_buildTextField(
controller: passwordController,
hintText: "Password",
icon: Icons.lock_rounded,
obscure: !_isPasswordVisible,
suffixIcon: IconButton(
icon: Icon(
_isPasswordVisible
? Icons.visibility_rounded
    : Icons.visibility_off_rounded,
color: Colors.white.withOpacity(0.7),
),
onPressed: () {
setState(() {
_isPasswordVisible = !_isPasswordVisible;
});
},
),
),
const SizedBox(height: 8),
// Error message
if (error != null)
Padding(
padding: const EdgeInsets.only(top: 8),
child: Text(
error!,
style: TextStyle(
color: Colors.amber[200],
fontSize: 14,
fontWeight: FontWeight.w500,
shadows: [
Shadow(
blurRadius: 5,
color: Colors.black.withOpacity(0.5),
offset: const Offset(1, 1),
),
],
),
),
),
const SizedBox(height: 24),
// Animated login button
AnimatedBuilder(
animation: _buttonController,
builder: (context, child) {
return Transform.scale(
scale: _buttonScaleAnimation.value,
child: child,
);
},
child: GestureDetector(
onTap: isLoading ? null : login,
child: Container(
height: 50,
width: double.infinity,
decoration: BoxDecoration(
gradient: LinearGradient(
colors: [
_buttonColorAnimation.value!,
Color.lerp(
const Color(0xFF9333EA),
const Color(0xFF3B82F6),
_buttonController.value,
)!,
],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
borderRadius: BorderRadius.circular(18),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.3),
blurRadius: 10,
offset: const Offset(0, 4),
),
],
),
child: Stack(
alignment: Alignment.center,
children: [
// Button text
AnimatedOpacity(
opacity: isLoading ? 0 : 1,
duration: const Duration(milliseconds: 200),
child: const Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Text(
'Sign In',
style: TextStyle(
color: Colors.white,
fontWeight: FontWeight.bold,
fontSize: 18,
letterSpacing: 1.2,
),
),
SizedBox(width: 8),
Icon(
Icons.arrow_forward_rounded,
color: Colors.white,
size: 20,
),
],
),
),
// Loading indicator
if (isLoading)
const CircularProgressIndicator(
strokeWidth: 3,
valueColor: AlwaysStoppedAnimation<Color>(
Colors.white),
),
],
),
),
),
),
const SizedBox(height: 10),
],
),
),
),
),
),
),
),
),
),
),
],
),
);
}

Widget _buildTextField({
required TextEditingController controller,
required String hintText,
required IconData icon,
bool obscure = false,
Widget? suffixIcon,
}) {
return TextField(
controller: controller,
obscureText: obscure,
style: const TextStyle(color: Colors.white),
cursorColor: Colors.white,
decoration: InputDecoration(
filled: true,
fillColor: Colors.white.withOpacity(0.1),
prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.8)),
suffixIcon: suffixIcon,
hintText: hintText,
hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
contentPadding:
const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(18),
borderSide: BorderSide.none,
),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(18),
borderSide: BorderSide(
color: Colors.white.withOpacity(0.2),
width: 1,
),
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(18),
borderSide: const BorderSide(
color: Colors.white,
width: 1.5,
),
),
),
);
}
}

// Particle system classes
class Particle {
double x;
double y;
double size;
double speedX;
double speedY;
Color color;

Particle({
required this.x,
required this.y,
required this.size,
required this.speedX,
required this.speedY,
required this.color,
});
}

class ParticlePainter extends CustomPainter {
final List<Particle> particles;

ParticlePainter({required this.particles});

@override
void paint(Canvas canvas, Size size) {
final paint = Paint()..style = PaintingStyle.fill;

for (final particle in particles) {
paint.color = particle.color;
canvas.drawCircle(
Offset(particle.x + size.width / 2, particle.y + size.height / 2),
particle.size,
paint,
);
}
}

@override
bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
