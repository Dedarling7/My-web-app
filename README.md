# C&R Premium Hospitality & Cleaning Services Portal

Responsive employee and finance portal with an online Supabase connection configured for the C&R project.

## Files

- `index.html` — GitHub Pages entry point; includes the app and browser-side Supabase integration.
- `style.css` — companion responsive stylesheet.
- `supabase/SQL-EDITOR-INSTALL.sql` — one-paste SQL Editor installer plus Admin/employee profile bootstrap (requires Auth users created first).
- `supabase/schema.sql` — schema source, including tables, RLS policies, private storage, and request-price enforcement.
- `supabase/functions/auth-login/index.ts` — secure Employee ID/Admin username login bridge.
- `supabase/frontend-client.js` — readable copy of the adapter embedded inside `index.html`.
- `supabase/README.md` — project setup, account provisioning and deployment instructions.

## Setup still required before online sign-in/sync works

The HTML is configured with the supplied Project URL and **publishable** key. I verified the project responds, but its `profiles` table and `auth-login` function currently return 404/not-found, so the shared portal is **not live yet**. Run `supabase/schema.sql` in the project's SQL Editor, enable Email/Password Auth, create the Admin and employee Auth users/profiles, set the `ADMIN_EMAIL` Edge Function secret, and deploy `auth-login`. Detailed steps are in [`supabase/README.md`](supabase/README.md). Do not put a service-role key in the repository or browser.

The HTML deliberately no longer accepts the old demo passwords or stores cloud passwords/recovery phrases locally. Real account credentials must be provisioned in Supabase Auth. New employees added from the portal need their Auth user and `profiles` row linked before they can log in.

## GitHub Pages

Upload this folder's contents to a GitHub repository, then select **Settings → Pages → Deploy from a branch**, the `main` branch, and `/ (root)`. No build step is needed.
