# Existing Supabase migrations (already applied)

Project: `zpeswzwyltgjhyvtqsoa`

The connected Supabase project reports:

- `20261019184554_pulseops_secure_foundation`
- `20261019184617_pulseops_revoke_unrelated_public_function_execution`
- `20261019191820_pulseops_founder_editor_invites`

They are already applied; **do not re-run/recreate them**.

See `../schema_reference.sql` for a captured schema/RPC/policy reference extracted from the live instance. This reference is *not* an automated replayable migration; it is intended for developer orientation and comparisons.

**Codex must author new, incremental, reversible migration files under this folder** for its future source-clip, event receipt/lease, SLA dedupe and post identifier changes, and apply them only after validating against existing live schema and data. Never wipe demo or production records.
