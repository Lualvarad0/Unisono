# 🗄️ Guía de datos y backend

Unísono no tiene una API HTTP propia: el cliente Flutter habla directo
con Firebase (Firestore, Auth, Storage, Cloud Messaging) a través de los
SDKs oficiales. La única pieza de backend propia son las **Cloud
Functions** de `functions/`, y esas son *triggers* — código que corre
solo cuando algo cambia en Firestore, no endpoints que se llaman a mano.

Esta guía documenta esa superficie: el modelo de datos en Firestore, cómo
el código Dart lo accede, y qué hace cada Cloud Function.

## Multi-tenancy: equipos

Cada grupo de alabanza es un **equipo** aislado. Todo el contenido vive
adentro de `equipos/{equipoId}/...` como subcolecciones — nunca suelto a
nivel raíz — así una cuenta nueva no puede ver ni tocar el contenido de
un equipo del que no es parte.

```
equipos/{equipoId}                      → documento Equipo (nombre, código, creadoPorUid)
equipos/{equipoId}/ritmos/{id}          → Ritmo
equipos/{equipoId}/artistas/{id}        → Artista
equipos/{equipoId}/canciones/{id}       → Cancion
equipos/{equipoId}/actividades/{id}     → Actividad (setlist embebido)
equipos/{equipoId}/notas/{id}           → Nota
equipos/{equipoId}/ejercicios/{id}      → Ejercicio
equipos/{equipoId}/miembros/{miembroId} → Miembro

usuarioEquipo/{uid}                     → { equipoId, miembroId }
rateLimitsAvisos/{clave}                → interno, Cloud Functions (ver abajo)
recordatoriosEnviados/{equipoId_actividadId} → interno, Cloud Functions
```

`usuarioEquipo/{uid}` es la pieza que hace posible resolver "a qué equipo
pertenece quien pide esto" con una lectura puntual (`get`), indexada por
el `uid` de Firebase Auth — las reglas de seguridad de Firestore no
soportan queries, así que sin esta colección no habría forma de que
`firestore.rules` supiera a qué equipo pertenece alguien. Se escribe una
sola vez, al crear o unirse a un equipo (`ElegirEquipoScreen`), y nunca
se reasigna.

Para unirse, alguien nuevo usa el código de 6 caracteres del equipo (sin
`O`/`0`/`I`/`1`/`L`, para que no se confundan al dictarlo por voz o
WhatsApp) — ver `EquipoRepository.generarCodigoUnico`.

## 🗂️ Modelo de datos

