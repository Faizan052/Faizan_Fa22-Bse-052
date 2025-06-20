import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('app_icon');
    const InitializationSettings settings =
    InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(settings);
  }

  void setupRealtimeNotifications(String userId) {
    _supabase
        .channel('complaint_history')
        .on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'INSERT',
        schema: 'public',
        table: 'complaint_history',
      ),
          (payload, [ref]) async {
        final complaintId = payload['new']['complaint_id'];
        final complaint = await _supabase
            .from('complaints')
            .select()
            .eq('id', complaintId)
            .single();
        if (complaint['student_id'] == userId ||
            complaint['advisor_id'] == userId ||
            complaint['hod_id'] == userId) {
          _showNotification(
            'Complaint Updated',
            'Complaint "${complaint['title']}" has a new update: ${payload['new']['action']}',
          );
        }
      },
    )
        .subscribe();
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'complaint_channel',
      'Complaint Updates',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(0, title, body, details);
  }
}