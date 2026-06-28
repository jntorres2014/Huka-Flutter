import 'package:flutter/material.dart';

/// Pantalla placeholder reutilizable para las features aún no migradas.
/// En las próximas fases, cada una se reemplaza por la pantalla real.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
    this.pendiente = const [],
  });

  final String title;
  final IconData icon;
  final Color accent;
  final List<String> pendiente;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: accent),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Pantalla lista para migrar en la próxima fase.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (pendiente.isNotEmpty) ...[
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('A migrar aquí:',
                    style: Theme.of(context).textTheme.labelLarge),
              ),
              const SizedBox(height: 8),
              ...pendiente.map((p) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text('•  $p'),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
