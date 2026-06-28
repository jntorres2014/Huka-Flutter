import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'logro_catalog.dart';
import 'logros_providers.dart';

/// Filtro de categoría seleccionado (null = todos).
final _filtroProvider = StateProvider<AchievementCategory?>((ref) => null);

class LogrosScreen extends ConsumerWidget {
  const LogrosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desbloqueados = ref.watch(logrosDesbloqueadosProvider);
    final filtro = ref.watch(_filtroProvider);
    final entradas = AchievementCatalog.byCategory(filtro);
    final totalDesbloqueados = desbloqueados.length;

    return Column(
      children: [
        _Header(
          desbloqueados: totalDesbloqueados,
          total: AchievementCatalog.total,
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _Chip(
                label: 'Todos',
                icon: Icons.apps,
                selected: filtro == null,
                onTap: () => ref.read(_filtroProvider.notifier).state = null,
              ),
              ...AchievementCategory.values.map((c) => _Chip(
                    label: c.displayName,
                    icon: c.icon,
                    color: c.color,
                    selected: filtro == c,
                    onTap: () =>
                        ref.read(_filtroProvider.notifier).state = c,
                  )),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              mainAxisExtent: 150,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: entradas.length,
            itemBuilder: (context, i) {
              final e = entradas[i];
              return _LogroCard(
                entry: e,
                desbloqueado: desbloqueados.contains(e.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.desbloqueados, required this.total});
  final int desbloqueados;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progreso = total == 0 ? 0.0 : desbloqueados / total;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$desbloqueados de $total logros',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: progreso, minHeight: 8),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.color,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: Icon(icon, size: 18, color: color),
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _LogroCard extends StatelessWidget {
  const _LogroCard({required this.entry, required this.desbloqueado});
  final CatalogEntry entry;
  final bool desbloqueado;

  @override
  Widget build(BuildContext context) {
    final cat = entry.category;
    return Card(
      color: desbloqueado ? cat.container : null,
      child: InkWell(
        onTap: () => showDialog(
          context: context,
          builder: (_) => _DetalleDialog(entry: entry, desbloqueado: desbloqueado),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Opacity(
                    opacity: desbloqueado ? 1 : 0.3,
                    child: Text(entry.emoji,
                        style: const TextStyle(fontSize: 30)),
                  ),
                  const Spacer(),
                  Icon(
                    desbloqueado ? Icons.check_circle : Icons.lock_outline,
                    size: 18,
                    color: desbloqueado ? cat.color : Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                entry.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: desbloqueado ? null : Theme.of(context).disabledColor,
                ),
              ),
              const Spacer(),
              Text(
                cat.shortLabel,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: cat.color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetalleDialog extends StatelessWidget {
  const _DetalleDialog({required this.entry, required this.desbloqueado});
  final CatalogEntry entry;
  final bool desbloqueado;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Text(entry.emoji, style: const TextStyle(fontSize: 40)),
      title: Text(entry.title, textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(entry.description, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Chip(
            avatar: Icon(
              desbloqueado ? Icons.check_circle : Icons.lock_outline,
              color: desbloqueado ? entry.category.color : Colors.grey,
              size: 18,
            ),
            label: Text(desbloqueado ? 'Desbloqueado' : 'Bloqueado'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
