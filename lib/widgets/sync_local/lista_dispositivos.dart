import 'package:flutter/material.dart';
import 'package:flutter_nearby_connections_plus/flutter_nearby_connections_plus.dart';

/// Lista de dispositivos descubiertos por Nearby Connections, con su
/// estado. Si se pasan [etiquetaAccion]/[onAccion], cada dispositivo no
/// conectado muestra un botón (lo usa el Seguidor para "Conectar" — el
/// Líder solo anuncia y no invita, así que la muestra sin botón).
class ListaDispositivos extends StatelessWidget {
  const ListaDispositivos({
    super.key,
    required this.dispositivos,
    this.etiquetaAccion,
    this.onAccion,
  });

  final List<Device> dispositivos;
  final String? etiquetaAccion;
  final void Function(Device dispositivo)? onAccion;

  @override
  Widget build(BuildContext context) {
    if (dispositivos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Buscando dispositivos cercanos...'),
      );
    }
    return ListView.builder(
      itemCount: dispositivos.length,
      itemBuilder: (context, index) {
        final dispositivo = dispositivos[index];
        final mostrarBoton =
            dispositivo.state == SessionState.notConnected && onAccion != null;
        return ListTile(
          title: Text(dispositivo.deviceName),
          subtitle: Text(_etiquetaEstado(dispositivo.state)),
          trailing: mostrarBoton
              ? TextButton(
                  onPressed: () => onAccion!(dispositivo),
                  child: Text(etiquetaAccion!),
                )
              : null,
        );
      },
    );
  }

  static String _etiquetaEstado(SessionState state) => switch (state) {
        SessionState.notConnected => 'No conectado',
        SessionState.connecting => 'Conectando...',
        SessionState.connected => 'Conectado',
      };
}
