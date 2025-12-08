-- FLEXR Row-Level Security Policies for Social Features
-- Comprehensive security policies for gym and social tables
-- Migration 015

-- Enable RLS on all social tables
ALTER TABLE gyms ENABLE ROW LEVEL SECURITY;
ALTER TABLE gym_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_relationships ENABLE ROW LEVEL SECURITY;
ALTER TABLE relationship_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE relationship_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE relationship_invite_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE gym_activity_feed ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_kudos ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_comparisons ENABLE ROW LEVEL SECURITY;
ALTER TABLE gym_leaderboards ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_personal_records ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- GYMS POLICIES
-- ============================================================================

-- Anyone can view public gyms
CREATE POLICY "Anyone can view public gyms"
  ON gyms FOR SELECT
  USING (is_public = true);

-- Gym members can view their gyms (even if not public)
CREATE POLICY "Gym members can view their gym"
  ON gyms FOR SELECT
  USING (
    id IN (
      SELECT gym_id FROM gym_memberships
      WHERE user_id::text = auth.uid()::text
        AND status IN ('active', 'pending')
    )
  );

-- Authenticated users can create gyms
CREATE POLICY "Authenticated users can create gyms"
  ON gyms FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- Gym admins/owners can update their gym
CREATE POLICY "Gym admins can update gym"
  ON gyms FOR UPDATE
  USING (
    id IN (
      SELECT gym_id FROM gym_memberships
      WHERE user_id::text = auth.uid()::text
        AND role IN ('admin', 'owner')
        AND status = 'active'
    )
  );

-- Only gym owners can delete gyms
CREATE POLICY "Only gym owners can delete gym"
  ON gyms FOR DELETE
  USING (
    id IN (
      SELECT gym_id FROM gym_memberships
      WHERE user_id::text = auth.uid()::text
        AND role = 'owner'
        AND status = 'active'
    )
  );

-- ============================================================================
-- GYM MEMBERSHIPS POLICIES
-- ============================================================================

-- Users can view their own memberships
CREATE POLICY "Users can view own memberships"
  ON gym_memberships FOR SELECT
  USING (user_id::text = auth.uid()::text);

-- Gym members can view other members of their gym (respecting privacy)
CREATE POLICY "Gym members can view other members"
  ON gym_memberships FOR SELECT
  USING (
    -- User is a member of the same gym
    gym_id IN (
      SELECT gym_id FROM gym_memberships
      WHERE user_id::text = auth.uid()::text
        AND status = 'active'
    )
    -- AND the member has show_in_member_list enabled
    AND (privacy_settings->>'show_in_member_list')::boolean = true
  );

-- Users can create their own gym memberships
CREATE POLICY "Users can join gyms"
  ON gym_memberships FOR INSERT
  WITH CHECK (user_id::text = auth.uid()::text);

-- Users can update their own memberships
CREATE POLICY "Users can update own membership"
  ON gym_memberships FOR UPDATE
  USING (user_id::text = auth.uid()::text);

-- Gym admins can update any membership at their gym
CREATE POLICY "Gym admins can update memberships"
  ON gym_memberships FOR UPDATE
  USING (
    gym_id IN (
      SELECT gym_id FROM gym_memberships
      WHERE user_id::text = auth.uid()::text
        AND role IN ('admin', 'owner')
        AND status = 'active'
    )
  );

-- Users can delete (leave) their own membership
CREATE POLICY "Users can leave gym"
  ON gym_memberships FOR DELETE
  USING (user_id::text = auth.uid()::text);

-- ============================================================================
-- USER RELATIONSHIPS POLICIES
-- ============================================================================

-- Users can view their own relationships
CREATE POLICY "Users can view own relationships"
  ON user_relationships FOR SELECT
  USING (
    user_a_id::text = auth.uid()::text
    OR user_b_id::text = auth.uid()::text
  );

-- Users can create relationships they're part of
CREATE POLICY "Users can create own relationships"
  ON user_relationships FOR INSERT
  WITH CHECK (
    initiated_by_user_id::text = auth.uid()::text
    AND (user_a_id::text = auth.uid()::text OR user_b_id::text = auth.uid()::text)
  );

