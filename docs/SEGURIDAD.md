# 🔐 Guía de seguridad

Qué protege la app, cómo, y qué queda explícitamente afuera por ahora.
Ver también [API.md](API.md) para el modelo de datos completo.

| Capa | Qué la protege |
|---|---|
| Cuentas | Firebase Auth + contraseña fuerte + sin enumeración de usuarios |
| Entre equipos | `usuarioEquipo/{uid}` + `equipoDeUsuario()` en `firestore.rules` |
| Código de equipo | Cloud Function `buscarEquipoPorCodigo` (nunca una query directa del cliente) |
| Fotos de perfil / reportes | `storage.rules`, con límite de tamaño y tipo de archivo |
| Avisos push | Rate limit de 2 min por Cloud Function |
| Búsqueda de código | Rate limit de 20 intentos / 5 min por cuenta |
| Config/claves | Nunca comiteadas — reconstruidas en CI desde Secrets |

## 🔑 Autenticación

Firebase Auth, correo + contraseña. Dos reglas del lado del cliente que
no impone Firebase por sí solo (`lib/screens/acceso/crear_cuenta_screen.dart`):

- **Contraseña fuerte**: 8+ caracteres, con mayúscula, minúscula y
  número; rechaza una que sea solo espacios o que empiece/termine con
  uno. Firebase Auth por sí solo solo exige 6+ caracteres de cualquier
  tipo.
- **Confirmación**: el campo "Confirmar contraseña" tiene que coincidir
  con el primero antes de poder enviar el formulario.

**Sin enumeración de usuarios**: `recuperarContrasena()` en
`autenticacion_service.dart` responde igual exista o no una cuenta con
ese correo — si Firebase devuelve `user-not-found`, se traga el error en
vez de mostrarlo. Sin esto, cualquiera podía usar el formulario de
"Olvidé mi contraseña" para probar una lista de correos y descubrir
cuáles tienen cuenta en la app, sin necesitar la contraseña de nadie.

No hay verificación de correo electrónico todavía (cualquier dirección
sintácticamente válida sirve para crear cuenta) ni Firebase App Check.
Quedan como mejoras futuras, no bloqueantes para el uso actual (equipos
chicos y de confianza).

## 🕵️ Auditoría 2026-10-17

Revisión estricta a pedido del dueño del proyecto: reglas línea por
línea asumiendo mala intención, más ingeniería inversa del APK de
release real (`unzip` + búsqueda de secretos en el binario +
`aapt dump badging/xmltree` sobre el manifest). Hallazgo central y tres
menores, todos ya corregidos.

> [!CAUTION]
> **Crítico, ya corregido** — cadena de 3 reglas que, combinadas, dejaban
> que **cualquier cuenta autenticada tomara lectura/escritura total de
> cualquier equipo del sistema, sin necesitar su código**:
> 1. `equipos` dejaba `list` (consultar la colección entera) a cualquier
>    autenticado — alcanzaba con `db.collection('equipos').get()` para
>    obtener el nombre y el código de **todos** los equipos de un saque.
> 2. `miembros.create` dejaba que cualquiera se auto-creara un perfil
>    (`uid: suPropioUid`) en **cualquier** `equipoId`, no solo uno
>    propio.
> 3. `usuarioEquipo.create` no cruzaba nada contra el `Miembro` real:
>    confiaba en el `equipoId`/`miembroId` que mandara el cliente.
>
> Con las tres juntas, alguien con una cuenta descartable podía: listar
> un equipo ajeno (1), crearse un perfil ahí (2), y vincularse a ese
> equipo (3) — sin haber visto el código de 6 caracteres en ningún
> momento. De paso, **el flujo real de unirse con código estaba roto**:
> la regla de `miembros.update` exigía ya pertenecer al equipo incluso
> para el primer paso (reclamar el perfil invitado), que es justo lo
> que te hace pertenecer — un usuario legítimo se encontraba con un
> error de permisos al intentar unirse.

**La corrección** (`firestore.rules` + `functions/index.js` +
`lib/repositories/equipo_repository.dart`):

- La búsqueda por código ya no es una query del cliente — es la Cloud
  Function callable `buscarEquipoPorCodigo` (Admin SDK, nunca expone la
  colección entera, con un límite de 20 intentos cada 5 minutos por
  cuenta). `equipos` pasa a `allow get` sí / `allow list: if false`.
- Con `list` cerrado, un `equipoId` (un ID autogenerado de 20
  caracteres) vale como secreto por sí solo — ya no hace falta
  restringir más el auto-create de `miembros` de lo que ya estaba.
- `usuarioEquipo.create` ahora cruza contra el `Miembro` real:
  ```
  allow create: if request.auth != null && request.auth.uid == uid &&
    get(/databases/$(database)/documents/equipos/$(request.resource.data.equipoId)/miembros/$(request.resource.data.miembroId)).data.uid == request.auth.uid;
  ```
  Solo podés vincularte a un `(equipoId, miembroId)` si ese `Miembro`
  **ya** tiene tu uid — algo que solo pasa a través de los caminos
  legítimos (reclamar un perfil invitado, o auto-crear el tuyo).
