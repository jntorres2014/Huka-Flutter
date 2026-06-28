import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipo de puntaje (equivalente a TipoPuntaje de Tournamentmodel.kt).
enum TipoPuntaje {
  cantidadPeces('CANTIDAD_PECES', 'Cantidad de peces'),
  especiesDistintas('ESPECIES_DISTINTAS', 'Especies distintas'),
  personalizado('PERSONALIZADO', 'Reglas personalizadas');

  const TipoPuntaje(this.id, this.display);
  final String id;
  final String display;

  static TipoPuntaje fromId(String? id) =>
      values.firstWhere((e) => e.id == id, orElse: () => cantidadPeces);
}

enum EstadoTorneo { proximo, activo, finalizado }

enum EstadoParticipante {
  pendiente('PENDIENTE'),
  aceptado('ACEPTADO'),
  rechazado('RECHAZADO');

  const EstadoParticipante(this.id);
  final String id;

  static EstadoParticipante fromId(String? id) =>
      values.firstWhere((e) => e.id == id, orElse: () => pendiente);
}

/// Torneo (equivalente a data class Torneo).
class Torneo {
  final String id;
  final String nombre;
  final String descripcion;
  final String creatorId;
  final String creatorName;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String tipoPuntaje;
  final String reglasPersonalizadas;
  final ReglasPuntaje? reglas;
  final String codigoInvitacion;
  final DateTime? creadoEn;

  const Torneo({
    this.id = '',
    this.nombre = '',
    this.descripcion = '',
    this.creatorId = '',
    this.creatorName = '',
    required this.fechaInicio,
    required this.fechaFin,
    this.tipoPuntaje = 'CANTIDAD_PECES',
    this.reglasPersonalizadas = '',
    this.reglas,
    this.codigoInvitacion = '',
    this.creadoEn,
  });

  TipoPuntaje get tipoPuntajeEnum => TipoPuntaje.fromId(tipoPuntaje);

  EstadoTorneo get estado {
    final ahora = DateTime.now();
    if (ahora.isBefore(fechaInicio)) return EstadoTorneo.proximo;
    if (ahora.isAfter(fechaFin)) return EstadoTorneo.finalizado;
    return EstadoTorneo.activo;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'creatorId': creatorId,
        'creatorName': creatorName,
        'fechaInicio': Timestamp.fromDate(fechaInicio),
        'fechaFin': Timestamp.fromDate(fechaFin),
        'tipoPuntaje': tipoPuntaje,
        'reglasPersonalizadas': reglasPersonalizadas,
        'reglas': reglas?.toMap(),
        'codigoInvitacion': codigoInvitacion,
        'creadoEn':
            creadoEn != null ? Timestamp.fromDate(creadoEn!) : FieldValue.serverTimestamp(),
      };

  factory Torneo.fromMap(String id, Map<String, dynamic> m) {
    DateTime ts(dynamic v) => v is Timestamp ? v.toDate() : DateTime.now();
    return Torneo(
      id: id,
      nombre: m['nombre']?.toString() ?? '',
      descripcion: m['descripcion']?.toString() ?? '',
      creatorId: m['creatorId']?.toString() ?? '',
      creatorName: m['creatorName']?.toString() ?? '',
      fechaInicio: ts(m['fechaInicio']),
      fechaFin: ts(m['fechaFin']),
      tipoPuntaje: m['tipoPuntaje']?.toString() ?? 'CANTIDAD_PECES',
      reglasPersonalizadas: m['reglasPersonalizadas']?.toString() ?? '',
      reglas: m['reglas'] is Map
          ? ReglasPuntaje.fromMap(Map<String, dynamic>.from(m['reglas'] as Map))
          : null,
      codigoInvitacion: m['codigoInvitacion']?.toString() ?? '',
      creadoEn: m['creadoEn'] is Timestamp
          ? (m['creadoEn'] as Timestamp).toDate()
          : null,
    );
  }
}

/// Reglas de puntaje componibles para torneos PERSONALIZADO
/// (equivalente a data class ReglasPuntaje). Son aditivas.
class ReglasPuntaje {
  final int? bonusPrimerParte;
  final int? puntosPorPez;
  final Map<String, int>? puntosPorEspecie; // especieId -> puntos
  final int puntosOtrosPeces;

  const ReglasPuntaje({
    this.bonusPrimerParte,
    this.puntosPorPez,
    this.puntosPorEspecie,
    this.puntosOtrosPeces = 0,
  });

  bool get tieneAlgunaRegla =>
      bonusPrimerParte != null ||
      puntosPorPez != null ||
      (puntosPorEspecie != null && puntosPorEspecie!.isNotEmpty);

  Map<String, dynamic> toMap() => {
        'bonusPrimerParte': bonusPrimerParte,
        'puntosPorPez': puntosPorPez,
        'puntosPorEspecie': puntosPorEspecie,
        'puntosOtrosPeces': puntosOtrosPeces,
      };

