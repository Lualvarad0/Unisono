import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_alabanzas/core/firestore/repositorio.dart';
import 'package:app_alabanzas/core/theme/app_theme.dart';
import 'package:app_alabanzas/services/autenticacion_service.dart';
import 'package:app_alabanzas/services/firestore_service.dart';
import 'package:app_alabanzas/screens/acceso/splash_screen.dart';
import 'package:app_alabanzas/models/actividad.dart';
import 'package:app_alabanzas/models/miembro.dart';
import 'package:app_alabanzas/repositories/actividad_repository.dart';
import 'package:app_alabanzas/repositories/miembro_repository.dart';
import 'package:app_alabanzas/models/artista.dart';
import 'package:app_alabanzas/models/cancion.dart';
import 'package:app_alabanzas/models/ritmo.dart';
import 'package:app_alabanzas/repositories/artista_repository.dart';
import 'package:app_alabanzas/repositories/cancion_repository.dart';
import 'package:app_alabanzas/repositories/ritmo_repository.dart';
import 'package:app_alabanzas/models/nota.dart';
import 'package:app_alabanzas/repositories/nota_repository.dart';
import 'package:app_alabanzas/models/ejercicio.dart';
import 'package:app_alabanzas/repositories/ejercicio_repository.dart';
// Generado por `flutterfire configure` — ver README, sección "Configurar
// Firebase". No se comitea (está en .gitignore): cada iglesia usa su
// propio proyecto Firebase gratuito.
import 'package:app_alabanzas/firebase_options.dart';

/// Widget raíz — y también el punto único donde arranca Firebase.
///
/// Antes de mostrar la app real hay que esperar `Firebase.initializeApp()`,
/// que puede fallar (sin internet en el primer arranque, proyecto mal
/// configurado) o tardar. En vez de hacer ese `await` en `main()` — lo que
/// deja la pantalla en blanco hasta que termina, y crashea la app entera
/// si falla — se maneja acá como estado de este widget: mientras carga se
/// ve nuestro propio logo, y si falla se ve un mensaje con botón
/// "Reintentar" en vez de la app muriendo antes de pintar nada.
class AppAlabanzas extends StatefulWidget {
  const AppAlabanzas({super.key});

  @override
  State<AppAlabanzas> createState() => _AppAlabanzasState();
}

class _AppAlabanzasState extends State<AppAlabanzas> {
  late Future<void> _inicializacion = _inicializarFirebase();

  Future<void> _inicializarFirebase() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    configurarFirestore();
  }

  void _reintentar() {
    setState(() => _inicializacion = _inicializarFirebase());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _inicializacion,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _ArranqueEnCurso();
        }
        if (snapshot.hasError) {
          return _ArranqueFallido(onReintentar: _reintentar);
        }
        return const _AppConProviders();
      },
    );
  }
}

/// La app real, una vez que Firebase ya está listo. Registra los
/// repositorios de la Capa 1 (Contenido) y el servicio de Acceso como
/// providers globales: cualquier pantalla, sin importar a qué capa
/// pertenezca, puede leerlos con `context.read<Repositorio<X>>()` /
/// `context.read<AutenticacionService>()`.
///
/// Se registran contra la interfaz `Repositorio<T>`, no contra la clase
/// concreta (`RitmoRepository`, etc.): así ninguna pantalla queda atada a
/// "esto es Firestore" — el día que haga falta otra implementación
/// (memoria para tests, caché local) se cambia acá, en un solo lugar, sin
/// tocar pantallas. Ver el doc de `Repositorio` para más detalle.
///
/// Se resuelven acá arriba, y no en `screens/`, porque varias pantallas
/// futuras cruzan capas — por ejemplo, armar un setlist necesita elegir
/// canciones.
class _AppConProviders extends StatelessWidget {
  const _AppConProviders();

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
        // ActividadRepository suma watchOrdenadasPorFecha, que no es parte
        // del CRUD genérico — mismo patrón que CancionRepository arriba.
        Provider<ActividadRepository>(create: (_) => ActividadRepository()),
        Provider<Repositorio<Actividad>>(
          create: (context) => context.read<ActividadRepository>(),
        ),
        Provider<NotaRepository>(create: (_) => NotaRepository()),
        Provider<Repositorio<Nota>>(
          create: (context) => context.read<NotaRepository>(),
        ),
        // EjercicioRepository suma marcarCompletado, que no es parte del
        // CRUD genérico — mismo patrón que CancionRepository arriba.
        Provider<EjercicioRepository>(create: (_) => EjercicioRepository()),
        Provider<Repositorio<Ejercicio>>(
          create: (context) => context.read<EjercicioRepository>(),
        ),
      ],
      child: MaterialApp(
        title: 'Unísono',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const SplashScreen(),
      ),
    );
  }
}

/// Se ve mientras `Firebase.initializeApp()` está en vuelo. Tiene su
/// propio `MaterialApp` chico (en vez de depender del de `_AppConProviders`,
/// que todavía no existe en este punto) para tener `Theme`/`Directionality`
/// y no reventar si algo acá adentro los necesita.
class _ArranqueEnCurso extends StatelessWidget {
  const _ArranqueEnCurso();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

/// Se ve si `Firebase.initializeApp()` falla — sin internet en el primer
/// arranque, o el proyecto de Firebase mal configurado. Nunca deja a
/// quien abre la app mirando una pantalla blanca o un crash sin
/// explicación: siempre hay un mensaje y un botón para reintentar.
class _ArranqueFallido extends StatelessWidget {
  const _ArranqueFallido({required this.onReintentar});

  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pudimos conectar',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Revisá tu conexión a internet e intentá de nuevo. Una '
                    'vez que entres, el repertorio queda guardado y '
                    'funciona sin conexión.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: onReintentar,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
