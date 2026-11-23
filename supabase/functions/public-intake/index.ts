import { createClient } from "npm:@supabase/supabase-js@2.57.0";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const INTAKE_ENABLED = false; // Do not accept personal data until the controller/privacy notice is finalized.
const ALLOWED_ORIGINS = new Set(["https://natverket-app.vercel.app"]);
const corsHeaders = { "Access-Control-Allow-Methods": "POST, OPTIONS", "Access-Control-Allow-Headers": "content-type", "Vary": "Origin" };
function json(body: unknown, status: number, origin: string) {
  return new Response(JSON.stringify(body), { status, headers: { ...corsHeaders, "Access-Control-Allow-Origin": origin, "Content-Type": "application/json", "Cache-Control": "no-store" } });
}
async function hashIp(ip: string, secret: string) {
  const key = await crypto.subtle.importKey("raw", new TextEncoder().encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const signature = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(ip));
  return Array.from(new Uint8Array(signature)).map((b) => b.toString(16).padStart(2, "0")).join("");
}
Deno.serve(async (req) => {
  const origin = req.headers.get("origin") ?? "";
  if (!ALLOWED_ORIGINS.has(origin)) return new Response("Origin not allowed", { status: 403 });
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: { ...corsHeaders, "Access-Control-Allow-Origin": origin } });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405, origin);
  if (!INTAKE_ENABLED) return json({ error: "Företagsintresse öppnar när integritetsinformationen är färdigställd." }, 503, origin);
  const length = Number(req.headers.get("content-length") ?? "0");
  if (length > 8000) return json({ error: "Förfrågan är för stor." }, 413, origin);
  try {
    const raw = await req.text();
    if (raw.length > 8000) return json({ error: "Förfrågan är för stor." }, 413, origin);
    const payload = JSON.parse(raw);
    if (!payload || typeof payload !== "object" || Array.isArray(payload)) return json({ error: "Ogiltig förfrågan." }, 400, origin);
    if (payload.kind !== "company") return json({ error: "Endast företagsintresse tas emot i denna lanseringsfas." }, 403, origin);
    const company_name = typeof payload.company_name === "string" ? payload.company_name.trim().slice(0, 180) : "";
    const email = typeof payload.email === "string" ? payload.email.trim().toLowerCase().slice(0, 254) : "";
    const interest_type = typeof payload.interest_type === "string" ? payload.interest_type.trim() : "";
    const instagram_handle = typeof payload.instagram === "string" ? payload.instagram.trim().slice(0, 80) : "";
    if (company_name.length < 2 || !/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email) || !["buy", "sell", "both"].includes(interest_type) || (instagram_handle !== "" && !/^@?[A-Za-z0-9._]{1,30}$/.test(instagram_handle) && !/^https?:\/\/(www\.)?instagram\.com\/[A-Za-z0-9._]{1,30}\/?$/i.test(instagram_handle))) {
      return json({ error: "Kontrollera företagsnamn, e-postadress och intresse." }, 400, origin);
    }
    const ip = req.headers.get("cf-connecting-ip") ?? req.headers.get("x-real-ip") ?? req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "unknown";
    const ipHash = await hashIp(ip, SERVICE_KEY);
    const supabase = createClient(SUPABASE_URL, SERVICE_KEY, { auth: { persistSession: false, autoRefreshToken: false } });
    await supabase.from("public_intake_rate_limits").delete().lt("created_at", new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString());
    const { count, error: countError } = await supabase.from("public_intake_rate_limits").select("id", { count: "exact", head: true }).eq("ip_hash", ipHash).gte("created_at", new Date(Date.now() - 15 * 60 * 1000).toISOString());
    if (countError) throw countError;
    if ((count ?? 0) >= 5) return json({ error: "För många försök. Vänta en stund och försök igen." }, 429, origin);
    const { error: rateError } = await supabase.from("public_intake_rate_limits").insert({ ip_hash: ipHash });
    if (rateError) throw rateError;
    const { data, error } = await supabase.rpc("submit_company_application", {
      p_payload: { company_name, email, interest_type, instagram_handle, privacy_notice_version: "company-interest-minimal-2026-11-23-v1" }
    });
    if (error) throw error;
    return json({ ok: true, reference: data }, 200, origin);
  } catch (_error) {
    return json({ error: "Vi kunde inte ta emot uppgifterna just nu. Försök igen senare." }, 500, origin);
  }
});
