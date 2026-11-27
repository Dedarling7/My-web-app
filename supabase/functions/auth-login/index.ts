import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};
const json = (status: number, body: Record<string, unknown>) =>
  new Response(JSON.stringify(body), { status, headers: corsHeaders });

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json(405, { error: "Method not allowed" });

  try {
    const { identifier, password } = await req.json();
    if (typeof identifier !== "string" || typeof password !== "string" ||
        identifier.length > 160 || password.length < 1 || password.length > 256) {
      return json(400, { error: "Enter a valid account and password." });
    }

    const url = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const adminEmail = Deno.env.get("ADMIN_EMAIL");
    if (!url || !anonKey || !serviceKey || !adminEmail) {
      console.error("Missing auth-login function environment configuration");
      return json(500, { error: "Sign-in is not configured. Contact the administrator." });
    }

    const service = createClient(url, serviceKey, { auth: { persistSession: false } });
    const auth = createClient(url, anonKey, { auth: { persistSession: false } });
    const account = identifier.trim();
    let email = "";
    let expectedRole = "employee";
    let employeeId: string | null = null;

    if (account.toLowerCase() === "admin") {
      email = adminEmail;
      expectedRole = "admin";
    } else {
      employeeId = account.toUpperCase();
      const { data: employee, error } = await service
        .from("employees")
        .select("login_email,login_blocked,status")
        .eq("employee_id", employeeId)
        .maybeSingle();
      if (error || !employee || employee.login_blocked || employee.status === "Inactive") {
        return json(401, { error: "Account or password was not recognized, or access is blocked." });
      }
      email = employee.login_email;
    }

    const { data: signedIn, error: authError } = await auth.auth.signInWithPassword({ email, password });
    if (authError || !signedIn.session || !signedIn.user) {
      return json(401, { error: "Account or password was not recognized." });
    }
    const { data: profile, error: profileError } = await service
      .from("profiles")
      .select("role,employee_id,active")
      .eq("user_id", signedIn.user.id)
      .maybeSingle();
    if (profileError || !profile || !profile.active || profile.role !== expectedRole ||
        (employeeId && profile.employee_id !== employeeId)) {
      await auth.auth.signOut();
      return json(401, { error: "Account is not active or is not authorized for this portal." });
    }

    return json(200, {
      access_token: signedIn.session.access_token,
      refresh_token: signedIn.session.refresh_token,
      token_type: signedIn.session.token_type,
      expires_in: signedIn.session.expires_in,
      user: { id: signedIn.user.id, role: profile.role, employee_id: profile.employee_id },
    });
  } catch (error) {
    console.error("auth-login failed", error);
    return json(400, { error: "Unable to sign in. Check the account details and try again." });
  }
});
