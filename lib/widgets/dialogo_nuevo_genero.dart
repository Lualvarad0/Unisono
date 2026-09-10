import 'package:flutter/material.dart';

import 'package:app_alabanzas/widgets/acciones_dialogo.dart';

/// Alta rápida de un género — un diálogo chico para una sola decisión
/// puntual, no un formulario propio. Se usa desde Nueva alabanza y desde
/// "Explorar por género" en Repertorio, así que vive acá en vez de
/// duplicarse en las dos pantallas.
///
/// El campo vive en su propio `StatefulWidget` (no un
/// `TextEditingController` local a quien llama `showDialog`, descartado
/// a mano justo después del `await`): ese `dispose()` manual corría
/// antes de que terminara la animación de salida del diálogo, y el
/// `TextField` todavía montado lo usaba ya descartado — "A
/// TextEditingController was used after being disposed." Acá Flutter
/// llama a `dispose()` recién cuando el elemento realmente se desmonta.
class DialogoNuevoGenero extends StatefulWidget {
  const DialogoNuevoGenero({super.key});

  @override
  State<DialogoNuevoGenero> createState() => _DialogoNuevoGeneroState();
}

class _DialogoNuevoGeneroState extends State<DialogoNuevoGenero> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo género'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Nombre'),
      ),
      actions: [
        AccionesDialogo(
          textoSecundario: 'Cancelar',
          onSecundario: () => Navigator.of(context).pop(),
          textoPrimario: 'Agregar',
          onPrimario: () => Navigator.of(context).pop(_controller.text.trim()),
        ),
      ],
    );
  }
}
