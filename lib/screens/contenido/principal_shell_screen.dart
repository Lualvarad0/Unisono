import 'package:flutter/material.dart';

import 'package:app_alabanzas/screens/contenido/home_screen.dart';
import 'package:app_alabanzas/screens/contenido/repertorio_screen.dart';
import 'package:app_alabanzas/screens/actividades/setlists_screen.dart';
import 'package:app_alabanzas/screens/en_vivo/en_vivo_screen.dart';
import 'package:app_alabanzas/screens/perfil/perfil_screen.dart';

/// Contenedor con la barra inferior de navegación (Inicio, Repertorio, En
/// vivo, Setlists, Perfil) — lo primero que se ve después de Acceso.
///
/// "En vivo" transmite con lo que ya hay (Firestore en tiempo real) en
/// vez de la Capa 2 P2P — ver doc de `VistaEnVivoScreen` y de
/// `Actividad.cancionActivaId`. El prototipo de sync P2P sigue aislado
/// en `main_prototipo_sync_local.dart`, sin conectar, para el día que
/// haga falta funcionar sin conexión también acá.
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
      const EnVivoScreen(),
      const SetlistsScreen(),
      const PerfilScreen(),
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
