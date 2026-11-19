import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_alabanzas/models/actividad.dart';
import 'package:app_alabanzas/models/miembro.dart';
import 'package:app_alabanzas/repositories/actividad_repository.dart';
import 'package:app_alabanzas/repositories/miembro_repository.dart';
import 'package:app_alabanzas/services/autenticacion_service.dart';
import 'package:app_alabanzas/screens/actividades/actividad_utils.dart';
import 'package:app_alabanzas/screens/actividades/agregar_actividad_screen.dart';
import 'package:app_alabanzas/screens/actividades/detalle_actividad_screen.dart';
import 'package:app_alabanzas/widgets/selector_segmentado.dart';

/// Recorte por fecha de la pestaña Setlists — `todas` conserva la vista
/// de siempre (sin filtrar), las otras dos parten las mismas Actividades
/// en futuras/pasadas sin tocar el orden que ya trae
/// `watchOrdenadasPorFecha` (más reciente primero).
enum _FiltroActividades { todas, proximas, anteriores }

extension on _FiltroActividades {
  String get etiqueta => switch (this) {
        _FiltroActividades.todas => 'Todas',
        _FiltroActividades.proximas => 'Próximas',
        _FiltroActividades.anteriores => 'Anteriores',
      };
}

/// Pestaña "Setlists": calendario simple de actividades (servicios,
/// ensayos), más reciente primero. Cualquiera la ve; solo el líder puede
/// crear una actividad nueva.
class SetlistsScreen extends StatefulWidget {
  const SetlistsScreen({super.key});

  @override
  State<SetlistsScreen> createState() => _SetlistsScreenState();
}

class _SetlistsScreenState extends State<SetlistsScreen> {
  late final Future<Miembro?> _miembroYo;
  _FiltroActividades _filtro = _FiltroActividades.todas;

  @override
  void initState() {
    super.initState();
    final uid = context.read<AutenticacionService>().usuarioActual?.uid;
    _miembroYo = uid == null
        ? Future.value(null)
        : context.read<MiembroRepository>().buscarPorUid(uid);
  }

  List<Actividad> _filtradas(List<Actividad> actividades) {
    final ahora = DateTime.now();
    return switch (_filtro) {
      _FiltroActividades.todas => actividades,
      _FiltroActividades.proximas =>
        actividades.where((a) => a.fecha.isAfter(ahora)).toList(),
      _FiltroActividades.anteriores =>
        actividades.where((a) => !a.fecha.isAfter(ahora)).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setlists')),
      body: FutureBuilder<Miembro?>(
        future: _miembroYo,
        builder: (context, snapshotYo) {
          final esLider =
              snapshotYo.data?.roles.contains(RolMiembro.lider) ?? false;
          return StreamBuilder<List<Actividad>>(
            stream:
                context.read<ActividadRepository>().watchOrdenadasPorFecha(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final actividades = snapshot.data!;
              if (actividades.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      esLider
                          ? 'Todavía no armaste ninguna actividad. Tocá '
                              '"+ Actividad" para crear una.'
                          : 'Todavía no hay actividades cargadas.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                );
              }
              final filtradas = _filtradas(actividades);
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: SelectorSegmentado<_FiltroActividades>(
                      opciones: _FiltroActividades.values,
                      etiqueta: (opcion) => opcion.etiqueta,
                      valor: _filtro,
                      onCambiar: (opcion) => setState(() => _filtro = opcion),
                    ),
                  ),
                  Expanded(
                    child: filtradas.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                _filtro == _FiltroActividades.proximas
                                    ? 'No hay actividades próximas.'
                                    : 'No hay actividades anteriores.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                            itemCount: filtradas.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final actividad = filtradas[i];
                              final esFutura =
                                  actividad.fecha.isAfter(DateTime.now());
                              return Card(
                                child: ListTile(
                                  leading: Icon(
                                    esFutura
                                        ? Icons.event_outlined
                                        : Icons.event_available_outlined,
                                  ),
                                  title: Text(actividad.nombre),
                                  subtitle: Text(
                                    '${formatearFechaActividad(actividad.fecha)} · '
                                    '${actividad.setlist.length} alabanzas',
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => DetalleActividadScreen(
                                          actividadId: actividad.id),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FutureBuilder<Miembro?>(
        future: _miembroYo,
        builder: (context, snapshot) {
          final esLider =
              snapshot.data?.roles.contains(RolMiembro.lider) ?? false;
          if (!esLider) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AgregarActividadScreen()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Actividad'),
          );
        },
      ),
    );
  }
}
