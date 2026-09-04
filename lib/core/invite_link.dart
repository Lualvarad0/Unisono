/// Dominio de Firebase Hosting del proyecto — mismo host que el
/// intent-filter de App Links en AndroidManifest.xml y que
/// `public/.well-known/assetlinks.json`. Si el proyecto de Firebase
/// cambia de nombre, hay que actualizar los tres lugares.
const inviteHost = 'app-alabanzas.web.app';

/// El enlace que el líder comparte al invitar a alguien — ver
/// `InvitarMiembroScreen` (lo genera) e `InviteLinkService` (lo captura
/// cuando alguien lo abre con la app instalada).
String construirEnlaceInvitacion(String miembroId) =>
    'https://$inviteHost/invitar/$miembroId';
