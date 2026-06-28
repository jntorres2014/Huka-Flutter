import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import 'torneo_models.dart';
import 'torneo_detail_screen.dart';
import 'torneos_providers.dart';

class TorneosScreen extends ConsumerWidget {
  const TorneosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final torneosAsync = ref.watch(misTorneosProvider);

    return Scaffold(
      body: torneosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('No se pudieron cargar los torneos.\n$e',
                textAlign: TextAlign.center),
          ),
        ),
        data: (torneos) {
          if (torneos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.emoji_events,
                        size: 72, color: HukaAccents.torneos),
                    const SizedBox(height: 12),
                    const Text('Todavía no participás en torneos.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _unirsePorCodigo(context, ref),
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Unirme con código'),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(misTorneosProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: torneos.length,
              itemBuilder: (_, i) => _TorneoCard(torneo: torneos[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _menuAcciones(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Torneo'),
      ),
    );
  }

  void _menuAcciones(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle),
              title: const Text('Crear torneo'),
              onTap: () {
                Navigator.pop(context);
                _crearTorneo(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('Unirme con código'),
              onTap: () {
                Navigator.pop(context);
                _unirsePorCodigo(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _unirsePorCodigo(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final codigo = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unirme con código'),
        content: TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Código de invitación',
            hintText: 'Ej: A1B2C3',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: const Text('Buscar')),
        ],
      ),
    );
    if (codigo == null || codigo.isEmpty) return;

    final repo = ref.read(torneosRepositoryProvider);
    try {
      final torneo = await repo.buscarPorCodigo(codigo);
      if (!context.mounted) return;
      if (torneo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró ese torneo.')),
        );
        return;
      }
      await repo.solicitarUnirse(torneo.id);
      ref.invalidate(misTorneosProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Solicitud enviada a "${torneo.nombre}" ✅')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _crearTorneo(BuildContext context, WidgetRef ref) async {
    final creado = await showDialog<bool>(
      context: context,
      builder: (_) => const _CrearTorneoDialog(),
    );
    if (creado == true) ref.invalidate(misTorneosProvider);
  }
}

class _TorneoCard extends ConsumerWidget {
  const _TorneoCard({required this.torneo});
  final Torneo torneo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final esCreador = ref.read(torneosRepositoryProvider).esCreador(torneo);
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: HukaAccents.torneos,
          child: Icon(Icons.emoji_events, color: Colors.white),
        ),
        title: Text(torneo.nombre),
        subtitle: Text(
          '${_EstadoBadge.texto(torneo.estado)} · '
          '${DateFormat('dd/MM').format(torneo.fechaInicio)}'
          '–${DateFormat('dd/MM').format(torneo.fechaFin)}'
          '${esCreador ? ' · Organizás' : ''}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TorneoDetailScreen(torneo: torneo)),
        ),
      ),
    );
  }
}

class _EstadoBadge {
  static String texto(EstadoTorneo e) => switch (e) {
        EstadoTorneo.proximo => 'Próximo',
        EstadoTorneo.activo => 'Activo',
        EstadoTorneo.finalizado => 'Finalizado',
      };
}

class _CrearTorneoDialog extends ConsumerStatefulWidget {
  const _CrearTorneoDialog();

  @override
  ConsumerState<_CrearTorneoDialog> createState() => _CrearTorneoDialogState();
}

class _CrearTorneoDialogState extends ConsumerState<_CrearTorneoDialog> {
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime _inicio = DateTime.now();
  DateTime _fin = DateTime.now().add(const Duration(days: 7));
  TipoPuntaje _tipo = TipoPuntaje.cantidadPeces;
  bool _guardando = false;

