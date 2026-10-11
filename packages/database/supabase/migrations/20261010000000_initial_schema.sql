-- SatPay initial schema
-- Simulated remittance platform: no real funds are held or moved.
-- Money columns use numeric (never float). Sats have 0 decimals, BTC has 8.

-- =====================================================================
-- Types
-- =====================================================================

create type public.transfer_status as enum (
  'Created',
  'Processing',
  'Completed',
  'Failed',
  'Cancelled'
);

create type public.user_role as enum ('user', 'admin');

create type public.currency_kind as enum ('fiat', 'bitcoin');

-- =====================================================================
-- Shared helpers
-- =====================================================================

create function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- =====================================================================
-- profiles (senders and recipients are both profiles; "sender" and
-- "recipient" are roles within a transfer, not account types)
-- =====================================================================

create table public.profiles (
  id            uuid primary key references auth.users (id) on delete cascade,
  full_name     text not null,
  country_code  char(2),
  role          public.user_role not null default 'user',
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  constraint profiles_country_code_upper check (country_code is null or country_code = upper(country_code))
);

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- Role is read from the profile row only, never from user-supplied metadata.
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, country_code)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'full_name', ''), split_part(new.email, '@', 1)),
    nullif(upper(new.raw_user_meta_data ->> 'country_code'), '')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- =====================================================================
-- currencies / exchange_rates / fee_rules
-- =====================================================================

create table public.currencies (
  code       text primary key,
  name       text not null,
  symbol     text not null,
  kind       public.currency_kind not null,
  decimals   smallint not null check (decimals between 0 and 18),
  is_active  boolean not null default true,
  constraint currencies_code_upper check (code = upper(code))
);

comment on column public.currencies.decimals is
  'Smallest unit precision: USD=2, BTC=8, SAT=0.';

-- Rates are append-only: the latest valid_from <= now() per pair is the active one.
-- A rate is quoted as: 1 base_currency = rate quote_currency.
create table public.exchange_rates (
  id              uuid primary key default gen_random_uuid(),
  base_currency   text not null references public.currencies (code),
  quote_currency  text not null references public.currencies (code),
  rate            numeric(28, 10) not null check (rate > 0),
  source          text not null default 'static',
  valid_from      timestamptz not null default now(),
  created_at      timestamptz not null default now(),
  constraint exchange_rates_distinct_pair check (base_currency <> quote_currency)
);

create index exchange_rates_pair_latest_idx
  on public.exchange_rates (base_currency, quote_currency, valid_from desc);

-- Simple, transparent fee model: fee = max(min_fee, amount * percent_fee + fixed_fee),
-- expressed in the send currency. Applied by the server-side calculation engine.
create table public.fee_rules (
  id            uuid primary key default gen_random_uuid(),
  currency      text not null references public.currencies (code),
  percent_fee   numeric(7, 6) not null default 0 check (percent_fee >= 0 and percent_fee < 1),
  fixed_fee     numeric(28, 8) not null default 0 check (fixed_fee >= 0),
  min_fee       numeric(28, 8) not null default 0 check (min_fee >= 0),
  is_active     boolean not null default true,
  valid_from    timestamptz not null default now(),
  created_at    timestamptz not null default now()
);

create index fee_rules_currency_idx on public.fee_rules (currency, valid_from desc);

-- =====================================================================
-- transfers
-- =====================================================================

create table public.transfers (
  id                    uuid primary key default gen_random_uuid(),
  reference_code        text not null unique
                          default 'SP-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10)),
  sender_id             uuid not null references public.profiles (id),
  recipient_id          uuid not null references public.profiles (id),

  send_currency         text not null references public.currencies (code),
  receive_currency      text not null references public.currencies (code),

  amount_sent           numeric(28, 8) not null check (amount_sent > 0),
  fee                   numeric(28, 8) not null check (fee >= 0),
  conversion_rate       numeric(28, 10) not null check (conversion_rate > 0),
  amount_received       numeric(28, 8) not null check (amount_received >= 0),

  -- Snapshot of the inputs, so a transfer stays explainable after rates change.
  exchange_rate_id      uuid references public.exchange_rates (id),
  fee_rule_id           uuid references public.fee_rules (id),

  status                public.transfer_status not null default 'Created',
  failure_reason        text,
  estimated_completion_at timestamptz,
  completed_at          timestamptz,

  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),

  constraint transfers_sender_not_recipient check (sender_id <> recipient_id),
  constraint transfers_fee_within_amount check (fee <= amount_sent),
  constraint transfers_failure_reason_only_on_failed
    check (failure_reason is null or status = 'Failed')
);

create index transfers_sender_idx    on public.transfers (sender_id, created_at desc);
create index transfers_recipient_idx on public.transfers (recipient_id, created_at desc);
create index transfers_status_idx    on public.transfers (status, created_at desc);

