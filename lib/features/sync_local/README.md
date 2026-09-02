# sync_local — Capa 2: estado en vivo sin internet

Acá va la sincronización peer-to-peer entre celulares durante el servicio,
usando Nearby Connections (Android) / Multipeer Connectivity (iOS) por
debajo de una sola interfaz Dart (`flutter_nearby_connections` o su fork
mantenido `flutter_nearby_connections_plus`).

Se construye en el **Paso 4**, como un prototipo aislado de dos pantallas
mínimas (líder que transmite un número que cambia, seguidor que lo recibe)
probado en un Android real y un iPhone real, **antes** de integrarlo al
resto de la app.

Estructura prevista:

```
sync_local/
  data/
    services/
      nearby_sync_service.dart   # wrapper sobre flutter_nearby_connections
  domain/
    models/
      estado_en_vivo.dart        # { actividadId, indiceCancion, seccion, tonoActual }
  presentation/
    screens/
      lider_broadcast_screen.dart
      seguidor_listen_screen.dart
```

Por qué es una carpeta separada de `contenido` y `actividades`: esta capa
no persiste nada ni depende de internet — es transporte efímero de un
mensaje chico entre dispositivos en la misma sala. Mezclarla con los
repositorios de Firestore de las otras dos carpetas confundiría qué código
depende de red y cuál no.
