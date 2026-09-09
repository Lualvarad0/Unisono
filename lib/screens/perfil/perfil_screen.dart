import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_alabanzas/core/firestore/repositorio.dart';
import 'package:app_alabanzas/core/theme/app_theme.dart';
import 'package:app_alabanzas/models/miembro.dart';
import 'package:app_alabanzas/services/autenticacion_service.dart';
import 'package:app_alabanzas/services/foto_perfil_service.dart';
import 'package:app_alabanzas/services/preferencias_service.dart';
import 'package:app_alabanzas/screens/equipo/equipo_screen.dart';
import 'package:app_alabanzas/screens/notas/mis_notas_screen.dart';
import 'package:app_alabanzas/screens/perfil/acerca_de_screen.dart';
import 'package:app_alabanzas/screens/perfil/apariencia_screen.dart';
import 'package:app_alabanzas/screens/perfil/editar_perfil_screen.dart';

/// Pestaña "Perfil": quién sos (nombre, correo, roles, datos personales,
/// foto) con edición completa en una pantalla propia — no un diálogo
/// flotante, ver `EditarPerfilScreen` — más los accesos a Mi equipo/Mis
/// notas/Apariencia/Acerca de y cerrar sesión, en formato lista de
/// configuración (como Ajustes de iOS/Android) en vez de una pila de
/// botones sueltos.
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

class _Contenido extends StatefulWidget {
  const _Contenido({required this.miembro, required this.email});

  final Miembro? miembro;
  final String email;

  @override
  State<_Contenido> createState() => _ContenidoState();
}

class _ContenidoState extends State<_Contenido> {
  bool _subiendoFoto = false;

  Future<void> _cambiarFoto() async {
    final miembro = widget.miembro;
    final uid = context.read<AutenticacionService>().usuarioActual?.uid;
    if (miembro == null || uid == null) return;
    setState(() => _subiendoFoto = true);
    try {
      // La ruta de Storage usa el UID de Firebase Auth (`uid`), no el id
      // del documento `Miembro` — la regla de seguridad compara contra
      // `request.auth.uid`, que es ese mismo UID, no el id de Firestore.
      final url = await context.read<FotoPerfilService>().elegirYSubir(uid);
      if (url == null || !mounted) return;
      await context
          .read<Repositorio<Miembro>>()
          .actualizar(miembro.id, miembro.copyWith(fotoUrl: url));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos subir la foto. Probá de nuevo.')),
      );
    } finally {
      if (mounted) setState(() => _subiendoFoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final miembro = widget.miembro;
    final nombre = miembro?.nombreCompleto ?? '';
    final iniciales =
        nombre.trim().isEmpty ? '?' : nombre.trim()[0].toUpperCase();
    final preferencias = context.watch<PreferenciasService>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        // Encabezado tipo "tarjeta de cuenta" — el mismo patrón que
        // Google/Apple usan arriba de sus pantallas de cuenta: avatar
        // grande arriba, datos personales debajo, y la edición vive en la
        // lista de opciones (fila "Editar mi perfil"), no acá arriba.
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Avatar(
                      iniciales: iniciales,
                      fotoUrl: miembro?.fotoUrl,
                      subiendo: _subiendoFoto,
                    ),
                    const SizedBox(width: 16),
                    if (miembro != null)
                      OutlinedButton(
                        onPressed: _subiendoFoto ? null : _cambiarFoto,
                        // El tema global fija `minimumSize:
                        // Size.fromHeight(56)` para los botones grandes
                        // de formulario (ancho infinito a propósito, ver
                        // AppTheme) — acá, adentro de un Row sin
                        // Expanded, ese ancho infinito no tiene dónde
                        // resolverse. Este botón es chico a propósito
                        // (al lado del avatar, no ocupa la fila entera).
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                        ),
                        child: const Text('Cambiar foto'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  nombre.isEmpty ? 'Sin nombre' : nombre,
                  style:
                      tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.email,
                  style: tema.textTheme.bodyMedium
                      ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
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
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: miembro.progresoPerfil,
                            minHeight: 6,
                            backgroundColor: tema.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${(miembro.progresoPerfil * 100).round()}%',
                        style: tema.textTheme.bodySmall
                            ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
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
        // borde propio cada uno. "Acerca de" queda al final a propósito
        // — es la última decisión que alguien busca en unos Ajustes,
        // justo antes de Cerrar sesión (que queda en su propia tarjeta,
        // separada por ser una acción distinta a las demás).
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: ListTile.divideTiles(
              context: context,
              tiles: [
                if (miembro != null)
                  ListTile(
                    leading: const Icon(Icons.manage_accounts_outlined),
                    title: const Text('Editar mi perfil'),
                    subtitle: const Text('Nombre, instrumento'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditarPerfilScreen(miembro: miembro),
                      ),
                    ),
                  ),
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
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Apariencia'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        switch (preferencias.temaModo) {
                          ThemeMode.system => 'Sistema',
                          ThemeMode.light => 'Claro',
                          ThemeMode.dark => 'Oscuro',
                        },
                        style: tema.textTheme.bodyMedium
                            ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AparienciaScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Acerca de Unísono'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'v1',
                        style: tema.textTheme.bodyMedium
                            ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AcercaDeScreen()),
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

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.iniciales,
    required this.fotoUrl,
    required this.subiendo,
  });

  final String iniciales;
  final String? fotoUrl;
  final bool subiendo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Stack(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppTheme.acento.withValues(alpha: 0.16),
          backgroundImage: fotoUrl == null ? null : NetworkImage(fotoUrl!),
          child: fotoUrl != null
              ? null
              : Text(
                  iniciales,
                  style: tema.textTheme.headlineSmall?.copyWith(
                    color: tema.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        if (subiendo)
          Positioned.fill(
            child: CircleAvatar(
              backgroundColor: Colors.black.withValues(alpha: 0.45),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
