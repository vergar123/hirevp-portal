-- Core tables: admin_profiles, clients, vps, client_vp_assignments

create table public.admin_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  email text not null,
  role text not null default 'admin' check (role in ('admin', 'super_admin')),
  created_at timestamptz not null default now()
);

create table public.clients (
  id uuid primary key default gen_random_uuid(),
  company_name text not null,
  contact_name text,
  contact_email text,
  status text not null default 'active' check (status in ('active', 'paused', 'offboarded')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.vps (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  email text not null unique,
  timezone text not null default 'UTC',
  status text not null default 'active' check (status in ('active', 'paused', 'offboarded')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.client_vp_assignments (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  vp_id uuid not null references public.vps(id) on delete cascade,
  role_title text,
  started_at date not null default current_date,
  ended_at date,
  created_at timestamptz not null default now()
);

-- Postgres doesn't index FK columns automatically
create index idx_assignments_client on public.client_vp_assignments(client_id);
create index idx_assignments_vp on public.client_vp_assignments(vp_id);

-- Keep updated_at honest without relying on app code
create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger clients_set_updated_at before update on public.clients
  for each row execute function public.set_updated_at();
create trigger vps_set_updated_at before update on public.vps
  for each row execute function public.set_updated_at();

-- Admin check used by every RLS policy
create function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.admin_profiles where id = (select auth.uid())
  );
$$;

revoke execute on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;

-- RLS on from day one: with no policy, a role is denied by default
alter table public.admin_profiles enable row level security;
alter table public.clients enable row level security;
alter table public.vps enable row level security;
alter table public.client_vp_assignments enable row level security;

create policy "admins full access" on public.admin_profiles
  for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "admins full access" on public.clients
  for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "admins full access" on public.vps
  for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "admins full access" on public.client_vp_assignments
  for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));