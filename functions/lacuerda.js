"use strict";

/**
 * Convierte una página de canción de acordes.lacuerda.net (issue #26) a
 * los campos que usa `Cancion` (`lib/models/cancion.dart`): título,
 * artista, un tono tentativo y la letra+acordes en formato ChordPro.
 *
 * El HTML de lacuerda.net no es un documento bien formado (etiquetas
 * sin comillas, sin cerrar, `<div></div>` como marcador de línea
 * vacío) así que en vez de un parser DOM completo se usan regex
 * puntuales sobre las dos zonas que importan: el bloque `#tH1`
 * (título/artista) y el bloque `#t_body > PRE` (letra y acordes, con
 * cada acorde envuelto en `<A>...</A>`).
 *
 * Formato de la letra en `#t_body`: pares de línea-de-acordes +
 * línea-de-letra, donde la columna de texto en la que aparece cada
 * acorde es la misma columna en la que hay que insertarlo dentro de la
 * letra. Una línea de acordes se reconoce porque, sacando los nombres
 * de acorde, lo que queda es solo espacios/paréntesis/barras — una
 * línea como "INTRO ( Sol Do ) 2X" tiene acordes pero también texto
 * propio, así que no se funde con la letra: queda como comentario.
 */

const ENTIDADES = { amp: "&", lt: "<", gt: ">", quot: '"', apos: "'", nbsp: " " };

function decodificarEntidades(texto) {
  return texto.replace(/&(#x?[0-9a-fA-F]+|[a-zA-Z]+);/g, (coincidencia, cuerpo) => {
    if (cuerpo[0] === "#") {
      const codigo = cuerpo[1].toLowerCase() === "x"
        ? parseInt(cuerpo.slice(2), 16)
        : parseInt(cuerpo.slice(1), 10);
      return Number.isNaN(codigo) ? coincidencia : String.fromCodePoint(codigo);
    }
    return ENTIDADES[cuerpo] ?? coincidencia;
  });
}

function quitarEtiquetas(fragmento) {
  return fragmento.replace(/<[^>]+>/g, "");
}

