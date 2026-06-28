import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

/// Raíz de la app (equivalente a setContent { HukaTheme { ... } } en MainActivity.kt).
class JukaApp extends ConsumerWidget {
  const JukaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Huka',
      debugShowCheckedModeBanner: false,
      theme: HukaTheme.light,
      darkTheme: HukaTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
