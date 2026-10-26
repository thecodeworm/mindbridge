-- Assertions for 0016_security_hardening_2.sql. Run by the CI rls-check job
-- after all migrations are applied (see .github/workflows/ci.yml). Any failed
-- expectation raises an exception and stops psql (ON_ERROR_STOP).
--
-- Needs roles `authenticated`, `service_role`, `anon` and the auth.users /
-- auth.uid() stub the CI job creates.

create function pg_temp.must_fail(stmt text, label text) returns void
language plpgsql as $$
begin
  begin
    execute stmt;
  exception when others then
    raise notice 'PASS (rejected): % [%]', label, sqlerrm;
    return;
  end;
  raise exception 'FAIL: % was NOT rejected', label;
end $$;

create function pg_temp.must_pass(stmt text, label text) returns void
language plpgsql as $$
begin
  execute stmt;
  raise notice 'PASS (allowed): %', label;
end $$;

create function pg_temp.must_affect(stmt text, expected int, label text) returns void
language plpgsql as $$
declare n int;
begin
  execute stmt;
  get diagnostics n = row_count;
  if n <> expected then
    raise exception 'FAIL: % affected % rows, expected %', label, n, expected;
  end if;
  raise notice 'PASS (% rows): %', n, label;
end $$;

create function pg_temp.must_equal(actual bigint, expected bigint, label text) returns void
language plpgsql as $$
begin
  if actual is distinct from expected then
    raise exception 'FAIL: % got %, expected %', label, actual, expected;
  end if;
  raise notice 'PASS (=%): %', actual, label;
end $$;

-- Fixtures (as the superuser) -------------------------------------------------
insert into auth.users (id, email, raw_user_meta_data) values
  ('f1111111-0000-0000-0000-000000000001', 'h2-a@mindbridge.test', null),
  ('f2222222-0000-0000-0000-000000000002', 'h2-b@mindbridge.test', null);

insert into public.mood_logs (id, user_id, mood_score, mood_tag) values
  ('f2222222-1000-0000-0000-000000000001', 'f2222222-0000-0000-0000-000000000002', 5, 'calm');
insert into public.activity_tags (id, user_id, slug, label, emoji) values
  ('f2222222-2000-0000-0000-000000000001', 'f2222222-0000-0000-0000-000000000002', 'b-private', 'B private', 'x');
insert into public.weekly_summaries (user_id, week_start, summary) values
  ('f1111111-0000-0000-0000-000000000001', '2026-01-05', 'A summary'),
  ('f2222222-0000-0000-0000-000000000002', '2026-01-05', 'B summary');

-- display_name truncation on signup
insert into auth.users (id, email, raw_user_meta_data) values
  ('f3333333-0000-0000-0000-000000000003', 'h2-c@mindbridge.test',
   jsonb_build_object('display_name', repeat('n', 200)));
select pg_temp.must_equal(
  (select char_length(display_name) from public.users where id = 'f3333333-0000-0000-0000-000000000003'),
  60, 'handle_new_user truncates display_name to 60');

-- Act as user A -----------------------------------------------------------------
set role authenticated;
select set_config('request.jwt.claims', '{"sub": "f1111111-0000-0000-0000-000000000001"}', false);

select pg_temp.must_pass($$insert into public.mood_logs (id, user_id, mood_score, mood_tag)
  values ('f1111111-1000-0000-0000-000000000001', 'f1111111-0000-0000-0000-000000000001', 5, 'calm')$$,
  'A creates own mood log');
select pg_temp.must_pass($$insert into public.activity_tags (id, user_id, slug, label, emoji)
  values ('f1111111-2000-0000-0000-000000000001', 'f1111111-0000-0000-0000-000000000001', 'a-tag', 'A tag', 'x')$$,
  'A creates own tag');

-- mood_log_activities ownership
select pg_temp.must_pass($$insert into public.mood_log_activities (mood_log_id, activity_tag_id, user_id)
  values ('f1111111-1000-0000-0000-000000000001', (select id from public.activity_tags where user_id is null limit 1),
          'f1111111-0000-0000-0000-000000000001')$$,
  'A links own log to a built-in tag');
select pg_temp.must_pass($$insert into public.mood_log_activities (mood_log_id, activity_tag_id, user_id)
  values ('f1111111-1000-0000-0000-000000000001', 'f1111111-2000-0000-0000-000000000001',
          'f1111111-0000-0000-0000-000000000001')$$,
  'A links own log to own tag');
