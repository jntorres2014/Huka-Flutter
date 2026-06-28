import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_providers.dart';
import '../features/auth/login_screen.dart';
import '../features/home/home_shell.dart';
import '../features/pescadex/pescadex_screen.dart';
import '../features/parte/crear_parte_screen.dart';
import '../features/contador/contador_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/reportes/reportes_screen.dart';
import '../features/logros/logros_screen.dart';
import '../features/torneos/torneos_screen.dart';
import '../features/identificar/identificar_screen.dart';
import '../features/perfil/perfil_screen.dart';

/// Rutas de la app (equivalente a Screen.kt + Navigation Compose).
class Routes {
  static const login = '/login';
  static const pescadex = '/pescadex';
  static const crearParte = '/crear-parte';
  static const contador = '/contador';
  static const chat = '/chat';
  static const reportes = '/reportes';
  static const logros = '/logros';
  static const torneos = '/torneos';
  static const identificar = '/identificar';
  static const perfil = '/perfil';
}

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: Routes.pescadex,
    refreshListenable: GoRouterRefreshStream(ref),
    redirect: (context, state) {
      final loggedIn = auth.valueOrNull != null;
      final goingToLogin = state.matchedLocation == Routes.login;
      if (!loggedIn) return goingToLogin ? null : Routes.login;
      if (goingToLogin) return Routes.pescadex;
      return null;
    },
    routes: [
      GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),
      // Shell con drawer compartido para todas las pantallas internas.
      ShellRoute(
        builder: (context, state, child) => HomeShell(
          location: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(path: Routes.pescadex, builder: (_, __) => const PescadexScreen()),
          GoRoute(path: Routes.crearParte, builder: (_, __) => const CrearParteScreen()),
          GoRoute(path: Routes.contador, builder: (_, __) => const ContadorScreen()),
          GoRoute(path: Routes.chat, builder: (_, __) => const ChatScreen()),
          GoRoute(path: Routes.reportes, builder: (_, __) => const ReportesScreen()),
          GoRoute(path: Routes.logros, builder: (_, __) => const LogrosScreen()),
          GoRoute(path: Routes.torneos, builder: (_, __) => const TorneosScreen()),
          GoRoute(path: Routes.identificar, builder: (_, __) => const IdentificarScreen()),
          GoRoute(path: Routes.perfil, builder: (_, __) => const PerfilScreen()),
        ],
      ),
    ],
  );
});

/// Hace que go_router reaccione a los cambios de sesión de Firebase.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
