import 'package:equatable/equatable.dart';

import 'package:app_alabanzas/services/chordpro/acorde.dart';

/// Tipo de sección de una canción, tomado de las directivas estándar de
/// ChordPro (`start_of_verse`/`sov`, `start_of_chorus`/`soc`,
/// `start_of_bridge`/`sob`, `start_of_tag`/`sot`).
///
/// "Intro" no es un tipo aparte del spec de ChordPro: se escribe como
/// `{start_of_verse: Intro}` — el *tipo* sigue siendo `verso`, pero la
/// `etiqueta` (el texto después de los dos puntos) es la que se muestra en
/// pantalla. Mismo criterio para "Puente instrumental", "Coro final", etc.
enum TipoSeccion { verso, coro, puente, tag, otra }

/// Un fragmento de línea: el acorde (si hay) que va *antes* de este trozo
/// de letra. `acorde == null` para el primer fragmento de una línea que
/// empieza con letra antes del primer acorde.
class SegmentoChordPro extends Equatable {
  final Acorde? acorde;
  final String letra;

  const SegmentoChordPro({this.acorde, required this.letra});

  SegmentoChordPro transponer(int semitonos) =>
      SegmentoChordPro(acorde: acorde?.transponer(semitonos), letra: letra);

  @override
  List<Object?> get props => [acorde, letra];
}

/// Una línea de la canción, ya separada en fragmentos letra/acorde.
class LineaChordPro extends Equatable {
  final List<SegmentoChordPro> segmentos;

  const LineaChordPro({required this.segmentos});

  /// Solo la letra, sin acordes — lo que necesita la Vista Cantante
  /// (Paso 5) para mostrar texto grande y legible sin ruido visual.
  String get soloLetra => segmentos.map((s) => s.letra).join();

  LineaChordPro transponer(int semitonos) => LineaChordPro(
        segmentos: segmentos.map((s) => s.transponer(semitonos)).toList(),
      );

  /// Reconstruye la línea en texto ChordPro (`[G]Cuán grande [D]es tu amor`).
  String toChordPro() {
    final buffer = StringBuffer();
    for (final segmento in segmentos) {
      if (segmento.acorde != null) buffer.write('[${segmento.acorde}]');
      buffer.write(segmento.letra);
    }
    return buffer.toString();
  }

  @override
  List<Object?> get props => [segmentos];
}

/// Una sección nombrada de la canción (Verso 1, Coro, Puente, ...).
class SeccionChordPro extends Equatable {
  final TipoSeccion tipo;
  final String etiqueta;
  final List<LineaChordPro> lineas;

  const SeccionChordPro({
    required this.tipo,
    required this.etiqueta,
    required this.lineas,
  });

  SeccionChordPro transponer(int semitonos) => SeccionChordPro(
        tipo: tipo,
        etiqueta: etiqueta,
        lineas: lineas.map((l) => l.transponer(semitonos)).toList(),
      );

  @override
  List<Object?> get props => [tipo, etiqueta, lineas];
}

/// Una canción completa ya parseada: la salida de `ChordProParser.parse`.
///
/// Es el modelo que consumen la Vista Músico y la Vista Cantante (Paso 5) y
/// el que sabe transportarse a sí mismo — así la pantalla nunca transporta
/// texto a mano, solo le pide a este objeto `transponer(offset)` con el
/// `tonoAsignado` de la `SetlistEntry` del día.
class CancionChordPro extends Equatable {
  final List<SeccionChordPro> secciones;

  const CancionChordPro({required this.secciones});

  CancionChordPro transponer(int semitonos) {
    if (semitonos == 0) return this;
    return CancionChordPro(
      secciones: secciones.map((s) => s.transponer(semitonos)).toList(),
    );
  }

  /// Reconstruye el documento completo en ChordPro, con las directivas de
  /// sección estándar. Sirve para guardar de vuelta en
  /// `Cancion.contenidoChordPro` después de editar el repertorio.
  String toChordPro() {
    final buffer = StringBuffer();
    for (final seccion in secciones) {
      final inicio = _directivaInicio(seccion.tipo);
      if (inicio != null) buffer.writeln('{$inicio: ${seccion.etiqueta}}');
      for (final linea in seccion.lineas) {
        buffer.writeln(linea.toChordPro());
      }
      final fin = _directivaFin(seccion.tipo);
      if (fin != null) buffer.writeln('{$fin}');
    }
    return buffer.toString().trimRight();
  }

  static String? _directivaInicio(TipoSeccion tipo) => switch (tipo) {
        TipoSeccion.verso => 'start_of_verse',
        TipoSeccion.coro => 'start_of_chorus',
        TipoSeccion.puente => 'start_of_bridge',
        TipoSeccion.tag => 'start_of_tag',
        TipoSeccion.otra => null,
      };

  static String? _directivaFin(TipoSeccion tipo) => switch (tipo) {
        TipoSeccion.verso => 'end_of_verse',
        TipoSeccion.coro => 'end_of_chorus',
        TipoSeccion.puente => 'end_of_bridge',
        TipoSeccion.tag => 'end_of_tag',
        TipoSeccion.otra => null,
      };

  @override
  List<Object?> get props => [secciones];
}
