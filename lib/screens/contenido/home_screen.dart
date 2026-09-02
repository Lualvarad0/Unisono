import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_alabanzas/core/firestore/repositorio.dart';
import 'package:app_alabanzas/core/theme/app_theme.dart';
import 'package:app_alabanzas/services/autenticacion_service.dart';
import 'package:app_alabanzas/models/actividad.dart';
import 'package:app_alabanzas/models/miembro.dart';
import 'package:app_alabanzas/repositories/miembro_repository.dart';
import 'package:app_alabanzas/models/cancion.dart';
import 'package:app_alabanzas/screens/actividades/actividad_utils.dart';
import 'package:app_alabanzas/screens/actividades/detalle_actividad_screen.dart';
import 'package:app_alabanzas/screens/contenido/agregar_alabanza_screen.dart';
import 'package:app_alabanzas/screens/contenido/repertorio_screen.dart';
import 'package:app_alabanzas/screens/ejercicios/ejercicios_screen.dart';
import 'package:app_alabanzas/screens/notas/mis_notas_screen.dart';

/// Pantalla 6 del prototipo. Punto de entrada después de Acceso — resumen
/// corto del repertorio y accesos directos a lo que se usa más seguido.
///
/// "Modo en vivo" todavía no lleva a nada real — solo cambia a la
/// pestaña "En vivo" del shell, que hoy es un placeholder (el Paso 4
/// tiene el prototipo P2P aislado en `main_prototipo_sync_local.dart`;
/// falta conectarlo al estado real de una canción).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onModoEnVivo});

  /// Cambia a la pestaña "En vivo" del shell — ver `PrincipalShellScreen`.
  final VoidCallback onModoEnVivo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final uid = context.read<AutenticacionService>().usuarioActual?.uid;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<Miembro?>(
            future: uid == null
                ? null
                : context.read<MiembroRepository>().buscarPorUid(uid),
            builder: (context, snapshot) {
              final nombre = snapshot.data?.nombre ?? '';
              final iniciales =
                  nombre.trim().isEmpty ? '?' : nombre.trim()[0].toUpperCase();
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Buenos días', style: tema.textTheme.bodyLarge),
                        Text(
                          nombre,
                          style: tema.textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.acento.withValues(alpha: 0.16),
                    child: Text(
                      iniciales,
                      style: tema.textTheme.titleMedium?.copyWith(
                        color: tema.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          const _TarjetaProximoServicio(),
          const SizedBox(height: 4),
          StreamBuilder<List<Cancion>>(
            stream: context.read<Repositorio<Cancion>>().watchAll(),
            builder: (context, snapshot) {
              final canciones = snapshot.data ?? const <Cancion>[];
              return Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: tema.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(
                    snapshot.connectionState == ConnectionState.waiting
                        ? 'Sincronizando repertorio...'
                        : '${canciones.length} alabanzas en el repertorio',
                    style: tema.textTheme.bodyMedium
                        ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _AccesoCard(
                icono: Icons.sensors,
                etiqueta: 'Modo en vivo',
                destacado: true,
                onTap: onModoEnVivo,
              ),
              _AccesoCard(
                icono: Icons.library_music_outlined,
                etiqueta: 'Repertorio',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RepertorioScreen()),
                ),
              ),
              _AccesoCard(
                icono: Icons.add,
                etiqueta: 'Agregar alabanza',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AgregarAlabanzaScreen(),
                  ),
                ),
              ),
              _AccesoCard(
                icono: Icons.sticky_note_2_outlined,
                etiqueta: 'Mis notas',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MisNotasScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EjerciciosScreen()),
              ),
              icon: const Icon(Icons.fitness_center_outlined),
              label: const Text('Ejercicios para practicar'),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'RECIENTES',
            style: tema.textTheme.labelLarge?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Cancion>>(
            stream: context.read<Repositorio<Cancion>>().watchAll(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(),
                );
              }
              final canciones = snapshot.data!;
              if (canciones.isEmpty) {
                return Text(
                  'Todavía no cargaste ninguna alabanza.',
                  style: tema.textTheme.bodyMedium
                      ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                );
              }
              // TODO(recientes): esto muestra las primeras 3 tal cual las
              // devuelve Firestore, no las últimas agregadas/tocadas de
              // verdad — Cancion todavía no guarda una fecha para ordenar
              // por eso.
              final destacadas = canciones.take(3).toList();
              return Column(
                children: [
                  for (final cancion in destacadas)
                    _TarjetaCancionReciente(cancion: cancion),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// La próxima Actividad con fecha futura, si hay alguna — no se muestra
/// nada si no hay ninguna cargada, en vez de simular un estado vacío
/// falso. Solo lectura: crear/editar actividades vive en la pestaña
/// Setlists.
class _TarjetaProximoServicio extends StatelessWidget {
  const _TarjetaProximoServicio();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Actividad>>(
      stream: context.read<Repositorio<Actividad>>().watchAll(),
      builder: (context, snapshot) {
        final ahora = DateTime.now();
        final proximas = (snapshot.data ?? const <Actividad>[])
            .where((a) => a.fecha.isAfter(ahora))
            .toList()
          ..sort((a, b) => a.fecha.compareTo(b.fecha));
        if (proximas.isEmpty) return const SizedBox.shrink();
        final proxima = proximas.first;
        final tema = Theme.of(context);

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radio + 4),
              side: BorderSide(
                color: tema.colorScheme.primary.withValues(alpha: 0.4),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PRÓXIMO SERVICIO',
                    style: tema.textTheme.labelSmall?.copyWith(
                      color: tema.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${formatearFechaActividad(proxima.fecha)} · '
                    '${TimeOfDay.fromDateTime(proxima.fecha).format(context)}',
                    style: tema.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${proxima.setlist.length} alabanzas',
                    style: tema.textTheme.bodyMedium
                        ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            DetalleActividadScreen(actividadId: proxima.id),
                      ),
                    ),
                    child: const Text('Ver setlist'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Tarjeta de acceso rápido en la grilla 2x2 de Home. `destacado` marca
/// "Modo en vivo" con un borde de color en vez de relleno sólido — sigue
/// siendo una tarjeta más, no un botón primario que compita con Guardar/
/// Confirmar en el resto de la app.
class _AccesoCard extends StatelessWidget {
  const _AccesoCard({
    required this.icono,
    required this.etiqueta,
    required this.onTap,
    this.destacado = false,
  });

  final IconData icono;
  final String etiqueta;
  final VoidCallback onTap;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radio + 4),
        side: destacado
            ? BorderSide(color: tema.colorScheme.primary, width: 1.4)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radio + 4),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, color: tema.colorScheme.primary),
              const SizedBox(height: 10),
              Text(
                etiqueta,
                style: tema.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Una fila de "Recientes": el avatar circular muestra el tono en vez de
/// la inicial del título — a un vistazo se ve en qué tono está cada
/// canción, no solo cuál es.
class _TarjetaCancionReciente extends StatelessWidget {
  const _TarjetaCancionReciente({required this.cancion});

  final Cancion cancion;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.acento.withValues(alpha: 0.16),
          child: Text(
            cancion.tonoOriginal,
            style: TextStyle(
              color: tema.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(cancion.titulo),
        subtitle: Text('Tono: ${cancion.tonoOriginal}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RepertorioScreen()),
        ),
      ),
    );
  }
}
