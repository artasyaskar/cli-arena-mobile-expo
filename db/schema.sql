-- Supabase Schema for CLI Arena Mobile Expo Project

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
-- Enable pgcrypto for encryption functions if needed by tasks
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA extensions;

-- -----------------------------------------------------------------------------
-- Users Table (Leveraging Supabase Auth)
-- -----------------------------------------------------------------------------
-- Supabase automatically creates an `auth.users` table.
-- We can add a public `profiles` table to store user-specific public data,
-- linked to `auth.users` via a one-to-one relationship.

CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  username TEXT UNIQUE,
  full_name TEXT,
  avatar_url TEXT,
  -- Constraints
  CONSTRAINT username_length CHECK (char_length(username) >= 3 AND char_length(username) <= 50)
);

-- Function to automatically create a profile when a new user signs up in Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, username)
  VALUES (new.id, new.raw_user_meta_data->>'username'); -- Assumes username is passed in metadata on signup
  RETURN new;
END;
$$;

-- Trigger to call the function after a new user is inserted into auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Enable Row Level Security (RLS) for the profiles table
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policies for profiles table:
-- 1. Users can view their own profile.
CREATE POLICY "Allow individual read access to own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

-- 2. Users can update their own profile.
CREATE POLICY "Allow individual update access to own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- (Optional) Allow users to view other users' public profiles (if desired)
-- CREATE POLICY "Allow authenticated read access to all profiles"
--   ON public.profiles FOR SELECT
--   USING (auth.role() = 'authenticated');


-- -----------------------------------------------------------------------------
-- Organizations Table (for multi-tenant tasks)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.organizations (
  id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  name TEXT NOT NULL UNIQUE,
  owner_id UUID REFERENCES auth.users(id) ON DELETE SET NULL, -- Org can exist without owner temporarily
  -- Other organization-specific details
  CONSTRAINT name_length CHECK (char_length(name) > 0)
);
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

-- Policies for organizations:
-- (Define based on requirements, e.g., members can see org, owner can update)


-- -----------------------------------------------------------------------------
-- Organization Members Table (linking users to organizations with roles)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.organization_members (
  organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role TEXT NOT NULL DEFAULT 'member', -- e.g., 'admin', 'member', 'viewer'
  joined_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  PRIMARY KEY (organization_id, user_id)
);
ALTER TABLE public.organization_members ENABLE ROW LEVEL SECURITY;

-- Policies for organization_members:
-- (Define based on requirements, e.g., org members can see other members, admin can add/remove)


-- -----------------------------------------------------------------------------
-- User Actions Table (for offline sync task)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_actions (
  id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  action_type TEXT NOT NULL, -- e.g., 'create_item', 'update_setting', 'delete_photo'
  payload JSONB,             -- Data associated with the action
  created_at_client TIMESTAMPTZ NOT NULL, -- Timestamp from the client when action occurred
  synced_at TIMESTAMPTZ,     -- Timestamp when action was synced to server
  status TEXT DEFAULT 'pending', -- 'pending', 'synced', 'failed', 'conflict'
  device_id TEXT,            -- Identifier for the device originating the action
  client_action_id TEXT UNIQUE, -- Unique ID generated by the client for deduplication
  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
ALTER TABLE public.user_actions ENABLE ROW LEVEL SECURITY;

-- Policies for user_actions:
-- 1. Users can insert their own actions.
CREATE POLICY "Allow individual insert access for own actions"
  ON public.user_actions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 2. Users can view and update their own pending/failed actions.
CREATE POLICY "Allow individual read/update access for own pending/failed actions"
  ON public.user_actions FOR ALL -- SELECT, UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id AND status IN ('pending', 'failed', 'conflict'));


-- -----------------------------------------------------------------------------
-- Secure Storage Table (for secure token storage task, if server-side part is needed)
-- This might be more focused on client-side keychain, but a table could track metadata.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.secure_items_metadata (
  id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  item_key TEXT NOT NULL, -- Key used to identify the item (e.g., 'api_token_service_x')
  metadata JSONB,         -- Any non-sensitive metadata about the stored item
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE (user_id, item_key),
  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
ALTER TABLE public.secure_items_metadata ENABLE ROW LEVEL SECURITY;

-- Policies for secure_items_metadata:
CREATE POLICY "Allow individual access to own secure items metadata"
  ON public.secure_items_metadata FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);


