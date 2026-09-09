import 'package:flutter/material.dart';

/// Selector tipo "pastilla" con 2 a 4 opciones en una fila — una sola
/// elegida a la vez, la elegida se resalta con superficie propia y texto
/// en el color de acento. Reemplaza los `ChoiceChip` sueltos que usaba
/// cada formulario por un único estilo compartido (Tema, Tamaño de
/// letra, Nivel de instrumento, ...).
class SelectorSegmentado<T> extends StatelessWidget {
  const SelectorSegmentado({
    super.key,
    required this.opciones,
    required this.etiqueta,
    required this.valor,
    required this.onCambiar,
  });

  final List<T> opciones;
  final String Function(T opcion) etiqueta;
  final T valor;
  final ValueChanged<T> onCambiar;

  @override
  Widget build(BuildContext context) {
    return _FondoPastilla(
      children: [
        for (final opcion in opciones)
          Expanded(
            child: _Segmento(
              seleccionado: opcion == valor,
              texto: etiqueta(opcion),
              onTap: () => onCambiar(opcion),
            ),
          ),
      ],
    );
  }
}

/// Misma pastilla que `SelectorSegmentado`, pero de selección múltiple —
/// para "Roles", donde alguien puede ser Músico y Cantante a la vez. Cada
/// segmento se prende/apaga por su cuenta en vez de excluir a los demás.
class SelectorSegmentadoMultiple<T> extends StatelessWidget {
  const SelectorSegmentadoMultiple({
    super.key,
    required this.opciones,
    required this.etiqueta,
    required this.valores,
    required this.onCambiar,
  });

  final List<T> opciones;
  final String Function(T opcion) etiqueta;
  final Set<T> valores;
  final ValueChanged<T> onCambiar;

  @override
  Widget build(BuildContext context) {
    return _FondoPastilla(
      children: [
        for (final opcion in opciones)
          Expanded(
            child: _Segmento(
              seleccionado: valores.contains(opcion),
              texto: etiqueta(opcion),
              onTap: () => onCambiar(opcion),
            ),
          ),
      ],
    );
  }
}

class _FondoPastilla extends StatelessWidget {
  const _FondoPastilla({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tema.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: children),
    );
  }
}

class _Segmento extends StatelessWidget {
  const _Segmento({
    required this.seleccionado,
    required this.texto,
    required this.onTap,
  });

  final bool seleccionado;
  final String texto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: seleccionado ? tema.colorScheme.surfaceContainer : null,
          borderRadius: BorderRadius.circular(10),
          boxShadow: seleccionado
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 5,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          texto,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tema.textTheme.labelLarge?.copyWith(
            color:
                seleccionado ? tema.colorScheme.primary : tema.colorScheme.onSurfaceVariant,
            fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
