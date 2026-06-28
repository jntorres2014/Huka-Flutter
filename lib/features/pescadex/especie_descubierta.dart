import 'package:cloud_firestore/cloud_firestore.dart';

/// Una especie que el usuario ya capturó (equivalente a EspecieDescubierta.kt).
/// Vive dentro del mapa `especiesDescubiertas` del doc pescadex_usuarios/{uid}.
class EspecieDescubierta {
  final int totalCapturas;
  final double? pesoRecord;
  final String? primeraFoto; // URL en Firebase Storage
  final String rareza;
  final int mejorDiaCantidad;
  final String? mejorDiaFecha;
  final DateTime? fechaDescubrimiento;

  const EspecieDescubierta({
    this.totalCapturas = 0,
    this.pesoRecord,
    this.primeraFoto,
    this.rareza = 'comun',
    this.mejorDiaCantidad = 0,
    this.mejorDiaFecha,
    this.fechaDescubrimiento,
  });

  bool get tieneFoto => primeraFoto != null && primeraFoto!.isNotEmpty;

  factory EspecieDescubierta.fromMap(Map<String, dynamic> m) {
    final fd = m['fechaDescubrimiento'];
    return EspecieDescubierta(
      totalCapturas: (m['totalCapturas'] as num?)?.toInt() ?? 0,
      pesoRecord: (m['pesoRecord'] as num?)?.toDouble(),
      primeraFoto: m['primeraFoto']?.toString(),
      rareza: m['rareza']?.toString() ?? 'comun',
      mejorDiaCantidad: (m['mejorDiaCantidad'] as num?)?.toInt() ?? 0,
      mejorDiaFecha: m['mejorDiaFecha']?.toString(),
      fechaDescubrimiento: fd is Timestamp ? fd.toDate() : null,
    );
  }
}

/// Normaliza un nombre a id (igual que normalizarParaId de PescadexManager.kt):
/// minúsculas, sin acentos/ñ, y no-alfanuméricos -> "_".
String normalizarParaId(String nombre) {
  var s = nombre.toLowerCase();
  const acentos = {
    'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ñ': 'n', 'ü': 'u'
  };
  acentos.forEach((k, v) => s = s.replaceAll(k, v));
  s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  return s.replaceAll(RegExp(r'^_+|_+$'), '');
}
