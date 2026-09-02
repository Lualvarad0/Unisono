import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_repository.dart';
import '../models/nota.dart';

/// Acceso a la colección `notas`.
class NotaRepository extends FirestoreRepository<Nota> {
  NotaRepository()
      : super(
          FirebaseFirestore.instance.collection('notas').withConverter<Nota>(
                fromFirestore: Nota.converter.fromFirestore,
                toFirestore: Nota.converter.toFirestore,
              ),
        );

  /// Todas las notas visibles para `uid`: las suyas propias (personales o
  /// no) más las que cualquiera marcó como compartidas. Se filtra del
  /// lado del cliente porque Firestore no permite un OR de dos campos
  /// distintos (`autorUid == uid` OR `compartida == true`) en una sola
  /// query, y la colección de notas de un equipo chico es chica.
  Stream<List<Nota>> watchVisiblesPara(String uid) {
    return watchAll().map(
      (notas) =>
          notas.where((n) => n.compartida || n.autorUid == uid).toList(),
    );
  }
}
