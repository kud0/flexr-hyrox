-- FLEXR User Relationships Migration
-- Creates unified table for gym connections, friends, and race partners
-- Migration 013

-- User relationships table (unified approach)
-- Handles gym connections, friends, and race partners in one table
CREATE TABLE IF NOT EXISTS user_relationships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Always store user IDs in canonical order (lower UUID first)
  -- This prevents duplicate relationships (A->B and B->A)
  user_a_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user_b_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Relationship type determines access level
  relationship_type TEXT NOT NULL CHECK (
    relationship_type IN ('gym_member', 'friend', 'race_partner')
  ),

  -- Status workflow: pending -> accepted -> (active/ended)
  status TEXT NOT NULL DEFAULT 'pending' CHECK (
    status IN ('pending', 'accepted', 'blocked', 'ended')
  ),

  -- Track who initiated the relationship
  initiated_by_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Track relationship origin (for gym_member type)
  origin_gym_id UUID REFERENCES gyms(id) ON DELETE SET NULL,

  -- Race partner specific fields
  race_partner_metadata JSONB DEFAULT '{}'::jsonb,
  -- Example: { "race_date": "2025-06-15", "race_type": "doubles", "race_location": "London" }

  -- Activity tracking
  last_interaction_at TIMESTAMPTZ,
  interaction_count INTEGER DEFAULT 0,

  -- Important dates
  created_at TIMESTAMPTZ DEFAULT NOW(),
  accepted_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Ensure no duplicate relationships
  -- user_a_id must be less than user_b_id (canonical ordering)
  CONSTRAINT user_relationships_canonical_order CHECK (user_a_id < user_b_id),
  UNIQUE(user_a_id, user_b_id, relationship_type)
);

-- Relationship permissions table
-- Granular per-user, per-relationship permissions
-- Each user controls what THEY share with the other person
CREATE TABLE IF NOT EXISTS relationship_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  relationship_id UUID NOT NULL REFERENCES user_relationships(id) ON DELETE CASCADE,

  -- Which user's permissions these are
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Granular permission flags (what THIS user shares with the OTHER user)
  share_workout_history BOOLEAN DEFAULT false,
  share_workout_details BOOLEAN DEFAULT false,
  share_performance_stats BOOLEAN DEFAULT false,
  share_station_strengths BOOLEAN DEFAULT false,
  share_training_plan BOOLEAN DEFAULT false,
  share_race_goals BOOLEAN DEFAULT false,
  share_personal_records BOOLEAN DEFAULT false,
  share_heart_rate BOOLEAN DEFAULT false,
  share_workout_videos BOOLEAN DEFAULT false,
  share_location BOOLEAN DEFAULT false,
  allow_workout_comparisons BOOLEAN DEFAULT false,
  allow_kudos BOOLEAN DEFAULT true,
  allow_comments BOOLEAN DEFAULT true,
  show_on_leaderboards BOOLEAN DEFAULT false,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Each user in a relationship has their own permission row
  UNIQUE(relationship_id, user_id)
);

-- Relationship requests table
-- Tracks pending friend/partner requests before acceptance
CREATE TABLE IF NOT EXISTS relationship_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Who is sending the request
  from_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Who is receiving the request
  to_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- What type of relationship is being requested
  relationship_type TEXT NOT NULL CHECK (
    relationship_type IN ('friend', 'race_partner')
  ),

  -- Optional message with request
  message TEXT,

  -- Request status
  status TEXT NOT NULL DEFAULT 'pending' CHECK (
    status IN ('pending', 'accepted', 'declined', 'cancelled')
  ),

  -- Auto-expire requests after 30 days
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '30 days'),

  created_at TIMESTAMPTZ DEFAULT NOW(),
  responded_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Prevent duplicate requests
  UNIQUE(from_user_id, to_user_id, relationship_type)
);

