import { motion } from "framer-motion";
import { ArrowRight, GitFork } from "lucide-react";
import { WordsPullUp } from "../components/WordsPullUp";
import { WaveformVisual } from "../components/WaveformVisual";
import { useLatestRelease } from "../hooks/useLatestRelease";

const EASE_CINE: [number, number, number, number] = [0.16, 1, 0.3, 1];

const NAV_ITEMS = [
  { label: "Funciones", href: "#funciones" },
  { label: "Cómo sincroniza", href: "#como-funciona" },
  { label: "Instalar", href: "#instalar" },
];

export function Hero() {
  const release = useLatestRelease();

  return (
    <section className="h-screen p-4 md:p-6">
      <div className="relative h-full w-full overflow-hidden rounded-2xl md:rounded-[2rem] bg-superficie">
        {/* Fondo: gradiente que deriva lento + ruido — reemplaza el video
            cinematográfico de la referencia (no tenemos ni licencia para
            usar material ajeno) sin perder la sensación de movimiento. */}
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_30%_20%,rgba(47,111,237,0.35),transparent_55%),radial-gradient(ellipse_at_80%_80%,rgba(107,155,255,0.25),transparent_50%)] animate-[derivar_14s_ease-in-out_infinite] motion-reduce:animate-none" />
        <div className="noise-overlay absolute inset-0 opacity-[0.05] mix-blend-overlay pointer-events-none" />
        <div className="absolute inset-0 bg-gradient-to-b from-black/20 via-transparent to-black/70 pointer-events-none" />
        <WaveformVisual />

        {/* Navbar */}
        <motion.nav
          initial={{ y: -16, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ duration: 0.6, ease: EASE_CINE }}
          className="absolute top-0 left-1/2 -translate-x-1/2 z-10 max-w-[94vw]"
        >
          <div className="bg-black rounded-b-2xl md:rounded-b-3xl px-3 py-2 md:px-8 flex items-center gap-2 sm:gap-6 md:gap-12 overflow-x-auto">
            <img src="/icono.png" alt="" className="w-5 h-5 rounded flex-shrink-0" />
            {NAV_ITEMS.map((item) => (
              <a
                key={item.label}
                href={item.href}
                className="text-[10px] sm:text-xs md:text-sm transition-colors whitespace-nowrap"
                style={{ color: "rgba(242,242,245,0.75)" }}
                onMouseEnter={(e) => (e.currentTarget.style.color = "#F2F2F5")}
                onMouseLeave={(e) => (e.currentTarget.style.color = "rgba(242,242,245,0.75)")}
              >
                {item.label}
              </a>
            ))}
            <a
              href="https://github.com/Lualvarad0/Unisono"
              target="_blank"
              rel="noopener"
              className="text-[10px] sm:text-xs md:text-sm transition-colors flex items-center gap-1 whitespace-nowrap"
              style={{ color: "rgba(242,242,245,0.75)" }}
              onMouseEnter={(e) => (e.currentTarget.style.color = "#F2F2F5")}
              onMouseLeave={(e) => (e.currentTarget.style.color = "rgba(242,242,245,0.75)")}
            >
              <GitFork size={12} /> GitHub
            </a>
          </div>
        </motion.nav>

        {/* Contenido, alineado abajo */}
        <div className="absolute bottom-0 left-0 right-0 p-6 md:p-12 grid grid-cols-1 md:grid-cols-12 gap-6 items-end">
          <div className="md:col-span-8">
            <h1
              className="font-medium leading-[1] tracking-[-0.03em] text-[16vw] sm:text-[15vw] md:text-[11vw] lg:text-[9.5vw]"
              style={{ color: "#F2F2F5" }}
            >
              <WordsPullUp text="Unísono" />
            </h1>
          </div>
          <div className="md:col-span-4 flex flex-col gap-5">
            <motion.p
              initial={{ y: 20, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ duration: 0.6, delay: 0.5, ease: EASE_CINE }}
              className="text-texto-tenue text-xs sm:text-sm md:text-base leading-snug"
            >
              La app para equipos de alabanza: letra, acordes y tonalidades
              sincronizados, incluso sin internet.
            </motion.p>
            <motion.a
              initial={{ y: 20, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ duration: 0.6, delay: 0.7, ease: EASE_CINE }}
              href={release.apkUrl}
              target="_blank"
              rel="noopener"
              className="group inline-flex items-center gap-2 bg-primary hover:gap-3 transition-all rounded-full pl-5 pr-1.5 py-1.5 w-fit"
            >
              <span className="text-black font-medium text-sm sm:text-base">
                Descargar para Android
              </span>
              <span className="bg-black rounded-full w-9 h-9 sm:w-10 sm:h-10 flex items-center justify-center flex-shrink-0 transition-transform group-hover:scale-110">
                <ArrowRight size={16} className="text-white" />
              </span>
            </motion.a>
            <span className="text-[11px] text-texto-tenue -mt-2">{release.label}</span>
          </div>
        </div>
      </div>
    </section>
  );
}
