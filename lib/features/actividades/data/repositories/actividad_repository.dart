import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_repository.dart';
import '../models/actividad.dart';

/// Acceso a la colección `actividades`.
class ActividadRepository extends FirestoreRepository<Actividad> {
  ActividadRepository()
      : super(
          FirebaseFirestore.instance
              .collection('actividades')
              .withConverter<Actividad>(
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
