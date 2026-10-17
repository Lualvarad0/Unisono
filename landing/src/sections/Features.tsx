import { motion } from "framer-motion";
import { Check, type LucideIcon, Music, Radio, Users } from "lucide-react";
import { ChordDemo } from "../components/ChordDemo";
import { WordsPullUpMultiStyle } from "../components/WordsPullUpMultiStyle";

const EASE_TARJETA: [number, number, number, number] = [0.22, 1, 0.36, 1];

interface TarjetaChecklist {
  numero: string;
  titulo: string;
  Icono: LucideIcon;
  items: string[];
}

const TARJETAS: TarjetaChecklist[] = [
  {
    numero: "01",
    titulo: "Tu repertorio",
    Icono: Music,
    items: ["Letra y acordes con transporte de tono instantáneo", "Disponible sin internet"],
  },
  {
    numero: "02",
    titulo: "Tu equipo",
    Icono: Users,
    items: ["Cada equipo con su propio código de acceso", "Setlists con aviso automático"],
  },
  {
    numero: "03",
    titulo: "En el momento",
    Icono: Radio,
    items: ["Modo en vivo, sincronizado con el resto", "Notas y ejercicios de práctica"],
  },
];

function TarjetaFeature({ tarjeta, indice }: { tarjeta: TarjetaChecklist; indice: number }) {
  const delayTarjeta = indice * 0.15;
  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.95 }}
      whileInView={{ opacity: 1, scale: 1 }}
      viewport={{ once: true, margin: "-100px" }}
      transition={{ duration: 0.5, delay: delayTarjeta, ease: EASE_TARJETA }}
      className="bg-superficie-2 rounded-xl p-5 flex flex-col"
    >
      <div className="w-10 h-10 rounded-lg bg-primary/15 flex items-center justify-center mb-4">
        <tarjeta.Icono size={18} className="text-primary-claro" />
      </div>
      <div className="flex items-baseline gap-2 mb-3">
        <h3 className="font-semibold text-texto">{tarjeta.titulo}</h3>
        <span className="text-texto-tenue text-xs">{tarjeta.numero}</span>
      </div>
      <ul className="flex flex-col gap-2">
        {tarjeta.items.map((item, i) => (
          <motion.li
            key={item}
            initial={{ opacity: 0, x: -8 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.4, delay: delayTarjeta + 0.3 + i * 0.12 }}
            className="flex items-start gap-2 text-sm text-texto-tenue"
          >
            <Check size={14} className="text-primary-claro mt-0.5 flex-shrink-0" />
            {item}
          </motion.li>
        ))}
      </ul>
    </motion.div>
  );
}

export function Features() {
  return (
    <section id="funciones" className="relative bg-fondo py-20 md:py-28 px-4 md:px-6 overflow-hidden">
      <div className="bg-noise absolute inset-0 opacity-[0.03] pointer-events-none" />
      <div className="absolute -top-40 left-1/2 -translate-x-1/2 w-[600px] h-[600px] rounded-full bg-[radial-gradient(circle,rgba(47,111,237,0.18),transparent_65%)] motion-safe:animate-[derivar_16s_ease-in-out_infinite] motion-reduce:animate-none pointer-events-none" />
      <div className="relative max-w-6xl mx-auto">
        <div className="text-center mb-14">
          <WordsPullUpMultiStyle
            className="block text-xl sm:text-2xl md:text-3xl lg:text-4xl font-normal"
            segmentos={[
              {
                text: "Pensada para el ensayo y el día del servicio.",
                className: "text-texto",
              },
            ]}
          />
          <WordsPullUpMultiStyle
            className="block text-xl sm:text-2xl md:text-3xl lg:text-4xl font-normal mt-1"
            segmentos={[
              {
                text: "Sin carpetas sueltas ni PDFs viejos por WhatsApp.",
                className: "text-texto-tenue",
              },
            ]}
          />
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3 lg:h-[420px]">
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.5, ease: EASE_TARJETA }}
            className="md:col-span-2 bg-superficie-2 rounded-xl p-3 flex flex-col min-h-[340px] lg:min-h-0"
          >
            <ChordDemo />
          </motion.div>
          {TARJETAS.map((tarjeta, i) => (
            <TarjetaFeature key={tarjeta.numero} tarjeta={tarjeta} indice={i + 1} />
          ))}
        </div>
      </div>
    </section>
  );
}
