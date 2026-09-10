import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_alabanzas/services/autenticacion_service.dart';
import 'package:app_alabanzas/screens/acceso/crear_cuenta_screen.dart';
import 'package:app_alabanzas/screens/acceso/recuperar_contrasena_screen.dart';
import 'package:app_alabanzas/widgets/campo_auth.dart';
import 'package:app_alabanzas/widgets/logo_unisono.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _contrasenaController = TextEditingController();

  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await context.read<AutenticacionService>().iniciarSesion(
            email: _emailController.text.trim(),
            contrasena: _contrasenaController.text,
          );
      // El StreamBuilder de SplashScreen decide la pantalla siguiente
      // solo, pero primero hay que sacar del medio esta pantalla, que
      // quedó apilada arriba de Splash con `push` — si no, el cambio de
      // Splash queda tapado por esta.
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const LogoUnisono(tamano: 56),
                        const SizedBox(height: 12),
                        Text('Unísono', style: tema.textTheme.titleLarge),
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
                          autofillHints: const [AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          validator: (valor) => (valor == null || valor.isEmpty)
                              ? 'Ingresa tu contraseña'
                              : null,
                          onFieldSubmitted: (_) => _iniciarSesion(),
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
                            onPressed: _enviando ? null : _iniciarSesion,
                            child: _enviando
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Iniciar sesión'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          runSpacing: 4,
                          children: [
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                              ),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RecuperarContrasenaScreen(),
                                ),
                              ),
                              child: const Text('¿Olvidaste tu contraseña?'),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                              ),
                              onPressed: () => Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const CrearCuentaScreen(),
                                ),
                              ),
                              child: const Text('Crear cuenta'),
                            ),
                          ],
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
