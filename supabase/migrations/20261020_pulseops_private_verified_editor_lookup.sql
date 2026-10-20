-- Private, narrowly scoped verified-editor lookup to avoid broad service_role access to auth.users.
create schema if not exists pulseops_private;
revoke all on schema pulseops_private from public, anon, authenticated;
grant usage on schema pulseops_private to service_role;
create or replace function pulseops_private.first_verified_editor()
returns uuid language sql stable security definer set search_path=''
as $fn$
  select m.user_id from public.pulseops_members m
  join auth.users u on u.id=m.user_id
  where m.role='editor' and u.email_confirmed_at is not null
  order by m.created_at,m.user_id
  limit 1;
$fn$;
revoke all on function pulseops_private.first_verified_editor() from public,anon,authenticated;
grant execute on function pulseops_private.first_verified_editor() to service_role;

-- Keep public ingest SECURITY INVOKER and service-role-only; replace only editor lookup.
CREATE OR REPLACE FUNCTION public.pulseops_ingest_drive_clip(p_source_file_id text, p_event_key text, p_filename text, p_mime_type text, p_size_bytes bigint, p_parent_folder_id text, p_drive_revision_id text DEFAULT NULL::text, p_drive_created_at timestamp with time zone DEFAULT NULL::timestamp with time zone, p_drive_modified_at timestamp with time zone DEFAULT NULL::timestamp with time zone, p_drive_web_url text DEFAULT NULL::text, p_metadata jsonb DEFAULT '{}'::jsonb)
 RETURNS TABLE(clip_id uuid, job_id uuid, event_id bigint, duplicate boolean, job_status text)
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare
  v_receipt public.pulseops_integration_receipts;
  v_clip public.pulseops_source_clips;
  v_job public.pulseops_jobs;
  v_outbox_id bigint;
  v_editor uuid;
  v_job_status text;
begin
  if current_user <> 'service_role' then
    raise exception 'Server integration role required' using errcode = '42501';
  end if;
  if length(trim(coalesce(p_source_file_id, ''))) not between 1 and 200
     or length(trim(coalesce(p_event_key, ''))) not between 1 and 300
     or length(trim(coalesce(p_filename, ''))) not between 1 and 255
     or length(trim(coalesce(p_parent_folder_id, ''))) not between 1 and 200
     or p_mime_type not in ('video/mp4', 'video/quicktime', 'video/webm')
     or p_size_bytes is null or p_size_bytes < 0 or p_size_bytes > 5368709120 then
    raise exception 'Invalid completed Drive video metadata';
  end if;
  if p_metadata is null or jsonb_typeof(p_metadata) <> 'object' then
    raise exception 'Metadata must be a JSON object';
  end if;

  insert into public.pulseops_integration_receipts(source, event_key, event_type)
  values ('google_drive', p_event_key, 'clip.uploaded')
  on conflict (source, event_key) do update set last_received_at = now()
  returning * into v_receipt;

  if v_receipt.id is not null and v_receipt.source_clip_id is not null then
    return query select v_receipt.source_clip_id, v_receipt.job_id, null::bigint, true, v_receipt.status;
    return;
  end if;

  select * into v_clip from public.pulseops_source_clips where drive_file_id = p_source_file_id for update;
  if not found then
    insert into public.pulseops_source_clips(
      drive_file_id, drive_revision_id, source_event_key, filename, mime_type, size_bytes,
      drive_created_at, drive_modified_at, drive_web_url, parent_folder_id, status, metadata
    ) values (
      trim(p_source_file_id), nullif(trim(p_drive_revision_id), ''), trim(p_event_key), trim(p_filename), p_mime_type, p_size_bytes,
      p_drive_created_at, p_drive_modified_at, nullif(trim(p_drive_web_url), ''), trim(p_parent_folder_id), 'ready',
      jsonb_build_object('source', 'google_drive', 'mime_type', p_mime_type, 'size_bytes', p_size_bytes,
        'drive_revision_id', nullif(trim(p_drive_revision_id), ''), 'metadata', p_metadata)
    ) returning * into v_clip;
  else
    update public.pulseops_source_clips set
      drive_revision_id = coalesce(nullif(trim(p_drive_revision_id), ''), drive_revision_id),
      drive_modified_at = coalesce(p_drive_modified_at, drive_modified_at),
      last_seen_at = now(), updated_at = now()
    where id = v_clip.id returning * into v_clip;
  end if;

  select pulseops_private.first_verified_editor() into v_editor;
  v_job_status := case when v_editor is null then 'unassigned' else 'ready' end;

  insert into public.pulseops_jobs(source_clip_id, title, status, editor_id, assignment_note, is_demo)
  values (v_clip.id, left(trim(p_filename), 180), v_job_status, v_editor,
    case when v_editor is null then 'No verified Editor membership was available at intake.' else null end, false)
  on conflict (source_clip_id) do update set
    editor_id = coalesce(public.pulseops_jobs.editor_id, excluded.editor_id),
    status = case when public.pulseops_jobs.status = 'unassigned' and excluded.editor_id is not null then 'ready' else public.pulseops_jobs.status end,
    assignment_note = case when excluded.editor_id is not null then null else public.pulseops_jobs.assignment_note end,
    updated_at = now()
  returning * into v_job;

  update public.pulseops_integration_receipts set
    source_clip_id = v_clip.id, job_id = v_job.id, status = 'accepted', last_received_at = now()
  where id = v_receipt.id;

  insert into public.pulseops_event_outbox(event_key, source, event_type, occurred_at, payload)
  values (
    p_event_key, 'google_drive', 'clip.uploaded', now(),
    jsonb_build_object('event_type', 'clip.uploaded', 'source', 'google_drive', 'clip_id', v_clip.id,
      'job_id', v_job.id, 'source_file_id', trim(p_source_file_id), 'status', v_job.status,
      'occurred_at', now())
  )
  on conflict do nothing
  returning id into v_outbox_id;

  return query select v_clip.id, v_job.id, v_outbox_id, false, v_job.status;
end;
$function$
;
revoke all on function public.pulseops_ingest_drive_clip(text,text,text,text,bigint,text,text,timestamptz,timestamptz,text,jsonb) from public,anon,authenticated;
grant execute on function public.pulseops_ingest_drive_clip(text,text,text,text,bigint,text,text,timestamptz,timestamptz,text,jsonb) to service_role;