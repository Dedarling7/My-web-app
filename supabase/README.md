# Supabase backend setup for C&R Premium

This folder is a **backend setup scaffold** for adding shared online data to the GitHub Pages site. The current HTML remains browser-local until the site is connected to a real Supabase project and the authenticated data adapter is completed. Do not treat this scaffold alone as an active sync implementation.

## Security model

- Supabase Auth owns password hashes and sessions; no employee or Admin plaintext passwords belong in browser storage or SQL rows.
- The website may contain the Supabase Project URL and publishable/anon key. Those are public client configuration values and are safe only because Row Level Security is enabled.
- **Never put `SUPABASE_SERVICE_ROLE_KEY` in `index.html`, `style.css`, GitHub Actions logs, or a public repository.** It belongs only in Edge Function secrets.
- Employee QIDs, passport data, payment records, messages, and document files are protected by Auth/RLS. The Storage bucket is private.
- The provided `auth-login` Edge Function maps Employee ID (or the `admin` username) to a Supabase Auth email, verifies the password through Supabase Auth, checks the matching active role, and returns an Auth session. It does not expose the service-role key. The browser adapter source is also included as `frontend-client.js`; the Pages `index.html` has the adapter inlined so no extra runtime file is required.

## Create the Supabase project

1. Create a Supabase project at [supabase.com](https://supabase.com/) and save its database password privately.
2. Before running the installer, create the Admin and employee Auth users in **Authentication → Users → Add user**. Set temporary passwords privately; the SQL does not create or store passwords.
3. In **Project Settings → API**, copy the Project URL and publishable/anon key for later front-end configuration. Do not copy or publish the service-role key.
4. Open [`SQL-EDITOR-INSTALL.sql`](SQL-EDITOR-INSTALL.sql), replace `v_admin_email` with the Auth Admin email, and replace `v_employees := '[]'::jsonb` with one JSON object per actual employee account. Paste the entire file into **SQL Editor → New query** and run it once on this new project. It creates the tables, RLS policies, safe team-directory/count RPCs, request-price enforcement, private document bucket, Admin profile, employee rows, and employee profiles. The bucket/policies are created, but actual files must be uploaded after sign-in.
5. In **Authentication → Providers**, enable Email/password sign-in. Configure a strong password policy, email confirmations as appropriate, and password-reset email templates. In **Authentication → URL Configuration**, set the Site URL and allowed redirect URLs to the final GitHub Pages site (for example `https://OWNER.github.io/REPOSITORY/`).

## Create the first Admin and employee Auth accounts

The combined SQL installer’s final `DO` block links those pre-created Auth users to the Admin and employee records. Its sample employee object is only a template; replace it with your real staff data. The employee Auth email must match `login_email`. Keep the populated SQL private and do not commit it to a public GitHub repository. Existing demo passwords are not migrated.

## Deploy Employee ID / Admin username sign-in

The web app uses the `auth-login` function to retain Employee ID + password sign-in without exposing account email lookups or the service key in the browser.

1. Install the [Supabase CLI](https://supabase.com/docs/guides/cli) locally and sign in: `supabase login`.
2. Link this folder to the project using the project reference from the Supabase dashboard: `supabase link --project-ref YOUR_PROJECT_REF`.
3. Set the Admin Auth email and the final site redirect URL: `supabase secrets set ADMIN_EMAIL=admin@example.com APP_SITE_URL=https://OWNER.github.io/REPOSITORY/` (use the Admin Auth email and your actual GitHub Pages URL). Ensure that redirect URL is also allowed under Supabase Auth URL Configuration.
4. Deploy both unauthenticated entry functions: `supabase functions deploy auth-login --no-verify-jwt` and `supabase functions deploy auth-recovery --no-verify-jwt`.
5. Confirm the function is healthy before connecting the browser app. The function relies on Supabase’s standard `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` Edge Function secrets; Supabase supplies those to its own function runtime. Never copy the service-role key into the static site.

`config.toml` sets `verify_jwt = false` only for the sign-in and password-reset entry endpoints because a user has no session before those requests. The recovery endpoint always returns the same generic response to avoid confirming whether an account exists. The function validates credentials with Supabase Auth and returns only that user’s session. All data APIs still require authenticated sessions and RLS.

## Next connection step

The GitHub Pages and standalone HTML files are now configured with the supplied Project URL and publishable key, with Auth, RLS-backed queries, and private Storage integration. Apply the schema, provision Auth users/profiles, and deploy both Edge Functions as above; until those project-side steps are complete, **cloud login and cross-device sync will fail because the project currently has no portal tables or deployed functions**. Existing local demo records are not automatically imported.

Password resets use the `auth-recovery` Edge Function and a verified Supabase Auth email link. Add the final GitHub Pages URL to Supabase Auth’s redirect allow-list and set it as `APP_SITE_URL`. No plaintext password or recovery phrase is stored by the cloud app. Admins should be able to reset an employee password, not read the actual password; secure authentication systems never reveal password values.
