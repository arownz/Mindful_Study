import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../bootstrap.dart';
import '../services/dio_client.dart';

/// Latest study plan JSON from API or [buildLocalPlan].
final studyPlanProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);

final analyticsSummaryProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  if (!supabaseEnabled) return null;
  if (Supabase.instance.client.auth.currentSession == null) return null;
  final Dio dio = ref.read(dioProvider);
  try {
    final r = await dio.get<Map<String, dynamic>>('/analytics/summary');
    return r.data;
  } catch (_) {
    return null;
  }
});
