# W01 — live connection checklist (updated October 20, 2026)

**Workflow:** [PulseOps | W01 - Drive Video Intake (STAGING ONLY)](https://caramelcrusade.app.n8n.cloud/workflow/UP3HFHLjUC7nlxXL)

**Project:** Personal — Jonas Viray (`MCPuPmeRmurDUeLx`).

**Status: UNPUBLISHED, STAGING ONLY.** The workflow has **no Google Drive trigger, no external HTTP write, no active schedule**, and does not insert rows into Supabase.

## Verified test results

- Execution `2`: test `sample-clip.mp4` (25,900,000 bytes, `video/mp4`, fake folder `TEST-FOLDER-ONLY`) generated `gdrive:TEST-DRIVE-FILE-001:test-checksum-001`, `eligible=true`, and an RPC mapping to `pulseops_ingest_drive_clip`. Reached `VALIDATED_ONLY_NOT_SENT_TO_SUPABASE`.
- Execution `3`: altered test MIME to `image/jpeg`; `eligible=false`, `unsupported_video_mime`, routed to `REJECTED_NEEDS_REVIEW`. The MP4 fixture was restored.
- The actual database already includes migrations: `20261019221050_n8n_integration_foundation`, `20261019221204_n8n_integration_indexes`, `20261019221226_n8n_integration_foundation_fix`. These migrations exist in Supabase, **not yet represented as SQL files in this repo**. Do not rerun the older `supabase/schema_reference.sql`.
- Introspected existing RPC: `public.pulseops_ingest_drive_clip(p_source_file_id,p_event_key,p_filename,p_mime_type,p_size_bytes,p_parent_folder_id,p_drive_revision_id,p_drive_created_at,p_drive_modified_at,p_drive_web_url,p_metadata)`. It requires `request.jwt.claim.role = service_role`, checks metadata, and creates one source clip, job and event receipt with deduplication and unassigned-editor fallback.
- Transactional database test (rolled back): first accepted, duplicate recognized, stable clip/job IDs, exactly one event in outbox. Verified production counts remained zero.
- The real project has source clip, job, receipt, publishing, SLA and outbox tables. **Reuse the existing schema instead of creating a new clips table.**

## Mandatory external setup before going live

1. **User supplies/approves the exact creator-upload Google Drive folder URL or ID.** Do not watch arbitrary folders, shared drives or the ChatGPT-connected Drive account by assumption. No matching named PulseOps/creator folder was found via a limited Drive search.
2. Create/authorize a **Google Drive OAuth2** credential within the **n8n instance itself** and grant only the required Drive permissions. The separate ChatGPT Google Drive connection cannot be reused automatically. W01 currently has **zero n8n credentials**.
3. Set the Google Drive Trigger to the approved folder, filter for newly completed video uploads; verify returned metadata includes the true parent folder, MIME, byte size and file ID. Check unsupported/trashed/empty files.
4. Configure a secure server-side Supabase integration credential (or narrow-scope Edge Function). Existing RPC currently requires `service_role`; DO NOT put the secret key in workflow JSON, browser scripts, GitHub, logs or user messages. Store secrets in n8n Credential manager / Supabase secrets only. Consider a scoped proxy instead of providing n8n with a broadly privileged key.
5. Connect the valid branch to the server-side ingestion endpoint only after test and authorization. Keep duplicate receipt/outbox behavior intact and do not create an editor assignment where no verified editor exists.
6. Test real approved Drive upload → n8n execution → matching `public.pulseops_source_clips` and `public.pulseops_jobs` records → secure dashboard. Repeat trigger to confirm one clip and job. Keep test content segregated.
7. Add real alerts only after recipients and notification channel are explicitly confirmed. Do not activate WhatsApp Channel automation.

## Guardrails

- Existing production frontends and all other user apps remain unchanged.
- n8n manually tested / unpublished is not proof of live Google Drive ingestion.
- This workflow's `rpc_payload` is a prepared JSON object, not a real HTTP request.
- Review Supabase schema + RLS security with user before changing privileges. Never expose service-role keys in a client.
