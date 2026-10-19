# CODEX HANDOFF — PulseOps → n8n live integration

**Status: implementation requested, NOT currently connected.** This is the primary handoff for Codex, to be read after cloning this private repository.

## Mission

Implement a **real and tested** n8n integration for PulseOps content operations, starting with one complete vertical slice: **Google Drive raw upload → n8n → secure Supabase source clip and production job → PulseOps dashboard / authorized notification**. Then extend into approval events, deadline alerts, publication reminders and the 1/4/12/23-hour analytics checkpoints.

This project is for an AI Operations Lead assessment. Preserve truthful separation of *implemented*, *simulated*, *proposed*, and *verified live* features. Only describe an integration as live after reviewing an actual n8n execution and matching Supabase record.

## Ownership and code

- GitHub repo (PRIVATE): **https://github.com/Caramelizationz/PulseOps**
- Local clone: `git clone https://github.com/Caramelizationz/PulseOps.git`
- Latest deployed public sandbox source: `apps/demo/index.html`; URL https://pulseops-command-center-demo.vercel.app/login
- Latest deployed authenticated source: `apps/secure-workspace/index.html`; URL https://pulseops-secure-workspace.vercel.app/login
- Vercel projects in personal **Thesis' projects**: `pulseops-command-center-demo` / `pulseops-secure-workspace`. These are currently deployed by direct upload, **not Git-linked**. Configure monorepo root directories and separate project connection only after verifying no destructive settings change.
- Supabase personal project: `zpeswzwyltgjhyvtqsoa`; `https://zpeswzwyltgjhyvtqsoa.supabase.co`. Existing PostgreSQL/RLS/Auth and private bucket `pulseops-media`.
- Do not use **Cynergists**, organizational projects or another organization's Google Drive. Do not modify the user's `caramelization` portfolio.
- Read `supabase/schema_reference.sql` for an **already-applied schema reference**; DO NOT execute it against the existing project. Inspect `public.pulseops_members`, `pulseops_frames`, `pulseops_activity`, `pulseops_event_outbox` and RPC definitions before changes.
- Existing `pulseops_create_frame`, `pulseops_action`, `pulseops_grant_editor` are real, role-enforced, `SECURITY DEFINER` RPCs. Do not replace with direct browser writes. Their execution roles, revision logic and audit trail must be preserved.
- Existing demo records are tagged `is_demo=true`; none are actual WhatsApp Channel publications. Do not send external alerts for demo data unless an explicitly authorized test mode is active.

## Discover before writing

1. Verify n8n instance URL, version, environment, plan, available nodes, API permissions, rate limits and network reachability from **your connected Codex environment**.
2. Verify allowed Google Drive account/folder ID with the user; **do not invent a folder ID or watch an arbitrary folder**.
3. Determine existing authorized email/Slack/Telegram notification endpoint and recipients. Do not make up contact details or send live messages without approval.
4. Inspect live Supabase tables, Auth memberships, RLS, function definitions, Storage policies and the integration event outbox. Only a Founder membership is known; zero real Editors at initial handoff.
5. Identify source-of-truth time zone for reporting and Founder morning digest. Store all timestamps UTC.
6. Check for existing n8n workflows by ID/name and reuse or update intentionally; do not create duplicate active copies.

## W01 — Drive upload intake (the first live vertical slice)

Trigger Google Drive folder file created/changed. Validate: correct parent, non-trashed, video MIME, upload complete/stable, size/duration limit, and authorization. Store Drive ID, web link, size, MIME, timestamps, event key and metadata. Extend Supabase schema via a *new incremental migration* for `pulseops_source_clips` and optional `pulseops_frames.clip_id`.

**Important cardinality:** one raw clip may produce several final publishable frames. Do **not** assume one clip = one frame. Source clip ingestion and frame creation should be distinct and idempotent.

A repeat trigger for same Drive file/revision must not duplicate source clips, editor tasks, or alerts. Enforce uniqueness at the database level. Assign only a real, active verified Editor; if none exists, mark "unassigned" and notify the Founder using a *confirmed* channel. Preserve direct, immutable provenance from Drive to clip to frame.

Suggested event name `clip.uploaded`, including a safe `source_file_id`, internal `clip_id`, `dedupe_key`, `occurred_at` and `status`. Never put raw video bytes in event logs.

## W02 — SLA and exceptions

Run approximately every five minutes (adjust to hosting limits):
- Raw upload idle >=120 minutes with no edit started
- Submitted frame awaiting Founder approval >=45 minutes
- Revision requested with no restart after >=90 minutes
- Approved frame past its publishing deadline
- Published frame missing a checkpoint at 1h / 4h / 12h / 23h, allowing +10 minutes

Implement alert state and deduplication on `(frame_id, version, alert_type, checkpoint)`: first breach, last notification, acknowledged, resolved, retry/failure metadata. Alert only to correct authorized recipients. Calculate from database UTC timestamps; display using configured reporting zone. Avoid per-poll spam.

## W03 — Outbox to n8n event dispatcher

Existing database writes append `public.pulseops_event_outbox` events: `frame.created`, `frame.start_edit`, `frame.submit`, `frame.approve`, `frame.revise`, `frame.publish`, `frame.record_views`.

