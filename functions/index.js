const { setGlobalOptions } = require("firebase-functions");
const { onDocumentUpdated, onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

setGlobalOptions({ maxInstances: 10 });

/**
 * Manda una notificación a una lista de tokens FCM, en tandas de 500
 * (límite de sendEachForMulticast) — de sobra para el tamaño de un equipo
 * de alabanza, pero evita que un equipo grande rompa la llamada.
 */
async function notificar(tokens, notification, data = {}) {
  const unicos = [...new Set(tokens)].filter(Boolean);
  if (unicos.length === 0) return;
  for (let i = 0; i < unicos.length; i += 500) {
    const tanda = unicos.slice(i, i + 500);
    try {
      await admin.messaging().sendEachForMulticast({ tokens: tanda, notification, data });
    } catch (error) {
      logger.error("Error al enviar notificación", error);
    }
  }
}

/**
 * Tokens FCM de todo UN equipo puntual (ver `equipos/{equipoId}/miembros`
 * — cada equipo tiene su propia base aislada, no hay un "equipo" global),
 * salvo quien se excluya (ej. quien generó el aviso).
 */
async function tokensDelEquipo(equipoId, { excluirId } = {}) {
  const snapshot = await db.collection("equipos").doc(equipoId).collection("miembros").get();
  return snapshot.docs
    .filter((doc) => doc.id !== excluirId)
    .map((doc) => doc.data().fcmToken)
    .filter(Boolean);
}

/**
 * Límite de frecuencia para avisos a todo el equipo: `firestore.rules`
 * deja que cualquier integrante autenticado escriba en `actividades`
 * (hace falta para que el líder pueda armar un setlist), así que nada
 * impide que alguien —con mala intención, o por un bug del lado del
 * cliente— dispare `onModoEnVivoIniciado`/`onSetlistEscrito` a repetición
 * tocando el mismo campo varias veces seguidas, mandándole un push a
 * todo el equipo cada vez. Esto frena eso: un mismo aviso (misma
 * `clave`, ya con el equipo adentro) no se repite dentro de la ventana,
 * sin importar cuántas escrituras lo disparen. Colección propia a nivel
 * raíz (no adentro de cada equipo) porque es puro control interno, nunca
 * la lee ni la escribe el cliente.
 */
const VENTANA_RATE_LIMIT_MS = 2 * 60 * 1000;

async function dentroDelLimite(clave) {
  const ref = db.collection("rateLimitsAvisos").doc(clave);
  const ahora = Date.now();
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const ultimo = snap.exists ? snap.data().ultimoEnviadoMs : 0;
    if (ahora - ultimo < VENTANA_RATE_LIMIT_MS) return true;
    tx.set(ref, { ultimoEnviadoMs: ahora });
    return false;
  });
}

/**
 * Límite de N intentos por ventana (a diferencia de `dentroDelLimite`,
 * que es "como mucho uno por ventana") — pensado para algo que un
 * usuario real reintenta varias veces seguidas sin culpa (tipeó mal un
 * código), pero que no puede quedar abierto a fuerza bruta: probar las
 * 32^6 combinaciones del código de equipo a mano tardaría años igual,
 * pero sin esto un script sí podría probar miles por segundo.
 */
async function intentosPermitidos(clave, { maxIntentos, ventanaMs }) {
  const ref = db.collection("rateLimitsIntentos").doc(clave);
  const ahora = Date.now();
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const datos = snap.exists ? snap.data() : null;
    const dentroDeVentana = datos && ahora - datos.inicioMs < ventanaMs;
    const intentosPrevios = dentroDeVentana ? datos.intentos : 0;
    if (intentosPrevios >= maxIntentos) return false;
    tx.set(ref, {
      inicioMs: dentroDeVentana ? datos.inicioMs : ahora,
      intentos: intentosPrevios + 1,
    });
    return true;
  });
}

