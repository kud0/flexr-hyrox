-- FLEXR Gym Social Features Migration
-- Creates tables for activity feed, workout comparisons, and leaderboards
-- Migration 014

-- Gym activity feed
-- Tracks user activities visible to gym members and friends
CREATE TABLE IF NOT EXISTS gym_activity_feed (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Who performed the activity
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Which gym this activity is associated with (if any)
  gym_id UUID REFERENCES gyms(id) ON DELETE CASCADE,

  -- Activity type determines what is shown
  activity_type TEXT NOT NULL CHECK (
    activity_type IN (
      'workout_completed',
      'personal_record',
      'milestone_reached',
      'gym_joined',
      'achievement_unlocked',
      'workout_streak',
      'friend_added',
      'race_partner_linked'
    )
  ),

  -- Reference to the entity (workout, achievement, etc.)
  entity_type TEXT,
  entity_id UUID,

  -- Activity metadata (flexible for different activity types)
  metadata JSONB DEFAULT '{}'::jsonb,
  -- Examples:
  -- workout_completed: { "workout_title": "HYROX Simulation", "duration_minutes": 65, "total_distance_km": 8 }
  -- personal_record: { "record_type": "fastest_1km", "time_seconds": 240, "previous_best": 255 }
  -- milestone: { "type": "100km_total", "value": 100 }

  -- Visibility control
  visibility TEXT NOT NULL DEFAULT 'gym' CHECK (
    visibility IN ('private', 'gym', 'friends', 'public')
  ),

  -- Engagement tracking
  kudos_count INTEGER DEFAULT 0,
  comment_count INTEGER DEFAULT 0,

  -- Auto-expire old activities (keep feed fresh)
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '90 days'),

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Activity kudos (reactions)
-- Users can give kudos to activities
CREATE TABLE IF NOT EXISTS activity_kudos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  activity_id UUID NOT NULL REFERENCES gym_activity_feed(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Kudos type (for future: fire, lightning, strong, etc.)
  kudos_type TEXT NOT NULL DEFAULT 'kudos' CHECK (
    kudos_type IN ('kudos', 'fire', 'lightning', 'strong', 'bullseye', 'heart')
  ),

  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Each user can give one kudos per activity
  UNIQUE(activity_id, user_id, kudos_type)
);

-- Activity comments (optional for v1)
CREATE TABLE IF NOT EXISTS activity_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  activity_id UUID NOT NULL REFERENCES gym_activity_feed(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  comment_text TEXT NOT NULL,

  -- For threading (optional)
  parent_comment_id UUID REFERENCES activity_comments(id) ON DELETE CASCADE,

  -- Moderation
  is_deleted BOOLEAN DEFAULT false,
  deleted_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Workout comparisons
-- Cached comparisons between similar workouts
CREATE TABLE IF NOT EXISTS workout_comparisons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- The two workouts being compared
  workout_a_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
  workout_b_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,

  -- Users who own these workouts
  user_a_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user_b_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Similarity score (0-1, higher = more similar)
  similarity_score NUMERIC(3, 2) NOT NULL,

  -- Comparison results (cached to avoid recomputation)
  comparison_data JSONB NOT NULL,
  -- Example:
  -- {
  --   "segment_comparisons": [
  --     { "segment_type": "1km_run", "user_a_time": 240, "user_b_time": 255, "difference": -15 },
  --     { "segment_type": "sled_push", "user_a_time": 180, "user_b_time": 165, "difference": 15 }
  --   ],
  --   "total_time_difference": 45,
  --   "winner": "user_a",
  --   "insights": ["User A was 15s faster on running", "User B was 15s faster on sled push"]
  -- }

  -- Cache expiration (recompute after 90 days)
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '90 days'),

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Prevent duplicate comparisons
  UNIQUE(workout_a_id, workout_b_id)
);

