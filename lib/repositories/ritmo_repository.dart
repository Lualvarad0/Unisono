import 'package:app_alabanzas/core/firestore/equipo_collections.dart';
import 'package:app_alabanzas/core/firestore/firestore_repository.dart';
import 'package:app_alabanzas/models/ritmo.dart';

/// Acceso a la subcolección `equipos/{equipoId}/ritmos`.
class RitmoRepository extends FirestoreRepository<Ritmo> {
  RitmoRepository({required String equipoId})
      : super(
          coleccionDeEquipo(equipoId, 'ritmos').withConverter<Ritmo>(
            fromFirestore: Ritmo.converter.fromFirestore,
            toFirestore: Ritmo.converter.toFirestore,
          ),
        );
}
