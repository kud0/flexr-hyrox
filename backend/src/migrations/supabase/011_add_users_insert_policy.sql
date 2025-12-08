-- ============================================================================
-- Add INSERT policy for users table
-- Migration: 011_add_users_insert_policy.sql
-- ============================================================================

-- Allow users to create their own user record on first sign-in
CREATE POLICY "Users can create own profile"
  ON users FOR INSERT
  WITH CHECK (auth.uid()::text = id::text);

COMMENT ON POLICY "Users can create own profile" ON users IS
'Allows authenticated users to create their own user record when signing in for the first time';
