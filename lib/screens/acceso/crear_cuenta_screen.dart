import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_alabanzas/services/autenticacion_service.dart';
import 'package:app_alabanzas/screens/acceso/login_screen.dart';
import 'package:app_alabanzas/widgets/campo_auth.dart';
import 'package:app_alabanzas/widgets/logo_unisono.dart';

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
      // El StreamBuilder de SplashScreen decide la pantalla siguiente
      // (Selección de rol) solo — pero primero hay que sacar del medio
      // esta pantalla, que quedó apilada arriba de Splash con `push`.
      // Si no, el cambio de Splash queda tapado por esta.
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 0,
                color: tema.colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(color: tema.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const LogoUnisono(tamano: 56),
                        const SizedBox(height: 12),
                        Text('Crear cuenta', style: tema.textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text(
                          'Con esto entras a la app — después eliges quién '
                          'eres dentro del equipo.',
                          textAlign: TextAlign.center,
                          style: tema.textTheme.bodyMedium
                              ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 28),
                        CampoAuth(
                          controller: _emailController,
                          hint: 'Correo',
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.next,
                          validator: (valor) => (valor == null || !valor.contains('@'))
                              ? 'Ingresa un correo válido'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        CampoAuth(
                          controller: _contrasenaController,
                          hint: 'Contraseña',
                          esContrasena: true,
                          autofillHints: const [AutofillHints.newPassword],
                          textInputAction: TextInputAction.next,
                          validator: (valor) => (valor == null || valor.length < 6)
                              ? 'La contraseña necesita al menos 6 caracteres'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        CampoAuth(
                          controller: _confirmarController,
                          hint: 'Confirmar contraseña',
                          esContrasena: true,
                          textInputAction: TextInputAction.done,
                          validator: (valor) => valor != _contrasenaController.text
                              ? 'Las contraseñas no coinciden'
                              : null,
                          onFieldSubmitted: (_) => _crearCuenta(),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: tema.colorScheme.error),
                          ),
                        ],
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: _enviando ? null : _crearCuenta,
                            child: _enviando
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Crear cuenta'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          ),
                          child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
