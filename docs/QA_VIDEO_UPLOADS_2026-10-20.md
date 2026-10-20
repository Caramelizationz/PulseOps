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
