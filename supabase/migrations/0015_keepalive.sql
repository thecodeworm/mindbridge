-- Keep-alive probe for the free-tier inactivity pause.
--
-- Supabase pauses a free project after about a week without traffic, which
-- took the live backend down once already (2026-10). The scheduled GitHub
-- Actions workflow .github/workflows/keepalive.yml calls this function through
-- PostgREST (POST /rest/v1/rpc/keepalive) with the anon key every two days so
-- that Postgres itself sees a real query.
--
-- A dedicated function is used instead of selecting from a table, because
-- 0005 locked the tables away from anon on purpose. This function reads no
-- user data, takes no arguments, and returns only the server clock, so
-- giving it to anon exposes nothing.
create function public.keepalive()
returns timestamptz
language sql
stable
security invoker
set search_path = ''
as $$
  select now();
$$;

revoke execute on function public.keepalive() from public;
grant execute on function public.keepalive() to anon;
