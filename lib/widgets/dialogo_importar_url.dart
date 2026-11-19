import 'package:flutter/material.dart';

import 'package:app_alabanzas/widgets/acciones_dialogo.dart';

/// Pide la URL de una canción de acordes.lacuerda.net — issue #26,
/// "Nueva alabanza". Mismo patrón que `DialogoNuevoGenero`: el campo
/// vive en su propio `StatefulWidget` para que `dispose()` del
/// controller no se adelante a la animación de salida del diálogo.
class DialogoImportarUrl extends StatefulWidget {
  const DialogoImportarUrl({super.key});

  @override
  State<DialogoImportarUrl> createState() => _DialogoImportarUrlState();
}

class _DialogoImportarUrlState extends State<DialogoImportarUrl> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Importar desde lacuerda.net'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.url,
        decoration: const InputDecoration(
          labelText: 'URL de la canción',
          hintText: 'https://acordes.lacuerda.net/...',
        ),
      ),
      actions: [
        AccionesDialogo(
          textoSecundario: 'Cancelar',
          onSecundario: () => Navigator.of(context).pop(),
          textoPrimario: 'Importar',
          onPrimario: () => Navigator.of(context).pop(_controller.text.trim()),
        ),
      ],
    );
  }
}
