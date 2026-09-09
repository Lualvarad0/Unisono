import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Escala de letra de la Vista en vivo (Paso 5) — separada de la escala de
/// preparación que fija `AppTheme` (ver su doc). Cuatro pasos a propósito,
/// no un slider: en el escenario nadie quiere andar ajustando con
/// precisión, solo elegir "más grande" o "más chico" de un vistazo.
enum TamanoLetra { pequeno, mediano, grande, muyGrande }

extension TamanoLetraEscala on TamanoLetra {
  String get etiqueta => switch (this) {
        TamanoLetra.pequeno => 'Pequeño',
        TamanoLetra.mediano => 'Mediano',
        TamanoLetra.grande => 'Grande',
        TamanoLetra.muyGrande => 'Muy grande',
      };

  /// Tamaño base de la letra en Vista en vivo, en px — `_SeccionEnVivo`
  /// todavía lo achica un poco si la sección tiene muchas líneas, para no
  /// desbordar la pantalla.
  double get tamanoBaseLetra => switch (this) {
        TamanoLetra.pequeno => 22,
        TamanoLetra.mediano => 28,
        TamanoLetra.grande => 34,
        TamanoLetra.muyGrande => 40,
      };
}

/// Preferencias de apariencia (tema, tamaño de letra, mostrar acordes,
/// mantener pantalla encendida) — ver `AparienciaScreen`. Viven en
/// `SharedPreferences`, local al celular: son de lectura personal, no
/// datos del equipo, así que no van a Firestore.
///
/// Se crea una sola vez en `_AppAlabanzasState` (junto con
/// `Firebase.initializeApp`) y se registra como `ChangeNotifierProvider`
/// — cualquier pantalla la lee con `context.watch<PreferenciasService>()`
/// para reconstruirse cuando cambia, o `context.read<...>()` para solo
/// disparar un cambio sin escuchar.
class PreferenciasService extends ChangeNotifier {
  PreferenciasService(this._prefs);

  final SharedPreferences _prefs;

  static const _claveTema = 'apariencia_tema';
  static const _claveTamanoLetra = 'apariencia_tamano_letra';
  static const _claveMostrarAcordes = 'apariencia_mostrar_acordes';
  static const _clavePantallaEncendida = 'apariencia_pantalla_encendida';

  static Future<PreferenciasService> cargar() async {
    return PreferenciasService(await SharedPreferences.getInstance());
  }

  ThemeMode get temaModo {
    final guardado = _prefs.getString(_claveTema);
    return ThemeMode.values.firstWhere(
      (m) => m.name == guardado,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> cambiarTema(ThemeMode modo) async {
    await _prefs.setString(_claveTema, modo.name);
    notifyListeners();
  }

  TamanoLetra get tamanoLetra {
    final guardado = _prefs.getString(_claveTamanoLetra);
    return TamanoLetra.values.firstWhere(
      (t) => t.name == guardado,
      orElse: () => TamanoLetra.mediano,
    );
  }

  Future<void> cambiarTamanoLetra(TamanoLetra tamano) async {
    await _prefs.setString(_claveTamanoLetra, tamano.name);
    notifyListeners();
  }

  /// Preferencia personal de ver acordes en Vista en vivo — combina con
  /// (no reemplaza) el permiso por rol: quien es Cantante nunca ve
  /// acordes, lo tenga prendido o no; esto es para que un Músico o Líder
  /// pueda apagarlos y leer solo la letra si así lo prefiere.
  bool get mostrarAcordes => _prefs.getBool(_claveMostrarAcordes) ?? true;

  Future<void> cambiarMostrarAcordes(bool valor) async {
    await _prefs.setBool(_claveMostrarAcordes, valor);
    notifyListeners();
  }

  bool get mantenerPantallaEncendida =>
      _prefs.getBool(_clavePantallaEncendida) ?? true;

  Future<void> cambiarMantenerPantallaEncendida(bool valor) async {
    await _prefs.setBool(_clavePantallaEncendida, valor);
    notifyListeners();
  }
}
