# Unísono

App offline-first para equipos de alabanza: letra, acordes y tonalidades
sincronizados entre todos los celulares del equipo, con o sin internet.
Cada equipo tiene su propio espacio aislado — se crea uno nuevo o te unís
a uno existente con un código de 6 caracteres, sin mezclarte con el
repertorio de otro grupo.

**Landing / descarga**: [app-alabanzas.web.app](https://app-alabanzas.web.app)

## Documentación

- **[docs/API.md](docs/API.md)** — modelo de datos en Firestore, Cloud
  Functions, y cómo la app accede a todo eso.
- **[docs/SEGURIDAD.md](docs/SEGURIDAD.md)** — reglas de Firestore/Storage,
  aislamiento entre equipos, manejo de secretos, qué queda afuera de
  alcance.
- **[docs/ESTILO_DE_CODIGO.md](docs/ESTILO_DE_CODIGO.md)** —
  convenciones del código: idioma, estructura, cómo se comenta, cómo se
  manejan errores y formularios.

## Qué hace

- **Repertorio con letra y acordes** en formato ChordPro, con transporte
  de tono instantáneo (ver [Cargar tu propio repertorio](#cargar-tu-propio-repertorio-chordpro)).
- **Equipos con código de invitación** — crear uno nuevo te deja como
  líder; unirte con un código te suma como integrante.
- **Setlists** por actividad (servicio/ensayo), con cantante y tono
  asignado por canción.
- **Modo en vivo**: el líder transmite qué canción/sección está sonando;
  el resto del equipo la ve sincronizada — por Firestore cuando hay
  internet, o por red local (Bluetooth/Wi-Fi) cuando no la hay (ver
  [Sincronización en vivo P2P](#sincronización-en-vivo-p2p-prototipo)).
- **Notificaciones push** cuando se arma/actualiza un setlist, cuando
  empieza el modo en vivo, cuando alguien se une al equipo, y recordatorio
  antes de que empiece una actividad.
- **Notas y ejercicios** de equipo, atados o no a una canción puntual.
- **Funciona sin internet** para todo lo ya sincronizado antes — gracias
  a la caché offline nativa de Firestore.

## Arquitectura (resumen)

`lib/` es **layer-first**: cada carpeta es una capa técnica, no un
dominio de negocio — el equivalente Dart a un backend organizado en
`model/repository/service/controller`.

```
lib/
  main.dart            # bootstrap: Firebase + runApp
  app.dart              # MaterialApp, tema, providers de nivel cuenta
  core/
    firestore/           # Repositorio<T>, FirestoreRepository<T>, coleccionDeEquipo()
    theme/                # AppTheme — tipografía y colores de toda la app
  models/               # datos inmutables (Equipo, Miembro, Cancion, Actividad...)
  repositories/          # un Repositorio<T> por modelo
  services/              # lógica de negocio sin widgets
    chordpro/              # parser + transposición, sin UI ni Firestore
    sync_local/             # transporte P2P en vivo (prototipo, ver abajo)
  screens/               # una pantalla = controller + view
    acceso/                 # login, crear cuenta, elegir/crear equipo
    contenido/               # home, repertorio, editor de canciones
    actividades/, equipo/, notas/, ejercicios/, en_vivo/, perfil/
  widgets/               # piezas de UI reutilizables entre pantallas
functions/              # Cloud Functions (Node) — notificaciones push
docs/                   # esta documentación
```

Ver [docs/API.md](docs/API.md) para el modelo de datos completo y
[docs/ESTILO_DE_CODIGO.md](docs/ESTILO_DE_CODIGO.md) para el porqué de
cada decisión (`Repositorio<T>` como interfaz, modelos inmutables,
imports absolutos, etc.).

## Requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.47.2+.
- Android toolchain (Android Studio o solo el SDK command-line) para
  compilar/correr en Android — sin esto se puede escribir código y
  correr `flutter analyze`/`flutter test`, pero no instalar en un
  celular/emulador.
- [Firebase CLI](https://firebase.google.com/docs/cli) (`npm i -g firebase-tools`)
  y [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/)
  (`dart pub global activate flutterfire_cli`).
- [Node.js 24](https://nodejs.org/) si vas a tocar las Cloud Functions
  de `functions/`.
- Una cuenta de Google para crear tu propio proyecto de Firebase (es
  gratis en el plan Spark para un equipo chico).

## Levantar el proyecto

```bash
git clone https://github.com/Lualvarad0/Unisono.git
cd Unisono
flutter pub get
```

Esto **no alcanza para correr la app todavía** — faltan los archivos de
configuración de Firebase, que son específicos de cada proyecto y por
eso están en `.gitignore` (ver [docs/SEGURIDAD.md](docs/SEGURIDAD.md#manejo-de-secretos)).

### 1. Crear y conectar tu proyecto de Firebase

```bash
firebase login
firebase projects:create unisono-tuequipo --display-name "Unísono"
flutterfire configure
```

`flutterfire configure` genera `lib/firebase_options.dart` y registra
automáticamente la app Android (`com.appalabanzas.app_alabanzas` —
cambialo en `android/app/build.gradle.kts` si querés tu propio id) e iOS
en Firebase. Te va a preguntar qué plataformas soportar — marcá al menos
`android`.

### 2. Habilitar Firestore y Authentication

Por consola, no hay forma confiable de hacerlo por CLI eligiendo región:

1. [console.firebase.google.com](https://console.firebase.google.com/) →
   tu proyecto → **Firestore Database** → **Crear base de datos** →
   modo **Producción** → elegí la región más cercana (no se puede
   cambiar después).
2. **Authentication** → **Comenzar** → habilitá el proveedor
   **Correo electrónico/contraseña**.

### 3. Publicar las reglas de seguridad y las Cloud Functions

```bash
firebase deploy --only firestore:rules,storage,functions
```

Esto publica `firestore.rules` y `storage.rules` tal como están en el
repo (documentados en [docs/SEGURIDAD.md](docs/SEGURIDAD.md)) y las 4
Cloud Functions de notificaciones (`functions/index.js`, documentadas en
[docs/API.md](docs/API.md#cloud-functions)). Sin este paso la app igual
funciona, pero nadie puede leer ni escribir nada (las reglas por defecto
de un proyecto nuevo lo bloquean todo) y no van a llegar notificaciones.

### 4. Correr la app

```bash
flutter analyze   # tiene que dar "No issues found"
flutter test
flutter run       # con un emulador/celular Android conectado
```

La primera cuenta que crees va a pasar por "¿Cómo arrancamos?" para
crear su propio equipo — a partir de ahí, cualquiera con el código de
ese equipo se puede sumar.

## Compilar y publicar un release firmado

Dos workflows de GitHub Actions ya configurados en `.github/workflows/`:

- **`build-debug-apk.yml`**: corre en cada push a `main`, compila un APK
  debug (firmado con una clave efímera, solo para probar) y lo deja
  como artifact descargable desde la pestaña Actions.
- **`release-apk.yml`**: se dispara con un tag `v*` (ej. `v1.0.0`) o a
  mano, compila un APK **release** firmado con el keystore real, y lo
  publica como GitHub Release — es el que se linkea desde la landing.

Para que `release-apk.yml` funcione en tu propio fork hacen falta estos
Secrets del repositorio (`Settings → Secrets and variables → Actions`):
`FIREBASE_OPTIONS_PARA_SECRET`, `GOOGLE_SERVICES_JSON`,
`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS` — ver [docs/SEGURIDAD.md](docs/SEGURIDAD.md#manejo-de-secretos)
para qué es cada uno y cómo generarlos.

## Cargar tu propio repertorio (ChordPro)

Las canciones se guardan en `Cancion.contenidoChordPro` en formato
[ChordPro](https://www.chordpro.org/chordpro/chordpro-file-format-specification/):
acordes entre corchetes intercalados con la letra, y las directivas
estándar del spec para marcar dónde empieza y termina cada sección.

```
{start_of_verse: Verso 1}
[G]Cuán grande [D]es tu amor
[Em]Grande en poder[C]
{end_of_verse}

{start_of_chorus}
[G]Cuán grande [D]es mi Dios
{end_of_chorus}
```

Directivas de sección reconocidas (forma larga o corta, da igual):

| Sección | Directiva |
|---|---|
| Verso (o Intro, Puente instrumental, etc. — cualquier texto libre como etiqueta) | `{start_of_verse: Etiqueta}` / `{sov}` … `{end_of_verse}` / `{eov}` |
| Coro | `{start_of_chorus: Etiqueta}` / `{soc}` … `{end_of_chorus}` / `{eoc}` |
| Puente | `{start_of_bridge: Etiqueta}` / `{sob}` … `{end_of_bridge}` / `{eob}` |
| Tag / final | `{start_of_tag: Etiqueta}` / `{sot}` … `{end_of_tag}` / `{eot}` |

La etiqueta (el texto después de `:`) es lo que se muestra en pantalla —
por eso "Intro" se escribe como `{start_of_verse: Intro}`, no como una
directiva propia: sigue siendo una sección tipo `verso` para el parser,
pero se etiqueta distinto en la UI. Sin etiqueta, usa una por defecto
("Coro", "Verso", "Puente", "Tag").

Cualquier otra directiva (`{title: ...}`, `{key: ...}`, `{comment: ...}`,
líneas que empiezan con `#`) se ignora al parsear — esos datos ya viven
en los campos propios de `Cancion`, así que un archivo `.cho` real, tal
cual lo exportó otro programa, se puede pegar sin editarlo a mano. Ver
[docs/API.md § ChordPro](docs/API.md#chordpro) para el uso programático
del parser.

## Sincronización en vivo P2P (prototipo)

Además del modo en vivo por Firestore (necesita internet), hay un
prototipo aislado de sincronización **sin internet** usando Nearby
Connections (`services/sync_local/`, pantallas en `screens/sync_local/`)
— dos pantallas mínimas (líder que transmite, seguidor que recibe), con
entry point propio (`lib/main_prototipo_sync_local.dart`) separado del
resto de la app.

### ⚠️ No funciona en emulador — y todavía no se probó en dos celulares reales

Nearby Connections necesita radios de Bluetooth/Wi-Fi Direct reales
("Android doesn't support emulator, only real devices", según el propio
paquete). Lo que sí está validado: la app instala, pide los permisos
correctos y llega a "Anunciando este celular como líder..." sin
crashear. **Falta la prueba real: conectar dos celulares Android y
confirmar que un valor viaja de uno a otro en vivo.**

```bash
flutter run -t lib/main_prototipo_sync_local.dart -d <id-del-celular-1>
flutter run -t lib/main_prototipo_sync_local.dart -d <id-del-celular-2>
```

En un celular tocá "Soy el líder", en el otro "Soy el seguidor", aceptá
los permisos de ubicación y "Nearby devices" en ambos, y conectá desde
"Dispositivos cercanos". El paquete publicado en pub.dev tenía dos
problemas de compilación contra herramientas actuales (`jcenter()`
descontinuado, y una API de registro de plugins eliminada hace años) —
la solución es [`packages/flutter_nearby_connections_plus/`](packages/flutter_nearby_connections_plus/),
una copia local parcheada (`dependency_overrides` en `pubspec.yaml`
apunta ahí), excluida del lint porque no es código propio.

## Pendientes conocidos

- Probar el modo en vivo P2P (arriba) en dos celulares Android reales.
- Probar el flujo completo en iOS (compilado, pero nunca corrido en un
  iPhone real — necesita Mac + Xcode).
- `Ejercicio.completadoPorUids` deja que cualquier integrante marque el
  ejercicio de otro como hecho/no hecho (ver [docs/SEGURIDAD.md](docs/SEGURIDAD.md#afuera-de-alcance)).
- Sin verificación de correo electrónico ni Firebase App Check.

## Licencia

[MIT](LICENSE) — se eligió sobre GPLv3 porque no restringe cómo cada
equipo distribuye su fork, y facilita usar el proyecto como base de apps
privadas sin fricción legal.
