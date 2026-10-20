# Instructions for Codex working on PulseOps.

Read `README.md` and **`docs/CODEX_N8N_HANDOFF.md`** before modifying any code.

## Scope and ownership
- Work only in this private repo, the personal Vercel projects `pulseops-command-center-demo` and `pulseops-secure-workspace`, the personal Supabase project `zpeswzwyltgjhyvtqsoa`, and an explicitly authorized personal n8n instance.
- **Never touch Cynergists, portfolio project `caramelization`, or other companies' resources.**
- Existing production sites were deployed via direct Vercel API uploads, not automatic Git pushes. **Do not assume a push updates Vercel.** Protect the current working URLs while you establish Git-linked deployments.
- The existing public demo is synthetic and should stay separate from authenticated production data. `demo123` is a *public sandbox* passcode, never use it on Supabase Auth.

## Architecture
- `apps/demo/index.html`: the up-to-date public sandbox.
- `apps/secure-workspace/index.html`: current Supabase Auth/Postgres frontend with Founder and Editor views.
- `supabase/schema_reference.sql`: reference only, **DO NOT RE-APPLY** to the live database.
- `supabase/migrations/`: new **incremental** migrations for any live schema additions.
- `n8n/`: integration specifications and (once implemented) redacted workflow JSON.

## Security
- Never commit or display n8n API keys, service-role/secret Supabase keys, credential JSON, OAuth tokens, private clip URLs, passwords, session files or auth cookies. Public Supabase publishable keys in browser apps are not service-role secrets.
- All webhook/database integration writes must use authenticated, validated, idempotent **server-side** endpoints; do not add broad public write permissions. Preserve RLS and role-gated RPC semantics. Only an authenticated Founder can approve/revise.
- Do not run unapproved external messaging, live WhatsApp Channel operations, costly API calls or destructive database changes.
- Baileys `https://github.com/WhiskeySockets/Baileys` is an unofficial proposed future research candidate, not authorized production integration.

## Definition of done
- Verify n8n real execution and matching Supabase changes.
- Test duplicate Drive events, unauthorized actions, alert idempotency, outbox retries, private video handling and 1/4/12/23h checkpoint reminders.
- Provide actual workflow IDs, versions, URLs, active/disabled states, redacted exports, deployment details, migrations and test evidence.
- Report honest blockers rather than guessing credential or account details.
