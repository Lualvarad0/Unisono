import 'package:app_alabanzas/core/firestore/equipo_collections.dart';
import 'package:app_alabanzas/core/firestore/firestore_repository.dart';
import 'package:app_alabanzas/models/cancion.dart';

/// Acceso a la subcolección `equipos/{equipoId}/canciones`.
class CancionRepository extends FirestoreRepository<Cancion> {
  CancionRepository({required String equipoId})
      : super(
          coleccionDeEquipo(equipoId, 'canciones').withConverter<Cancion>(
            fromFirestore: Cancion.converter.fromFirestore,
            toFirestore: Cancion.converter.toFirestore,
          ),
        );

  /// Canciones de un ritmo específico — la jerarquía de navegación del
  /// repertorio es Ritmo -> Artista -> Canción.
  Stream<List<Cancion>> watchByRitmo(String ritmoId) {
    return collection
        .where('ritmoId', isEqualTo: ritmoId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
