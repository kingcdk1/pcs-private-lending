-- ============================================================================
-- PCS Private Lending → shared CRM leads (Supabase project gcrzmiwgjvuujffbqjbq)
-- Run this ONCE in Supabase → SQL Editor → New query → paste → Run.
-- Idempotent: safe to run again; it will not duplicate or destroy anything.
-- ============================================================================

-- 1) Make sure the existing profiles table carries a role (admin|manager|staff)
alter table public.profiles add column if not exists email text;
alter table public.profiles add column if not exists role  text;
alter table public.profiles alter column role set default 'staff';
update public.profiles set role = 'staff' where role is null;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'profiles_role_check'
  ) then
    alter table public.profiles
      add constraint profiles_role_check check (role in ('admin','manager','staff'));
  end if;
end $$;

-- 2) Auto-create a profile row the moment someone signs up (default role = staff)
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, role)
  values (new.id, new.email, 'staff')
  on conflict (id) do update set email = excluded.email;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 3) The shared leads table (every business feeds this; "type" labels the source)
create table if not exists public.leads (
  id             uuid primary key default gen_random_uuid(),
  created_at     timestamptz not null default now(),
  type           text not null default 'private-lending',
  first_name     text,
  last_name      text,
  phone          text,
  email          text,
  loan_type      text,
  has_property   text,
  property_type  text,
  purchase_price text,
  credit_score   text,
  consent        boolean default false,
  source         text,
  status         text not null default 'new',
  raw            jsonb
);

-- 4) Security: public can SUBMIT a lead; only admin/manager can READ/UPDATE them
alter table public.leads enable row level security;

drop policy if exists leads_insert_public on public.leads;
create policy leads_insert_public on public.leads
  for insert to anon, authenticated with check (true);

drop policy if exists leads_select_staff on public.leads;
create policy leads_select_staff on public.leads
  for select to authenticated
  using (exists (select 1 from public.profiles p
                 where p.id = auth.uid() and p.role in ('admin','manager')));

drop policy if exists leads_update_staff on public.leads;
create policy leads_update_staff on public.leads
  for update to authenticated
  using (exists (select 1 from public.profiles p
                 where p.id = auth.uid() and p.role in ('admin','manager')))
  with check (exists (select 1 from public.profiles p
                 where p.id = auth.uid() and p.role in ('admin','manager')));

-- 5) Make Cyrus an admin. Harmless to run now (0 rows until first login);
--    re-run this one line AFTER you log in once, or it auto-applies on next run.
update public.profiles set role = 'admin'
  where email = 'fivestoneinvestments@gmail.com';

-- Done. Leads from the lending site now land in public.leads,
-- visible only to admin/manager accounts via the /admin dashboard.
