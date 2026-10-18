import { motion } from "framer-motion";
import { AlertTriangle, ImagePlus, Loader2, Send, X } from "lucide-react";
import { useRef, useState } from "react";
import { collection, doc, serverTimestamp, setDoc } from "firebase/firestore";
import { getDownloadURL, ref, uploadBytes } from "firebase/storage";
import { db, storage } from "../lib/firebase";

const TAMANO_MAXIMO = 5 * 1024 * 1024;

type Estado = "inactivo" | "enviando" | "enviado" | "error";

export function ReportarFalla() {
  const [mensaje, setMensaje] = useState("");
  const [imagen, setImagen] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [estado, setEstado] = useState<Estado>("inactivo");
  const [error, setError] = useState<string | null>(null);
  const inputArchivoRef = useRef<HTMLInputElement>(null);

  const elegirImagen = (archivo: File | undefined) => {
    if (!archivo) return;
    if (!archivo.type.startsWith("image/")) {
      setError("Ese archivo no es una imagen.");
      return;
    }
    if (archivo.size > TAMANO_MAXIMO) {
      setError("La imagen pesa más de 5 MB — probá con una más liviana.");
      return;
    }
    setError(null);
    setImagen(archivo);
    setPreviewUrl(URL.createObjectURL(archivo));
  };

  const quitarImagen = () => {
    setImagen(null);
    if (previewUrl) URL.revokeObjectURL(previewUrl);
    setPreviewUrl(null);
    if (inputArchivoRef.current) inputArchivoRef.current.value = "";
  };

  const enviar = async () => {
    const texto = mensaje.trim();
    if (!texto) {
      setError("Contanos qué falla encontraste.");
      return;
    }
    setEstado("enviando");
    setError(null);
    try {
      const reporteRef = doc(collection(db, "reportesDeFalla"));

      let imagenUrl: string | undefined;
      if (imagen) {
        const extension = imagen.name.includes(".") ? imagen.name.split(".").pop() : "jpg";
        const archivoRef = ref(storage, `reportes/${reporteRef.id}/imagen.${extension}`);
        await uploadBytes(archivoRef, imagen, { contentType: imagen.type });
        imagenUrl = await getDownloadURL(archivoRef);
      }

      await setDoc(reporteRef, {
        mensaje: texto,
        ...(imagenUrl ? { imagenUrl } : {}),
        creadoEn: serverTimestamp(),
      });

      setEstado("enviado");
      setMensaje("");
      quitarImagen();
    } catch {
      setEstado("error");
      setError("No se pudo enviar — revisá tu conexión y probá de nuevo.");
    }
  };

  if (estado === "enviado") {
    return (
      <section id="reportar" className="bg-fondo py-20 md:py-28 px-4">
        <motion.div
          initial={{ opacity: 0, y: 12 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="max-w-xl mx-auto text-center bg-superficie-2 rounded-2xl p-10"
        >
          <div className="w-12 h-12 rounded-full bg-primary/15 flex items-center justify-center mx-auto mb-4">
            <Send size={20} className="text-primary-claro" />
          </div>
          <h2 className="text-xl font-semibold text-texto mb-2">¡Gracias!</h2>
          <p className="text-texto-tenue text-sm">
            Recibimos tu reporte. Lo vamos a revisar apenas podamos.
          </p>
          <button
            onClick={() => setEstado("inactivo")}
            className="mt-6 text-sm text-primary-claro font-medium hover:underline"
          >
            Mandar otro reporte
          </button>
        </motion.div>
      </section>
    );
  }

  return (
    <section id="reportar" className="bg-fondo py-20 md:py-28 px-4">
      <div className="max-w-xl mx-auto">
        <div className="text-center mb-8">
          <div className="w-10 h-10 rounded-lg bg-primary/15 flex items-center justify-center mx-auto mb-4">
            <AlertTriangle size={18} className="text-primary-claro" />
          </div>
          <h2 className="text-xl sm:text-2xl font-semibold text-texto mb-2">
            ¿Encontraste una falla?
          </h2>
          <p className="text-texto-tenue text-sm">
            Contanos qué pasó — una captura de pantalla ayuda, pero no hace falta.
          </p>
        </div>

        <motion.div
          initial={{ opacity: 0, y: 12 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="bg-superficie-2 rounded-2xl p-5 sm:p-6"
        >
          <textarea
            value={mensaje}
            onChange={(e) => setMensaje(e.target.value)}
            placeholder='Ej. "Al tocar en vivo no avanza de sección" o "no me deja guardar una canción nueva"'
            maxLength={2000}
            rows={4}
            disabled={estado === "enviando"}
            className="w-full bg-fondo rounded-xl p-3.5 text-sm text-texto placeholder:text-texto-tenue outline-none resize-none border border-borde focus:border-primary transition-colors"
          />

          {previewUrl ? (
            <div className="relative mt-3 inline-block">
              <img
                src={previewUrl}
                alt="Captura adjunta"
                className="max-h-40 rounded-lg border border-borde"
              />
              <button
                onClick={quitarImagen}
                aria-label="Quitar imagen"
                className="absolute -top-2 -right-2 w-6 h-6 rounded-full bg-black border border-borde flex items-center justify-center text-texto-tenue hover:text-texto"
              >
                <X size={13} />
              </button>
            </div>
          ) : (
            <label className="mt-3 inline-flex items-center gap-2 text-sm text-texto-tenue hover:text-texto cursor-pointer transition-colors">
              <ImagePlus size={16} />
              Adjuntar una captura (opcional)
              <input
                ref={inputArchivoRef}
                type="file"
                accept="image/*"
                className="hidden"
                onChange={(e) => elegirImagen(e.target.files?.[0])}
              />
            </label>
          )}

          {error && <p className="mt-3 text-sm text-red-400">{error}</p>}

          <button
            onClick={enviar}
            disabled={estado === "enviando"}
            className="mt-5 w-full inline-flex items-center justify-center gap-2 bg-primary disabled:opacity-60 rounded-full py-3 text-black font-medium text-sm transition-opacity"
          >
            {estado === "enviando" ? (
              <Loader2 size={16} className="animate-spin" />
            ) : (
              <Send size={14} />
            )}
            {estado === "enviando" ? "Enviando…" : "Enviar reporte"}
          </button>
        </motion.div>
      </div>
    </section>
  );
}
