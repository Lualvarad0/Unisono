import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sistema visual "Nocturne", tomado del prototipo de diseño (32
/// pantallas): Inter en todo el texto, radios de 8px, y un acento blurple
/// que se usa como línea/resplandor — nunca como relleno grande de fondo.
/// Oscuro sigue siendo la base del diseño, pero ahora hay tema claro
/// también y el usuario elige Sistema/Claro/Oscuro desde Perfil →
/// Apariencia — ver `PreferenciasService` y `AparienciaScreen`. Los dos
/// comparten el mismo acento (`#6C63FF`, el mismo violeta del ícono de la
/// app) para que se sigan viendo como la misma app en cualquiera de los
/// dos modos; lo que cambia es la profundidad de las superficies: oscuro
/// usa un negro con tinte violeta bien marcado entre fondo/tarjeta/campo,
/// claro un blanco lavanda suave con la misma jerarquía.
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
      surface: esOscuro ? const Color(0xFF0F1120) : const Color(0xFFFAFAFE),
      surfaceContainer: esOscuro ? const Color(0xFF191C2E) : const Color(0xFFF0F0F8),
      surfaceContainerHighest:
          esOscuro ? const Color(0xFF262A42) : const Color(0xFFE7E7F3),
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
        // Más padding arriba que abajo: el label flotante (cuando el
        // campo tiene foco o contenido) necesita ese aire para no quedar
        // pegado al techo de la caja — sin esto se ve amontonado contra
        // el título de sección de arriba en vez de flotar con margen
        // propio.
        contentPadding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
        // El hint ("Ej. Guitarra...") tiene que leerse claramente como un
        // ejemplo, no como si ya hubiera algo escrito — opacidad baja lo
        // distingue del texto real qué se escribe (contraste completo).
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        floatingLabelStyle: TextStyle(color: colorScheme.primary),
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
