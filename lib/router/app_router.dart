import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../bootstrap.dart';
import '../screens/auth_screen.dart';
import '../screens/focus_timer_screen.dart';
import '../screens/mood_checkin_screen.dart';
import '../screens/performance_analytics_screen.dart';
import '../screens/study_dashboard_screen.dart';
import '../shell/main_shell.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

String _initialLocation() {
  if (!supabaseEnabled) return '/mood';
  return Supabase.instance.client.auth.currentSession != null ? '/mood' : '/auth';
}

GoRouter createAppRouter(Listenable? refreshListenable) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: _initialLocation(),
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      if (!supabaseEnabled) return null;
      final session = Supabase.instance.client.auth.currentSession;
      final path = state.uri.path;
      if (session == null && path != '/auth') return '/auth';
      if (session != null && path == '/auth') return '/mood';
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/mood',
        builder: (context, state) => const MoodCheckInScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: StudyDashboardScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/timer',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: FocusTimerScreen(embeddedInShell: true),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analytics',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: PerformanceAnalyticsScreen(embeddedInShell: true),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
