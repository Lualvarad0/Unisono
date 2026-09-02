# App Alabanzas

App offline-first para grupos de alabanza: letras y acordes sincronizados
en tiempo real entre los celulares del equipo, con o sin internet en el
local.

## Cómo funciona (dos capas)

- **Capa 1 — Contenido**: antes del servicio, con wifi o datos, cada
  celular descarga su copia local del repertorio (ritmos, artistas,
  canciones) y de las actividades (setlists). Usa Firestore, que ya trae
  caché offline nativa. Es el código de `models/`, `repositories/` y
  `services/firestore_service.dart` relacionado con Firestore.
- **Capa 2 — Estado en vivo** (todo lo agrupado bajo `sync_local/` dentro
  de `services/`, `screens/` y `widgets/`): durante el servicio, sin
  internet, el celular del líder transmite por red local (Nearby
  Connections en Android / Multipeer Connectivity en iOS) qué canción y
  qué sección están sonando. Los demás celulares —que ya tienen el
  contenido descargado por la Capa 1— avanzan solos a esa misma parte.

## Estado del proyecto

- [x] Paso 1 — Estructura base del proyecto Flutter
- [x] Paso 2 — Modelos Dart + integración Firestore (offline-first)
- [x] Paso 3 — Parser/renderer de ChordPro (secciones + transposición)
- [x] Paso 4 — Prototipo aislado de la Capa 2 (Nearby Connections) —
      código listo y validado en Android (compila, corre, permisos OK);
      **falta la prueba real en dos celulares** (ver sección Paso 4)
- [ ] Paso 5 — Vista Músico y Vista Cantante
- [ ] Paso 6 — Calendario de actividades + armado de setlist

## Estructura de carpetas

El proyecto es **layer-first**: cada carpeta bajo `lib/` es una capa
técnica (`models/`, `repositories/`, `services/`, `screens/`, `widgets/`),
no un dominio del negocio — el equivalente Dart a un proyecto Java/Spring
organizado en `model/`, `repository/`, `service/`, `controller/`. Dentro
de cada capa, los archivos se agrupan en una subcarpeta por dominio
(`chordpro/`, `sync_local/`, `acceso/`...) solo cuando hay más de un
archivo relacionado — así una capa con muchos archivos sigue siendo
navegable sin volver a mezclar capas distintas.

```
lib/
  main.dart                     # bootstrap: Firebase + Firestore + runApp
  app.dart                      # MaterialApp, tema, providers globales (el "composition root")
  main_prototipo_sync_local.dart  # entry point SEPARADO del prototipo (Paso 4)
  core/
    firestore/                   # helpers compartidos por TODOS los repositorios
      repositorio.dart            # contrato Repositorio<T>: contra esto programa el resto de la app
      model_converter.dart        # fromMap/toMap -> withConverter, sin repetir boilerplate
      firestore_repository.dart   # implementación con Firestore de Repositorio<T>
    theme/
      app_theme.dart              # tipografía grande / alto contraste, pensado para atril
  models/                        # los "datos" — equivalente a entity/ en Java
    ritmo.dart, artista.dart, cancion.dart      # Capa 1: repertorio
    miembro.dart, actividad.dart, setlist_entry.dart  # Capa 1: calendario y setlists
    nota.dart                                   # notas del equipo
    chordpro/
      chordpro_modelo.dart        # CancionChordPro/SeccionChordPro/LineaChordPro (+ toChordPro)
  repositories/                  # acceso a datos — interfaz en core/, implementación acá
    ritmo_repository.dart, artista_repository.dart, cancion_repository.dart
    miembro_repository.dart, actividad_repository.dart
    nota_repository.dart
  services/                      # lógica de negocio pura, sin widgets
    autenticacion_service.dart    # login/registro/roles (Firebase Auth)
    firestore_service.dart        # Capa 1: configura la caché offline persistente
    chordpro/                     # parser + transposición de ChordPro (Paso 3), sin UI ni Firestore
      acorde.dart                  # Acorde: parseo (cifrado americano o español) + transposición
      chordpro_parser.dart         # ChordProParser.parse: texto crudo -> CancionChordPro
      editor_simple.dart           # conversión letra+acordes <-> ChordPro para el editor simple
    sync_local/                   # Capa 2: sincronización P2P en vivo (Paso 4)
      permisos_sync_local.dart     # pide Bluetooth/ubicación en runtime
      prototipo_conexion_service.dart  # wrapper delgado sobre NearbyService
  screens/                       # pantallas — cada widget cumple el rol de controller + view
    acceso/                        # login, registro, selección de rol
    contenido/                     # home, repertorio, agregar/editar/detalle de alabanza
    notas/                         # agregar y ver notas del equipo
    sync_local/                    # prototipo_lider_screen, prototipo_seguidor_screen (Paso 4)
  widgets/                       # piezas de UI reutilizables entre pantallas
    linea_chordpro_widget.dart     # una línea de letra+acordes ya renderizada
    sync_local/lista_dispositivos.dart
packages/
  flutter_nearby_connections_plus/  # copia local parcheada — ver Paso 4
```

