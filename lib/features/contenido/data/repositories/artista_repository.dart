import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_repository.dart';
import '../models/artista.dart';

/// Acceso a la colección `artistas`.
class ArtistaRepository extends FirestoreRepository<Artista> {
  ArtistaRepository()
      : super(
          FirebaseFirestore.instance
              .collection('artistas')
              .withConverter<Artista>(
                fromFirestore: Artista.converter.fromFirestore,
                toFirestore: Artista.converter.toFirestore,
              ),
        );
}