-- Users can update relationships they're part of
CREATE POLICY "Users can update own relationships"
  ON user_relationships FOR UPDATE
  USING (
    user_a_id::text = auth.uid()::text
    OR user_b_id::text = auth.uid()::text
  );

-- Users can delete relationships they're part of
CREATE POLICY "Users can delete own relationships"
  ON user_relationships FOR DELETE
  USING (
    user_a_id::text = auth.uid()::text
    OR user_b_id::text = auth.uid()::text
  );

-- ============================================================================
-- RELATIONSHIP PERMISSIONS POLICIES
-- ============================================================================

-- Users can view permissions for their relationships
CREATE POLICY "Users can view relationship permissions"
  ON relationship_permissions FOR SELECT
  USING (
    relationship_id IN (
      SELECT id FROM user_relationships
      WHERE user_a_id::text = auth.uid()::text
        OR user_b_id::text = auth.uid()::text
    )
  );

-- Users can update their own permissions
CREATE POLICY "Users can update own permissions"
  ON relationship_permissions FOR UPDATE
  USING (user_id::text = auth.uid()::text);

-- ============================================================================
-- RELATIONSHIP REQUESTS POLICIES
-- ============================================================================

-- Users can view requests sent to them
CREATE POLICY "Users can view requests to them"
  ON relationship_requests FOR SELECT
  USING (to_user_id::text = auth.uid()::text);

-- Users can view requests they sent
CREATE POLICY "Users can view own requests"
  ON relationship_requests FOR SELECT
  USING (from_user_id::text = auth.uid()::text);

-- Users can create requests they're sending
CREATE POLICY "Users can create requests"
  ON relationship_requests FOR INSERT
  WITH CHECK (from_user_id::text = auth.uid()::text);

-- Users can update requests they're involved in (accept/decline)
CREATE POLICY "Users can update requests to them"
  ON relationship_requests FOR UPDATE
  USING (
    to_user_id::text = auth.uid()::text
    OR from_user_id::text = auth.uid()::text
  );

-- Users can delete requests they sent (cancel)
CREATE POLICY "Users can cancel own requests"
  ON relationship_requests FOR DELETE
  USING (from_user_id::text = auth.uid()::text);

-- ============================================================================
-- INVITE CODES POLICIES
-- ============================================================================

-- Users can view their own invite codes
CREATE POLICY "Users can view own invite codes"
  ON relationship_invite_codes FOR SELECT
  USING (user_id::text = auth.uid()::text);

-- Anyone can view active invite codes by code (for redemption)
CREATE POLICY "Anyone can view active codes by code"
  ON relationship_invite_codes FOR SELECT
  USING (is_active = true);

-- Users can create their own invite codes
CREATE POLICY "Users can create invite codes"
  ON relationship_invite_codes FOR INSERT
  WITH CHECK (user_id::text = auth.uid()::text);

-- Users can update their own invite codes
CREATE POLICY "Users can update own invite codes"
  ON relationship_invite_codes FOR UPDATE
  USING (user_id::text = auth.uid()::text);

-- Users can delete their own invite codes
CREATE POLICY "Users can delete own invite codes"
  ON relationship_invite_codes FOR DELETE
  USING (user_id::text = auth.uid()::text);

-- ============================================================================
-- ACTIVITY FEED POLICIES
-- ============================================================================

-- Users can view their own activities
CREATE POLICY "Users can view own activities"
  ON gym_activity_feed FOR SELECT
  USING (user_id::text = auth.uid()::text);

-- Users can view gym activities if they're a member of that gym
CREATE POLICY "Gym members can view gym activities"
  ON gym_activity_feed FOR SELECT
  USING (
    visibility = 'gym'
    AND gym_id IN (
      SELECT gym_id FROM gym_memberships
      WHERE user_id::text = auth.uid()::text
        AND status = 'active'
    )
  );

