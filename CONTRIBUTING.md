# Contribuir a Unísono

Gracias por ayudar a mejorar Unísono. Antes de proponer un cambio, revisa
los [issues abiertos](https://github.com/Lualvarad0/Unisono/issues) para
ver si el trabajo ya está planteado. Para cambios grandes de producto o
arquitectura, conversa primero en un issue para acordar alcance y
comportamiento.

## Preparar el entorno

1. Instala Flutter estable `3.47.2`, Java `17` para Android y configura
   Android Studio/SDK. Para ejecutar iOS se requiere macOS con Xcode.
2. Clona el repositorio y resuelve los paquetes:

   ```bash
   git clone https://github.com/Lualvarad0/Unisono.git
   cd Unisono
   flutter pub get
   ```

3. Si vas a iniciar la app, crea o usa un proyecto Firebase propio y
   sigue [la configuración de Firebase del README](README.md#configurar-tu-propio-proyecto-firebase).
   No compartas ni agregues archivos de Firebase o claves de firma.

## Antes de enviar cambios

Ejecuta desde la raíz:

```bash
flutter analyze
flutter test
```

Los cambios de código deberían incluir pruebas que cubran la lógica nueva,
especialmente cuando se puede probar sin Firebase o UI. Si una validación
no se puede ejecutar, explica por qué y qué dispositivo/servicio hace
falta.

Para Cloud Functions, usa Node.js `24` (el runtime declarado en
`functions/package.json`) y respeta el `functions/package-lock.json`.
No hay un script de pruebas para Functions declarado actualmente. No
despliegues a un proyecto Firebase de producción desde una contribución;
usa un proyecto de prueba propio.

Para cambios de la landing, consulta [`landing/README.md`](landing/README.md)
y ejecuta sus scripts existentes (`npm run build`; `npm run dev` para
desarrollo). La instalación de npm usa el `package-lock.json` de esa
carpeta.

## Convenciones del proyecto

- Sigue [`docs/ESTILO_DE_CODIGO.md`](docs/ESTILO_DE_CODIGO.md): nombres
  del dominio en español, imports `package:`, capas y patrones existentes.
- Mantén los modelos de dominio y las referencias de Firestore coherentes
  con [`docs/API.md`](docs/API.md).
- No relajes las reglas Firestore/Storage para hacer pasar un flujo.
  Revisa [`docs/SEGURIDAD.md`](docs/SEGURIDAD.md) antes de modificar
  autorización o datos personales.
- No presentes como terminada una función que solo esté planeada o
  parcialmente integrada. Actualiza la documentación asociada y enlaza
  los issues relevantes.
- Mantén los cambios acotados y evita archivos generados, secretos,
  builds y credenciales.

## Pull requests

Abre un pull request contra `main` con:

- un título descriptivo y una explicación breve del problema y la
  solución;
- los issues que resuelve o complementa;
- las pruebas ejecutadas y, si el cambio es visual, capturas de datos
  ficticios;
- limitaciones conocidas y cualquier configuración manual requerida.

El proyecto está bajo licencia [MIT](LICENSE). Las contribuciones se
publican bajo esa licencia, con las atribuciones adicionales que exija
cualquier dependencia de terceros incluida.
