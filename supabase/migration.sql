-- À exécuter dans l'éditeur SQL de ton projet Supabase (Dashboard > SQL Editor).
-- Crée la table des favoris et restreint chaque ligne à son propriétaire via RLS.

create table if not exists public.favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  pokemon_id integer not null,
  pokemon_name text not null,
  image_url text,
  created_at timestamptz not null default now(),
  unique (user_id, pokemon_id)
);

alter table public.favorites enable row level security;

create policy "Users can view their own favorites"
  on public.favorites for select
  using (auth.uid() = user_id);

create policy "Users can insert their own favorites"
  on public.favorites for insert
  with check (auth.uid() = user_id);

create policy "Users can delete their own favorites"
  on public.favorites for delete
  using (auth.uid() = user_id);
