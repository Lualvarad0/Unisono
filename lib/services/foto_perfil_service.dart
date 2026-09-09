import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Elige y sube la foto de perfil a Firebase Storage — Firestore no es
/// para archivos binarios, así que el documento del `Miembro` solo guarda
/// la URL de descarga (`fotoUrl`), no la imagen en sí.
///
/// Un archivo por persona a propósito (`perfiles/<uid>.jpg`, siempre el
/// mismo nombre): cada foto nueva pisa la anterior en vez de acumular
/// archivos huérfanos en Storage que nadie referencia ni borra.
class FotoPerfilService {
  FotoPerfilService({ImagePicker? picker, FirebaseStorage? storage})
      : _picker = picker ?? ImagePicker(),
        _storage = storage ?? FirebaseStorage.instance;

  final ImagePicker _picker;
  final FirebaseStorage _storage;

  /// Abre la galería, comprime a un tamaño razonable para un avatar
  /// (evita subir fotos de varios MB sin necesidad) y sube el resultado.
  /// Devuelve la URL de descarga, o `null` si se canceló la selección.
  Future<String?> elegirYSubir(String uid) async {
    final elegida = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (elegida == null) return null;

    final referencia = _storage.ref('perfiles/$uid.jpg');
    await referencia.putFile(File(elegida.path));
    return referencia.getDownloadURL();
  }
}
