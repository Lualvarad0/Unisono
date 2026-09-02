import 'package:equatable/equatable.dart';

/// Un acorde individual dentro de una canción en formato ChordPro
/// (ej. `G`, `Am7`, `F#m`, `D/F#`).
///
/// Acepta la nota fundamental tanto en cifrado americano (`C`, `D`, `Em`)
/// como en cifrado español/latino (`Do`, `Re`, `Mim`) — quien carga el
/// repertorio escribe en el que ya conoce. Internamente todo se guarda y
/// se muestra en americano (`nota`), que es el que usa el resto del
/// sistema (transposición, `Detectar tonalidad`, etc.) — esto es
/// normalización de *entrada*, no una preferencia de visualización por
/// usuario.
///
/// Si el texto no matchea la forma de un acorde reconocible (ej. `N.C.`,
/// una marca de percusión, o cualquier anotación libre), queda como
/// `reconocido = false` y se preserva tal cual — `transponer` no le hace
/// nada. Esto evita que el parser (`ChordProParser`) tenga que rechazar
/// archivos ChordPro reales, que suelen tener anotaciones no estándar.
class Acorde extends Equatable {
  final String textoOriginal;
  final bool reconocido;

  /// Nota fundamental ya deletreada (ej. `'C'`, `'F#'`, `'Bb'`).
  /// Cadena vacía si `!reconocido`.
  final String nota;

  /// Todo lo que va después de la nota fundamental: calidad, extensiones,
  /// tensiones (ej. `'m7'`, `'sus4'`, `'maj7'`, `''` para mayor simple).
  final String sufijo;

  /// Nota de bajo para acordes con bajo alterado tipo `D/F#`. `null` si no
  /// hay bajo explícito.
  final String? bajo;

  const Acorde._({
    required this.textoOriginal,
    required this.reconocido,
    this.nota = '',
    this.sufijo = '',
    this.bajo,
  });

  factory Acorde.crudo(String texto) =>
      Acorde._(textoOriginal: texto, reconocido: false);

  // El orden importa: "Sol"/"Si"/etc. tienen que probarse antes que
  // [A-Ga-g] para que "Sol" no matchee solo como si empezara con una nota
  // suelta rara — pero como ninguna nota en español es prefijo de otra
  // ("Do" vs "Re" vs "Mi" vs "Fa" vs "Sol" vs "La" vs "Si"), no hay
  // ambigüedad real entre ellas ni con las americanas de una letra
  // (p.ej. "D7" no matchea "Do" porque falta la "o").
  static final RegExp _notaAlInicio = RegExp(
    r'^(Do|Re|Mi|Fa|Sol|La|Si|[A-Ga-g])([#b])?',
    caseSensitive: false,
  );

  static const _notasEspanol = {
    'DO': 'C', 'RE': 'D', 'MI': 'E', 'FA': 'F', //
    'SOL': 'G', 'LA': 'A', 'SI': 'B', //
  };

  static String _normalizarNota(String letra) {
    final clave = letra.toUpperCase();
    return _notasEspanol[clave] ?? clave;
  }

  factory Acorde.parse(String texto) {
    final crudo = texto.trim();
    if (crudo.isEmpty) return Acorde.crudo(crudo);

    final partes = crudo.split('/');
    final principal = _notaAlInicio.firstMatch(partes[0]);
    if (principal == null) return Acorde.crudo(crudo);

    final nota =
        _normalizarNota(principal.group(1)!) + (principal.group(2) ?? '');
    final sufijo = partes[0].substring(principal.end);

    String? bajo;
    if (partes.length > 1) {
      final bajoMatch = _notaAlInicio.firstMatch(partes[1]);
      if (bajoMatch == null) return Acorde.crudo(crudo);
      bajo = _normalizarNota(bajoMatch.group(1)!) + (bajoMatch.group(2) ?? '');
    }

    return Acorde._(
      textoOriginal: crudo,
      reconocido: true,
      nota: nota,
      sufijo: sufijo,
      bajo: bajo,
    );
  }

  /// Transporta el acorde `semitonos` posiciones (positivo = sube, negativo
  /// = baja). Los acordes no reconocidos se devuelven sin cambios.
  ///
  /// La nota resultante se deletrea con sostenidos o con bemoles según cómo
  /// estaba escrito el acorde original — así una canción en Bb sigue
  /// mostrando Eb/Ab/Db en vez de saltar a D#/G#/C#, que es más difícil de
  /// leer en vivo.
  Acorde transponer(int semitonos) {
    if (!reconocido || semitonos == 0) return this;
    final usarBemoles = nota.contains('b') || (bajo?.contains('b') ?? false);
    final nuevaNota = _transponerNota(nota, semitonos, usarBemoles);
    final nuevoBajo =
        bajo == null ? null : _transponerNota(bajo!, semitonos, usarBemoles);
    return Acorde._(
      textoOriginal: textoOriginal,
      reconocido: true,
      nota: nuevaNota,
      sufijo: sufijo,
      bajo: nuevoBajo,
    );
  }

  static const _escalaConSostenidos = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B', //
  ];
  static const _escalaConBemoles = [
    'C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B', //
  ];
  static const _indiceNotaNatural = {
    'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11, //
  };

  static String _transponerNota(
      String notaOriginal, int semitonos, bool usarBemoles) {
    final letra = notaOriginal[0];
    final alteracion = notaOriginal.length > 1 ? notaOriginal.substring(1) : '';
    var indice = _indiceNotaNatural[letra]!;
    if (alteracion == '#') indice += 1;
    if (alteracion == 'b') indice -= 1;
    indice = (indice + semitonos) % 12; // % en Dart es módulo, siempre >= 0
    return (usarBemoles ? _escalaConBemoles : _escalaConSostenidos)[indice];
  }

  @override
  String toString() {
    if (!reconocido) return textoOriginal;
    final bajoTexto = bajo != null ? '/$bajo' : '';
    return '$nota$sufijo$bajoTexto';
  }

  @override
  List<Object?> get props => [textoOriginal, reconocido, nota, sufijo, bajo];
}
