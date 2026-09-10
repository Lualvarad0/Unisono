import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_alabanzas/services/autenticacion_service.dart';
import 'package:app_alabanzas/screens/acceso/crear_cuenta_screen.dart';
import 'package:app_alabanzas/screens/acceso/login_screen.dart';
import 'package:app_alabanzas/screens/acceso/seleccion_rol_screen.dart';
import 'package:app_alabanzas/widgets/logo_unisono.dart';

/// Splash + Bienvenida (pantallas 1/4d del prototipo) en una sola: mientras
/// `AutenticacionService.estadoDeSesion` resuelve si hay sesión activa,
/// esto es lo primero que ve cualquiera al abrir la app. Sin sesión ->
/// Bienvenida con Login/Crear cuenta. Con sesión -> Selección de rol, que
/// decide sola si hace falta preguntar algo o si ya se puede pasar.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final autenticacion = context.read<AutenticacionService>();
    return StreamBuilder<Object?>(
      stream: autenticacion.estadoDeSesion,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Cargando();
        }
        if (snapshot.data != null) {
          return const SeleccionRolScreen();
        }
        return const _Bienvenida();
      },
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: LogoUnisono(tamano: 56)),
    );
  }
}

class _Bienvenida extends StatelessWidget {
  const _Bienvenida();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 3),
              const LogoUnisono(tamano: 64),
              const SizedBox(height: 24),
              Text(
                'Tu repertorio. Tu equipo.\nSiempre sincronizados.',
                textAlign: TextAlign.center,
                style: tema.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Letra, acordes y tonalidades para todo tu equipo, '
                'incluso sin internet.',
                textAlign: TextAlign.center,
                style: tema.textTheme.bodyLarge?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(flex: 4),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text('Iniciar sesión'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CrearCuentaScreen()),
                ),
                child: const Text('Crear cuenta'),
              ),
              const SizedBox(height: 24),
              Text(
                'Código abierto · Funciona sin internet',
                style: tema.textTheme.labelMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
