-- Grant table privileges to the authenticated role.
-- RLS policies alone are not enough — Postgres also requires the role to
-- have the underlying privilege before RLS even runs.
grant select, insert, update, delete on public.users to authenticated;
grant select, insert, update, delete on public.mood_logs to authenticated;
grant select, insert, update, delete on public.journal_entries to authenticated;
grant select, insert, update, delete on public.coping_suggestions to authenticated;
grant select, insert, update, delete on public.ai_call_logs to authenticated;
