"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const { parseLacuerdaHtml } = require("../lacuerda");

function leerFixture(nombre) {
  return fs.readFileSync(path.join(__dirname, "fixtures", nombre), "utf8");
}

test("parsea título, artista, tono y acordes fusionados con la letra", () => {
  const resultado = parseLacuerdaHtml(leerFixture("cancion_basica.shtml"));

  assert.equal(resultado.titulo, "Canción de Prueba");
  assert.equal(resultado.artista, "Grupo de Prueba");
  assert.equal(resultado.tono, "Sol");
  assert.match(resultado.contenidoChordPro, /\[Sol\]Vamos \[Mim\]cantando \[Do\]con gozo/);
  assert.match(resultado.contenidoChordPro, /\[Re\]Con todo el \[Lam\]corazon/);
});

test("reconoce la etiqueta 'coro:' como {start_of_chorus}", () => {
  const { contenidoChordPro } = parseLacuerdaHtml(leerFixture("cancion_basica.shtml"));

  assert.match(contenidoChordPro, /\{start_of_chorus: Coro\}/);
  assert.match(contenidoChordPro, /\{end_of_chorus\}/);
  assert.match(contenidoChordPro, /\[Do\]Te alabamos \[Sol\]oh Senor/);
});

test("reconoce 'Puente:' como verso con nombre propio", () => {
  const { contenidoChordPro } = parseLacuerdaHtml(leerFixture("cancion_basica.shtml"));

  assert.match(contenidoChordPro, /\{start_of_verse: Puente\}/);
  assert.match(contenidoChordPro, /\[Lam\]Gloria a tu nombre/);
});

test("una línea de acordes sin letra abajo (ej. INTRO) se guarda como comentario, no se pierde", () => {
  const { contenidoChordPro } = parseLacuerdaHtml(leerFixture("cancion_basica.shtml"));

  assert.match(contenidoChordPro, /\{comment: INTRO\s*\(\s*Sol\s+Do\s*\)\s*2X\}/);
});

test("una página sin bloque #t_body lanza un error legible", () => {
  assert.throws(
    () => parseLacuerdaHtml(leerFixture("pagina_sin_cuerpo.shtml")),
    /no tiene el formato de una canción de lacuerda\.net/,
  );
});

test("un HTML vacío o no-string lanza en vez de reventar", () => {
  assert.throws(() => parseLacuerdaHtml(""), /no tiene el formato/);
  assert.throws(() => parseLacuerdaHtml(null), /no tiene el formato/);
});
