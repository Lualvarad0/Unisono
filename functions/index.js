const { setGlobalOptions } = require("firebase-functions");
const { onDocumentUpdated, onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
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

/** Tokens FCM de todo el equipo, salvo quien se excluya (ej. quien generó el aviso). */
async function tokensDelEquipo({ excluirId } = {}) {
  const snapshot = await db.collection("miembros").get();
  return snapshot.docs
    .filter((doc) => doc.id !== excluirId)
    .map((doc) => doc.data().fcmToken)
    .filter(Boolean);
}

/**
 * El líder inicia "Modo en vivo": `cancionActivaId` pasa de vacío a tener
 * valor. Es el mismo campo que ya usa Vista en vivo (Firestore en tiempo
 * real) para que los celulares sepan qué mostrar — acá solo se avisa
 * al resto que arrancó.
 */
exports.onModoEnVivoIniciado = onDocumentUpdated("actividades/{actividadId}", async (event) => {
  const antes = event.data.before.data();
  const despues = event.data.after.data();
  if (antes.cancionActivaId || !despues.cancionActivaId) return;

  const tokens = await tokensDelEquipo({});
  await notificar(tokens, {
    title: "🔴 Modo en vivo",
    body: `El líder inició la transmisión de "${despues.nombre}"`,
  });
});

/**
 * Setlist armado, cambiado, o con una canción/cantante reasignado — los
 * tres pasan por escrituras del mismo documento `Actividad`, así que se
 * comparan `before`/`after` acá en vez de triplicar el trigger.
 */
exports.onSetlistEscrito = onDocumentWritten("actividades/{actividadId}", async (event) => {
  const despuesExiste = event.data.after.exists;
  if (!despuesExiste) return;
  const despues = event.data.after.data();

  const antesExiste = event.data.before.exists;
  if (!antesExiste) {
    if ((despues.setlist || []).length === 0) return;
    const tokens = await tokensDelEquipo({});
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
  for (const entrada of asignaciones) {
    const miembro = await db.collection("miembros").doc(entrada.cantanteId).get();
    const token = miembro.data()?.fcmToken;
    if (!token) continue;
    const cancion = await db.collection("canciones").doc(entrada.cancionId).get();
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
    const tokens = await tokensDelEquipo({});
    await notificar(tokens, {
      title: "📋 Setlist actualizado",
      body: `Se actualizó el setlist de "${despues.nombre}"`,
    });
  }
});

/**
 * `Miembro.uid` pasa de null a tener valor cuando alguien "reclama" su
 * perfil invitado (Selección de rol) — recién ahí es una persona real
 * usando la app, así que se avisa al resto del equipo. No se le avisa a
 * quien se acaba de unir: todavía no tenía token FCM guardado antes de
 * este mismo evento, no hay a quién mandarle nada.
 */
exports.onMiembroSeUnioAlEquipo = onDocumentUpdated("miembros/{miembroId}", async (event) => {
  const antes = event.data.before.data();
  const despues = event.data.after.data();
  if (antes.uid || !despues.uid) return;

  const tokens = await tokensDelEquipo({ excluirId: event.params.miembroId });
  await notificar(tokens, {
    title: "👋 Nuevo integrante",
    body: `${despues.nombre} se unió al equipo`,
  });
});

/**
 * Corre cada 15 minutos y avisa las actividades que empiezan dentro de
 * la próxima hora. La ventana (50-70 min) es más ancha que el intervalo
 * del scheduler para no perderse ninguna por el redondeo de la corrida;
 * `recordatoriosEnviados` evita mandar el mismo aviso dos veces si dos
 * corridas la agarran dentro de la ventana.
 */
exports.recordatorioAntesDelServicio = onSchedule("every 15 minutes", async () => {
  const ahora = Date.now();
  const desde = admin.firestore.Timestamp.fromMillis(ahora + 50 * 60 * 1000);
  const hasta = admin.firestore.Timestamp.fromMillis(ahora + 70 * 60 * 1000);

  const snapshot = await db
    .collection("actividades")
    .where("fecha", ">=", desde)
    .where("fecha", "<=", hasta)
    .get();

  for (const doc of snapshot.docs) {
    const yaEnviado = await db.collection("recordatoriosEnviados").doc(doc.id).get();
    if (yaEnviado.exists) continue;

    const actividad = doc.data();
    const tokens = await tokensDelEquipo({});
    await notificar(tokens, {
      title: "⏰ Recordatorio",
      body: `"${actividad.nombre}" empieza pronto`,
    });
    await db
      .collection("recordatoriosEnviados")
      .doc(doc.id)
      .set({ enviadoEn: admin.firestore.FieldValue.serverTimestamp() });
  }
});
