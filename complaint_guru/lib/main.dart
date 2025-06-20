import 'package:flutter/material.dart';

void main() {
  runApp(ReelsApp());
}

class ReelsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Reels',
      debugShowCheckedModeBanner: false,
      home: ReelsScreen(),
    );
  }
}

class ReelsScreen extends StatelessWidget {
  final List<Map<String, String>> reels = [
    {
      'user': 'user_1',
      'caption': 'Enjoying the sunset 🌅',
      'bg': 'https://picsum.photos/id/1018/800/1600',
    },
    {
      'user': 'cool_dude',
      'caption': 'Weekend vibes 😎',
      'bg': 'https://picsum.photos/id/1015/800/1600',
    },
    {
      'user': 'traveler_girl',
      'caption': 'Wandering in nature 🌿',
      'bg': 'https://picsum.photos/id/1016/800/1600',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: reels.length,
        itemBuilder: (context, index) {
          final reel = reels[index];
          return Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              Image.network(
                reel['bg']!,
                fit: BoxFit.cover,
              ),
              // Dark gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.3), Colors.black],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${reel['user']}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      reel['caption']!,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
              // Right-side icons
              Positioned(
                right: 16,
                bottom: 100,
                child: Column(
                  children: [
                    Icon(Icons.favorite, color: Colors.white, size: 32),
                    SizedBox(height: 16),
                    Icon(Icons.comment, color: Colors.white, size: 32),
                    SizedBox(height: 16),
                    Icon(Icons.share, color: Colors.white, size: 32),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
