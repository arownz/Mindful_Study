import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../bootstrap.dart';

final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

/// Initializes Firebase Messaging (mobile), local notifications, and syncs FCM token to Supabase.
Future<void> initPush() async {
  if (kIsWeb) return;
  if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    return;
  }

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init skipped (add Firebase config): $e');
    return;
  }

  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();
  await _local.initialize(
    settings: const InitializationSettings(android: android, iOS: ios),
  );

  final androidPlugin = _local.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.createNotificationChannel(
    const AndroidNotificationChannel(
      'study_reminders',
      'Study reminders',
      description: 'Focus and reminder notifications',
      importance: Importance.defaultImportance,
    ),
  );

  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  FirebaseMessaging.onMessage.listen((RemoteMessage msg) async {
    final title = msg.notification?.title ?? 'I Study Buddy';
    final body = msg.notification?.body ?? '';
    const androidDetails = AndroidNotificationDetails(
      'study_reminders',
      'Study reminders',
      channelDescription: 'Focus and reminder notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    await _local.show(
      id: msg.hashCode,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  });

  final token = await messaging.getToken();
  if (token == null) return;
  if (!supabaseEnabled) return;
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) return;
  final uid = Supabase.instance.client.auth.currentUser!.id;
  try {
    await Supabase.instance.client.from('device_tokens').upsert({
      'user_id': uid,
      'token': token,
      'platform': defaultTargetPlatform.name,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'token');
  } catch (e) {
    debugPrint('device_tokens upsert failed: $e');
  }
}

/// Call after sign-in so the FCM token is stored when the session was not present at cold start.
Future<void> trySyncFcmToken() async {
  if (kIsWeb) return;
  if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    return;
  }
  try {
    await Firebase.initializeApp();
  } catch (_) {
    return;
  }
  if (!supabaseEnabled) return;
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) return;
  final token = await FirebaseMessaging.instance.getToken();
  if (token == null) return;
  final uid = Supabase.instance.client.auth.currentUser!.id;
  try {
    await Supabase.instance.client.from('device_tokens').upsert({
      'user_id': uid,
      'token': token,
      'platform': defaultTargetPlatform.name,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'token');
  } catch (e) {
    debugPrint('trySyncFcmToken failed: $e');
  }
}
