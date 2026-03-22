import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../bootstrap.dart';

final dioProvider = Provider<Dio>((ref) {
  final base = dotenv.env['API_BASE_URL']?.trim().isNotEmpty == true
      ? dotenv.env['API_BASE_URL']!.trim()
      : 'http://127.0.0.1:8000';
  final dio = Dio(
    BaseOptions(
      baseUrl: base,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (supabaseEnabled) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            options.headers['Authorization'] = 'Bearer ${session.accessToken}';
          }
        }
        handler.next(options);
      },
    ),
  );
  return dio;
});
