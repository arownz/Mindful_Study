-- I Study Buddy — core schema (Postgres + RLS). Run via Supabase CLI or SQL editor.

-- Extensions
create extension if not exists "pgcrypto";

-- Schools / classes (nullable on profiles for future SaaS)
create table public.schools (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table public.classes (
  id uuid primary key default gen_random_uuid(),
  school_id uuid references public.schools (id) on delete set null,
  name text not null,
  created_at timestamptz not null default now()
);

-- Profiles (1:1 with auth.users)
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  school_id uuid references public.schools (id),
  class_id uuid references public.classes (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  plan text not null default 'free',
  is_active boolean not null default true,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.mood_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  mood_index int not null check (mood_index between 0 and 4),
  energy_level int not null check (energy_level between 1 and 5),
  factors text[] not null default '{}',
  created_at timestamptz not null default now()
);

create table public.focus_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  focus_score int not null check (focus_score between 1 and 10),
  note text,
  created_at timestamptz not null default now()
);

create table public.study_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  plan_json jsonb not null default '{}',
  generated_at timestamptz not null default now(),
  source text not null default 'rule_based'
);

create table public.study_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  subject text,
  duration_seconds int not null check (duration_seconds >= 0),
  completed_at timestamptz not null default now(),
  mood_before int,
  mood_after int
);

create table public.streaks (
  user_id uuid primary key references auth.users (id) on delete cascade,
  current_streak int not null default 0,
  last_activity_date date,
  longest_streak int not null default 0,
  updated_at timestamptz not null default now()
);

create table public.reminders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  fire_at timestamptz not null,
  repeat_rule text,
  enabled boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  token text not null unique,
  platform text,
  updated_at timestamptz not null default now()
);

create table public.analytics_snapshots (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  period_start date not null,
  period_end date not null,
  total_minutes int not null default 0,
  session_count int not null default 0,
  avg_mood numeric,
  payload jsonb not null default '{}',
  created_at timestamptz not null default now(),
  unique (user_id, period_start, period_end)
);

-- RLS
alter table public.profiles enable row level security;
alter table public.subscriptions enable row level security;
alter table public.mood_logs enable row level security;
alter table public.focus_logs enable row level security;
alter table public.study_plans enable row level security;
alter table public.study_sessions enable row level security;
alter table public.streaks enable row level security;
alter table public.reminders enable row level security;
alter table public.device_tokens enable row level security;
alter table public.analytics_snapshots enable row level security;
alter table public.schools enable row level security;
alter table public.classes enable row level security;

-- Schools / classes: readable by authenticated users (MVP); writes reserved for service role later
create policy "schools_select_authenticated"
  on public.schools for select
  to authenticated
  using (true);

create policy "classes_select_authenticated"
  on public.classes for select
  to authenticated
  using (true);

create policy "profiles_select_own"
  on public.profiles for select
  to authenticated
  using (auth.uid() = id);

create policy "profiles_update_own"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

create policy "profiles_insert_own"
  on public.profiles for insert
  to authenticated
  with check (auth.uid() = id);

create policy "subscriptions_select_own"
  on public.subscriptions for select
  to authenticated
  using (auth.uid() = user_id);

create policy "mood_logs_all_own"
  on public.mood_logs for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "focus_logs_all_own"
  on public.focus_logs for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "study_plans_all_own"
  on public.study_plans for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "study_sessions_all_own"
  on public.study_sessions for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "streaks_all_own"
  on public.streaks for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "reminders_all_own"
  on public.reminders for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "device_tokens_all_own"
  on public.device_tokens for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "analytics_snapshots_all_own"
  on public.analytics_snapshots for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Auto-create profile on signup
create or replace function public.handle_new_user ()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name', 'Student')
  );
  insert into public.streaks (user_id) values (new.id)
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user ();
