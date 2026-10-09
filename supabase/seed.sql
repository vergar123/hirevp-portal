-- DEV SEED DATA ONLY. Never run this against the production project.

insert into public.clients (company_name, contact_name, contact_email) values
  ('Acme Dental (seed)',       'Dana Cruz',  'dana@acme-dental.example.com'),
  ('Northwind Realty (seed)',  'Sam Lee',    'sam@northwind.example.com'),
  ('Bluebird Logistics (seed)','Priya Nair', 'priya@bluebird.example.com');

insert into public.vps (full_name, email, timezone) values
  ('Ana Reyes (seed)',   'ana.reyes@seed.example.com',   'Asia/Manila'),
  ('Ben Santos (seed)',  'ben.santos@seed.example.com',  'Asia/Manila'),
  ('Carla Lim (seed)',   'carla.lim@seed.example.com',   'Asia/Manila'),
  ('Dino Torres (seed)', 'dino.torres@seed.example.com', 'Asia/Manila'),
  ('Ella Cruz (seed)',   'ella.cruz@seed.example.com',   'Asia/Manila');

insert into public.client_vp_assignments (client_id, vp_id, role_title)
select c.id, v.id, a.role_title
from (values
  ('Acme Dental (seed)',        'ana.reyes@seed.example.com',   'Front Desk VA'),
  ('Acme Dental (seed)',        'ben.santos@seed.example.com',  'Billing VA'),
  ('Northwind Realty (seed)',   'carla.lim@seed.example.com',   'Lead Follow-up'),
  ('Northwind Realty (seed)',   'dino.torres@seed.example.com', 'Admin Support'),
  ('Bluebird Logistics (seed)', 'ella.cruz@seed.example.com',   'Dispatch Support')
) as a(company_name, vp_email, role_title)
join public.clients c on c.company_name = a.company_name
join public.vps v on v.email = a.vp_email;

insert into public.attendance_records (vp_id, clock_in_at, clock_out_at, clock_in_ip, clock_out_ip)
select v.id,
       t.ci,
       t.ci + interval '8 hours' + make_interval(mins => floor(random() * 40)::int),
       '203.0.113.10'::inet,
       '203.0.113.10'::inet
from public.vps v
cross join generate_series(current_date - 14, current_date - 1, interval '1 day') d
cross join lateral (
  select ((d::date + time '01:00') at time zone 'UTC')
         + make_interval(mins => floor(random() * 30)::int) as ci
) t
where v.email like '%@seed.example.com'
  and extract(isodow from d) < 6;

insert into public.attendance_records (vp_id, clock_in_at)
select id, now() - interval '2 hours'
from public.vps
where email = 'ana.reyes@seed.example.com';