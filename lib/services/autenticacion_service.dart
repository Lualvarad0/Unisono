import 'package:firebase_auth/firebase_auth.dart';

/// Envoltorio sobre `FirebaseAuth` para las pantallas de Acceso (Splash,
/// Login, Crear cuenta, Recuperar contraseña). Traduce los códigos de
/// error de Firebase a mensajes en español que alguien sin conocimiento
/// técnico puede entender — nadie del equipo debería ver
/// `invalid-credential` en una alerta.
///
/// A diferencia del contenido (Capa 1, que funciona sin internet gracias
/// a la caché de Firestore), iniciar/crear sesión SÍ necesita conexión la
/// primera vez — Firebase Auth no tiene modo offline para eso.
class AutenticacionService {
  AutenticacionService({FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// `null` cuando no hay nadie logueado. Lo escucha la pantalla Splash
  /// para decidir a dónde mandar a cada uno al abrir la app.
  Stream<User?> get estadoDeSesion => _auth.authStateChanges();

  User? get usuarioActual => _auth.currentUser;

  Future<void> iniciarSesion({
    required String email,
    required String contrasena,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: contrasena,
      );
    } on FirebaseAuthException catch (e) {
      throw AutenticacionExcepcion(_mensaje(e.code));
    }
  }

  Future<void> crearCuenta({
    required String email,
    required String contrasena,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: contrasena,
      );
    } on FirebaseAuthException catch (e) {
      throw AutenticacionExcepcion(_mensaje(e.code));
    }
  }

  Future<void> recuperarContrasena({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AutenticacionExcepcion(_mensaje(e.code));
    }
  }

  Future<void> cerrarSesion() => _auth.signOut();

  static String _mensaje(String codigo) => switch (codigo) {
        'invalid-email' => 'Ese correo no parece válido.',
        'user-disabled' => 'Esta cuenta fue deshabilitada.',
        'user-not-found' => 'No hay ninguna cuenta con ese correo.',
        'wrong-password' => 'La contraseña no es correcta.',
        'invalid-credential' => 'Correo o contraseña incorrectos.',
        'email-already-in-use' => 'Ya existe una cuenta con ese correo.',
        'weak-password' => 'La contraseña necesita al menos 6 caracteres.',
        'too-many-requests' =>
          'Demasiados intentos — esperá un momento y probá de nuevo.',
        'network-request-failed' =>
          'Sin conexión — para entrar o crear una cuenta hace falta '
              'internet, aunque después la app funcione sin ella.',
        _ => 'Algo no funcionó. Probá de nuevo en un momento.',
      };
}

/// Error de autenticación ya traducido a un mensaje que se puede mostrar
/// directo en pantalla.
class AutenticacionExcepcion implements Exception {
  const AutenticacionExcepcion(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}
