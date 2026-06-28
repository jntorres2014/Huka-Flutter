import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import 'especie.dart';
import 'especie_descubierta.dart';
import 'especie_detail_screen.dart';
import 'pescadex_providers.dart';

class PescadexScreen extends ConsumerWidget {
  const PescadexScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtradas = ref.watch(especiesFiltradasProvider);
    final descubiertas =
        ref.watch(descubiertasProvider).valueOrNull ?? const {};
    final filtro = ref.watch(filtroPescadexProvider);
    final totalCatalogo = ref.watch(especiesProvider).valueOrNull?.length ?? 0;

    return Column(
      children: [
        _HeaderProgreso(
          descubiertas: descubiertas.length,
          total: totalCatalogo,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o especie...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              isDense: true,
            ),
            onChanged: (v) => ref.read(busquedaProvider.notifier).state = v,
          ),
        ),
        _FiltrosRow(
          actual: filtro,
          onSelect: (f) =>
              ref.read(filtroPescadexProvider.notifier).state = f,
        ),
        Expanded(
          child: filtradas.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No se pudo cargar la Pescadex.\n$e',
                    textAlign: TextAlign.center),
              ),
            ),
            data: (lista) {
              // Aplica el filtro por estado de captura.
              final visibles = lista.where((e) {
                final capturada =
                    descubiertas.containsKey(normalizarParaId(e.nombre));
                return switch (filtro) {
                  FiltroPescadex.todas => true,
                  FiltroPescadex.capturadas => capturada,
                  FiltroPescadex.porDescubrir => !capturada,
                };
              }).toList();

              if (visibles.isEmpty) {
                return const Center(child: Text('Sin resultados.'));
              }
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisExtent: 190,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: visibles.length,
                itemBuilder: (context, i) {
                  final especie = visibles[i];
                  final desc = descubiertas[normalizarParaId(especie.nombre)];
                  return _EspecieCard(especie: especie, descubierta: desc);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HeaderProgreso extends StatelessWidget {
  const _HeaderProgreso({required this.descubiertas, required this.total});
  final int descubiertas;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progreso = total == 0 ? 0.0 : descubiertas / total;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$descubiertas de $total especies descubiertas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: progreso, minHeight: 8),
          ),
        ],
      ),
    );
  }
}

class _FiltrosRow extends StatelessWidget {
  const _FiltrosRow({required this.actual, required this.onSelect});
  final FiltroPescadex actual;
  final ValueChanged<FiltroPescadex> onSelect;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, FiltroPescadex f) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: actual == f,
            onSelected: (_) => onSelect(f),
          ),
        );
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          chip('Todas', FiltroPescadex.todas),
          chip('Capturadas', FiltroPescadex.capturadas),
          chip('Por descubrir', FiltroPescadex.porDescubrir),
        ],
      ),
    );
  }
}

class _EspecieCard extends StatelessWidget {
  const _EspecieCard({required this.especie, required this.descubierta});
  final Especie especie;
  final EspecieDescubierta? descubierta;

  @override
  Widget build(BuildContext context) {
    final capturada = descubierta != null;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                EspecieDetailScreen(especie: especie, descubierta: descubierta),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: _Foto(descubierta: descubierta),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          especie.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (capturada)
                        const Icon(Icons.check_circle,
                            size: 16, color: HukaAccents.pescadex),
                    ],
                  ),
                  Text(
                    especie.cientifico,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Muestra la foto del usuario si capturó la especie; si no, un placeholder.
class _Foto extends StatelessWidget {
  const _Foto({required this.descubierta});
  final EspecieDescubierta? descubierta;

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surfaceContainerHighest;
    if (descubierta != null && descubierta!.tieneFoto) {
      return CachedNetworkImage(
        imageUrl: descubierta!.primeraFoto!,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
            color: bg,
            child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2))),
        errorWidget: (_, __, ___) => Container(
          color: bg,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }
    // No capturada o sin foto: ícono (silueta si está por descubrir).
    return Container(
      color: bg,
      child: Icon(
        descubierta == null ? Icons.help_outline : Icons.set_meal,
        size: 44,
        color: descubierta == null ? Colors.grey : HukaAccents.pescadex,
      ),
    );
  }
}
