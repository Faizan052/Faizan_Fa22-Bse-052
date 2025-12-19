import 'package:flutter/material.dart';

class AnimatedGradientButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isLoading;

  const AnimatedGradientButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

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
      onTapDown: widget.isLoading ? null : (_) => _controller.forward(),
      onTapUp: widget.isLoading
          ? null
          : (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: widget.isLoading ? null : () => _controller.reverse(),
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
          child: widget.isLoading
              ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : Row(
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