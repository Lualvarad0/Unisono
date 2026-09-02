import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_repository.dart';
import '../models/cancion.dart';

/// Acceso a la colección `canciones`.
class CancionRepository extends FirestoreRepository<Cancion> {
  CancionRepository()
      : super(
          FirebaseFirestore.instance
              .collection('canciones')
              .withConverter<Cancion>(
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
