import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_alabanzas/services/autenticacion_service.dart';
import 'package:app_alabanzas/screens/notas/mis_notas_screen.dart';
import 'package:app_alabanzas/screens/contenido/home_screen.dart';
import 'package:app_alabanzas/screens/contenido/repertorio_screen.dart';
import 'package:app_alabanzas/screens/equipo/equipo_screen.dart';

/// Contenedor con la barra inferior de navegación (Inicio, Repertorio, En
/// vivo, Setlists, Perfil) — lo primero que se ve después de Acceso.
///
/// "En vivo" y "Setlists" son placeholders: esas rondas de pantallas
/// (Paso 4 ya tiene el prototipo de sync en vivo, pero falta conectarlo al
/// estado real de una canción; Setlists no se construyó todavía).
class PrincipalShellScreen extends StatefulWidget {
  const PrincipalShellScreen({super.key});

  @override
  State<PrincipalShellScreen> createState() => _PrincipalShellScreenState();
}

class _PrincipalShellScreenState extends State<PrincipalShellScreen> {
  int _indice = 0;

  @override
  Widget build(BuildContext context) {
    // No es `static const` porque Home necesita un callback que capture
    // `this` (para cambiar de pestaña a "En vivo" al tocar "Modo en
    // vivo") — el resto de las pantallas sigue siendo `const`.
    final pantallas = [
      HomeScreen(onModoEnVivo: () => setState(() => _indice = 2)),
      const RepertorioScreenSinAppBar(),
      const _ProximamenteScreen(titulo: 'En vivo'),
      const _ProximamenteScreen(titulo: 'Setlists'),
      const _PerfilScreen(),
    ];
    return Scaffold(
      appBar: _indice == 0 ? AppBar(title: const Text('Unísono')) : null,
      body: SafeArea(child: pantallas[_indice]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            label: 'Repertorio',
          ),
          NavigationDestination(icon: Icon(Icons.sensors), label: 'En vivo'),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            label: 'Setlists',
          ),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }
}

/// `RepertorioScreen` ya trae su propio `AppBar` (para cuando se navega a
/// ella desde un botón); acá, como pestaña del shell, no hace falta
/// duplicar la barra superior.
class RepertorioScreenSinAppBar extends StatelessWidget {
  const RepertorioScreenSinAppBar({super.key});

  @override
  Widget build(BuildContext context) => const RepertorioScreen();
}

class _ProximamenteScreen extends StatelessWidget {
  const _ProximamenteScreen({required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$titulo — todavía no construido',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _PerfilScreen extends StatelessWidget {
  const _PerfilScreen();

  @override
  Widget build(BuildContext context) {
    final usuario = context.read<AutenticacionService>().usuarioActual;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(radius: 32, child: Icon(Icons.person, size: 32)),
            const SizedBox(height: 16),
            Text(usuario?.email ?? ''),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EquipoScreen()),
              ),
              icon: const Icon(Icons.groups_outlined),
              label: const Text('Mi equipo'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MisNotasScreen()),
              ),
              icon: const Icon(Icons.sticky_note_2_outlined),
              label: const Text('Mis notas'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () =>
                  context.read<AutenticacionService>().cerrarSesion(),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