-- -----------------------------------------------------------------------------
-- Location Audit Table (for user location audit task)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.location_audits (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  latitude DECIMAL(9,6) NOT NULL,
  longitude DECIMAL(9,6) NOT NULL,
  accuracy DECIMAL(10,2), -- Accuracy in meters
  timestamp TIMESTAMPTZ NOT NULL, -- Timestamp of the location fix
  recorded_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL, -- Server timestamp
  source TEXT, -- e.g., 'gps', 'network', 'manual_cli'
  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
ALTER TABLE public.location_audits ENABLE ROW LEVEL SECURITY;

-- Policies for location_audits:
CREATE POLICY "Allow individual insert access for own location data"
  ON public.location_audits FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow individual read access to own location data"
  ON public.location_audits FOR SELECT
  USING (auth.uid() = user_id);


-- -----------------------------------------------------------------------------
-- Background Jobs Table (for async background jobs task)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.background_jobs (
  id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE, -- Optional, if job is user-specific
  job_type TEXT NOT NULL,
  payload JSONB,
  status TEXT DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed', 'retry'
  attempts INT DEFAULT 0,
  max_attempts INT DEFAULT 5,
  last_attempted_at TIMESTAMPTZ,
  next_attempt_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()),
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
ALTER TABLE public.background_jobs ENABLE ROW LEVEL SECURITY;

-- Policies for background_jobs:
-- (Typically managed by server-side logic or privileged roles, but users might view their own jobs)
CREATE POLICY "Allow individual read access to own background jobs"
  ON public.background_jobs FOR SELECT
  USING (auth.uid() = user_id AND user_id IS NOT NULL);

CREATE POLICY "Allow individual insert access for own background jobs"
  ON public.background_jobs FOR INSERT
  WITH CHECK (auth.uid() = user_id AND user_id IS NOT NULL);

-- -----------------------------------------------------------------------------
-- Localized Errors Table (for localized error capture task)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.error_reports (
  id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL, -- User might be null if error occurs before login
  error_code TEXT NOT NULL,       -- e.g., 'NETWORK_FAILURE', 'VALIDATION_ERROR'
  message_template_key TEXT,    -- Key to look up localized message template
  context JSONB,                -- Additional context for the error (variables for template)
  client_locale VARCHAR(10),      -- e.g., 'en-US', 'fr-CA'
  platform_info JSONB,          -- OS, app version, device model
  stack_trace TEXT,
  reported_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
ALTER TABLE public.error_reports ENABLE ROW LEVEL SECURITY;

-- Policies for error_reports:
-- Generally, users might only be allowed to insert. Reading might be restricted to admins/developers.
CREATE POLICY "Allow anonymous or authenticated insert access for error reports"
  ON public.error_reports FOR INSERT
  WITH CHECK (true); -- Or add specific checks if needed


-- -----------------------------------------------------------------------------
-- User Sessions Table (for session timeout manager task, if server tracks sessions)
-- Note: Supabase GoTrue handles its own session management. This table could be for custom app-level sessions.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.app_sessions (
  id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  device_id TEXT,
  last_active_at TIMESTAMPTZ NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
ALTER TABLE public.app_sessions ENABLE ROW LEVEL SECURITY;

-- Policies for app_sessions:
CREATE POLICY "Allow individual access to own app sessions"
  ON public.app_sessions FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);


-- -----------------------------------------------------------------------------
-- File Uploads Metadata (for cross-platform uploads task, tracking files in Supabase Storage)
-- Supabase Storage handles the actual files. This table stores related metadata.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.file_metadata (
  id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE, -- Optional, if files are org-specific
  storage_path TEXT NOT NULL UNIQUE, -- Path in Supabase Storage (e.g., 'user_uploads/user_id/filename.jpg')
  bucket_id TEXT NOT NULL DEFAULT 'general', -- Supabase Storage bucket name
  file_name TEXT NOT NULL,
  mime_type TEXT,
  size_bytes BIGINT,
  metadata JSONB, -- Custom metadata (tags, description, etc.)
  upload_status TEXT DEFAULT 'pending', -- 'pending', 'completed', 'failed'
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT fk_organization FOREIGN KEY (organization_id) REFERENCES public.organizations(id)
);
ALTER TABLE public.file_metadata ENABLE ROW LEVEL SECURITY;

-- Policies for file_metadata:
CREATE POLICY "Allow individual access to own file metadata"
  ON public.file_metadata FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- (Optional) Policy for organization members to access org files
-- CREATE POLICY "Allow organization members to access organization file metadata"
--   ON public.file_metadata FOR SELECT
--   USING (
--     EXISTS (
--       SELECT 1 FROM public.organization_members om
--       WHERE om.organization_id = file_metadata.organization_id AND om.user_id = auth.uid()
--     )
--   );


-- -----------------------------------------------------------------------------
-- Data Transformation Records (for metadata transformer task)
-- Example: Storing transformed/indexed versions of data from other tables.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.indexed_cli_records (
  id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE, -- Optional, if records are user-specific
  source_table TEXT NOT NULL,
  source_record_id TEXT NOT NULL, -- Could be UUID or other type depending on source
  transformed_data JSONB NOT NULL,
  indexed_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  version INT DEFAULT 1,
  UNIQUE (source_table, source_record_id), -- Ensure one indexed record per source item
  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
ALTER TABLE public.indexed_cli_records ENABLE ROW LEVEL SECURITY;

-- Policies for indexed_cli_records:
-- (Define based on how these records are used and who should access them)
CREATE POLICY "Allow individual read access to own indexed records"
  ON public.indexed_cli_records FOR SELECT
  USING (auth.uid() = user_id AND user_id IS NOT NULL);


-- -----------------------------------------------------------------------------
-- Offline Form Submissions (for offline form replayer task)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.offline_form_submissions (
  id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(), -- Client-generated ID for idempotency
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  form_id TEXT NOT NULL, -- Identifier for the type of form
  data JSONB NOT NULL,   -- The actual form data
  client_submitted_at TIMESTAMPTZ NOT NULL, -- When the user submitted it on the client
  status TEXT DEFAULT 'pending', -- 'pending', 'replayed', 'failed', 'conflict'
  server_replayed_at TIMESTAMPTZ,
  error_details TEXT,
  device_id TEXT,
  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
ALTER TABLE public.offline_form_submissions ENABLE ROW LEVEL SECURITY;

-- Policies for offline_form_submissions:
CREATE POLICY "Allow individual access to own offline form submissions"
  ON public.offline_form_submissions FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);


-- -----------------------------------------------------------------------------
-- Helper function to update `updated_at` columns automatically
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply the trigger to tables with `updated_at`
CREATE TRIGGER set_profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();

CREATE TRIGGER set_secure_items_metadata_updated_at
BEFORE UPDATE ON public.secure_items_metadata
FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();

CREATE TRIGGER set_background_jobs_updated_at
BEFORE UPDATE ON public.background_jobs
FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();

CREATE TRIGGER set_file_metadata_updated_at
BEFORE UPDATE ON public.file_metadata
FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


-- -----------------------------------------------------------------------------
-- Supabase Storage Buckets
-- -----------------------------------------------------------------------------
-- This is typically managed via Supabase dashboard or CLI, but good to note.
-- Example: Create a bucket for general user uploads if it doesn't exist.
-- Note: `storage.buckets` table is owned by `supabase_storage_admin` role.
--       Direct inserts might be restricted. Use Supabase provided functions or UI.
--       This is more of a reminder of buckets needed.

-- INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
-- VALUES
--   ('user_uploads', 'user_uploads', FALSE, 5242880, ARRAY['image/jpeg', 'image/png', 'application/pdf'])
-- ON CONFLICT (id) DO NOTHING;

-- INSERT INTO storage.buckets (id, name, public)
-- VALUES
--   ('public_assets', 'public_assets', TRUE)
-- ON CONFLICT (id) DO NOTHING;


-- Ensure RLS is enabled on Supabase Storage objects as well.
-- Policies for storage objects are defined separately, usually like:

-- Example policy for 'user_uploads' bucket: allow users to upload to their own folder
-- CREATE POLICY "Allow individual uploads to own folder"
--   ON storage.objects FOR INSERT
--   TO authenticated
--   WITH CHECK (bucket_id = 'user_uploads' AND auth.uid()::text = (storage.foldername(name))[1]);

-- CREATE POLICY "Allow individual read access to own files"
--   ON storage.objects FOR SELECT
--   TO authenticated
--   USING (bucket_id = 'user_uploads' AND auth.uid()::text = (storage.foldername(name))[1]);

-- (Add more specific policies as needed for each task)

-- -----------------------------------------------------------------------------
-- END OF SCHEMA
-- -----------------------------------------------------------------------------
-- Remember to run `supabase db push` (if using Supabase CLI with migrations)
-- or ensure this file is correctly picked up by `docker-entrypoint-initdb.d`
-- when the PostgreSQL container starts for the first time.
-- -----------------------------------------------------------------------------
