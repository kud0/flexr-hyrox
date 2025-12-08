-- Migration: 004_training_plan_tables.sql
-- Description: Create training plan, training weeks, and planned workouts tables for FLEXR HYROX training app
-- Created: 2025-12-01

-- =====================================================
-- 1. TRAINING PLANS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.training_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ,
    total_weeks INTEGER NOT NULL CHECK (total_weeks > 0),
    current_week INTEGER NOT NULL DEFAULT 1 CHECK (current_week > 0),
    goal TEXT NOT NULL,
    race_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT valid_week_range CHECK (current_week <= total_weeks),
    CONSTRAINT valid_date_range CHECK (end_date IS NULL OR end_date >= start_date),
    CONSTRAINT valid_race_date CHECK (race_date IS NULL OR race_date >= start_date)
);

-- Indexes for training_plans
CREATE INDEX IF NOT EXISTS idx_training_plans_user_id ON public.training_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_training_plans_start_date ON public.training_plans(start_date);
CREATE INDEX IF NOT EXISTS idx_training_plans_race_date ON public.training_plans(race_date) WHERE race_date IS NOT NULL;

-- =====================================================
-- 2. TRAINING WEEKS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.training_weeks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    week_number INTEGER NOT NULL CHECK (week_number > 0),
    total_weeks INTEGER CHECK (total_weeks IS NULL OR total_weeks > 0),
    phase TEXT NOT NULL CHECK (phase IN ('base', 'build', 'peak', 'taper', 'race', 'recovery')),
    focus TEXT NOT NULL,
    start_date TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT valid_week_total CHECK (total_weeks IS NULL OR week_number <= total_weeks),
    CONSTRAINT unique_user_week_start UNIQUE (user_id, start_date)
);

-- Indexes for training_weeks
CREATE INDEX IF NOT EXISTS idx_training_weeks_user_id ON public.training_weeks(user_id);
CREATE INDEX IF NOT EXISTS idx_training_weeks_start_date ON public.training_weeks(start_date);
CREATE INDEX IF NOT EXISTS idx_training_weeks_week_number ON public.training_weeks(week_number);
CREATE INDEX IF NOT EXISTS idx_training_weeks_phase ON public.training_weeks(phase);

-- =====================================================
-- 3. PLANNED WORKOUTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.planned_workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    scheduled_date TIMESTAMPTZ NOT NULL,
    session_number INTEGER NOT NULL CHECK (session_number > 0),
    workout_type TEXT NOT NULL CHECK (workout_type IN ('full_simulation', 'half_simulation', 'station_focus', 'running', 'strength', 'recovery')),
    name TEXT NOT NULL,
    description TEXT,
    estimated_duration INTEGER NOT NULL CHECK (estimated_duration > 0), -- in minutes
    intensity TEXT NOT NULL CHECK (intensity IN ('recovery', 'easy', 'moderate', 'hard', 'very_hard', 'max_effort')),
    ai_explanation TEXT,
    status TEXT NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'in_progress', 'completed', 'skipped')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for planned_workouts
