-- User preferences: daily reminder time (Item 9)

alter table public.users add column reminder_time time null;
