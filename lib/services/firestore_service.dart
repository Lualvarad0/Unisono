import 'package:cloud_firestore/cloud_firestore.dart';

/// Configuración de Firestore para la Capa 1 (Contenido). Se llama una vez
/// desde `AppAlabanzas` (`app.dart`), justo después de `Firebase.initializeApp`.
///
/// La caché offline persistente ya viene activada por defecto en
/// Android/iOS; esto solo sube su límite de tamaño a "ilimitado", porque el
/// repertorio completo de una iglesia (texto plano: letras + acordes) pesa
/// muy poco y conviene tenerlo entero en el celular, no solo lo último que
/// se consultó.
void configurarFirestore() {
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
}
