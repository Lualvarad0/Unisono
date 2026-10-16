import { useScroll } from "framer-motion";
import { useRef } from "react";
import { WordsPullUpMultiStyle } from "../components/WordsPullUpMultiStyle";
import { ScrollRevealText } from "../components/ScrollRevealText";

const PARRAFO =
  "Cada equipo tiene su propio espacio, aislado del resto. El repertorio se descarga antes del servicio y queda disponible sin conexión, y el modo en vivo mantiene a todos viendo la misma sección mientras el líder avanza.";

export function About() {
  const refParrafo = useRef(null);
  const { scrollYProgress } = useScroll({
    target: refParrafo,
    offset: ["start 0.8", "end 0.3"],
  });

  return (
    <section id="como-funciona" className="bg-fondo py-20 md:py-28 px-4">
      <div className="bg-superficie rounded-2xl md:rounded-[2rem] max-w-5xl mx-auto px-6 py-16 md:py-24 text-center">
        <span className="text-primary-claro text-[10px] sm:text-xs font-semibold tracking-widest uppercase">
          Cómo funciona
        </span>

        <div className="mt-5 max-w-3xl mx-auto leading-[1.05] sm:leading-[1] text-2xl sm:text-3xl md:text-4xl lg:text-5xl">
          <WordsPullUpMultiStyle
            segmentos={[
              { text: "Unísono es la app que", className: "font-normal text-texto" },
              {
                text: "mantiene a tu equipo sincronizado.",
                className: "italic font-normal text-primary-claro",
              },
            ]}
          />
        </div>

        <div ref={refParrafo} className="mt-10">
          <ScrollRevealText
            text={PARRAFO}
            progresoScroll={scrollYProgress}
            className="text-texto max-w-2xl mx-auto text-sm sm:text-base leading-relaxed"
          />
        </div>
      </div>
    </section>
  );
}
