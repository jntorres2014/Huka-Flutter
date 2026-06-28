import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../torneos/torneos_providers.dart';
import 'location_service.dart';
import 'parte_models.dart';
import 'partes_providers.dart';

/// Wizard de creación de parte (equivalente a ParteWizardScreen.kt).
class CrearParteScreen extends ConsumerStatefulWidget {
  const CrearParteScreen({super.key});

  @override
  ConsumerState<CrearParteScreen> createState() => _CrearParteScreenState();
}

class _CrearParteScreenState extends ConsumerState<CrearParteScreen> {
  int _paso = 0;
  bool _guardando = false;

  // Datos del parte en construcción.
  ModalidadPesca? _modalidad;
  DateTime _fecha = DateTime.now();
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
  final List<Captura> _capturas = [];
  final _ubicacionCtrl = TextEditingController();
  final _zonaCtrl = TextEditingController();
  int _numeroCanas = 1;
  final _obsCtrl = TextEditingController();

  // Ubicación GPS.
  double? _lat;
  double? _lon;
  bool _ubicCargando = false;

  @override
  void initState() {
    super.initState();
    // Si venimos del Contador, precargamos las capturas contadas.
    final iniciales = ref.read(capturasInicialesProvider);
    if (iniciales.isNotEmpty) {
      _capturas.addAll(iniciales);
      // Vaciamos el provider para no recargarlas la próxima vez.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(capturasInicialesProvider.notifier).state = const [];
      });
    }
  }

  Future<void> _detectarUbicacion() async {
    setState(() => _ubicCargando = true);
    final res = await LocationService().obtenerActual();
    if (!mounted) return;
    setState(() {
      _ubicCargando = false;
      if (res.ok) {
        _lat = res.latitud;
        _lon = res.longitud;
      }
    });
    if (!res.ok && res.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(res.error!)));
    }
  }

  @override
  void dispose() {
    _ubicacionCtrl.dispose();
    _zonaCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  int get _cantidadTotal =>
      _capturas.fold(0, (s, c) => s + (c.cantidad <= 0 ? 1 : c.cantidad));

  /// Completado estilo ParteLogicUseCase.kt: % sobre campos obligatorios +
  /// opcionales, lista de faltantes y si los obligatorios están OK.
  /// Obligatorios: fecha (siempre), modalidad, especies (≥1 captura).
  /// Opcionales: provincia/zona, hora inicio, hora fin, cañas, lugar.
  ({int porcentaje, List<String> faltantes, bool obligatoriosOk}) _progreso() {
    final campos = <String, bool>{
      'fecha': true,
      'modalidad': _modalidad != null,
      'especies': _capturas.isNotEmpty,
      'provincia': _zonaCtrl.text.trim().isNotEmpty,
      'hora inicio': _horaInicio != null,
      'hora fin': _horaFin != null,
      'cañas': _numeroCanas > 0,
      'lugar': _ubicacionCtrl.text.trim().isNotEmpty ||
          (_lat != null && _lon != null),
    };
    final completos = campos.values.where((v) => v).length;
    final pct = (completos / campos.length * 100).round();
    final faltantes =
        campos.entries.where((e) => !e.value).map((e) => e.key).toList();
    final obligatoriosOk = _modalidad != null && _capturas.isNotEmpty;
    return (porcentaje: pct, faltantes: faltantes, obligatoriosOk: obligatoriosOk);
  }

  /// Habilita guardar: obligatorios completos y ≥70% (como el original).
  bool get _puedeGuardar {
    final p = _progreso();
    return p.obligatoriosOk && p.porcentaje >= 70;
  }

  void _avisar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _guardar() async {
    if (!_puedeGuardar) {
      final p = _progreso();
      if (!p.obligatoriosOk) {
        final faltan = [
          if (_modalidad == null) 'modalidad',
          if (_capturas.isEmpty) 'al menos una captura',
        ].join(', ');
        _avisar('Faltan datos obligatorios: $faltan.');
      } else {
        _avisar('Completá más datos (vas ${p.porcentaje}%). '
            'Falta: ${p.faltantes.take(3).join(', ')}.');
      }
      return;
    }
    setState(() => _guardando = true);
    final df = DateFormat('yyyy-MM-dd');
    String? hhmm(TimeOfDay? t) => t == null
        ? null
        : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    final ubic = UbicacionParte(
      nombre: _ubicacionCtrl.text.trim().isEmpty
          ? null
          : _ubicacionCtrl.text.trim(),
      zona: _zonaCtrl.text.trim().isEmpty ? null : _zonaCtrl.text.trim(),
      latitud: _lat,
      longitud: _lon,
    );

    final parte = PartePesca(
      fecha: df.format(_fecha),
      horaInicio: hhmm(_horaInicio),
      horaFin: hhmm(_horaFin),
      timestamp: DateTime.now(),
      modalidad: _modalidad,
      cantidadTotal: _cantidadTotal,
      numeroCanas: _numeroCanas,
      observaciones: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
      ubicacion: ubic.vacia ? null : ubic,
      peces: List.of(_capturas),
      estado: 'completado',
    );

    try {
      await ref.read(partesRepositoryProvider).guardarParte(parte);
      // Carga automática a los torneos activos donde participa (best-effort).
      try {
        await ref
            .read(torneosRepositoryProvider)
            .cargarParteEnTorneosActivos(parte);
      } catch (_) {/* no bloquea el guardado del parte */}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parte guardado ✅')),
      );
      setState(() {
        _paso = 0;
        _modalidad = null;
        _fecha = DateTime.now();
        _horaInicio = null;
        _horaFin = null;
        _capturas.clear();
        _ubicacionCtrl.clear();
        _zonaCtrl.clear();
        _numeroCanas = 1;
        _obsCtrl.clear();
        _lat = null;
        _lon = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prog = _progreso();
    return Column(
      children: [
        _ProgresoHeader(porcentaje: prog.porcentaje, faltantes: prog.faltantes),
        Expanded(child: _buildStepper()),
      ],
    );
  }

  Widget _buildStepper() {
    return Stepper(
      currentStep: _paso,
      type: StepperType.vertical,
      onStepTapped: (i) => setState(() => _paso = i),
      onStepContinue: () {
        if (_paso < 3) {
          setState(() => _paso++);
        } else {
          _guardar();
        }
      },
      onStepCancel: _paso == 0 ? null : () => setState(() => _paso--),
      controlsBuilder: (context, details) {
        final esUltimo = _paso == 3;
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              FilledButton(
                onPressed: _guardando ? null : details.onStepContinue,
                child: _guardando && esUltimo
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(esUltimo ? 'Guardar parte' : 'Continuar'),
              ),
              if (_paso > 0)
                TextButton(
                  onPressed: details.onStepCancel,
                  child: const Text('Atrás'),
                ),
            ],
          ),
        );
      },
      steps: [
        Step(
          title: const Text('Modalidad'),
          isActive: _paso >= 0,
          content: _PasoModalidad(
            seleccionada: _modalidad,
            onSelect: (m) => setState(() => _modalidad = m),
          ),
        ),
        Step(
          title: const Text('Fecha y horario'),
          isActive: _paso >= 1,
          content: _PasoFechaHora(
            fecha: _fecha,
            horaInicio: _horaInicio,
            horaFin: _horaFin,
            onFecha: (d) => setState(() => _fecha = d),
            onHoraInicio: (t) => setState(() => _horaInicio = t),
            onHoraFin: (t) => setState(() => _horaFin = t),
          ),
        ),
        Step(
          title: Text('Capturas ($_cantidadTotal)'),
          isActive: _paso >= 2,
          content: _PasoCapturas(
            capturas: _capturas,
            onChanged: () => setState(() {}),
          ),
        ),
        Step(
          title: const Text('Detalles'),
          isActive: _paso >= 3,
          content: _PasoDetalles(
            ubicacionCtrl: _ubicacionCtrl,
            zonaCtrl: _zonaCtrl,
            obsCtrl: _obsCtrl,
            numeroCanas: _numeroCanas,
            onCanas: (n) => setState(() => _numeroCanas = n),
            lat: _lat,
            lon: _lon,
            ubicCargando: _ubicCargando,
            onDetectar: _detectarUbicacion,
            onTapMapa: (p) => setState(() {
              _lat = p.latitude;
              _lon = p.longitude;
            }),
          ),
        ),
      ],
    );
  }
}