select pg_temp.must_fail($$insert into public.mood_log_activities (mood_log_id, activity_tag_id, user_id)
  values ('f2222222-1000-0000-0000-000000000001', (select id from public.activity_tags where user_id is null limit 1),
          'f1111111-0000-0000-0000-000000000001')$$,
  'A cannot link a row to B''s mood log');
select pg_temp.must_fail($$insert into public.mood_log_activities (mood_log_id, activity_tag_id, user_id)
  values ('f1111111-1000-0000-0000-000000000001', 'f2222222-2000-0000-0000-000000000001',
          'f1111111-0000-0000-0000-000000000001')$$,
  'A cannot use B''s private tag');

-- length limits
select pg_temp.must_fail($$insert into public.activity_tags (user_id, slug, label, emoji)
  values ('f1111111-0000-0000-0000-000000000001', 'x', repeat('L', 41), 'x')$$, 'tag label 41 chars rejected');
select pg_temp.must_pass($$insert into public.activity_tags (user_id, slug, label, emoji)
  values ('f1111111-0000-0000-0000-000000000001', 'y', repeat('L', 40), 'x')$$, 'tag label 40 chars accepted');
select pg_temp.must_fail($$update public.users set display_name = repeat('n', 61)
  where id = 'f1111111-0000-0000-0000-000000000001'$$, 'display_name 61 chars rejected');
select pg_temp.must_affect($$update public.users set display_name = 'Alex'
  where id = 'f1111111-0000-0000-0000-000000000001'$$, 1, 'display_name update still works');

-- immutable columns
select pg_temp.must_fail($$update public.users set created_at = '1999-01-01'
  where id = 'f1111111-0000-0000-0000-000000000001'$$, 'created_at is not client-writable');
select pg_temp.must_fail($$update public.users set id = gen_random_uuid()
  where id = 'f1111111-0000-0000-0000-000000000001'$$, 'users.id is not client-writable');

-- one journal entry per mood log
select pg_temp.must_pass($$insert into public.journal_entries (mood_log_id, user_id, body)
  values ('f1111111-1000-0000-0000-000000000001', 'f1111111-0000-0000-0000-000000000001', 'first')$$,
  'first journal entry');
select pg_temp.must_fail($$insert into public.journal_entries (mood_log_id, user_id, body)
  values ('f1111111-1000-0000-0000-000000000001', 'f1111111-0000-0000-0000-000000000001', 'second')$$,
  'second journal entry on the same log is rejected');

-- archive table is not reachable by users
select pg_temp.must_fail($$select * from public.journal_entries_dupe_archive$$, 'authenticated cannot read dupe archive');

-- delete_my_data wipes the caller only
select pg_temp.must_pass($$select public.delete_my_data()$$, 'A runs delete_my_data');
select pg_temp.must_equal((select count(*) from public.mood_logs), 0, 'A: mood_logs empty');
select pg_temp.must_equal((select count(*) from public.journal_entries), 0, 'A: journal_entries empty');
select pg_temp.must_equal((select count(*) from public.mood_log_activities), 0, 'A: activity links empty');
select pg_temp.must_equal((select count(*) from public.weekly_summaries), 0, 'A: weekly_summaries empty');
select pg_temp.must_equal((select count(*) from public.activity_tags where user_id is not null), 0, 'A: custom tags empty');
select pg_temp.must_equal((select count(*) from public.activity_tags where user_id is null), 12, 'built-in tags untouched');

reset role;
select pg_temp.must_equal((select count(*) from public.mood_logs where user_id = 'f2222222-0000-0000-0000-000000000002'), 1, 'B mood log survives');
select pg_temp.must_equal((select count(*) from public.weekly_summaries where user_id = 'f2222222-0000-0000-0000-000000000002'), 1, 'B summary survives');
select pg_temp.must_equal((select count(*) from public.activity_tags where user_id = 'f2222222-0000-0000-0000-000000000002'), 1, 'B tag survives');

-- anon cannot run it
set role anon;
select pg_temp.must_fail($$select public.delete_my_data()$$, 'anon cannot execute delete_my_data');
reset role;

-- Cleanup fixtures so reruns and later CI steps start clean
delete from auth.users where email like 'h2-%@mindbridge.test';
delete from public.users where id in (
  'f1111111-0000-0000-0000-000000000001', 'f2222222-0000-0000-0000-000000000002', 'f3333333-0000-0000-0000-000000000003');
select 'security_hardening_2: ALL ASSERTIONS PASSED' as result;
