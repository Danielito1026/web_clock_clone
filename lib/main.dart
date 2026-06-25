import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_clock_clone/app/routes.dart';
import 'package:web_clock_clone/lifecycle/app_lifecycle_observer.dart';
import 'package:web_clock_clone/utils/app_theme.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(child: AppRoot()),
  );
}

class AppRoot extends ConsumerStatefulWidget {
  const AppRoot({super.key});

  @override
  ConsumerState<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<AppRoot> {
  late final AppLifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    _lifecycleObserver = AppLifecycleObserver(ref);
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ref.watch here — when routerProvider rebuilds (e.g. after a hot reload),
    // MaterialApp.router picks up the new instance automatically.
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Time & Attendance',
      routerConfig: router,
      theme: AppTheme.themeData(),
      debugShowCheckedModeBanner: false,
    );
  }
}