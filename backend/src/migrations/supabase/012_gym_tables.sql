-- FLEXR Gym Tables Migration
-- Creates tables for gym-local social features
-- Migration 012

-- Gyms table
-- Represents physical gyms, CrossFit boxes, training facilities
CREATE TABLE IF NOT EXISTS gyms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  location_address TEXT,
  location_city TEXT,
  location_state TEXT,
  location_country TEXT,
  location_postal_code TEXT,

  -- Geolocation for nearby search
  latitude NUMERIC(10, 7),
  longitude NUMERIC(10, 7),

  -- Gym type and verification
  gym_type TEXT NOT NULL DEFAULT 'gym' CHECK (
    gym_type IN ('crossfit', 'hyrox_affiliate', 'commercial_gym', 'boutique', 'home_gym', 'other')
  ),
  is_verified BOOLEAN DEFAULT false,
  verified_at TIMESTAMPTZ,

  -- Contact and social
  website_url TEXT,
  phone_number TEXT,
  email TEXT,
  instagram_handle TEXT,

  -- Stats (updated via triggers)
  member_count INTEGER DEFAULT 0,
  active_member_count INTEGER DEFAULT 0, -- members active in last 30 days

  -- Privacy and settings
  is_public BOOLEAN DEFAULT true, -- can be found in search
  allow_auto_join BOOLEAN DEFAULT true, -- users can join without approval

  -- Admin tracking
  created_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Gym memberships table
-- Represents user-gym relationships
CREATE TABLE IF NOT EXISTS gym_memberships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  gym_id UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,

  -- Membership status
  status TEXT NOT NULL DEFAULT 'active' CHECK (
    status IN ('pending', 'active', 'inactive', 'left')
  ),

  -- Role at gym
  role TEXT NOT NULL DEFAULT 'member' CHECK (
    role IN ('member', 'coach', 'admin', 'owner')
  ),

  -- Privacy settings for this gym
  privacy_settings JSONB DEFAULT '{
    "show_on_leaderboard": true,
    "show_in_member_list": true,
    "show_workout_activity": true,
    "allow_workout_comparisons": true,
    "show_profile_to_members": true
  }'::jsonb,

  -- Activity tracking
  last_activity_at TIMESTAMPTZ,
  total_workouts_at_gym INTEGER DEFAULT 0,

  -- Membership dates
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  approved_at TIMESTAMPTZ,
  left_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Ensure user can only be member of each gym once
  UNIQUE(user_id, gym_id)
);

-- Create indexes for performance
-- Gym searches
CREATE INDEX IF NOT EXISTS idx_gyms_location ON gyms(location_city, location_state, location_country);
CREATE INDEX IF NOT EXISTS idx_gyms_type ON gyms(gym_type) WHERE is_public = true;
CREATE INDEX IF NOT EXISTS idx_gyms_name_search ON gyms USING gin(to_tsvector('english', name));

-- Membership lookups
CREATE INDEX IF NOT EXISTS idx_gym_memberships_user ON gym_memberships(user_id, status);
CREATE INDEX IF NOT EXISTS idx_gym_memberships_gym ON gym_memberships(gym_id, status);
CREATE INDEX IF NOT EXISTS idx_gym_memberships_active ON gym_memberships(gym_id) WHERE status = 'active';

-- Geospatial index for nearby gym search (if using PostGIS in future)
-- CREATE INDEX IF NOT EXISTS idx_gyms_location_geo ON gyms USING gist(ll_to_earth(latitude, longitude));

-- Function to update gym member counts
CREATE OR REPLACE FUNCTION update_gym_member_count()
RETURNS TRIGGER AS $$
BEGIN
  -- Update member counts when membership status changes
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    UPDATE gyms
    SET
      member_count = (
        SELECT COUNT(*)
        FROM gym_memberships
        WHERE gym_id = NEW.gym_id
          AND status IN ('active', 'pending')
      ),
      active_member_count = (
        SELECT COUNT(*)
        FROM gym_memberships
        WHERE gym_id = NEW.gym_id
          AND status = 'active'
          AND last_activity_at > NOW() - INTERVAL '30 days'
      ),
      updated_at = NOW()
    WHERE id = NEW.gym_id;
  END IF;

  IF TG_OP = 'DELETE' THEN
    UPDATE gyms
    SET
      member_count = (
        SELECT COUNT(*)
        FROM gym_memberships
        WHERE gym_id = OLD.gym_id
          AND status IN ('active', 'pending')
      ),
      active_member_count = (
        SELECT COUNT(*)
        FROM gym_memberships
        WHERE gym_id = OLD.gym_id
          AND status = 'active'
          AND last_activity_at > NOW() - INTERVAL '30 days'
      ),
      updated_at = NOW()
    WHERE id = OLD.gym_id;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Trigger to update gym member counts
DROP TRIGGER IF EXISTS trigger_update_gym_member_count ON gym_memberships;
CREATE TRIGGER trigger_update_gym_member_count
  AFTER INSERT OR UPDATE OR DELETE ON gym_memberships
  FOR EACH ROW
  EXECUTE FUNCTION update_gym_member_count();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
DROP TRIGGER IF EXISTS trigger_gyms_updated_at ON gyms;
CREATE TRIGGER trigger_gyms_updated_at
  BEFORE UPDATE ON gyms
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trigger_gym_memberships_updated_at ON gym_memberships;
CREATE TRIGGER trigger_gym_memberships_updated_at
  BEFORE UPDATE ON gym_memberships
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Add helpful comments
COMMENT ON TABLE gyms IS 'Physical gyms, CrossFit boxes, and training facilities';
COMMENT ON TABLE gym_memberships IS 'User membership and privacy settings for each gym';
COMMENT ON COLUMN gyms.allow_auto_join IS 'If true, users can join without admin approval';
COMMENT ON COLUMN gym_memberships.privacy_settings IS 'Per-gym privacy controls for social features';
