import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import 'torneo_models.dart';
import 'torneos_providers.dart';

class TorneoDetailScreen extends ConsumerWidget {
  const TorneoDetailScreen({super.key, required this.torneo});
  final Torneo torneo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participantesAsync = ref.watch(participantesProvider(torneo.id));
    final esCreador = ref.read(torneosRepositoryProvider).esCreador(torneo);
    final df = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: Text(torneo.nombre)),
      body: participantesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (participantes) {
          final con = TorneoConParticipantes(
            torneo: torneo,
            participantes: participantes,
            soyCreador: esCreador,
          );
          final ranking = con.aceptados;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (torneo.descripcion.isNotEmpty) ...[
                Text(torneo.descripcion),
                const SizedBox(height: 12),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(Icons.flag, _estado(torneo.estado)),
                  _InfoChip(Icons.calendar_today,
                      '${df.format(torneo.fechaInicio)} – ${df.format(torneo.fechaFin)}'),
                  _InfoChip(Icons.leaderboard, torneo.tipoPuntajeEnum.display),
                ],
              ),
              const SizedBox(height: 16),
              if (esCreador) _CodigoCard(codigo: torneo.codigoInvitacion),

              // Nota: los partes se cargan solos al torneo cuando guardás un
              // parte (si el torneo está activo y sos participante).

              // Solicitudes pendientes (solo creador)
              if (esCreador && con.pendientes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Solicitudes pendientes',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...con.pendientes.map((p) => _SolicitudTile(
                      torneoId: torneo.id,
                      participante: p,
                    )),
              ],

              const SizedBox(height: 16),
              Text('Ranking', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (ranking.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text('Sin participantes aceptados aún.')),
                )
              else
                ...ranking.asMap().entries.map((e) =>
                    _RankingTile(posicion: e.key + 1, participante: e.value)),

              const SizedBox(height: 16),
              Text('Partes cargados',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _PartesCargados(torneoId: torneo.id, esCreador: esCreador),
            ],
          );
        },
      ),
    );
  }

  String _estado(EstadoTorneo e) => switch (e) {
        EstadoTorneo.proximo => 'Próximo',
        EstadoTorneo.activo => 'Activo',
        EstadoTorneo.finalizado => 'Finalizado',
      };
}

class _PartesCargados extends ConsumerWidget {
  const _PartesCargados({required this.torneoId, required this.esCreador});
  final String torneoId;
  final bool esCreador;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partesAsync = ref.watch(partesTorneoProvider(torneoId));
    return partesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Error: $e'),
      data: (partes) {
        final activos = partes
            .where((p) => p.estadoEnum == EstadoParteTorneo.activo)
            .toList();
        if (activos.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Todavía no se cargaron partes.'),
          );
        }
        return Column(
          children: activos.map((p) {
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: HukaAccents.torneos,
                  child: Text('${p.puntaje}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12)),
                ),
                title: Text(p.userName),
                subtitle: Text(
                    '${p.fecha} · ${p.totalPeces} peces · ${p.puntaje} pts'),
                trailing: esCreador
                    ? IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        tooltip: 'Rechazar parte',
                        onPressed: () => _confirmarRechazo(context, ref, p),
                      )
                    : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _confirmarRechazo(
      BuildContext context, WidgetRef ref, ParteTorneo parte) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rechazar parte'),
        content: Text(
            '¿Rechazar el parte de ${parte.userName}? Se le restarán ${parte.puntaje} puntos.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Rechazar')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(torneosRepositoryProvider).rechazarParte(torneoId, parte);
    }
  }
}

class _CodigoCard extends StatelessWidget {
  const _CodigoCard({required this.codigo});
  final String codigo;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.qr_code),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Código de invitación',
                      style: Theme.of(context).textTheme.labelMedium),
                  SelectableText(codigo,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold, letterSpacing: 2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SolicitudTile extends ConsumerWidget {
  const _SolicitudTile({required this.torneoId, required this.participante});
  final String torneoId;
  final ParticipanteTorneo participante;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(torneosRepositoryProvider);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: participante.userPhoto.isNotEmpty
              ? NetworkImage(participante.userPhoto)
              : null,
          child: participante.userPhoto.isEmpty
              ? const Icon(Icons.person)
              : null,
        ),
        title: Text(participante.userName),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () =>
                  repo.responderSolicitud(torneoId, participante.userId, true),
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () =>
                  repo.responderSolicitud(torneoId, participante.userId, false),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingTile extends StatelessWidget {
  const _RankingTile({required this.posicion, required this.participante});
  final int posicion;
  final ParticipanteTorneo participante;

  @override
  Widget build(BuildContext context) {
    final medalla = switch (posicion) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '$posicion',
    };
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: HukaAccents.torneos.withValues(alpha: 0.15),
          child: Text(medalla),
        ),
        title: Text(participante.userName),
        trailing: Text('${participante.puntaje} pts',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.icon, this.texto);
  final IconData icon;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(texto),
      visualDensity: VisualDensity.compact,
    );
  }
}
