import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/firestore/repositorio.dart';
import 'core/theme/app_theme.dart';
import 'features/acceso/data/services/autenticacion_service.dart';
import 'features/acceso/presentation/splash_screen.dart';
import 'features/actividades/data/models/actividad.dart';
import 'features/actividades/data/models/miembro.dart';
import 'features/actividades/data/repositories/actividad_repository.dart';
import 'features/actividades/data/repositories/miembro_repository.dart';
import 'features/contenido/data/models/artista.dart';
import 'features/contenido/data/models/cancion.dart';
import 'features/contenido/data/models/ritmo.dart';
import 'features/contenido/data/repositories/artista_repository.dart';
import 'features/contenido/data/repositories/cancion_repository.dart';
import 'features/contenido/data/repositories/ritmo_repository.dart';

/// Widget raíz. Registra los repositorios de la Capa 1 (Contenido) y el
/// servicio de Acceso como providers globales: cualquier pantalla, sin
/// importar a qué feature pertenezca, puede leerlos con
/// `context.read<Repositorio<X>>()` / `context.read<AutenticacionService>()`.
///
/// Se registran contra la interfaz `Repositorio<T>`, no contra la clase
/// concreta (`RitmoRepository`, etc.): así ninguna pantalla queda atada a
/// "esto es Firestore" — el día que haga falta otra implementación
/// (memoria para tests, caché local) se cambia acá, en un solo lugar, sin
/// tocar pantallas. Ver el doc de `Repositorio` para más detalle.
///
/// Se resuelven acá arriba, y no dentro de cada feature, porque varias
/// pantallas futuras cruzan features — por ejemplo, armar un setlist
/// (actividades) necesita elegir canciones (contenido).
class AppAlabanzas extends StatelessWidget {
  const AppAlabanzas({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AutenticacionService>(create: (_) => AutenticacionService()),
        Provider<Repositorio<Ritmo>>(create: (_) => RitmoRepository()),
        Provider<Repositorio<Artista>>(create: (_) => ArtistaRepository()),
        // CancionRepository y MiembroRepository suman métodos que no son
        // parte del CRUD genérico (watchByRitmo, buscarPorUid): se
        // registran también por su tipo concreto para que una pantalla
        // que los necesite los pida con `context.read<XRepository>()`,
        // sin crear una segunda instancia (la de abajo reutiliza esta).
        Provider<CancionRepository>(create: (_) => CancionRepository()),
        Provider<Repositorio<Cancion>>(
          create: (context) => context.read<CancionRepository>(),
        ),
        Provider<MiembroRepository>(create: (_) => MiembroRepository()),
        Provider<Repositorio<Miembro>>(
          create: (context) => context.read<MiembroRepository>(),
        ),
        Provider<Repositorio<Actividad>>(create: (_) => ActividadRepository()),
      ],
      child: MaterialApp(
        title: 'Unísono',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
      ),
    );
  }
}
