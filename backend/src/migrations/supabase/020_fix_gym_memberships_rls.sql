-- FLEXR - Fix RLS Infinite Recursion in gym_memberships
-- Migration 020
-- Problem: gym_memberships RLS policies query gym_memberships, causing infinite recursion
-- Solution: Use SECURITY DEFINER functions to bypass RLS for membership checks

-- Drop problematic policies on gym_memberships
DROP POLICY IF EXISTS "Gym members can view other members" ON gym_memberships;
DROP POLICY IF EXISTS "Gym admins can update memberships" ON gym_memberships;

-- Drop problematic policies on running_sessions
DROP POLICY IF EXISTS "Gym members can view gym running sessions" ON running_sessions;

-- Create a security definer function for gym membership checks
-- This bypasses RLS to check if user is member of a gym
CREATE OR REPLACE FUNCTION is_gym_member(check_gym_id UUID, check_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM gym_memberships
    WHERE gym_id = check_gym_id
      AND user_id = check_user_id
      AND status = 'active'
  );
$$;

-- Create function to check if user is gym admin
CREATE OR REPLACE FUNCTION is_gym_admin(check_gym_id UUID, check_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM gym_memberships
    WHERE gym_id = check_gym_id
      AND user_id = check_user_id
      AND role IN ('admin', 'owner')
      AND status = 'active'
  );
$$;

-- Create function to get user's gym IDs
CREATE OR REPLACE FUNCTION get_user_gym_ids(check_user_id UUID)
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT gym_id FROM gym_memberships
  WHERE user_id = check_user_id
    AND status = 'active';
$$;

-- Re-create gym_memberships policies using security definer functions
CREATE POLICY "Gym members can view other members"
  ON gym_memberships FOR SELECT
  USING (
    -- User is a member of the same gym (use security definer function)
    is_gym_member(gym_id, auth.uid())
    -- AND the member has show_in_member_list enabled
    AND (privacy_settings->>'show_in_member_list')::boolean = true
  );

CREATE POLICY "Gym admins can update memberships"
  ON gym_memberships FOR UPDATE
  USING (is_gym_admin(gym_id, auth.uid()));

-- Re-create running_sessions policies using security definer functions
CREATE POLICY "Gym members can view gym running sessions"
  ON running_sessions FOR SELECT
  USING (
    visibility IN ('gym', 'public')
    AND gym_id IS NOT NULL
    AND is_gym_member(gym_id, auth.uid())
  );

-- Fix other tables that might have similar issues

-- Fix gym_activity_feed policy
DROP POLICY IF EXISTS "Gym members can view gym activities" ON gym_activity_feed;
CREATE POLICY "Gym members can view gym activities"
  ON gym_activity_feed FOR SELECT
  USING (
    visibility = 'gym'
    AND is_gym_member(gym_id, auth.uid())
  );

-- Fix gym_leaderboards policy
DROP POLICY IF EXISTS "Gym members can view leaderboards" ON gym_leaderboards;
CREATE POLICY "Gym members can view leaderboards"
  ON gym_leaderboards FOR SELECT
  USING (is_gym_member(gym_id, auth.uid()));

DROP POLICY IF EXISTS "Gym admins can manage leaderboards" ON gym_leaderboards;
CREATE POLICY "Gym admins can manage leaderboards"
  ON gym_leaderboards FOR ALL
  USING (is_gym_admin(gym_id, auth.uid()));

-- Fix gyms policies that reference gym_memberships
DROP POLICY IF EXISTS "Gym members can view their gym" ON gyms;
CREATE POLICY "Gym members can view their gym"
  ON gyms FOR SELECT
  USING (is_gym_member(id, auth.uid()));

DROP POLICY IF EXISTS "Gym admins can update gym" ON gyms;
CREATE POLICY "Gym admins can update gym"
  ON gyms FOR UPDATE
  USING (is_gym_admin(id, auth.uid()));

DROP POLICY IF EXISTS "Only gym owners can delete gym" ON gyms;
CREATE POLICY "Only gym owners can delete gym"
  ON gyms FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM gym_memberships
      WHERE gym_memberships.gym_id = gyms.id
        AND gym_memberships.user_id = auth.uid()
        AND gym_memberships.role = 'owner'
        AND gym_memberships.status = 'active'
    )
  );

-- Grant execute on functions
GRANT EXECUTE ON FUNCTION is_gym_member TO authenticated;
GRANT EXECUTE ON FUNCTION is_gym_admin TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_gym_ids TO authenticated;

-- Comments
COMMENT ON FUNCTION is_gym_member IS 'Security definer function to check gym membership without RLS recursion';
COMMENT ON FUNCTION is_gym_admin IS 'Security definer function to check gym admin status without RLS recursion';
COMMENT ON FUNCTION get_user_gym_ids IS 'Security definer function to get all gym IDs for a user without RLS recursion';

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'Migration 020: Fixed RLS infinite recursion in gym_memberships';
  RAISE NOTICE 'Created security definer functions: is_gym_member, is_gym_admin, get_user_gym_ids';
END $$;
