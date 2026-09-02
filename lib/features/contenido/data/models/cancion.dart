import 'package:equatable/equatable.dart';

import '../../../../core/firestore/model_converter.dart';

/// Una canción del repertorio.
///
/// `contenidoChordPro` guarda la letra y los acordes completos en formato
/// ChordPro (https://www.chordpro.org/chordpro/chordpro-file-format-specification/),
/// usando las directivas de sección estándar del spec, por ejemplo:
///
/// ```
/// {start_of_verse: Verso 1}
/// Cuán [G]grande es tu [D]amor
/// {end_of_verse}
/// {start_of_chorus: Coro}
/// [Em]Grande, [C]grande es tu [G]amor
/// {end_of_chorus}
/// ```
///
/// El parser/renderer (Paso 3) lee esas directivas para dividir la canción
/// en secciones navegables — las mismas secciones que la Capa 2 resalta y
/// avanza automáticamente cuando el líder cambia de parte.
class Cancion extends Equatable {
  const Cancion({
    required this.id,
    required this.titulo,
    required this.ritmoId,
    this.artistaId,
    required this.tonoOriginal,
    required this.contenidoChordPro,
  });

  final String id;
  final String titulo;
  final String ritmoId;

  /// null = "Varios" / sin artista específico.
  final String? artistaId;

  final String tonoOriginal;
  final String contenidoChordPro;

  factory Cancion.fromMap(String id, Map<String, dynamic> map) {
    return Cancion(
      id: id,
      titulo: map['titulo'] as String? ?? '',
      ritmoId: map['ritmoId'] as String? ?? '',
      artistaId: map['artistaId'] as String?,
      tonoOriginal: map['tonoOriginal'] as String? ?? 'C',
      contenidoChordPro: map['contenidoChordPro'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'titulo': titulo,
        'ritmoId': ritmoId,
        'artistaId': artistaId,
        'tonoOriginal': tonoOriginal,
        'contenidoChordPro': contenidoChordPro,
      };

  Cancion copyWith({
    String? titulo,
    String? ritmoId,
    String? artistaId,
    bool limpiarArtista = false,
    String? tonoOriginal,
    String? contenidoChordPro,
  }) {
    return Cancion(
      id: id,
      titulo: titulo ?? this.titulo,
      ritmoId: ritmoId ?? this.ritmoId,
      artistaId: limpiarArtista ? null : (artistaId ?? this.artistaId),
      tonoOriginal: tonoOriginal ?? this.tonoOriginal,
      contenidoChordPro: contenidoChordPro ?? this.contenidoChordPro,
    );
  }

  static final converter = ModelConverter<Cancion>(
    fromMap: Cancion.fromMap,
    toMap: (c) => c.toMap(),
  );

  @override
  List<Object?> get props =>
      [id, titulo, ritmoId, artistaId, tonoOriginal, contenidoChordPro];
}
