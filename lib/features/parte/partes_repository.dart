import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'parte_models.dart';

/// Acceso a Firestore para partes de pesca.
/// Estructura (igual a PartesFirebase.kt / Constants.kt):
///   partes_pesca/{userId}/partes/{parteId}
class PartesRepository {
  PartesRepository(this._db, this._auth);
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const _coleccionRaiz = 'partes_pesca';
  static const _subcoleccion = 'partes';

  String get _uid => _auth.currentUser?.uid ?? '';

  CollectionReference<Map<String, dynamic>> get _partesRef =>
      _db.collection(_coleccionRaiz).doc(_uid).collection(_subcoleccion);

  /// Genera un id estilo "parte_<timestamp>" (como generarIdParte()).
  String _nuevoId() => 'parte_${DateTime.now().millisecondsSinceEpoch}';

  Future<void> guardarParte(PartePesca parte) async {
    final id = parte.id ?? _nuevoId();
    final data = parte.toMap()
      ..['id'] = id
      ..['userId'] = _uid;
    await _partesRef.doc(id).set(data, SetOptions(merge: true));
  }

  /// Lista en tiempo real, más recientes primero (orderBy timestamp DESC).
  Stream<List<PartePesca>> observarPartes() {
    return _partesRef
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => PartePesca.fromMap(d.id, d.data())).toList());
  }

  Future<void> eliminarParte(String id) => _partesRef.doc(id).delete();
}