/// Encabezado con el progreso de completado y los campos que faltan.
class _ProgresoHeader extends StatelessWidget {
  const _ProgresoHeader({required this.porcentaje, required this.faltantes});
  final int porcentaje;
  final List<String> faltantes;

  @override
  Widget build(BuildContext context) {
    final completo = porcentaje >= 70;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Completado: $porcentaje%',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (completo)
                const Text('✓ listo para guardar',
                    style: TextStyle(color: HukaAccents.pescadex, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
                value: porcentaje / 100, minHeight: 7),
          ),
          if (faltantes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Falta: ${faltantes.take(3).join(', ')}',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _PasoModalidad extends StatelessWidget {
  const _PasoModalidad({required this.seleccionada, required this.onSelect});
  final ModalidadPesca? seleccionada;
  final ValueChanged<ModalidadPesca> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ModalidadPesca.values.map((m) {
        return ChoiceChip(
          label: Text('${m.emoji} ${m.display}'),
          selected: seleccionada == m,
          onSelected: (_) => onSelect(m),
        );
      }).toList(),
    );
  }
}

class _PasoFechaHora extends StatelessWidget {
  const _PasoFechaHora({
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.onFecha,
    required this.onHoraInicio,
    required this.onHoraFin,
  });

  final DateTime fecha;
  final TimeOfDay? horaInicio;
  final TimeOfDay? horaFin;
  final ValueChanged<DateTime> onFecha;
  final ValueChanged<TimeOfDay> onHoraInicio;
  final ValueChanged<TimeOfDay> onHoraFin;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE dd/MM/yyyy', 'es');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_today),
          title: Text(df.format(fecha)),
          trailing: const Icon(Icons.edit),
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: fecha,
              firstDate: DateTime(2015),
              lastDate: DateTime.now(),
            );
            if (d != null) onFecha(d);
          },
        ),
        Row(
          children: [
            Expanded(
              child: _HoraTile(
                label: 'Inicio',
                hora: horaInicio,
                onPick: onHoraInicio,
              ),
            ),
            Expanded(
              child: _HoraTile(
                label: 'Fin',
                hora: horaFin,
                onPick: onHoraFin,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HoraTile extends StatelessWidget {
  const _HoraTile(
      {required this.label, required this.hora, required this.onPick});
  final String label;
  final TimeOfDay? hora;
  final ValueChanged<TimeOfDay> onPick;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(hora?.format(context) ?? '--:--'),
      onTap: () async {
        final t = await showTimePicker(
          context: context,
          initialTime: hora ?? TimeOfDay.now(),
        );
        if (t != null) onPick(t);
      },
    );
  }
}

class _PasoCapturas extends StatefulWidget {
  const _PasoCapturas({required this.capturas, required this.onChanged});
  final List<Captura> capturas;
  final VoidCallback onChanged;

  @override
  State<_PasoCapturas> createState() => _PasoCapturasState();
}

class _PasoCapturasState extends State<_PasoCapturas> {
  final _especieCtrl = TextEditingController();
  int _cantidad = 1;

  @override
  void dispose() {
    _especieCtrl.dispose();
    super.dispose();
  }

  void _agregar() {
    final esp = _especieCtrl.text.trim();
    if (esp.isEmpty) return;
    widget.capturas.add(Captura(especie: esp, cantidad: _cantidad));
    _especieCtrl.clear();
    _cantidad = 1;
    widget.onChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _especieCtrl,
                decoration: const InputDecoration(
                  labelText: 'Especie',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _Stepper(
              valor: _cantidad,
              min: 1,
              onChanged: (v) => setState(() => _cantidad = v),
            ),
            IconButton.filled(
              onPressed: _agregar,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...widget.capturas.asMap().entries.map((e) {
          final c = e.value;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.set_meal, color: HukaAccents.crearParte),
            title: Text(c.especie),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('x${c.cantidad}'),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    widget.capturas.removeAt(e.key);
                    widget.onChanged();
                    setState(() {});
                  },
                ),
              ],
            ),
          );
        }),
        if (widget.capturas.isEmpty)
          Text('Sin capturas todavía.',
              style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _PasoDetalles extends StatelessWidget {
  const _PasoDetalles({
    required this.ubicacionCtrl,
    required this.zonaCtrl,
    required this.obsCtrl,
    required this.numeroCanas,
    required this.onCanas,
    required this.lat,
    required this.lon,
    required this.ubicCargando,
    required this.onDetectar,
    required this.onTapMapa,
  });

  final TextEditingController ubicacionCtrl;
  final TextEditingController zonaCtrl;
  final TextEditingController obsCtrl;
  final int numeroCanas;
  final ValueChanged<int> onCanas;
  final double? lat;
  final double? lon;
  final bool ubicCargando;
  final VoidCallback onDetectar;
  final ValueChanged<LatLng> onTapMapa;

  @override
  Widget build(BuildContext context) {
    final tienePunto = lat != null && lon != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: ubicacionCtrl,
          decoration: const InputDecoration(
              labelText: 'Lugar (ej: Río Paraná)', isDense: true),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: zonaCtrl,
          decoration: const InputDecoration(
              labelText: 'Zona / provincia', isDense: true),
        ),
        const SizedBox(height: 12),
        // --- Ubicación GPS ---
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: ubicCargando ? null : onDetectar,
                icon: ubicCargando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location),
                label: Text(tienePunto ? 'Actualizar ubicación' : 'Usar mi ubicación'),
              ),
            ),
          ],
        ),
        if (tienePunto) ...[
          const SizedBox(height: 8),
          Text(
            'Lat: ${lat!.toStringAsFixed(5)}, Lon: ${lon!.toStringAsFixed(5)}'
            '  ·  tocá el mapa para ajustar',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 200,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(lat!, lon!),
                  initialZoom: 13,
                  onTap: (_, p) => onTapMapa(p),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.juka_flutter',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(lat!, lon!),
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_on,
                            color: HukaAccents.crearParte, size: 40),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Cañas'),
            const Spacer(),
            _Stepper(valor: numeroCanas, min: 0, onChanged: onCanas),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: obsCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Observaciones',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper(
      {required this.valor, required this.onChanged, this.min = 0});
  final int valor;
  final int min;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: valor > min ? () => onChanged(valor - 1) : null,
        ),
        Text('$valor', style: Theme.of(context).textTheme.titleMedium),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => onChanged(valor + 1),
        ),
      ],
    );
  }
}
