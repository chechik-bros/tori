-- Initial schema (week 1, task S2)
--
-- Glossary:
--   appointment = a time slot in the business calendar, with a capacity.
--                 A barber haircut is an appointment with capacity 1,
--                 a yoga class is an appointment with capacity 10.
--   booking     = one client registered to an appointment.
--
-- Public (anonymous) visitors can only READ what the booking page needs
-- (business, active services, working hours, time off, busy times).
-- Public WRITES (creating a booking, cancelling by token) go through
-- security-definer RPC functions that are added in week 3 (tasks B4, B5).
-- The daily reminder job uses the service role key, which bypasses RLS.

create extension if not exists btree_gist;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table public.businesses (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references auth.users (id) on delete set null,
  name text not null,
  slug text not null unique check (slug ~ '^[a-z0-9-]{2,40}$'),
  phone text not null check (phone ~ '^972[0-9]{8,9}$'),
  timezone text not null default 'Asia/Jerusalem',
  created_at timestamptz not null default now()
);

create table public.services (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses (id) on delete cascade,
  name text not null,
  duration_minutes integer not null check (duration_minutes between 5 and 600),
  price_ils integer not null default 0 check (price_ils >= 0),
  capacity integer not null default 1 check (capacity >= 1),
  buffer_minutes integer not null default 0 check (buffer_minutes >= 0),
  is_active boolean not null default true, -- deactivate instead of deleting
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table public.availability_rules (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses (id) on delete cascade,
  weekday smallint not null check (weekday between 0 and 6), -- 0 = Sunday ... 6 = Saturday
  start_time time not null, -- local time in businesses.timezone
  end_time time not null,
  check (end_time > start_time)
);

create table public.time_off (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses (id) on delete cascade,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  check (ends_at > starts_at)
);

create table public.clients (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses (id) on delete cascade,
  name text not null,
  phone text not null check (phone ~ '^972[0-9]{8,9}$'),
  created_at timestamptz not null default now(),
  unique (business_id, phone)
);

create table public.appointments (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses (id) on delete cascade,
  service_id uuid not null references public.services (id),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  capacity integer not null default 1 check (capacity >= 1),
  status text not null default 'scheduled' check (status in ('scheduled', 'cancelled')),
  created_at timestamptz not null default now(),
  check (ends_at > starts_at),
  -- One person can't be in two places at once: no overlapping scheduled
  -- appointments per business. This is what stops double booking when two
  -- clients press "book" at the same second.
  constraint appointments_no_overlap exclude using gist (
    business_id with =,
    tstzrange(starts_at, ends_at, '[)') with &&
  ) where (status = 'scheduled')
);

create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses (id) on delete cascade,
  appointment_id uuid not null references public.appointments (id) on delete cascade,
  client_id uuid not null references public.clients (id) on delete cascade,
  status text not null default 'booked' check (status in ('booked', 'cancelled')),
  cancel_token text not null unique default replace(gen_random_uuid()::text, '-', ''),
  notes text, -- private, visible to the business owner only
  created_at timestamptz not null default now(),
  unique (appointment_id, client_id)
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses (id) on delete cascade,
  booking_id uuid not null references public.bookings (id) on delete cascade,
  channel text not null check (channel in ('whatsapp', 'email')),
  kind text not null check (kind in ('reminder', 'confirmation')),
  status text not null check (status in ('sent', 'failed')),
  provider_message_id text,
  error text,
  created_at timestamptz not null default now()
);

-- A booking gets each kind of message at most once successfully.
-- Failed attempts can be logged as many times as needed.
create unique index notifications_sent_once
  on public.notifications (booking_id, channel, kind)
  where status = 'sent';

create index services_business_idx on public.services (business_id);
create index availability_rules_business_idx on public.availability_rules (business_id);
create index time_off_business_idx on public.time_off (business_id, starts_at);
create index clients_business_idx on public.clients (business_id);
create index appointments_business_starts_idx on public.appointments (business_id, starts_at);
create index bookings_appointment_idx on public.bookings (appointment_id);
create index bookings_business_idx on public.bookings (business_id);

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------

create or replace function public.is_business_owner(bid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.businesses where id = bid and owner_id = auth.uid()
  );
$$;

alter table public.businesses enable row level security;
alter table public.services enable row level security;
alter table public.availability_rules enable row level security;
alter table public.time_off enable row level security;
alter table public.clients enable row level security;
alter table public.appointments enable row level security;
alter table public.bookings enable row level security;
alter table public.notifications enable row level security;

-- businesses: everyone can read (booking page), the owner can update.
create policy "public read" on public.businesses
  for select to anon, authenticated using (true);
create policy "owner update" on public.businesses
  for update to authenticated
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());

-- services: everyone reads active services, the owner manages all of them.
create policy "public read active" on public.services
  for select to anon, authenticated using (is_active);
create policy "owner all" on public.services
  for all to authenticated
  using (public.is_business_owner(business_id))
  with check (public.is_business_owner(business_id));

-- working hours and time off: everyone reads, the owner manages.
create policy "public read" on public.availability_rules
  for select to anon, authenticated using (true);
create policy "owner all" on public.availability_rules
  for all to authenticated
  using (public.is_business_owner(business_id))
  with check (public.is_business_owner(business_id));

create policy "public read" on public.time_off
  for select to anon, authenticated using (true);
create policy "owner all" on public.time_off
  for all to authenticated
  using (public.is_business_owner(business_id))
  with check (public.is_business_owner(business_id));

-- appointments hold only times, no personal data, so the booking page can
-- read them to know which slots are taken.
create policy "public read" on public.appointments
  for select to anon, authenticated using (true);
create policy "owner all" on public.appointments
  for all to authenticated
  using (public.is_business_owner(business_id))
  with check (public.is_business_owner(business_id));

-- clients, bookings, notifications: owner only.
create policy "owner all" on public.clients
  for all to authenticated
  using (public.is_business_owner(business_id))
  with check (public.is_business_owner(business_id));

create policy "owner all" on public.bookings
  for all to authenticated
  using (public.is_business_owner(business_id))
  with check (public.is_business_owner(business_id));

create policy "owner read" on public.notifications
  for select to authenticated
  using (public.is_business_owner(business_id));
