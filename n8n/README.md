# PulseOps — n8n live workflow register

**Verified runtime snapshot: October 20, 2026.** This file replaces the earlier pre-connection plan. Workflow definitions and encrypted credentials reside inside the user's personal n8n instance. This repository stores verified IDs, runbooks and SQL migrations; it does not contain exported credentials.

| ID | Workflow | Status | Schedule | Scope |
| --- | --- | --- | --- | --- |
| `UP3HFHLjUC7nlxXL` | W01 — Live Drive Intake (Demo-Safe) | **Active** | Google Drive file-created trigger | Validates approved private folder metadata; excludes five test videos; real-event Supabase RPC with retry |
| `dlUKTDPmr4ddH4Yb` | W02 — SLA Monitoring and Auto-Resolution | **Active** | Every 5 min | Detects/report/resolves real overdue milestones, idempotent |
| `0g4j2eQP0cZVkueM` | W03 — Founder Internal Inbox | **Active** | Every 5 min | Founder-only stored in-app notices for actual events/alerts; no external messages |
| `kGatkfxfGmAE96BU` | W06 — Self-Healing Guardian | **Active** | Every 15 min | Reclaims expired event leases, stores health heartbeat |
| `oOVNskQfkDRqqwaI` | W07 — Drive Reconciliation | **Active** | Every 15 min | Scans same folder, excludes demo videos and backfills genuinely missed uploads |
| `TGJMijKRtCs6cGjE` | QA video backfill | Inactive/manual only | On demand | Exact allowlist of five open-license MP4s; all records marked `is_demo` |

*Demo ingestion proof:* execution #12 ingested five sample videos; #13 returned five duplicate responses with stable clip and job IDs, no extra records. Dry-run and scheduled tests are documented in [submission readiness evidence](../docs/SUBMISSION_READY_2026-10-20.md) and [QA upload report](../docs/QA_VIDEO_UPLOADS_2026-10-20.md).

**Security:** The original monitored Google Drive folder remains private. A separate public-viewer folder contains copied test-only MP4s for the assessment reviewer. The Supabase service credential and Google Drive OAuth remain in n8n Credential manager. Server-only RPCs and RLS restrict real data access. None of the five test uploads contributes to real KPI totals or notification events.

**Not implemented as a live integration:** automatic WhatsApp Channel posting, Channel view scraping, external email/Slack/WhatsApp notifications or the optional morning Founder digest. Actual publication and 1/4/12/23-hour view observations are manual. The company Drive/Editors were not supplied, so no real employer handoff is claimed.

The design requirements in [CODEX_N8N_HANDOFF.md](../docs/CODEX_N8N_HANDOFF.md) were drafted before connection; for the current working state refer here and to [README.md](../README.md). Historical commits remain unchanged.
