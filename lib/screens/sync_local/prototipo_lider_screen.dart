import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_nearby_connections_plus/flutter_nearby_connections_plus.dart';

import 'package:app_alabanzas/services/sync_local/permisos_sync_local.dart';
import 'package:app_alabanzas/services/sync_local/prototipo_conexion_service.dart';
import 'package:app_alabanzas/widgets/sync_local/lista_dispositivos.dart';

/// Pantalla líder del prototipo aislado (Paso 4): anuncia este celular por
/// Nearby Connections y, a cada dispositivo que se conecta, le transmite
/// un contador que va cambiando — el equivalente mínimo al
/// `{ actividadId, indiceCancion, seccion, tonoActual }` real que se arma
/// en el Paso 5.
class PrototipoLiderScreen extends StatefulWidget {
  const PrototipoLiderScreen({super.key});

  @override
  State<PrototipoLiderScreen> createState() => _PrototipoLiderScreenState();
}

class _PrototipoLiderScreenState extends State<PrototipoLiderScreen> {
  final _servicio = PrototipoConexionService();
  StreamSubscription<List<Device>>? _dispositivosSub;
  Timer? _autoIncremento;

  List<Device> _dispositivos = const [];
  int _contador = 0;
  String _estado = 'Iniciando...';

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    final permisosOk = await pedirPermisosSyncLocal();
    if (!permisosOk) {
      setState(() => _estado = 'Faltan permisos de Bluetooth/ubicación.');
      return;
    }

    await _servicio.iniciar(nombreDispositivo: 'Líder');
    await _servicio.anunciarse();
    if (!mounted) return;
    setState(() => _estado = 'Anunciando este celular como líder...');

    _dispositivosSub = _servicio.dispositivos.listen((dispositivosEncontrados) {
      if (!mounted) return;
      setState(() => _dispositivos = dispositivosEncontrados);
    });
  }

  void _incrementar() {
    setState(() => _contador++);
    _transmitir();
  }

  void _transmitir() {
    for (final dispositivo in _dispositivos) {
      if (dispositivo.state == SessionState.connected) {
        _servicio.enviar(dispositivo.deviceId, '$_contador');
      }
    }
  }

  void _alternarAutoIncremento(bool activo) {
    _autoIncremento?.cancel();
    _autoIncremento = activo
        ? Timer.periodic(const Duration(seconds: 2), (_) => _incrementar())
        : null;
    setState(() {});
  }

  @override
  void dispose() {
    _autoIncremento?.cancel();
    _dispositivosSub?.cancel();
    _servicio.detener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conectados =
        _dispositivos.where((d) => d.state == SessionState.connected).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Líder')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(_estado),
            const SizedBox(height: 4),
            Text('$conectados dispositivo(s) conectado(s)'),
            const SizedBox(height: 24),
            Text('$_contador', style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _incrementar,
              child: const Text('+1 (transmitir)'),
            ),
            SwitchListTile(
              title: const Text('Auto-incrementar cada 2s'),
              value: _autoIncremento != null,
              onChanged: _alternarAutoIncremento,
            ),
            const Divider(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Dispositivos cercanos'),
            ),
            Expanded(child: ListaDispositivos(dispositivos: _dispositivos)),
          ],
        ),
      ),
    );
  }
}
