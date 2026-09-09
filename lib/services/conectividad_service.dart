import 'package:cloud_firestore/cloud_firestore.dart';

/// Si hay conexión a internet o no — sin agregar un paquete aparte
/// (`connectivity_plus`, etc.): Firestore ya sabe distinguir "esta
/// respuesta vino del caché local" de "vino del servidor", y esa
/// distinción es exactamente lo que hace falta acá. Escucha una
/// colección chica (`ritmos`, que además ya se usa en toda la app) con
/// `includeMetadataChanges: true` para enterarse apenas cambia.
///
/// No es una detección instantánea de "se cortó el wifi" — es "la
/// última vez que Firestore necesitó datos, ¿los sirvió del servidor o
/// del disco?", que es la definición de "en línea" que le importa a una
/// app offline-first como esta.
class ConectividadService {
  Stream<bool> watchEnLinea() {
    return FirebaseFirestore.instance
        .collection('ritmos')
        .limit(1)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => !snapshot.metadata.isFromCache);
  }
}
