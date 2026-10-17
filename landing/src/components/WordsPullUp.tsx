import { motion, useInView } from "framer-motion";
import { useRef } from "react";

/**
 * Separa `text` por espacios y anima cada palabra con un slide-up
 * escalonado, disparado una sola vez cuando entra en viewport
 * (`useInView`, `once: true`) — pensado para titulares grandes donde el
 * movimiento palabra por palabra se nota, a diferencia de animar el
 * bloque entero de una.
 */
export function WordsPullUp({
  text,
  className = "",
  delayBase = 0,
}: {
  text: string;
  className?: string;
  delayBase?: number;
}) {
  const ref = useRef(null);
  const enVista = useInView(ref, { once: true, margin: "-10%" });
  const palabras = text.split(" ");

  return (
    <span ref={ref} className={`inline-flex flex-wrap ${className}`}>
      {palabras.map((palabra, i) => (
        <span key={i} className="overflow-hidden pt-[0.2em] pb-[0.1em] mr-[0.25em]">
          <motion.span
            className="inline-block"
            initial={{ y: "100%", opacity: 0 }}
            animate={enVista ? { y: 0, opacity: 1 } : {}}
            transition={{
              duration: 0.6,
              delay: delayBase + i * 0.08,
              ease: [0.16, 1, 0.3, 1],
            }}
          >
            {palabra}
          </motion.span>
        </span>
      ))}
    </span>
  );
}
