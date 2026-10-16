import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_alabanzas/core/theme/app_theme.dart';
import 'package:app_alabanzas/services/autenticacion_service.dart';
import 'package:app_alabanzas/services/firestore_service.dart';
import 'package:app_alabanzas/services/conectividad_service.dart';
import 'package:app_alabanzas/services/foto_perfil_service.dart';
import 'package:app_alabanzas/services/preferencias_service.dart';
import 'package:app_alabanzas/services/sync_local/conexion_local_service.dart';
import 'package:app_alabanzas/screens/acceso/splash_screen.dart';
import 'package:app_alabanzas/repositories/equipo_repository.dart';
import 'package:app_alabanzas/repositories/usuario_equipo_repository.dart';
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
  PreferenciasService? _preferencias;

  Future<void> _inicializarFirebase() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    configurarFirestore();
    _preferencias = await PreferenciasService.cargar();
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
        return _AppConProviders(preferencias: _preferencias!);
      },
    );
  }
}

/// La app real, una vez que Firebase ya está listo. Acá solo se registran
/// los providers de CUENTA (Acceso, preferencias, servicios que no
/// dependen de a qué equipo pertenece quien inició sesión) — los
/// repositorios de contenido (repertorio, setlists, integrantes, notas,
/// ejercicios) son por equipo, no globales, así que se arman recién en
/// `ResolverEquipoScreen` una vez que se sabe cuál es ese equipo. Ver el
/// doc de esa pantalla para la razón completa.
class _AppConProviders extends StatelessWidget {
  const _AppConProviders({required this.preferencias});

  final PreferenciasService preferencias;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AutenticacionService>(create: (_) => AutenticacionService()),
        ChangeNotifierProvider<PreferenciasService>.value(value: preferencias),
        Provider<FotoPerfilService>(create: (_) => FotoPerfilService()),
        Provider<ConectividadService>(create: (_) => ConectividadService()),
        Provider<ConexionLocalService>(create: (_) => ConexionLocalService()),
        Provider<EquipoRepository>(create: (_) => EquipoRepository()),
        Provider<UsuarioEquipoRepository>(create: (_) => UsuarioEquipoRepository()),
      ],
      child: Consumer<PreferenciasService>(
        builder: (context, preferencias, _) => MaterialApp(
          title: 'Unísono',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: preferencias.temaModo,
          home: const SplashScreen(),
        ),
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
