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

  @override
  void initState() {
    super.initState();
    final uid = context.read<AutenticacionService>().usuarioActual?.uid;
    _miembroYo = uid == null
        ? Future.value(null)
        : context.read<MiembroRepository>().buscarPorUid(uid);
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
            stream: context.read<ActividadRepository>().watchOrdenadasPorFecha(),
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
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: actividades.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final actividad = actividades[i];
                  final esFutura = actividad.fecha.isAfter(DateTime.now());
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
                          builder: (_) =>
                              DetalleActividadScreen(actividadId: actividad.id),
                        ),
                      ),
                    ),
                  );
                },
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
