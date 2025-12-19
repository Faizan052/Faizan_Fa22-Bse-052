import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssignTaskScreen extends StatefulWidget {
  final Map<String, dynamic> student;

  const AssignTaskScreen({super.key, required this.student});

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _categoryController = TextEditingController();

  String _priority = 'Low';
  String _status = 'Pending'; // Must match enum in Supabase
  DateTime? _dueDate;
  bool isLoading = false;
  String? error;

  final supabase = Supabase.instance.client;

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
  }

  @override
  void dispose() {
    _mainController.dispose();
    _gradientController.dispose();
    _buttonController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _assignTask() async {
    if (!_formKey.currentState!.validate() || _dueDate == null) {
      setState(() => error = 'Please complete all fields');
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
      await supabase.from('tasks').insert({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'assigned_to': widget.student['id'],
        'status': _status,
        'due_date': _dueDate!.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'category': _categoryController.text.trim(),
        'priority': _priority,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Task assigned successfully!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => error = 'Failed to assign task: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentName = widget.student['name'] ?? 'Unknown Student';
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
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 10),
                                  // Title with animated shine
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
                                    child: Text(
                                      '📌 Assign Task to $studentName',
                                      style: const TextStyle(
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
                                  ),
                                  const SizedBox(height: 30),
                                  // Task Title
                                  _buildTextField(
                                    controller: _titleController,
                                    hintText: 'Task Title',
                                    icon: Icons.title_rounded,
                                    validator: (value) =>
                                    value!.isEmpty ? 'Enter task title' : null,
                                  ),
                                  const SizedBox(height: 20),
                                  // Task Description
                                  _buildTextField(
                                    controller: _descController,
                                    hintText: 'Task Description',
                                    icon: Icons.description_rounded,
                                    maxLines: 3,
                                    validator: (value) =>
                                    value!.isEmpty ? 'Enter description' : null,
                                  ),
                                  const SizedBox(height: 20),
                                  // Category
                                  _buildTextField(
                                    controller: _categoryController,
                                    hintText: 'Category',
                                    icon: Icons.category_rounded,
                                    validator: (value) =>
                                    value!.isEmpty ? 'Enter category' : null,
                                  ),
                                  const SizedBox(height: 20),
                                  // Priority Dropdown
                                  _buildDropdown(
                                    value: _priority,
                                    hintText: 'Priority',
                                    icon: Icons.priority_high_rounded,
                                    items: ['Low', 'Medium', 'High'],
                                    onChanged: (val) => setState(() => _priority = val!),
                                  ),
                                  const SizedBox(height: 20),
                                  // Status Dropdown
                                  _buildDropdown(
                                    value: _status,
                                    hintText: 'Status',
                                    icon: Icons.flag_rounded,
                                    items: ['Pending', 'Completed'],
                                    onChanged: (val) => setState(() => _status = val!),
                                  ),
                                  const SizedBox(height: 20),
                                  // Due Date
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _dueDate == null
                                              ? 'No deadline selected'
                                              : 'Deadline: ${_dueDate!.toLocal().toString().split(' ')[0]}',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _pickDueDate(context),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(18),
                                            color: Colors.white.withOpacity(0.1),
                                          ),
                                          child: Text(
                                            'Pick Deadline',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.8),
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
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
                                  // Assign Task Button
                                  AnimatedBuilder(
                                    animation: _buttonController,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _buttonScaleAnimation.value,
                                        child: child,
                                      );
                                    },
                                    child: GestureDetector(
                                      onTap: isLoading ? null : _assignTask,
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
                                            AnimatedOpacity(
                                              opacity: isLoading ? 0 : 1,
                                              duration: const Duration(milliseconds: 200),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Text(
                                                    'Assign Task',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 18,
                                                      letterSpacing: 1.2,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Icon(
                                                    Icons.check_rounded,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ],
                                              ),
                                            ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.8)),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
        errorStyle: TextStyle(
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
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String value,
    required String hintText,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      style: const TextStyle(color: Colors.white),
      dropdownColor: Colors.white.withOpacity(0.1),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.8)),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
        errorStyle: TextStyle(
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
      items: items
          .map((val) => DropdownMenuItem(
        value: val,
        child: Text(
          val,
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
      ))
          .toList(),
      onChanged: onChanged,
    );
  }
}