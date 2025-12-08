-- Migration: Fix workout and workout_segments schema to match edge function expectations
-- This migration adds missing columns and updates constraints for proper workout generation

-- ============================================================================
-- 1. FIX WORKOUTS TABLE
-- ============================================================================

-- Add missing columns that edge function expects
ALTER TABLE workouts
ADD COLUMN IF NOT EXISTS name TEXT,
ADD COLUMN IF NOT EXISTS workout_type TEXT,
ADD COLUMN IF NOT EXISTS estimated_duration_minutes INTEGER;

-- Copy existing data from old columns to new columns (only if columns exist)
-- Use DO block to handle missing columns gracefully
DO $$
BEGIN
    -- Try to copy title to name if title column exists
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'workouts' AND column_name = 'title') THEN
        UPDATE workouts SET name = title WHERE name IS NULL AND title IS NOT NULL;
        ALTER TABLE workouts ALTER COLUMN title DROP NOT NULL;
    END IF;

    -- Copy type to workout_type
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'workouts' AND column_name = 'type') THEN
        UPDATE workouts SET workout_type = type WHERE workout_type IS NULL AND type IS NOT NULL;
    END IF;

    -- Copy total_duration_minutes to estimated_duration_minutes
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'workouts' AND column_name = 'total_duration_minutes') THEN
        UPDATE workouts SET estimated_duration_minutes = total_duration_minutes WHERE estimated_duration_minutes IS NULL AND total_duration_minutes IS NOT NULL;
    END IF;
END $$;

-- Update type constraint to include all workout types (only if type column exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'workouts' AND column_name = 'type') THEN
        ALTER TABLE workouts DROP CONSTRAINT IF EXISTS workouts_type_check;
        ALTER TABLE workouts ADD CONSTRAINT workouts_type_check
        CHECK (type IS NULL OR type IN ('strength', 'running', 'hybrid', 'recovery', 'race_sim', 'full_simulation', 'half_simulation', 'station_focus', 'functional', 'interval', 'custom', 'compromised_running', 'warmup', 'cooldown'));
    END IF;
END $$;

-- Add workout_type constraint with all types
ALTER TABLE workouts DROP CONSTRAINT IF EXISTS workouts_workout_type_check;
ALTER TABLE workouts ADD CONSTRAINT workouts_workout_type_check
CHECK (workout_type IS NULL OR workout_type IN ('strength', 'running', 'hybrid', 'recovery', 'race_sim', 'full_simulation', 'half_simulation', 'station_focus', 'functional', 'interval', 'custom', 'compromised_running', 'warmup', 'cooldown', 'ai_generated'));

-- Update status constraint to include 'planned' and 'cancelled'
ALTER TABLE workouts DROP CONSTRAINT IF EXISTS workouts_status_check;
ALTER TABLE workouts ADD CONSTRAINT workouts_status_check
CHECK (status IS NULL OR status IN ('scheduled', 'planned', 'in_progress', 'paused', 'completed', 'skipped', 'cancelled'));

-- Make difficulty nullable (edge function may not always provide it)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'workouts' AND column_name = 'difficulty') THEN
        ALTER TABLE workouts ALTER COLUMN difficulty DROP NOT NULL;
        ALTER TABLE workouts DROP CONSTRAINT IF EXISTS workouts_difficulty_check;
        ALTER TABLE workouts ADD CONSTRAINT workouts_difficulty_check
        CHECK (difficulty IS NULL OR difficulty IN ('easy', 'moderate', 'hard', 'very_hard'));
    END IF;
END $$;

-- ============================================================================
-- 2. FIX WORKOUT_SEGMENTS TABLE
-- ============================================================================

-- Add segment_type column (edge function uses this instead of type)
ALTER TABLE workout_segments
ADD COLUMN IF NOT EXISTS segment_type TEXT;

-- Add target columns that edge function expects
ALTER TABLE workout_segments
ADD COLUMN IF NOT EXISTS target_duration_seconds INTEGER,
ADD COLUMN IF NOT EXISTS target_distance_meters DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS target_reps INTEGER,
ADD COLUMN IF NOT EXISTS station_type TEXT,
ADD COLUMN IF NOT EXISTS notes TEXT;

-- Add actual tracking columns
ALTER TABLE workout_segments
ADD COLUMN IF NOT EXISTS actual_duration_seconds INTEGER,
ADD COLUMN IF NOT EXISTS actual_distance_meters DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS actual_reps INTEGER;

-- Add heart rate columns
ALTER TABLE workout_segments
ADD COLUMN IF NOT EXISTS avg_heart_rate DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS max_heart_rate DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS heart_rate_zones JSONB;

