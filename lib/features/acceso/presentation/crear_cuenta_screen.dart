import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/services/autenticacion_service.dart';
import 'login_screen.dart';

class CrearCuentaScreen extends StatefulWidget {
  const CrearCuentaScreen({super.key});

  @override
  State<CrearCuentaScreen> createState() => _CrearCuentaScreenState();
}

class _CrearCuentaScreenState extends State<CrearCuentaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _confirmarController = TextEditingController();

  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _contrasenaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _crearCuenta() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await context.read<AutenticacionService>().crearCuenta(
            email: _emailController.text.trim(),
            contrasena: _contrasenaController.text,
          );
      // El StreamBuilder de SplashScreen lleva a Selección de rol solo.
    } on AutenticacionExcepcion catch (e) {
      setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crear cuenta',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Con esto entrás a la app — después elegís quién sos '
                  'dentro del equipo.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
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
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contrasenaController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    helperText: 'Al menos 6 caracteres',
                  ),
                  validator: (valor) => (valor == null || valor.length < 6)
                      ? 'La contraseña necesita al menos 6 caracteres'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmarController,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Confirmar contraseña'),
                  validator: (valor) => valor != _contrasenaController.text
                      ? 'Las contraseñas no coinciden'
                      : null,
                  onFieldSubmitted: (_) => _crearCuenta(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _enviando ? null : _crearCuenta,
                  child: _enviando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : const Text('Crear cuenta'),
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: const Text('¿Ya tenés cuenta? Iniciá sesión'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
