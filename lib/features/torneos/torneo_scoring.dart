import '../parte/parte_models.dart';
import 'torneo_models.dart';

/// Calcula el puntaje de un parte para un torneo (equivalente a
/// TorneosViewModel.calcularPuntaje).
///
/// - CANTIDAD_PECES: 1 punto por cada ejemplar.
/// - ESPECIES_DISTINTAS: 1 punto por cada especie distinta.
/// - PERSONALIZADO con reglas: aplica las 3 reglas aditivamente (bonus primer
///   parte, puntos por pez, tabla por especie + "otros"). Sin reglas: fallback
///   a CANTIDAD_PECES (igual que los torneos viejos de la app original).
int calcularPuntaje(Torneo torneo, PartePesca parte, {bool esPrimerParte = false}) {
  final total = parte.peces
      .fold<int>(0, (s, c) => s + (c.cantidad <= 0 ? 1 : c.cantidad));

  switch (torneo.tipoPuntajeEnum) {
    case TipoPuntaje.cantidadPeces:
      return total;
    case TipoPuntaje.especiesDistintas:
      return parte.peces
          .map((c) => c.especie.toLowerCase())
          .where((n) => n.isNotEmpty)
          .toSet()
          .length;
    case TipoPuntaje.personalizado:
      final reglas = torneo.reglas;
      if (reglas == null || !reglas.tieneAlgunaRegla) return total;
      return _aplicarReglas(reglas, parte, esPrimerParte);
  }
}

/// Aplica las reglas componibles (equivalente a aplicarReglasPersonalizadas).
int _aplicarReglas(ReglasPuntaje reglas, PartePesca parte, bool esPrimerParte) {
  var total = 0;

  // Regla 1: bonus al primer parte del torneo.
  if (esPrimerParte && reglas.bonusPrimerParte != null) {
    total += reglas.bonusPrimerParte!;
  }

  final cantPorPez = (Captura c) => c.cantidad <= 0 ? 1 : c.cantidad;

  // Regla 2: X puntos por cada pez.
  if (reglas.puntosPorPez != null) {
    final totalPeces =
        parte.peces.fold<int>(0, (s, c) => s + cantPorPez(c));
    total += totalPeces * reglas.puntosPorPez!;
  }

  // Regla 3: tabla por especie + catch-all "otros".
  final tabla = reglas.puntosPorEspecie;
  if (tabla != null && tabla.isNotEmpty) {
    for (final c in parte.peces) {
      final id = normalizarParaIdTorneo(c.especie);
      final pts = tabla[id] ?? reglas.puntosOtrosPeces;
      total += pts * cantPorPez(c);
    }
  }

  return total;
}
