import 'package:flutter/material.dart';

import 'package:app_alabanzas/core/theme/app_theme.dart';

/// El ícono de Unísono: barras de distinta altura, como un ecualizador —
/// "cuando varias voces suenan como una sola". Geometría simple a
/// propósito (nada de cruces ni instrumentos dibujados) para que aguante
/// bien chico en la pantalla de inicio del celular. Compartido entre
/// Splash y las pantallas de Acceso (Login, Crear cuenta) — antes vivía
/// solo, duplicado, en `splash_screen.dart`.
class LogoUnisono extends StatelessWidget {
  const LogoUnisono({super.key, required this.tamano});

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
