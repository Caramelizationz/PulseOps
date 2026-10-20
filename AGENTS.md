# PulseOps — contributor and Codex safety guide

Read [README.md](README.md), [n8n/README.md](n8n/README.md), and
[docs/SUBMISSION_READY_2026-10-20.md](docs/SUBMISSION_READY_2026-10-20.md)
before modifying a live integration. The original
[docs/CODEX_N8N_HANDOFF.md](docs/CODEX_N8N_HANDOFF.md) is a **historical
design brief**, not the current implementation status.

## Ownership and deployed applications
- Work only in this private repo, the personal Vercel projects
  `pulseops-command-center-demo` and `pulseops-secure-workspace`,
  personal Supabase project `zpeswzwyltgjhyvtqsoa`, and explicitly authorized
  personal n8n at `caramelcrusade.app.n8n.cloud`.
- **Never touch Cynergists, the personal portfolio `caramelization`, or another
  organization's resources.**
- The Vercel sites are deployed separately via direct uploads; Git commits do
  **not** automatically deploy them. Check the live alias after a safe deployment.
- `apps/demo/` is public and synthetic; passcode `demo123` is a non-secret
  sandbox control and never authorizes the real Supabase workspace.
- `apps/secure-workspace/` enforces Supabase Auth, membership checks, RLS,
  role-checked RPCs, and private media handling.

## Connected workflow baseline (verified October 20, 2026)
- **W01** `UP3HFHLjUC7nlxXL`: Google Drive source-file watch, validated
  authenticated intake and idempotent Supabase RPC; excludes known QA files.
- **W02** `dlUKTDPmr4ddH4Yb`: five-minute SLA monitoring, deduplication,
  and resolution when an exception clears.
- **W03** `0g4j2eQP0cZVkueM`: five-minute Founder-only in-app notifications;
  external email/Slack/WhatsApp delivery is **not** configured.
- **W06** `kGatkfxfGmAE96BU`: fifteen-minute expired delivery-lease recovery
  with health heartbeat and bounded retries.
- **W07** `oOVNskQfkDRqqwaI`: fifteen-minute missed-Drive-upload scan,
  test fixture filtering and idempotent backfill.
- The exact-five-video **QA-only** workflow is manual and inactive by default;
  do not use it for genuine creator videos.

## Data safety and provenance
- `supabase/schema_reference.sql` describes an **already deployed** schema:
  **never replay it** as a migration. Apply incremental SQL in
  `supabase/migrations/` only after inspecting the current database.
- Demo source clips and demo jobs must remain `is_demo=true`. Exclude them from
  live post counts, escalation messages, Founder KPIs, and WhatsApp claims.
- Only the authorized private creator Drive folder is watched. The reviewer's
  separately shared five-video fixture folder is **not** a live intake source.
- Keep the distinction between source clips/jobs and independently publishable
  frames. One original clip may produce multiple frames.
- Never invent verified Editor accounts or auto-assign to nonexistent users.
- Do not auto-approve Founder decisions, auto-post to WhatsApp Channels, or
  synthesize observed 1h/4h/12h/23h view counts.

## Credentials, boundaries and self-healing
- Never commit n8n credential JSON, OAuth tokens, Supabase secret/service-role
  keys, private upload URLs, live auth cookies or other sensitive materials.
- Only credential-backed server-side RPCs may ingest real media metadata; keep
  public client credentials separate from private service-role credentials.
  Review RLS and least-privilege permissions before changing auth policies.
- n8n transient failures can retry up to three attempts; idempotent database
  receipts prevent duplicate jobs. The W06 guardian reclaims expired leases,
  **not** falsely acknowledged messages.
- W07 currently scans a bounded folder listing and fails closed if more than
  1,000 items require pagination. Add safe pagination before claiming unlimited
  replay capability.
- External recipients, live WhatsApp publishing/view scraping, and the optional
  morning digest require separate company approval and account access.

## Definition of done for subsequent work
1. Inspect existing nodes, tables, and live deployments before editing.
2. Write a genuine, scoped change with a tested rollback or manual recovery plan.
3. Test both the successful path and failure/idempotency path using permitted
   test data; identify exact n8n execution IDs and database results.
4. Verify the production alias and document whether the result is live,
   controlled-QA-only, simulated, or still awaiting authorization.
5. Preserve Git commit history and original timestamps; do not manufacture
   assessment elapsed time, outcomes, customers, or production statistics.
