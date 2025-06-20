import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../lib/main.dart';
import '../lib/providers.dart';

void main() {
  setUpAll(() async {
    // Initialize Supabase for testing
    await Supabase.initialize(
      url: 'https://vgxztzhbiljfgewfokkj.supabase.co', // Replace with your Supabase URL
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZneHp0emhiaWxqZmdld2Zva2tqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk5NzYxNjAsImV4cCI6MjA2NTU1MjE2MH0.yBWDxXOH5qdOIezTnZLUFfy4tQ6PZ3X4uJE-sazM2DY', // Replace with your Supabase Anon Key
    );
  });

  testWidgets('SplashScreen displays CircularProgressIndicator', (WidgetTester tester) async {
    // Build the app with providers
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ComplaintProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // Allow async operations to complete
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Verify that the SplashScreen shows a CircularProgressIndicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Smart Complaint System'), findsNothing); // Not on SplashScreen
  });
}