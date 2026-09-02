import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sistema visual "Nocturne", tomado del prototipo de diseño (32
/// pantallas): Inter en todo el texto, radios de 8px, y un acento blurple
/// que se usa como línea/resplandor — nunca como relleno grande de fondo.
/// Oscuro es la base (así está diseñado el prototipo); el claro existe
/// para el caso iOS con luz de sala.
///
/// Las vistas de Músico y Cantante (Paso 5) parten de acá pero además
/// suben el tamaño de letra puntual del bloque de la canción activa — dos
/// escalas de tipo separadas: preparación (13–25px) y en vivo (letra
/// 26–40px, acorde 15–17px). Acá solo se fija la escala de preparación.
class AppTheme {
  AppTheme._();

  static const acento = Color(0xFF6C63FF);
  static const radio = 8.0;

  /// Ningún estado de sincronización usa rojo de error — sin Internet no
  /// es un fallo. Rojo queda reservado para errores de verdad (ej. login).
  static const error = Color(0xFFE0526B);

  static ThemeData get dark => _base(Brightness.dark);
  static ThemeData get light => _base(Brightness.light);

  static ThemeData _base(Brightness brightness) {
    final esOscuro = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: acento,
      brightness: brightness,
      error: error,
    ).copyWith(
      surface: esOscuro ? const Color(0xFF14161F) : const Color(0xFFF7F7FB),
    );

    final textTheme = GoogleFonts.interTextTheme(
      esOscuro ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme.copyWith(
        bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: 18),
        bodyMedium: textTheme.bodyMedium?.copyWith(fontSize: 16),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(
          alpha: esOscuro ? 0.4 : 0.7,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radio),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radio),
          ),
          minimumSize: const Size.fromHeight(56), // mínimo táctil
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radio),
          ),
          minimumSize: const Size.fromHeight(56),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radio),
          ),
          minimumSize: const Size.fromHeight(56),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radio + 4),
        ),
      ),
    );
  }
}
