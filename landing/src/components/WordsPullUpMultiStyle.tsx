import { motion, useInView } from "framer-motion";
import { useRef } from "react";

export interface SegmentoTexto {
  text: string;
  className?: string;
}

/**
 * Como `WordsPullUp`, pero recibe varios segmentos con su propia clase
 * (ej. una frase normal seguida de una en cursiva) y anima TODAS las
 * palabras de todos los segmentos como una sola secuencia continua —
 * el stagger no se reinicia entre segmentos, para que el titular se
 * lea como una sola animación.
 */
export function WordsPullUpMultiStyle({
  segmentos,
  className = "",
}: {
  segmentos: SegmentoTexto[];
  className?: string;
}) {
  const ref = useRef(null);
  const enVista = useInView(ref, { once: true, margin: "-10%" });

  let indiceGlobal = 0;

  return (
    <span ref={ref} className={`inline-flex flex-wrap justify-center ${className}`}>
      {segmentos.map((segmento, si) =>
        segmento.text.split(" ").map((palabra, pi) => {
          const indice = indiceGlobal++;
          return (
            <span
              key={`${si}-${pi}`}
              className={`overflow-hidden pb-[0.15em] mr-[0.28em] ${segmento.className ?? ""}`}
            >
              <motion.span
                className="inline-block"
                initial={{ y: "100%", opacity: 0 }}
                animate={enVista ? { y: 0, opacity: 1 } : {}}
                transition={{
                  duration: 0.6,
                  delay: indice * 0.08,
                  ease: [0.16, 1, 0.3, 1],
                }}
              >
                {palabra}
              </motion.span>
            </span>
          );
        }),
      )}
    </span>
  );
}