  // Reglas personalizadas (solo si _tipo == personalizado).
  bool _bonusOn = false;
  final _bonusCtrl = TextEditingController(text: '20');
  bool _porPezOn = false;
  final _porPezCtrl = TextEditingController(text: '1');
  bool _porEspecieOn = false;
  final List<_FilaEspecie> _filas = [];
  final _otrosCtrl = TextEditingController(text: '0');

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _bonusCtrl.dispose();
    _porPezCtrl.dispose();
    _otrosCtrl.dispose();
    for (final f in _filas) {
      f.especie.dispose();
      f.puntos.dispose();
    }
    super.dispose();
  }

  /// Reglas válidas: al menos una regla activa y bien cargada.
  bool get _reglasOk {
    if (_tipo != TipoPuntaje.personalizado) return true;
    final bonus = _bonusOn && int.tryParse(_bonusCtrl.text) != null;
    final porPez = _porPezOn && int.tryParse(_porPezCtrl.text) != null;
    final porEsp = _porEspecieOn &&
        _filas.any((f) =>
            f.especie.text.trim().isNotEmpty &&
            int.tryParse(f.puntos.text) != null);
    return bonus || porPez || porEsp;
  }

  ReglasPuntaje? _construirReglas() {
    if (_tipo != TipoPuntaje.personalizado) return null;
    Map<String, int>? tabla;
    if (_porEspecieOn) {
      tabla = {};
      for (final f in _filas) {
        final nombre = f.especie.text.trim();
        final pts = int.tryParse(f.puntos.text);
        if (nombre.isNotEmpty && pts != null) {
          tabla[normalizarParaIdTorneo(nombre)] = pts;
        }
      }
      if (tabla.isEmpty) tabla = null;
    }
    return ReglasPuntaje(
      bonusPrimerParte: _bonusOn ? int.tryParse(_bonusCtrl.text) : null,
      puntosPorPez: _porPezOn ? int.tryParse(_porPezCtrl.text) : null,
      puntosPorEspecie: tabla,
      puntosOtrosPeces: int.tryParse(_otrosCtrl.text) ?? 0,
    );
  }

  Future<void> _pickFecha(bool inicio) async {
    final hoy = DateTime.now();
    final hoyCero = DateTime(hoy.year, hoy.month, hoy.day);
    final d = await showDatePicker(
      context: context,
      initialDate: inicio ? _inicio : _fin,
      // El inicio no puede ser en el pasado; el fin no antes del inicio.
      firstDate: inicio ? hoyCero : _inicio,
      lastDate: hoy.add(const Duration(days: 365)),
    );
    if (d == null) return;
    setState(() {
      if (inicio) {
        _inicio = d;
        if (_fin.isBefore(_inicio)) _fin = _inicio.add(const Duration(days: 1));
      } else {
        _fin = d;
      }
    });
  }

  bool get _fechasValidas => _fin.isAfter(_inicio);
  bool get _puedeCrear =>
      _nombreCtrl.text.trim().isNotEmpty && _fechasValidas && _reglasOk;

  Future<void> _crear() async {
    if (!_puedeCrear) return;
    setState(() => _guardando = true);
    try {
      final codigo = await ref.read(torneosRepositoryProvider).crearTorneo(
            nombre: _nombreCtrl.text.trim(),
            descripcion: _descCtrl.text.trim(),
            fechaInicio: _inicio,
            fechaFin: _fin,
            tipoPuntaje: _tipo,
            reglas: _construirReglas(),
          );
      if (!mounted) return;
      Navigator.pop(context, true);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('¡Torneo creado! 🏆'),
          content: SelectableText('Código de invitación: $codigo\n\n'
              'Compartilo para que se sumen participantes.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Listo')),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _guardando = false);
    }
  }

  Widget _editorReglas() {
    InputDecoration dec(String l) =>
        InputDecoration(labelText: l, isDense: true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Divider(),
        Text('Reglas de puntaje',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary)),
        // Bonus primer parte
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Bonus al primer parte'),
          value: _bonusOn,
          onChanged: (v) => setState(() => _bonusOn = v),
        ),
        if (_bonusOn)
          TextField(
            controller: _bonusCtrl,
            keyboardType: TextInputType.number,
            decoration: dec('Puntos de bonus'),
            onChanged: (_) => setState(() {}),
          ),
        // Puntos por pez
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Puntos por cada pez'),
          value: _porPezOn,
          onChanged: (v) => setState(() => _porPezOn = v),
        ),
        if (_porPezOn)
          TextField(
            controller: _porPezCtrl,
            keyboardType: TextInputType.number,
            decoration: dec('Puntos por pez'),
            onChanged: (_) => setState(() {}),
          ),
        // Tabla por especie
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Puntos por especie'),
          value: _porEspecieOn,
          onChanged: (v) => setState(() => _porEspecieOn = v),
        ),
        if (_porEspecieOn) ...[
          ..._filas.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: f.especie,
                        decoration: dec('Especie'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: f.puntos,
                        keyboardType: TextInputType.number,
                        decoration: dec('Pts'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        setState(() {
                          f.especie.dispose();
                          f.puntos.dispose();
                          _filas.remove(f);
                        });
                      },
                    ),
                  ],
                ),
              )),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _filas.add(_FilaEspecie())),
              icon: const Icon(Icons.add),
              label: const Text('Agregar especie'),
            ),
          ),
          TextField(
            controller: _otrosCtrl,
            keyboardType: TextInputType.number,
            decoration: dec('Puntos para otras especies'),
          ),
        ],
        if (!_reglasOk) ...[
          const SizedBox(height: 6),
          Text('Activá al menos una regla válida.',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error, fontSize: 12)),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');
    return AlertDialog(
      title: const Text('Crear torneo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                hintText: 'Obligatorio',
              ),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickFecha(true),
                    child: Text('Inicio: ${df.format(_inicio)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickFecha(false),
                    child: Text('Fin: ${df.format(_fin)}'),
                  ),
                ),
              ],
            ),
            if (!_fechasValidas) ...[
              const SizedBox(height: 6),
              Text('La fecha de fin debe ser posterior a la de inicio.',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12)),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<TipoPuntaje>(
              initialValue: _tipo,
              decoration: const InputDecoration(labelText: 'Puntaje'),
              items: TipoPuntaje.values
                  .map((t) =>
                      DropdownMenuItem(value: t, child: Text(t.display)))
                  .toList(),
              onChanged: (t) => setState(() => _tipo = t ?? _tipo),
            ),
            if (_tipo == TipoPuntaje.personalizado) _editorReglas(),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: _guardando ? null : () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
          onPressed: (_guardando || !_puedeCrear) ? null : _crear,
          child: _guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Crear'),
        ),
      ],
    );
  }
}

/// Una fila del editor "puntos por especie" (controladores propios).
class _FilaEspecie {
  final TextEditingController especie = TextEditingController();
  final TextEditingController puntos = TextEditingController();
}
