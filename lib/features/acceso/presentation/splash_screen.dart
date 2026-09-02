import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../data/services/autenticacion_service.dart';
import 'crear_cuenta_screen.dart';
import 'login_screen.dart';
import 'seleccion_rol_screen.dart';

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
      body: Center(child: _LogoUnisono(tamano: 56)),
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
              const _LogoUnisono(tamano: 64),
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

/// El ícono de Unísono: barras de distinta altura, como un ecualizador —
/// "cuando varias voces suenan como una sola". Geometría simple a
/// propósito (nada de cruces ni instrumentos dibujados) para que aguante
/// bien chico en la pantalla de inicio del celular.
class _LogoUnisono extends StatelessWidget {
  const _LogoUnisono({required this.tamano});

  final double tamano;

  static const _alturasRelativas = [0.45, 0.7, 1.0, 0.7, 0.45];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        color: AppTheme.acento.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(tamano * 0.28),
      ),
      padding: EdgeInsets.all(tamano * 0.24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final altura in _alturasRelativas)
            Container(
              width: tamano * 0.08,
              height: tamano * 0.5 * altura,
              decoration: BoxDecoration(
                color: AppTheme.acento,
                borderRadius: BorderRadius.circular(tamano * 0.04),
              ),
            ),
        ],
      ),
    );
  }
}
