-- Migration: 021_workout_feedback
-- Description: Add workout feedback system for AI coach personalization
-- Created: 2024-12-05

-- ============================================================================
-- WORKOUT FEEDBACK TABLE
-- Stores user's subjective feedback after each workout
-- ============================================================================

CREATE TABLE IF NOT EXISTS workout_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    workout_id UUID REFERENCES planned_workouts(id) ON DELETE CASCADE NOT NULL,

    -- Subjective feedback
    rpe_score INTEGER CHECK (rpe_score >= 1 AND rpe_score <= 10),
    mood_score INTEGER CHECK (mood_score >= 1 AND mood_score <= 5),
    tags TEXT[] DEFAULT '{}',
    free_text TEXT,

    -- Objective metrics (from HealthKit/Watch)
    actual_duration_seconds INTEGER,
    avg_heart_rate INTEGER,
    max_heart_rate INTEGER,
    calories_burned INTEGER,
    completion_percentage DECIMAL(5,2) DEFAULT 100.00,

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- One feedback per workout
    UNIQUE(workout_id)
);

-- Index for efficient queries
CREATE INDEX IF NOT EXISTS idx_workout_feedback_user_id ON workout_feedback(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_feedback_created_at ON workout_feedback(created_at DESC);

-- Updated_at trigger
CREATE TRIGGER update_workout_feedback_updated_at
    BEFORE UPDATE ON workout_feedback
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE workout_feedback ENABLE ROW LEVEL SECURITY;

-- Users can read their own feedback
CREATE POLICY "Users can read own workout feedback"
    ON workout_feedback FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own feedback
CREATE POLICY "Users can insert own workout feedback"
    ON workout_feedback FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own feedback
CREATE POLICY "Users can update own workout feedback"
    ON workout_feedback FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own feedback
CREATE POLICY "Users can delete own workout feedback"
    ON workout_feedback FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================================================
-- ADD COACH NOTE FIELDS TO PLANNED_WORKOUTS
-- ============================================================================

ALTER TABLE planned_workouts
ADD COLUMN IF NOT EXISTS coach_headline TEXT,
ADD COLUMN IF NOT EXISTS coach_explanation TEXT,
ADD COLUMN IF NOT EXISTS coach_data_points JSONB;

-- ============================================================================
-- ADD WEEK COACH NOTE TO TRAINING_WEEKS
-- ============================================================================

ALTER TABLE training_weeks
ADD COLUMN IF NOT EXISTS week_coach_note TEXT,
ADD COLUMN IF NOT EXISTS week_adjustments JSONB;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE workout_feedback IS 'User feedback after completing workouts - used for AI personalization';
COMMENT ON COLUMN workout_feedback.rpe_score IS 'Rate of Perceived Exertion (1-10)';
COMMENT ON COLUMN workout_feedback.mood_score IS 'How user felt (1-5, maps to emoji)';
COMMENT ON COLUMN workout_feedback.tags IS 'Quick feedback tags: too_easy, too_hard, low_energy, etc.';
COMMENT ON COLUMN workout_feedback.free_text IS 'Optional free-form notes from user';
COMMENT ON COLUMN planned_workouts.coach_headline IS 'Short AI coach headline for this workout';
COMMENT ON COLUMN planned_workouts.coach_explanation IS 'AI explanation of why this workout';
COMMENT ON COLUMN planned_workouts.coach_data_points IS 'Data points that drove this workout selection';
