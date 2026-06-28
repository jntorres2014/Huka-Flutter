import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'especie.dart';
import 'especie_descubierta.dart';

/// Detalle de una especie (equivalente al detalle de PescadexScreen.kt).
class EspecieDetailScreen extends StatelessWidget {
  const EspecieDetailScreen({
    super.key,
    required this.especie,
    this.descubierta,
  });
  final Especie especie;
  final EspecieDescubierta? descubierta;

  @override
  Widget build(BuildContext context) {
    final d = descubierta;
    return Scaffold(
      appBar: AppBar(title: Text(especie.nombre)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                if (d != null && d.tieneFoto)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: d.primeraFoto!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const SizedBox(
                          height: 200,
                          child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2))),
                      errorWidget: (_, __, ___) => const Icon(Icons.set_meal,
                          size: 96, color: HukaAccents.pescadex),
                    ),
                  )
                else
                  const Icon(Icons.set_meal,
                      size: 96, color: HukaAccents.pescadex),
                const SizedBox(height: 8),
                Text(especie.cientifico,
                    style: const TextStyle(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (d != null) _MiRecord(descubierta: d),
          const SizedBox(height: 8),
          _Campo(icon: Icons.place, titulo: 'Hábitat', valor: especie.habitat),
          _Campo(
              icon: Icons.straighten, titulo: 'Tamaño', valor: especie.tamano),
          _Campo(
              icon: Icons.schedule,
              titulo: 'Mejor horario',
              valor: especie.mejorHorario),
          _Campo(
              icon: Icons.calendar_month,
              titulo: 'Temporada',
              valor: especie.temporada),
          _Campo(
              icon: Icons.phishing, titulo: 'Técnica', valor: especie.tecnica),
          _CampoLista(
              icon: Icons.bug_report,
              titulo: 'Carnadas',
              valores: especie.carnadas),
          if (especie.sinonimos.isNotEmpty)
            _CampoLista(
                icon: Icons.label,
                titulo: 'También conocido como',
                valores: especie.sinonimos),
        ],
      ),
    );
  }
}

/// Tarjeta "Mi récord" con las estadísticas de captura del usuario.
class _MiRecord extends StatelessWidget {
  const _MiRecord({required this.descubierta});
  final EspecieDescubierta descubierta;

  @override
  Widget build(BuildContext context) {
    final d = descubierta;
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mi récord 🏆',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                if (d.pesoRecord != null)
                  _stat('💪', '${d.pesoRecord!.toStringAsFixed(1)} kg', 'Peso'),
                _stat('📈', '${d.totalCapturas}', 'Capturas'),
                if (d.mejorDiaCantidad > 0)
                  _stat('🌟', '${d.mejorDiaCantidad}', 'Mejor jornada'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String icon, String valor, String etiqueta) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$icon $valor',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(etiqueta, style: const TextStyle(fontSize: 12)),
        ],
      );
}

class _Campo extends StatelessWidget {
  const _Campo(
      {required this.icon, required this.titulo, required this.valor});
  final IconData icon;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    if (valor.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: HukaAccents.pescadex),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: Theme.of(context).textTheme.labelMedium),
                Text(valor, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CampoLista extends StatelessWidget {
  const _CampoLista(
      {required this.icon, required this.titulo, required this.valores});
  final IconData icon;
  final String titulo;
  final List<String> valores;

  @override
  Widget build(BuildContext context) {
    if (valores.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: HukaAccents.pescadex),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: valores
                      .map((v) => Chip(
                            label: Text(v),
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
