import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import 'especie.dart';

/// Carga la Pescadex desde el asset JSON (equivalente a PescadexManager.kt).
class PescadexRepository {
  static const _assetPath = 'assets/peces_argentinos.json';

  Future<List<Especie>> cargarEspecies() async {
    final raw = await rootBundle.loadString(_assetPath);
    final data = json.decode(raw) as List<dynamic>;
    final especies = data
        .map((e) => Especie.fromJson(e as Map<String, dynamic>))
        .toList();
    especies.sort((a, b) => a.nombre.compareTo(b.nombre));
    return especies;
  }
}
