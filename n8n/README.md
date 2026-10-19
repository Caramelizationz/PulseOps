# n8n — implementation scope

The current deployed apps do **not** have live n8n workflows. No credentials or workflow IDs have been connected.

Read **[Codex integration handoff](../docs/CODEX_N8N_HANDOFF.md)** before building workflows.

Planned workflows: `W01 Drive upload intake`, `W02 SLA watchdog`, `W03 outbox notification relay`, `W04 publication/view-checkpoint reminders`, `W05 Founder morning digest (optional)`.

Implement against the **Supabase secure backend**; never send production webhook events to the public demo or copy service-role keys into static files. Keep exported workflow JSON redacted, with credentials maintained in n8n's credential manager. One Drive source video may yield multiple publishable frames.

WhatsApp Channel integration using **[WhiskeySockets/Baileys](https://github.com/WhiskeySockets/Baileys)** is only a future *unofficial* research candidate and must not be auto-activated.

Once created, add workflow exports to `n8n/workflows/` and record workflow IDs, n8n instance version, active state, runbook and reproducible test evidence without exposing secrets.