-- Gym leaderboards (materialized view approach)
-- Pre-computed leaderboards for fast access
CREATE TABLE IF NOT EXISTS gym_leaderboards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gym_id UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,

  -- Leaderboard type and period
  leaderboard_type TEXT NOT NULL CHECK (
    leaderboard_type IN (
      'overall_workouts',        -- Most workouts completed
      'overall_distance',        -- Total distance covered
      'overall_time',            -- Total training time
      'consistency',             -- Training streak
      'station_1km_run',         -- Fastest 1km run
      'station_sled_push',       -- Fastest sled push
      'station_sled_pull',       -- Fastest sled pull
      'station_rowing',          -- Fastest 1000m row
      'station_ski_erg',         -- Fastest 1000m ski erg
      'station_wall_balls',      -- Fastest 100 wall balls
      'station_burpee_broad_jump' -- Fastest 80m burpee broad jump
    )
  ),

  period TEXT NOT NULL CHECK (
    period IN ('weekly', 'monthly', 'all_time')
  ),

  -- Period boundaries
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,

  -- Leaderboard data (array of rankings)
  rankings JSONB NOT NULL,
  -- Example:
  -- [
  --   { "rank": 1, "user_id": "uuid", "value": 1250, "metadata": { "workout_count": 12 } },
  --   { "rank": 2, "user_id": "uuid", "value": 1180, "metadata": { "workout_count": 11 } }
  -- ]

  -- Metadata
  total_participants INTEGER NOT NULL DEFAULT 0,
  last_computed_at TIMESTAMPTZ DEFAULT NOW(),

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- One leaderboard per gym + type + period
  UNIQUE(gym_id, leaderboard_type, period, period_start)
);

-- User personal records
-- Track PRs for stations and overall workouts
CREATE TABLE IF NOT EXISTS user_personal_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Record type
  record_type TEXT NOT NULL CHECK (
    record_type IN (
      'fastest_1km_run',
      'fastest_sled_push_50m',
      'fastest_sled_pull_50m',
      'fastest_1000m_row',
      'fastest_1000m_ski_erg',
      'fastest_100_wall_balls',
      'fastest_80m_burpee_broad_jump',
      'fastest_full_hyrox',
      'longest_distance_single_workout',
      'longest_training_streak'
    )
  ),

  -- Record value (time in seconds, distance in meters, count, etc.)
  value NUMERIC(10, 2) NOT NULL,
  unit TEXT NOT NULL, -- 'seconds', 'meters', 'count', 'days'

  -- Reference to workout/segment where record was set
  workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL,
  segment_id UUID REFERENCES workout_segments(id) ON DELETE SET NULL,

  -- Previous record (for calculating improvement)
  previous_value NUMERIC(10, 2),

  -- Verification status (for leaderboard integrity)
  is_verified BOOLEAN DEFAULT false,
  verified_by_device TEXT, -- 'apple_watch', 'manual', 'video'

  -- Metadata
  metadata JSONB DEFAULT '{}'::jsonb,

  achieved_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- One record per user per type (updated when beaten)
  UNIQUE(user_id, record_type)
);

-- Create indexes for performance

