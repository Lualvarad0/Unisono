import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:provider/provider.dart';

import 'package:app_alabanzas/core/invite_link.dart';
import 'package:app_alabanzas/models/miembro.dart';
import 'package:app_alabanzas/repositories/miembro_repository.dart';
import 'package:app_alabanzas/widgets/encabezado_seccion.dart';

/// Pantalla para que el líder invite a alguien nuevo al equipo: crea un
/// `Miembro` con nombre y rol pero sin `uid` — el mismo estado "sin
/// reclamar" que ya usa `SeleccionRolScreen`. La persona invitada puede
/// tocar el enlace generado acá (si ya tiene la app instalada, la abre
/// directo en "¿Sos vos?" — ver InviteLinkService) o, si no lo encuentra
/// entre sus mensajes, buscar su nombre a mano en "¿Quién sos?".
///
/// Sin cloud functions ni envío de email: el link se comparte a mano por
/// el canal que el líder prefiera (WhatsApp, SMS, etc.) — ver
/// `construirEnlaceInvitacion`.
class InvitarMiembroScreen extends StatefulWidget {
  const InvitarMiembroScreen({super.key});

  @override
  State<InvitarMiembroScreen> createState() => _InvitarMiembroScreenState();
}

class _InvitarMiembroScreenState extends State<InvitarMiembroScreen> {
  final _nombreController = TextEditingController();
  final Set<RolMiembro> _roles = {};
  bool _invitando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _invitar() async {
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty || _roles.isEmpty) return;
    setState(() => _invitando = true);
    final repositorio = context.read<MiembroRepository>();
    final id = await repositorio.crear(
      Miembro(id: '', nombre: nombre, roles: _roles.toList()),
    );
    if (!mounted) return;
    final enlace = construirEnlaceInvitacion(id);
    final mensaje = 'Te sumamos a Unísono como '
        '${_roles.map((r) => r.nombreVisible.toLowerCase()).join(' y ')}. '
        'Descargá la app y abrí este enlace para unirte: $enlace';
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$nombre ya está en el equipo'),
        action: SnackBarAction(
          label: 'Copiar mensaje',
          onPressed: () => Clipboard.setData(ClipboardData(text: mensaje)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombreVacio = _nombreController.text.trim().isEmpty;
    final puedeInvitar = !nombreVacio && _roles.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Invitar integrante')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Se suma como un integrante sin cuenta todavía — cuando esa '
            'persona se registre en la app, va a elegir su nombre en la '
            'lista y quedar vinculada a este perfil.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          const EncabezadoSeccion('DATOS'),
          const SizedBox(height: 12),
          TextField(
            controller: _nombreController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nombre *'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 28),
          const EncabezadoSeccion('ROL *'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final rol in RolMiembro.values)
                FilterChip(
                  label: Text(rol.nombreVisible),
                  selected: _roles.contains(rol),
                  onSelected: (marcado) => setState(() {
                    if (marcado) {
                      _roles.add(rol);
                    } else {
                      _roles.remove(rol);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: (_invitando || !puedeInvitar) ? null : _invitar,
            child: _invitando
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : const Text('Invitar'),
          ),
        ],
      ),
    );
  }
}
