# C&R Premium Hospitality & Cleaning Services Portal

A responsive, offline-capable workforce and finance dashboard delivered as a single HTML app with an optional companion stylesheet. No package installation, server, or internet connection is required for normal use.

## Files

- `CR-Premium-Hospitality.html` — the app. CSS and JavaScript are embedded so the HTML continues to work when opened by itself.
- `style.css` — companion stylesheet for the app. If present next to the HTML file, it is loaded as an additional stylesheet; the embedded CSS is the standalone fallback.
- `README.md` — this guide.

Keep the files in the same folder if you want the companion stylesheet to load. Open the HTML file in a modern browser (Chrome, Edge, Firefox, or Safari).

## Demo access

**Admin demo:** username `admin`, password `CRadmin2026`. The initial demo recovery phrase is `CR-ADMIN-RESET`; change it in Admin settings after sign-in.

**Employee demo:** employee ID such as `CR-1001`; first-use password is the last four digits of that employee’s phone number. Employees can change their password and set a recovery phrase in **My profile & settings**.

These are demonstration credentials only. Do not put this local HTML app on a public web server or use it for real credentials, QIDs, passports, payroll, or other sensitive records. Browser storage and the login gate are not secure authentication.

## Main features

- Employee profiles, editable employee IDs, status and login blocking, QID/passport tracking, profile photos, document uploads, and Admin login-detail visibility.
- Employee request submission with Admin-configured request types and prices, workflow status, and a Paid/Not paid flag. Admin-confirmed request receipts flow into company finance calculations.
- Employee-scoped profile, request, payment, and document access, with an Admin directory and finance/reporting views.
- Direct or broadcast Admin messages to employees.
- Company budget additions, expenses, confirmed request revenue, available budget, and profit tracking.
- Finance charts: a six-month grouped monthly trend of budget additions, confirmed request payments, and expenses (QAR); and a payment-method breakdown showing transaction counts and per-currency totals.
- Budget and employee payment report export to Excel-compatible CSV or print-ready PDF. CSV opens in Excel and spreadsheet apps; PDF is produced using the browser’s Print → Save as PDF flow.
- JSON backup and restore under **Admin settings**.

## Finance chart interpretation

The budget trend chart uses the prior six calendar months, including the current month. It plots budget additions, request amounts explicitly marked Paid, and recorded expenses as three separate QAR series. The payment breakdown counts payment records by method (Cash, Bank, Check, Card, or other method) and lists totals separately by currency, so QAR and USD are not combined.

## Data storage and backups

Records are stored in the browser’s local storage for the file’s origin/profile on that device. Different browsers or devices do not automatically share data. Use **Admin settings → Export backup** regularly and keep the resulting JSON file somewhere safe. Importing a backup replaces the current local records. Uploaded files consume browser storage; this demo limits a single document upload to 3 MB.

## Responsive use

The interface adapts to desktop, tablet, and mobile widths. Tables support touch-friendly horizontal scrolling, while the compact Admin employee directory prioritizes employee, QID, nationality, requests, and payment totals on narrow screens.

## Editing and redistribution

The HTML is self-contained and can be customized directly. `style.css` mirrors the embedded CSS as a companion file; if you change the design, update both files to keep them aligned.


## Publish on GitHub Pages

1. Create a GitHub repository and upload the contents of this folder to the repository root.
2. Open **Settings → Pages** in the repository.
3. Under **Build and deployment**, choose **Deploy from a branch**, select the default branch (usually `main`) and the `/ (root)` folder, then save.
4. Wait for the Pages deployment and open the published URL. `index.html` is the site entry point.

The site is static and has no build step. Keep `index.html` and `style.css` together in the repository root. The HTML also includes embedded CSS and JavaScript as an offline fallback. No separate `assets/` directory is required because the app uses no external image or font assets.

**Hosting limitation:** GitHub Pages hosts the static interface, not a secure backend. Browser local storage remains specific to each visitor’s browser/device; staff on different devices will not share live data. Do not publish real employee credentials, identity documents, or financial records in a static GitHub repository. For a real multi-user deployment, connect a secure backend, access control, and protected document storage.