-- ---------------------------------------------------------------------
-- State machine, enforced in the database so no code path can bypass it:
--   Created    -> Processing | Cancelled
--   Processing -> Completed  | Failed
--   Completed, Failed, Cancelled are terminal.
-- Financial fields are immutable after creation.
-- ---------------------------------------------------------------------
create function public.enforce_transfer_rules()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'INSERT' then
    if new.status <> 'Created' then
      raise exception 'Transfers must be created in status Created (got %)', new.status;
    end if;
    return new;
  end if;

  if (new.sender_id, new.recipient_id, new.send_currency, new.receive_currency,
      new.amount_sent, new.fee, new.conversion_rate, new.amount_received)
     is distinct from
     (old.sender_id, old.recipient_id, old.send_currency, old.receive_currency,
      old.amount_sent, old.fee, old.conversion_rate, old.amount_received) then
    raise exception 'Financial fields of transfer % are immutable', old.id;
  end if;

  if new.status is distinct from old.status then
    if not (
      (old.status = 'Created'    and new.status in ('Processing', 'Cancelled')) or
      (old.status = 'Processing' and new.status in ('Completed', 'Failed'))
    ) then
      raise exception 'Invalid transfer transition: % -> %', old.status, new.status;
    end if;

    if new.status = 'Completed' then
      new.completed_at = now();
    end if;
  end if;

  new.updated_at = now();
  return new;
end;
$$;

create trigger transfers_enforce_rules
  before insert or update on public.transfers
  for each row execute function public.enforce_transfer_rules();

-- =====================================================================
-- transfer_history (one row per status change) and audit_logs (generic)
-- =====================================================================

create table public.transfer_history (
  id           bigint generated always as identity primary key,
  transfer_id  uuid not null references public.transfers (id) on delete cascade,
  from_status  public.transfer_status,
  to_status    public.transfer_status not null,
  changed_by   uuid references public.profiles (id),
  note         text,
  created_at   timestamptz not null default now()
);

create index transfer_history_transfer_idx on public.transfer_history (transfer_id, created_at);

create table public.audit_logs (
  id           bigint generated always as identity primary key,
  actor_id     uuid references public.profiles (id),
  action       text not null,
  entity_type  text not null,
  entity_id    text not null,
  metadata     jsonb not null default '{}'::jsonb,
  created_at   timestamptz not null default now()
);

create index audit_logs_entity_idx on public.audit_logs (entity_type, entity_id, created_at desc);
create index audit_logs_actor_idx  on public.audit_logs (actor_id, created_at desc);

-- Every insert/status change is recorded automatically.
-- auth.uid() is null when the service role performs the change (e.g. the
-- simulated processing job), which is recorded as a system action.
create function public.log_transfer_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' or new.status is distinct from old.status then
    insert into public.transfer_history (transfer_id, from_status, to_status, changed_by, note)
    values (
      new.id,
      case when tg_op = 'UPDATE' then old.status end,
      new.status,
      auth.uid(),
      new.failure_reason
    );

    insert into public.audit_logs (actor_id, action, entity_type, entity_id, metadata)
    values (
      auth.uid(),
      case when tg_op = 'INSERT' then 'transfer.created' else 'transfer.status_changed' end,
      'transfer',
      new.id::text,
      jsonb_build_object(
        'reference_code', new.reference_code,
        'from', case when tg_op = 'UPDATE' then old.status end,
        'to', new.status
      )
    );
  end if;
  return new;
end;
$$;

create trigger transfers_log_change
  after insert or update on public.transfers
  for each row execute function public.log_transfer_change();

-- =====================================================================
-- Row Level Security
-- Writes to transfers, rates and fees go through server-side API routes
-- using the service role (calculations must be validated on the server).
-- Authenticated clients only read, plus update their own safe profile fields.
-- =====================================================================

alter table public.profiles          enable row level security;
alter table public.currencies        enable row level security;
alter table public.exchange_rates    enable row level security;
alter table public.fee_rules         enable row level security;
alter table public.transfers         enable row level security;
alter table public.transfer_history  enable row level security;
alter table public.audit_logs        enable row level security;

-- profiles: any signed-in user can look up a recipient; edit only yourself.
create policy "profiles_select_authenticated" on public.profiles
  for select to authenticated using (true);

create policy "profiles_update_own" on public.profiles
  for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

revoke update on public.profiles from authenticated;
grant update (full_name, country_code) on public.profiles to authenticated;

-- reference data: readable by everyone signed in (the UI needs it to quote).
create policy "currencies_select" on public.currencies
  for select to authenticated using (true);
create policy "exchange_rates_select" on public.exchange_rates
  for select to authenticated using (true);
create policy "fee_rules_select" on public.fee_rules
  for select to authenticated using (true);

-- transfers: visible to the two parties and to admins.
create policy "transfers_select_parties" on public.transfers
  for select to authenticated
  using (sender_id = auth.uid() or recipient_id = auth.uid() or public.is_admin());

create policy "transfer_history_select_parties" on public.transfer_history
  for select to authenticated
  using (
    public.is_admin() or exists (
      select 1 from public.transfers t
      where t.id = transfer_id
        and (t.sender_id = auth.uid() or t.recipient_id = auth.uid())
    )
  );

create policy "audit_logs_select_admin" on public.audit_logs
  for select to authenticated using (public.is_admin());

-- Realtime: live status updates for the sender, recipient and admin dashboard.
alter publication supabase_realtime add table public.transfers;