### Por qué esta forma y no otra

- **Layer-first en vez de feature-first**: se eligió así para que la
  estructura resulte familiar viniendo de un backend Java/C#/Node
  organizado en capas (`model/service/repository/controller`). El costo
  conocido de este enfoque es que capas con muchas pantallas (`screens/`)
  pueden crecer bastante — por eso cada capa se subdivide en una carpeta
  por dominio (`screens/contenido/`, `services/chordpro/`) en vez de tirar
  todo suelto.
- **`services/sync_local/` y `firestore_service.dart` no comparten nada**
  aunque los dos se llamen "sync": uno persiste en Firestore con internet
  ocasional, el otro es transporte P2P efímero sin internet. Es la
  separación más importante de todo el proyecto (es la razón de ser de la
  app), así que sigue existiendo como subcarpeta propia aunque ya no sea
  un feature de nivel superior.
- **`Repositorio<T>` es una interfaz abstracta; `FirestoreRepository<T>`
  (en `core/firestore/`) es su única implementación** — y es la que se usa
  hoy, pero ninguna pantalla, provider ni test programa contra ella
  directamente (`app.dart` registra los providers como `Repositorio<Ritmo>`,
  no `RitmoRepository`). Es la pieza que hace que la arquitectura aguante
  cambios sin reescribir: el día que haga falta un repositorio en memoria
  para tests de widgets, o una capa de caché antes de escribir a Firestore,
  se agrega una clase nueva que implementa `Repositorio<T>` — no se toca
  ni una pantalla. Los modelos inmutables con `copyWith`
  (`cancion.copyWith(...)`, `acorde.transponer(...)`) siguen la misma idea
  a nivel de datos: nunca se edita un objeto existente, siempre se deriva
  uno nuevo.
- **`core/firestore/` en vez de repetir el boilerplate de
  `withConverter` en cada modelo**: los modelos (Ritmo, Artista, Canción,
  Miembro, Actividad, Nota) necesitan exactamente las mismas cinco
  operaciones CRUD contra Firestore. `ModelConverter` y
  `FirestoreRepository<T>` existen para que agregar un modelo nuevo sea
  "escribir el modelo + una clase de 8 líneas", no repetir 40 líneas de
  Firestore.
- **`SetlistEntry` embebido en `Actividad`, no en su propia
  subcolección**: un setlist siempre se lee/escribe completo (armarlo,
  reordenarlo), nunca una canción del setlist por separado. Embeberlo
  como array evita una lectura extra y es más simple de mantener
  consistente offline.
- **`services/chordpro/` separado de `models/chordpro/`**: el parser de
  ChordPro no sabe nada de Firestore ni de widgets — solo convierte texto
  en un árbol de secciones/acordes (definido en `models/chordpro/`) y sabe
  transportarse. Vive en `services/` para que se pueda testear con
  `flutter test` sin Firebase inicializado, y para que cualquier pantalla
  lo use como cualquier librería, sin acoplarse a cómo se persiste la
  canción.
- **Los imports internos son absolutos (`package:app_alabanzas/...`),
  no relativos (`../../../..`)** — es lo más parecido en Dart a los
  imports totalmente calificados de Java (`import com.app.model.User;`):
  el path no cambia si movés el archivo que importa, y se lee de un
  vistazo desde qué capa viene cada dependencia.

