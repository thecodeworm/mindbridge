-- Weekly AI summary (Item 15)

create table public.weekly_summaries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  week_start date not null,
  summary text,
  highlights jsonb,
  model_used text,
  generated_at timestamptz default now(),
  unique (user_id, week_start)
);

alter table public.weekly_summaries enable row level security;

create policy "Users read own weekly summaries"
  on public.weekly_summaries for select
  using (auth.uid() = user_id);

grant select on public.weekly_summaries to authenticated;
grant select, insert, update, delete on public.weekly_summaries to service_role;
