
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { JWT } from 'npm:google-auth-library@9'

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

Deno.serve(async () => {

  const today = new Date().toISOString().slice(0, 10);

  const { data: tareas, error: errorTareas } = await supabase
    .from("TAREAS")
    .select("id,nombre,descripcion,user_id")
    .eq("fechaFinalizacion", today);

  if (errorTareas) {
    return new Response(JSON.stringify(errorTareas), { status: 500 });
  }

  if (!tareas || tareas.length == 0) {
    return new Response(JSON.stringify({ message: "No hay tareas para hoy" }));
  }

  // 1. Obtener la variable de entorno
  const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");

  if (!serviceAccountJson) {
    return new Response(JSON.stringify({ error: "FIREBASE_SERVICE_ACCOUNT variable de entorno no encontrada" }), { status: 500 });
  }

  // 2. Parsear el JSON para obtener el objeto serviceAccount
  let serviceAccount: any;
  try {
    serviceAccount = JSON.parse(serviceAccountJson);
  } catch (e) {
    return new Response(JSON.stringify({ error: "Error al parsear FIREBASE_SERVICE_ACCOUNT" }), { status: 500 });
  }

  const accessToken = await getAccessToken({
    clientEmail: serviceAccount.client_email,
    privateKey: serviceAccount.private_key.replace(/\\n/g, '\n'), // Importante: Reemplazar los '\\n' por saltos de línea reales
  })

  const IMAGE_URL = "https://fynix-app.vercel.app/assets/assets/fynix_logo.png";

  for (const tarea of tareas) {

    const project_id = Deno.env.get("FIREBASE_PROJECT_ID")

    const { data: profile } = await supabase
      .from("PROFILES")
      .select("fcm_token")
      .eq("id", tarea.user_id)
      .single();

    if (!profile?.fcm_token) continue;

    const fcmRes = await fetch(`https://fcm.googleapis.com/v1/projects/${project_id}/messages:send`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: { 
          token: profile.fcm_token,
          notification: {
            title: "📅 Recordatorio",
            body: `Tienes una tarea pendiente para hoy: ${tarea.nombre}`
          }
        }
      })
    });

    if (!fcmRes.ok) {
        const errorData = await fcmRes.json();
        console.error(`Fallo al enviar FCM para tarea ${tarea.id}:`, errorData);
    } else {
        console.log(`FCM enviado con éxito para tarea ${tarea.id}.`);
    }

  }

  return new Response(JSON.stringify({
    message: `Intentos de notificación para ${tareas.length} tareas.`,
    count: tareas.length
  }), {
    headers: { 'Content-Type': 'application/json' }
  });

});


const getAccessToken = ({
  clientEmail,
  privateKey
}: {
  clientEmail: string,
  privateKey: string
}): Promise<string> => {
  return new Promise((resolve, reject) => {
    const jwtClient = new JWT({
      email: clientEmail,
      key: privateKey,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    })
    jwtClient.authorize((err, tokens) => {
      if (err) {
        reject(err)
        return;
      }
      resolve(tokens!.access_token!)
    })
  })
}
