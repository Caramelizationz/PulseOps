# Existing Supabase migrations (already applied)

Project: `zpeswzwyltgjhyvtqsoa`

The connected Supabase project reports:

- `20261019184554_pulseops_secure_foundation`
- `20261019184617_pulseops_revoke_unrelated_public_function_execution`
- `20261019191820_pulseops_founder_editor_invites`

They are already applied; **do not re-run/recreate them**.

See `../schema_reference.sql` for a captured schema/RPC/policy reference extracted from the live instance. This reference is *not* an automated replayable migration; it is intended for developer orientation and comparisons.

**Codex must author new, incremental, reversible migration files under this folder** for its future source-clip, event receipt/lease, SLA dedupe and post identifier changes, and apply them only after validating against existing live schema and data. Never wipe demo or production records.

## October 20, 2026 — W01 QA-only integration migrations

Additional migrations already applied on live Supabase:
- `pulseops_qa_video_ingest_strict_allowlist`
- `pulseops_service_integration_role_probe`
- `pulseops_ingest_service_role_secret_key_compat`
- `pulseops_qa_service_role_secret_key_compat`
- `pulseops_private_verified_editor_lookup`

The matching SQL reference files are stored in this directory. **Already applied: do not replay against the live project.** The service role check uses `current_user` rather than requiring a legacy JWT claim (because server Secret Keys may not create that claim); the private schema helper verifies editor email without exposing `auth.users` to n8n. See `docs/QA_VIDEO_UPLOADS_2026-10-20.md` for execution tests and results.
