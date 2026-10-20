-- PulseOps QA-only video intake. Whitelist verified public sample-video Drive IDs.
-- Do not use for production creator footage.
create function public.pulseops_ingest_qa_video(
 p_source_file_id text,
 p_event_key text,
 p_filename text,
 p_mime_type text,
 p_size_bytes bigint,
 p_parent_folder_id text,
 p_drive_revision_id text default null,
 p_drive_created_at timestamptz default null,
 p_drive_modified_at timestamptz default null,
 p_drive_web_url text default null,
 p_metadata jsonb default '{}'::jsonb
)
returns table (clip_id uuid, job_id uuid, event_id bigint, duplicate boolean, job_status text)
language plpgsql
security invoker
set search_path = ''
as $body$
declare
  v_result record;
begin
  if coalesce(current_setting('request.jwt.claim.role',true),'') <> 'service_role' then
    raise exception 'Server integration role required' using errcode='42501';
  end if;
  if p_parent_folder_id <> '1wN6mDtXSyTJLKma_-Uf4z4CmHhXx1tNh'
    or p_mime_type <> 'video/mp4'
    or p_event_key is null
    or left(p_event_key, length('gdrive:' || p_source_file_id || ':')) <> 'gdrive:' || p_source_file_id || ':'
    or p_metadata is null
    or jsonb_typeof(p_metadata) <> 'object'
    or not exists (
      select 1 from (values
       ('1CdYX44ohTne7F7MhnmobI0w3p7dDOnwm'::text,'pulseops-test-01-landscape-480p.mp4'::text,1048576::bigint),
     ('1OVxyNR1d5K5KVU_SrE0o08sPYoAwYCyl'::text,'pulseops-test-02-landscape-720p.mp4'::text,5242880::bigint),
     ('1HAoj49fKEQRjTUqVzqjqJCMXEsQqwVjy'::text,'pulseops-test-03-portrait-1080p.mp4'::text,14390087::bigint),
     ('1AkqLYFXnZnbAh2x2x72aTgcrfL4YRJAz'::text,'pulseops-test-04-square-1080p.mp4'::text,9371436::bigint),
     ('1sEW429GyqjYckvmJtr1nmTv7sFnh2wam'::text,'pulseops-test-05-silent-720p.mp4'::text,4334089::bigint)
      ) as whitelist(drive_id, filename, file_size)
      where drive_id = p_source_file_id
        and filename = p_filename
        and file_size = p_size_bytes
    ) then
    raise exception 'Not an approved PulseOps QA video'
      using errcode='22023';
  end if;

  select x.* into strict v_result
  from public.pulseops_ingest_drive_clip(
    p_source_file_id, p_event_key, p_filename, p_mime_type, p_size_bytes,
    p_parent_folder_id, p_drive_revision_id, p_drive_created_at,
    p_drive_modified_at, p_drive_web_url,
    p_metadata || jsonb_build_object('qa_only',true,'demo_source','pulseops_approved_test_videos')
  ) as x;

  -- These flags and event suppression happen within the same uncommitted transaction.
  -- A dispatcher cannot observe any intermediate notification event.
  update public.pulseops_source_clips c
    set is_demo=true,
        metadata = c.metadata || jsonb_build_object('qa_only',true)
    where c.id=v_result.clip_id;

  update public.pulseops_jobs j set is_demo=true
    where j.id=v_result.job_id;

  if v_result.event_id is not null then
    delete from public.pulseops_event_outbox
    where id=v_result.event_id
      and source='google_drive'
      and event_key=p_event_key;
  end if;

  return query select
    v_result.clip_id::uuid,
    v_result.job_id::uuid,
    null::bigint,
    v_result.duplicate::boolean,
    (select j.status from public.pulseops_jobs j where j.id=v_result.job_id)::text;
end;
$body$;
revoke all on function public.pulseops_ingest_qa_video(text,text,text,text,bigint,text,text,timestamptz,timestamptz,text,jsonb) from public,anon,authenticated;
grant execute on function public.pulseops_ingest_qa_video(text,text,text,text,bigint,text,text,timestamptz,timestamptz,text,jsonb) to service_role;