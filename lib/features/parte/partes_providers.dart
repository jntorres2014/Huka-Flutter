import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'parte_models.dart';
import 'partes_repository.dart';

final partesRepositoryProvider = Provider<PartesRepository>((ref) {
  return PartesRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

/// Stream de partes del usuario (alimenta la pantalla de Reportes).
final partesProvider = StreamProvider<List<PartePesca>>((ref) {
  return ref.watch(partesRepositoryProvider).observarPartes();
});

/// Capturas que el Contador pasa al wizard de Crear parte. El wizard las
/// consume al iniciarse y vuelve a vaciar este provider.
final capturasInicialesProvider =
    StateProvider<List<Captura>>((ref) => const []);

/// Estadísticas derivadas de los partes (equivalente al ReportesViewModel).
class EstadisticasReportes {
  final int totalJornadas;
  final int totalCapturas;
  final String especieTop;
  final double promedioPorJornada;

  const EstadisticasReportes({
    required this.totalJornadas,
    required this.totalCapturas,
    required this.especieTop,
    required this.promedioPorJornada,
  });
}

final estadisticasProvider = Provider<EstadisticasReportes>((ref) {
  final partes = ref.watch(partesProvider).valueOrNull ?? const [];
  final totalJornadas = partes.length;
  final totalCapturas =
      partes.fold<int>(0, (acc, p) => acc + p.cantidadTotal);

  final conteoEspecies = <String, int>{};
  for (final p in partes) {
    for (final c in p.peces) {
      if (c.especie.isEmpty) continue;
      conteoEspecies[c.especie] =
          (conteoEspecies[c.especie] ?? 0) + (c.cantidad <= 0 ? 1 : c.cantidad);
    }
  }
  String especieTop = '—';
  int max = 0;
  conteoEspecies.forEach((esp, n) {
    if (n > max) {
      max = n;
      especieTop = esp;
    }
  });

  return EstadisticasReportes(
    totalJornadas: totalJornadas,
    totalCapturas: totalCapturas,
    especieTop: especieTop,
    promedioPorJornada:
        totalJornadas == 0 ? 0 : totalCapturas / totalJornadas,
  );
});
