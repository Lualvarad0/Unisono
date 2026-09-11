import 'package:flutter/material.dart';

/// Pantalla completa para ver una foto de perfil en grande — se abre al
/// tocar cualquier avatar que tenga una `fotoUrl` cargada (Perfil, Mi
/// equipo). Antes no había forma de ver la foto propia ni la de nadie
/// más que como el círculo chico del avatar.
void mostrarFotoCompleta(BuildContext context, String url) {
  Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        // `InteractiveViewer` deja acercar con pellizco — útil para ver
        // bien una cara en una foto tomada de lejos.
        body: Center(
          child: InteractiveViewer(
            child: Image.network(url),
          ),
        ),
      ),
    ),
  );
}
