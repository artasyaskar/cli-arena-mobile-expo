-- Supabase Seed Data for CLI Arena Mobile Expo Project

-- This script will be run after schema.sql when the database is initialized.
-- It's useful for populating initial data for development and testing.

-- Make sure to use `INSERT INTO ... ON CONFLICT DO NOTHING` or similar
-- to make seeding idempotent if the script might be run multiple times.

-- Example: Create a test user (if not handled by Supabase Auth UI/API for seeding)
-- Note: Managing users directly in SQL is complex due to auth.users internal structure and hashing.
-- It's often better to create test users via Supabase client library or UI after setup.
-- However, if you need a dummy user that auth might not know about for some specific non-auth related test:
-- This is NOT for creating real auth users.
-- INSERT INTO auth.users (id, email, encrypted_password, role)
-- VALUES ('00000000-0000-0000-0000-000000000001', 'testuser@example.com', 'hashed_password_placeholder', 'authenticated')
-- ON CONFLICT (id) DO NOTHING;
--
-- INSERT INTO public.profiles (id, username, full_name)
-- VALUES ('00000000-0000-0000-0000-000000000001', 'testuser', 'Test User One')
-- ON CONFLICT (id) DO NOTHING;


-- Example: Create a couple of organizations
INSERT INTO public.organizations (id, name, owner_id)
VALUES
  ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Global Dynamics Inc.', NULL), -- Owner can be set later
  ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12', 'Cyberdyne Systems LLC', NULL)
ON CONFLICT (id) DO NOTHING;

-- Example: Create some sample error message templates (if doing localized error task)
-- This is a simplified example. A real system might have a dedicated `localization_templates` table.
-- For now, let's assume these keys are used by the client to fetch full templates.
-- No actual table for these yet, just as a concept for `error_reports.message_template_key`.


-- Example: Seed some background job types (if a table for job definitions existed)
-- No direct table for this, but tasks might create jobs of certain types.


-- Example: Seed some file metadata for testing uploads
-- This assumes a user '00000000-0000-0000-0000-000000000001' exists and a bucket 'user_uploads'.
-- INSERT INTO public.file_metadata (user_id, storage_path, bucket_id, file_name, mime_type, size_bytes, metadata, upload_status)
-- VALUES
--   ('00000000-0000-0000-0000-000000000001', 'user_uploads/00000000-0000-0000-0000-000000000001/example.jpg', 'user_uploads', 'example.jpg', 'image/jpeg', 102400, '{"description": "A sample image"}', 'completed'),
--   ('00000000-0000-0000-0000-000000000001', 'user_uploads/00000000-0000-0000-0000-000000000001/report.pdf', 'user_uploads', 'report.pdf', 'application/pdf', 204800, '{"year": 2023}', 'completed')
-- ON CONFLICT (storage_path) DO NOTHING;


-- Seeding for specific tasks can be added here as they are developed.
-- For example, for `cli-offline-user-sync`, you might want some initial items that actions could modify.

-- Example: A generic items table that tasks might interact with
CREATE TABLE IF NOT EXISTS public.generic_items (
  id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  details JSONB,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);
ALTER TABLE public.generic_items ENABLE ROW LEVEL SECURITY;

-- Policies for generic_items (examples, adjust as needed)
CREATE POLICY "Allow individual full access to own generic items"
  ON public.generic_items FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow organization members to read generic items in their org"
  ON public.generic_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.organization_members om
      WHERE om.organization_id = generic_items.organization_id AND om.user_id = auth.uid()
    )
  );

-- Apply the updated_at trigger
CREATE TRIGGER set_generic_items_updated_at
BEFORE UPDATE ON public.generic_items
FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


-- Seed some generic items
INSERT INTO public.generic_items (id, user_id, organization_id, name, description, details)
VALUES
  ('c1f8e4d9-0b7e-4b1f-8c7a-6d5e4f3a2b10', NULL, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Project Alpha', 'Initial project for Global Dynamics.', '{"priority": "high", "status": "active"}'),
  ('d2e7f5c8-1a6d-4c0e-9b5b-5e4f3a2b1c11', NULL, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12', 'Skynet Prototype', 'Early AI development at Cyberdyne.', '{"version": "0.1", "confidential": true}')
ON CONFLICT (id) DO NOTHING;

-- Add more seed data as needed for other tables and tasks.
-- Keep this file organized by table or feature if it grows large.

\echo 'Seed data script complete.'
