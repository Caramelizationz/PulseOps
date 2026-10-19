# PulseOps — Content Command Center

Private source repository for the AI Operations Lead **Track B** assessment and prototype. This repository contains the **latest hosted source** for both separately deployed frontends.

## Applications

| Application | Source | Hosted URL | Data |
| --- | --- | --- | --- |
| Public assessment demo | `apps/demo/index.html` | https://pulseops-command-center-demo.vercel.app/login | Synthetic browser-session records and demo-only passcode |
| Secure operations workspace | `apps/secure-workspace/index.html` | https://pulseops-secure-workspace.vercel.app/login | Supabase Auth, PostgreSQL, RLS and private media bucket |

**Security:** `demo123` is intentionally a non-secret *public sandbox* passcode. Never use it for a real Founder account. Supabase publishable keys may appear in browser code; NEVER commit Supabase secret/service-role keys, n8n API keys, Google OAuth tokens, credentials, session exports, or company/private videos.

## Clone locally

```bash
git clone https://github.com/Caramelizationz/PulseOps.git
cd PulseOps
```

Both applications currently use self-contained static HTML/CSS/JS, so a static development server is sufficient:

```bash
cd apps/demo
python -m http.server 8080
```

Then visit http://localhost:8080/login (your local server may require a SPA route fallback for deep links, see `vercel.json`). The secure workspace also requires configuring the localhost redirect URL in Supabase Auth.

## Repo layout

- `apps/demo/`: public sandbox with simulated Founder/Editor actions and synthetic content.
- `apps/secure-workspace/`: authenticated Supabase client UI and database-enforced roles.
- `supabase/`: existing project schema documentation and migrations guidance.
- `n8n/`: planned workflow integration and security contract; **not connected**.
- `docs/`: Codex integration plan, QA status and submission context.

## Current status

- The two sites are already deployed via **direct Vercel uploads**, not GitHub-connected deployment.
- Supabase project: `zpeswzwyltgjhyvtqsoa`. Keep using the existing personal project; do not touch Cynergists or the `caramelization` portfolio.
- Private database has four PulseOps tables and role-gated RPCs. A Founder account exists. Editor onboarding and real multi-user browser tests are still pending.
- Google Drive/n8n and WhatsApp **are not live**. A future `WhiskeySockets/Baileys` proof of concept is proposed only; it is unofficial and carries account/ToS risk.
- The original Node/SQLite reference prototype **is not** the secure hosted backend. Do not replace either deployed UI with that older code.
- Codex should use `docs/CODEX_N8N_HANDOFF.md` before creating workflows.

## Git / Vercel integration

Vercel production aliases are maintained as-is. The existing projects are not yet Git-linked. When connecting them to this monorepo, configure separate roots `apps/demo` and `apps/secure-workspace`, retain SPA rewrites, and validate before changing production deployments.

## Integrity

This is an assessment prototype with an intentionally public demo. Do not claim WhatsApp posting, Channel analytics, Google Drive monitoring, live n8n executions, or 40 real posts/day.
