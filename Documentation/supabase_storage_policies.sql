-- Supabase Storage policy setup for ArtFlow
-- Run this in the Supabase SQL Editor.
--
-- This setup assumes:
-- 1. The bucket already exists.
-- 2. The bucket ID is `artflow-media`.
-- 3. You want uploads to work with the anon key and no signed-in Supabase user.
--
-- Notes:
-- - Public buckets already allow public file serving/download by URL.
-- - Uploads are still controlled by RLS policies on storage.objects.
-- - Because the app now uploads with unique filenames and `upsert: false`,
--   we only need INSERT access for uploads.

update storage.buckets
set public = true
where id = 'artflow-media';

create policy "artflow_media_public_insert_anon"
on storage.objects
for insert
to anon
with check (bucket_id = 'artflow-media');

create policy "artflow_media_public_insert_authenticated"
on storage.objects
for insert
to authenticated
with check (bucket_id = 'artflow-media');

-- Optional:
-- If you want unauthenticated users to also be able to list objects via the API,
-- uncomment the policy below. Public buckets do not require this just for public URL access.
--
-- create policy "artflow_media_public_select_anon"
-- on storage.objects
-- for select
-- to anon
-- using (bucket_id = 'artflow-media');
