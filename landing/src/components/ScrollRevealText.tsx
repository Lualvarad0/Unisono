import { motion, type MotionValue, useTransform } from "framer-motion";

/** Una letra cuya opacidad sigue el progreso de scroll del párrafo entero. */
function AnimatedLetter({
  letra,
  progresoScroll,
  progresoCaracter,
}: {
  letra: string;
  progresoScroll: MotionValue<number>;
  progresoCaracter: number;
}) {
  const opacidad = useTransform(
    progresoScroll,
    [progresoCaracter - 0.1, progresoCaracter + 0.05],
    [0.2, 1],
  );
  return <motion.span style={{ opacity: opacidad }}>{letra}</motion.span>;
}

/**
 * Revelado progresivo letra por letra en función del scroll — cada
 * caracter pasa de apenas visible a opacidad completa a medida que el
 * párrafo cruza el viewport, en vez de aparecer todo de una. El
 * progreso de cada letra es `índice / total`, así que el efecto
 * "recorre" el texto de izquierda a derecha mientras se hace scroll.
 */
export function ScrollRevealText({
  text,
  progresoScroll,
  className = "",
}: {
  text: string;
  progresoScroll: MotionValue<number>;
  className?: string;
}) {
  const caracteres = text.split("");
  const total = caracteres.length;

  return (
    <p className={className}>
      {caracteres.map((letra, i) => (
        <AnimatedLetter
          key={i}
          letra={letra}
          progresoScroll={progresoScroll}
          progresoCaracter={i / total}
        />
      ))}
    </p>
  );
}
