-- Rulează în Supabase SQL Editor; activează Anonymous Sign-ins în Auth > Providers.
-- Nu adăuga chei secrete în codul site-ului.
create table if not exists public.mission_campaigns (
 id text primary key,
 goal integer not null default 1000 check (goal > 0),
 round_no integer not null default 1
);
insert into public.mission_campaigns(id,goal) values ('its-your-turn-1000',1000) on conflict(id) do nothing;
create table if not exists public.mission_completions (
 campaign_id text not null references public.mission_campaigns(id),
 user_id uuid not null references auth.users(id) on delete cascade,
 challenge_id text not null,
 completed_at timestamptz not null default now(),
 primary key(campaign_id,user_id,challenge_id),
 constraint valid_mission_challenge check(challenge_id ~ '^(serve|see|speak|encourage|pray)-[0-4]$')
);
create index if not exists mission_completions_campaign_idx on public.mission_completions(campaign_id);
alter table public.mission_campaigns enable row level security;
alter table public.mission_completions enable row level security;
revoke all on public.mission_campaigns from anon,authenticated;
revoke all on public.mission_completions from anon,authenticated;
-- Individual access only through narrowly scoped RPC methods.
create or replace function public.mission_snapshot(p_campaign text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare result jsonb;
begin
 if auth.uid() is null then raise exception 'authentication required'; end if;
 if not exists(select 1 from public.mission_campaigns where id=p_campaign) then raise exception 'unknown campaign'; end if;
 select jsonb_build_object(
  'round', (select round_no from public.mission_campaigns where id=p_campaign),
  'total', (select count(*) from public.mission_completions where campaign_id=p_campaign),
  'completed', coalesce((select jsonb_agg(challenge_id order by challenge_id) from public.mission_completions where campaign_id=p_campaign and user_id=auth.uid()), '[]'::jsonb),
  'by_category', jsonb_build_object(
   'serve',(select count(*) from public.mission_completions where campaign_id=p_campaign and split_part(challenge_id,'-',1)='serve'),
   'see',(select count(*) from public.mission_completions where campaign_id=p_campaign and split_part(challenge_id,'-',1)='see'),
   'speak',(select count(*) from public.mission_completions where campaign_id=p_campaign and split_part(challenge_id,'-',1)='speak'),
   'encourage',(select count(*) from public.mission_completions where campaign_id=p_campaign and split_part(challenge_id,'-',1)='encourage'),
   'pray',(select count(*) from public.mission_completions where campaign_id=p_campaign and split_part(challenge_id,'-',1)='pray')
  )
 ) into result;
 return result;
end $$;
create or replace function public.mission_complete(p_campaign text,p_challenge text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare n integer; v_goal integer;
begin
 if auth.uid() is null then raise exception 'authentication required'; end if;
 if p_challenge !~ '^(serve|see|speak|encourage|pray)-[0-4]$' then raise exception 'invalid challenge'; end if;
 -- Lock campaign row so parallel completions cannot exceed 1000.
 select goal into v_goal from public.mission_campaigns where id=p_campaign for update;
 if v_goal is null then raise exception 'unknown campaign'; end if;
 if exists(select 1 from public.mission_completions where campaign_id=p_campaign and user_id=auth.uid() and challenge_id=p_challenge) then
  return jsonb_build_object('status','already_completed');
 end if;
 select count(*) into n from public.mission_completions where campaign_id=p_campaign;
 if n >= v_goal then return jsonb_build_object('status','finished'); end if;
 insert into public.mission_completions(campaign_id,user_id,challenge_id) values(p_campaign,auth.uid(),p_challenge);
 return jsonb_build_object('status','saved','total',n+1);
end $$;
create or replace function public.mission_undo(p_campaign text,p_challenge text)
returns jsonb language plpgsql security definer set search_path = '' as $$
begin
 if auth.uid() is null then raise exception 'authentication required'; end if;
 -- Prevent editing global totals after the campaign finishes.
 perform 1 from public.mission_campaigns where id=p_campaign for update;
 if (select count(*) from public.mission_completions where campaign_id=p_campaign) >= (select goal from public.mission_campaigns where id=p_campaign) then
  raise exception 'campaign closed';
 end if;
 delete from public.mission_completions where campaign_id=p_campaign and user_id=auth.uid() and challenge_id=p_challenge;
 return jsonb_build_object('status','ok');
end $$;
revoke all on function public.mission_snapshot(text) from public,anon;
revoke all on function public.mission_complete(text,text) from public,anon;
revoke all on function public.mission_undo(text,text) from public,anon;
grant execute on function public.mission_snapshot(text) to authenticated;
grant execute on function public.mission_complete(text,text) to authenticated;
grant execute on function public.mission_undo(text,text) to authenticated;
-- Admin only: pune contorul la zero și începe o rundă nouă. Nu e accesibil din site.
-- Se rulează în SQL Editor: select public.mission_reset('its-your-turn-1000');
create or replace function public.mission_reset(p_campaign text)
returns void language plpgsql set search_path = '' as $$
begin
 update public.mission_campaigns set round_no=round_no+1 where id=p_campaign;
 if not found then raise exception 'unknown campaign'; end if;
 delete from public.mission_completions where campaign_id=p_campaign;
end $$;
revoke all on function public.mission_reset(text) from public,anon,authenticated;
