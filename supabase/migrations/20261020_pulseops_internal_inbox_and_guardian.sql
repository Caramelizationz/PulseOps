
create table if not exists public.pulseops_internal_notifications (
 id bigint generated always as identity primary key,
 event_outbox_id bigint unique references public.pulseops_event_outbox(id) on delete set null,
 sla_alert_id uuid unique references public.pulseops_sla_alerts(id) on delete set null,
 notification_type text not null, headline text not null, details text not null default '',
 created_at timestamptz not null default now(), acknowledged_at timestamptz,
 constraint one_notification_source check ((event_outbox_id is not null) <> (sla_alert_id is not null))
);
alter table public.pulseops_internal_notifications enable row level security;
revoke all on public.pulseops_internal_notifications from anon,authenticated;
grant select on public.pulseops_internal_notifications to authenticated;
grant all on public.pulseops_internal_notifications to service_role;
create policy "Founder only sees internal inbox" on public.pulseops_internal_notifications
 for select to authenticated using(exists(select 1 from public.pulseops_members m where m.user_id=(select auth.uid()) and m.role='founder'));
create table if not exists public.pulseops_system_health (
 component text primary key,last_success_at timestamptz not null default now(),
 last_details jsonb not null default '{}'::jsonb,updated_at timestamptz not null default now());
alter table public.pulseops_system_health enable row level security;
revoke all on public.pulseops_system_health from anon,authenticated;
grant select on public.pulseops_system_health to authenticated;
grant all on public.pulseops_system_health to service_role;
create policy "Founder only sees system health" on public.pulseops_system_health
 for select to authenticated using(exists(select 1 from public.pulseops_members m where m.user_id=(select auth.uid()) and m.role='founder'));

create or replace function public.pulseops_reconcile_internal_inbox(p_limit integer default 50)
returns jsonb language plpgsql security invoker set search_path=''
as $body$
declare v_events integer:=0;v_alerts integer:=0;
begin
 if current_user<>'service_role' then raise exception 'Server integration role required' using errcode='42501'; end if;
 with candidates as (
  select o.id,o.event_type,o.payload from public.pulseops_event_outbox o
  where not exists(select 1 from public.pulseops_internal_notifications n where n.event_outbox_id=o.id)
  and ((o.frame_id is not null and exists(select 1 from public.pulseops_frames f where f.id=o.frame_id and not f.is_demo))
  or exists(select 1 from public.pulseops_jobs j where j.id::text=o.payload->>'job_id' and not j.is_demo))
  order by o.id for update of o skip locked limit least(greatest(coalesce(p_limit,50),1),100)
 ), inserted as (
  insert into public.pulseops_internal_notifications(event_outbox_id,notification_type,headline,details)
  select id,'event',case event_type when 'clip.uploaded' then 'New creator upload' when 'frame.submit' then 'Founder approval requested'
    when 'frame.revise' then 'Revision requested' when 'frame.approve' then 'Frame approved' when 'frame.publish' then 'Frame published'
    else 'Content workflow update' end,
    left('Event: '||event_type||' - ID: '||id,500) from candidates
  on conflict do nothing returning id
 ) select count(*) into v_events from inserted;
 with candidate_alerts as (
  select a.id,a.alert_type,a.checkpoint from public.pulseops_sla_alerts a
  where a.state='open' and not exists(select 1 from public.pulseops_internal_notifications n where n.sla_alert_id=a.id)
  and ((a.frame_id is not null and exists(select 1 from public.pulseops_frames f where f.id=a.frame_id and not f.is_demo))
  or (a.job_id is not null and exists(select 1 from public.pulseops_jobs j where j.id=a.job_id and not j.is_demo)))
  order by a.id for update of a skip locked limit least(greatest(coalesce(p_limit,50),1),100)
 ), inserted as (
  insert into public.pulseops_internal_notifications(sla_alert_id,notification_type,headline,details)
  select id,'sla','SLA exception: '||alert_type, 'Missing milestone or overdue - checkpoint '||checkpoint from candidate_alerts
  on conflict do nothing returning id
 ) select count(*) into v_alerts from inserted;
 insert into public.pulseops_system_health(component,last_success_at,last_details,updated_at)
 values('W03',now(),jsonb_build_object('inbox_events_added',v_events,'inbox_alerts_added',v_alerts),now())
 on conflict(component) do update set last_success_at=excluded.last_success_at,last_details=excluded.last_details,updated_at=now();
 return jsonb_build_object('inbox_events_added',v_events,'inbox_alerts_added',v_alerts,'channel','founder_in_app_only','external_messages_sent',0);
end;$body$;
revoke all on function public.pulseops_reconcile_internal_inbox(integer) from public,anon,authenticated;
grant execute on function public.pulseops_reconcile_internal_inbox(integer) to service_role;

create or replace function public.pulseops_guardian_recover()
returns jsonb language plpgsql security invoker set search_path=''
as $body$
declare v_reclaimed integer:=0;v_open integer:=0;v_pending integer:=0;
begin
 if current_user<>'service_role' then raise exception 'Server integration role required' using errcode='42501'; end if;
 update public.pulseops_event_outbox set lease_token=null,lease_until=null,last_error=coalesce(last_error,'Recovered expired delivery lease')
 where delivered_at is null and dead_lettered_at is null and lease_until is not null and lease_until<now() and delivery_attempts<5;
 get diagnostics v_reclaimed=row_count;
 select count(*) into v_open from public.pulseops_sla_alerts where state='open';
 select count(*) into v_pending from public.pulseops_event_outbox where delivered_at is null and dead_lettered_at is null;
 insert into public.pulseops_system_health(component,last_success_at,last_details,updated_at)
 values('W06',now(),jsonb_build_object('leases_reclaimed',v_reclaimed,'open_sla_alerts',v_open,'pending_external_events',v_pending),now())
 on conflict(component) do update set last_success_at=excluded.last_success_at,last_details=excluded.last_details,updated_at=now();
 return jsonb_build_object('leases_reclaimed',v_reclaimed,'open_sla_alerts',v_open,'pending_external_events',v_pending);
end;$body$;
revoke all on function public.pulseops_guardian_recover() from public,anon,authenticated;
grant execute on function public.pulseops_guardian_recover() to service_role;
