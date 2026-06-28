import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../parte/parte_models.dart';
import '../parte/partes_providers.dart';
import 'parte_detail_screen.dart';

class ReportesScreen extends ConsumerWidget {
  const ReportesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partesAsync = ref.watch(partesProvider);
    final stats = ref.watch(estadisticasProvider);

    return partesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('No se pudieron cargar tus reportes.\n$e',
              textAlign: TextAlign.center),
        ),
      ),
      data: (partes) {
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _StatsCard(stats: stats),
            const SizedBox(height: 12),
            if (partes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text('Todavía no registraste partes.\n'
                      'Creá uno desde "Crear parte".',
                      textAlign: TextAlign.center),
                ),
              )
            else
              ...partes.map((p) => _ParteCard(parte: p)),
          ],
        );
      },
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});
  final EstadisticasReportes stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Mini('🎣', '${stats.totalJornadas}', 'Jornadas'),
            _Mini('🐟', '${stats.totalCapturas}', 'Capturas'),
            _Mini('🏆', stats.especieTop, 'Top'),
            _Mini('📈', stats.promedioPorJornada.toStringAsFixed(1), 'Prom.'),
          ],
        ),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini(this.icon, this.valor, this.etiqueta);
  final String icon;
  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        SizedBox(
          width: 70,
          child: Text(valor,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Text(etiqueta, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _ParteCard extends StatelessWidget {
  const _ParteCard({required this.parte});
  final PartePesca parte;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: HukaAccents.reportes,
          child: Text('${parte.cantidadTotal}',
              style: const TextStyle(color: Colors.white)),
        ),
        title: Text(parte.modalidadLabel),
        subtitle: Text(
          [
            if (parte.fecha != null) parte.fecha,
            if (parte.ubicacion?.nombre != null) parte.ubicacion!.nombre,
          ].whereType<String>().join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ParteDetailScreen(parte: parte)),
        ),
      ),
    );
  }
}
