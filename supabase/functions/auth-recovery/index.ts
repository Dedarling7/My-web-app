import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const headers = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};
const json = (status: number, body: Record<string, unknown>) =>
  new Response(JSON.stringify(body), { status, headers });

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers });
  if (req.method !== "POST") return json(405, { error: "Method not allowed" });
  try {
    const { identifier } = await req.json();
    if (typeof identifier !== "string" || identifier.trim().length < 1 || identifier.length > 160)
      return json(400, { error: "Enter your account ID." });
    const url = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const adminEmail = Deno.env.get("ADMIN_EMAIL");
    const redirectTo = Deno.env.get("APP_SITE_URL");
    if (!url || !anonKey || !serviceKey || !adminEmail || !redirectTo) {
      console.error("Missing auth-recovery function configuration");
      return json(500, { error: "Password recovery is not configured." });
    }

    const account = identifier.trim();
    const service = createClient(url, serviceKey, { auth: { persistSession: false } });
    let email = "";
    if (account.toLowerCase() === "admin") {
      email = adminEmail;
      const { data } = await service.from("profiles").select("user_id")
        .eq("role", "admin").eq("active", true).limit(1).maybeSingle();
      if (!data) email = "";
    } else {
      const employeeId = account.toUpperCase();
      const { data: employee } = await service.from("employees")
        .select("login_email,login_blocked,status").eq("employee_id", employeeId).maybeSingle();
      const { data: profile } = await service.from("profiles")
        .select("user_id").eq("employee_id", employeeId).eq("role", "employee").eq("active", true).maybeSingle();
      if (employee && profile && !employee.login_blocked && employee.status !== "Inactive")
        email = employee.login_email;
    }

    // Return the same response whether the account exists or not.
    if (email) {
      const auth = createClient(url, anonKey, { auth: { persistSession: false } });
      const { error } = await auth.auth.resetPasswordForEmail(email, { redirectTo });
      if (error) console.error("Auth recovery dispatch failed", error.message);
    }
    return json(200, { message: "If the account is active and has a valid email, a password reset link has been sent." });
  } catch (error) {
    console.error("auth-recovery failed", error);
    return json(400, { error: "Unable to request password recovery." });
  }
});
