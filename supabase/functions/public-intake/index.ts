import { createClient } from "npm:@supabase/supabase-js@2.57.0";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const LEGAL_BASIS = Deno.env.get("PUBLIC_INTAKE_LEGAL_BASIS") ?? "";
const PRIVACY_NOTICE_VERSION = Deno.env.get("PUBLIC_PRIVACY_NOTICE_VERSION") ?? "";

// Hard gate: do not accept personal data until legal, security and browser tests are signed off.
const INTAKE_ENABLED = false;
const ALLOWED_ORIGINS = new Set(["https://natverket-app.vercel.app"]);
const corsHeaders = {
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "content-type, authorization, x-client-info, apikey",
  "Vary": "Origin",
};
const emailPattern = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;

function json(body: unknown, status: number, origin: string) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Access-Control-Allow-Origin": origin,
      "Content-Type": "application/json",
      "Cache-Control": "no-store",
    },
  });
}

function value(payload: Record<string, unknown>, key: string, max: number): string {
  const raw = payload[key];
  return typeof raw === "string" ? raw.trim().slice(0, max) : "";
}

async function hashIp(ip: string, secret: string) {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(ip));
  return Array.from(new Uint8Array(signature)).map((b) => b.toString(16).padStart(2, "0")).join("");
}

Deno.serve(async (req) => {
  const origin = req.headers.get("origin") ?? "";
  if (!ALLOWED_ORIGINS.has(origin)) return new Response("Origin not allowed", { status: 403 });

  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: { ...corsHeaders, "Access-Control-Allow-Origin": origin },
    });
  }
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405, origin);

  // This remains deliberately closed in the production deployment.
  if (!INTAKE_ENABLED) {
    return json({ error: "Formulären är inte öppna ännu. Inga uppgifter har tagits emot." }, 503, origin);
  }
  if (!LEGAL_BASIS || !PRIVACY_NOTICE_VERSION) {
    return json({ error: "Integritetsinformationen är inte färdigställd." }, 503, origin);
  }

  const length = Number(req.headers.get("content-length") ?? "0");
  if (length > 8000) return json({ error: "Förfrågan är för stor." }, 413, origin);

  try {
    const raw = await req.text();
    if (raw.length > 8000) return json({ error: "Förfrågan är för stor." }, 413, origin);
    const payload = JSON.parse(raw) as Record<string, unknown>;
    if (!payload || typeof payload !== "object" || Array.isArray(payload)) {
      return json({ error: "Ogiltig förfrågan." }, 400, origin);
    }

    // Honeypot: bots filling this field receive a neutral success without a database write.
    if (value(payload, "website", 300) !== "") return json({ ok: true }, 200, origin);

    const kind = value(payload, "kind", 20);
    if (!["company", "request", "person"].includes(kind)) {
      return json({ error: "Okänd typ av intresseanmälan." }, 400, origin);
    }

    const ip = req.headers.get("cf-connecting-ip")
      ?? req.headers.get("x-real-ip")
      ?? req.headers.get("x-forwarded-for")?.split(",")[0]?.trim()
      ?? "unknown";
    const ipHash = await hashIp(ip, SERVICE_KEY);
    const supabase = createClient(SUPABASE_URL, SERVICE_KEY, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const cutoff = new Date(Date.now() - 15 * 60 * 1000).toISOString();
    const cleanupCutoff = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
    await supabase.from("public_intake_rate_limits").delete().lt("created_at", cleanupCutoff);
    const { count, error: countError } = await supabase
      .from("public_intake_rate_limits")
      .select("id", { count: "exact", head: true })
      .eq("ip_hash", ipHash)
      .gte("created_at", cutoff);
    if (countError) throw countError;
    if ((count ?? 0) >= 5) {
      return json({ error: "För många försök. Vänta en stund och försök igen." }, 429, origin);
    }
    const { error: rateError } = await supabase.from("public_intake_rate_limits").insert({ ip_hash: ipHash });
    if (rateError) throw rateError;

    let reference: string | null = null;
    if (kind === "company") {
      const companyPayload = {
        company_name: value(payload, "company_name", 180),
        organization_number: value(payload, "organization_number", 24),
        industry: value(payload, "industry", 120),
        company_website: value(payload, "company_website", 300),
        contact_name: value(payload, "contact_name", 160),
        email: value(payload, "email", 254).toLowerCase(),
        phone: value(payload, "phone", 40),
        city: value(payload, "city", 100),
        services: value(payload, "services", 2000),
        interest_type: value(payload, "interest_type", 10),
        instagram: value(payload, "instagram", 80),
        legal_basis: LEGAL_BASIS,
        privacy_notice_version: PRIVACY_NOTICE_VERSION,
      };
      if (!companyPayload.company_name || !emailPattern.test(companyPayload.email)
        || !["buy", "sell", "both"].includes(companyPayload.interest_type)) {
        return json({ error: "Kontrollera företagsnamn, e-postadress och intresse." }, 400, origin);
      }
      const { data, error } = await supabase.rpc("submit_company_application", { p_payload: companyPayload });
      if (error) throw error;
      reference = data;
    } else if (kind === "request") {
      const requestPayload = {
        name: value(payload, "name", 160),
        email: value(payload, "email", 254).toLowerCase(),
        phone: value(payload, "phone", 40),
        city: value(payload, "city", 100),
        customer_type: value(payload, "customer_type", 20),
        service_category: value(payload, "service_category", 120),
        title: value(payload, "title", 160),
        description: value(payload, "description", 3000),
      };
      if (!requestPayload.name || !emailPattern.test(requestPayload.email)
        || !["private", "business"].includes(requestPayload.customer_type)
        || !requestPayload.service_category || !requestPayload.title) {
        return json({ error: "Kontrollera namn, e-postadress och vald kategori." }, 400, origin);
      }
      const { data, error } = await supabase.rpc("submit_public_request", {
        p_payload: requestPayload,
        p_legal_basis: LEGAL_BASIS,
        p_notice_version: PRIVACY_NOTICE_VERSION,
      });
      if (error) throw error;
      reference = data;
    } else {
      const personPayload = {
        first_name: value(payload, "first_name", 80),
        last_name: value(payload, "last_name", 100),
        email: value(payload, "email", 254).toLowerCase(),
        phone: value(payload, "phone", 40),
        city: value(payload, "city", 100),
        interest_category: value(payload, "interest_category", 120),
        work_type: value(payload, "work_type", 60),
        availability: value(payload, "availability", 60),
        experience: value(payload, "experience", 2500),
      };
      if (!personPayload.first_name || !emailPattern.test(personPayload.email)) {
        return json({ error: "Kontrollera förnamn och e-postadress." }, 400, origin);
      }
      const { data, error } = await supabase.rpc("submit_person_application", {
        p_payload: personPayload,
        p_legal_basis: LEGAL_BASIS,
        p_notice_version: PRIVACY_NOTICE_VERSION,
      });
      if (error) throw error;
      reference = data;
    }

    return json({ ok: true, reference }, 200, origin);
  } catch (_error) {
    return json({ error: "Vi kunde inte ta emot uppgifterna just nu. Försök igen senare." }, 500, origin);
  }
});