/**
 * Busca un equipo por su código de 6 caracteres — del lado del
 * servidor, con el Admin SDK, a propósito: antes esto era una query
 * directa desde el cliente (`equipos.where('codigo', '==', ...)`), y
 * para que esa query pudiera funcionar `firestore.rules` tenía que
 * dejar leer (`list`) la colección `equipos` entera a cualquier
 * autenticado — lo que de paso dejaba que cualquiera listara el
 * nombre y el código de TODOS los equipos de un saque, sin necesitar
 * ningún código. Acá en cambio el cliente nunca puede listar nada:
 * solo recibe sí/no + el equipo puntual que preguntó, y con un límite
 * de intentos para que probar códigos al voleo no sea gratis.
 */
exports.buscarEquipoPorCodigo = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Hace falta estar logueado.");
  }
  const codigoCrudo = request.data?.codigo;
  if (typeof codigoCrudo !== "string") {
    throw new HttpsError("invalid-argument", "Falta el código.");
  }
  const codigo = codigoCrudo.trim().toUpperCase();
  if (!/^[A-Z0-9]{6}$/.test(codigo)) {
    throw new HttpsError("invalid-argument", "El código tiene que tener 6 caracteres.");
  }

  const permitido = await intentosPermitidos(`buscarCodigo_${request.auth.uid}`, {
    maxIntentos: 20,
    ventanaMs: 5 * 60 * 1000,
  });
  if (!permitido) {
    throw new HttpsError(
      "resource-exhausted",
      "Demasiados intentos — esperá un momento y probá de nuevo.",
    );
  }

  const resultado = await db.collection("equipos").where("codigo", "==", codigo).limit(1).get();
  if (resultado.empty) return { encontrado: false };
  const doc = resultado.docs[0];
  const datos = doc.data();
  return {
    encontrado: true,
    equipoId: doc.id,
    nombre: datos.nombre,
    creadoPorUid: datos.creadoPorUid,
  };
});

/**
 * El líder inicia "Modo en vivo": `cancionActivaId` pasa de vacío a tener
 * valor. Es el mismo campo que ya usa Vista en vivo (Firestore en tiempo
 * real) para que los celulares sepan qué mostrar — acá solo se avisa
 * al resto que arrancó.
 */
exports.onModoEnVivoIniciado = onDocumentUpdated(
  "equipos/{equipoId}/actividades/{actividadId}",
  async (event) => {
    const antes = event.data.before.data();
    const despues = event.data.after.data();
    if (antes.cancionActivaId || !despues.cancionActivaId) return;
    const { equipoId, actividadId } = event.params;
    if (await dentroDelLimite(`${equipoId}_modoEnVivo_${actividadId}`)) return;

    const tokens = await tokensDelEquipo(equipoId);
    await notificar(tokens, {
      title: "🔴 Modo en vivo",
      body: `El líder inició la transmisión de "${despues.nombre}"`,
    });
  },
);

/**
 * Setlist armado, cambiado, o con una canción/cantante reasignado — los
 * tres pasan por escrituras del mismo documento `Actividad`, así que se
 * comparan `before`/`after` acá en vez de triplicar el trigger.
 */