- `miembros.update` separa "editar un perfil que ya es tuyo" (exige
  pertenecer) de "reclamar un perfil invitado sin dueño" (no exige
  pertenecer todavía — arregla el bug real de arriba):
  ```
  allow update: if request.auth != null && (
    (equipoDeUsuario() == equipoId && request.resource.data.uid == resource.data.uid) ||
    (resource.data.uid == null && request.resource.data.uid == request.auth.uid)
  );
  ```
- `miembros.read` ahora también deja ver perfiles sin reclamar
  (`uid == null`) a cualquier autenticado — es la lista de nombres para
  elegir al unirse, que pasa *antes* de pertenecer. Solo funciona si la
  query del cliente ya viene filtrada por `uid == null`
  (`MiembroRepository.fetchSinReclamar`): Firestore rechaza cualquier
  lectura que pudiera devolver un perfil ajeno ya reclamado.

**Hallazgos menores, también corregidos:**

- `usuarioEquipo` dejaba leer el `{equipoId, miembroId}` de **cualquier**
  uid a cualquier autenticado (filtraba a qué equipo pertenece cada
  persona del sistema) — ahora es `allow read` solo de la propia.
- `storage.rules` no validaba tamaño ni tipo de archivo al subir una
  foto de perfil — ahora exige `< 5 MB` y `image/*`.
- `android:allowBackup` quedaba en el default de la plataforma (`true`)
  — se fija explícitamente en `false` en el manifest.

**Ingeniería inversa del APK — nada que corregir, documentado para que
quede constancia:**

- La `apiKey` de Firebase se extrae en segundos (`grep` sobre
  `libapp.so`, el snapshot AOT de Dart). **Esto es esperado, no una
  falla**: Google documenta explícitamente que la `apiKey` de un
  proyecto Firebase no es secreta — identifica el proyecto, no
  autoriza nada por sí sola. La seguridad real son las reglas de
  arriba, no ocultar esta clave.
- Sin claves privadas, contraseñas de keystore, ni tokens de cuenta de
  servicio en el binario.
- Build sin `debuggable`, sin tráfico HTTP sin cifrar permitido.
- Build sin `--obfuscate` — los nombres de clases/métodos Dart se
  pueden recuperar con un decompilador. No es una falla de seguridad en
  sí (la app no tiene ningún algoritmo propietario que ocultar, y el
  control de acceso real vive del lado del servidor), pero es barato
  de endurecer para el próximo release real:
  `flutter build apk --release --obfuscate --split-debug-info=<carpeta>`.

## 🏘️ Aislamiento entre equipos (multi-tenancy)

