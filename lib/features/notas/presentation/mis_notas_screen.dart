import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/firestore/repositorio.dart';
import '../../acceso/data/services/autenticacion_service.dart';
import '../../contenido/data/models/cancion.dart';
import '../data/models/nota.dart';
import '../data/repositories/nota_repository.dart';
import 'agregar_nota_screen.dart';

/// Pantalla 13: todas las notas que este usuario puede ver — las propias
/// más las que el equipo compartió.
class MisNotasScreen extends StatelessWidget {
  const MisNotasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AutenticacionService>().usuarioActual!.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis notas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nota general',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AgregarNotaScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Nota>>(
        stream: context.read<NotaRepository>().watchVisiblesPara(uid),
        builder: (context, snapshotNotas) {
          if (!snapshotNotas.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final notas = snapshotNotas.data!;
          if (notas.isEmpty) {
            return const Center(child: Text('Todavía no hay notas.'));
          }
          return StreamBuilder<List<Cancion>>(
            stream: context.read<Repositorio<Cancion>>().watchAll(),
            builder: (context, snapshotCanciones) {
              final titulosPorId = {
                for (final c in snapshotCanciones.data ?? const <Cancion>[])
                  c.id: c.titulo,
              };
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notas.length,
                itemBuilder: (context, index) {
                  final nota = notas[index];
                  final titulo = nota.cancionId == null
                      ? 'Nota general'
                      : [
                          titulosPorId[nota.cancionId] ?? 'Alabanza',
                          if (nota.seccionEtiqueta != null) nota.seccionEtiqueta!,
                        ].join(' · ');
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  titulo,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Chip(
                                label: Text(
                                  nota.compartida ? 'Compartida' : 'Personal',
                                ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(nota.texto),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
