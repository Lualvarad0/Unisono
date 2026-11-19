import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'package:app_alabanzas/core/firestore/model_converter.dart';

/// Marca una Cancion como favorita para un Miembro puntual. Vive en
/// `equipos/{equipoId}/favoritas/{uid}/canciones/{cancionId}` — una
/// subcolección propia por `uid`, no un campo `favorita` en `Cancion`:
/// así las reglas de seguridad pueden negarle lectura y escritura a
/// cualquiera que no sea ese mismo uid (ver `firestore.rules`), y
/// "favorita" queda de cada persona, no del repertorio entero que
/// comparte todo el equipo.
///
/// `id` es el mismo valor que `Cancion.id` — no un id autogenerado
/// propio — así marcar/desmarcar es un `crear`/`eliminar` directo por
/// ese id, sin necesitar una query para encontrar qué borrar.
class Favorita extends Equatable {
  const Favorita({required this.id, this.agregadaEn});

  final String id;
  final DateTime? agregadaEn;

  factory Favorita.fromMap(String id, Map<String, dynamic> map) {
    return Favorita(
      id: id,
      agregadaEn: (map['agregadaEn'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'agregadaEn':
            agregadaEn == null ? null : Timestamp.fromDate(agregadaEn!),
      };

  static final converter = ModelConverter<Favorita>(
    fromMap: Favorita.fromMap,
    toMap: (f) => f.toMap(),
  );

  @override
  List<Object?> get props => [id, agregadaEn];
}
