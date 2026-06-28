import 'package:flutter/material.dart';

/// Categorías de logros (equivalente a AchievementCategory de AchievementCatalog.kt).
enum AchievementCategory {
  eventos('Eventos', 'EVENTO', Icons.card_giftcard, Color(0xFFE53935),
      Color(0xFFFFEBEE)),
  especies('Especies', 'ESPECIES', Icons.set_meal, Color(0xFF2E7D32),
      Color(0xFFE8F5E9)),
  horarios('Horarios', 'HORARIOS', Icons.nightlight, Color(0xFF6A4C93),
      Color(0xFFEDE7F6)),
  especiales('Especiales', 'ESPECIAL', Icons.star, Color(0xFFEF6C00),
      Color(0xFFFFF3E0));

  const AchievementCategory(
      this.displayName, this.shortLabel, this.icon, this.color, this.container);
  final String displayName;
  final String shortLabel;
  final IconData icon;
  final Color color;
  final Color container;
}

/// Una entrada del catálogo (equivalente a CatalogEntry).
class CatalogEntry {
  final String id;
  final String title;
  final String description;
  final AchievementCategory category;

  const CatalogEntry(this.id, this.title, this.description, this.category);

  String get emoji => _emojiFor(id);
}

/// Catálogo completo de logros (migrado 1:1 de AchievementCatalog.kt).
class AchievementCatalog {
  static const List<CatalogEntry> all = [
    // EVENTOS ESTACIONALES
    CatalogEntry('pescador_navideño', 'Pescador Navideño',
        'Pescaste durante las fiestas navideñas (24-31 dic)', AchievementCategory.eventos),
    CatalogEntry('pescador_año_nuevo', 'Pescador de Año Nuevo',
        'Empezaste el año pescando (1-7 enero)', AchievementCategory.eventos),
    CatalogEntry('regalo_de_reyes', 'Regalo de Reyes',
        'Pescaste el día de Reyes Magos', AchievementCategory.eventos),
    CatalogEntry('pescador_invernal', 'Pescador Invernal',
        'Desafiaste el frío del invierno argentino', AchievementCategory.eventos),
    CatalogEntry('pescador_primaveral', 'Pescador Primaveral',
        'Aprovechaste la primavera para pescar', AchievementCategory.eventos),

    // ESPECIES
    CatalogEntry('variedad_es_vida', 'La Variedad es Vida',
        'Pescaste 5 especies diferentes en un parte', AchievementCategory.especies),
    CatalogEntry('rey_del_rio', 'Rey del Río',
        'Pescaste 5+ dorados en una jornada', AchievementCategory.especies),
    CatalogEntry('cazador_de_dorados', 'Cazador de Dorados',
        'Registraste tu primer dorado', AchievementCategory.especies),
    CatalogEntry('amigo_del_surubi', 'Amigo del Surubí',
        'Pescaste el gigante del río', AchievementCategory.especies),
    CatalogEntry('pejerreyes_master', 'Maestro del Pejerrey',
        'Pescaste 10 o más pejerreyes', AchievementCategory.especies),

    // HORARIOS
    CatalogEntry('madrugador', 'Madrugador',
        'Pescaste antes del amanecer (5-7 AM)', AchievementCategory.horarios),
    CatalogEntry('pescador_nocturno', 'Pescador Nocturno',
        'Pescaste después del atardecer (19-23 hs)', AchievementCategory.horarios),
    CatalogEntry('noctambulo', 'Noctámbulo Extremo',
        'Pescaste de madrugada (0-4 AM)', AchievementCategory.horarios),

    // PESCADEX (colección)
    CatalogEntry('pescadex_primer_pez', 'Primer Pez',
        'Tu primera especie en el Pescadex', AchievementCategory.especies),
    CatalogEntry('pescadex_explorador', 'Explorador del Pescadex',
        'Capturaste 5 especies diferentes', AchievementCategory.especies),
    CatalogEntry('pescadex_coleccionista', 'Coleccionista',
        '10 especies diferentes en tu Pescadex', AchievementCategory.especies),
    CatalogEntry('pescadex_especialista', 'Especialista',
        '15 especies diferentes en tu Pescadex', AchievementCategory.especies),
    CatalogEntry('pescadex_maestro', 'Maestro Pescador',
        '20 especies diferentes en tu Pescadex', AchievementCategory.especies),
    CatalogEntry('pescadex_cazador_raros', 'Cazador de Raros',
        'Capturaste al menos una especie rara', AchievementCategory.especies),
    CatalogEntry('pescadex_cazador_epicos', 'Cazador Épico',
        'Capturaste al menos una especie épica o legendaria',
        AchievementCategory.especies),
    CatalogEntry('pescadex_completista', 'Completista',
        'Capturaste 30 especies diferentes', AchievementCategory.especies),

    // ESPECIALES
    CatalogEntry('mi_primer_parte', 'Mi Primer Parte',
        '¡Bienvenido a Huka! Creaste tu primer reporte de pesca',
        AchievementCategory.especiales),
    CatalogEntry('solo_un_pez', 'Solo Un Pez',
        'No pescaste nada... bueno, casi nada', AchievementCategory.especiales),
    CatalogEntry('zapatero_wade', 'Zapatero Wade',
        '¡No tuviste suerte hoy, espero esto te ayude la próxima!',
        AchievementCategory.especiales),
    CatalogEntry('pesca_abundante', 'Pesca Abundante',
        '¡Pescaste 10 o más peces en una salida!', AchievementCategory.especiales),
    CatalogEntry('explorador', 'Explorador',
        'Compartiste la ubicación de tu pesca', AchievementCategory.especiales),
  ];

  static int get total => all.length;

  static List<CatalogEntry> byCategory(AchievementCategory? c) =>
      c == null ? all : all.where((e) => e.category == c).toList();
}

String _emojiFor(String id) {
  if (id.contains('invernal')) return '❄️';
  if (id.contains('navideño')) return '🎄';
  if (id.contains('año_nuevo')) return '🎆';
  if (id.contains('reyes')) return '👑';
  if (id.contains('primaveral')) return '🌸';
  if (id.contains('noctambulo')) return '🌙';
  if (id.contains('nocturno')) return '🌃';
  if (id.contains('madrugador')) return '🌅';
  if (id.contains('dorado')) return '🐟';
  if (id.contains('surubi')) return '🐠';
  if (id.contains('pejerrey')) return '🎣';
  if (id.contains('variedad')) return '🌈';
  if (id.contains('primer')) return '✨';
  if (id.contains('zapatero') || id.contains('solo_un_pez')) return '🥲';
  if (id.contains('abundante')) return '🎯';
  if (id.contains('explorador')) return '🗺️';
  return '🏆';
}
