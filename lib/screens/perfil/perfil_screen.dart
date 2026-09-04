import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_alabanzas/core/firestore/repositorio.dart';
import 'package:app_alabanzas/core/theme/app_theme.dart';
import 'package:app_alabanzas/models/miembro.dart';
import 'package:app_alabanzas/services/autenticacion_service.dart';
import 'package:app_alabanzas/screens/equipo/equipo_screen.dart';
import 'package:app_alabanzas/screens/notas/mis_notas_screen.dart';
import 'package:app_alabanzas/screens/perfil/editar_perfil_screen.dart';

/// Pestaña "Perfil": quién sos (nombre, correo, roles, datos personales)
/// con edición completa en una pantalla propia — no un diálogo flotante,
/// ver `EditarPerfilScreen` — más los accesos a Mi equipo/Mis notas y
/// cerrar sesión, en formato lista de configuración (como Ajustes de
/// iOS/Android) en vez de una pila de botones sueltos.
///
/// El correo es de Firebase Auth y no se edita acá — cambiarlo pide
/// reautenticación y no es parte de este pedido.
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.read<AutenticacionService>().usuarioActual;
    final uid = usuario?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: StreamBuilder<List<Miembro>>(
        stream: context.read<Repositorio<Miembro>>().watchAll(),
        builder: (context, snapshot) {
          final coincidencias =
              (snapshot.data ?? const <Miembro>[]).where((m) => m.uid == uid);
          final miembro = coincidencias.isEmpty ? null : coincidencias.first;
          return _Contenido(miembro: miembro, email: usuario?.email ?? '');
        },
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.miembro, required this.email});

  final Miembro? miembro;
  final String email;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final miembro = this.miembro;
    final nombre = miembro?.nombreCompleto ?? '';
    final iniciales =
        nombre.trim().isEmpty ? '?' : nombre.trim()[0].toUpperCase();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        // Encabezado tipo "tarjeta de cuenta" — el mismo patrón que
        // Google/Apple usan arriba de sus pantallas de cuenta: avatar
        // grande, nombre, correo, y el editar vive al lado, no como un
        // botón aparte más abajo.
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppTheme.acento.withValues(alpha: 0.16),
                      child: Text(
                        iniciales,
                        style: tema.textTheme.headlineSmall?.copyWith(
                          color: tema.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre.isEmpty ? 'Sin nombre' : nombre,
                            style: tema.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: tema.textTheme.bodyMedium?.copyWith(
                              color: tema.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (miembro != null) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (miembro.roles.isEmpty)
                                  Text(
                                    'Sin rol asignado',
                                    style: tema.textTheme.bodySmall?.copyWith(
                                      color: tema.colorScheme.onSurfaceVariant,
                                    ),
                                  )
                                else
                                  for (final rol in miembro.roles)
                                    Chip(
                                      label: Text(rol.nombreVisible),
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (miembro != null)
                      IconButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                EditarPerfilScreen(miembro: miembro),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Editar perfil',
                      ),
                  ],
                ),
                if (miembro != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: miembro.progresoPerfil,
                            minHeight: 6,
                            backgroundColor:
                                tema.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${(miembro.progresoPerfil * 100).round()}%',
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Perfil completo',
                    style: tema.textTheme.bodySmall
                        ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (miembro != null &&
            (miembro.edad != null ||
                (miembro.telefono?.isNotEmpty ?? false) ||
                (miembro.instrumento?.isNotEmpty ?? false) ||
                miembro.nivelInstrumento != null)) ...[
          const SizedBox(height: 24),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: ListTile.divideTiles(
                context: context,
                tiles: [
                  if (miembro.edad != null)
                    ListTile(
                      leading: const Icon(Icons.cake_outlined),
                      title: const Text('Edad'),
                      trailing: Text('${miembro.edad} años'),
                    ),
                  if (miembro.telefono?.isNotEmpty ?? false)
                    ListTile(
                      leading: const Icon(Icons.call_outlined),
                      title: const Text('Teléfono'),
                      trailing: Text(miembro.telefono!),
                    ),
                  if (miembro.instrumento?.isNotEmpty ?? false)
                    ListTile(
                      leading: const Icon(Icons.music_note_outlined),
                      title: const Text('Instrumento'),
                      trailing: Text(miembro.instrumento!),
                    ),
                  if (miembro.nivelInstrumento != null)
                    ListTile(
                      leading: const Icon(Icons.trending_up),
                      title: const Text('Nivel'),
                      trailing: Text(miembro.nivelInstrumento!.nombreVisible),
                    ),
                ],
              ).toList(),
            ),
          ),
        ],
        const SizedBox(height: 24),
        // Lista de opciones agrupada — mismo patrón visual que una
        // pantalla de Ajustes nativa: filas con ícono + título + flecha,
        // separadas por líneas finas, en vez de botones sueltos con
        // borde propio cada uno.
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: ListTile.divideTiles(
              context: context,
              tiles: [
                ListTile(
                  leading: const Icon(Icons.groups_outlined),
                  title: const Text('Mi equipo'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EquipoScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.sticky_note_2_outlined),
                  title: const Text('Mis notas'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MisNotasScreen()),
                  ),
                ),
              ],
            ).toList(),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: Icon(Icons.logout, color: tema.colorScheme.error),
            title: Text(
              'Cerrar sesión',
              style: TextStyle(color: tema.colorScheme.error),
            ),
            onTap: () => context.read<AutenticacionService>().cerrarSesion(),
          ),
        ),
      ],
    );
  }
}
