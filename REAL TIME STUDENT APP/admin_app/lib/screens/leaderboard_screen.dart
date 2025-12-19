import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _leaderboardData = [];
  bool _isLoading = true;
  String? _error;

  // Animation controllers
  late AnimationController _mainController;
  late AnimationController _gradientController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _gradientAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _gradientController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

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

    // Start animations
    _mainController.forward();
    fetchLeaderboardData();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  Future<void> fetchLeaderboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final students = await supabase
          .from('users')
          .select('id, name')
          .eq('role', 'student');

      final taskCounts = <String, int>{};

      for (var student in students) {
        final tasks = await supabase
            .from('tasks')
            .select('status')
            .eq('assigned_to', student['id'])
            .eq('status', 'Completed');

        taskCounts[student['id']] = tasks.length;
      }

      _leaderboardData = students.map<Map<String, dynamic>>((student) {
        return {
          'name': student['name'] ?? 'Unnamed',
          'completed': taskCounts[student['id']] ?? 0,
        };
      }).toList();

      _leaderboardData.sort((a, b) => b['completed'].compareTo(a['completed']));
    } catch (e) {
      _error = 'Error loading leaderboard: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildPodium() {
    final podiumGradients = [
      LinearGradient(
        colors: [Color(0xFF9333EA), Color(0xFF3B82F6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [0.1, 0.9],
      ),
      LinearGradient(
        colors: [Color(0xFFC0C0C0), Color(0xFF808080)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [0.1, 0.9],
      ),
      LinearGradient(
        colors: [Color(0xFFCD7F32), Color(0xFF8C5523)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [0.1, 0.9],
      ),
    ];
    final heights = [180.0, 140.0, 120.0];
    final iconSizes = [48.0, 36.0, 32.0];
    final medals = ['🥇', '🥈', '🥉'];

    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(3, (index) {
                if (index >= _leaderboardData.length) {
                  return const SizedBox(width: 80);
                }

                final student = _leaderboardData[index];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Medal icon
                    Container(
                      width: iconSizes[index],
                      height: iconSizes[index],
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          medals[index],
                          style: TextStyle(fontSize: iconSizes[index] * 0.7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Name
                    Container(
                      constraints: BoxConstraints(maxWidth: 80),
                      child: Text(
                        student['name'],
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 5,
                              color: Colors.black38,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Podium
                    Container(
                      width: 80,
                      height: heights[index],
                      decoration: BoxDecoration(
                        gradient: podiumGradients[index],
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${student['completed']}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              shadows: [
                                Shadow(
                                  blurRadius: 5,
                                  color: Colors.black38,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'tasks',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRankingList() {
    if (_leaderboardData.length <= 3) return const SizedBox();

    return ListView.separated(
      itemCount: _leaderboardData.length - 3,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: Colors.white.withOpacity(0.1),
      ),
      itemBuilder: (context, index) {
        final student = _leaderboardData[index + 3];
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0.5, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _mainController,
                curve: Interval(
                  0.5 + (index * 0.1),
                  1.0,
                  curve: Curves.easeOut,
                ),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 4}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      student['name'],
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${student['completed']} tasks',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _gradientAnimation,
            builder: (context, _) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFF1E3A8A).withOpacity(0.8),
                      Color(0xFF6B21A8).withOpacity(0.8),
                    ],
                    center: Alignment.topLeft,
                    radius: 1.5,
                    stops: [0.0, 1.0],
                    transform: GradientRotation(_gradientAnimation.value * pi),
                  ),
                ),
              );
            },
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.8)),
                ),
              )
                  : _error != null
                  ? Center(
                child: Text(
                  _error!,
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
              )
                  : SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Title
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            Text(
                              'Student Leaderboard',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(
                                    blurRadius: 10,
                                    color: Colors.black38,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Top performers based on completed tasks',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.8),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Podium
                    _buildPodium(),
                    const SizedBox(height: 32),
                    // Rankings title
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Text(
                          'All Rankings',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Rankings list
                    SizedBox(
                      height: size.height * 0.35,
                      child: _buildRankingList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}