-- Activity feed queries (most common: user's feed, gym feed)
CREATE INDEX IF NOT EXISTS idx_activity_feed_user ON gym_activity_feed(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_feed_gym ON gym_activity_feed(gym_id, created_at DESC) WHERE gym_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_activity_feed_visibility ON gym_activity_feed(visibility, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_feed_type ON gym_activity_feed(activity_type, created_at DESC);

-- Kudos lookups
CREATE INDEX IF NOT EXISTS idx_activity_kudos_activity ON activity_kudos(activity_id);
CREATE INDEX IF NOT EXISTS idx_activity_kudos_user ON activity_kudos(user_id, created_at DESC);

-- Comments lookups
CREATE INDEX IF NOT EXISTS idx_activity_comments_activity ON activity_comments(activity_id, created_at);
CREATE INDEX IF NOT EXISTS idx_activity_comments_parent ON activity_comments(parent_comment_id) WHERE parent_comment_id IS NOT NULL;

-- Comparison lookups
CREATE INDEX IF NOT EXISTS idx_workout_comparisons_users ON workout_comparisons(user_a_id, user_b_id);
CREATE INDEX IF NOT EXISTS idx_workout_comparisons_workouts ON workout_comparisons(workout_a_id, workout_b_id);
CREATE INDEX IF NOT EXISTS idx_workout_comparisons_similarity ON workout_comparisons(similarity_score DESC);

-- Leaderboard lookups
CREATE INDEX IF NOT EXISTS idx_gym_leaderboards_gym ON gym_leaderboards(gym_id, period, leaderboard_type);
CREATE INDEX IF NOT EXISTS idx_gym_leaderboards_period ON gym_leaderboards(period_start, period_end);

-- Personal record lookups
CREATE INDEX IF NOT EXISTS idx_personal_records_user ON user_personal_records(user_id, record_type);
CREATE INDEX IF NOT EXISTS idx_personal_records_type ON user_personal_records(record_type, value) WHERE is_verified = true;

-- Function to update kudos count on activity
CREATE OR REPLACE FUNCTION update_activity_kudos_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE gym_activity_feed
    SET kudos_count = kudos_count + 1
    WHERE id = NEW.activity_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE gym_activity_feed
    SET kudos_count = GREATEST(0, kudos_count - 1)
    WHERE id = OLD.activity_id;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Trigger for kudos count
DROP TRIGGER IF EXISTS trigger_update_activity_kudos_count ON activity_kudos;
CREATE TRIGGER trigger_update_activity_kudos_count
  AFTER INSERT OR DELETE ON activity_kudos
  FOR EACH ROW
  EXECUTE FUNCTION update_activity_kudos_count();

-- Function to update comment count on activity
CREATE OR REPLACE FUNCTION update_activity_comment_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE gym_activity_feed
    SET comment_count = comment_count + 1
    WHERE id = NEW.activity_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE gym_activity_feed
    SET comment_count = GREATEST(0, comment_count - 1)
    WHERE id = OLD.activity_id;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Trigger for comment count
DROP TRIGGER IF EXISTS trigger_update_activity_comment_count ON activity_comments;
CREATE TRIGGER trigger_update_activity_comment_count
  AFTER INSERT OR DELETE ON activity_comments
  FOR EACH ROW
  EXECUTE FUNCTION update_activity_comment_count();

-- Function to auto-create activity feed entry when workout completed
CREATE OR REPLACE FUNCTION create_workout_completion_activity()
RETURNS TRIGGER AS $$
DECLARE
  user_gym_id UUID;
BEGIN
  -- Only create activity for completed workouts
  IF NEW.status = 'completed' AND (OLD IS NULL OR OLD.status != 'completed') THEN

    -- Get user's primary gym (if any)
    SELECT gym_id INTO user_gym_id
    FROM gym_memberships
    WHERE user_id = NEW.user_id
      AND status = 'active'
    ORDER BY joined_at
    LIMIT 1;

    -- Create activity feed entry
    INSERT INTO gym_activity_feed (
      user_id,
      gym_id,
      activity_type,
      entity_type,
      entity_id,
      metadata,
      visibility
    ) VALUES (
      NEW.user_id,
      user_gym_id,
      'workout_completed',
      'workout',
      NEW.id,
      jsonb_build_object(
        'workout_title', NEW.title,
        'workout_type', NEW.type,
        'duration_minutes', NEW.total_duration_minutes,
        'difficulty', NEW.difficulty
      ),
      'gym' -- Default visibility to gym
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to create activity on workout completion
DROP TRIGGER IF EXISTS trigger_create_workout_activity ON workouts;
CREATE TRIGGER trigger_create_workout_activity
  AFTER UPDATE OF status ON workouts
  FOR EACH ROW
  EXECUTE FUNCTION create_workout_completion_activity();

-- Updated_at triggers
DROP TRIGGER IF EXISTS trigger_activity_comments_updated_at ON activity_comments;
CREATE TRIGGER trigger_activity_comments_updated_at
  BEFORE UPDATE ON activity_comments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trigger_workout_comparisons_updated_at ON workout_comparisons;
CREATE TRIGGER trigger_workout_comparisons_updated_at
  BEFORE UPDATE ON workout_comparisons
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trigger_gym_leaderboards_updated_at ON gym_leaderboards;
CREATE TRIGGER trigger_gym_leaderboards_updated_at
  BEFORE UPDATE ON gym_leaderboards
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Add helpful comments
COMMENT ON TABLE gym_activity_feed IS 'Social activity feed for gym members and friends';
COMMENT ON TABLE activity_kudos IS 'Kudos/reactions given to activities';
COMMENT ON TABLE activity_comments IS 'Comments on activities (optional feature)';
COMMENT ON TABLE workout_comparisons IS 'Cached comparisons between similar workouts';
COMMENT ON TABLE gym_leaderboards IS 'Pre-computed leaderboards for fast access';
COMMENT ON TABLE user_personal_records IS 'User personal records for stations and overall performance';
COMMENT ON COLUMN gym_activity_feed.expires_at IS 'Activities auto-expire after 90 days to keep feed fresh';
COMMENT ON COLUMN workout_comparisons.similarity_score IS 'Score 0-1 indicating how similar the workouts are';