exports.onSetlistEscrito = onDocumentWritten(
  "equipos/{equipoId}/actividades/{actividadId}",
  async (event) => {
    const despuesExiste = event.data.after.exists;
    if (!despuesExiste) return;
    const despues = event.data.after.data();
    const { equipoId, actividadId } = event.params;

    const antesExiste = event.data.before.exists;
    if (!antesExiste) {
      if ((despues.setlist || []).length === 0) return;
      if (await dentroDelLimite(`${equipoId}_setlist_${actividadId}`)) return;
      const tokens = await tokensDelEquipo(equipoId);
      await notificar(tokens, {
        title: "📋 Nuevo setlist",
        body: `Se armó el setlist de "${despues.nombre}"`,
      });
      return;
    }

    const antes = event.data.before.data();
    const setlistAntes = antes.setlist || [];
    const setlistDespues = despues.setlist || [];

    // Misma canción+orden con otro cantante = reasignación puntual, se avisa
    // solo a quien queda asignado ahora (no a todo el equipo).
    const asignaciones = [];
    for (const entrada of setlistDespues) {
      const anterior = setlistAntes.find(
        (e) => e.cancionId === entrada.cancionId && e.orden === entrada.orden,
      );
      if (anterior && anterior.cantanteId !== entrada.cantanteId && entrada.cantanteId) {
        asignaciones.push(entrada);
      }
    }
    const miembrosRef = db.collection("equipos").doc(equipoId).collection("miembros");
    const cancionesRef = db.collection("equipos").doc(equipoId).collection("canciones");
    for (const entrada of asignaciones) {
      const miembro = await miembrosRef.doc(entrada.cantanteId).get();
      const token = miembro.data()?.fcmToken;
      if (!token) continue;
      const cancion = await cancionesRef.doc(entrada.cancionId).get();
      const titulo = cancion.data()?.titulo ?? "una canción";
      await notificar([token], {
        title: "🎵 Canción asignada",
        body: `Te asignaron "${titulo}" en "${despues.nombre}"`,
      });
    }

    // Además de reasignaciones puntuales, ¿cambió qué canciones tiene o en
    // qué orden? Eso sí es aviso para todo el equipo.
    const firmaAntes = JSON.stringify(setlistAntes.map((e) => [e.cancionId, e.orden]));
    const firmaDespues = JSON.stringify(setlistDespues.map((e) => [e.cancionId, e.orden]));
    if (firmaAntes !== firmaDespues) {
      if (await dentroDelLimite(`${equipoId}_setlist_${actividadId}`)) return;
      const tokens = await tokensDelEquipo(equipoId);
      await notificar(tokens, {
        title: "📋 Setlist actualizado",
        body: `Se actualizó el setlist de "${despues.nombre}"`,
      });
    }
  },
);

/**
 * `Miembro.uid` pasa de null a tener valor cuando alguien "reclama" su
 * perfil invitado (crear equipo / unirse con código) — recién ahí es una
 * persona real usando la app, así que se avisa al resto del equipo. No
 * se le avisa a quien se acaba de unir: todavía no tenía token FCM
 * guardado antes de este mismo evento, no hay a quién mandarle nada.
 */
exports.onMiembroSeUnioAlEquipo = onDocumentUpdated(
  "equipos/{equipoId}/miembros/{miembroId}",
  async (event) => {
    const antes = event.data.before.data();
    const despues = event.data.after.data();
    if (antes.uid || !despues.uid) return;
    const { equipoId, miembroId } = event.params;

    const tokens = await tokensDelEquipo(equipoId, { excluirId: miembroId });
    await notificar(tokens, {
      title: "👋 Nuevo integrante",
      body: `${despues.nombre} se unió al equipo`,
    });
  },
);

/**
 * Corre cada 15 minutos y avisa las actividades de CUALQUIER equipo que
 * empiezan dentro de la próxima hora — `collectionGroup` busca en todas
 * las subcolecciones `actividades`, sin importar de qué equipo sean. La
 * ventana (50-70 min) es más ancha que el intervalo del scheduler para
 * no perderse ninguna por el redondeo de la corrida; `recordatoriosEnviados`
 * (clave `equipoId_actividadId`) evita mandar el mismo aviso dos veces si
 * dos corridas la agarran dentro de la ventana.
 */
exports.recordatorioAntesDelServicio = onSchedule("every 15 minutes", async () => {
  const ahora = Date.now();
  const desde = admin.firestore.Timestamp.fromMillis(ahora + 50 * 60 * 1000);
  const hasta = admin.firestore.Timestamp.fromMillis(ahora + 70 * 60 * 1000);

  const snapshot = await db
    .collectionGroup("actividades")
    .where("fecha", ">=", desde)
    .where("fecha", "<=", hasta)
    .get();

  for (const doc of snapshot.docs) {
    const equipoId = doc.ref.parent.parent.id;
    const clave = `${equipoId}_${doc.id}`;
    const yaEnviado = await db.collection("recordatoriosEnviados").doc(clave).get();
    if (yaEnviado.exists) continue;

    const actividad = doc.data();
    const tokens = await tokensDelEquipo(equipoId);
    await notificar(tokens, {
      title: "⏰ Recordatorio",
      body: `"${actividad.nombre}" empieza pronto`,
    });
    await db
      .collection("recordatoriosEnviados")
      .doc(clave)
      .set({ enviadoEn: admin.firestore.FieldValue.serverTimestamp() });
  }
});