-- Users can view friends' activities
CREATE POLICY "Users can view friends activities"
  ON gym_activity_feed FOR SELECT
  USING (
    visibility IN ('friends', 'public')
    AND user_id::text IN (
      -- Get all friends (relationships where status = accepted)
      SELECT CASE
        WHEN user_a_id::text = auth.uid()::text THEN user_b_id::text
        WHEN user_b_id::text = auth.uid()::text THEN user_a_id::text
      END
      FROM user_relationships
      WHERE (user_a_id::text = auth.uid()::text OR user_b_id::text = auth.uid()::text)
        AND status = 'accepted'
        AND relationship_type IN ('friend', 'race_partner')
    )
  );

-- Users can create their own activities
CREATE POLICY "Users can create own activities"
  ON gym_activity_feed FOR INSERT
  WITH CHECK (user_id::text = auth.uid()::text);

-- Users can update their own activities
CREATE POLICY "Users can update own activities"
  ON gym_activity_feed FOR UPDATE
  USING (user_id::text = auth.uid()::text);

-- Users can delete their own activities
CREATE POLICY "Users can delete own activities"
  ON gym_activity_feed FOR DELETE
  USING (user_id::text = auth.uid()::text);

-- ============================================================================
-- ACTIVITY KUDOS POLICIES
-- ============================================================================

-- Users can view kudos on activities they can see
CREATE POLICY "Users can view kudos on visible activities"
  ON activity_kudos FOR SELECT
  USING (
    activity_id IN (
      SELECT id FROM gym_activity_feed
      -- Reuse activity feed visibility logic
      WHERE user_id::text = auth.uid()::text
        OR (
          visibility = 'gym'
          AND gym_id IN (
            SELECT gym_id FROM gym_memberships
            WHERE user_id::text = auth.uid()::text AND status = 'active'
          )
        )
        OR (
          visibility IN ('friends', 'public')
          AND user_id::text IN (
            SELECT CASE
              WHEN user_a_id::text = auth.uid()::text THEN user_b_id::text
              WHEN user_b_id::text = auth.uid()::text THEN user_a_id::text
            END
            FROM user_relationships
            WHERE (user_a_id::text = auth.uid()::text OR user_b_id::text = auth.uid()::text)
              AND status = 'accepted'
          )
        )
    )
  );

-- Users can create kudos on activities they can see
CREATE POLICY "Users can give kudos"
  ON activity_kudos FOR INSERT
  WITH CHECK (
    user_id::text = auth.uid()::text
    AND activity_id IN (
      SELECT id FROM gym_activity_feed
      WHERE visibility IN ('gym', 'friends', 'public')
    )
  );

-- Users can delete their own kudos
CREATE POLICY "Users can remove own kudos"
  ON activity_kudos FOR DELETE
  USING (user_id::text = auth.uid()::text);

-- ============================================================================
-- ACTIVITY COMMENTS POLICIES
-- ============================================================================

-- Users can view comments on activities they can see
CREATE POLICY "Users can view comments on visible activities"
  ON activity_comments FOR SELECT
  USING (
    activity_id IN (
      SELECT id FROM gym_activity_feed
      WHERE user_id::text = auth.uid()::text
        OR visibility IN ('gym', 'friends', 'public')
    )
  );

-- Users can create comments on activities they can see
CREATE POLICY "Users can comment on activities"
  ON activity_comments FOR INSERT
  WITH CHECK (
    user_id::text = auth.uid()::text
    AND activity_id IN (
      SELECT id FROM gym_activity_feed
      WHERE visibility IN ('gym', 'friends', 'public')
    )
  );

-- Users can update their own comments
CREATE POLICY "Users can update own comments"
  ON activity_comments FOR UPDATE
  USING (user_id::text = auth.uid()::text);

-- Users can delete their own comments
CREATE POLICY "Users can delete own comments"
  ON activity_comments FOR DELETE
  USING (user_id::text = auth.uid()::text);

-- ============================================================================
-- WORKOUT COMPARISONS POLICIES
-- ============================================================================

-- Users can view comparisons involving their workouts
CREATE POLICY "Users can view own workout comparisons"
  ON workout_comparisons FOR SELECT
  USING (
    user_a_id::text = auth.uid()::text
    OR user_b_id::text = auth.uid()::text
  );

-- Users can create comparisons involving their workouts
CREATE POLICY "Users can create workout comparisons"
  ON workout_comparisons FOR INSERT
  WITH CHECK (
    user_a_id::text = auth.uid()::text
    OR user_b_id::text = auth.uid()::text
  );

