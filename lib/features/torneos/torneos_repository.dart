import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../parte/parte_models.dart';
import 'torneo_models.dart';
import 'torneo_scoring.dart';

/// Acceso a Firestore para torneos (equivalente a TorneosFirebase.kt).
/// Estructura:
///   torneos/{id}
///   torneos/{id}/participantes/{userId}
///   torneos/{id}/partes/{parteId}
class TorneosRepository {
  TorneosRepository(this._db, this._auth);
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const _colTorneos = 'torneos';
  static const _colParticipantes = 'participantes';
  static const _colPartes = 'partes';

  User? get _user => _auth.currentUser;
  String get _uid => _user?.uid ?? '';
  String get uid => _uid;

  CollectionReference<Map<String, dynamic>> get _torneos =>
      _db.collection(_colTorneos);

  String _generarCodigo() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final r = Random();
    return List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
  }

  Future<String> crearTorneo({
    required String nombre,
    required String descripcion,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required TipoPuntaje tipoPuntaje,
    ReglasPuntaje? reglas,
  }) async {
    final docRef = _torneos.doc();
    final torneo = Torneo(
      id: docRef.id,
      nombre: nombre,
      descripcion: descripcion,
      creatorId: _uid,
      creatorName: _user?.displayName ?? 'Organizador',
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      tipoPuntaje: tipoPuntaje.id,
      // Solo persistimos reglas si el torneo es PERSONALIZADO.
      reglas: tipoPuntaje == TipoPuntaje.personalizado ? reglas : null,
      codigoInvitacion: _generarCodigo(),
    );
    await docRef.set(torneo.toMap());
    return torneo.codigoInvitacion;
  }

  Future<Torneo?> buscarPorCodigo(String codigo) async {
    final snap = await _torneos
        .where('codigoInvitacion', isEqualTo: codigo.trim().toUpperCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final d = snap.docs.first;
    return Torneo.fromMap(d.id, d.data());
  }

  Future<void> solicitarUnirse(String torneoId) async {
    final ref =
        _torneos.doc(torneoId).collection(_colParticipantes).doc(_uid);
    final existe = (await ref.get()).exists;
    if (existe) return;
    final participante = ParticipanteTorneo(
      userId: _uid,
      userName: _user?.displayName ?? 'Pescador',
      userPhoto: _user?.photoURL ?? '',
      estado: EstadoParticipante.pendiente.id,
    );
    await ref.set(participante.toMap());
  }

  Future<void> responderSolicitud(
      String torneoId, String participanteId, bool aceptar) async {
    await _torneos
        .doc(torneoId)
        .collection(_colParticipantes)
        .doc(participanteId)
        .update({
      'estado': (aceptar
              ? EstadoParticipante.aceptado
              : EstadoParticipante.rechazado)
          .id,
      'respondidoEn': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ParticipanteTorneo>> observarParticipantes(String torneoId) {
    return _torneos
        .doc(torneoId)
        .collection(_colParticipantes)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ParticipanteTorneo.fromMap(d.data())).toList());
  }

  /// Mis torneos: los que creé + aquellos donde soy participante.
  Future<List<Torneo>> obtenerMisTorneos() async {
    final creados =
        await _torneos.where('creatorId', isEqualTo: _uid).get();
    final mapa = <String, Torneo>{};
    for (final d in creados.docs) {
      mapa[d.id] = Torneo.fromMap(d.id, d.data());
    }

    // Torneos donde participo (collectionGroup sobre participantes).
    final comoParticipante = await _db
        .collectionGroup(_colParticipantes)
        .where('userId', isEqualTo: _uid)
        .get();
    for (final p in comoParticipante.docs) {
      final torneoRef = p.reference.parent.parent;
      if (torneoRef == null || mapa.containsKey(torneoRef.id)) continue;
      final tDoc = await torneoRef.get();
      if (tDoc.exists) {
        mapa[tDoc.id] = Torneo.fromMap(tDoc.id, tDoc.data()!);
      }
    }

    final lista = mapa.values.toList()
      ..sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));
    return lista;
  }

  bool esCreador(Torneo t) => t.creatorId == _uid;

  // ── Partes del torneo ──────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _partesRef(String torneoId) =>
      _torneos.doc(torneoId).collection(_colPartes);

  /// True si todavía no hay partes cargados (para el bonus de primer parte).
  Future<bool> esPrimerParteTorneo(String torneoId) async {
    final snap = await _partesRef(torneoId).limit(1).get();
    return snap.docs.isEmpty;
  }

  /// Partes cargados al torneo, en tiempo real.
  Stream<List<ParteTorneo>> observarPartes(String torneoId) {
    return _partesRef(torneoId).snapshots().map(
        (s) => s.docs.map((d) => ParteTorneo.fromMap(d.data())).toList());
  }

  /// Carga un parte del usuario al torneo, calcula el puntaje y lo suma al
  /// participante (equivalente a guardarParteTorneo + actualizarPuntaje).
  Future<int> cargarParte(Torneo torneo, PartePesca parte) async {
    final esPrimero = await esPrimerParteTorneo(torneo.id);
    final puntaje =
        calcularPuntaje(torneo, parte, esPrimerParte: esPrimero);
    final parteId =
        parte.id ?? 'pt_${DateTime.now().millisecondsSinceEpoch}';

    final pt = ParteTorneo(
      parteId: parteId,
      userId: _uid,
      userName: _user?.displayName ?? 'Pescador',
      fecha: parte.fecha ?? '',
      especies: parte.peces
          .map((c) => EspecieTorneo(nombre: c.especie, cantidad: c.cantidad))
          .toList(),
      puntaje: puntaje,
      estado: EstadoParteTorneo.activo.id,
    );

    await _partesRef(torneo.id).doc(parteId).set(pt.toMap());

    // Suma el puntaje al participante (transacción). Si no existe el doc
    // (caso del creador que también compite), lo crea.
    final pref =
        _torneos.doc(torneo.id).collection(_colParticipantes).doc(_uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(pref);
      if (!snap.exists) {
        tx.set(pref, {
          'userId': _uid,
          'userName': _user?.displayName ?? 'Pescador',
          'userPhoto': _user?.photoURL ?? '',
          'estado': EstadoParticipante.aceptado.id,
          'puntaje': puntaje,
          'parteIds': [parteId],
          'solicitadoEn': FieldValue.serverTimestamp(),
        });
        return;
      }
      final actual = (snap.data()?['puntaje'] as num?)?.toInt() ?? 0;
      final ids =
          (snap.data()?['parteIds'] as List?)?.map((e) => e.toString()).toList() ??
              <String>[];
      tx.update(pref, {
        'puntaje': actual + puntaje,
        'parteIds': [...ids, parteId],
      });
    });

    return puntaje;
  }

  /// Carga el parte automáticamente a TODOS los torneos activos donde el
  /// usuario es participante aceptado o creador (equivalente a onParteSaved).
  Future<void> cargarParteEnTorneosActivos(PartePesca parte) async {
    final torneos = await obtenerMisTorneos();
    for (final t in torneos) {
      if (t.estado != EstadoTorneo.activo) continue;

      var habilitado = t.creatorId == _uid;
      if (!habilitado) {
        final pdoc = await _torneos
            .doc(t.id)
            .collection(_colParticipantes)
            .doc(_uid)
            .get();
        habilitado = pdoc.exists &&
            pdoc.data()?['estado'] == EstadoParticipante.aceptado.id;
      }
      if (!habilitado) continue;

      try {
        await cargarParte(t, parte);
      } catch (_) {
        // Si falla en un torneo, seguimos con los demás.
      }
    }
  }

  /// Rechaza un parte (admin): lo marca RECHAZADO y resta el puntaje.
  Future<void> rechazarParte(String torneoId, ParteTorneo parte) async {
    await _partesRef(torneoId)
        .doc(parte.parteId)
        .update({'estado': EstadoParteTorneo.rechazado.id});

    final pref = _torneos
        .doc(torneoId)
        .collection(_colParticipantes)
        .doc(parte.userId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(pref);
      final actual = (snap.data()?['puntaje'] as num?)?.toInt() ?? 0;
      final ids =
          (snap.data()?['parteIds'] as List?)?.map((e) => e.toString()).toList() ??
              <String>[];
      final nuevo = (actual - parte.puntaje).clamp(0, 1 << 30);
      tx.update(pref, {
        'puntaje': nuevo,
        'parteIds': ids.where((x) => x != parte.parteId).toList(),
      });
    });
  }
}
