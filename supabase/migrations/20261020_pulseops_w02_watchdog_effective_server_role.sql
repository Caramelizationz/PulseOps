-- W02 supports Supabase sb_secret credentials; preserve service-role-only execution.
CREATE OR REPLACE FUNCTION public.pulseops_run_sla_watchdog(p_now timestamp with time zone DEFAULT now())
 RETURNS SETOF pulseops_sla_alerts
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
  if current_user <> 'service_role' then
    raise exception 'Server integration role required' using errcode = '42501';
  end if;
  create temp table pulseops_sla_candidates(
    dedupe_key text primary key,
    job_id uuid,
    frame_id uuid,
    frame_version integer not null,
    alert_type text not null,
    checkpoint integer not null,
    breached_at timestamptz not null
  ) on commit drop;

  insert into pulseops_sla_candidates
  select 'job:' || j.id || ':1:raw_uploaded:0', j.id, null, 1, 'raw_uploaded', 0, c.first_seen_at + interval '120 minutes'
  from public.pulseops_jobs j
  join public.pulseops_source_clips c on c.id = j.source_clip_id
  where not c.is_demo and j.status in ('unassigned', 'ready')
    and c.first_seen_at <= p_now - interval '120 minutes';

  insert into pulseops_sla_candidates
  select 'frame:' || f.id || ':' || f.version || ':awaiting_approval:0', f.job_id, f.id, f.version, 'awaiting_approval', 0, f.submitted_at + interval '45 minutes'
  from public.pulseops_frames f
  where not f.is_demo and f.status = 'awaiting_approval' and f.submitted_at is not null
    and f.submitted_at <= p_now - interval '45 minutes';

  insert into pulseops_sla_candidates
  select 'frame:' || f.id || ':' || f.version || ':revision_requested:0', f.job_id, f.id, f.version, 'revision_requested', 0, f.updated_at + interval '90 minutes'
  from public.pulseops_frames f
  where not f.is_demo and f.status = 'revision_requested'
    and f.updated_at <= p_now - interval '90 minutes';

  insert into pulseops_sla_candidates
  select 'frame:' || f.id || ':' || f.version || ':approved:0', f.job_id, f.id, f.version, 'approved', 0, f.publish_due_at
  from public.pulseops_frames f
  where not f.is_demo and f.status = 'approved' and f.publish_due_at is not null
    and f.publish_due_at <= p_now;

  insert into pulseops_sla_candidates
  select 'frame:' || f.id || ':' || f.version || ':published:' || x.checkpoint, f.job_id, f.id, f.version, 'published', x.checkpoint,
    f.published_at + make_interval(hours => x.checkpoint) + interval '10 minutes'
  from public.pulseops_frames f
  cross join lateral (values (1, f.views_1h), (4, f.views_4h), (12, f.views_12h), (23, f.views_23h)) x(checkpoint, recorded_views)
  where not f.is_demo and f.status = 'published' and f.published_at is not null and x.recorded_views is null
    and f.published_at + make_interval(hours => x.checkpoint) + interval '10 minutes' <= p_now;

  insert into public.pulseops_sla_alerts(dedupe_key, job_id, frame_id, frame_version, alert_type, checkpoint, first_breached_at, last_seen_at, state, notification_status)
  select c.dedupe_key, c.job_id, c.frame_id, c.frame_version, c.alert_type, c.checkpoint, c.breached_at, p_now, 'open', 'pending'
  from pulseops_sla_candidates c
  on conflict (dedupe_key) do update set last_seen_at = excluded.last_seen_at, updated_at = now(), state = case when public.pulseops_sla_alerts.state = 'resolved' then 'open' else public.pulseops_sla_alerts.state end;

  update public.pulseops_sla_alerts a
  set state = 'resolved', resolved_at = coalesce(a.resolved_at, p_now), updated_at = p_now, notification_status = 'pending'
  where a.state = 'open' and not exists (select 1 from pulseops_sla_candidates c where c.dedupe_key = a.dedupe_key);

  return query select * from public.pulseops_sla_alerts where state = 'open' order by first_breached_at;
end;
$function$
;
revoke all on function public.pulseops_run_sla_watchdog(timestamptz) from public,anon,authenticated;
grant execute on function public.pulseops_run_sla_watchdog(timestamptz) to service_role;