-- Users can delete comparisons involving their workouts
CREATE POLICY "Users can delete workout comparisons"
  ON workout_comparisons FOR DELETE
  USING (
    user_a_id::text = auth.uid()::text
    OR user_b_id::text = auth.uid()::text
  );

-- ============================================================================
-- GYM LEADERBOARDS POLICIES
-- ============================================================================

-- Gym members can view leaderboards for their gym
CREATE POLICY "Gym members can view leaderboards"
  ON gym_leaderboards FOR SELECT
  USING (
    gym_id IN (
      SELECT gym_id FROM gym_memberships
      WHERE user_id::text = auth.uid()::text
        AND status = 'active'
    )
  );

-- Gym admins can create/update leaderboards (system operation)
CREATE POLICY "Gym admins can manage leaderboards"
  ON gym_leaderboards FOR ALL
  USING (
    gym_id IN (
      SELECT gym_id FROM gym_memberships
      WHERE user_id::text = auth.uid()::text
        AND role IN ('admin', 'owner')
        AND status = 'active'
    )
  );

-- ============================================================================
-- PERSONAL RECORDS POLICIES
-- ============================================================================

-- Users can view their own PRs
CREATE POLICY "Users can view own PRs"
  ON user_personal_records FOR SELECT
  USING (user_id::text = auth.uid()::text);

-- Friends can view each other's PRs (if permission granted)
CREATE POLICY "Friends can view PRs"
  ON user_personal_records FOR SELECT
  USING (
    user_id::text IN (
      -- Get friends with permission to share PRs
      SELECT other_user_id::text
      FROM (
        SELECT
          CASE
            WHEN ur.user_a_id::text = auth.uid()::text THEN ur.user_b_id
            ELSE ur.user_a_id
          END as other_user_id,
          ur.id as relationship_id
        FROM user_relationships ur
        WHERE (ur.user_a_id::text = auth.uid()::text OR ur.user_b_id::text = auth.uid()::text)
          AND ur.status = 'accepted'
      ) AS rels
      WHERE EXISTS (
        SELECT 1 FROM relationship_permissions rp
        WHERE rp.relationship_id = rels.relationship_id
          AND rp.user_id::text = rels.other_user_id::text
          AND rp.share_personal_records = true
      )
    )
  );

-- Gym members can view PRs of members who opt-in to leaderboards
CREATE POLICY "Gym members can view PRs on leaderboards"
  ON user_personal_records FOR SELECT
  USING (
    is_verified = true
    AND user_id IN (
      SELECT gm.user_id
      FROM gym_memberships gm
      WHERE gm.gym_id IN (
        SELECT gym_id FROM gym_memberships
        WHERE user_id::text = auth.uid()::text
          AND status = 'active'
      )
      AND gm.status = 'active'
      AND (gm.privacy_settings->>'show_on_leaderboard')::boolean = true
    )
  );

-- Users can create their own PRs
CREATE POLICY "Users can create own PRs"
  ON user_personal_records FOR INSERT
  WITH CHECK (user_id::text = auth.uid()::text);

-- Users can update their own PRs
CREATE POLICY "Users can update own PRs"
  ON user_personal_records FOR UPDATE
  USING (user_id::text = auth.uid()::text);

-- Users can delete their own PRs
CREATE POLICY "Users can delete own PRs"
  ON user_personal_records FOR DELETE
  USING (user_id::text = auth.uid()::text);

-- ============================================================================
-- HELPER COMMENTS
-- ============================================================================

COMMENT ON POLICY "Anyone can view public gyms" ON gyms IS 'Public gyms are discoverable by all users for search';
COMMENT ON POLICY "Gym members can view other members" ON gym_memberships IS 'Members can see each other only if show_in_member_list is true';
COMMENT ON POLICY "Users can view friends activities" ON gym_activity_feed IS 'Friends defined as accepted relationships of type friend or race_partner';
COMMENT ON POLICY "Friends can view PRs" ON user_personal_records IS 'PRs visible to friends only if share_personal_records permission is true';
