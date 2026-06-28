import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme.dart';
import '../parte/parte_models.dart';
import '../parte/partes_providers.dart';

/// Detalle de un parte registrado.
class ParteDetailScreen extends ConsumerWidget {
  const ParteDetailScreen({super.key, required this.parte});
  final PartePesca parte;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ubic = parte.ubicacion;
    return Scaffold(
      appBar: AppBar(
        title: Text(parte.fecha ?? 'Parte'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmarEliminar(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Fila(Icons.phishing, 'Modalidad', parte.modalidadLabel),
          if (parte.horaInicio != null || parte.horaFin != null)
            _Fila(Icons.schedule, 'Horario',
                '${parte.horaInicio ?? '--:--'} a ${parte.horaFin ?? '--:--'}'),
          _Fila(Icons.set_meal, 'Capturas totales', '${parte.cantidadTotal}'),
          if (parte.numeroCanas > 0)
            _Fila(Icons.straighten, 'Cañas', '${parte.numeroCanas}'),
          if (ubic?.nombre != null) _Fila(Icons.place, 'Lugar', ubic!.nombre!),
          if (ubic?.zona != null) _Fila(Icons.map, 'Zona', ubic!.zona!),
          if (ubic?.latitud != null && ubic?.longitud != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 180,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(ubic!.latitud!, ubic.longitud!),
                    initialZoom: 13,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.juka_flutter',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(ubic.latitud!, ubic.longitud!),
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on,
                              color: HukaAccents.reportes, size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (parte.observaciones != null)
            _Fila(Icons.notes, 'Observaciones', parte.observaciones!),
          if (parte.peces.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Especies', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...parte.peces.map((c) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.set_meal,
                      color: HukaAccents.reportes),
                  title: Text(c.especie),
                  trailing: Text('x${c.cantidad}'),
                )),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmarEliminar(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar parte'),
        content: const Text('¿Seguro que querés eliminar este parte?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true && parte.id != null) {
      await ref.read(partesRepositoryProvider).eliminarParte(parte.id!);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class _Fila extends StatelessWidget {
  const _Fila(this.icon, this.titulo, this.valor);
  final IconData icon;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: HukaAccents.reportes),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: Theme.of(context).textTheme.labelMedium),
                Text(valor, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
