import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'especie_descubierta.dart';

/// Lee la Pescadex del usuario (equivalente a PescadexManager.kt).
/// Documento: pescadex_usuarios/{uid}, campo `especiesDescubiertas`
/// (mapa especieId -> datos de la especie capturada).
class PescadexUsuarioRepository {
  PescadexUsuarioRepository(this._db, this._auth);
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const _coleccion = 'pescadex_usuarios';

  String get _uid => _auth.currentUser?.uid ?? '';

  /// Mapa especieId -> EspecieDescubierta, en tiempo real.
  Stream<Map<String, EspecieDescubierta>> observar() {
    if (_uid.isEmpty) {
      return Stream.value(const {});
    }
    return _db.collection(_coleccion).doc(_uid).snapshots().map((snap) {
      final data = snap.data();
      final mapa = data?['especiesDescubiertas'];
      if (mapa is! Map) return <String, EspecieDescubierta>{};
      final result = <String, EspecieDescubierta>{};
      mapa.forEach((key, value) {
        if (value is Map) {
          result[key.toString()] =
              EspecieDescubierta.fromMap(Map<String, dynamic>.from(value));
        }
      });
      return result;
    });
  }
}
