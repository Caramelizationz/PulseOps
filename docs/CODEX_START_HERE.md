# Codex — Start Here (PulseOps)

**Clone the existing private repository; do not create a second one.**

```bash
git clone https://github.com/Caramelizationz/PulseOps.git
cd PulseOps
```

Read `AGENTS.md`, `README.md`, `docs/CODEX_N8N_HANDOFF.md`, `docs/QA_REPORT.md`, `supabase/schema_reference.sql`, and `supabase/migrations/README.md` in full before coding.

## Objective

You have authorized n8n API credentials in your own Codex environment. **Build and prove a working end-to-end integration**, not just diagrams or JSON drafts, from a permitted Google Drive video upload through n8n and Supabase into the secure PulseOps operations dashboard. Ask for the specific Google Drive folder and sender permissions when unavailable; never invent them.

### Scope

- Private repo: `Caramelizationz/PulseOps`; branch from `main`.
- Public sandbox: https://pulseops-command-center-demo.vercel.app/login — synthetic demo data; `demo123` is not real authentication.
- Secure app: https://pulseops-secure-workspace.vercel.app/login — real Supabase Auth/Postgres/RLS.
- Supabase: project `zpeswzwyltgjhyvtqsoa`.
- Personal Vercel workspace `Thesis' projects`; two existing project names `pulseops-command-center-demo` and `pulseops-secure-workspace`. Deployments were uploaded directly, NOT yet linked to GitHub. Do not assume a `git push` deploys code; connect correct monorepo roots safely and verify production URLs before making changes.
- **Never modify Cynergists or personal portfolio project `caramelization`.**

### Milestones

1. W01: Google Drive completed MP4 → n8n workflow → idempotent Supabase source clip record → visible job/status in secure dashboard; duplicate triggers must not duplicate records.
2. W02: 120m raw idle, 45m approval delay, 90m revision delay, overdue publication, missing 1h/4h/12h/23h view checkpoint alerts. Durable, deduplicated notifications; exclude `is_demo=true` from real sends.
3. W03: Secure, server-only event-outbox dispatcher (claim/lease/ack, retries) for Founder approval, revision, editor submit and start; no n8n bypass of Founder authorization.
4. W04: Manual WhatsApp Channel publication + reminder-based view checkpoint entry; only observed cumulative views.
5. W05: Optional morning digest after recipient, timezone, and time are confirmed.

### Security and WhatsApp

Preserve Supabase Founder/Editor RBAC, existing data and private storage. Use only additive migrations. Existing `supabase/schema_reference.sql` is for **reference only** and must not be replayed on the live database. Never leak secrets or credentials into GitHub, browser JS, n8n workflow exports or logs.

Baileys (https://github.com/WhiskeySockets/Baileys) is a **proposed unofficial WhatsApp Channel research candidate**, not verified or approved production automation. Keep any auto-Channel integration disabled; do not send live messages without explicit permission.

### Report actual outcomes

Create workflows and provide their n8n IDs/URLs, activated or inactive status, migration files, commits/PRs, redacted workflow exports, real execution evidence and matching Supabase IDs. Test duplicate Drive event, missing Editor, role-denied approval, private media access, retries, alert dedupe and checkpoint schedule. Do not claim n8n is integrated until a real execution succeeds. If a step is blocked by missing permissions, ask for exact access rather than guessing.

**Start with W01 live Drive upload → n8n → Supabase → secure dashboard.**