-- Invite codes table
-- For easy friend/partner linking via shareable codes
CREATE TABLE IF NOT EXISTS relationship_invite_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Who created this code
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Human-readable code (e.g., "ALEX-TRAIN-2025")
  code TEXT NOT NULL UNIQUE,

  -- What type of relationship this code creates
  relationship_type TEXT NOT NULL CHECK (
    relationship_type IN ('friend', 'race_partner')
  ),

  -- Usage tracking
  max_uses INTEGER DEFAULT 1, -- Usually 1 for race partners, could be unlimited for gym codes
  current_uses INTEGER DEFAULT 0,

  -- Expiration
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '90 days'),
  is_active BOOLEAN DEFAULT true,

  -- Metadata
  metadata JSONB DEFAULT '{}'::jsonb,
  -- Example: { "race_name": "HYROX London 2025", "note": "Let's train together!" }

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
-- Relationship lookups (most common query pattern)
CREATE INDEX IF NOT EXISTS idx_user_relationships_user_a ON user_relationships(user_a_id, status);
CREATE INDEX IF NOT EXISTS idx_user_relationships_user_b ON user_relationships(user_b_id, status);
CREATE INDEX IF NOT EXISTS idx_user_relationships_type ON user_relationships(relationship_type, status);
CREATE INDEX IF NOT EXISTS idx_user_relationships_gym ON user_relationships(origin_gym_id) WHERE origin_gym_id IS NOT NULL;

-- Permission lookups
CREATE INDEX IF NOT EXISTS idx_relationship_permissions_relationship ON relationship_permissions(relationship_id, user_id);

-- Request lookups
CREATE INDEX IF NOT EXISTS idx_relationship_requests_to_user ON relationship_requests(to_user_id, status);
CREATE INDEX IF NOT EXISTS idx_relationship_requests_from_user ON relationship_requests(from_user_id, status);

-- Invite code lookups
CREATE INDEX IF NOT EXISTS idx_invite_codes_code ON relationship_invite_codes(code) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_invite_codes_user ON relationship_invite_codes(user_id, is_active);

