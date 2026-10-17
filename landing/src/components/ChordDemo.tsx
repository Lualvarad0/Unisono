const LINEAS = [
  { acordes: ["D", "G"], letra: "Tu presencia aquí está" },
  { acordes: ["Em", "A"], letra: "Nos querés transformar" },
  { acordes: ["D", "G", "A"], letra: "Cantaremos sin cesar" },
  { acordes: ["Bm", "A"], letra: "Tu amor es sin igual" },
];

/**
 * Maqueta de la hoja de acordes de la app — letra de ejemplo 100%
 * original (no es de ninguna canción real, ver commit que la agregó),
 * con la línea "que está sonando" recorriendo la canción en loop. Es
 * la pieza central de la tarjeta grande de Features: muestra la
 * función principal de la app en vez de describirla con texto.
 */
export function ChordDemo() {
  return (
    <div
      className="bg-[#FAFAFA] text-[#1C1C1F] rounded-xl p-4 h-full overflow-hidden font-mono text-sm"
      role="img"
      aria-label="Letra y acordes de una canción en Unísono, con la línea que está sonando resaltada en vivo"
    >
      <div className="font-sans font-extrabold text-base mb-1">Tu Presencia</div>
      <span className="font-sans inline-block mb-4 text-[10px] font-semibold text-primary bg-primary/10 px-2 py-0.5 rounded-full">
        Tono · D
      </span>
      {LINEAS.map((linea, i) => (
        <div
          key={i}
          className={`px-2 -mx-2 mb-2.5 rounded-lg motion-safe:animate-[recorrer-linea_6s_ease-in-out_infinite] ${
            i === 1 ? "motion-reduce:bg-primary/10" : ""
          }`}
          style={{ animationDelay: `${i * 1.5}s` }}
        >
          <div className="flex gap-4 text-primary font-bold text-[11px] min-h-[14px]">
            {linea.acordes.map((a, j) => (
              <span key={j}>{a}</span>
            ))}
          </div>
          <div>{linea.letra}</div>
        </div>
      ))}
    </div>
  );
}
