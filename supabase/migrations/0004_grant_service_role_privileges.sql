-- CI: touched to exercise the rls-check workflow job's path filter.
-- The service-role client in generate-suggestion bypasses RLS but still
-- needs explicit table privileges — RLS bypass and Postgres GRANTs are
-- separate. Without this, service-role inserts fail with
-- "permission denied for table coping_suggestions".
grant select, insert, update, delete on public.coping_suggestions to service_role;
grant select, insert, update, delete on public.ai_call_logs to service_role;
