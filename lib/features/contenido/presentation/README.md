# contenido/presentation

Screens y widgets para explorar el repertorio (Ritmo -> Artista -> Canción)
y editarlo. Se construyen en el **Paso 5**, junto con:

- El parser/renderer de ChordPro (Paso 3), del que dependen para mostrar
  letra + acordes ya transportados al tono del día.
- Las vistas Músico y Cantante, que son widgets separados que consumen el
  mismo estado (sección activa + tono) — viven acá porque renderizan
  `Cancion`, aunque el estado que consumen venga de `sync_local`.
