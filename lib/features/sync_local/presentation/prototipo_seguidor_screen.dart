import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_nearby_connections_plus/flutter_nearby_connections_plus.dart';

import '../domain/permisos_sync_local.dart';
import '../domain/prototipo_conexion_service.dart';
import 'widgets/lista_dispositivos.dart';

/// Pantalla seguidor del prototipo aislado (Paso 4): busca al líder por
/// Nearby Connections, se conecta, y muestra el último valor que le llegó
/// — sin scroll ni acción manual, tal como tiene que verse el avance de
/// canción/sección en la app real (Paso 5).
class PrototipoSeguidorScreen extends StatefulWidget {
  const PrototipoSeguidorScreen({super.key});

  @override
  State<PrototipoSeguidorScreen> createState() =>
      _PrototipoSeguidorScreenState();
}

class _PrototipoSeguidorScreenState extends State<PrototipoSeguidorScreen> {
  final _servicio = PrototipoConexionService();
  StreamSubscription<List<Device>>? _dispositivosSub;
  StreamSubscription<String>? _mensajesSub;

  List<Device> _dispositivos = const [];
  String _ultimoValorRecibido = '—';
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

    await _servicio.iniciar(nombreDispositivo: 'Seguidor');
    await _servicio.buscarPeers();
    if (!mounted) return;
    setState(() => _estado = 'Buscando al líder...');

    _dispositivosSub = _servicio.dispositivos.listen((dispositivosEncontrados) {
      if (!mounted) return;
      setState(() => _dispositivos = dispositivosEncontrados);
    });

    _mensajesSub = _servicio.mensajes.listen((mensaje) {
      if (!mounted) return;
      setState(() => _ultimoValorRecibido = mensaje);
    });
  }

  @override
  void dispose() {
    _dispositivosSub?.cancel();
    _mensajesSub?.cancel();
    _servicio.detener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seguidor')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(_estado),
            const SizedBox(height: 24),
            const Text('Último valor recibido del líder:'),
            const SizedBox(height: 8),
            Text(
              _ultimoValorRecibido,
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const Divider(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Dispositivos cercanos'),
            ),
            Expanded(
              child: ListaDispositivos(
                dispositivos: _dispositivos,
                etiquetaAccion: 'Conectar',
                onAccion: (dispositivo) => _servicio.conectarA(dispositivo),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