CREATE INDEX IF NOT EXISTS idx_planned_workouts_user_id ON public.planned_workouts(user_id);
CREATE INDEX IF NOT EXISTS idx_planned_workouts_scheduled_date ON public.planned_workouts(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_planned_workouts_status ON public.planned_workouts(status);
CREATE INDEX IF NOT EXISTS idx_planned_workouts_workout_type ON public.planned_workouts(workout_type);
CREATE INDEX IF NOT EXISTS idx_planned_workouts_user_date ON public.planned_workouts(user_id, scheduled_date);

-- =====================================================
-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE public.training_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.training_weeks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.planned_workouts ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 4.1 Training Plans RLS Policies
-- =====================================================

-- Policy: Users can view their own training plans
CREATE POLICY "Users can view own training plans"
    ON public.training_plans
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy: Users can insert their own training plans
CREATE POLICY "Users can insert own training plans"
    ON public.training_plans
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own training plans
CREATE POLICY "Users can update own training plans"
    ON public.training_plans
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own training plans
CREATE POLICY "Users can delete own training plans"
    ON public.training_plans
    FOR DELETE
    USING (auth.uid() = user_id);

-- =====================================================
-- 4.2 Training Weeks RLS Policies
-- =====================================================

-- Policy: Users can view their own training weeks
CREATE POLICY "Users can view own training weeks"
    ON public.training_weeks
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy: Users can insert their own training weeks
CREATE POLICY "Users can insert own training weeks"
    ON public.training_weeks
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own training weeks
CREATE POLICY "Users can update own training weeks"
    ON public.training_weeks
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own training weeks
CREATE POLICY "Users can delete own training weeks"
    ON public.training_weeks
    FOR DELETE
    USING (auth.uid() = user_id);

-- =====================================================
-- 4.3 Planned Workouts RLS Policies
-- =====================================================

-- Policy: Users can view their own planned workouts
CREATE POLICY "Users can view own planned workouts"
    ON public.planned_workouts
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy: Users can insert their own planned workouts
CREATE POLICY "Users can insert own planned workouts"
    ON public.planned_workouts
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own planned workouts
CREATE POLICY "Users can update own planned workouts"
    ON public.planned_workouts
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own planned workouts
CREATE POLICY "Users can delete own planned workouts"
    ON public.planned_workouts
    FOR DELETE
    USING (auth.uid() = user_id);

-- =====================================================
-- 5. TRIGGER FUNCTIONS FOR UPDATED_AT
-- =====================================================

-- Create or replace the updated_at trigger function if it doesn't exist
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for training_plans
DROP TRIGGER IF EXISTS update_training_plans_updated_at ON public.training_plans;
CREATE TRIGGER update_training_plans_updated_at
    BEFORE UPDATE ON public.training_plans
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Triggers for training_weeks
DROP TRIGGER IF EXISTS update_training_weeks_updated_at ON public.training_weeks;
CREATE TRIGGER update_training_weeks_updated_at
    BEFORE UPDATE ON public.training_weeks
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Triggers for planned_workouts
DROP TRIGGER IF EXISTS update_planned_workouts_updated_at ON public.planned_workouts;
CREATE TRIGGER update_planned_workouts_updated_at
    BEFORE UPDATE ON public.planned_workouts
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- =====================================================
-- 6. COMMENTS
-- =====================================================

COMMENT ON TABLE public.training_plans IS 'Stores user training plans for HYROX race preparation';
COMMENT ON TABLE public.training_weeks IS 'Stores weekly training structure and phases';
COMMENT ON TABLE public.planned_workouts IS 'Stores individual planned workout sessions';

COMMENT ON COLUMN public.training_plans.total_weeks IS 'Total number of weeks in the training plan';
COMMENT ON COLUMN public.training_plans.current_week IS 'Current active week number';
COMMENT ON COLUMN public.training_plans.goal IS 'User training goal (e.g., "Complete HYROX under 90 minutes")';
COMMENT ON COLUMN public.training_plans.race_date IS 'Target race date if applicable';

COMMENT ON COLUMN public.training_weeks.phase IS 'Training phase: base, build, peak, taper, race, recovery';
COMMENT ON COLUMN public.training_weeks.focus IS 'Main focus area for the week';

COMMENT ON COLUMN public.planned_workouts.workout_type IS 'Type of workout: full_simulation, half_simulation, station_focus, running, strength, recovery';
COMMENT ON COLUMN public.planned_workouts.estimated_duration IS 'Estimated workout duration in minutes';
COMMENT ON COLUMN public.planned_workouts.intensity IS 'Workout intensity level';
COMMENT ON COLUMN public.planned_workouts.ai_explanation IS 'AI-generated explanation of workout purpose and benefits';
COMMENT ON COLUMN public.planned_workouts.status IS 'Workout status: planned, in_progress, completed, skipped';

-- =====================================================
-- 7. GRANTS (Optional - adjust based on your setup)
-- =====================================================

-- Grant appropriate permissions to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON public.training_plans TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.training_weeks TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.planned_workouts TO authenticated;

-- Grant usage on sequences (if needed)
-- Note: gen_random_uuid() doesn't use sequences, so this might not be necessary
-- but including for completeness if you switch to SERIAL types

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================

-- Verify tables were created
DO $$
BEGIN
    RAISE NOTICE 'Migration 004_training_plan_tables.sql completed successfully';
    RAISE NOTICE 'Created tables: training_plans, training_weeks, planned_workouts';
    RAISE NOTICE 'RLS policies enabled and configured';
    RAISE NOTICE 'Indexes created for optimal query performance';
END $$;
