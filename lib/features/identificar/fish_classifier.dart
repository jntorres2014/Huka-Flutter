import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Una predicción del modelo.
class Prediccion {
  final String etiqueta; // ej: "trucha_arcoiris"
  final String cientifico; // ej: "Oncorhynchus mykiss"
  final double score; // 0..1

  const Prediccion(this.etiqueta, this.cientifico, this.score);

  String get nombreLegible =>
      etiqueta.replaceAll('_', ' ').replaceFirstChar((c) => c.toUpperCase());

  int get porcentaje => (score * 100).round();
}

extension on String {
  String replaceFirstChar(String Function(String) f) =>
      isEmpty ? this : f(this[0]) + substring(1);
}

/// Clasificador con el modelo propio (equivalente a FishIdentifier.identifyWithModeloPropio).
///
/// Entrada: 224x224x3 float32 SIN normalizar (el modelo aplica
/// efficientnet.preprocess_input internamente).
/// Salida: 5 probabilidades.
class FishClassifier {
  static const _modelo = 'assets/models/modelo_nuevo.tflite';
  static const umbral = 0.30;

  // Mismas clases y orden que clasesModeloPropio en FishIdentifier.kt.
  static const _clases = [
    'bagre',
    'carpa',
    'pejerrey_patagonico',
    'trucha_arcoiris',
    'trucha_marron',
  ];

  static const _cientificos = {
    'bagre': 'Pimelodus maculatus',
    'carpa': 'Cyprinus carpio',
    'pejerrey_patagonico': 'Odontesthes hatcheri',
    'trucha_arcoiris': 'Oncorhynchus mykiss',
    'trucha_marron': 'Salmo trutta',
  };

  Interpreter? _interpreter;

  Future<void> _cargar() async {
    _interpreter ??= await Interpreter.fromAsset(_modelo);
  }

  /// Devuelve las predicciones ordenadas de mayor a menor score.
  Future<List<Prediccion>> clasificar(String imagePath) async {
    await _cargar();

    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('No se pudo leer la imagen.');
    }
    final resized = img.copyResize(decoded, width: 224, height: 224);

    // Construye el tensor [1,224,224,3] con valores 0..255 (sin normalizar).
    final input = List.generate(
      1,
      (_) => List.generate(
        224,
        (y) => List.generate(224, (x) {
          final p = resized.getPixel(x, y);
          return [p.r.toDouble(), p.g.toDouble(), p.b.toDouble()];
        }),
      ),
    );

    final output = List.generate(1, (_) => List.filled(_clases.length, 0.0));
    _interpreter!.run(input, output);

    final scores = output[0];
    final preds = <Prediccion>[];
    for (var i = 0; i < _clases.length; i++) {
      preds.add(Prediccion(
        _clases[i],
        _cientificos[_clases[i]] ?? _clases[i],
        (scores[i] as num).toDouble(),
      ));
    }
    preds.sort((a, b) => b.score.compareTo(a.score));
    return preds;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