  factory ReglasPuntaje.fromMap(Map<String, dynamic> m) {
    Map<String, int>? tabla;
    if (m['puntosPorEspecie'] is Map) {
      tabla = (m['puntosPorEspecie'] as Map).map(
          (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0));
    }
    return ReglasPuntaje(
      bonusPrimerParte: (m['bonusPrimerParte'] as num?)?.toInt(),
      puntosPorPez: (m['puntosPorPez'] as num?)?.toInt(),
      puntosPorEspecie: tabla,
      puntosOtrosPeces: (m['puntosOtrosPeces'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Normaliza un nombre de especie a id para la tabla `puntosPorEspecie`
/// (igual que normalizarParaIdTorneo: minúsculas + sin acentos).
String normalizarParaIdTorneo(String nombre) {
  var s = nombre.toLowerCase();
  const acentos = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ñ': 'n'};
  acentos.forEach((k, v) => s = s.replaceAll(k, v));
  return s.trim();
}

/// Participante de un torneo (equivalente a ParticipanteTorneo).
class ParticipanteTorneo {
  final String userId;
  final String userName;
  final String userPhoto;
  final String estado;
  final int puntaje;
  final List<String> parteIds;

  const ParticipanteTorneo({
    this.userId = '',
    this.userName = '',
    this.userPhoto = '',
    this.estado = 'PENDIENTE',
    this.puntaje = 0,
    this.parteIds = const [],
  });

  EstadoParticipante get estadoEnum => EstadoParticipante.fromId(estado);

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'userPhoto': userPhoto,
        'estado': estado,
        'puntaje': puntaje,
        'parteIds': parteIds,
        'solicitadoEn': FieldValue.serverTimestamp(),
      };

  factory ParticipanteTorneo.fromMap(Map<String, dynamic> m) =>
      ParticipanteTorneo(
        userId: m['userId']?.toString() ?? '',
        userName: m['userName']?.toString() ?? '',
        userPhoto: m['userPhoto']?.toString() ?? '',
        estado: m['estado']?.toString() ?? 'PENDIENTE',
        puntaje: (m['puntaje'] as num?)?.toInt() ?? 0,
        parteIds: (m['parteIds'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
      );
}

/// Torneo + participantes para la UI (equivalente a TorneoConParticipantes).
class TorneoConParticipantes {
  final Torneo torneo;
  final List<ParticipanteTorneo> participantes;
  final bool soyCreador;

  const TorneoConParticipantes({
    required this.torneo,
    this.participantes = const [],
    this.soyCreador = false,
  });

  List<ParticipanteTorneo> get pendientes => participantes
      .where((p) => p.estadoEnum == EstadoParticipante.pendiente)
      .toList();

  List<ParticipanteTorneo> get aceptados => participantes
      .where((p) => p.estadoEnum == EstadoParticipante.aceptado)
      .toList()
    ..sort((a, b) => b.puntaje.compareTo(a.puntaje));
}

enum EstadoParteTorneo {
  activo('ACTIVO'),
  rechazado('RECHAZADO');

  const EstadoParteTorneo(this.id);
  final String id;

  static EstadoParteTorneo fromId(String? id) =>
      values.firstWhere((e) => e.id == id, orElse: () => activo);
}

/// Una especie dentro de un parte de torneo.
class EspecieTorneo {
  final String nombre;
  final int cantidad;
  const EspecieTorneo({this.nombre = '', this.cantidad = 0});

  Map<String, dynamic> toMap() => {'nombre': nombre, 'cantidad': cantidad};

  factory EspecieTorneo.fromMap(Map<String, dynamic> m) => EspecieTorneo(
        nombre: m['nombre']?.toString() ?? '',
        cantidad: (m['cantidad'] as num?)?.toInt() ?? 0,
      );
}

/// Un parte cargado a un torneo (equivalente a data class ParteTorneo).
class ParteTorneo {
  final String parteId;
  final String userId;
  final String userName;
  final String fecha;
  final List<EspecieTorneo> especies;
  final int puntaje;
  final String estado;
  final String motivoRechazo;

  const ParteTorneo({
    this.parteId = '',
    this.userId = '',
    this.userName = '',
    this.fecha = '',
    this.especies = const [],
    this.puntaje = 0,
    this.estado = 'ACTIVO',
    this.motivoRechazo = '',
  });

  EstadoParteTorneo get estadoEnum => EstadoParteTorneo.fromId(estado);
  int get totalPeces => especies.fold(0, (s, e) => s + e.cantidad);

  Map<String, dynamic> toMap() => {
        'parteId': parteId,
        'userId': userId,
        'userName': userName,
        'fecha': fecha,
        'especies': especies.map((e) => e.toMap()).toList(),
        'puntaje': puntaje,
        'estado': estado,
        'motivoRechazo': motivoRechazo,
        'creadoEn': FieldValue.serverTimestamp(),
      };

  factory ParteTorneo.fromMap(Map<String, dynamic> m) => ParteTorneo(
        parteId: m['parteId']?.toString() ?? '',
        userId: m['userId']?.toString() ?? '',
        userName: m['userName']?.toString() ?? '',
        fecha: m['fecha']?.toString() ?? '',
        especies: (m['especies'] as List?)
                ?.map((e) =>
                    EspecieTorneo.fromMap(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        puntaje: (m['puntaje'] as num?)?.toInt() ?? 0,
        estado: m['estado']?.toString() ?? 'ACTIVO',
        motivoRechazo: m['motivoRechazo']?.toString() ?? '',
      );
}
