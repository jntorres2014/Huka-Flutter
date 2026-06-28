import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../auth/auth_providers.dart';

/// Entrada del menú lateral (equivalente a DrawerEntry de HukaNavigationDrawer.kt).
class _Entry {
  final String route;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  const _Entry(this.route, this.title, this.subtitle, this.icon, this.accent);
}

const _entries = <_Entry>[
  _Entry(Routes.pescadex, 'Pescadex', 'Identificá especies', Icons.menu_book, HukaAccents.pescadex),
  _Entry(Routes.crearParte, 'Crear parte', 'Registrá tu captura', Icons.edit_note, HukaAccents.crearParte),
  _Entry(Routes.contador, 'Contador', 'Sumá capturas en vivo', Icons.calculate, HukaAccents.contador),
  _Entry(Routes.chat, 'Chat Huka', 'Consultá con la IA', Icons.chat, HukaAccents.chat),
  _Entry(Routes.reportes, 'Reportes', 'Estadísticas y registros', Icons.assignment, HukaAccents.reportes),
  _Entry(Routes.logros, 'Logros', 'Tus medallas y logros', Icons.emoji_events, HukaAccents.logros),
  _Entry(Routes.torneos, 'Torneos', 'Participá y competí', Icons.military_tech, HukaAccents.torneos),
  _Entry(Routes.identificar, 'Identificar pez', 'Sacale una foto', Icons.photo_camera, HukaAccents.identificar),
  _Entry(Routes.perfil, 'Perfil', 'Tu cuenta y ajustes', Icons.person, HukaAccents.perfil),
];

/// Scaffold con drawer compartido por todas las pantallas internas.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = _entries.firstWhere(
      (e) => e.route == location,
      orElse: () => _entries.first,
    );
    final user = ref.watch(authStateProvider).valueOrNull;
    final nombre = (user?.displayName?.split(' ').first) ?? 'Pescador';

    return Scaffold(
      appBar: AppBar(title: Text(current.title)),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              DrawerHeader(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Huka',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Hola $nombre 👋'),
                    const Text('Buen día para pescar'),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: _entries.map((e) {
                    final selected = e.route == location;
                    return ListTile(
                      leading: Icon(e.icon, color: e.accent),
                      title: Text(e.title),
                      subtitle: Text(e.subtitle),
                      selected: selected,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go(e.route);
                      },
                    );
                  }).toList(),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Cerrar sesión'),
                onTap: () => ref.read(authControllerProvider.notifier).signOut(),
              ),
            ],
          ),
        ),
      ),
      body: child,
    );
  }
}
