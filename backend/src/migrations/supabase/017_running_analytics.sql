-- FLEXR - Running Analytics Schema
-- Comprehensive running data for HYROX athletes
-- Focus: Performance metrics, not social features

-- Drop existing objects for idempotent migration
DROP TABLE IF EXISTS interval_sessions CASCADE;
DROP TABLE IF EXISTS running_sessions CASCADE;
DROP TYPE IF EXISTS running_session_type CASCADE;
DROP TYPE IF EXISTS activity_visibility CASCADE;

-- Activity visibility enum (used across platform)
CREATE TYPE activity_visibility AS ENUM (
  'private',    -- Only user
  'friends',    -- User + friends
  'gym',        -- User + gym members (default)
  'public'      -- Everyone
);

-- Running session types enum
CREATE TYPE running_session_type AS ENUM (
  'long_run',        -- Endurance building
  'intervals',       -- Speed work (400m, 800m, 1k, etc.)
  'threshold',       -- Tempo pace (sustained effort)
  'time_trial_5k',   -- 5K benchmark
  'time_trial_10k',  -- 10K benchmark
  'recovery',        -- Easy recovery
  'easy'             -- General easy run
);

-- Main running sessions table
CREATE TABLE running_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  gym_id UUID REFERENCES public.gyms(id) ON DELETE SET NULL,

  -- Session classification
  session_type running_session_type NOT NULL,
  workout_id UUID REFERENCES public.workouts(id) ON DELETE SET NULL,

  -- Basic metrics (all in metric units)
  distance_meters INT NOT NULL CHECK (distance_meters > 0),
  duration_seconds INT NOT NULL CHECK (duration_seconds > 0),
  elevation_gain_meters INT DEFAULT 0,

  -- Pace data (seconds per km)
  avg_pace_per_km NUMERIC(6,2) NOT NULL CHECK (avg_pace_per_km > 0),
  fastest_km_pace NUMERIC(6,2),
  slowest_km_pace NUMERIC(6,2),

  -- Heart rate (bpm)
  avg_heart_rate INT CHECK (avg_heart_rate > 0 AND avg_heart_rate < 250),
  max_heart_rate INT CHECK (max_heart_rate > 0 AND max_heart_rate < 250),

  -- Heart rate zones (JSONB for flexibility)
  -- Format: {"zone1": 300, "zone2": 450, "zone3": 600, "zone4": 200, "zone5": 50}
  -- Values are seconds spent in each zone
  heart_rate_zones JSONB,

  -- Detailed split data (JSONB array)
  -- Format: [{"km": 1, "time": 240, "pace": 240, "hr": 165, "elevation": 5}, ...]
  -- Time in seconds, pace in sec/km, hr in bpm, elevation in meters
  splits JSONB,

  -- Route data (optional, for outdoor runs)
  -- Format: {"coordinates": [[lat, lng], ...], "city": "Berlin", "country": "Germany"}
  route_data JSONB,

  -- Performance analysis
  pace_consistency NUMERIC(6,2), -- Standard deviation of pace (lower = more consistent)
  fade_factor NUMERIC(4,2),      -- % slower in second half vs first half (negative = negative split)

  -- Metadata
  created_at TIMESTAMP DEFAULT NOW(),
  started_at TIMESTAMP,
  ended_at TIMESTAMP,

  -- Privacy
  visibility activity_visibility DEFAULT 'gym',

  -- Notes/comments
  notes TEXT,

  -- Constraints
  CONSTRAINT valid_heart_rate CHECK (
    (avg_heart_rate IS NULL AND max_heart_rate IS NULL) OR
    (avg_heart_rate IS NOT NULL AND max_heart_rate IS NOT NULL AND max_heart_rate >= avg_heart_rate)
  ),
  CONSTRAINT valid_pace_range CHECK (
    (fastest_km_pace IS NULL AND slowest_km_pace IS NULL) OR
    (fastest_km_pace IS NOT NULL AND slowest_km_pace IS NOT NULL AND slowest_km_pace >= fastest_km_pace)
  ),
  CONSTRAINT valid_timestamps CHECK (
    (started_at IS NULL AND ended_at IS NULL) OR
    (started_at IS NOT NULL AND ended_at IS NOT NULL AND ended_at > started_at)
  )
);

-- Interval-specific data (structured workouts)
CREATE TABLE interval_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  running_session_id UUID NOT NULL REFERENCES running_sessions(id) ON DELETE CASCADE,

  -- Interval structure
  work_distance_meters INT NOT NULL CHECK (work_distance_meters > 0),  -- e.g., 400, 800, 1000
  rest_duration_seconds INT NOT NULL CHECK (rest_duration_seconds >= 0),
  target_pace_per_km NUMERIC(6,2),  -- Target pace in sec/km (optional)
  total_reps INT NOT NULL CHECK (total_reps > 0),

  -- Individual interval data (JSONB array)
  -- Format: [{"rep": 1, "distance": 400, "time": 75, "pace": 187.5, "hr_avg": 175, "hr_max": 182}, ...]
  -- pace in sec/km, time in seconds, hr in bpm
  intervals JSONB NOT NULL,

  -- Performance analysis
  avg_work_pace NUMERIC(6,2) NOT NULL,    -- Average pace across all work intervals
  pace_drop_off NUMERIC(4,2),              -- % slower on last rep vs first rep
  recovery_quality NUMERIC(4,2),           -- Avg HR drop during rest periods (%)

  created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_running_sessions_user ON running_sessions(user_id);
CREATE INDEX idx_running_sessions_gym ON running_sessions(gym_id);
CREATE INDEX idx_running_sessions_type ON running_sessions(session_type);
CREATE INDEX idx_running_sessions_date ON running_sessions(created_at DESC);
CREATE INDEX idx_running_sessions_visibility ON running_sessions(visibility);

