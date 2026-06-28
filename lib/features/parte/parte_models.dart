import 'package:cloud_firestore/cloud_firestore.dart';

/// Modalidad de pesca (equivalente al enum ModalidadPesca de ChatModes.kt).
enum ModalidadPesca {
  conLineaCosta('CON_LINEA_COSTA', 'Desde costa', '🏖️'),
  conLineaEmbarcacion('CON_LINEA_EMBARCACION', 'Embarcado', '🚤'),
  conRed('CON_RED', 'Con red', '🕸️'),
  pescaSubmarinaCosta('PESCA_SUBMARINA_COSTA', 'Submarina', '🤿'),
  pescaSubmarinaEmbarcacion(
      'PESCA_SUBMARINA_EMBARCACION', 'Submarina embarcado', '🤿🚤');

  const ModalidadPesca(this.id, this.display, this.emoji);
  final String id;
  final String display;
  final String emoji;

  static ModalidadPesca? fromId(String? id) {
    if (id == null) return null;
    for (final m in values) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Matchea por displayName (como lo guarda la app Kotlin en el campo `tipo`,
  /// ej: "con línea costa"). Comparación flexible, sin distinguir mayúsculas.
  static ModalidadPesca? fromDisplay(String? texto) {
    if (texto == null || texto.isEmpty) return null;
    final t = texto.toLowerCase();
    for (final m in values) {
      final d = m.display.toLowerCase();
      if (d == t || t.contains(d) || d.contains(t)) return m;
    }
    return null;
  }
}

/// Una captura dentro de un parte (equivalente a data class Captura).
class Captura {
  final String especie;
  final int cantidad;

  const Captura({required this.especie, this.cantidad = 0});

  Map<String, dynamic> toMap() => {'especie': especie, 'cantidad': cantidad};

  factory Captura.fromMap(Map<String, dynamic> m) => Captura(
        especie: m['especie']?.toString() ?? '',
        cantidad: (m['cantidad'] as num?)?.toInt() ?? 0,
      );
}

/// Ubicación de un parte (equivalente a UbicacionParte).
class UbicacionParte {
  final String? nombre;
  final double? latitud;
  final double? longitud;
  final String? zona;

  const UbicacionParte({this.nombre, this.latitud, this.longitud, this.zona});

  bool get vacia =>
      (nombre == null || nombre!.isEmpty) &&
      latitud == null &&
      longitud == null &&
      (zona == null || zona!.isEmpty);

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'latitud': latitud,
        'longitud': longitud,
        'zona': zona,
      };

  factory UbicacionParte.fromMap(Map<String, dynamic> m) => UbicacionParte(
        nombre: m['nombre']?.toString(),
        latitud: (m['latitud'] as num?)?.toDouble(),
        longitud: (m['longitud'] as num?)?.toDouble(),
        zona: m['zona']?.toString(),
      );
}

/// Parte de pesca (equivalente a data class PartePesca de ModelsFirebase.kt).
class PartePesca {
  final String? id;
  final String? userId;
  final String? fecha; // "yyyy-MM-dd"
  final String? horaInicio; // "HH:mm"
  final String? horaFin;
  final DateTime? timestamp;
  final String? duracionHoras;
  final ModalidadPesca? modalidad;
  // Campo legacy de la app Kotlin: displayName en minúsculas o texto libre.
  final String? tipo;
  final String? modalidadOtra;
  final int cantidadTotal;
  final String? observaciones;
  final int numeroCanas;
  final String? estado;
  final UbicacionParte? ubicacion;
  final List<Captura> peces;
  final List<String> fotos;

  const PartePesca({
    this.id,
    this.userId,
    this.fecha,
    this.horaInicio,
    this.horaFin,
    this.timestamp,
    this.duracionHoras,
    this.modalidad,
    this.tipo,
    this.modalidadOtra,
    this.cantidadTotal = 0,
    this.observaciones,
    this.numeroCanas = 0,
    this.estado,
    this.ubicacion,
    this.peces = const [],
    this.fotos = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'fecha': fecha,
        'horaInicio': horaInicio,
        'horaFin': horaFin,
        'timestamp': timestamp != null
            ? Timestamp.fromDate(timestamp!)
            : FieldValue.serverTimestamp(),
        'duracionHoras': duracionHoras,
        'modalidad': modalidad?.id,
        // 'tipo' replica el formato Kotlin (displayName en minúsculas) para
        // que la app Android existente siga leyendo estos partes.
        'tipo': tipo ?? modalidadOtra ?? modalidad?.display.toLowerCase(),
        'modalidadOtra': modalidadOtra,
        'cantidadTotal': cantidadTotal,
        'observaciones': observaciones,
        'numeroCanas': numeroCanas,
        'estado': estado ?? 'completado',
        'ubicacion': ubicacion?.toMap(),
        'peces': peces.map((p) => p.toMap()).toList(),
        'fotos': fotos,
      };

  factory PartePesca.fromMap(String id, Map<String, dynamic> m) {
    final ts = m['timestamp'];
    return PartePesca(
      id: id,
      userId: m['userId']?.toString(),
      fecha: m['fecha']?.toString(),
      horaInicio: m['horaInicio']?.toString(),
      horaFin: m['horaFin']?.toString(),
      timestamp: ts is Timestamp ? ts.toDate() : null,
      duracionHoras: m['duracionHoras']?.toString(),
      // Lee 'modalidad' (formato nuevo) y, si no está, deduce del 'tipo' legacy.
      modalidad: ModalidadPesca.fromId(m['modalidad']?.toString()) ??
          ModalidadPesca.fromDisplay(m['tipo']?.toString()),
      tipo: m['tipo']?.toString(),
      modalidadOtra: m['modalidadOtra']?.toString(),
      cantidadTotal: (m['cantidadTotal'] as num?)?.toInt() ?? 0,
      observaciones: m['observaciones']?.toString(),
      numeroCanas: (m['numeroCanas'] as num?)?.toInt() ?? 0,
      estado: m['estado']?.toString(),
      ubicacion: m['ubicacion'] is Map
          ? UbicacionParte.fromMap(
              Map<String, dynamic>.from(m['ubicacion'] as Map))
          : null,
      peces: (m['peces'] as List?)
              ?.map((e) => Captura.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      fotos: (m['fotos'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }

  /// Etiqueta de modalidad lista para mostrar.
  String get modalidadLabel =>
      modalidad?.display ??
      modalidadOtra ??
      (tipo != null && tipo!.isNotEmpty
          ? '${tipo![0].toUpperCase()}${tipo!.substring(1)}'
          : 'Sin especificar');
}
