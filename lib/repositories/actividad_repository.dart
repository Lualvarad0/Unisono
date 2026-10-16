import 'package:app_alabanzas/core/firestore/equipo_collections.dart';
import 'package:app_alabanzas/core/firestore/firestore_repository.dart';
import 'package:app_alabanzas/models/actividad.dart';

/// Acceso a la subcolección `equipos/{equipoId}/actividades`.
class ActividadRepository extends FirestoreRepository<Actividad> {
  ActividadRepository({required String equipoId})
      : super(
          coleccionDeEquipo(equipoId, 'actividades').withConverter<Actividad>(
            fromFirestore: Actividad.converter.fromFirestore,
            toFirestore: Actividad.converter.toFirestore,
          ),
        );

  /// Para el calendario de actividades (Paso 6): más reciente primero.
  Stream<List<Actividad>> watchOrdenadasPorFecha() {
    return collection
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
