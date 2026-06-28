import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../parte/parte_models.dart';

/// Item del contador (equivalente a EspecieCapturada de ChatModes.kt).
class ContadorItem {
  final String nombre;
  final int cantidad;

  const ContadorItem({required this.nombre, this.cantidad = 0});

  ContadorItem copyWith({int? cantidad}) =>
      ContadorItem(nombre: nombre, cantidad: cantidad ?? this.cantidad);

  Map<String, dynamic> toMap() => {'nombre': nombre, 'cantidad': cantidad};

  factory ContadorItem.fromMap(Map<String, dynamic> m) => ContadorItem(
        nombre: m['nombre']?.toString() ?? '',
        cantidad: (m['cantidad'] as num?)?.toInt() ?? 0,
      );

  Captura toCaptura() => Captura(especie: nombre, cantidad: cantidad);
}

/// Estado del contador en vivo (equivalente a FishCounterManager.kt).
/// Persiste un backup en shared_preferences entre sesiones.
class ContadorNotifier extends StateNotifier<List<ContadorItem>> {
  ContadorNotifier() : super(const []) {
    _restaurar();
  }

  static const _key = 'contador_peces_backup';

  int get total => state.fold(0, (s, e) => s + e.cantidad);

  int _indice(String nombre) =>
      state.indexWhere((e) => e.nombre.toLowerCase() == nombre.toLowerCase());

  void agregar(String nombre, int cantidad) {
    if (nombre.trim().isEmpty || cantidad <= 0) return;
    final i = _indice(nombre);
    final lista = [...state];
    if (i >= 0) {
      lista[i] = lista[i].copyWith(cantidad: lista[i].cantidad + cantidad);
    } else {
      lista.add(ContadorItem(nombre: nombre.trim(), cantidad: cantidad));
    }
    state = lista;
    _guardar();
  }

  void incrementar(String nombre) => agregar(nombre, 1);

  void decrementar(String nombre) {
    final i = _indice(nombre);
    if (i < 0) return;
    final lista = [...state];
    final nueva = lista[i].cantidad - 1;
    if (nueva <= 0) {
      lista.removeAt(i);
    } else {
      lista[i] = lista[i].copyWith(cantidad: nueva);
    }
    state = lista;
    _guardar();
  }

  void eliminar(String nombre) {
    state = state.where((e) => e.nombre != nombre).toList();
    _guardar();
  }

  void limpiar() {
    state = const [];
    _guardar();
  }

  Future<void> _guardar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(state.map((e) => e.toMap()).toList()));
  }

  Future<void> _restaurar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as List<dynamic>;
      state = data
          .map((e) => ContadorItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      // Backup corrupto: lo ignoramos.
    }
  }
}

final contadorProvider =
    StateNotifierProvider<ContadorNotifier, List<ContadorItem>>((ref) {
  return ContadorNotifier();
});

/// Total de capturas en el contador (derivado).
final contadorTotalProvider = Provider<int>((ref) {
  return ref.watch(contadorProvider).fold(0, (s, e) => s + e.cantidad);
});
