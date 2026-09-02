import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/services/autenticacion_service.dart';

class RecuperarContrasenaScreen extends StatefulWidget {
  const RecuperarContrasenaScreen({super.key});

  @override
  State<RecuperarContrasenaScreen> createState() =>
      _RecuperarContrasenaScreenState();
}

class _RecuperarContrasenaScreenState
    extends State<RecuperarContrasenaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _enviando = false;
  bool _enviado = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await context.read<AutenticacionService>().recuperarContrasena(
            email: _emailController.text.trim(),
          );
      setState(() => _enviado = true);
    } on AutenticacionExcepcion catch (e) {
      setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: _enviado ? _mensajeEnviado(tema) : _formulario(tema),
        ),
      ),
    );
  }

  Widget _formulario(ThemeData tema) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recuperar contraseña',
            style: tema.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Te mandamos un correo con instrucciones para elegir una '
            'contraseña nueva.',
            style: tema.textTheme.bodyMedium
                ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Correo'),
            validator: (valor) => (valor == null || !valor.contains('@'))
                ? 'Ingresá un correo válido'
                : null,
            onFieldSubmitted: (_) => _enviar(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: tema.colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _enviando ? null : _enviar,
            child: _enviando
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : const Text('Enviar instrucciones'),
          ),
        ],
      ),
    );
  }

  Widget _mensajeEnviado(ThemeData tema) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.mark_email_read_outlined,
            size: 56, color: tema.colorScheme.primary),
        const SizedBox(height: 20),
        Text(
          'Revisá tu correo',
          style:
              tema.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Text(
          'Te mandamos instrucciones a ${_emailController.text.trim()} '
          'para elegir una contraseña nueva.',
          textAlign: TextAlign.center,
          style: tema.textTheme.bodyMedium
              ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 28),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Volver'),
        ),
      ],
    );
  }
}
