import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_alabanzas/core/firestore/firestore_repository.dart';
import 'package:app_alabanzas/models/ritmo.dart';

/// Acceso a la colección `ritmos`.
class RitmoRepository extends FirestoreRepository<Ritmo> {
  RitmoRepository()
      : super(
          FirebaseFirestore.instance
              .collection('ritmos')
              .withConverter<Ritmo>(
                fromFirestore: Ritmo.converter.fromFirestore,
                toFirestore: Ritmo.converter.toFirestore,
              ),
        );
}
