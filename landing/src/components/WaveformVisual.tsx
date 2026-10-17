import { motion } from "framer-motion";
import { useMemo } from "react";

const CANTIDAD_BARRAS = 48;

/**
 * Visualización de onda de audio grande, centrada en el espacio vacío
 * del hero — mismo motivo visual que las barras del ícono/logo, a
 * mayor escala. Reemplaza al video de fondo que pedía la referencia
 * original: no tenemos metraje propio ni licencia para usar uno
 * ajeno, así que esto comunica "voz/música" sin depender de ningún
 * archivo externo ni de la imagen de una persona real.
 */
export function WaveformVisual() {
  // Alturas base fijas (no Math.random en cada render) para que el pulso
  // se vea orgánico en vez de parejo, pero sin recalcularse de golpe.
  const barras = useMemo(
    () =>
      Array.from({ length: CANTIDAD_BARRAS }, (_, i) => {
        const centro = CANTIDAD_BARRAS / 2;
        const distancia = Math.abs(i - centro) / centro;
        return 0.25 + (1 - distancia) * 0.65;
      }),
    [],
  );

  return (
    <div
      className="absolute inset-0 flex items-center justify-center gap-[5px] md:gap-[7px] px-10 pointer-events-none"
      aria-hidden="true"
    >
      {barras.map((alturaBase, i) => (
        <motion.div
          key={i}
          className="w-[3px] md:w-[4px] rounded-full bg-gradient-to-t from-primary to-primary-claro"
          style={{ height: `${alturaBase * 42}vh`, opacity: 0.35 }}
          animate={{
            scaleY: [1, 0.35 + (i % 5) * 0.12, 1, 0.6 + (i % 3) * 0.15, 1],
          }}
          transition={{
            duration: 2.6 + (i % 7) * 0.15,
            repeat: Infinity,
            ease: "easeInOut",
            delay: (i % 12) * 0.08,
          }}
        />
      ))}
    </div>
  );
}
