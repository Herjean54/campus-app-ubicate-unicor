import 'package:flutter/material.dart';

import '../datos/horarios.dart';
import '../modelo/lugares.dart';

Widget _estadoChip(Estado e) {
  final color = e.abierto == null
      ? Colors.grey
      : (e.abierto! ? Colors.green.shade700 : Colors.red.shade700);
  final etiqueta = e.abierto == null
      ? 'Sin horario'
      : (e.abierto! ? 'Abierto ahora' : 'Cerrado');
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 6),
        Text(
          etiqueta,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

void mostrarFicha(
  BuildContext context,
  String nombre, {
  VoidCallback? alEstoyAqui,
  VoidCallback? alIrAqui,
}) {
  final info = infoDe(nombre);
  final estado = estadoAhora(info, DateTime.now());

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nombre, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 10),
            Row(
              children: [
                _estadoChip(estado),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    estado.texto,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(info.descripcion),
            const SizedBox(height: 16),
            const Text(
              'Horario',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            if (info.horarios.isEmpty)
              const Text(
                'Sin horario registrado.',
                style: TextStyle(color: Colors.black54),
              )
            else
              for (final f in info.horarios)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, size: 18),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 90,
                        child: Text(
                          diasTexto(f.dias),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text('${f.desde} – ${f.hasta}'),
                    ],
                  ),
                ),
            if (alEstoyAqui != null || alIrAqui != null) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  if (alEstoyAqui != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.my_location),
                        label: const Text('Estoy aquí'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          alEstoyAqui();
                        },
                      ),
                    ),
                  if (alEstoyAqui != null && alIrAqui != null)
                    const SizedBox(width: 12),
                  if (alIrAqui != null)
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.directions_walk),
                        label: const Text('Ir aquí'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          alIrAqui();
                        },
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

// Lista de todos los lugares con su estado
void mostrarListaLugares(BuildContext context, ValueChanged<String> alElegir) {
  final ahora = DateTime.now();
  final nombres = lugares.keys.toList()..sort();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (_, scroll) => ListView.builder(
        controller: scroll,
        itemCount: nombres.length,
        itemBuilder: (_, i) {
          final n = nombres[i];
          final e = estadoAhora(infoDe(n), ahora);
          final color = e.abierto == null
              ? Colors.grey
              : (e.abierto! ? Colors.green.shade700 : Colors.red.shade700);
          return ListTile(
            leading: Icon(Icons.circle, size: 12, color: color),
            title: Text(n),
            subtitle: Text(e.texto),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(ctx);
              alElegir(n);
            },
          );
        },
      ),
    ),
  );
}