Build a server-only worker, Edge Function or tightly protected endpoint to *claim/lease* undelivered rows, emit signed n8n events and ack only on successful delivery. Implement bounded retries, timeout, dead-letter handling and stable idempotency keys. `pulseops_event_outbox` intentionally has RLS enabled and NO frontend SELECT policy. **Never grant browser SELECT** just to connect n8n.

Explicit Founder approval must continue to happen only through Supabase Auth and `pulseops_action`, not via an arbitrary webhook. The event dispatcher may notify editors but cannot approve on the Founder's behalf.

## W04 — Approved publication + recorded Channel views

WhatsApp **Channel** publishing is manual for this milestone. After a real Founder approval, an authorized team member records the actual post time and link/ID where available. Track and remind 1/4/12/23-hour checkpoints. Record only observed, cumulative, monotonic post view counts; do not estimate or scrape unsupported metrics. Keep the 40-frames/day KPI tied to actual published records, not created/approved records.

Make checkpoint reminders idempotent and avoid sending messages for synthetic data. Do not auto-publish.

## W05 — Founder digest, optional after W01–W04

Once notification recipient, timezone and local morning time are approved, send a 60-second executive summary: count published versus 40/day, pending approvals, idle raw clips, open revisions, overdue posts, checkpoint completeness, and top 3 blockers. Do not include fake metrics. Keep disabled until scheduling details and recipients are confirmed.

## Server authentication/security design

- n8n API credentials, Supabase secret/service-role key, Drive OAuth credentials, notification tokens and signing keys belong in **n8n Credentials / encrypted environment variables / Vercel server environment / Supabase secrets**. They must NEVER appear in `apps/**/index.html`, static JS, public assets, repository files, n8n workflow exports, build logs or screenshots.
- Browser may use a *publishable* Supabase key under strict RLS, but must never possess a service-role key.
- Protect integration endpoints with scoped short-lived credentials or signed HMAC, timestamp/replay prevention, idempotency ID, rate limits, validation and explicit request timeouts. Validate input source, path ownership, MIME, sizes and workflow actors.
- Use least-privilege; only server-side code can alter outbox delivery status. Log errors without payload secrets or private media links.
- Preserve RLS. Migrations should be additive and reversible, with backups/safety checks. No remote changes to existing authentication users unless explicitly approved.
- Do not send webhook requests to the public demo app; integrate with the **real secure app/backend**.
- Vercel Hobby has plan restrictions: evaluate commercial eligibility, cron restrictions and timeouts before making this a paid-company platform. Use n8n worker/Edge Functions as appropriate.

## Future WhatsApp Channel R&D — NOT APPROVED FOR PRODUCTION

Research candidate: **https://github.com/WhiskeySockets/Baileys**

It is **unofficial WhatsApp Web integration**, not an official WhatsApp Business or Channel publishing API. Verify what it genuinely supports and its Terms of Service/account-ban risk. Channel/newsletter video or photo publishing and accurate post view extraction are not established as reliable production features. If asked to investigate, do a separate opt-in feasibility test using a **dedicated test WhatsApp number and Channel**, not the company's live number. Verify admin permission, photo/video publication, exact view checkpoints, post ID mapping, reconnects, upgrades, reliability and policy risk. Keep `CHANNEL_AUTOMATION_ENABLED=false`. No unsolicited messaging, no scraping, and no claim of a live integration.

## Required acceptance test evidence

1. A completed authorized Google Drive upload yields **exactly one** source clip record with source ID and correct metadata.
2. Replayed/duplicate triggers produce no duplicate clip or frame.
3. Missing editor remains unassigned and triggers correct internal exception, not fabricated assignment.
4. Founder decision recorded in DB emits **one** durable outbox record, followed by one delivered n8n notification to an authorized test recipient. Retry/replay remains safe.
5. Unauthorized Editor fails to approve, even via direct API/RPC; Founder approval succeeds. Test with **distinct verified accounts**.
6. SLA calculations and reminders show correct breach timing, recovery, dedupe, and a no-spam repeated poll.
7. Manual publish status produces 1/4/12/23-hour reminders without fabricated views; recorded nondecreasing counts update analytics.
8. Credential scan reports no secrets in GitHub, browser bundles, logs or exported n8n JSON.
9. Capture exact workflow IDs, URLs, activation state, last successful execution timestamps, redacted workflow JSON, test records, and screenshots/log evidence.
10. Public demo and secure workspace links still work, and no Cynergists or portfolio project changed.

## Implementation approach

Start with a non-destructive status review and short plan. Work in a new Git branch and meaningful commits. Create the proper incremental Supabase migrations and server-side integration components, then test first Drive intake vertical slice and document actual outputs.

Make real external sends, production workflow activation, credential changes, company WhatsApp actions, or potentially billable API calls **only with the user's approval**. If a critical account/folder/recipient detail is unavailable, mark it as a blocker and stop that portion without inventing a value.

After implementing, report: commits/PRs, migrations, n8n workflow IDs + active/inactive status, actual execution evidence, passed/failed test cases, updated Vercel deployments, remaining blockers, and exact next actions for the Loom.

**Do not declare the overall integration complete until a real n8n execution has been verified.**