-- Helper function to get all relationships for a user
-- Returns relationships regardless of whether user is user_a or user_b
CREATE OR REPLACE FUNCTION get_user_relationships(target_user_id UUID)
RETURNS TABLE (
  relationship_id UUID,
  other_user_id UUID,
  relationship_type TEXT,
  status TEXT,
  initiated_by_me BOOLEAN,
  origin_gym_id UUID,
  created_at TIMESTAMPTZ,
  accepted_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    ur.id as relationship_id,
    CASE
      WHEN ur.user_a_id = target_user_id THEN ur.user_b_id
      ELSE ur.user_a_id
    END as other_user_id,
    ur.relationship_type,
    ur.status,
    ur.initiated_by_user_id = target_user_id as initiated_by_me,
    ur.origin_gym_id,
    ur.created_at,
    ur.accepted_at
  FROM user_relationships ur
  WHERE ur.user_a_id = target_user_id OR ur.user_b_id = target_user_id;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to create default permissions when relationship is accepted
CREATE OR REPLACE FUNCTION create_default_relationship_permissions()
RETURNS TRIGGER AS $$
DECLARE
  default_permissions JSONB;
BEGIN
  -- Only create permissions when relationship is accepted
  IF NEW.status = 'accepted' AND (OLD IS NULL OR OLD.status != 'accepted') THEN

    -- Set default permissions based on relationship type
    CASE NEW.relationship_type
      WHEN 'gym_member' THEN
        -- Gym members: minimal sharing by default
        default_permissions := '{
          "share_workout_history": false,
          "share_workout_details": false,
          "share_performance_stats": false,
          "share_station_strengths": false,
          "allow_workout_comparisons": false,
          "allow_kudos": true,
          "show_on_leaderboards": true
        }'::jsonb;

      WHEN 'friend' THEN
        -- Friends: moderate sharing by default
        default_permissions := '{
          "share_workout_history": true,
          "share_workout_details": true,
          "share_performance_stats": true,
          "share_station_strengths": true,
          "allow_workout_comparisons": true,
          "allow_kudos": true,
          "allow_comments": true,
          "show_on_leaderboards": true
        }'::jsonb;

      WHEN 'race_partner' THEN
        -- Race partners: high sharing by default
        default_permissions := '{
          "share_workout_history": true,
          "share_workout_details": true,
          "share_performance_stats": true,
          "share_station_strengths": true,
          "share_training_plan": true,
          "share_race_goals": true,
          "share_personal_records": true,
          "allow_workout_comparisons": true,
          "allow_kudos": true,
          "allow_comments": true,
          "show_on_leaderboards": true
        }'::jsonb;
    END CASE;

    -- Create permission rows for both users
    INSERT INTO relationship_permissions (relationship_id, user_id)
    VALUES (NEW.id, NEW.user_a_id), (NEW.id, NEW.user_b_id)
    ON CONFLICT (relationship_id, user_id) DO NOTHING;

    -- Update permissions with defaults
    UPDATE relationship_permissions
    SET
      share_workout_history = (default_permissions->>'share_workout_history')::boolean,
      share_workout_details = (default_permissions->>'share_workout_details')::boolean,
      share_performance_stats = (default_permissions->>'share_performance_stats')::boolean,
      share_station_strengths = (default_permissions->>'share_station_strengths')::boolean,
      share_training_plan = COALESCE((default_permissions->>'share_training_plan')::boolean, false),
      share_race_goals = COALESCE((default_permissions->>'share_race_goals')::boolean, false),
      share_personal_records = COALESCE((default_permissions->>'share_personal_records')::boolean, false),
      allow_workout_comparisons = (default_permissions->>'allow_workout_comparisons')::boolean,
      allow_kudos = (default_permissions->>'allow_kudos')::boolean,
      allow_comments = COALESCE((default_permissions->>'allow_comments')::boolean, true),
      show_on_leaderboards = (default_permissions->>'show_on_leaderboards')::boolean,
      updated_at = NOW()
    WHERE relationship_id = NEW.id;

  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to create default permissions
DROP TRIGGER IF EXISTS trigger_create_default_permissions ON user_relationships;
CREATE TRIGGER trigger_create_default_permissions
  AFTER INSERT OR UPDATE OF status ON user_relationships
  FOR EACH ROW
  EXECUTE FUNCTION create_default_relationship_permissions();

-- Updated_at triggers
DROP TRIGGER IF EXISTS trigger_user_relationships_updated_at ON user_relationships;
CREATE TRIGGER trigger_user_relationships_updated_at
  BEFORE UPDATE ON user_relationships
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trigger_relationship_permissions_updated_at ON relationship_permissions;
CREATE TRIGGER trigger_relationship_permissions_updated_at
  BEFORE UPDATE ON relationship_permissions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trigger_relationship_requests_updated_at ON relationship_requests;
CREATE TRIGGER trigger_relationship_requests_updated_at
  BEFORE UPDATE ON relationship_requests
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trigger_invite_codes_updated_at ON relationship_invite_codes;
CREATE TRIGGER trigger_invite_codes_updated_at
  BEFORE UPDATE ON relationship_invite_codes
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Add helpful comments
COMMENT ON TABLE user_relationships IS 'Unified table for all user relationships: gym connections, friends, race partners';
COMMENT ON TABLE relationship_permissions IS 'Granular per-user permissions for what each user shares in a relationship';
COMMENT ON TABLE relationship_requests IS 'Pending friend/partner requests before acceptance';
COMMENT ON TABLE relationship_invite_codes IS 'Shareable codes for easy friend/partner linking';
COMMENT ON CONSTRAINT user_relationships_canonical_order ON user_relationships IS 'Ensures user_a_id < user_b_id to prevent duplicate relationships';
COMMENT ON FUNCTION get_user_relationships IS 'Helper to get all relationships for a user regardless of position in canonical ordering';