### Pendiente de ubicar (Pasos 5-6)

Dos decisiones de diseño que todavía no se implementaron, para que no se
pierdan:

- **Vista Músico / Vista Cantante** (Paso 5): son widgets que consumen
  `Cancion` ya transportada al tono del día — van en `screens/contenido/`
  aunque el estado que consuman (sección activa, tono en vivo) venga de
  `services/sync_local/`.
- **Vista Líder** (Paso 6): además de letra/acordes, tiene los controles
  para avanzar sección/canción, cambiar tono en vivo, y ver el estado de
  conexión de los demás dispositivos. Va a vivir junto al calendario de
  actividades (`screens/`, dominio "actividades" — todavía sin crear) y no
  en `sync_local`, porque su punto de partida conceptual es "elegir y
  controlar la Actividad de hoy", no el transporte P2P en sí mismo.

## Requisitos

Todo lo de esta lista **ya está instalado en esta máquina**:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.47.2,
  clonado en `C:\src\flutter`, en el PATH del usuario. `flutter doctor`
  corre limpio salvo el Android toolchain (ver abajo).
- Las carpetas nativas `android/` e `ios/` ya están generadas
  (`flutter create --platforms=android,ios --org com.appalabanzas .`).
  `com.appalabanzas` es un org genérico de placeholder — si tu iglesia
  tiene dominio propio, es un find-replace en `android/app/build.gradle.kts`,
  `ios/Runner.xcodeproj` y el `bundle_id`/`package_name` del lado de
  Firebase antes de publicar.
- [Firebase CLI](https://firebase.google.com/docs/cli) (`firebase-tools`,
  vía npm) y [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/)
  (`dart pub global activate flutterfire_cli`), ambos en el PATH.
- **Android toolchain**: NO instalado todavía. Sin esto no se puede
  compilar/correr en Android real ni emulador, pero sí se puede escribir
  código, correr `flutter analyze`, y correr la app en web
  (`flutter run -d chrome`) — Firebase/Firestore soportan Android, iOS y
  Web, pero no tienen implementación oficial para Windows desktop, así
  que `flutter run -d windows` no sirve para probar esta parte. Instalar
  después con `winget install --id Google.AndroidStudio` si hace falta.

Si abrís una terminal nueva y algún comando no se reconoce, cerrá esa
terminal y abrí una de nuevo — los cambios de PATH no llegan a terminales
ya abiertas.

## Conectar Firebase (Firestore)

> **En esta instancia ya está hecho.** Proyecto `app-alabanzas`
> (`southamerica-west1`), Firestore Standard creado, reglas publicadas,
> apps Android e iOS registradas, `lib/firebase_options.dart` generado.
> `flutter analyze` corre sin errores. Esta sección queda como guía para
> otra iglesia que clone el repo y necesite conectar su propio proyecto.

Esta parte no la puedo hacer yo: implica iniciar sesión con tu cuenta de
Google y crear un proyecto en la nube a tu nombre. Corré estos pasos vos,
**en una terminal nueva**, parado en la carpeta del proyecto.

**1. Iniciar sesión en Firebase** (abre el navegador, iniciá sesión con la
cuenta de Google que va a ser dueña del proyecto — puede ser una cuenta
del equipo, no tiene que ser personal):

```bash
firebase login
```

**2. Crear el proyecto de Firebase.** El id tiene que ser único a nivel
mundial, minúsculas, 6-30 caracteres — ajustá `app-alabanzas-tuiglesia` si
ya está tomado:

```bash
firebase projects:create app-alabanzas-tuiglesia --display-name "App Alabanzas"
```

**3. Conectar el proyecto de Firebase a este código Flutter.** Esto
genera `lib/firebase_options.dart` (gitignored, es el que faltaba) y
registra automáticamente la app Android (`com.appalabanzas.app_alabanzas`)
y la app iOS en Firebase:

```bash
flutterfire configure
```

Te va a preguntar interactivamente:
- **Select a Firebase project**: elegí el que creaste en el paso 2.
- **Which platforms should your configuration support?**: marcá `android`
  e `ios` con la barra espaciadora, `web` si también vas a probar en
  Chrome, y Enter.

