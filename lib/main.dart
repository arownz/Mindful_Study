import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'bootstrap.dart';
import 'router/app_router.dart';
import 'router/auth_refresh.dart';
import 'services/push_service.dart';
import 'theme.dart';

late final GoRouter _appRouter;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrap();
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await initPush();
  }
  GoRouterRefreshStream? refresh;
  if (supabaseEnabled) {
    refresh = GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    );
  }
  _appRouter = createAppRouter(refresh);
  runApp(const ProviderScope(child: IStudyBuddyApp()));
}

class IStudyBuddyApp extends StatelessWidget {
  const IStudyBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mindful Study',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: _appRouter,
    );
  }
}
