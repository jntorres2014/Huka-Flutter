import 'package:geolocator/geolocator.dart';

/// Resultado de pedir la ubicación.
class UbicacionResultado {
  final double? latitud;
  final double? longitud;
  final String? error;

  const UbicacionResultado({this.latitud, this.longitud, this.error});

  bool get ok => latitud != null && longitud != null;
}

/// Obtiene la ubicación actual con geolocator (equivalente a LocationDetector.kt).
/// Maneja servicios apagados y permisos denegados con mensajes claros.
class LocationService {
  Future<UbicacionResultado> obtenerActual() async {
    final habilitado = await Geolocator.isLocationServiceEnabled();
    if (!habilitado) {
      return const UbicacionResultado(
          error: 'El GPS está apagado. Activalo y reintentá.');
    }

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied) {
      return const UbicacionResultado(
          error: 'Necesito permiso de ubicación para detectar la zona.');
    }
    if (permiso == LocationPermission.deniedForever) {
      return const UbicacionResultado(
          error: 'El permiso de ubicación está bloqueado. '
              'Activalo desde los ajustes del teléfono.');
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return UbicacionResultado(latitud: pos.latitude, longitud: pos.longitude);
    } catch (e) {
      return UbicacionResultado(error: 'No se pudo obtener la ubicación: $e');
    }
  }
}
