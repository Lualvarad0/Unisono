import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_alabanzas/core/firestore/repositorio.dart';
import 'package:app_alabanzas/core/theme/app_theme.dart';
import 'package:app_alabanzas/models/miembro.dart';
import 'package:app_alabanzas/repositories/miembro_repository.dart';
import 'package:app_alabanzas/services/autenticacion_service.dart';
import 'package:app_alabanzas/screens/equipo/equipo_screen.dart';
import 'package:app_alabanzas/screens/notas/mis_notas_screen.dart';

/// Pestaña "Perfil": quién sos (nombre, correo, roles) con edición de
/// nombre y roles propios, más los accesos a Mi equipo/Mis notas y cerrar
/// sesión, en formato lista de configuración (como Ajustes de iOS/Android)
/// en vez de una pila de botones sueltos.
///
/// Edita `nombre`/`roles` en `Miembro` directamente — el correo es de
/// Firebase Auth y no se toca acá (cambiarlo pide reautenticación y no es
/// parte de este pedido).
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

  Future<void> _editarPerfil(BuildContext context) async {
    final miembroActual = miembro;
    if (miembroActual == null) return;
    final repositorio = context.read<MiembroRepository>();
    final actualizado = await showDialog<Miembro>(
      context: context,
      builder: (_) => _DialogoEditarPerfil(miembro: miembroActual),
    );
    if (actualizado == null) return;
    await repositorio.actualizar(miembroActual.id, actualizado);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final nombre = miembro?.nombre ?? '';
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
            child: Row(
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
                            if (miembro!.roles.isEmpty)
                              Text(
                                'Sin rol asignado',
                                style: tema.textTheme.bodySmall?.copyWith(
                                  color: tema.colorScheme.onSurfaceVariant,
                                ),
                              )
                            else
                              for (final rol in miembro!.roles)
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
                    onPressed: () => _editarPerfil(context),
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Editar perfil',
                  ),
              ],
            ),
          ),
        ),
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

class _DialogoEditarPerfil extends StatefulWidget {
  const _DialogoEditarPerfil({required this.miembro});

  final Miembro miembro;

  @override
  State<_DialogoEditarPerfil> createState() => _DialogoEditarPerfilState();
}

class _DialogoEditarPerfilState extends State<_DialogoEditarPerfil> {
  late final _nombreController =
      TextEditingController(text: widget.miembro.nombre);
  late final Set<RolMiembro> _roles = {...widget.miembro.roles};

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar perfil'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nombreController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nombre *'),
            ),
            const SizedBox(height: 20),
            Text('Roles', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final rol in RolMiembro.values)
                  FilterChip(
                    label: Text(rol.nombreVisible),
                    selected: _roles.contains(rol),
                    onSelected: (marcado) => setState(() {
                      if (marcado) {
                        _roles.add(rol);
                      } else {
                        _roles.remove(rol);
                      }
                    }),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final nombre = _nombreController.text.trim();
            if (nombre.isEmpty) return;
            Navigator.of(context).pop(
              widget.miembro.copyWith(nombre: nombre, roles: _roles.toList()),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
