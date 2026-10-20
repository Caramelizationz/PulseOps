# PulseOps — Content Operations Command Center

**AI Operations Lead paid assessment · Track B · Current project snapshot: October 20, 2026**

This private repository contains source code, database migrations, and verification notes for an independent, connected content-operations prototype. Development and test work occurred across multiple commits; this summary reports the current working state, **not** a claim that all work was completed within a particular time limit.

## Reviewer deliverable

**[Final Track B assessment — viewable Google Doc](https://docs.google.com/document/d/1-_J9aeG464Mqvt2uDevqC6lxzpSLziCrYTEglMdyGsM/edit)**

- [Public interactive product demo](https://pulseops-command-center-demo.vercel.app/login) — synthetic browser-session data; demonstration passcode `demo123` only.
- [Authenticated secure workspace](https://pulseops-secure-workspace.vercel.app/login) — real Supabase Auth, PostgreSQL and row-level security; requires an approved account.
- [Incoming clips and isolated QA jobs](https://pulseops-secure-workspace.vercel.app/clips) — secure login required.
- [Founder-only system health and internal inbox](https://pulseops-secure-workspace.vercel.app/ops) — secure Founder login required.
- [Five shareable sample video copies](https://drive.google.com/drive/folders/15iN-VtQbCJAZCDcgv3Umcwqui2yw1k30) — open-license test footage; separate from the monitored private creator folder.
- [Implementation and QA evidence](docs/SUBMISSION_READY_2026-10-20.md) · [Five-video test report](docs/QA_VIDEO_UPLOADS_2026-10-20.md).
- The employer submission requires a **separate two-minute Loom** recorded by the applicant; no Loom is included here.

## Live n8n workflows

| Workflow | What is implemented | Live state and evidence |
| --- | --- | --- |
| **W01 — Drive intake** | Folder-specific Google Drive OAuth watcher; validates file metadata; filters five QA fixtures; posts real eligible clips via a service-role-only, idempotent Supabase RPC | Active. Drive trigger execution #6; guarded test #18. |
| **W02 — SLA monitor** | Five-minute checks: 120m idle upload, 45m approval, 90m revision, overdue publishing, and missing 1/4/12/23h views after 10m grace | Active. Manual and scheduled executions succeeded. |
| **W03 — Founder internal inbox** | Five-minute reconciliation of non-demo events and SLA alerts into durable Founder-only notifications | Active. Internal only; no email, Slack or WhatsApp sends. |
| **W06 — Self-healing guardian** | Fifteen-minute detection of expired undelivered event leases; bounded recovery and system heartbeat | Active. Simulated expired-lease recovery tested transactionally. |
| **W07 — Missed-upload reconciliation** | Fifteen-minute recovery scan of approved folder; demo fixtures excluded; idempotent backfill, bounded HTTP retries | Active. Five demo files correctly skipped during test. |

n8n workflows live in the personal instance: https://caramelcrusade.app.n8n.cloud. Credential values live in the encrypted n8n credential manager and are **not** checked into this repository.

## What was actually verified

- Five different CC0-labeled sample MP4 files were uploaded to the private test Drive folder.
- The controlled manual QA workflow ingested **five demo clips** and **five demo jobs** in Supabase.
- Replaying the five inputs returned `duplicate=true` for each and created **zero extra jobs**.
- Database verification reported **0 non-demo clips/jobs, 0 notification outbox events, 0 actual SLA alerts** from those fixtures.
- Rollback-only SQL tests covered SLA exception detection/replay/resolution, Founder inbox event deduplication, and expired-lease recovery.
- The authenticated workspace and public demo deployments were checked online. Production Vercel applications are still deployed via direct source upload rather than GitHub-connected automatic deployment.

**Not yet tested or authorized:** employer Drive access, two verified Editor accounts and real dual-account approval handoff, external notification recipients, real WhatsApp Channel posting/view retrieval, or a Founder digest with an approved timezone. WhatsApp posting and post view recording remain **manual**; no Channel automation is claimed. Commercial production operation and long-term uptime have not been validated.

## Repository layout

- `apps/demo/` — public, fully synthetic interactive product demonstration.
- `apps/secure-workspace/` — authenticated Supabase dashboard.
- `supabase/` — existing schema reference plus incremental applied migrations. Do **not** replay the complete reference schema against the live project.
- `n8n/` — workflow IDs, automation documentation and safe integration runbooks.
- `docs/` — architectural background, QA reports, test evidence and reviewer context. `docs/CODEX_N8N_HANDOFF.md` is an earlier planning handoff and should not be used as the current runtime status.

## Running locally and security

```bash
git clone https://github.com/Caramelizationz/PulseOps.git
cd PulseOps/apps/demo
python -m http.server 8080
```

Local deep links may require the configured SPA rewrite. The secure app additionally requires Supabase Auth redirect configuration.

Never commit Supabase service-role/secret keys, n8n credentials, OAuth tokens, or other private authentication material. The public passcode `demo123` is solely for synthetic demo content, not real authentication. Founder decisions remain role-protected in Supabase; no automation approves on behalf of the Founder. The original `caramelization` portfolio and unrelated organizations are outside this project.

**Evidence date:** October 20, 2026. Historical Git commit timestamps remain unaltered.
