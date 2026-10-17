# Landing de Unísono

La página de descarga (`app-alabanzas.web.app`) — React + Vite + TypeScript
+ Tailwind CSS 4 + framer-motion + lucide-react. Reemplaza al HTML/CSS/JS
estático que vivía en `public/` (ver el README principal del repo para por
qué).

## Levantar en desarrollo

```bash
npm install
npm run dev
```

## Build de producción

```bash
npm run build
```

Genera `dist/` — es lo que `firebase.json` (en la raíz del repo, no
comiteado) apunta como `hosting.public` para desplegar con
`firebase deploy --only hosting`, corrido desde la raíz del repo.

## Estructura

```
src/
  components/   # WordsPullUp, WordsPullUpMultiStyle, ScrollRevealText,
                # ChordDemo (maqueta de letra+acordes), WaveformVisual
  hooks/
    useLatestRelease.ts  # último release de GitHub, para el botón de descarga
  sections/     # Hero, About, Features, Instalar, Footer
public/
  icono.png              # mismo ícono que assets/icon/icon.png del proyecto Flutter
  .well-known/
    assetlinks.json       # Digital Asset Links (Android), copiado del proyecto Flutter
```

La letra de ejemplo que se usa en `ChordDemo` ("Tu Presencia") es 100%
original, escrita para esto — no es de ninguna canción real.
