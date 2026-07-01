create table public.users (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now()
);

create table public.mood_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  mood_score smallint not null check (mood_score between 1 and 10),
  mood_tag text not null,
  logged_at timestamptz not null default now()
);

create table public.journal_entries (
  id uuid primary key default gen_random_uuid(),
  mood_log_id uuid not null references public.mood_logs (id) on delete cascade,
  user_id uuid not null references public.users (id) on delete cascade,
  body text not null check (char_length(body) <= 500),
  created_at timestamptz not null default now()
);

create table public.coping_suggestions (
  id uuid primary key default gen_random_uuid(),
  mood_log_id uuid not null unique references public.mood_logs (id) on delete cascade,
  user_id uuid not null references public.users (id) on delete cascade,
  technique_name text not null,
  description text not null,
  steps jsonb not null,
  model_used text not null,
  generated_at timestamptz not null default now()
);

create table public.ai_call_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  input_tokens integer not null,
  output_tokens integer not null,
  latency_ms integer not null,
  called_at timestamptz not null default now()
);

create index mood_logs_user_id_logged_at_idx on public.mood_logs (user_id, logged_at desc);
create index journal_entries_mood_log_id_idx on public.journal_entries (mood_log_id);
create index journal_entries_user_id_idx on public.journal_entries (user_id);
create index coping_suggestions_user_id_idx on public.coping_suggestions (user_id);
create index ai_call_logs_user_id_idx on public.ai_call_logs (user_id);



create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.users (id, display_name)
  values (new.id, new.raw_user_meta_data ->> 'display_name');
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();


alter table public.users enable row level security;
create policy "Users can view own profile" on public.users
  for select using (auth.uid() = id);
create policy "Users can update own profile" on public.users
  for update using (auth.uid() = id);

alter table public.mood_logs enable row level security;
create policy "Users can view own mood logs" on public.mood_logs
  for select using (auth.uid() = user_id);
create policy "Users can insert own mood logs" on public.mood_logs
  for insert with check (auth.uid() = user_id);
create policy "Users can update own mood logs" on public.mood_logs
  for update using (auth.uid() = user_id);
create policy "Users can delete own mood logs" on public.mood_logs
  for delete using (auth.uid() = user_id);

alter table public.journal_entries enable row level security;
create policy "Users can view own journal entries" on public.journal_entries
  for select using (auth.uid() = user_id);
create policy "Users can insert own journal entries" on public.journal_entries
  for insert with check (auth.uid() = user_id);
create policy "Users can update own journal entries" on public.journal_entries
  for update using (auth.uid() = user_id);
create policy "Users can delete own journal entries" on public.journal_entries
  for delete using (auth.uid() = user_id);

alter table public.coping_suggestions enable row level security;
create policy "Users can view own coping suggestions" on public.coping_suggestions
  for select using (auth.uid() = user_id);

alter table public.ai_call_logs enable row level security;
create policy "Users can view own ai call logs" on public.ai_call_logs
  for select using (auth.uid() = user_id);
