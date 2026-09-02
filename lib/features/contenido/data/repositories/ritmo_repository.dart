import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_repository.dart';
import '../models/ritmo.dart';

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
