# Stay Lake Leaf — Migration to Self-Managed Supabase + Vercel

Everything you need to move this project off Lovable Cloud onto your own
Supabase project and host it on Vercel.

## Contents

- `full-schema.sql` — all 13 migrations bundled. Creates tables, enums,
  functions, RLS policies, triggers, grants.
- `admin-user.sql` — recreates `welcome@staylakeleaf.com` / `Bangladesh#123`
  as an admin user in the new project.
- `data-export/*.csv` — one CSV per table. Currently only `profiles.csv` and
  `user_roles.csv` contain rows (the admin user). All other tables are empty.

## Step-by-step

### 1. Create a new Supabase project
1. https://supabase.com → **New Project**. Save the DB password.
2. Wait for provisioning (~2 min).
3. From **Project Settings → API**, copy:
   - Project URL
   - `anon` public key
   - `service_role` secret key
4. From **Project Settings → General**, copy the Project Ref.

### 2. Apply the schema
1. Supabase Dashboard → **SQL Editor → New query**.
2. Paste the entire contents of `full-schema.sql` → **Run**.
3. Verify tables exist under **Table Editor**: `profiles`, `user_roles`,
   `bookings`, `site_content`, `site_media`, `gallery_images`.

### 3. Create the storage bucket
1. Dashboard → **Storage → New bucket** → name: `site-media`, Public: **off**.
2. Storage policies (SQL Editor):
   ```sql
   -- Public read
   CREATE POLICY "site-media public read" ON storage.objects
     FOR SELECT USING (bucket_id = 'site-media');
   -- Admin write
   CREATE POLICY "site-media admin write" ON storage.objects
     FOR INSERT TO authenticated
     WITH CHECK (bucket_id = 'site-media' AND public.is_admin());
   CREATE POLICY "site-media admin update" ON storage.objects
     FOR UPDATE TO authenticated
     USING (bucket_id = 'site-media' AND public.is_admin());
   CREATE POLICY "site-media admin delete" ON storage.objects
     FOR DELETE TO authenticated
     USING (bucket_id = 'site-media' AND public.is_admin());
   ```

### 4. Create the admin user
Run `admin-user.sql` in the SQL Editor.
Sign-in: `welcome@staylakeleaf.com` / `Bangladesh#123`.

### 5. (Optional) Import data
Only needed if the current app has data you want to keep. In our export,
all content tables are empty, so you can skip this. If you add data later
and want to migrate:
- Dashboard → **Table Editor → <table> → Import data from CSV**.

### 6. Push code to GitHub
Lovable → **+ (chat menu) → GitHub → Connect project → Create Repository**.

### 7. Deploy on Vercel
1. https://vercel.com → **Add New → Project** → import the repo.
2. Framework preset: **Vite** (auto-detected).
3. **Environment Variables** (add for Production + Preview):
   ```
   VITE_SUPABASE_URL=<new project URL>
   VITE_SUPABASE_PUBLISHABLE_KEY=<new anon key>
   VITE_SUPABASE_PROJECT_ID=<new project ref>
   SUPABASE_URL=<same URL>
   SUPABASE_PUBLISHABLE_KEY=<same anon key>
   SUPABASE_SERVICE_ROLE_KEY=<new service_role key>
   ```
4. **Deploy**. First build ~1–2 min. You'll get `https://<name>.vercel.app`.

### 8. Whitelist the Vercel URL in your new Supabase
Supabase Dashboard → **Authentication → URL Configuration**:
- **Site URL**: `https://<name>.vercel.app`
- **Redirect URLs**: add
  - `https://<name>.vercel.app`
  - `https://<name>.vercel.app/**`
  - `http://localhost:8080` and `/**` (local dev)
  - Any custom domain you attach.

### 9. Verify end-to-end
- Open the Vercel URL, sign in as admin, load `/admin`, create a booking,
  add a gallery image (upload to `site-media`), save site content.
- If everything works, proceed.

### 10. (Irreversible) Disconnect Lovable Cloud
Only after step 9 succeeds.
- Lovable → **Cloud tab → Advanced → Disconnect Cloud**.
- ⚠️ This permanently deletes the current Lovable Cloud database. The
  Lovable preview will stop working against a live backend afterwards; use
  Vercel Preview deploys or local `bun dev` for future iteration.

## Notes

- No source-code change is required. The app already reads
  `VITE_SUPABASE_*` from env; pointing Vercel at your new Supabase is
  enough.
- If you use Lovable AI features (`LOVABLE_API_KEY`), those won't work
  post-disconnect. Replace with your own provider (OpenAI, Anthropic, etc.)
  by editing the relevant server functions and setting new secrets in
  Vercel.
- Every push to `main` (from GitHub or Lovable) triggers a Vercel deploy.
