import 'package:app_alabanzas/core/firestore/equipo_collections.dart';
import 'package:app_alabanzas/core/firestore/firestore_repository.dart';
import 'package:app_alabanzas/models/nota.dart';

/// Acceso a la subcolección `equipos/{equipoId}/notas`.
class NotaRepository extends FirestoreRepository<Nota> {
  NotaRepository({required String equipoId})
      : super(
          coleccionDeEquipo(equipoId, 'notas').withConverter<Nota>(
            fromFirestore: Nota.converter.fromFirestore,
            toFirestore: Nota.converter.toFirestore,
          ),
        );

  /// Todas las notas visibles para `uid`: las suyas propias (personales o
  /// no) más las que cualquiera marcó como compartidas. Se filtra del
  /// lado del cliente porque Firestore no permite un OR de dos campos
  /// distintos (`autorUid == uid` OR `compartida == true`) en una sola
  /// query, y la colección de notas de un equipo chico es chica.
  Stream<List<Nota>> watchVisiblesPara(String uid) {
    return watchAll().map(
      (notas) =>
          notas.where((n) => n.compartida || n.autorUid == uid).toList(),
    );
  }
}
