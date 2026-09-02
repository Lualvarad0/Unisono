import 'package:cloud_firestore/cloud_firestore.dart';

/// Junta el `fromMap` / `toMap` de un modelo en las dos funciones que pide
/// `CollectionReference.withConverter`, para no repetir ese boilerplate en
/// cada repositorio. Cada modelo declara un `static final converter` de
/// este tipo (ver `ritmo.dart`, `cancion.dart`, etc.).
class ModelConverter<T> {
  const ModelConverter({required this.fromMap, required this.toMap});

  final T Function(String id, Map<String, dynamic> data) fromMap;
  final Map<String, dynamic> Function(T value) toMap;

  T fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? _,
  ) {
    return fromMap(snapshot.id, snapshot.data() ?? const {});
  }

  Map<String, dynamic> toFirestore(T value, SetOptions? _) => toMap(value);
}
