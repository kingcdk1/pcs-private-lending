-- PCS Lending — notify recipients (the "where leads go" list).
-- Run ONCE in the shared Supabase project (gcrzmiwgjvuujffbqjbq) → SQL Editor.
-- api/lead.js reads this (enabled=true) to decide who gets the lead email;
-- if it's empty / not wired, api falls back to the LEAD_EMAIL_TO env var.
create table if not exists public.notify_recipients (
  id         uuid primary key default gen_random_uuid(),
  site       text not null default 'private-lending',
  email      text not null,
  label      text,
  enabled    boolean not null default true,
  created_at timestamptz default now(),
  unique (site, email)
);

alter table public.notify_recipients enable row level security;

-- Only admins/managers can see or manage the list (in-app toggle later).
drop policy if exists nr_admin_all on public.notify_recipients;
create policy nr_admin_all on public.notify_recipients
  for all to authenticated
  using      (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('admin','manager')))
  with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('admin','manager')));

-- Seed the owner as the default recipient (notify defaults to you).
insert into public.notify_recipients (site, email, label, enabled)
values ('private-lending', 'fivestoneinvestments@gmail.com', 'Cyrus (owner)', true)
on conflict (site, email) do nothing;
