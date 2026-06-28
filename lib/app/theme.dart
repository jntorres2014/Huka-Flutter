import 'package:flutter/material.dart';

/// Tema Material 3 de Huka, migrado desde HukaTheme.kt.
/// Mantiene la paleta púrpura original (seed #6750A4) en claro y oscuro.
class HukaTheme {
  static const Color _seed = Color(0xFF6750A4);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.light,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
      );
}

/// Acentos por sección, equivalentes a los del NavigationDrawer original.
class HukaAccents {
  static const pescadex = Color(0xFF2E7D32);
  static const crearParte = Color(0xFF1565C0);
  static const contador = Color(0xFF6A1B9A);
  static const chat = Color(0xFF00838F);
  static const reportes = Color(0xFFEF6C00);
  static const logros = Color(0xFFF9A825);
  static const torneos = Color(0xFFAD1457);
  static const identificar = Color(0xFF4527A0);
  static const perfil = Color(0xFF455A64);
}
