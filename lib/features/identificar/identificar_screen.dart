import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme.dart';
import '../chat/chat_providers.dart';
import '../pescadex/especie.dart';
import '../pescadex/pescadex_providers.dart';
import 'fish_classifier.dart';

final _classifierProvider = Provider<FishClassifier>((ref) {
  final c = FishClassifier();
  ref.onDispose(c.dispose);
  return c;
});

class IdentificarScreen extends ConsumerStatefulWidget {
  const IdentificarScreen({super.key});

  @override
  ConsumerState<IdentificarScreen> createState() => _IdentificarScreenState();
}

class _IdentificarScreenState extends ConsumerState<IdentificarScreen> {
  final _picker = ImagePicker();
  String? _imagePath;
  bool _cargando = false;

  List<Prediccion>? _preds; // resultado del modelo offline
  String? _reporteGemini; // resultado del modo IA
  String? _error;

  Future<void> _elegirFoto(ImageSource source) async {
    final x = await _picker.pickImage(source: source, maxWidth: 1024);
    if (x == null) return;
    setState(() {
      _imagePath = x.path;
      _preds = null;
      _reporteGemini = null;
      _error = null;
    });
  }

  Future<void> _analizarOffline() async {
    if (_imagePath == null) return;
    setState(() {
      _cargando = true;
      _preds = null;
      _reporteGemini = null;
      _error = null;
    });
    try {
      final preds = await ref.read(_classifierProvider).clasificar(_imagePath!);
      setState(() => _preds = preds);
    } catch (e) {
      setState(() => _error =
          'No se pudo correr el modelo. ¿Copiaste modelo_nuevo.tflite en assets/models/?\n\n$e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _analizarGemini() async {
    if (_imagePath == null) return;
    setState(() {
      _cargando = true;
      _preds = null;
      _reporteGemini = null;
      _error = null;
    });
    final reporte =
        await ref.read(geminiServiceProvider).identificarPorFoto(_imagePath!);
    if (mounted) {
      setState(() {
        _reporteGemini = reporte;
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              image: _imagePath != null
                  ? DecorationImage(
                      image: FileImage(File(_imagePath!)), fit: BoxFit.cover)
                  : null,
            ),
            child: _imagePath == null
                ? const Center(
                    child: Icon(Icons.photo_camera,
                        size: 64, color: HukaAccents.identificar),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _elegirFoto(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Cámara'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _elegirFoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galería'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed:
                    _imagePath == null || _cargando ? null : _analizarOffline,
                icon: const Icon(Icons.memory),
                label: const Text('Modelo offline'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed:
                    _imagePath == null || _cargando ? null : _analizarGemini,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Analizar con IA'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_cargando)
          const Center(child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          )),
        if (_error != null)
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!),
            ),
          ),
        if (_preds != null) _ResultadoOffline(preds: _preds!),
        if (_reporteGemini != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_reporteGemini!),
            ),
          ),
      ],
    );
  }
}

class _ResultadoOffline extends ConsumerWidget {
  const _ResultadoOffline({required this.preds});
  final List<Prediccion> preds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = preds.first;

    if (top.score < FishClassifier.umbral) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🤔 No estoy seguro (confianza ${top.porcentaje}%).',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const Text(
                  'Este modelo reconoce: bagre, carpa, pejerrey patagónico, '
                  'trucha arcoíris y trucha marrón.'),
            ],
          ),
        ),
      );
    }

    // Busca info en la Pescadex por nombre científico.
    final especies = ref.watch(especiesProvider).valueOrNull ?? const <Especie>[];
    Especie? local;
    for (final e in especies) {
      if (e.cientifico.toLowerCase() == top.cientifico.toLowerCase()) {
        local = e;
        break;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🐟 ${local?.nombre ?? top.nombreLegible}',
                style: Theme.of(context).textTheme.titleLarge),
            Text('${top.cientifico} — Confianza: ${top.porcentaje}%',
                style: const TextStyle(fontStyle: FontStyle.italic)),
            if (local != null) ...[
              const Divider(height: 24),
              if (local.habitat.isNotEmpty) _info('📍 Hábitat', local.habitat),
              if (local.tecnica.isNotEmpty) _info('🎣 Técnica', local.tecnica),
              if (local.carnadas.isNotEmpty)
                _info('🪱 Carnadas', local.carnadas.join(', ')),
              if (local.temporada.isNotEmpty)
                _info('📅 Temporada', local.temporada),
            ],
            const Divider(height: 24),
            Text('Otras posibilidades',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            ...preds.skip(1).take(2).map((p) =>
                Text('• ${p.nombreLegible} — ${p.porcentaje}%')),
            const SizedBox(height: 8),
            Text('Modelo local · sin conexión',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _info(String titulo, String valor) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                  text: '$titulo: ',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: valor),
            ],
          ),
        ),
      );
}
