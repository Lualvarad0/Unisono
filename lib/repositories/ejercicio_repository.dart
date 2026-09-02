import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_alabanzas/core/firestore/firestore_repository.dart';
import 'package:app_alabanzas/models/ejercicio.dart';

/// Acceso a la colección `ejercicios`.
class EjercicioRepository extends FirestoreRepository<Ejercicio> {
  EjercicioRepository()
      : super(
          FirebaseFirestore.instance
              .collection('ejercicios')
              .withConverter<Ejercicio>(
                fromFirestore: Ejercicio.converter.fromFirestore,
                toFirestore: Ejercicio.converter.toFirestore,
              ),
        );

  /// Marca (o desmarca) a `uid` como que ya practicó este ejercicio. Usa
  /// `arrayUnion`/`arrayRemove` en vez de leer el documento entero y
  /// reescribirlo con la lista modificada, para que dos integrantes
  /// marcando al mismo tiempo no se pisen el cambio uno al otro.
  Future<void> marcarCompletado(
    String ejercicioId,
    String uid, {
    required bool completado,
  }) {
    return collection.doc(ejercicioId).update({
      'completadoPorUids': completado
          ? FieldValue.arrayUnion([uid])
          : FieldValue.arrayRemove([uid]),
    });
  }
}
