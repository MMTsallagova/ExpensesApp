-- Выполните целиком в Supabase: SQL Editor → New query → вставить → Run.
-- Замените почту в строке insert на свою (строчными буквами).

create table if not exists public.docs (
  collection text not null,
  id         text not null,
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (collection, id)
);

-- Список почт, у которых есть доступ к данным (из приложения не читается)
create table if not exists public.members (email text primary key);
alter table public.members enable row level security;

create or replace function public.is_member() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.members where email = lower(auth.jwt() ->> 'email'))
$$;
revoke all on function public.is_member() from public, anon;
grant execute on function public.is_member() to authenticated;

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.docs to authenticated;

alter table public.docs enable row level security;
drop policy if exists "only_us" on public.docs;
create policy "only_us" on public.docs
  for all to authenticated
  using (public.is_member()) with check (public.is_member());

-- Мгновенная синхронизация между телефонами (если уже добавлено — строку можно пропустить)
alter publication supabase_realtime add table public.docs;

insert into public.members (email) values ('margo@example.com') on conflict do nothing;

-- Позже, чтобы добавить Мишу, выполните отдельно:
-- insert into public.members (email) values ('misha@example.com');
