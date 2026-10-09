-- attendance_records, access_tokens, report_exports

create table public.attendance_records (
  id uuid primary key default gen_random_uuid(),
  vp_id uuid not null references public.vps(id) on delete restrict,
  clock_in_at timestamptz not null,
  clock_out_at timestamptz,
  clock_in_ip inet,
  clock_out_ip inet,
  notes text,
  created_at timestamptz not null default now(),
  constraint clock_out_after_clock_in
    check (clock_out_at is null or clock_out_at > clock_in_at)
);

-- At most one open session per VP, enforced by the database rather than app code
create unique index one_open_session_per_vp
  on public.attendance_records (vp_id) where clock_out_at is null;

create index idx_attendance_vp_clock_in
  on public.attendance_records (vp_id, clock_in_at desc);
create index idx_attendance_clock_in
  on public.attendance_records (clock_in_at);  -- date-range exports

create table public.access_tokens (
  id uuid primary key default gen_random_uuid(),
  token_hash text not null unique,
  vp_id uuid references public.vps(id) on delete cascade,
  client_id uuid references public.clients(id) on delete cascade,
  expires_at timestamptz,
  revoked_at timestamptz,
  last_used_at timestamptz,
  created_at timestamptz not null default now(),
  created_by uuid references public.admin_profiles(id) on delete set null,
  -- sha256 hex digest only: a plaintext token can never be stored by accident
  constraint token_hash_is_sha256_hex check (token_hash ~ '^[0-9a-f]{64}$'),
  constraint token_has_exactly_one_subject
    check ((vp_id is not null)::int + (client_id is not null)::int = 1)
);

create index idx_access_tokens_vp on public.access_tokens(vp_id) where vp_id is not null;
create index idx_access_tokens_client on public.access_tokens(client_id) where client_id is not null;

create table public.report_exports (
  id uuid primary key default gen_random_uuid(),
  exported_by uuid references public.admin_profiles(id) on delete set null,
  client_id uuid references public.clients(id) on delete restrict,  -- null = no client filter
  vp_id uuid references public.vps(id) on delete restrict,          -- null = no VP filter
  period_start date not null,
  period_end date not null,
  format text not null check (format in ('csv', 'xlsx', 'pdf')),
  exported_at timestamptz not null default now(),
  constraint export_period_valid check (period_end >= period_start)
);

create index idx_report_exports_exported_at on public.report_exports(exported_at desc);

-- Defense in depth: the public (anon) key can't even attempt to touch these
revoke all on public.attendance_records, public.access_tokens, public.report_exports from anon;

alter table public.attendance_records enable row level security;
alter table public.access_tokens enable row level security;
alter table public.report_exports enable row level security;

create policy "admins full access" on public.attendance_records
  for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));

create policy "admins full access" on public.access_tokens
  for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));

-- The audit log is append-only: admins can read and insert, never edit or delete
create policy "admins can read exports" on public.report_exports
  for select to authenticated
  using ((select public.is_admin()));

create policy "admins can log own exports" on public.report_exports
  for insert to authenticated
  with check ((select public.is_admin()) and exported_by = (select auth.uid()));