# PulseOps W01 — sample Google Drive videos (QA)

**Date:** 2026-10-20  
**Google Drive folder:** [Video folder](https://drive.google.com/drive/folders/1wN6mDtXSyTJLKma_-Uf4z4CmHhXx1tNh)  
**n8n watcher:** [W01 – Drive Video Intake](https://caramelcrusade.app.n8n.cloud/workflow/UP3HFHLjUC7nlxXL)  
**One-time upload workflow:** [PulseOps QA – Five CC0 Videos](https://caramelcrusade.app.n8n.cloud/workflow/BG20mSwqSnBoglgR)  
**Upload n8n execution:** `5`, **success**, 5/5 uploads; upload workflow remains unpublished/manual-only.

## Source / license

The five files were retrieved from [TrueFileSize sample MP4 catalog](https://truefilesize.com/video/mp4/) and are labeled by the site as **CC0 / public domain**. They are synthetic testing footage (generated test patterns, not actual creators' content).

## Uploaded sample files

| Name | Size (bytes, verified by Drive) | Google Drive file ID | Original URL |
|---|---:|---|---|
| `pulseops-test-01-landscape-480p.mp4` | 1048576 | `1CdYX44ohTne7F7MhnmobI0w3p7dDOnwm` | https://cdn.truefilesize.com/mp4/sample-1mb.mp4 |
| `pulseops-test-02-landscape-720p.mp4` | 5242880 | `1OVxyNR1d5K5KVU_SrE0o08sPYoAwYCyl` | https://cdn.truefilesize.com/mp4/sample-5mb.mp4 |
| `pulseops-test-03-portrait-1080p.mp4` | 14390087 | `1HAoj49fKEQRjTUqVzqjqJCMXEsQqwVjy` | https://cdn.truefilesize.com/mp4/sample-portrait.mp4 |
| `pulseops-test-04-square-1080p.mp4` | 9371436 | `1AkqLYFXnZnbAh2x2x72aTgcrfL4YRJAz` | https://cdn.truefilesize.com/mp4/sample-square.mp4 |
| `pulseops-test-05-silent-720p.mp4` | 4334089 | `1sEW429GyqjYckvmJtr1nmTv7sFnh2wam` | https://cdn.truefilesize.com/mp4/sample-silent.mp4 |

Verified via Google Drive metadata: all **video/mp4**, each with parent ID `1wN6mDtXSyTJLKma_-Uf4z4CmHhXx1tNh`.

## Trigger validation

At the first check, W01 trigger execution `6` (**success**) returned 4 files (01–04). The `Validate and Normalize Clip` step marked all four `eligible:true` with `errors:[]` and matched the authorized folder. A later check still found only execution `6` and five files in the folder; do **not** claim the fifth triggered until a subsequent execution proves it.

The `Supabase Intake RPC (DISABLED - configure credential)` node is configured with the existing private n8n credential but **DISABLED**. The workflow is active in **monitoring-only** mode, with zero backend writes attributable to these uploads. No actual production jobs have been created from them yet.

For the end-to-end test, either re-trigger five sample videos (e.g. copy into folder with fresh IDs), or implement a controlled backfill. Simply enabling the downstream HTTP Request node will **not replay already consumed Google Drive trigger events**.

## Next actions

1. Confirm the Supabase RPC can authenticate with the n8n `supabaseApi` credential as a service-role integration; check request headers and perform an explicitly approved controlled single-record write.
2. Ensure secure app /clips can see the new jobs and test duplicate delivery.
3. Exclude these `pulseops-test-` fixture clips from real output KPIs and notifications (existing DB ingest helper defaults `is_demo=false`, so test markers must be implemented before production ingestion).
4. Keep WhatsApp Channel publishing and external notifications disabled.

## QA-only Supabase ingestion — completed

- QA RPC: `public.pulseops_ingest_qa_video`, accessible **only** to effective Postgres `service_role`. Its exact allowlist contains only the five Drive file IDs, original filenames, sizes, MIME type, and parent folder used in this run. It delegates idempotent intake to the existing server-side function and marks both the clip and job `is_demo=true` inside the same transaction, removing its intermediate outbox event before commit.
- n8n manual workflow: [QA — Secure Ingest Approved Drive Videos](https://caramelcrusade.app.n8n.cloud/workflow/TGJMijKRtCs6cGjE); **unpublished** and runs only when manually executed. Credential remains in n8n, not GitHub.
- Execution `7`: 403 due to legacy JWT claim check; no inserted records.
- Execution `8`: read-only role probe showed `effective_service_role=true`, `jwt_claim_service_role=false`, confirming newer Supabase secret-key authentication needs an actual DB role check.
- Executions `9` and `10`: caught role-check issue in QA wrapper and permission-denied issue while reading protected `auth.users`; fixes were applied while keeping anonymous/authenticated callers denied.
- Execution `11`: first actual QA POST **success**, with demo clip and demo unassigned job, zero outbox event.
- Execution `12`: all five POSTs **success**; first clip duplicate=true, other four created. Five distinct sample clip IDs and five distinct jobs.
- Execution `13`: all five POSTs **success**, each returned duplicate=true with the **same clip/job IDs** as execution 12.

Verified database state after execution `12`:
```text
approved_clips     5       distinct_drive_ids    5
both_demo          5       unassigned_jobs       5
marked_qa          5       drive_receipts        5
outbox_all         0       alerts_all            0
real_clips         0       real_jobs             0
```

The secure Founder app now shows these under a **separate QA-only section** in the [Incoming Clips](https://pulseops-secure-workspace.vercel.app/clips) page; production uploaded clip/job totals remain unaffected. The updated UI deployed as production deployment `dpl_HfnqX9C9DEy3BCf4GesoMLCgT1Bt`, READY.

**Separation is intentional:** Do not enable the ordinary W01 Supabase POST node based on these QA results. W01 is active as a **monitoring-only** Drive watcher, and its existing standard HTTP writer remains **disabled**; test backfill is through the manually executed QA-only workflow. No external WhatsApp, Slack, or other notifications have been configured or sent.

### Security notes

- `public.pulseops_ingest_drive_clip` uses an effective `service_role` check (supports Supabase server Secret Keys); it still has `SECURITY INVOKER` and `EXECUTE` restricted to `service_role`.
- Editor verification uses `pulseops_private.first_verified_editor()`, a narrowly scoped `SECURITY DEFINER` function in the **unexposed private schema**, executable only by `service_role`. This avoids granting broad `auth.users` access to n8n.
- Supabase security advisor still reports pre-existing findings for RLS-enabled server-only outbox/receipt tables (INFO), authenticated SECURITY DEFINER application RPCs (intentional workflow paths to review), and disabled leaked-password protection (Auth hardening).
- The QA-only role probe is restricted to `service_role`; it returns only two boolean fields, no keys.

**Remaining tasks:** explicitly switch on authenticated real ingestion after test folder semantics and live notification guardrails are approved; invite a verified Editor; end-to-end Founder UI review; W02 SLA workflow; W03 outbox dispatcher and W04 manual channel metrics. Do not claim those are completed.