**4. Habilitar Cloud Firestore.** Todavía no hay forma confiable de
hacerlo por CLI sin elegir región a mano, así que es el único paso por
consola web:

1. Andá a [console.firebase.google.com](https://console.firebase.google.com/),
   entrá al proyecto que creaste.
2. Menú lateral → **Firestore Database** → **Crear base de datos**.
3. Modo: **Producción** (no "modo de prueba" — las reglas de abajo ya
   cubren ese caso).
4. Región: la más cercana a tu iglesia — **no se puede cambiar después**
   sin recrear la base de datos.

**5. Reglas de seguridad.** El proyecto todavía no tiene Firebase Auth
implementado (`Miembro` guarda nombre/roles, pero no hay login todavía),
así que no hay forma de restringir por usuario. Estas reglas son un punto
intermedio razonable para un equipo chico y confiable: cualquiera con el
link/proyecto puede leer, pero solo puede escribir si trae un token válido
de Firebase (cosa que, sin Auth, hoy nadie tiene) — o sea, de arranque,
**nadie externo puede escribir, y el equipo tampoco todavía**. Pegalas en
Firestore Database → Reglas:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

> ⚠️ Esto es temporal. Antes de usar la app en un servicio real hay que
> agregar Firebase Auth (aunque sea anónimo, para los 5 dispositivos del
> equipo) y reglas que validen ese usuario — si no, nadie va a poder
> guardar canciones/actividades desde la app. Quedó anotado como pendiente
> del roadmap.

**6. Confirmar que quedó conectado:**

```bash
flutter pub get
flutter analyze
flutter run -d chrome
```

`flutter analyze` tiene que dar "No issues found" (ya lo probé sin
`firebase_options.dart` con un stub descartable, y el resto del código
compila limpio). Si `flutter run -d chrome` levanta la app y no tira
errores de Firebase en la consola, quedó conectado.

Después de correr `flutter create` y `flutterfire configure`, revisá
`git status`/`git diff` antes de comitear — son los dos pasos que tocan
archivos generados automáticamente y conviene mirar qué cambió.

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
pero se etiqueta distinto en la UI. Si no ponés etiqueta (`{start_of_chorus}`
a secas), usa una por defecto ("Coro", "Verso", "Puente", "Tag").

Cualquier otra directiva del archivo (`{title: ...}`, `{key: ...}`,
`{comment: ...}`, líneas que empiezan con `#`) se ignora al parsear — esos
datos ya viven en los campos propios de `Cancion` (`titulo`,
`tonoOriginal`), así que un archivo `.cho` real, tal cual lo exportó otro
programa, se puede pegar en `contenidoChordPro` sin editarlo a mano.

El parser vive en
[lib/services/chordpro/](lib/services/chordpro/)
y no depende de Firestore ni de Flutter UI — es una librería Dart pura,
así que la usan tanto la futura Vista Músico/Cantante (Paso 5) como
cualquier test. Uso típico, con el offset del día que ya trae
`SetlistEntry.tonoAsignado`:

```dart
final cancionParseada = ChordProParser.parse(cancion.contenidoChordPro);
final transportada = cancionParseada.transponer(setlistEntry.tonoAsignado);

for (final seccion in transportada.secciones) {
  print(seccion.etiqueta); // "Verso 1", "Coro", ...
  for (final linea in seccion.lineas) {
    print(linea.soloLetra);  // Vista Cantante: solo letra
    print(linea.toChordPro()); // Vista Músico: letra + acordes ya transportados
  }
}
```

La transposición es matemática (círculo de semitonos), no busca/reemplaza
texto — y respeta si el original usaba sostenidos o bemoles (`Bb` + 2
semitonos da `C`, no `B##`).

## Paso 4 — Prototipo de sincronización en vivo (Nearby Connections)

Prototipo aislado de la Capa 2, tal como lo pedía el roadmap original: dos
pantallas mínimas (líder que transmite un contador, seguidor que lo
recibe) usando `flutter_nearby_connections_plus`, **separadas del resto de
la app** — no usan Firebase, no usan Provider, no tocan `lib/main.dart`.

### ⚠️ No funciona en emulador

Nearby Connections necesita radios de Bluetooth/Wi-Fi Direct reales — la
propia documentación del paquete dice "Android doesn't support emulator,
only real devices". Lo que sí se validó en el emulador: que la app
instala, arranca, pide los permisos correctos (ubicación + "Nearby
devices") y llega a "Anunciando este celular como líder..." sin crashear.
**Falta la prueba real: conectar dos celulares Android y confirmar que un
valor viaja de uno a otro en vivo.**

### Cómo probarlo

```bash
flutter run -t lib/main_prototipo_sync_local.dart -d <id-del-celular-1>
flutter run -t lib/main_prototipo_sync_local.dart -d <id-del-celular-2>
```

En un celular tocá **"Soy el líder"**, en el otro **"Soy el seguidor"**.
Aceptá los permisos de ubicación y "Nearby devices" en ambos. En la
pantalla del seguidor debería aparecer el líder en "Dispositivos
cercanos" — tocá **"Conectar"**. Una vez conectado, el botón **"+1
(transmitir)"** del líder (o el switch de auto-incremento) tiene que
actualizar el número grande en la pantalla del seguidor, sin internet.

### Dos problemas reales que aparecieron al compilar (y cómo se resolvieron)

El paquete publicado en pub.dev no compilaba tal cual contra las
herramientas actuales — nada de esto es específico de esta app, cualquiera
que lo use hoy se choca con lo mismo:

1. **`android/build.gradle` usaba `jcenter()`**, el repositorio que Google
   cerró en 2022, y un Android Gradle Plugin de 2019 declarado en un
   `buildscript` propio que pisa la versión que ya resuelve el proyecto
   raíz. Sin arreglo: `Could not find method jcenter()`.
2. **El código Kotlin usaba `PluginRegistry.Registrar`**, la API de
   registro de plugins de Flutter *v1 embedding* (pre-2019), eliminada del
   engine hace años. Sin arreglo: `Unresolved reference 'Registrar'`. Era
   código muerto de todos modos — el plugin ya se registra por la vía
   moderna (`FlutterPlugin`/`ActivityAware`), así que se borró sin perder
   funcionalidad.

**La solución**: [packages/flutter_nearby_connections_plus/](packages/flutter_nearby_connections_plus/)
es una copia local del paquete (`dependency_overrides` en `pubspec.yaml`
apunta ahí) con *solo* esos dos archivos parcheados — el resto del
paquete (Dart, la lógica Kotlin real) queda intacta. Se puede sacar el
override el día que el paquete original se actualice en pub.dev; mientras
tanto, `analysis_options.yaml` excluye `packages/**` porque no es código
nuestro.

Advertencia pendiente (no bloquea el build, pero Flutter avisa que en el
futuro sí lo hará): el plugin aplica su propio Kotlin Gradle Plugin en vez
de usar el "Built-in Kotlin" que Flutter recomienda desde hace poco. Si en
algún momento deja de compilar por esto, es la próxima pieza a parchear en
el mismo `build.gradle`.

### Permisos

Android exige, además de declararlos en el manifest (ya está en
`android/app/src/main/AndroidManifest.xml` y en el propio manifest del
plugin), pedirlos en tiempo de ejecución — eso lo hace
[permisos_sync_local.dart](lib/services/sync_local/permisos_sync_local.dart)
antes de iniciar el servicio: ubicación (`locationWhenInUse`) y los tres
permisos granulares de Bluetooth de Android 12+ (`bluetoothScan`,
`bluetoothAdvertise`, `bluetoothConnect`). En iOS, `Info.plist` ya declara
`NSBonjourServices`, `NSLocalNetworkUsageDescription` y
`NSBluetoothAlwaysUsageDescription` — falta probarlo en un iPhone real
(necesita Mac + Xcode, ver sección Despliegue).

## Licencia

[MIT](LICENSE) — se eligió sobre GPLv3 porque no restringe cómo cada
iglesia distribuye su fork (algunas comunidades prefieren no publicar sus
cambios), y facilita que el proyecto se use como base de apps privadas sin
fricción legal. Si tu comunidad prefiere GPLv3 (para forzar que las
mejoras vuelvan siempre como código abierto), es un cambio de un solo
archivo — avisá y lo actualizamos.
