import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'torneo_models.dart';
import 'torneos_repository.dart';

final torneosRepositoryProvider = Provider<TorneosRepository>((ref) {
  return TorneosRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});

/// Lista de mis torneos (creados + donde participo). Se refresca al invalidar.
final misTorneosProvider = FutureProvider<List<Torneo>>((ref) {
  return ref.watch(torneosRepositoryProvider).obtenerMisTorneos();
});

/// Participantes de un torneo, en tiempo real.
final participantesProvider =
    StreamProvider.family<List<ParticipanteTorneo>, String>((ref, torneoId) {
  return ref.watch(torneosRepositoryProvider).observarParticipantes(torneoId);
});

/// Partes cargados a un torneo, en tiempo real.
final partesTorneoProvider =
    StreamProvider.family<List<ParteTorneo>, String>((ref, torneoId) {
  return ref.watch(torneosRepositoryProvider).observarPartes(torneoId);
});
