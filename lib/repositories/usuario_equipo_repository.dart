import 'package:cloud_firestore/cloud_firestore.dart';

/// A qué equipo pertenece cada cuenta, y cuál es su `Miembro` ahí adentro
/// — vive en `usuarioEquipo/{uid}`, indexado directo por el uid de
/// Firebase Auth (no por un id autogenerado). Esa es la pieza clave que
/// permite que `firestore.rules` resuelva "a qué equipo pertenece quien
/// está pidiendo esto" con una lectura puntual (`get`) en vez de
/// necesitar una query, que las reglas de seguridad no soportan.
class UsuarioEquipoRepository {
  final _coleccion = FirebaseFirestore.instance.collection('usuarioEquipo');

  Future<({String equipoId, String miembroId})?> buscar(String uid) async {
    final doc = await _coleccion.doc(uid).get();
    final datos = doc.data();
    if (datos == null) return null;
    return (
      equipoId: datos['equipoId'] as String,
      miembroId: datos['miembroId'] as String,
    );
  }

  Future<void> vincular({
    required String uid,
    required String equipoId,
    required String miembroId,
  }) {
    return _coleccion.doc(uid).set({'equipoId': equipoId, 'miembroId': miembroId});
  }
}