-- Composite indexes for common queries
CREATE INDEX idx_running_sessions_gym_type_date ON running_sessions(gym_id, session_type, created_at DESC)
  WHERE gym_id IS NOT NULL AND visibility IN ('gym', 'public');

CREATE INDEX idx_running_sessions_leaderboard_5k ON running_sessions(gym_id, avg_pace_per_km)
  WHERE session_type = 'time_trial_5k' AND distance_meters BETWEEN 4900 AND 5100;

CREATE INDEX idx_running_sessions_leaderboard_10k ON running_sessions(gym_id, avg_pace_per_km)
  WHERE session_type = 'time_trial_10k' AND distance_meters BETWEEN 9900 AND 10100;

CREATE INDEX idx_interval_sessions_running ON interval_sessions(running_session_id);

-- RLS Policies
ALTER TABLE running_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE interval_sessions ENABLE ROW LEVEL SECURITY;

-- Users can view their own sessions
CREATE POLICY "Users can view own running sessions"
  ON running_sessions FOR SELECT
  USING (auth.uid() = user_id);

-- Users can view public sessions
CREATE POLICY "Users can view public running sessions"
  ON running_sessions FOR SELECT
  USING (visibility = 'public');

-- Users can view gym sessions if they're a member
CREATE POLICY "Gym members can view gym running sessions"
  ON running_sessions FOR SELECT
  USING (
    visibility IN ('gym', 'public') AND
    EXISTS (
      SELECT 1 FROM gym_memberships
      WHERE gym_memberships.gym_id = running_sessions.gym_id
        AND gym_memberships.user_id = auth.uid()
        AND gym_memberships.status = 'active'
    )
  );

-- Users can view friends' sessions
CREATE POLICY "Friends can view friends running sessions"
  ON running_sessions FOR SELECT
  USING (
    visibility IN ('friends', 'gym', 'public') AND
    EXISTS (
      SELECT 1 FROM user_relationships
      WHERE (
        (user_a_id = auth.uid() AND user_b_id = user_id) OR
        (user_b_id = auth.uid() AND user_a_id = user_id)
      )
      AND relationship_type IN ('friend', 'race_partner')
      AND status = 'accepted'
    )
  );

-- Users can insert their own sessions
CREATE POLICY "Users can insert own running sessions"
  ON running_sessions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own sessions
CREATE POLICY "Users can update own running sessions"
  ON running_sessions FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own sessions
CREATE POLICY "Users can delete own running sessions"
  ON running_sessions FOR DELETE
  USING (auth.uid() = user_id);

-- Interval sessions inherit permissions from running_sessions
CREATE POLICY "Users can view interval sessions"
  ON interval_sessions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM running_sessions
      WHERE running_sessions.id = interval_sessions.running_session_id
        AND running_sessions.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert interval sessions"
  ON interval_sessions FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM running_sessions
      WHERE running_sessions.id = interval_sessions.running_session_id
        AND running_sessions.user_id = auth.uid()
    )
  );

-- Helper functions

-- Function to calculate pace from distance and time
CREATE OR REPLACE FUNCTION calculate_pace_per_km(distance_meters INT, duration_seconds INT)
RETURNS NUMERIC AS $$
BEGIN
  IF distance_meters <= 0 OR duration_seconds <= 0 THEN
    RETURN NULL;
  END IF;
  RETURN (duration_seconds::NUMERIC / (distance_meters::NUMERIC / 1000.0));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to get gym leaderboard for specific distance
CREATE OR REPLACE FUNCTION get_gym_running_leaderboard(
  p_gym_id UUID,
  p_session_type running_session_type,
  p_limit INT DEFAULT 10
)
RETURNS TABLE (
  user_id UUID,
  session_id UUID,
  distance_meters INT,
  duration_seconds INT,
  avg_pace_per_km NUMERIC,
  created_at TIMESTAMP,
  rank BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    rs.user_id,
    rs.id AS session_id,
    rs.distance_meters,
    rs.duration_seconds,
    rs.avg_pace_per_km,
    rs.created_at,
    ROW_NUMBER() OVER (ORDER BY rs.avg_pace_per_km ASC) AS rank
  FROM running_sessions rs
  WHERE rs.gym_id = p_gym_id
    AND rs.session_type = p_session_type
    AND rs.visibility IN ('gym', 'public')
  ORDER BY rs.avg_pace_per_km ASC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- Comments for documentation
COMMENT ON TABLE running_sessions IS 'Running performance data for HYROX athletes. Focus on metrics that matter: pace, consistency, heart rate.';
COMMENT ON TABLE interval_sessions IS 'Structured interval workout data with rep-by-rep breakdown and drop-off analysis.';
COMMENT ON COLUMN running_sessions.pace_consistency IS 'Standard deviation of pace across splits. Lower = more consistent pacing.';
COMMENT ON COLUMN running_sessions.fade_factor IS 'Percentage slower in second half vs first half. Negative = negative split (faster finish).';
COMMENT ON COLUMN interval_sessions.pace_drop_off IS 'Percentage slower on last rep vs first rep. Measures fatigue/pacing strategy.';
COMMENT ON COLUMN interval_sessions.recovery_quality IS 'Average heart rate drop during rest periods as percentage. Higher = better recovery.';

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'Migration 017: Running analytics tables created successfully';
  RAISE NOTICE 'Focus: Performance metrics for HYROX athletes';
  RAISE NOTICE 'Supported session types: long_run, intervals, threshold, time_trial_5k, time_trial_10k, recovery, easy';
END $$;
