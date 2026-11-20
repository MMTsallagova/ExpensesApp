-- Выполните целиком в Supabase: SQL Editor → New query → вставить → Run.
-- Замените почту в последней строке на свою.

create table if not exists public.docs (
  collection text not null,
  id         text not null,
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (collection, id)
);

-- Список почт, у которых есть доступ к данным
create table if not exists public.members (email text primary key);
alter table public.members enable row level security;  -- из приложения список не читается и не меняется

alter table public.docs enable row level security;
drop policy if exists "only_us" on public.docs;
create policy "only_us" on public.docs
  for all to authenticated
  using      (exists (select 1 from public.members m where m.email = lower(auth.jwt() ->> 'email')))
  with check (exists (select 1 from public.members m where m.email = lower(auth.jwt() ->> 'email')));

-- Мгновенная синхронизация между телефонами
alter publication supabase_realtime add table public.docs;

-- Ваша почта (строчными буквами)
insert into public.members (email) values ('margo@example.com') on conflict do nothing;

-- Позже, чтобы добавить Мишу, выполните отдельно:
-- insert into public.members (email) values ('misha@example.com');
