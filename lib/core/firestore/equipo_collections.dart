import 'package:cloud_firestore/cloud_firestore.dart';

/// Subcolección de un equipo puntual — `equipos/{equipoId}/{nombre}`.
/// Toda la Capa 1 (repertorio, setlists, integrantes, notas, ejercicios)
/// vive acá adentro, no suelta a nivel raíz: así cada equipo tiene su
/// propia base aislada, y una cuenta nueva no puede ver el contenido de
/// un equipo del que no es parte solo por estar logueada — ver
/// `firestore.rules`, función `equipoDeUsuario()`.
CollectionReference<Map<String, dynamic>> coleccionDeEquipo(
  String equipoId,
  String nombre,
) {
  return FirebaseFirestore.instance.collection('equipos').doc(equipoId).collection(nombre);
}
