import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<String?> errorMsg = ValueNotifier(null);
  bool _obscure = true;
  bool _showLoginForm = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Configure animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
      ),
    );

    // Start animation sequence
    _animationController.forward().whenComplete(() {
      setState(() {
        _showLoginForm = true;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    loading.dispose();
    errorMsg.dispose();
    super.dispose();
  }

  Widget _buildWelcomeAnimation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.2).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
                ),
              ),
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Text(
                "Welcome to\nComplaint Guru",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  height: 1.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Text(
                "Smart Complaint Management System",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 380;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4F8FFF), Color(0xFF1CB5E0), Color(0xFF0F2027)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.1, 0.5, 0.9],
            ),
          ),
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _showLoginForm
                  ? SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: size.height - MediaQuery.of(context).padding.vertical,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Hero(
                        tag: 'logo',
                        child: CircleAvatar(
                          radius: isSmallScreen ? 40 : 48,
                          backgroundColor: Colors.white.withOpacity(0.15),
                          child: Icon(
                            Icons.security_rounded,
                            size: isSmallScreen ? 52 : 64,
                            color: Colors.white.withOpacity(0.95),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 16,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // App Name with Gradient
                                ShaderMask(
                                  shaderCallback: (rect) => const LinearGradient(
                                    colors: [Color(0xFF4F8FFF), Color(0xFF1CB5E0)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(rect),
                                  child: Text(
                                    "Complaint Guru",
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 26 : 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Login to your account",
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 20 : 28),

                                // Email Field
                                TextFormField(
                                  controller: emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [AutofillHints.email],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.email_rounded, color: const Color(0xFF4F8FFF)),
                                    labelText: "Email",
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: isSmallScreen ? 14 : 16,
                                      horizontal: 16,
                                    ),
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 16 : 20),

                                // Password Field
                                TextFormField(
                                  controller: passCtrl,
                                  obscureText: _obscure,
                                  autofillHints: const [AutofillHints.password],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.lock_rounded, color: const Color(0xFF4F8FFF)),
                                    labelText: "Password",
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: isSmallScreen ? 14 : 16,
                                      horizontal: 16,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                        color: const Color(0xFF4F8FFF).withOpacity(0.7),
                                        size: 22,
                                      ),
                                      onPressed: () => setState(() => _obscure = !_obscure),
                                      splashRadius: 20,
                                    ),
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 24 : 32),

                                // Login Button
                                ValueListenableBuilder<bool>(
                                  valueListenable: loading,
                                  builder: (context, isLoading, _) => SizedBox(
                                    width: double.infinity,
                                    height: isSmallScreen ? 48 : 52,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF4F8FFF),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        elevation: 6,
                                        shadowColor: const Color(0xFF1CB5E0).withOpacity(0.3),
                                        padding: EdgeInsets.zero,
                                      ),
                                      onPressed: isLoading
                                          ? null
                                          : () async {
                                        if (_formKey.currentState?.validate() ?? false) {
                                          FocusScope.of(context).unfocus();
                                          loading.value = true;
                                          errorMsg.value = null;
                                          try {
                                            await auth.signIn(emailCtrl.text.trim(), passCtrl.text);
                                            final role = auth.user?.role;
                                            switch (role) {
                                              case 'student':
                                                Navigator.pushReplacementNamed(context, AppRoutes.studentDash);
                                                break;
                                              case 'batch_advisor':
                                                Navigator.pushReplacementNamed(context, AppRoutes.advisorDash);
                                                break;
                                              case 'hod':
                                                Navigator.pushReplacementNamed(context, AppRoutes.hodDash);
                                                break;
                                              case 'admin':
                                                Navigator.pushReplacementNamed(context, AppRoutes.adminDash);
                                                break;
                                              default:
                                                errorMsg.value = "Unknown role: ${role ?? ''}";
                                            }
                                          } catch (e) {
                                            errorMsg.value = "Login failed. Please check your credentials.";
                                          } finally {
                                            loading.value = false;
                                          }
                                        }
                                      },
                                      child: isLoading
                                          ? SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                          : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.login_rounded, color: Colors.white, size: 22),
                                          const SizedBox(width: 10),
                                          Text(
                                            "Login",
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 16 : 18,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 14 : 18),

                                // Error Message
                                ValueListenableBuilder<String?>(
                                  valueListenable: errorMsg,
                                  builder: (context, msg, _) => AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: msg == null
                                        ? const SizedBox.shrink()
                                        : Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.red[100]!),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.error_outline, color: Colors.red[400], size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              msg,
                                              style: TextStyle(
                                                color: Colors.red[700],
                                                fontSize: isSmallScreen ? 13 : 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 16 : 20),

                                // Footer Text
                                Text(
                                  "Smart Complaint Management System",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 13 : 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : _buildWelcomeAnimation(),
            ),
          ),
        ),
      ),
    );
  }
}