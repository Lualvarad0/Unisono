import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_alabanzas/core/firestore/repositorio.dart';
import 'package:app_alabanzas/models/actividad.dart';
import 'package:app_alabanzas/models/artista.dart';
import 'package:app_alabanzas/models/cancion.dart';
import 'package:app_alabanzas/models/ejercicio.dart';
import 'package:app_alabanzas/models/equipo.dart';
import 'package:app_alabanzas/models/miembro.dart';
import 'package:app_alabanzas/models/nota.dart';
import 'package:app_alabanzas/models/ritmo.dart';
import 'package:app_alabanzas/repositories/actividad_repository.dart';
import 'package:app_alabanzas/repositories/artista_repository.dart';
import 'package:app_alabanzas/repositories/cancion_repository.dart';
import 'package:app_alabanzas/repositories/ejercicio_repository.dart';
import 'package:app_alabanzas/repositories/equipo_repository.dart';
import 'package:app_alabanzas/repositories/miembro_repository.dart';
import 'package:app_alabanzas/repositories/nota_repository.dart';
import 'package:app_alabanzas/repositories/ritmo_repository.dart';
import 'package:app_alabanzas/repositories/usuario_equipo_repository.dart';
import 'package:app_alabanzas/screens/acceso/elegir_equipo_screen.dart';
import 'package:app_alabanzas/screens/contenido/principal_shell_screen.dart';
import 'package:app_alabanzas/services/autenticacion_service.dart';
import 'package:app_alabanzas/services/notificaciones_service.dart';
import 'package:app_alabanzas/widgets/logo_unisono.dart';

/// Entre Splash y el resto de la app: resuelve a qué equipo pertenece
/// esta cuenta (`usuarioEquipo/{uid}`) y recién ahí arma los providers
/// del contenido (repertorio, setlists, equipo, notas, ejercicios), ya
/// apuntando a las subcolecciones de ESE equipo — antes de esto no hay
/// forma de saber qué `equipoId` usar, porque son repositorios por
/// equipo, no globales (ver `core/firestore/equipo_collections.dart`).
///
/// Si la cuenta todavía no está vinculada a ningún equipo, pasa por
/// `ElegirEquipoScreen` (crear uno nuevo o unirse con un código) antes
/// de seguir.
class ResolverEquipoScreen extends StatefulWidget {
  const ResolverEquipoScreen({super.key});

  @override
  State<ResolverEquipoScreen> createState() => _ResolverEquipoScreenState();
}

class _ResolverEquipoScreenState extends State<ResolverEquipoScreen> {
  late Future<({String equipoId, String miembroId})?> _futuro = _resolver();

  Future<({String equipoId, String miembroId})?> _resolver() {
    final uid = context.read<AutenticacionService>().usuarioActual!.uid;
    return context.read<UsuarioEquipoRepository>().buscar(uid);
  }

  void _reintentar() {
    setState(() => _futuro = _resolver());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({String equipoId, String miembroId})?>(
      future: _futuro,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: LogoUnisono(tamano: 56)));
        }
        final resultado = snapshot.data;
        if (resultado == null) {
          return ElegirEquipoScreen(onListo: _reintentar);
        }
        return _ProveedoresDeEquipo(equipoId: resultado.equipoId);
      },
    );
  }
}

class _ProveedoresDeEquipo extends StatelessWidget {
  const _ProveedoresDeEquipo({required this.equipoId});

  final String equipoId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Equipo?>(
      future: context.read<EquipoRepository>().fetchById(equipoId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: LogoUnisono(tamano: 56)));
        }
        return MultiProvider(
          providers: [
            Provider<Equipo>.value(value: snapshot.data!),
            Provider<Repositorio<Ritmo>>(
              create: (_) => RitmoRepository(equipoId: equipoId),
            ),
            Provider<Repositorio<Artista>>(
              create: (_) => ArtistaRepository(equipoId: equipoId),
            ),
            Provider<CancionRepository>(
              create: (_) => CancionRepository(equipoId: equipoId),
            ),
            Provider<Repositorio<Cancion>>(
              create: (context) => context.read<CancionRepository>(),
            ),
            Provider<MiembroRepository>(
              create: (_) => MiembroRepository(equipoId: equipoId),
            ),
            Provider<Repositorio<Miembro>>(
              create: (context) => context.read<MiembroRepository>(),
            ),
            Provider<NotificacionesService>(
              create: (context) =>
                  NotificacionesService(context.read<MiembroRepository>()),
            ),
            Provider<ActividadRepository>(
              create: (_) => ActividadRepository(equipoId: equipoId),
            ),
            Provider<Repositorio<Actividad>>(
              create: (context) => context.read<ActividadRepository>(),
            ),
            Provider<NotaRepository>(
              create: (_) => NotaRepository(equipoId: equipoId),
            ),
            Provider<Repositorio<Nota>>(
              create: (context) => context.read<NotaRepository>(),
            ),
            Provider<EjercicioRepository>(
              create: (_) => EjercicioRepository(equipoId: equipoId),
            ),
            Provider<Repositorio<Ejercicio>>(
              create: (context) => context.read<EjercicioRepository>(),
            ),
          ],
          child: const PrincipalShellScreen(),
        );
      },
    );
  }
}
