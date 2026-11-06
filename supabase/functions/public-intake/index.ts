// NÄTVERKET public intake – server-side only
// Required Supabase secrets: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY,
// PUBLIC_SITE_URL, PUBLIC_INTAKE_ENABLED=true
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const headers = (origin: string, allowed: string) => ({
  "Access-Control-Allow-Origin": origin === allowed ? origin : allowed,
  "Access-Control-Allow-Headers": "content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Vary": "Origin",
  "Content-Type": "application/json",
});

Deno.serve(async (req) => {
  const allowed = Deno.env.get("PUBLIC_SITE_URL") ?? "";
  const origin = req.headers.get("origin") ?? "";
  const h = headers(origin, allowed);
  if (req.method === "OPTIONS") return new Response("ok", { headers: h });
  if (req.method !== "POST") return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405, headers: h });
  if (!allowed || origin !== allowed) return new Response(JSON.stringify({ error: "Origin not allowed" }), { status: 403, headers: h });
  if (Deno.env.get("PUBLIC_INTAKE_ENABLED") !== "true") return new Response(JSON.stringify({ error: "Formulären är ännu inte öppna." }), { status: 503, headers: h });

  try {
    const body = await req.json();
    // Honeypot: bots fill this hidden field. Return a neutral success response.
    if (typeof body.website === "string" && body.website.trim()) {
      return new Response(JSON.stringify({ ok: true }), { status: 200, headers: h });
    }
    const kind = body.kind;
    const email = String(body.email ?? "").trim().toLowerCase();
    const phone = String(body.phone ?? "").trim();
    const city = String(body.city ?? "").trim();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || email.length > 254) {
      return new Response(JSON.stringify({ error: "Ange en giltig e-postadress." }), { status: 400, headers: h });
    }
    if (phone.length > 40 || city.length > 100) {
      return new Response(JSON.stringify({ error: "Kontrollera telefonnummer och ort." }), { status: 400, headers: h });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceKey) throw new Error("Server configuration missing");
    const db = createClient(supabaseUrl, serviceKey, { auth: { persistSession: false } });

    if (kind === "request") {
      const name = String(body.name ?? "").trim();
      const title = String(body.title ?? "").trim();
      const description = String(body.description ?? "").trim();
      if (!name || !title || name.length > 160 || title.length > 160 || description.length > 3000) {
        return new Response(JSON.stringify({ error: "Fyll i namn, rubrik och en kort beskrivning." }), { status: 400, headers: h });
      }
      const customer = await db.from("customers").insert({
        name, customer_type: body.customer_type === "business" ? "business" : "private",
        email, phone: phone || null, city: city || null,
        notes: "Inkommen via publikt NÄTVERKET-formulär"
      }).select("id").single();
      if (customer.error) throw customer.error;
      const request = await db.from("requests").insert({
        customer_id: customer.data.id, title, description: description || null,
        city: city || null, location: city || null, status: "new"
      });
      if (request.error) {
        await db.from("customers").delete().eq("id", customer.data.id);
        throw request.error;
      }
    } else if (kind === "person") {
      const firstName = String(body.first_name ?? "").trim();
      const lastName = String(body.last_name ?? "").trim();
      const experience = String(body.experience ?? "").trim();
      if (!firstName || firstName.length > 80 || lastName.length > 100 || experience.length > 3000) {
        return new Response(JSON.stringify({ error: "Fyll i förnamn och kontrollera uppgifterna." }), { status: 400, headers: h });
      }
      const person = await db.from("people").insert({
        first_name: firstName, last_name: lastName || null, email,
        phone: phone || null, city: city || null,
        experience_description: experience || null
      });
      if (person.error) throw person.error;
    } else {
      return new Response(JSON.stringify({ error: "Okänd formulärtyp." }), { status: 400, headers: h });
    }
    return new Response(JSON.stringify({ ok: true }), { status: 200, headers: h });
  } catch (error) {
    console.error("public-intake error", error);
    return new Response(JSON.stringify({ error: "Det gick inte att skicka just nu. Försök igen senare." }), { status: 500, headers: h });
  }
});
