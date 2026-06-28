import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../parte/parte_models.dart';
import '../parte/partes_providers.dart';

/// Calcula el set de logros desbloqueados a partir de los partes del usuario.
/// Replica las reglas de AchievementsChecker.kt (cálculo del lado del cliente).
Set<String> computarLogros(List<PartePesca> partes) {
  final unlocked = <String>{};
  if (partes.isEmpty) return unlocked;

  // Iniciación
  unlocked.add('mi_primer_parte');

  // Especies distintas a lo largo de toda la historia (para la colección).
  final especiesGlobales = <String>{};

  for (final p in partes) {
    final total = p.cantidadTotal;
    final especiesParte = p.peces;

    // Cantidad
    if (total == 0) unlocked.add('zapatero_wade');
    if (total == 1) unlocked.add('solo_un_pez');
    if (total >= 10) unlocked.add('pesca_abundante');

    // Ubicación
    if (p.ubicacion != null && !p.ubicacion!.vacia) unlocked.add('explorador');

    // Variedad en un mismo parte
    final distintasEnParte =
        especiesParte.map((c) => c.especie.toLowerCase()).toSet();
    if (distintasEnParte.length >= 5) unlocked.add('variedad_es_vida');

    // Especies concretas
    for (final c in especiesParte) {
      final nombre = c.especie.toLowerCase();
      if (nombre.isNotEmpty) especiesGlobales.add(nombre);

      if (nombre.contains('dorado')) {
        unlocked.add('cazador_de_dorados');
        if (c.cantidad >= 5) unlocked.add('rey_del_rio');
      }
      if (nombre.contains('surub')) {
        unlocked.add('amigo_del_surubi');
      }
      if (nombre.contains('pejerrey') && c.cantidad >= 10) {
        unlocked.add('pejerreyes_master');
      }
    }

    // Estacionales (fecha "yyyy-MM-dd")
    final f = _parseFecha(p.fecha);
    if (f != null) {
      final mes = f.$1, dia = f.$2;
      if (mes == 12 && dia >= 24 && dia <= 31) unlocked.add('pescador_navideño');
      if (mes == 1 && dia >= 1 && dia <= 7) unlocked.add('pescador_año_nuevo');
      if (mes == 1 && dia == 6) unlocked.add('regalo_de_reyes');
      if (mes >= 6 && mes <= 8) unlocked.add('pescador_invernal');
      if (mes >= 9 && mes <= 11) unlocked.add('pescador_primaveral');
    }

    // Horarios (horaInicio "HH:mm")
    final h = _parseHora(p.horaInicio);
    if (h != null) {
      if (h >= 5 && h <= 7) unlocked.add('madrugador');
      if (h >= 19 && h <= 23) unlocked.add('pescador_nocturno');
      if (h >= 0 && h <= 4) unlocked.add('noctambulo');
    }
  }

  // Colección Pescadex por cantidad de especies distintas
  final n = especiesGlobales.length;
  if (n >= 1) unlocked.add('pescadex_primer_pez');
  if (n >= 5) unlocked.add('pescadex_explorador');
  if (n >= 10) unlocked.add('pescadex_coleccionista');
  if (n >= 15) unlocked.add('pescadex_especialista');
  if (n >= 20) unlocked.add('pescadex_maestro');
  if (n >= 30) unlocked.add('pescadex_completista');
  // pescadex_cazador_raros / epicos requieren rareza por especie (fase futura).

  return unlocked;
}

(int, int)? _parseFecha(String? fecha) {
  if (fecha == null) return null;
  final parts = fecha.split('-');
  if (parts.length != 3) return null;
  final mes = int.tryParse(parts[1]);
  final dia = int.tryParse(parts[2]);
  if (mes == null || dia == null) return null;
  return (mes, dia);
}

int? _parseHora(String? hora) {
  if (hora == null) return null;
  return int.tryParse(hora.split(':').first);
}

/// Set de ids desbloqueados, reactivo a los partes.
final logrosDesbloqueadosProvider = Provider<Set<String>>((ref) {
  final partes = ref.watch(partesProvider).valueOrNull ?? const [];
  return computarLogros(partes);
});
