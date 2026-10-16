# 🔐 Guía de seguridad

Qué protege la app, cómo, y qué queda explícitamente afuera por ahora.
Ver también [API.md](API.md) para el modelo de datos completo.

| Capa | Qué la protege |
|---|---|
| Cuentas | Firebase Auth + contraseña fuerte + sin enumeración de usuarios |
| Entre equipos | `usuarioEquipo/{uid}` + `equipoDeUsuario()` en `firestore.rules` |
| Fotos de perfil | `storage.rules`, un archivo por uid |
| Avisos push | Rate limit de 2 min por Cloud Function |
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
así que `equipoDeUsuario()` todavía no resuelve nada en ese momento — por
eso `create` acepta además la condición
`request.resource.data.uid == request.auth.uid` (alguien reclamando su
propio perfil sin pertenecer todavía al equipo). El resto de las
operaciones sí exige pertenencia como siempre.

**Protección contra robo de identidad**: el campo `uid` de un perfil ya
reclamado no se puede pisar con otro uid — solo se puede fijar una vez.
Sin esto, cualquier cuenta nueva podía pisarle el `uid` a un integrante
ya existente (incluido el líder) y robarle la identidad dentro del
equipo.

```
allow update: if request.auth != null && equipoDeUsuario() == equipoId && (
  request.resource.data.uid == resource.data.uid ||
  (resource.data.uid == null && request.resource.data.uid == request.auth.uid)
);
```

## 🖼️ Storage (fotos de perfil)

`storage.rules`: un archivo por persona
(`perfiles/{uid}/foto.jpg`) — cualquiera logueado puede verlas, pero solo
el dueño de esa cuenta puede subir o reemplazar la suya
(`request.auth.uid == uid`).

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
