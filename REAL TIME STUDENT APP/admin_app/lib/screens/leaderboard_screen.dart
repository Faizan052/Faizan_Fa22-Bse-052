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
      const LinearGradient(
        colors: [Color(0xFF9333EA), Color(0xFF3B82F6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFFC0C0C0), Color(0xFF808080)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFFCD7F32), Color(0xFF8C5523)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ];
    final heights = [160.0, 120.0, 100.0];

    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (index) {
                if (index >= _leaderboardData.length) {
                  return const SizedBox(width: 60);
                }

                final student = _leaderboardData[index];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
                        student['name'],
                        style: const TextStyle(
                          fontSize: 16,
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
                    Container(
                      width: 60,
                      height: heights[index],
                      decoration: BoxDecoration(
                        gradient: podiumGradients[index],
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}\n${student['completed']}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
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

    return ListView.builder(
      itemCount: _leaderboardData.length - 3,
      itemBuilder: (context, index) {
        final student = _leaderboardData[index + 3];
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.transparent,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF9333EA), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 4}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              title: Text(
                student['name'],
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              trailing: Text(
                '${student['completed']} completed',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
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
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                                // Title
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
                                  child: const Text(
                                    '🏆 Student Leaderboard',
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
                                ),
                                const SizedBox(height: 30),
                                // Top 3 Performers
                                Text(
                                  '🏆 Top 3 Performers',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white.withOpacity(0.8),
                                    shadows: [
                                      Shadow(
                                        blurRadius: 5,
                                        color: Colors.black.withOpacity(0.3),
                                        offset: const Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildPodium(),
                                const Divider(
                                  height: 32,
                                  color: Colors.white24,
                                ),
                                // Other Rankings
                                Text(
                                  '📋 Other Rankings',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white.withOpacity(0.8),
                                    shadows: [
                                      Shadow(
                                        blurRadius: 5,
                                        color: Colors.black.withOpacity(0.3),
                                        offset: const Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: size.height * 0.3,
                                  child: _buildRankingList(),
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
}