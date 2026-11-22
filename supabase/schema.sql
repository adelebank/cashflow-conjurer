-- The Cashflow Conjurer: multiplayer database
-- Run this once in your Supabase project: Dashboard > SQL Editor > New query > paste > Run.
-- Everything is protected by row level security: players only see their own rooms,
-- banned accounts cannot chat or join rooms, and only admins can read reports or ban.

-- ---------- tables ----------
create table if not exists public.players (
  id uuid primary key references auth.users on delete cascade,
  nickname text not null check (char_length(nickname) between 1 and 16),
  created_at timestamptz not null default now()
);

create table if not exists public.admins (
  user_id uuid primary key references auth.users on delete cascade
);

create table if not exists public.banned (
  user_id uuid primary key references auth.users on delete cascade,
  reason text,
  banned_at timestamptz not null default now()
);

create table if not exists public.rooms (
  code text primary key check (code ~ '^[A-Z0-9]{6}$'),
  owner uuid not null default auth.uid() references auth.users on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.room_members (
  room text not null references public.rooms(code) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (room, user_id)
);

create table if not exists public.messages (
  id bigint generated always as identity primary key,
  room text not null references public.rooms(code) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  nickname text not null default '',
  body text not null check (char_length(body) between 1 and 200),
  hidden boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists messages_room_time on public.messages (room, created_at desc);

create table if not exists public.reports (
  id bigint generated always as identity primary key,
  reporter uuid not null default auth.uid() references auth.users on delete cascade,
  reported uuid not null references auth.users on delete cascade,
  message_id bigint references public.messages(id) on delete set null,
  room text,
  body text,
  reason text,
  status text not null default 'open' check (status in ('open', 'banned', 'dismissed')),
  created_at timestamptz not null default now()
);
create unique index if not exists reports_once_per_message on public.reports (reporter, message_id) where message_id is not null;

-- ---------- helpers ----------
create or replace function public.is_banned(uid uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.banned where user_id = uid)
$$;

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.admins where user_id = auth.uid())
$$;

create or replace function public.is_member(r text) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.room_members where room = r and user_id = auth.uid())
$$;

-- a message always carries the sender's current nickname (players cannot fake someone else's)
create or replace function public.set_message_nickname() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  new.user_id := auth.uid();
  new.hidden := false;
  select nickname into new.nickname from public.players where id = auth.uid();
  if new.nickname is null then raise exception 'Pick a nickname first'; end if;
  return new;
end $$;
drop trigger if exists messages_nickname on public.messages;
create trigger messages_nickname before insert on public.messages
  for each row execute function public.set_message_nickname();

-- ---------- row level security ----------
alter table public.players enable row level security;
alter table public.admins enable row level security;
alter table public.banned enable row level security;
alter table public.rooms enable row level security;
alter table public.room_members enable row level security;
alter table public.messages enable row level security;
alter table public.reports enable row level security;

-- players: you see yourself and people who share a room with you
drop policy if exists "players read" on public.players;
create policy "players read" on public.players for select to authenticated using (
  id = auth.uid() or public.is_admin() or exists (
    select 1 from public.room_members a join public.room_members b on a.room = b.room
    where a.user_id = auth.uid() and b.user_id = players.id)
);
drop policy if exists "players write self" on public.players;
create policy "players write self" on public.players for insert to authenticated
  with check (id = auth.uid() and not public.is_banned(auth.uid()));
drop policy if exists "players update self" on public.players;
create policy "players update self" on public.players for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid() and not public.is_banned(auth.uid()));

-- admins: you can only see whether you are one
drop policy if exists "admins read self" on public.admins;
create policy "admins read self" on public.admins for select to authenticated using (user_id = auth.uid());

-- banned: you can see your own ban; admins see all (bans are made with ban_user())
drop policy if exists "banned read" on public.banned;
create policy "banned read" on public.banned for select to authenticated
  using (user_id = auth.uid() or public.is_admin());

-- rooms: anyone signed in can check an invite code exists and make their own room
drop policy if exists "rooms read" on public.rooms;
create policy "rooms read" on public.rooms for select to authenticated using (true);
drop policy if exists "rooms create" on public.rooms;
create policy "rooms create" on public.rooms for insert to authenticated
  with check (owner = auth.uid() and not public.is_banned(auth.uid()));

-- room members: joining a room needs its code (an invite); you see your own rooms' members
drop policy if exists "members read" on public.room_members;
create policy "members read" on public.room_members for select to authenticated
  using (public.is_member(room) or public.is_admin());
