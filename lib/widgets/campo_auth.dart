import 'package:flutter/material.dart';

/// Campo de texto para Login/Crear cuenta/Recuperar contraseña: bordes
/// bien redondeados y relleno, sin etiqueta flotante (el texto de ayuda
/// vive adentro, como placeholder) — estilo "píldora" tomado de una
/// referencia visual que pidió el equipo, en vez del `TextFormField` con
/// etiqueta de arriba que usa el resto de la app en formularios de
/// contenido.
///
/// Si `esContrasena` es true, agrega el ojito para mostrar/ocultar sin
/// tener que reintroducir a mano — común en apps grandes, nada acá que
/// vulnere la regla de no escribir contraseñas por la persona: el toque
/// lo da quien ya tiene el campo enfocado.
class CampoAuth extends StatefulWidget {
  const CampoAuth({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.autofillHints,
    this.esContrasena = false,
    this.validator,
    this.onFieldSubmitted,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final bool esContrasena;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction? textInputAction;

  @override
  State<CampoAuth> createState() => _CampoAuthState();
}

class _CampoAuthState extends State<CampoAuth> {
  bool _oculto = true;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      autofillHints: widget.autofillHints,
      obscureText: widget.esContrasena && _oculto,
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      textInputAction: widget.textInputAction,
      decoration: InputDecoration(
        hintText: widget.hint,
        filled: true,
        fillColor: tema.colorScheme.surfaceContainerHigh,
        suffixIcon: widget.esContrasena
            ? IconButton(
                icon: Icon(_oculto ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _oculto = !_oculto),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      ),
    );
  }
}
