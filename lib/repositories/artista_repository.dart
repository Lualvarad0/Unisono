import 'package:app_alabanzas/core/firestore/equipo_collections.dart';
import 'package:app_alabanzas/core/firestore/firestore_repository.dart';
import 'package:app_alabanzas/models/artista.dart';

/// Acceso a la subcolección `equipos/{equipoId}/artistas`.
class ArtistaRepository extends FirestoreRepository<Artista> {
  ArtistaRepository({required String equipoId})
      : super(
          coleccionDeEquipo(equipoId, 'artistas').withConverter<Artista>(
            fromFirestore: Artista.converter.fromFirestore,
            toFirestore: Artista.converter.toFirestore,
          ),
        );
}
