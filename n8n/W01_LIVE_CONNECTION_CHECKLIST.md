# W01 — live connection checklist (updated October 20, 2026)

**Workflow:** [PulseOps | W01 - Drive Video Intake (STAGING ONLY)](https://caramelcrusade.app.n8n.cloud/workflow/UP3HFHLjUC7nlxXL)

**Project:** Personal — Jonas Viray (`MCPuPmeRmurDUeLx`).

**Status: UNPUBLISHED, STAGING ONLY.** The workflow now includes an OAuth-authenticated folder-specific Google Drive trigger and a guarded Supabase POST node, but the POST node is DISABLED, no live schedule is active, and nothing is being written to Supabase.

## Verified test results

- Execution `2`: test `sample-clip.mp4` (25,900,000 bytes, `video/mp4`, fake folder `TEST-FOLDER-ONLY`) generated `gdrive:TEST-DRIVE-FILE-001:test-checksum-001`, `eligible=true`, and an RPC mapping to `pulseops_ingest_drive_clip`. Reached `VALIDATED_ONLY_NOT_SENT_TO_SUPABASE`.
- Execution `3`: altered test MIME to `image/jpeg`; `eligible=false`, `unsupported_video_mime`, routed to `REJECTED_NEEDS_REVIEW`. The MP4 fixture was restored.
- The actual database already includes migrations: `20261019221050_n8n_integration_foundation`, `20261019221204_n8n_integration_indexes`, `20261019221226_n8n_integration_foundation_fix`. These migrations exist in Supabase, **not yet represented as SQL files in this repo**. Do not rerun the older `supabase/schema_reference.sql`.
- Introspected existing RPC: `public.pulseops_ingest_drive_clip(p_source_file_id,p_event_key,p_filename,p_mime_type,p_size_bytes,p_parent_folder_id,p_drive_revision_id,p_drive_created_at,p_drive_modified_at,p_drive_web_url,p_metadata)`. It requires `request.jwt.claim.role = service_role`, checks metadata, and creates one source clip, job and event receipt with deduplication and unassigned-editor fallback.
- Transactional database test (rolled back): first accepted, duplicate recognized, stable clip/job IDs, exactly one event in outbox. Verified production counts remained zero.
- The real project has source clip, job, receipt, publishing, SLA and outbox tables. **Reuse the existing schema instead of creating a new clips table.**

## Mandatory external setup before going live

1. **Completed:** User-authorized Drive folder `Video folder`: `https://drive.google.com/drive/folders/1wN6mDtXSyTJLKma_-Uf4z4CmHhXx1tNh`. Its metadata identifies Jonas Viray as owner. Folder was confirmed empty.
2. **Completed:** n8n Google Drive OAuth2 credential `Google Drive account`, bound to workflow's `Google Drive - Video Folder` trigger. Credential lookup confirmed the exact folder ID. Source validation checks exact parent ID and supported MIME / 1–100 MB video size.
3. **Completed as disabled draft:** Real-only guard to prevent synthetic `TEST-` fixtures from reaching the database. Prepared HTTP Request `POST https://zpeswzwyltgjhyvtqsoa.supabase.co/rest/v1/rpc/pulseops_ingest_drive_clip`, with native n8n Supabase API credential selected but not yet assigned. HTTP Request stays DISABLED.
4. **User action required:** In personal n8n project → Credentials → Add → **Supabase API**. Host `https://zpeswzwyltgjhyvtqsoa.supabase.co` (no /rest/v1). Enter Supabase project's server-side Secret Key in n8n credential manager only. Do not paste secret into ChatGPT or GitHub. This credential has broad service privileges; consider a scoped proxy before production.
5. **Next:** Connect created Supabase API credential to disabled HTTP Request node; verify credential and endpoint on safe test records; compare first request and duplicate replay, keep live notifications disabled.
6. **Next:** Activate W01 only after endpoint is verified and permission to monitor the folder is confirmed. Upload one non-sensitive sample MP4 to approved folder → n8n execution → matching `public.pulseops_source_clips` + `public.pulseops_jobs`. Repeat to check idempotency. The secure dashboard's `/clips` view now displays production jobs.
7. **Later:** Configure real Editor memberships and confirmed notification channel; no WhatsApp Channel automation.

## Guardrails

- Existing production frontends and all other user apps remain unchanged.
- n8n manually tested / unpublished is not proof of live Google Drive ingestion. The recent combined-trigger test via ChatGPT was blocked by connection safety checks, so it is not a passing test.
- Current secure dashboard: https://pulseops-secure-workspace.vercel.app/clips (deployed with job/source-clip querying, empty until live intake).
- This workflow's `rpc_payload` is a prepared JSON object, not a real HTTP request.
- Review Supabase schema + RLS security with user before changing privileges. Never expose service-role keys in a client.
