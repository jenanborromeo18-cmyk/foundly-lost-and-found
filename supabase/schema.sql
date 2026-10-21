-- Run this file in the Supabase SQL Editor for a new project.
-- Foundly uses Supabase Auth, Postgres Row Level Security, and Supabase Storage.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default 'Community member',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(title) between 3 and 80),
  description text not null check (char_length(description) between 10 and 700),
  item_type text not null check (item_type in ('lost', 'found')),
  category text not null check (category in ('Electronics', 'Keys', 'Wallets & bags', 'Clothing', 'IDs & cards', 'Jewelry', 'Pets', 'Other')),
  location_name text not null check (char_length(location_name) between 1 and 140),
  occurred_at timestamptz,
  photo_url text,
  photo_path text,
  status text not null default 'open' check (status in ('open', 'matched', 'returned', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.claims (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.items(id) on delete cascade,
  claimant_id uuid not null references public.profiles(id) on delete cascade,
  message text not null check (char_length(message) between 10 and 400),
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  owner_message text check (owner_message is null or char_length(owner_message) <= 300),
  created_at timestamptz not null default now(),
  unique (item_id, claimant_id)
);

create index if not exists items_open_created_idx on public.items (created_at desc) where status = 'open';
create index if not exists items_owner_created_idx on public.items (user_id, created_at desc);
create index if not exists items_category_type_status_idx on public.items (category, item_type, status);
create index if not exists claims_item_created_idx on public.claims (item_id, created_at desc);
create index if not exists claims_claimant_created_idx on public.claims (claimant_id, created_at desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists items_set_updated_at on public.items;
create trigger items_set_updated_at before update on public.items
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''), 'Community member'))
  on conflict (id) do update set full_name = excluded.full_name;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute function public.handle_new_user();

-- Also populate users who already existed before this schema was installed.
insert into public.profiles (id, full_name)
select u.id, coalesce(nullif(trim(u.raw_user_meta_data ->> 'full_name'), ''), 'Community member')
from auth.users u
on conflict (id) do nothing;

alter table public.profiles enable row level security;
alter table public.items enable row level security;
alter table public.claims enable row level security;

drop policy if exists "Authenticated users can read profiles" on public.profiles;
create policy "Authenticated users can read profiles" on public.profiles
for select to authenticated using (true);

drop policy if exists "Users can update their profile" on public.profiles;
create policy "Users can update their profile" on public.profiles
for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "Users can read active listings" on public.items;
create policy "Users can read active listings" on public.items
for select to authenticated using (status <> 'archived' or user_id = auth.uid());

drop policy if exists "Users can create their listings" on public.items;
create policy "Users can create their listings" on public.items
for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "Owners can update their listings" on public.items;
create policy "Owners can update their listings" on public.items
for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "Owners can delete their listings" on public.items;
create policy "Owners can delete their listings" on public.items
for delete to authenticated using (user_id = auth.uid());

drop policy if exists "Claimants and listing owners can read claims" on public.claims;
create policy "Claimants and listing owners can read claims" on public.claims
for select to authenticated using (
  claimant_id = auth.uid()
  or exists (select 1 from public.items i where i.id = item_id and i.user_id = auth.uid())
);

drop policy if exists "Users can claim another person's open listing" on public.claims;
create policy "Users can claim another person's open listing" on public.claims
for insert to authenticated with check (
  claimant_id = auth.uid()
  and exists (
    select 1 from public.items i
    where i.id = item_id and i.user_id <> auth.uid() and i.status = 'open'
  )
);

-- Claim review and listing status change happen in one transaction.
create or replace function public.set_item_status(
  p_item_id uuid,
  p_status text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;
  if p_status not in ('open', 'matched', 'returned', 'archived') then
    raise exception 'Invalid listing status';
  end if;

  select user_id into v_owner_id
  from public.items
  where id = p_item_id
  for update;

  if v_owner_id is null or v_owner_id <> auth.uid() then
    raise exception 'Listing not found';
  end if;

  update public.items set status = p_status where id = p_item_id;

  if p_status in ('returned', 'archived') then
    update public.claims
    set status = 'rejected',
        owner_message = 'The listing was marked resolved by its owner.'
    where item_id = p_item_id and status = 'pending';
  end if;
end;
$$;

revoke all on function public.set_item_status(uuid, text) from public;
grant execute on function public.set_item_status(uuid, text) to authenticated;

create or replace function public.review_item_claim(
  p_claim_id uuid,
  p_status text,
  p_owner_message text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_item_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;
  if p_status not in ('approved', 'rejected') then
    raise exception 'Invalid claim status';
  end if;

  select c.item_id into v_item_id
  from public.claims c
  join public.items i on i.id = c.item_id
  where c.id = p_claim_id
    and i.user_id = auth.uid()
    and i.status = 'open'
    and c.status = 'pending'
  for update of i;

  if v_item_id is null then
    raise exception 'Claim not found or no longer pending';
  end if;

  update public.claims
  set status = p_status,
      owner_message = case when p_status = 'approved' then nullif(trim(p_owner_message), '') else null end
  where id = p_claim_id;

  if p_status = 'approved' then
    update public.items set status = 'matched' where id = v_item_id;
    update public.claims
    set status = 'rejected',
        owner_message = 'The owner approved another claim.'
    where item_id = v_item_id and id <> p_claim_id and status = 'pending';
  end if;
end;
$$;

revoke all on function public.review_item_claim(uuid, text, text) from public;
grant execute on function public.review_item_claim(uuid, text, text) to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('item-photos', 'item-photos', true, 5242880, array['image/jpeg', 'image/png', 'image/webp', 'image/heic'])
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Item photos are publicly readable" on storage.objects;
create policy "Item photos are publicly readable" on storage.objects
for select using (bucket_id = 'item-photos');

drop policy if exists "Users can upload their item photos" on storage.objects;
create policy "Users can upload their item photos" on storage.objects
for insert to authenticated with check (
  bucket_id = 'item-photos' and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Users can update their item photos" on storage.objects;
create policy "Users can update their item photos" on storage.objects
for update to authenticated using (
  bucket_id = 'item-photos' and (storage.foldername(name))[1] = auth.uid()::text
) with check (
  bucket_id = 'item-photos' and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Users can delete their item photos" on storage.objects;
create policy "Users can delete their item photos" on storage.objects
for delete to authenticated using (
  bucket_id = 'item-photos' and (storage.foldername(name))[1] = auth.uid()::text
);
