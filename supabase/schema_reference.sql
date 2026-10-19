-- PulseOps baseline/schema reference extracted from ACTIVE Supabase project.
-- Project: zpeswzwyltgjhyvtqsoa
-- IMPORTANT: Existing migrations ALREADY APPLIED remotely; DO NOT replay this file.
-- This is for Codex orientation and provisioning a new empty project if separately approved.
-- It contains NO account IDs, sample data or service-role keys.
-- Foundational functions and policies below were fetched from pg_catalog/pg_policies.

-- AUTH MEMBERSHIP
CREATE TABLE public.pulseops_members (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name text NOT NULL DEFAULT 'Team member',
  role text NOT NULL CHECK(role IN ('founder','editor')),
  created_at timestamptz NOT NULL DEFAULT now()
);
-- FRAME RECORDS
CREATE TABLE public.pulseops_frames (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL CHECK(char_length(title) BETWEEN 3 AND 180),
  source_clip_id text NOT NULL DEFAULT '',
  editor_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  editor_name text NOT NULL DEFAULT 'Unassigned',
  status text NOT NULL DEFAULT 'raw_uploaded' CHECK(status IN ('raw_uploaded','editing','awaiting_approval','revision_requested','approved','published')),
  priority text NOT NULL DEFAULT 'normal' CHECK(priority IN ('normal','high')),
  media_path text,
  sample_video_url text,
  version integer NOT NULL DEFAULT 1 CHECK(version>0),
  revision_note text,
  uploaded_at timestamptz NOT NULL DEFAULT now(),
  edit_started_at timestamptz,
  submitted_at timestamptz,
  approved_at timestamptz,
  published_at timestamptz,
  publish_due_at timestamptz,
  views_1h bigint CHECK(views_1h>=0),
  views_4h bigint CHECK(views_4h>=0),
  views_12h bigint CHECK(views_12h>=0),
  views_23h bigint CHECK(views_23h>=0),
  is_demo boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX pulseops_frames_status_idx ON public.pulseops_frames(status);
CREATE INDEX pulseops_frames_editor_idx ON public.pulseops_frames(editor_id);

CREATE TABLE public.pulseops_activity (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  frame_id uuid NOT NULL REFERENCES public.pulseops_frames(id) ON DELETE CASCADE,
  actor_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  actor_role text,
  action text NOT NULL,
  note text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX pulseops_activity_recent_idx ON public.pulseops_activity(created_at DESC);

CREATE TABLE public.pulseops_event_outbox (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  frame_id uuid REFERENCES public.pulseops_frames(id) ON DELETE SET NULL,
  event_type text NOT NULL,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  delivered_at timestamptz
);
ALTER TABLE public.pulseops_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pulseops_frames ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pulseops_activity ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pulseops_event_outbox ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.pulseops_members,public.pulseops_frames,public.pulseops_activity,public.pulseops_event_outbox FROM anon,authenticated;
GRANT SELECT ON public.pulseops_members,public.pulseops_frames,public.pulseops_activity TO authenticated;

-- PRIVATE STORAGE (do not make public)
INSERT INTO storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
 VALUES ('pulseops-media','pulseops-media',false,104857600,ARRAY['video/mp4','video/quicktime','video/webm','image/jpeg','image/png'])
 ON CONFLICT (id) DO NOTHING;

-- POLICIES as introspected (may depend on function order below)
CREATE POLICY "Only approved members read history" ON public.pulseops_activity AS PERMISSIVE FOR SELECT TO authenticated
 USING ((EXISTS ( SELECT 1
   FROM pulseops_members m
  WHERE (m.user_id = ( SELECT auth.uid() AS uid)))));

CREATE POLICY "Only approved members read frames" ON public.pulseops_frames AS PERMISSIVE FOR SELECT TO authenticated
 USING ((EXISTS ( SELECT 1
   FROM pulseops_members m
  WHERE (m.user_id = ( SELECT auth.uid() AS uid)))));

CREATE POLICY "Members may see own role" ON public.pulseops_members AS PERMISSIVE FOR SELECT TO authenticated
 USING ((( SELECT auth.uid() AS uid) = user_id));

CREATE POLICY "PulseOps editor uploads to own prefix" ON storage.objects AS PERMISSIVE FOR INSERT TO authenticated
 WITH CHECK (((bucket_id = 'pulseops-media'::text) AND ((storage.foldername(name))[1] = (( SELECT auth.uid() AS uid))::text) AND (EXISTS ( SELECT 1
   FROM pulseops_members m
  WHERE (m.user_id = ( SELECT auth.uid() AS uid))))));

CREATE POLICY "PulseOps members view private media" ON storage.objects AS PERMISSIVE FOR SELECT TO authenticated
 USING (((bucket_id = 'pulseops-media'::text) AND (EXISTS ( SELECT 1
   FROM pulseops_members m
  WHERE (m.user_id = ( SELECT auth.uid() AS uid))))));

-- AUTHORITATIVE RPC DEFINITIONS
CREATE OR REPLACE FUNCTION public.pulseops_action(p_frame_id uuid, p_action text, p_note text DEFAULT NULL::text, p_checkpoint integer DEFAULT NULL::integer, p_views bigint DEFAULT NULL::bigint)
 RETURNS pulseops_frames
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_uid uuid := auth.uid(); v_role text; v_frame public.pulseops_frames; v_name text;
begin
  if v_uid is null then raise exception 'Sign in required' using errcode='42501'; end if;
  select role,display_name into v_role,v_name from public.pulseops_members where user_id=v_uid;
  if v_role not in ('founder','editor') or v_role is null then raise exception 'Member access required' using errcode='42501'; end if;
  select * into v_frame from public.pulseops_frames where id=p_frame_id for update;
  if not found then raise exception 'Frame not found'; end if;
  if p_action='start_edit' then
    if v_role <> 'editor' or v_frame.status not in ('raw_uploaded','revision_requested') or (v_frame.editor_id is not null and v_frame.editor_id <> v_uid) then raise exception 'Not permitted to start edit' using errcode='42501'; end if;
    update public.pulseops_frames set status='editing',editor_id=v_uid,editor_name=v_name,edit_started_at=now(),updated_at=now() where id=p_frame_id;
  elsif p_action='submit' then
    if v_role <> 'editor' or v_frame.editor_id <> v_uid or v_frame.status <> 'editing' then raise exception 'Not permitted to submit' using errcode='42501'; end if;
    update public.pulseops_frames set status='awaiting_approval', submitted_at=now(),version=version+1, revision_note=null, updated_at=now() where id=p_frame_id;
  elsif p_action='approve' then
    if v_role <> 'founder' or v_frame.status <> 'awaiting_approval' then raise exception 'Founder approval required' using errcode='42501'; end if;
    update public.pulseops_frames set status='approved',approved_at=now(),updated_at=now() where id=p_frame_id;
  elsif p_action='revise' then
    if v_role <> 'founder' or v_frame.status <> 'awaiting_approval' then raise exception 'Founder review required' using errcode='42501'; end if;
    if char_length(trim(coalesce(p_note,''))) < 8 then raise exception 'Specific revision note required'; end if;
    update public.pulseops_frames set status='revision_requested',revision_note=left(trim(p_note),1500),updated_at=now() where id=p_frame_id;
  elsif p_action='publish' then
    if v_frame.status <> 'approved' or (v_role <> 'founder' and (v_role <> 'editor' or v_frame.editor_id <> v_uid)) then raise exception 'Cannot mark as published' using errcode='42501'; end if;
    update public.pulseops_frames set status='published',published_at=now(),updated_at=now() where id=p_frame_id;
  elsif p_action='record_views' then
    if v_frame.status <> 'published' or (v_role <> 'founder' and (v_role <> 'editor' or v_frame.editor_id <> v_uid)) then raise exception 'Cannot record views' using errcode='42501'; end if;
    if p_checkpoint not in (1,4,12,23) or p_views is null or p_views < 0 then raise exception 'Invalid checkpoint'; end if;
    if (p_checkpoint=4 and v_frame.views_1h>p_views) or
       (p_checkpoint=12 and coalesce(v_frame.views_4h,v_frame.views_1h,0)>p_views) or
       (p_checkpoint=23 and coalesce(v_frame.views_12h,v_frame.views_4h,v_frame.views_1h,0)>p_views) or
       (p_checkpoint=1 and (v_frame.views_4h<p_views or v_frame.views_12h<p_views or v_frame.views_23h<p_views)) or
       (p_checkpoint=4 and (v_frame.views_12h<p_views or v_frame.views_23h<p_views)) or
       (p_checkpoint=12 and v_frame.views_23h<p_views)
    then raise exception 'View counts must be monotonic'; end if;
    update public.pulseops_frames set
       views_1h=case when p_checkpoint=1 then p_views else views_1h end,
       views_4h=case when p_checkpoint=4 then p_views else views_4h end,
       views_12h=case when p_checkpoint=12 then p_views else views_12h end,
       views_23h=case when p_checkpoint=23 then p_views else views_23h end,
       updated_at=now()
    where id=p_frame_id;
  else
    raise exception 'Unknown action';
  end if;
  insert into public.pulseops_activity(frame_id,actor_id,actor_role,action,note)
  values(p_frame_id,v_uid,v_role,p_action,case when p_action='record_views' then p_checkpoint::text || 'h: ' || p_views::text else left(coalesce(p_note,''),1500) end);
  insert into public.pulseops_event_outbox(frame_id,event_type,payload)
  values(p_frame_id,'frame.'||p_action,jsonb_build_object('frame_id',p_frame_id,'action',p_action,'actor',v_uid));
  select * into v_frame from public.pulseops_frames where id=p_frame_id;
  return v_frame;
end $function$


REVOKE ALL ON FUNCTION public.pulseops_action(p_frame_id uuid, p_action text, p_note text, p_checkpoint integer, p_views bigint) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.pulseops_action(p_frame_id uuid, p_action text, p_note text, p_checkpoint integer, p_views bigint) TO authenticated;

CREATE OR REPLACE FUNCTION public.pulseops_create_frame(p_title text, p_source_clip_id text DEFAULT ''::text, p_due timestamp with time zone DEFAULT NULL::timestamp with time zone, p_media_path text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_uid uuid := auth.uid(); v_role text; v_id uuid;
begin
  if v_uid is null then raise exception 'Sign in required' using errcode='42501'; end if;
  select role into v_role from public.pulseops_members where user_id=v_uid;
  if v_role not in ('founder','editor') or v_role is null then raise exception 'Access denied' using errcode='42501'; end if;
  if length(trim(coalesce(p_title,''))) not between 3 and 180 then raise exception 'Invalid title'; end if;
  if p_media_path is not null and split_part(p_media_path,'/',1) <> v_uid::text then raise exception 'Invalid media path'; end if;
  insert into public.pulseops_frames(title,source_clip_id,editor_id,editor_name,publish_due_at,media_path)
  values(trim(p_title),left(coalesce(p_source_clip_id,''),120),case when v_role='editor' then v_uid else null end,case when v_role='editor' then (select display_name from public.pulseops_members where user_id=v_uid) else 'Unassigned' end,p_due,p_media_path)
  returning id into v_id;
  insert into public.pulseops_activity(frame_id,actor_id,actor_role,action,note) values(v_id,v_uid,v_role,'created','New frame registered');
  insert into public.pulseops_event_outbox(frame_id,event_type,payload) values(v_id,'frame.created',jsonb_build_object('frame_id',v_id));
  return v_id;
end $function$


REVOKE ALL ON FUNCTION public.pulseops_create_frame(p_title text, p_source_clip_id text, p_due timestamp with time zone, p_media_path text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.pulseops_create_frame(p_title text, p_source_clip_id text, p_due timestamp with time zone, p_media_path text) TO authenticated;

CREATE OR REPLACE FUNCTION public.pulseops_grant_editor(p_email text, p_display_name text DEFAULT 'Video Editor'::text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_founder uuid := auth.uid(); v_editor uuid; v_confirmed timestamptz; v_current_role text;
begin
  if v_founder is null or not exists(
    select 1 from public.pulseops_members
    where user_id=v_founder and role='founder'
  ) then
    raise exception 'Only a Founder can authorize editors' using errcode='42501';
  end if;
  if length(trim(coalesce(p_email,''))) < 5 or length(p_email)>254 then
    raise exception 'Valid email required';
  end if;
  select u.id,u.email_confirmed_at into v_editor,v_confirmed
    from auth.users u where lower(u.email)=lower(trim(p_email)) limit 1;
  if v_editor is null then
    raise exception 'User must sign in with a verified email before role assignment';
  end if;
  if v_confirmed is null then
    raise exception 'Editor email must be confirmed';
  end if;
  select role into v_current_role from public.pulseops_members where user_id=v_editor;
  if v_current_role='founder' then
    raise exception 'Founder role cannot be replaced using editor invitation';
  end if;
  insert into public.pulseops_members(user_id,display_name,role)
  values(v_editor,left(trim(coalesce(nullif(trim(p_display_name),''),'Video Editor')),100),'editor')
  on conflict (user_id) do update set
    role='editor', display_name=excluded.display_name;
  return 'Editor access granted';
end;
$function$


REVOKE ALL ON FUNCTION public.pulseops_grant_editor(p_email text, p_display_name text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.pulseops_grant_editor(p_email text, p_display_name text) TO authenticated;