-- Add running data columns
ALTER TABLE workout_segments
ADD COLUMN IF NOT EXISTS avg_pace DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS max_pace DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS min_pace DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS target_pace TEXT,
ADD COLUMN IF NOT EXISTS is_compromised BOOLEAN,
ADD COLUMN IF NOT EXISTS previous_station TEXT,
ADD COLUMN IF NOT EXISTS transition_time DOUBLE PRECISION;

-- Add timestamp columns
ALTER TABLE workout_segments
ADD COLUMN IF NOT EXISTS start_time TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS end_time TIMESTAMPTZ;

-- Copy data from old columns to new columns (only if columns exist)
DO $$
BEGIN
    -- Copy type to segment_type
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'workout_segments' AND column_name = 'type') THEN
        UPDATE workout_segments SET segment_type = type WHERE segment_type IS NULL AND type IS NOT NULL;
        -- Make type nullable
        ALTER TABLE workout_segments ALTER COLUMN type DROP NOT NULL;
    END IF;

    -- Copy instructions to notes
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'workout_segments' AND column_name = 'instructions') THEN
        UPDATE workout_segments SET notes = instructions WHERE notes IS NULL AND instructions IS NOT NULL;
    END IF;

    -- Make name nullable if it exists
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'workout_segments' AND column_name = 'name') THEN
        ALTER TABLE workout_segments ALTER COLUMN name DROP NOT NULL;
    END IF;
END $$;

-- Update segment type constraint to include all types (only if type column exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'workout_segments' AND column_name = 'type') THEN
        ALTER TABLE workout_segments DROP CONSTRAINT IF EXISTS workout_segments_type_check;
        ALTER TABLE workout_segments ADD CONSTRAINT workout_segments_type_check
        CHECK (type IS NULL OR type IN ('warmup', 'strength', 'cardio', 'hybrid', 'cooldown', 'run', 'station', 'transition', 'rest', 'finisher'));
    END IF;
END $$;

-- Add segment_type constraint with all types edge function uses
ALTER TABLE workout_segments DROP CONSTRAINT IF EXISTS workout_segments_segment_type_check;
ALTER TABLE workout_segments ADD CONSTRAINT workout_segments_segment_type_check
CHECK (segment_type IS NULL OR segment_type IN ('run', 'station', 'transition', 'rest', 'warmup', 'cooldown', 'strength', 'finisher'));

-- Add station_type constraint for HYROX stations
ALTER TABLE workout_segments DROP CONSTRAINT IF EXISTS workout_segments_station_type_check;
ALTER TABLE workout_segments ADD CONSTRAINT workout_segments_station_type_check
CHECK (station_type IS NULL OR station_type IN ('ski_erg', 'sled_push', 'sled_pull', 'burpee_broad_jump', 'rowing', 'farmers_carry', 'sandbag_lunges', 'wall_balls'));

-- ============================================================================
-- 3. CREATE INDEXES FOR PERFORMANCE
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_workouts_workout_type ON workouts(workout_type);
CREATE INDEX IF NOT EXISTS idx_workouts_name ON workouts(name);
CREATE INDEX IF NOT EXISTS idx_workout_segments_segment_type ON workout_segments(segment_type);
CREATE INDEX IF NOT EXISTS idx_workout_segments_station_type ON workout_segments(station_type);

-- ============================================================================
-- 4. ADD COMMENTS FOR DOCUMENTATION
-- ============================================================================

COMMENT ON COLUMN workouts.name IS 'Workout name (e.g., "Squat Day + EMOM")';
COMMENT ON COLUMN workouts.workout_type IS 'Type of workout for filtering and display';
COMMENT ON COLUMN workouts.estimated_duration_minutes IS 'Estimated workout duration in minutes';

COMMENT ON COLUMN workout_segments.segment_type IS 'Type of segment: run, station, transition, rest, warmup, cooldown, strength, finisher';
COMMENT ON COLUMN workout_segments.station_type IS 'HYROX station type if applicable';
COMMENT ON COLUMN workout_segments.target_duration_seconds IS 'Target duration in seconds';
COMMENT ON COLUMN workout_segments.target_distance_meters IS 'Target distance in meters';
COMMENT ON COLUMN workout_segments.target_reps IS 'Target number of repetitions';
COMMENT ON COLUMN workout_segments.is_compromised IS 'Whether this is a compromised run (after a station)';

-- Verify migration
DO $$ BEGIN RAISE NOTICE 'Migration 024_fix_workout_schema completed successfully'; END $$;
