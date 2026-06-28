import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../parte/partes_providers.dart';
import '../pescadex/especie.dart';
import '../pescadex/pescadex_providers.dart';
import 'contador_providers.dart';

/// Especies de acceso rápido (chips), como en FishCounterScreen.kt.
const _accesoRapido = [
  'Dorado',
  'Surubí',
  'Tararira',
  'Pejerrey',
  'Sábalo',
];

class ContadorScreen extends ConsumerStatefulWidget {
  const ContadorScreen({super.key});

  @override
  ConsumerState<ContadorScreen> createState() => _ContadorScreenState();
}

class _ContadorScreenState extends ConsumerState<ContadorScreen> {
  final _especieCtrl = TextEditingController();
  int _cantidad = 1;

  @override
  void dispose() {
    _especieCtrl.dispose();
    super.dispose();
  }

  List<String> _nombresPescadex() {
    final especies = ref.read(especiesProvider).valueOrNull ?? const <Especie>[];
    return especies.map((e) => e.nombre).toList();
  }

  void _agregar(String nombre) {
    final n = nombre.trim();
    if (n.isEmpty) {
      _avisar('Escribí una especie.');
      return;
    }
    // Igual que la app original: la especie debe estar en la Pescadex.
    // Los chips de acceso rápido (Dorado, etc.) ya son válidos.
    final valida = _nombresPescadex()
            .any((e) => e.toLowerCase() == n.toLowerCase()) ||
        _accesoRapido.any((e) => e.toLowerCase() == n.toLowerCase());
    if (!valida) {
      _avisar('Elegí una especie válida de la lista.');
      return;
    }
    ref.read(contadorProvider.notifier).agregar(n, _cantidad);
    _especieCtrl.clear();
    setState(() => _cantidad = 1);
  }

  void _avisar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Pasa las capturas contadas al wizard de Crear parte y limpia el contador.
  /// El pescador completa ahí el resto del parte (fecha, modalidad, etc.).
  void _continuarAlParte() {
    final items = ref.read(contadorProvider);
    if (items.isEmpty) return;
    ref.read(capturasInicialesProvider.notifier).state =
        items.map((e) => e.toCaptura()).toList();
    ref.read(contadorProvider.notifier).limpiar();
    context.go(Routes.crearParte);
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(contadorProvider);
    final total = ref.watch(contadorTotalProvider);

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.primaryContainer,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text('$total',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer)),
              Text(total == 1 ? 'pez' : 'peces',
                  style: TextStyle(
                      color:
                          Theme.of(context).colorScheme.onPrimaryContainer)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text('Acceso rápido',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: _accesoRapido
                    .map((e) => ActionChip(
                          avatar: const Icon(Icons.add, size: 18),
                          label: Text(e),
                          onPressed: () =>
                              ref.read(contadorProvider.notifier).incrementar(e),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Autocomplete<String>(
                        optionsBuilder: (value) {
                          final q = value.text.trim().toLowerCase();
                          if (q.isEmpty) return const Iterable<String>.empty();
                          return _nombresPescadex().where(
                              (n) => n.toLowerCase().contains(q));
                        },
                        onSelected: (s) => _especieCtrl.text = s,
                        fieldViewBuilder:
                            (context, controller, focusNode, onSubmit) {
                          // Sincroniza el controlador interno con el nuestro.
                          controller.addListener(
                              () => _especieCtrl.text = controller.text);
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'Buscar especie',
                              hintText: 'Ej: Dorado, Surubí...',
                              prefixIcon: Icon(Icons.search),
                              isDense: true,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: _cantidad > 1
                                ? () => setState(() => _cantidad--)
                                : null,
                          ),
                          Text('$_cantidad',
                              style:
                                  Theme.of(context).textTheme.titleLarge),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: _cantidad < 99
                                ? () => setState(() => _cantidad++)
                                : null,
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: () => _agregar(_especieCtrl.text),
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tus capturas',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  if (items.isNotEmpty)
                    TextButton(
                      onPressed: () =>
                          ref.read(contadorProvider.notifier).limpiar(),
                      child: const Text('Limpiar todo'),
                    ),
                ],
              ),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text('No hay capturas registradas.',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                )
              else
                ...items.map((it) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.set_meal,
                            color: HukaAccents.contador),
                        title: Text(it.nombre),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => ref
                                  .read(contadorProvider.notifier)
                                  .decrementar(it.nombre),
                            ),
                            Text('${it.cantidad}',
                                style:
                                    Theme.of(context).textTheme.titleMedium),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => ref
                                  .read(contadorProvider.notifier)
                                  .incrementar(it.nombre),
                            ),
                          ],
                        ),
                      ),
                    )),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: items.isEmpty ? null : _continuarAlParte,
                icon: const Icon(Icons.description),
                label: Text(items.isEmpty
                    ? 'Sumá capturas para crear el parte'
                    : 'Crear parte con ${items.length} '
                        '${items.length == 1 ? "especie" : "especies"}'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
