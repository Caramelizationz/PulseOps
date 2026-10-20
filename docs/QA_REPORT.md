> **Historical QA baseline.** This document records early frontend validation before the later n8n integration was completed. Its “NOT verified/live yet” section is deliberately preserved as the earlier state, **not the current status**. For the latest verified workflows and submission evidence as of October 20, 2026, consult [SUBMISSION_READY_2026-10-20.md](SUBMISSION_READY_2026-10-20.md) and [QA_VIDEO_UPLOADS_2026-10-20.md](QA_VIDEO_UPLOADS_2026-10-20.md). The final reviewer deliverable is the [Google Doc](https://docs.google.com/document/d/1-_J9aeG464Mqvt2uDevqC6lxzpSLziCrYTEglMdyGsM/edit). Git history has not been rewritten.

---

# QA / Current State — October 20, 2026

## Confirmed

- Both Vercel projects report READY and direct URLs respond HTTP 200.
- Public demo `/login`, `/overview`, `/pipeline`, `/integrations` are present and render source code.
- Latest public demo JavaScript was executed with a mock DOM for 9 checks: valid/invalid passcode, Founder approval, Editor start/submit, forbidden Editor approval, Founder revision, shareable pipeline filter. **9/9 passed in mock DOM**; not a real browser automation run.
- Secure workspace code retrieved from production Vercel and JS syntax parsed.
- Supabase has `pulseops_members`, `pulseops_frames`, `pulseops_activity`, `pulseops_event_outbox` with RLS enabled.
- The real database has one Founder member, **no verified Editor membership** at the last check, and 12 synthetic sample frames tagged `is_demo=true`.
- Transactional SQL role simulations (rolled back) exercised Founder approval, Editor edit/submit and denied approval; no production state modifications persisted.
- `public.pulseops_event_outbox` has **no client SELECT RLS policy**, deliberately.
- `Baileys` is listed on the public demo Integrations page strictly as a proposed third-party research candidate.

## NOT verified/live yet

- Real two-account browser sign-in and Editor-to-Founder approval/revision lifecycle.
- n8n instance/API connection; Drive OAuth; actual source upload; notifications; end-to-end outbox processing.
- Private video upload/update end-to-end.
- WhatsApp Channel automatic posting or readouts; no WhatsApp account has been connected.
- Git-linked Vercel continuous deployment. The current sites were deployed by API direct source upload. GitHub repo now contains copies of the latest source, but production build/link is a separate later task.
- Commercial production readiness, uptime and load.

## Security advisory follow-up

Supabase security scan flagged: `pulseops_event_outbox` has RLS without policy (intentional deny); three restricted authenticated SECURITY DEFINER RPCs (role checks internally; review before changing); leaked-password protection currently disabled (enable when available). No client credentials are needed for the Code Mode agent to see repository files.

## QA strategy for Codex

- Validate all acceptance criteria in `docs/CODEX_N8N_HANDOFF.md`, using confirmed test Drive folder and internal notification recipients.
- Do not treat simulated role-switcher data as company usage.
- Keep `is_demo` records excluded from production summaries and external notifications by default.
- Confirm monotonic view checks and no duplicate webhook events.
- Verify production URLs after any Vercel Git setup change.