Cada equipo de alabanza es un compartimento separado — ver
[API.md § Multi-tenancy](API.md#multi-tenancy-equipos) para el modelo de
datos. La garantía de seguridad real vive en `firestore.rules`, función
`equipoDeUsuario()`:

```
function equipoDeUsuario() {
  return get(/databases/$(database)/documents/usuarioEquipo/$(request.auth.uid)).data.equipoId;
}
```

Cada subcolección de contenido (`ritmos`, `artistas`, `canciones`,
`actividades`, `notas`, `ejercicios`) exige
`equipoDeUsuario() == equipoId` del documento que se está leyendo o
escribiendo — así que estar logueado no alcanza para ver el contenido de
otro equipo, hace falta además pertenecer a ese equipo puntual.

### La lección de las reglas OR (importante, ya nos pasó dos veces)

> [!IMPORTANT]
> **Firestore combina las reglas con OR entre todos los bloques `match`
> que apliquen a una misma ruta** — un bloque específico y restrictivo
> NO puede ganarle a uno genérico y permisivo que también matchee esa
> ruta.

Ejemplo real de este proyecto que no funcionó como parecía:

```
// ❌ Esto NO protege nada — el wildcard genérico ya permite cualquier
// escritura de cualquier logueado, sin importar qué tan restrictivo sea
// el bloque de /miembros de al lado.
match /{document=**} {
  allow write: if request.auth != null;
}
match /miembros/{id} {
  allow write: if /* condición mucho más estricta */;
}
```

La solución, aplicada en ambas rondas (las reglas planas originales y
después el refactor a equipos): **nunca un comodín genérico** — cada
colección tiene su propio bloque `match` explícito, sin nada más amplio
que la cubra desde afuera.

### `miembros`: por qué tiene su propia regla

Reclamar o crear un perfil de `Miembro` pasa **antes** de que exista
`usuarioEquipo/{uid}` (es parte del mismo paso de unirse/crear equipo),
así que `equipoDeUsuario()` todavía no resuelve nada en ese momento —
`create` y `update` necesitan un segundo camino para ese caso puntual,
sin dejar de proteger el resto. El campo `uid` de un perfil ya reclamado
tampoco se puede pisar con otro — solo se fija una vez.

Ver [Auditoría 2026-10-17](#auditoría-2026-10-17) arriba para las
reglas tal como quedaron hoy (las originales de este diseño tenían una
falla real, ya corregida).

## 🖼️ Storage (fotos de perfil)

`storage.rules`: un archivo por persona
(`perfiles/{uid}/foto.jpg`) — cualquiera logueado puede verlas, pero solo
el dueño de esa cuenta puede subir o reemplazar la suya
(`request.auth.uid == uid`).

## 📮 Reportes de falla desde la landing (sin login)

`landing/src/sections/ReportarFalla.tsx` escribe directo a Firestore
(`reportesDeFalla`) y Storage (`reportes/{id}/...`) **sin pasar por
Firebase Auth** — la landing no tiene ningún concepto de cuenta, así que
el control de acceso acá es distinto al resto de la app:

- **Un solo sentido**: `reportesDeFalla` es `allow create` para
  cualquiera, `allow read, update, delete: if false` para todos — ni
  siquiera quien mandó el reporte lo puede releer. Se revisan desde la
  consola de Firebase (acceso de Admin, fuera de las reglas del
  cliente).
- **Campos validados en la regla, no solo en el formulario**:
  `mensaje` tiene que ser texto no vacío de hasta 2000 caracteres,
  `imagenUrl` (si está) hasta 500, `hasOnly(...)` rechaza cualquier
  campo de más, y `creadoEn == request.time` fuerza que la fecha la
  ponga el servidor — nada de esto se puede falsificar mandando un
  payload distinto al que arma el formulario.
- **La imagen** (`storage.rules`, ruta `reportes/{id}/...`) exige
  `< 5 MB` y `image/*`, sin lectura pública — cada reporte sube a su
  propio id (el mismo que el documento de Firestore, generado del lado
  del cliente antes de escribir ninguno de los dos), así que no hay
  forma de pisar ni listar lo que subió otra persona.
- **Lo que queda afuera a propósito**: sin reCAPTCHA/App Check, sin
  límite de cuántos reportes puede mandar la misma persona. Es un buzón
  público por diseño (cualquiera, sin cuenta, tiene que poder avisar una
  falla) — el límite de tamaño de archivo y el límite de 2000
  caracteres acotan el costo de un posible abuso, pero no lo eliminan
  del todo. Si en algún momento se vuelve un problema real (spam),
  Firebase App Check es el siguiente paso natural.

## ⏱️ Rate limiting (Cloud Functions)

Cualquier integrante autenticado puede escribir en `actividades` (lo
necesita el líder para armar un setlist), así que nada impide que una
escritura repetida dispare el mismo aviso push varias veces seguidas —
sea sin querer o a propósito. `dentroDelLimite()` en `functions/index.js`
usa una transacción de Firestore para que un mismo aviso (misma
`equipoId_tipo_actividadId`) no se repita dentro de una ventana de 2
minutos, sin importar cuántas escrituras lo disparen. Ver
[API.md § Cloud Functions](API.md#cloud-functions).

## 🗝️ Manejo de secretos

Ningún archivo de configuración de Firebase ni ninguna clave se comitea:

| Archivo | Por qué está afuera |
|---|---|
| `lib/firebase_options.dart`, `android/app/google-services.json` | Específicos del proyecto Firebase de cada iglesia — se reconstruyen en CI desde GitHub Secrets (`FIREBASE_OPTIONS_PARA_SECRET`, `GOOGLE_SERVICES_JSON`). |
| `android/key.properties`, `android/app/*.jks` | Keystore de firma de release. Reconstruido en CI desde `ANDROID_KEYSTORE_BASE64` (el `.jks` en base64), `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`. El `.jks` real solo existe en la máquina donde se generó y en los Secrets del repo — si se pierde, no hay forma de publicar una actualización que reemplace una instalación existente (Android exige la misma firma). |
| `firebase.json`, `.firebaserc` | Locales a cada clon — no hace falta compartirlos, cada quien apunta a su propio proyecto de Firebase. |

El APK **debug** (`build-debug-apk.yml`) se firma con una clave efímera
distinta en cada corrida de CI — sirve para probar, no para publicar: una
instalación nueva no puede actualizar a otra con una firma distinta. El
APK **release** (`release-apk.yml`) usa el keystore real de arriba,
así que las versiones sí se actualizan unas sobre otras.

## 🚧 Afuera de alcance

- **`Ejercicio.completadoPorUids`**: cualquier integrante del equipo
  puede marcar el ejercicio de otro como hecho/no hecho (no solo el
  propio). Riesgo bajo (molestia interna, no fuga de datos) — no
  bloqueante.
- Sin Firebase App Check (protege contra tráfico que no viene de la app
  real, no contra usuarios de la app).
- Sin verificación de correo electrónico al crear cuenta.
- Sin límite de intentos de login más allá del que ya impone Firebase
  Auth (`too-many-requests`).

## 📣 Reportar un problema de seguridad

> [!CAUTION]
> Si encontrás una falla de seguridad, abrí un issue en el repositorio
> describiéndolo — para algo sensible, contactá directo a quien
> mantiene el proyecto en vez de publicar los detalles de explotación
> en un issue público.