drop policy if exists "members join" on public.room_members;
create policy "members join" on public.room_members for insert to authenticated
  with check (user_id = auth.uid() and not public.is_banned(auth.uid()));
drop policy if exists "members leave" on public.room_members;
create policy "members leave" on public.room_members for delete to authenticated using (user_id = auth.uid());

-- messages: room members read visible messages and post as themselves; admins read everything
drop policy if exists "messages read" on public.messages;
create policy "messages read" on public.messages for select to authenticated
  using ((public.is_member(room) and not hidden) or public.is_admin());
drop policy if exists "messages post" on public.messages;
create policy "messages post" on public.messages for insert to authenticated
  with check (public.is_member(room) and not public.is_banned(auth.uid()));

-- reports: only admins can read them (players report through the functions below)
drop policy if exists "reports admin" on public.reports;
create policy "reports admin" on public.reports for select to authenticated using (public.is_admin());

-- ---------- reporting (players) ----------
-- report a chat message: it is hidden for everyone right away and goes to the moderator
create or replace function public.report_message(mid bigint, why text default null) returns void
language plpgsql security definer set search_path = '' as $$
declare m public.messages;
begin
  select * into m from public.messages where id = mid;
  if not found or not public.is_member(m.room) then raise exception 'Message not found'; end if;
  if m.user_id = auth.uid() then raise exception 'You cannot report yourself'; end if;
  insert into public.reports (reporter, reported, message_id, room, body, reason)
    values (auth.uid(), m.user_id, mid, m.room, m.body, left(why, 200))
    on conflict do nothing;
  update public.messages set hidden = true where id = mid;
end $$;

-- report a player (for things that are not a single message)
create or replace function public.report_player(uid uuid, r text, why text default null) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if uid = auth.uid() then raise exception 'You cannot report yourself'; end if;
  if not public.is_member(r) or not exists (select 1 from public.room_members where room = r and user_id = uid) then
    raise exception 'Player not found';
  end if;
  insert into public.reports (reporter, reported, room, reason) values (auth.uid(), uid, r, left(why, 200));
end $$;

-- ---------- moderation (admins) ----------
create or replace function public.ban_user(uid uuid, why text default null) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_admin() then raise exception 'Admins only'; end if;
  insert into public.banned (user_id, reason) values (uid, left(why, 200)) on conflict (user_id) do nothing;
  update public.reports set status = 'banned' where reported = uid and status = 'open';
  update public.messages set hidden = true where user_id = uid;
  delete from public.room_members where user_id = uid;
end $$;

create or replace function public.unban_user(uid uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_admin() then raise exception 'Admins only'; end if;
  delete from public.banned where user_id = uid;
end $$;

-- dismiss a report: the message comes back unless someone else also reported it
create or replace function public.dismiss_report(rid bigint) returns void
language plpgsql security definer set search_path = '' as $$
declare mid bigint;
begin
  if not public.is_admin() then raise exception 'Admins only'; end if;
  update public.reports set status = 'dismissed' where id = rid returning message_id into mid;
  if mid is not null and not exists (select 1 from public.reports where message_id = mid and status <> 'dismissed') then
    update public.messages set hidden = false where id = mid;
  end if;
end $$;

revoke execute on function public.ban_user(uuid, text), public.unban_user(uuid), public.dismiss_report(bigint) from anon;
revoke execute on function public.report_message(bigint, text), public.report_player(uuid, text, text) from anon;

-- ---------- realtime ----------
-- new chat messages are pushed to room members (row level security still applies)
do $$ begin
  alter publication supabase_realtime add table public.messages;
exception when duplicate_object then null; end $$;

-- the live room channel (positions, who is online) is private: only members of that room,
-- and never banned accounts, can listen or send
drop policy if exists "room channel read" on realtime.messages;
create policy "room channel read" on realtime.messages for select to authenticated using (
  realtime.topic() like 'room:%' and public.is_member(substring(realtime.topic() from 6))
  and not public.is_banned(auth.uid())
);
drop policy if exists "room channel send" on realtime.messages;
create policy "room channel send" on realtime.messages for insert to authenticated with check (
  realtime.topic() like 'room:%' and public.is_member(substring(realtime.topic() from 6))
  and not public.is_banned(auth.uid())
);

-- ---------- make yourself the moderator ----------
-- After you have signed in to the game once, run ONE of these:
-- name and password account:
-- insert into public.admins (user_id) select id from auth.users where raw_user_meta_data->>'username' = 'YourName';
-- Google account:
-- insert into public.admins (user_id) select id from auth.users where email = 'you@example.com';
