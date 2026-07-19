-- Run in your NEW Supabase project's SQL Editor AFTER applying full-schema.sql.
-- Creates the admin user welcome@staylakeleaf.com / Bangladesh#123 and grants the admin role.

DO $$
DECLARE
  new_user_id uuid := gen_random_uuid();
BEGIN
  -- 1. auth.users
  INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at, confirmation_token, email_change,
    email_change_token_new, recovery_token
  ) VALUES (
    new_user_id,
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'welcome@staylakeleaf.com',
    crypt('Bangladesh#123', gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Stay Lake Leaf Admin"}',
    now(), now(), '', '', '', ''
  );

  -- 2. auth.identities
  INSERT INTO auth.identities (
    id, user_id, identity_data, provider, provider_id,
    last_sign_in_at, created_at, updated_at
  ) VALUES (
    gen_random_uuid(),
    new_user_id,
    jsonb_build_object('sub', new_user_id::text, 'email', 'welcome@staylakeleaf.com', 'email_verified', true),
    'email',
    new_user_id::text,
    now(), now(), now()
  );

  -- 3. profiles + admin role (handle_new_user trigger normally does this;
  --    include explicit inserts in case the trigger is not yet installed).
  INSERT INTO public.profiles (id, full_name, email)
  VALUES (new_user_id, 'Stay Lake Leaf Admin', 'welcome@staylakeleaf.com')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.user_roles (user_id, role)
  VALUES (new_user_id, 'admin')
  ON CONFLICT (user_id, role) DO NOTHING;
END $$;
