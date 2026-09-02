import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:app_alabanzas/app.dart';
import 'package:app_alabanzas/services/firestore_service.dart';
// Generado por `flutterfire configure` — ver README, sección "Configurar
// Firebase". No se comitea (está en .gitignore): cada iglesia usa su
// propio proyecto Firebase gratuito.
import 'package:app_alabanzas/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  configurarFirestore();
  runApp(const AppAlabanzas());
}
