import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../auth/auth_providers.dart';

class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final foto = user?.photoURL;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: HukaAccents.perfil,
              backgroundImage: foto != null ? NetworkImage(foto) : null,
              child: foto == null
                  ? const Icon(Icons.person, color: Colors.white, size: 36)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.displayName ?? 'Pescador',
                      style: Theme.of(context).textTheme.titleLarge),
                  Text(user?.email ?? '',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const _SectionTitle('Cuenta'),
        ListTile(
          leading: const Icon(Icons.badge_outlined),
          title: const Text('Proveedor de acceso'),
          subtitle: Text(_proveedor(ref)),
          contentPadding: EdgeInsets.zero,
        ),
        ListTile(
          leading: const Icon(Icons.verified_user_outlined),
          title: const Text('Email verificado'),
          subtitle: Text((user?.emailVerified ?? false) ? 'Sí' : 'No'),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),
        const _SectionTitle('Ajustes'),
        const ListTile(
          leading: Icon(Icons.brightness_6_outlined),
          title: Text('Tema'),
          subtitle: Text('Sigue el sistema (claro/oscuro)'),
          contentPadding: EdgeInsets.zero,
        ),
        ListTile(
          leading: const Icon(Icons.notifications_outlined),
          title: const Text('Notificaciones'),
          subtitle: const Text('Se configuran en una fase posterior (FCM)'),
          contentPadding: EdgeInsets.zero,
          enabled: false,
          onTap: () {},
        ),
        const SizedBox(height: 24),
        FilledButton.tonalIcon(
          onPressed: () =>
              ref.read(authControllerProvider.notifier).signOut(),
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
        ),
      ],
    );
  }

  String _proveedor(WidgetRef ref) {
    final providers =
        ref.read(authRepositoryProvider).currentUser?.providerData ?? [];
    if (providers.isEmpty) return 'Desconocido';
    final id = providers.first.providerId;
    if (id.contains('google')) return 'Google';
    if (id.contains('apple')) return 'Apple';
    return id;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
