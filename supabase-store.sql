-- Comenzile din magazin. Rulează în Supabase SQL Editor. Se poate rula din nou fără să piardă comenzi.
-- Nu atinge tabelele contorului. Comenzile nu păstrează codul anonim al telefonului,
-- ca numele și numărul de telefon să nu poată fi legate de provocările bifate.
do $$ begin
 create type public.store_order_status as enum ('noua','confirmata','platita','predata','anulata');
exception when duplicate_object then null;
end $$;
create table if not exists public.store_products (
 id text primary key
);
insert into public.store_products(id) values ('be-the-light'),('faith-mountains') on conflict(id) do nothing;
create table if not exists public.store_orders (
 id bigint generated always as identity primary key,
 created_at timestamptz not null default now(),
 status public.store_order_status not null default 'noua',
 name text not null,
 phone text not null,
 items jsonb not null,
 note text,
 request_id text not null unique
);
create index if not exists store_orders_status_idx on public.store_orders(status,created_at);
alter table public.store_products enable row level security;
alter table public.store_orders enable row level security;
revoke all on public.store_products from anon,authenticated;
revoke all on public.store_orders from anon,authenticated;
-- The site can only add an order through this function. It can never read or change one.
-- p_ref comes from the phone, so a retry after a lost response returns the same order instead of a new one.
create or replace function public.store_place_order(p_ref text,p_name text,p_phone text,p_items jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
 v_name text := btrim(p_name);
 v_phone text := btrim(p_phone);
 v_items jsonb := '[]'::jsonb;
 v_line jsonb;
 v_id bigint;
begin
 if (p_ref ~ '^[0-9a-f]{32}$') is not true then raise exception 'invalid ref'; end if;
 if (length(v_name) between 2 and 80) is not true then raise exception 'invalid name'; end if;
 if (v_phone ~ '^\+?[0-9 ().-]+$') is not true
  or length(regexp_replace(v_phone,'[^0-9]','','g')) not between 9 and 15 then raise exception 'invalid phone'; end if;
 if jsonb_typeof(p_items) is distinct from 'array' or jsonb_array_length(p_items) not between 1 and 30 then raise exception 'invalid items'; end if;
 for v_line in select value from jsonb_array_elements(p_items) loop
  if not exists(select 1 from public.store_products where id = v_line->>'item') then raise exception 'unknown item'; end if;
  if ((v_line->>'size') = any(array['XS','S','M','L','XL','XXL'])) is not true then raise exception 'invalid size'; end if;
  if ((v_line->>'qty') ~ '^[0-9]{1,2}$' and (v_line->>'qty')::integer between 1 and 20) is not true then raise exception 'invalid quantity'; end if;
  v_items := v_items || jsonb_build_object('item',v_line->>'item','size',v_line->>'size','qty',(v_line->>'qty')::integer);
 end loop;
 insert into public.store_orders(request_id,name,phone,items) values(p_ref,v_name,v_phone,v_items)
  on conflict(request_id) do nothing returning id into v_id;
 if v_id is null then select id into v_id from public.store_orders where request_id = p_ref; end if;
 return jsonb_build_object('status','saved','order_no',v_id);
end $$;
revoke all on function public.store_place_order(text,text,text,jsonb) from public;
grant execute on function public.store_place_order(text,text,text,jsonb) to anon,authenticated;
-- Admin only: how many of each item and size to order from the printer. Cancelled orders don't count.
create or replace view public.store_totals with (security_invoker = true) as
 select l.item,l.size,sum(l.qty)::integer as total
 from public.store_orders o
 cross join lateral jsonb_to_recordset(o.items) as l(item text,size text,qty integer)
 where o.status <> 'anulata'
 group by l.item,l.size
 order by l.item,array_position(array['XS','S','M','L','XL','XXL'],l.size);
revoke all on public.store_totals from anon,authenticated;
