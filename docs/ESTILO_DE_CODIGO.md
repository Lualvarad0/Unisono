# 🎨 Guía de estilo de código

Convenciones ya en uso en todo el proyecto — esta guía las documenta
para que el código nuevo se sienta igual al existente, no introduce
reglas nuevas.

## 🗣️ Idioma

**Todo el código de dominio está en español**: nombres de clases,
métodos, variables, archivos, mensajes de commit. `camelCase`/`PascalCase`
normal, solo que con palabras en español (`cancionActivaId`,
`generarCodigoUnico`, `RolMiembro`). El inglés queda para lo que viene
del SDK/framework (`build`, `State`, `child`, nombres de paquetes de
pub.dev) — no se traduce la API de Flutter, se traduce el dominio propio
de la app.

```dart
// Así
class CancionRepository extends FirestoreRepository<Cancion> { ... }
Future<void> marcarCompletado(String id, String uid) { ... }

// No así
class SongRepository extends FirestoreRepository<Song> { ... }
Future<void> markCompleted(String id, String uid) { ... }
```

## 💬 Comentarios: por qué, no qué

Por defecto, sin comentarios — los nombres ya dicen qué hace el código.
Un comentario se agrega solo cuando explica algo que el código por sí
solo no puede: una restricción oculta, un trade-off, por qué se descartó
la alternativa obvia, una lección aprendida de un bug real. Si al sacar
el comentario el código sigue siendo igual de claro, el comentario no
debería estar.

```dart
// Así — explica una restricción no obvia (Firestore combina reglas con
// OR, no se puede restringir con un bloque específico sobre uno genérico)
// y por qué importa acá.
match /miembros/{miembroId} {
  allow create: if request.auth != null && (
    equipoDeUsuario() == equipoId ||
    request.resource.data.uid == request.auth.uid
  );
}

// No así — el nombre del método ya dice qué hace, esto no agrega nada.
// Busca un miembro por su uid.
Future<Miembro?> buscarPorUid(String uid) { ... }
```

Varios doc-comments del proyecto son deliberadamente largos cuando
documentan una decisión de arquitectura no evidente (ver
`core/firestore/repositorio.dart`, `equipo_collections.dart`) — eso no
contradice la regla de arriba, porque esas no son explicaciones de "qué
hace esta línea" sino de "por qué existe esta pieza en vez de la
alternativa más directa".

## 📦 Modelos: inmutables, con `copyWith`

Ningún modelo (`models/`) se edita in-place — todos son `Equatable`,
todos los campos son `final`, y el único modo de "cambiar" uno es derivar
una copia nueva con `copyWith`. `Acorde.transponer()` sigue la misma idea
a otro nivel: devuelve un `Acorde` nuevo, no modifica el original.

```dart
final actualizada = cancion.copyWith(titulo: nuevoTitulo);
await repositorio.actualizar(cancion.id, actualizada);
```

Cada modelo trae `fromMap`/`toMap` + un `ModelConverter` estático (ver
`core/firestore/model_converter.dart`) para hablar con Firestore sin
repetir boilerplate de `withConverter` en cada repositorio.

## 🔌 Capa de datos: programar contra la interfaz, no la implementación

Pantallas, providers y tests dependen de `Repositorio<T>`
(`core/firestore/repositorio.dart`), nunca de `FirestoreRepository<T>`
directamente — `app.dart`/`ResolverEquipoScreen` registran los providers
como `Repositorio<Cancion>`, no como `CancionRepository`. El día que haga
falta otra implementación (un repositorio en memoria para tests de
widgets, una capa de caché), se agrega al lado sin tocar una sola
pantalla. Ver [API.md](API.md#capa-de-acceso-a-datos-dart) para el
contrato completo.

## 🏗️ Estructura: layer-first, con subcarpeta por dominio cuando hace falta

`lib/` se organiza por capa técnica (`models/`, `repositories/`,
`services/`, `screens/`, `widgets/`), no por feature — el equivalente
Dart a un backend organizado en `model/service/repository/controller`.
Dentro de una capa, los archivos se agrupan en una subcarpeta por dominio
(`screens/contenido/`, `services/chordpro/`, `screens/acceso/`) solo
cuando hay más de un archivo relacionado, para que una capa con muchas
pantallas siga siendo navegable sin mezclar dominios distintos.

Nombres de archivo por sufijo según qué son: `_screen.dart` (pantallas),
`_service.dart` (lógica de negocio sin widgets), `_repository.dart`
(acceso a datos), y los widgets reutilizables van sueltos en `widgets/`
sin sufijo (son sustantivos: `visor_foto.dart`, `chip_genero.dart`).

## 📥 Imports: absolutos, no relativos

```dart
// Así
import 'package:app_alabanzas/models/cancion.dart';

// No así
import '../../../models/cancion.dart';
```

El path no cambia si se mueve el archivo que importa, y se lee de un
vistazo de qué capa viene cada dependencia.

## ⚠️ Manejo de errores de cara al usuario

Los servicios que hablan con algo externo (`AutenticacionService`)
atrapan la excepción específica del SDK y la relanzan como una excepción
propia con un `.mensaje` ya en español, listo para mostrar:

```dart
class AutenticacionExcepcion implements Exception {
  const AutenticacionExcepcion(this.mensaje);
  final String mensaje;
}
```

La pantalla nunca muestra un código de error técnico (`invalid-credential`)
directo en una alerta — siempre pasa por esta traducción.

## 📋 Formularios: nunca fallar en silencio

Todo formulario con campos obligatorios tiene que avisar
específicamente qué falta si el usuario intenta guardar sin completarlo
— nunca un `return` silencioso que no hace nada visible. Patrón estándar
en todas las pantallas de "Agregar"/"Editar":

```dart
Future<void> _guardar() async {
  if (_nombreController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Falta el nombre de la actividad.')),
    );
    return;
  }
  // ...
}
```

## ✅ Linting

`analysis_options.yaml` extiende `package:flutter_lints/flutter.yaml` más
`prefer_single_quotes`, `sort_child_properties_last`,
`always_declare_return_types`.

> [!IMPORTANT]
> `flutter analyze` tiene que dar **"No issues found"** antes de
> cualquier commit — no hay excepciones documentadas para saltarse
> esto.

`packages/flutter_nearby_connections_plus/` (copia local parcheada de un
paquete de terceros, ver [README](../README.md#sincronización-en-vivo-p2p-prototipo))
está excluido del análisis — no es código propio, no tiene sentido
aplicarle las reglas de lint del proyecto.

## 🧪 Tests

`flutter test` antes de cualquier commit, igual que `flutter analyze`.
La lógica pura sin Flutter/Firebase (`services/chordpro/`) tiene
cobertura de unit tests directa (`test/chordpro/`); el resto del proyecto
no tiene tests de widgets más allá del smoke test de arranque
(`test/widget_test.dart`) — una pantalla nueva no necesita tests de
widget para encajar con el resto, pero lógica nueva que no dependa de
Flutter/Firebase (parsers, validadores, transformaciones) sí debería
testearse igual que `chordpro/`.

## 📝 Mensajes de commit

En español, en imperativo/descriptivo corto en el asunto, con el cuerpo
explicando el **por qué** del cambio (qué problema resolvía, qué se
probó y descartó) más que el qué — el diff ya muestra el qué. Ver
`git log` para el tono real: los mensajes de este repo son
deliberadamente más largos que el mínimo de una línea cuando el cambio
tiene una razón no obvia detrás.
