# C&R Premium Hospitality & Cleaning Services Portal

A responsive, offline-capable workforce and finance dashboard delivered as a single HTML app with an optional companion stylesheet.

## Project files

- `index.html` — static app entry point; styles and JavaScript are embedded as a single-file fallback.
- `style.css` — companion stylesheet loaded when kept beside `index.html`.
- `supabase/` — initial schema, secure login Edge Function, and setup guide for a future shared-data backend.
- `.nojekyll` — turns off Jekyll processing for GitHub Pages.

## Run locally

Open `index.html` in a modern browser. Keep it beside `style.css` for the companion CSS.

## Publish on GitHub Pages

1. Create a GitHub repository and upload the contents of this folder to its root.
2. Go to **Settings → Pages**.
3. Select **Deploy from a branch**, choose the default branch (usually `main`) and `/ (root)`, then save.
4. After deployment, open the GitHub Pages URL. `index.html` is the entry point; no build step is needed.

## Important: online synchronization is not active yet

The current frontend still uses browser local storage and does **not** synchronize between devices. GitHub Pages serves static files only. The `supabase/` directory is a setup scaffold; create a Supabase project, apply its schema, configure Auth, and then connect the frontend before shared sync will work. Follow [`supabase/README.md`](supabase/README.md).

Do not publish real employee credentials, QIDs, passports, uploaded documents, payments, or financial records while using the local demo. Its login is not production-grade security. Never put a Supabase service-role key in this repository or frontend.

## Local demo features

- Employee profiles, editable IDs, status/login blocking, QID/passport expiry tracking, profile images and document controls.
- Requests with Admin-configured fees, progress and payment-status management; Admin payments and employee-scoped views.
- Direct/broadcast messages, company budgets/expenses/profit, and finance trend/payment charts.
- Budget and payment reports as Excel-compatible CSV or print-ready PDF; JSON local backup/restore.
- Responsive desktop/tablet/mobile layouts.
