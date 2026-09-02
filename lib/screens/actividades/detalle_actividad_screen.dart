import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_alabanzas/core/firestore/repositorio.dart';
import 'package:app_alabanzas/models/actividad.dart';
import 'package:app_alabanzas/models/cancion.dart';
import 'package:app_alabanzas/models/miembro.dart';
import 'package:app_alabanzas/models/setlist_entry.dart';
import 'package:app_alabanzas/repositories/miembro_repository.dart';
import 'package:app_alabanzas/services/autenticacion_service.dart';
import 'package:app_alabanzas/screens/actividades/actividad_utils.dart';
import 'package:app_alabanzas/screens/actividades/agregar_actividad_screen.dart';
import 'package:app_alabanzas/screens/contenido/detalle_alabanza_screen.dart';

/// Vista de una Actividad ya guardada: nombre, fecha y el setlist en
/// orden, con canción, tono asignado y cantante por fila. El líder puede
/// tocar el lápiz para editarla — el resto la ve de solo lectura.
class DetalleActividadScreen extends StatelessWidget {
  const DetalleActividadScreen({super.key, required this.actividadId});

  final String actividadId;

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AutenticacionService>().usuarioActual?.uid;

    return Scaffold(
      body: FutureBuilder<Miembro?>(
        future: uid == null
            ? null
            : context.read<MiembroRepository>().buscarPorUid(uid),
        builder: (context, snapshotYo) {
          final esLider =
              snapshotYo.data?.roles.contains(RolMiembro.lider) ?? false;
          return StreamBuilder<List<Cancion>>(
            stream: context.read<Repositorio<Cancion>>().watchAll(),
            builder: (context, snapshotCanciones) {
              final cancionPorId = {
                for (final c in snapshotCanciones.data ?? const <Cancion>[])
                  c.id: c,
              };
              return StreamBuilder<List<Miembro>>(
                stream: context.read<Repositorio<Miembro>>().watchAll(),
                builder: (context, snapshotMiembros) {
                  final nombrePorMiembroId = {
                    for (final m in snapshotMiembros.data ?? const <Miembro>[])
                      m.id: m.nombre,
                  };
                  return StreamBuilder<List<Actividad>>(
                    stream: context.read<Repositorio<Actividad>>().watchAll(),
                    builder: (context, snapshot) {
                      final coincidencias =
                          (snapshot.data ?? const <Actividad>[])
                              .where((a) => a.id == actividadId);
                      if (coincidencias.isEmpty) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      return _Contenido(
                        actividad: coincidencias.first,
                        esLider: esLider,
                        cancionPorId: cancionPorId,
                        nombrePorMiembroId: nombrePorMiembroId,
                      );
                    },
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

class _Contenido extends StatelessWidget {
  const _Contenido({
    required this.actividad,
    required this.esLider,
    required this.cancionPorId,
    required this.nombrePorMiembroId,
  });

  final Actividad actividad;
  final bool esLider;
  final Map<String, Cancion> cancionPorId;
  final Map<String, String> nombrePorMiembroId;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: Text(actividad.nombre),
          floating: true,
          actions: [
            if (esLider)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar actividad',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        AgregarActividadScreen(actividadExistente: actividad),
                  ),
                ),
              ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Text(
              '${formatearFechaActividad(actividad.fecha)} · '
              '${TimeOfDay.fromDateTime(actividad.fecha).format(context)}',
              style: tema.textTheme.bodyMedium
                  ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
          ),
        ),
        if (actividad.setlist.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Text(
                'Todavía no se cargó el setlist.',
                style: tema.textTheme.bodyMedium
                    ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverList.list(
              children: [
                for (final entrada in actividad.setlist)
                  _FilaSetlist(
                    entrada: entrada,
                    cancion: cancionPorId[entrada.cancionId],
                    cantanteNombre: nombrePorMiembroId[entrada.cantanteId],
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FilaSetlist extends StatelessWidget {
  const _FilaSetlist({
    required this.entrada,
    required this.cancion,
    required this.cantanteNombre,
  });

  final SetlistEntry entrada;
  final Cancion? cancion;
  final String? cantanteNombre;

  @override
  Widget build(BuildContext context) {
    final cancion = this.cancion;
    final tonoResultante =
        cancion == null ? null : transponerTono(cancion.tonoOriginal, entrada.tonoAsignado);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(child: Text('${entrada.orden + 1}')),
        title: Text(cancion?.titulo ?? 'Canción eliminada'),
        subtitle: Text([
          if (tonoResultante != null) 'Tono: $tonoResultante',
          if (cantanteNombre != null && cantanteNombre!.isNotEmpty)
            'Canta: $cantanteNombre',
        ].join(' · ')),
        trailing: cancion == null ? null : const Icon(Icons.chevron_right),
        onTap: cancion == null
            ? null
            : () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DetalleAlabanzaScreen(cancionId: cancion.id),
                  ),
                ),
      ),
    );
  }
}