function extraerTituloArtista(html) {
  const bloque = html.match(/<div id=['"]?tH1['"]?>([\s\S]*?)<\/div>/i);
  if (!bloque) return { titulo: "", artista: "" };
  const h1 = bloque[1].match(/<h1>([\s\S]*?)<\/h1>/i);
  const h2 = bloque[1].match(/<h2>([\s\S]*?)<\/h2>/i);
  const limpiar = (fragmento) => decodificarEntidades(quitarEtiquetas(fragmento)).trim();
  return {
    titulo: h1 ? limpiar(h1[1]) : "",
    artista: h2 ? limpiar(h2[1]) : "",
  };
}

function extraerCuerpoCrudo(html) {
  const bloque = html.match(/<div id=['"]?t_body['"]?><PRE>([\s\S]*?)<\/PRE><\/div>/i);
  return bloque ? bloque[1] : null;
}

/** Cada ocurrencia de `<A>acorde</A>` dentro de una línea, en orden. */
function extraerAcordes(linea) {
  const regex = /<A>([^<]*)<\/A>/g;
  const acordes = [];
  let coincidencia;
  while ((coincidencia = regex.exec(linea)) !== null) acordes.push(coincidencia);
  return acordes;
}

/**
 * Para una línea cruda (con sus `<A>`): el texto plano resultante, en
 * qué columna de ese texto arranca cada acorde, y si la línea es
 * "pura de acordes" (nada más que espacios/paréntesis/barras fuera de
 * los `<A>`) — ver nota de formato arriba.
 */
function analizarLinea(lineaCruda) {
  const acordes = extraerAcordes(lineaCruda);
  let texto = "";
  let huecos = "";
  let cursor = 0;
  const columnas = [];
  for (const coincidencia of acordes) {
    const previo = decodificarEntidades(lineaCruda.slice(cursor, coincidencia.index));
    texto += previo;
    huecos += previo;
    const nombre = decodificarEntidades(coincidencia[1]).trim();
    if (nombre !== "") columnas.push({ columna: texto.length, acorde: nombre });
    texto += nombre;
    cursor = coincidencia.index + coincidencia[0].length;
  }
  const resto = decodificarEntidades(lineaCruda.slice(cursor));
  texto += resto;
  huecos += resto;
  const soloAcordes = columnas.length > 0 && /^[\s()|.:–-]*$/.test(huecos);
  return { texto, columnas, soloAcordes };
}

/** Inserta `[Acorde]` en `letra` en las columnas de `columnas`, de izquierda a derecha. */
function fusionarAcordesEnLetra(columnas, letra) {
  let resultado = letra;
  let desplazamiento = 0;
  for (const { columna, acorde } of columnas) {
    const posicion = Math.min(columna + desplazamiento, resultado.length);
    const inserto = `[${acorde}]`;
    resultado = resultado.slice(0, posicion) + inserto + resultado.slice(posicion);
    desplazamiento += inserto.length;
  }
  return resultado;
}

const ETIQUETAS_SECCION =
  /^(coro|estribillo|puente|verso\s*\d*|intro(?:ducci[oó]n)?|final|outro|interludio)\s*:?\s*$/i;

function normalizarEtiqueta(crudo) {
  const limpio = crudo.replace(/:\s*$/, "").trim().toLowerCase();
  const numero = limpio.match(/\d+/)?.[0];
  if (/^(coro|estribillo)/.test(limpio)) return "Coro";
  if (/^puente/.test(limpio)) return numero ? `Puente ${numero}` : "Puente";
  if (/^(intro|introducci[oó]n)/.test(limpio)) return "Intro";
  if (/^final/.test(limpio)) return "Final";
  if (/^outro/.test(limpio)) return "Outro";
  if (/^interludio/.test(limpio)) return "Interludio";
  if (/^verso/.test(limpio)) return numero ? `Verso ${numero}` : "Verso";
  return crudo.trim();
}

/**
 * Convierte el cuerpo crudo de `#t_body` a ChordPro, agrupando en
 * `{start_of_verse}`/`{start_of_chorus}` por bloques separados por
 * líneas en blanco o por una etiqueta reconocida (p. ej. "coro:").
 * Devuelve también el primer acorde encontrado, como tono tentativo.
 */
function convertirCuerpoAChordPro(cuerpoCrudo) {
  const lineas = cuerpoCrudo.replace(/<div><\/div>/g, "").split(/\r?\n/);

  let primerAcorde = null;
  const unidades = [];
  for (let i = 0; i < lineas.length; i++) {
    const actual = analizarLinea(lineas[i]);
    if (!primerAcorde && actual.columnas.length > 0) {
      primerAcorde = actual.columnas[0].acorde;
    }
    if (actual.columnas.length > 0) {
      if (actual.soloAcordes) {
        const siguienteCruda = lineas[i + 1];
        const siguiente = siguienteCruda !== undefined ? analizarLinea(siguienteCruda) : null;
        const siguienteEsLetra =
          siguiente && siguiente.columnas.length === 0 && siguiente.texto.trim() !== "";
        if (siguienteEsLetra) {
          unidades.push({ tipo: "texto", texto: fusionarAcordesEnLetra(actual.columnas, siguiente.texto) });
          i++;
          continue;
        }
      }
      // Tiene acordes pero no se fundió con una línea de letra de abajo
      // (ej. "INTRO ( Sol Do ) 2X" o una progresión suelta) — se guarda
      // como comentario en vez de perderse o mezclarse con la letra.
      if (actual.texto.trim() !== "") {
        unidades.push({ tipo: "comentario", texto: actual.texto.trim() });
      }
      continue;
    }
    const comoEtiqueta = actual.texto.trim().match(ETIQUETAS_SECCION);
    unidades.push(
      comoEtiqueta
        ? { tipo: "etiqueta", nombre: normalizarEtiqueta(comoEtiqueta[0]) }
        : { tipo: "texto", texto: actual.texto },
    );
  }

  const bloques = [];
  let actualEtiqueta = null;
  let actualLineas = [];
  let contadorVerso = 1;

  const cerrarBloque = () => {
    const tieneContenido = actualLineas.some((l) => l.texto.trim() !== "");
    if (tieneContenido) {
      const esCoro = actualEtiqueta && /^coro/i.test(actualEtiqueta);
      const directiva = esCoro ? "chorus" : "verse";
      const nombre = actualEtiqueta ?? `Verso ${contadorVerso++}`;
      const cuerpo = actualLineas
        .map((l) => (l.tipo === "comentario" ? `{comment: ${l.texto}}` : l.texto))
        .join("\n")
        .trim();
      bloques.push(`{start_of_${directiva}: ${nombre}}\n${cuerpo}\n{end_of_${directiva}}`);
    }
    actualEtiqueta = null;
    actualLineas = [];
  };

  for (const unidad of unidades) {
    if (unidad.tipo === "etiqueta") {
      cerrarBloque();
      actualEtiqueta = unidad.nombre;
      continue;
    }
    if (unidad.tipo === "texto" && unidad.texto.trim() === "") {
      cerrarBloque();
      continue;
    }
    actualLineas.push(unidad);
  }
  cerrarBloque();

  return {
    contenidoChordPro: bloques.join("\n\n"),
    tono: primerAcorde ? primerAcorde.split("/")[0] : null,
  };
}

/**
 * @param {string} html Documento completo de una página de
 *   acordes.lacuerda.net.
 * @returns {{titulo: string, artista: string, tono: string|null, contenidoChordPro: string}}
 * @throws {Error} si no parece una página de canción de lacuerda.net,
 *   o si no se encontró letra para importar — mensajes pensados para
 *   mostrarse tal cual al líder (ver `importarCancionLacuerda` en
 *   `index.js`).
 */
function parseLacuerdaHtml(html) {
  if (typeof html !== "string" || !/id=['"]?t_body['"]?/i.test(html)) {
    throw new Error("Esa página no tiene el formato de una canción de lacuerda.net.");
  }
  const { titulo, artista } = extraerTituloArtista(html);
  const cuerpoCrudo = extraerCuerpoCrudo(html);
  if (!cuerpoCrudo) {
    throw new Error("No se encontró la letra y los acordes en esa página.");
  }
  const { contenidoChordPro, tono } = convertirCuerpoAChordPro(cuerpoCrudo);
  if (contenidoChordPro.trim() === "") {
    throw new Error("Esa página no tiene letra para importar.");
  }
  return { titulo, artista, tono, contenidoChordPro };
}

module.exports = { parseLacuerdaHtml };
