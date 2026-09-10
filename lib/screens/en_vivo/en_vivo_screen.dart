import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_alabanzas/core/firestore/repositorio.dart';
import 'package:app_alabanzas/models/actividad.dart';
import 'package:app_alabanzas/models/cancion.dart';
import 'package:app_alabanzas/models/miembro.dart';
import 'package:app_alabanzas/repositories/actividad_repository.dart';
import 'package:app_alabanzas/repositories/miembro_repository.dart';
import 'package:app_alabanzas/screens/actividades/actividad_utils.dart';
import 'package:app_alabanzas/screens/en_vivo/vista_en_vivo_screen.dart';
import 'package:app_alabanzas/services/autenticacion_service.dart';
import 'package:app_alabanzas/services/sync_local/conexion_local_service.dart';

/// Pestaña "En vivo": el setlist de la actividad de hoy (o si no hay
/// ninguna hoy, la próxima más cercana, o si no hay futuras, la última
/// que hubo) — listo para transmitir. El líder toca una canción para
/// empezar a mostrarla en `VistaEnVivoScreen`; quien no es líder también
/// puede tocar cualquier canción para verla, pero solo la que está
/// marcada "En vivo ahora" sigue automáticamente al líder — ver doc de
/// esa pantalla.
class EnVivoScreen extends StatelessWidget {
  const EnVivoScreen({super.key});

  static Actividad? _elegirActividad(List<Actividad> actividades) {
    if (actividades.isEmpty) return null;
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    for (final actividad in actividades) {
      final fecha = DateTime(
        actividad.fecha.year,
        actividad.fecha.month,
        actividad.fecha.day,
      );
      if (fecha == hoy) return actividad;
    }
    final futuras = actividades.where((a) => a.fecha.isAfter(ahora)).toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));
    if (futuras.isNotEmpty) return futuras.first;
    final pasadas = [...actividades]..sort((a, b) => b.fecha.compareTo(a.fecha));
    return pasadas.first;
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AutenticacionService>().usuarioActual?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('En vivo')),
      body: FutureBuilder<Miembro?>(
        future: uid == null ? null : context.read<MiembroRepository>().buscarPorUid(uid),
        builder: (context, snapshotYo) {
          final esLider = snapshotYo.data?.roles.contains(RolMiembro.lider) ?? false;
          return StreamBuilder<List<Actividad>>(
            stream: context.read<ActividadRepository>().watchOrdenadasPorFecha(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final actividad = _elegirActividad(snapshot.data!);
              if (actividad == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Todavía no hay actividades cargadas.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                );
              }
              return StreamBuilder<List<Cancion>>(
                stream: context.read<Repositorio<Cancion>>().watchAll(),
                builder: (context, snapshotCanciones) {
                  final cancionPorId = {
                    for (final c in snapshotCanciones.data ?? const <Cancion>[]) c.id: c,
                  };
                  return StreamBuilder<List<Miembro>>(
                    stream: context.read<Repositorio<Miembro>>().watchAll(),
                    builder: (context, snapshotMiembros) {
                      final nombrePorMiembroId = {
                        for (final m in snapshotMiembros.data ?? const <Miembro>[])
                          m.id: m.nombre,
                      };
                      final conexionLocal = context.read<ConexionLocalService>();
                      return StreamBuilder<EstadoEnVivoLocal>(
                        initialData: conexionLocal.ultimoEstado(actividad.id),
                        stream: conexionLocal.estados
                            .where((e) => e.actividadId == actividad.id),
                        builder: (context, snapshotEstadoLocal) {
                          final estadoLocal = snapshotEstadoLocal.data;
                          // El estado que llega por red local (sin
                          // internet) pisa al de Firestore mientras esté
                          // disponible — ver doc de `ConexionLocalService`.
                          final actividadEfectiva = estadoLocal == null
                              ? actividad
                              : actividad.copyWith(
                                  cancionActivaId: estadoLocal.cancionActivaId,
                                  limpiarCancionActiva:
                                      estadoLocal.cancionActivaId == null,
                                  seccionActivaIndice: estadoLocal.seccionActivaIndice,
                                );
                          return _Contenido(
                            actividad: actividadEfectiva,
                            esLider: esLider,
                            cancionPorId: cancionPorId,
                            nombrePorMiembroId: nombrePorMiembroId,
                            conexionLocal: conexionLocal,
                          );
                        },
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
    required this.conexionLocal,
  });

  final Actividad actividad;
  final bool esLider;
  final Map<String, Cancion> cancionPorId;
  final Map<String, String> nombrePorMiembroId;
  final ConexionLocalService conexionLocal;

  Future<void> _abrir(BuildContext context, String cancionId) async {
    if (esLider) {
      await context.read<Repositorio<Actividad>>().actualizar(
            actividad.id,
            actividad.copyWith(cancionActivaId: cancionId, seccionActivaIndice: 0),
          );
      await conexionLocal.transmitir(
        EstadoEnVivoLocal(actividadId: actividad.id, cancionActivaId: cancionId),
      );
    }
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VistaEnVivoScreen(
          actividadId: actividad.id,
          cancionId: cancionId,
          esLider: esLider,
        ),
      ),
    );
  }

  Future<void> _detener(BuildContext context) async {
    await context.read<Repositorio<Actividad>>().actualizar(
          actividad.id,
          actividad.copyWith(limpiarCancionActiva: true, seccionActivaIndice: 0),
        );
    await conexionLocal.transmitir(
      EstadoEnVivoLocal(actividadId: actividad.id, cancionActivaId: null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(actividad.nombre, style: tema.textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(
                      formatearFechaActividad(actividad.fecha),
                      style: tema.textTheme.bodyMedium
                          ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (esLider && actividad.cancionActivaId != null)
                OutlinedButton.icon(
                  onPressed: () => _detener(context),
                  icon: const Icon(Icons.stop_circle_outlined, size: 18),
                  label: const Text('Detener'),
                ),
            ],
          ),
        ),
        if (actividad.setlist.isEmpty)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Esta actividad todavía no tiene setlist cargado.',
                  textAlign: TextAlign.center,
                  style: tema.textTheme.bodyMedium
                      ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: actividad.setlist.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final entrada = actividad.setlist[i];
                final cancion = cancionPorId[entrada.cancionId];
                final activa = actividad.cancionActivaId == entrada.cancionId;
                final tono = cancion == null
                    ? null
                    : transponerTono(cancion.tonoOriginal, entrada.tonoAsignado);
                return Card(
                  color: activa ? tema.colorScheme.primaryContainer : null,
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${entrada.orden + 1}')),
                    title: Text(cancion?.titulo ?? 'Canción eliminada'),
                    subtitle: Text([
                      if (tono != null) 'Tono $tono',
                      nombrePorMiembroId[entrada.cantanteId] ?? 'Sin cantante asignado',
                    ].join(' · ')),
                    trailing: activa
                        ? Icon(Icons.sensors, color: tema.colorScheme.primary)
                        : const Icon(Icons.chevron_right),
                    onTap: cancion == null ? null : () => _abrir(context, cancion.id),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
