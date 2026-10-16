import { motion } from "framer-motion";

const PASOS = [
  { titulo: "Descargá el APK", texto: 'Tocá "Descargar para Android" arriba, desde tu celular.' },
  {
    titulo: "Permití instalar",
    texto: 'Android pide habilitar "Apps desconocidas" — normal fuera de la tienda.',
  },
  {
    titulo: "Abrí el archivo",
    texto: "Las próximas versiones se actualizan encima, sin perder tus datos.",
  },
];

export function Instalar() {
  return (
    <section id="instalar" className="bg-fondo py-20 md:py-28 px-4">
      <div className="max-w-4xl mx-auto text-center">
        <h2 className="text-2xl sm:text-3xl font-semibold text-texto mb-3">Cómo instalarla</h2>
        <p className="text-texto-tenue text-sm mb-12">
          Todavía no está en Google Play — el instalador se baja directo de GitHub.
        </p>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-8 text-left">
          {PASOS.map((paso, i) => (
            <motion.div
              key={paso.titulo}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-60px" }}
              transition={{ duration: 0.5, delay: i * 0.1 }}
            >
              <div className="w-8 h-8 rounded-full bg-superficie-2 border border-borde flex items-center justify-center text-primary-claro font-semibold text-sm mb-3">
                {i + 1}
              </div>
              <h3 className="font-semibold text-texto mb-1">{paso.titulo}</h3>
              <p className="text-sm text-texto-tenue">{paso.texto}</p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
