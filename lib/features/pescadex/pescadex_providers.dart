import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'especie.dart';
import 'especie_descubierta.dart';
import 'pescadex_repository.dart';
import 'pescadex_usuario_repository.dart';

final pescadexRepositoryProvider = Provider((ref) => PescadexRepository());

/// Lista completa de especies cargada del JSON.
final especiesProvider = FutureProvider<List<Especie>>((ref) {
  return ref.watch(pescadexRepositoryProvider).cargarEspecies();
});

/// Texto de búsqueda actual.
final busquedaProvider = StateProvider<String>((ref) => '');

/// Filtro por estado de captura.
enum FiltroPescadex { todas, capturadas, porDescubrir }

final filtroPescadexProvider =
    StateProvider<FiltroPescadex>((ref) => FiltroPescadex.todas);

/// Especies filtradas SOLO por el texto de búsqueda.
final especiesFiltradasProvider = Provider<AsyncValue<List<Especie>>>((ref) {
  final especies = ref.watch(especiesProvider);
  final q = ref.watch(busquedaProvider).trim().toLowerCase();
  return especies.whenData((lista) {
    if (q.isEmpty) return lista;
    return lista.where((e) => e.textoBusqueda.contains(q)).toList();
  });
});

/// Repositorio + stream de la Pescadex del usuario (especies capturadas).
final pescadexUsuarioRepositoryProvider =
    Provider((ref) => PescadexUsuarioRepository(
          FirebaseFirestore.instance,
          FirebaseAuth.instance,
        ));

/// Mapa especieId -> EspecieDescubierta del usuario, en tiempo real.
final descubiertasProvider =
    StreamProvider<Map<String, EspecieDescubierta>>((ref) {
  return ref.watch(pescadexUsuarioRepositoryProvider).observar();
});
