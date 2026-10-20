# PulseOps Track B — submission readiness report
**20 October 2026 · Independent personal prototype · all data below are verified/synthetic as explicitly stated**

## Working interfaces
- Authenticated secure application: https://pulseops-secure-workspace.vercel.app/login
- Founder-only operations, internal notifications, and last-success health: https://pulseops-secure-workspace.vercel.app/ops
- Demo clips and jobs: https://pulseops-secure-workspace.vercel.app/clips
- Public interactive sample UI (synthetic, demo passcode `demo123`): https://pulseops-command-center-demo.vercel.app/login
- Production secure Vercel deployment verified READY: `dpl_2vEUcsWT8fakzkV4eUpB2FwcvZyS`.

## n8n workflows verified active in personal project
| Name | ID | Cadence | Test evidence |
|---|---|---|---|
| W01 live Google Drive intake, excludes QA samples | `UP3HFHLjUC7nlxXL` | Drive created event | Actual trigger #6 detected 4 MP4s; manual guard #18 passed |
| W02 SLA detection and recovery | `dlUKTDPmr4ddH4Yb` | Every 5 minutes | Manual #14 and scheduled #19/#24 succeeded |
| W03 Founder-only internal event inbox | `0g4j2eQP0cZVkueM` | Every 5 minutes | Manual #16 and scheduled #20/#25 succeeded |
| W06 self-healing guardian | `kGatkfxfGmAE96BU` | Every 15 minutes | Manual #17 and scheduled #21 succeeded |
| W07 missed-upload reconciliation | `oOVNskQfkDRqqwaI` | Every 15 minutes | Manual #22/#23 read 5 QA uploads and wrote zero production jobs |

Manual-only QA workflow: `TGJMijKRtCs6cGjE` (unpublished). Real Supabase ingestion uses a `service_role`-restricted database RPC, connected through encrypted n8n credentials. No credentials or server secrets are in static frontend source.

## Verified database baseline
- 5 original CC0 test MP4s in personally owned Google Drive folder.
- 5 source clips and 5 jobs recorded with `is_demo=true`.
- Zero non-demo clips/jobs, zero persisted notification outbox rows, zero active alerts, zero internal notifications from test data.
- QA ingestion execution #12: five results; execution #13: all five replayed with `duplicate=true` and preserved clip/job IDs.
- Role-checked Founder and Editor actions exist; verified Editor membership remains **0**, so dual-account E2E approval/assignment is not demonstrated.

## Self-healing verification (no speculative claim)
- Google Drive missed-event recovery: W07 scans exact approved folder, ignores five QA IDs and any `pulseops-test-` fixtures, and uses existing unique Drive ID/receipt logic.
- Outbound/DB transient error handling: bounded three-attempt HTTP retries; scheduled later runs retry idempotent work.
- W06 expired delivery lease recovery preserves event state for later delivery and does not silently acknowledge undelivered external messages.
- Transactional rollback-only SQL tests: overdue upload alert created once, repeated poll produced no duplicate, completing a job resolved the alert; inbox event deduplicated; W06 reclaimed a simulated expired lease.
- Limits: recovery of invalid credentials, broken third-party services, API quota exhaustion, very large Drive folders, and all failure categories is **not** automatic. W07 fails closed if more than 1,000 files require pagination. Show n8n error executions for operator follow-up.

## Business flow and things deliberately not claimed
- Creator Drive upload -> n8n -> Supabase source clip/job -> verified Editor assignment (only if actual verified Editor exists) -> Editor edit/submit -> Founder approve/revise -> **manual** Channel publication -> actual 1h/4h/12h/23h view checks.
- SLA thresholds: upload idle 120m; approval 45m; revision 90m; approved/publish due; 1h/4h/12h/23h metric checkpoint grace +10m. Example spreadsheet contains additional optional hypothetical thresholds, not all configured as automated rules.
- W03 notifications are a durable *in-app Founder inbox*, **not outbound email/Slack/WhatsApp delivery**. External transport remains unconfigured because no approved team recipient/channel exists.
- WhatsApp Channel automation, bot-posting and Channel view scraping are not implemented or represented as functional.
- First real company integration still requires company Drive permission, verified Editor account(s), approved notification destinations/timezone and explicit testing of a genuine clip.
- Optional W05 Founder digest disabled until timezone/time and delivery destination confirmed.

## Submission assets
- Final assessment PDF and supporting XLSX workbook: downloadable artifacts attached in ChatGPT.
- Two-minute Loom script: `PulseOps_FINAL_Loom_Script.md` attached in ChatGPT; record via your own account, never include secrets.
- Existing detailed five-video evidence: `docs/QA_VIDEO_UPLOADS_2026-10-20.md`.

## AI disclosure
ChatGPT/GPT-6 assisted architectural planning, implementation, test design, database migrations, UI and documentation. The shipped workflows are deterministic n8n/Postgres logic, not an autonomous publishing agent.

**Before sharing with an employer:** private GitHub and authenticated personal Supabase workspace are not automatically accessible to third parties. Share public demo + Loom and selectively grant reviewer access if permitted, without revealing secret credentials.
