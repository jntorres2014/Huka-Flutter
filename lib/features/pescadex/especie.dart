/// Modelo de una especie de la Pescadex.
/// Mapea cada objeto de assets/peces_argentinos.json.
class Especie {
  final String nombre;
  final String cientifico;
  final String habitat;
  final List<String> carnadas;
  final String mejorHorario;
  final String tecnica;
  final String tamano;
  final String temporada;
  final List<String> sinonimos;

  const Especie({
    required this.nombre,
    required this.cientifico,
    required this.habitat,
    required this.carnadas,
    required this.mejorHorario,
    required this.tecnica,
    required this.tamano,
    required this.temporada,
    required this.sinonimos,
  });

  factory Especie.fromJson(Map<String, dynamic> json) {
    List<String> toStringList(dynamic v) =>
        (v as List?)?.map((e) => e.toString()).toList() ?? const [];

    return Especie(
      nombre: json['nombre']?.toString() ?? '',
      cientifico: json['cientifico']?.toString() ?? '',
      habitat: json['habitat']?.toString() ?? '',
      carnadas: toStringList(json['carnadas']),
      mejorHorario: json['mejor_horario']?.toString() ?? '',
      tecnica: json['tecnica']?.toString() ?? '',
      // En el JSON la clave usa "ñ": "tamaño".
      tamano: (json['tamaño'] ?? json['tamano'])?.toString() ?? '',
      temporada: json['temporada']?.toString() ?? '',
      sinonimos: toStringList(json['sinonimos']),
    );
  }

  /// Texto sobre el que se busca (nombre, científico y sinónimos).
  String get textoBusqueda =>
      '$nombre $cientifico ${sinonimos.join(' ')}'.toLowerCase();
}
