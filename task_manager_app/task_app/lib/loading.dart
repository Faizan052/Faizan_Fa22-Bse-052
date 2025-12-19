import 'package:flutter/material.dart';
import 'home.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  _LoadingPageState createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isDarkMode = false; // Added to match home page theme logic

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              return SlideTransition(position: offsetAnimation, child: child);
            },
            transitionDuration: const Duration(seconds: 1),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isDarkMode
                ? [Colors.indigo[900]!, Colors.teal[800]!] // Dark mode colors
                : [Colors.blue[800]!, Colors.teal[600]!], // Light mode colors
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Icon(
                      Icons.task_alt,
                      size: 100,
                      color: _isDarkMode ? Colors.white : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Task Manager',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black45,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Loading your tasks...',
                    style: TextStyle(
                      fontSize: 18,
                      color: _isDarkMode ? Colors.white70 : Colors.white70,
                      shadows: const [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black45,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Footer with copyright
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '© 2025 Task Manager. All rights reserved.',
                  style: TextStyle(
                    fontSize: 14,
                    color: _isDarkMode ? Colors.white70 : Colors.white70,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}