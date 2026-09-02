import 'package:equatable/equatable.dart';

import 'package:app_alabanzas/core/firestore/model_converter.dart';

/// Una nota corta sobre una canción (o general, sin canción asociada) —
/// "entrar suave en el puente", "capo en 2", "revisar afinación del bajo".
///
/// Nunca modifica `Cancion.contenidoChordPro`: es una anotación aparte,
/// pensada para arreglos puntuales de un servicio o preferencias
/// personales que no tienen por qué quedar en la letra/acordes de base
/// que ve todo el mundo.
class Nota extends Equatable {
  const Nota({
    required this.id,
    required this.texto,
    required this.compartida,
    required this.autorUid,
    this.cancionId,
    this.seccionEtiqueta,
  });

  final String id;
  final String texto;

  /// true = visible para todo el equipo. false = solo la ve quien la creó.
  final bool compartida;

  final String autorUid;

  /// null = nota general, no atada a ninguna canción.
  final String? cancionId;

  /// Ej. "Puente", "Coro" — la sección de la canción a la que aplica.
  /// null si es una nota general de la canción entera (o si `cancionId`
  /// también es null).
  final String? seccionEtiqueta;

  factory Nota.fromMap(String id, Map<String, dynamic> map) {
    return Nota(
      id: id,
      texto: map['texto'] as String? ?? '',
      compartida: map['compartida'] as bool? ?? false,
      autorUid: map['autorUid'] as String? ?? '',
      cancionId: map['cancionId'] as String?,
      seccionEtiqueta: map['seccionEtiqueta'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'texto': texto,
        'compartida': compartida,
        'autorUid': autorUid,
        'cancionId': cancionId,
        'seccionEtiqueta': seccionEtiqueta,
      };

  static final converter = ModelConverter<Nota>(
    fromMap: Nota.fromMap,
    toMap: (n) => n.toMap(),
  );

  @override
  List<Object?> get props =>
      [id, texto, compartida, autorUid, cancionId, seccionEtiqueta];
}