| Colección | Campos | Notas |
|---|---|---|
| `equipos/{id}` | `nombre`, `codigo`, `creadoPorUid`, `creadoEn` | Raíz, no dentro de un equipo — es la que los define. |
| `usuarioEquipo/{uid}` | `equipoId`, `miembroId` | Indexado por uid, no autogenerado. |
| `ritmos/{id}` | `nombre` | Género/ritmo musical — nivel más alto de clasificación. |
| `artistas/{id}` | `nombre` | Opcional en `Cancion`; sin artista se muestra "Varios". |
| `canciones/{id}` | `titulo`, `ritmoId?`, `artistaId?`, `tonoOriginal`, `contenidoChordPro`, `bpm?`, `compas?`, `etiquetas[]`, `creadaEn?` | `contenidoChordPro` es el texto completo en formato ChordPro — ver [el parser](#chordpro). |
| `actividades/{id}` | `nombre`, `fecha`, `setlist[]`, `cancionActivaId?`, `seccionActivaIndice` | `setlist` es un array de `SetlistEntry` **embebido** (no subcolección — ver abajo). `cancionActivaId` es lo que lee Vista en vivo para saber qué mostrar. |
| `notas/{id}` | `texto`, `compartida`, `autorUid`, `cancionId?`, `seccionEtiqueta?` | `compartida=false` → solo la ve quien la escribió. |
| `ejercicios/{id}` | `titulo`, `descripcion`, `autorUid`, `cancionId?`, `seccionEtiqueta?`, `completadoPorUids[]` | Cada integrante se agrega a `completadoPorUids` por su cuenta. |
| `miembros/{id}` | `nombre`, `apellido`, `roles[]`, `uid?`, `fechaNacimiento?`, `telefono?`, `instrumento?`, `nivelInstrumento?`, `fotoUrl?`, `fcmToken?` | `uid=null` = perfil invitado sin reclamar (ver [Seguridad](SEGURIDAD.md)). `roles` es una lista de `lider`/`musico`/`cantante` — alguien puede tener varios. |

`SetlistEntry` (`cancionId`, `orden`, `cantanteId`, `tonoAsignado`) no es
un documento propio: vive embebido en `Actividad.setlist` porque siempre
se lee y se escribe como una unidad completa (armar o reordenar el
setlist), así que una subcolección aparte no suma nada y además no se
puede leer de un tirón offline.

## Capa de acceso a datos (Dart)

Todas las pantallas y providers programan contra la interfaz
`Repositorio<T>` ([`lib/core/firestore/repositorio.dart`](../lib/core/firestore/repositorio.dart)),
nunca contra Firestore directo:

```dart
abstract class Repositorio<T> {
  Stream<List<T>> watchAll();
  Future<List<T>> fetchAll();
  Future<T?> fetchById(String id);
  Future<String> crear(T item, {String? id});
  Future<void> actualizar(String id, T item);
  Future<void> eliminar(String id);
}
```

`FirestoreRepository<T>` ([`firestore_repository.dart`](../lib/core/firestore/firestore_repository.dart))
es la única implementación real, y le basta con recibir el
`CollectionReference<T>` ya tipado — Ritmo, Artista, Canción, Actividad,
Nota, Ejercicio y Miembro la extienden sin repetir las cinco operaciones.
`watchAll()` es la forma "normal" de leer para pantallas reactivas:
Firestore ya trae caché offline persistente, así que ese stream emite
primero desde el disco del celular si no hay red, sin que la UI tenga
que distinguir online de offline.

Las subcolecciones de un equipo se arman con
[`coleccionDeEquipo(equipoId, nombre)`](../lib/core/firestore/equipo_collections.dart),
que construye la referencia `equipos/{equipoId}/{nombre}`. Los 7
repositorios de contenido reciben `equipoId` en el constructor y se
instancian recién en `ResolverEquipoScreen` (una vez resuelto a qué
equipo pertenece la cuenta) — antes de eso, al arrancar la app, solo
existen los providers a nivel de cuenta (`AutenticacionService`,
`EquipoRepository`, `UsuarioEquipoRepository`, ver `app.dart`).

### 🧩 Agregar un modelo nuevo

> [!TIP]
> Mismos cuatro pasos para cualquier colección nueva de contenido.

1. Clase en `models/`, con `fromMap`/`toMap` y un `ModelConverter`
   estático (ver `model_converter.dart`) — copiá cualquiera de los
   modelos existentes como plantilla.
2. Repositorio en `repositories/` que extienda `FirestoreRepository<T>`,
   pasando `coleccionDeEquipo(equipoId, 'nombreDeLaColeccion')
   .withConverter(...)`.
3. Agregar el bloque correspondiente a `firestore.rules` (ver
   [Seguridad](SEGURIDAD.md)) — nunca un comodín genérico.
4. Registrar el provider en `ResolverEquipoScreen` (`_ProveedoresDeEquipo`),
   como tipo concreto y como `Repositorio<T>`.

## Cloud Functions

Código en [`functions/index.js`](../functions/index.js), Node 24,
desplegadas con `firebase deploy --only functions`. Las cuatro son
*triggers* sobre escrituras de Firestore o un *scheduler* — nada se
llama por HTTP.

| Función | Dispara con | Qué hace |
|---|---|---|
| `onModoEnVivoIniciado` | `onDocumentUpdated` en `equipos/{equipoId}/actividades/{actividadId}` | `cancionActivaId` pasa de vacío a tener valor → avisa a todo el equipo que arrancó la transmisión. |
| `onSetlistEscrito` | `onDocumentWritten` en la misma ruta | Setlist nuevo o cambiado → avisa a todo el equipo. Si solo cambió el cantante asignado a una entrada existente, avisa solo a esa persona. |
| `onMiembroSeUnioAlEquipo` | `onDocumentUpdated` en `equipos/{equipoId}/miembros/{miembroId}` | `uid` pasa de `null` a tener valor (alguien reclamó el perfil) → avisa al resto del equipo. |
| `recordatorioAntesDelServicio` | `onSchedule`, cada 15 minutos | `collectionGroup('actividades')` busca en todos los equipos las que empiezan dentro de la próxima hora, y avisa una sola vez por actividad (`recordatoriosEnviados`). |

Todas mandan el push a través de `tokensDelEquipo(equipoId)`, que lee
`fcmToken` de cada `Miembro` de ese equipo puntual — nunca cruza equipos.

**Rate limit**: como cualquier integrante autenticado puede escribir en
`actividades` (lo necesita el líder para armar un setlist), nada impide
que una escritura repetida dispare el mismo aviso varias veces seguidas.
`dentroDelLimite(clave)` usa una transacción de Firestore
(`rateLimitsAvisos/{clave}`) para que un mismo aviso no se repita dentro
de una ventana de 2 minutos, sin importar cuántas escrituras lo disparen.

## 🔑 Autenticación

`AutenticacionService` ([`lib/services/autenticacion_service.dart`](../lib/services/autenticacion_service.dart))
envuelve Firebase Auth (correo + contraseña): `iniciarSesion`,
`crearCuenta`, `recuperarContrasena`, `cerrarSesion`, y traduce cada
`FirebaseAuthException.code` a un mensaje en español. A diferencia del
contenido (que funciona offline gracias a la caché de Firestore),
iniciar o crear sesión necesita conexión la primera vez.

`SplashScreen` escucha `estadoDeSesion` (`authStateChanges()`) para
decidir a dónde mandar a cada quien: sin sesión → `LoginScreen`; con
sesión → `ResolverEquipoScreen`, que busca `usuarioEquipo/{uid}` y
muestra `ElegirEquipoScreen` si todavía no existe.

## 🔔 Notificaciones push

`NotificacionesService` ([`lib/services/notificaciones_service.dart`](../lib/services/notificaciones_service.dart))
hace solo la parte del celular — quien manda los avisos de verdad son
las Cloud Functions de arriba:

1. Pide permiso (`FirebaseMessaging.requestPermission`, obligatorio en
   tiempo de ejecución desde Android 13).
2. Guarda el token FCM de este dispositivo en `Miembro.fcmToken` — las
   Cloud Functions lo leen de ahí. Un solo token por `Miembro` a
   propósito: el push va al último dispositivo donde esa persona inició
   sesión, no a todos los que usó alguna vez.
3. Con la app abierta, FCM no muestra nada solo (a diferencia de segundo
   plano o cerrada) — se muestra a mano con `flutter_local_notifications`
   para que se vea igual en los tres casos.

## ChordPro

El repertorio se guarda como texto en formato
[ChordPro](https://www.chordpro.org/chordpro/chordpro-file-format-specification/)
(`Cancion.contenidoChordPro`). El parser vive en
[`lib/services/chordpro/`](../lib/services/chordpro/) y es una librería
Dart pura — no depende de Firestore ni de Flutter UI, así que se testea
con `flutter test` sin Firebase inicializado.

```dart
final cancionParseada = ChordProParser.parse(cancion.contenidoChordPro);
final transportada = cancionParseada.transponer(setlistEntry.tonoAsignado);

for (final seccion in transportada.secciones) {
  print(seccion.etiqueta);       // "Verso 1", "Coro"...
  for (final linea in seccion.lineas) {
    print(linea.soloLetra);      // Vista Cantante
    print(linea.toChordPro());   // Vista Músico: letra + acordes transportados
  }
}
```

La transposición es matemática (círculo de semitonos), no busca/reemplaza
texto, y respeta si el original usaba sostenidos o bemoles.
`services/chordpro/editor_simple.dart` hace la conversión inversa (letra
+ fila de acordes posicionados por caracter ↔ ChordPro) para el editor
de `EditorSimpleScreen`.
