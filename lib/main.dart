import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'features/sync_remoto/data/services/firestore_service.dart';
// Generado por `flutterfire configure` — ver README, sección "Configurar
// Firebase". No se comitea (está en .gitignore): cada iglesia usa su
// propio proyecto Firebase gratuito.
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  configurarFirestore();
  runApp(const AppAlabanzas());
}
