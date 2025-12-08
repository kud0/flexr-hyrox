-- Migration: 005_fix_foreign_keys.sql
-- Description: Remove auth.users foreign key constraints to allow mock auth testing
-- Created: 2025-12-01

-- =====================================================
-- DROP AND RECREATE TABLES WITHOUT AUTH.USERS FK
-- =====================================================

-- Drop existing tables (cascade will handle dependencies)
DROP TABLE IF EXISTS public.planned_workouts CASCADE;
DROP TABLE IF EXISTS public.training_weeks CASCADE;
DROP TABLE IF EXISTS public.training_plans CASCADE;

-- =====================================================
-- 1. TRAINING PLANS TABLE (without auth.users FK)
-- =====================================================
CREATE TABLE public.training_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL, -- No FK constraint for mock auth compatibility
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ,
    total_weeks INTEGER NOT NULL CHECK (total_weeks > 0),
    current_week INTEGER NOT NULL DEFAULT 1 CHECK (current_week > 0),
    goal TEXT NOT NULL,
    race_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT valid_week_range CHECK (current_week <= total_weeks),
    CONSTRAINT valid_date_range CHECK (end_date IS NULL OR end_date >= start_date),
    CONSTRAINT valid_race_date CHECK (race_date IS NULL OR race_date >= start_date),
    CONSTRAINT unique_user_plan UNIQUE (user_id)
);

CREATE INDEX idx_training_plans_user_id ON public.training_plans(user_id);
CREATE INDEX idx_training_plans_start_date ON public.training_plans(start_date);

-- =====================================================
-- 2. TRAINING WEEKS TABLE (without auth.users FK)
-- =====================================================
CREATE TABLE public.training_weeks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL, -- No FK constraint for mock auth compatibility
    week_number INTEGER NOT NULL CHECK (week_number > 0),
    total_weeks INTEGER CHECK (total_weeks IS NULL OR total_weeks > 0),
    phase TEXT NOT NULL CHECK (phase IN ('base', 'build', 'peak', 'taper', 'race', 'recovery')),
    focus TEXT NOT NULL,
    start_date TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT valid_week_total CHECK (total_weeks IS NULL OR week_number <= total_weeks),
    CONSTRAINT unique_user_week_start UNIQUE (user_id, start_date)
);

CREATE INDEX idx_training_weeks_user_id ON public.training_weeks(user_id);
CREATE INDEX idx_training_weeks_start_date ON public.training_weeks(start_date);
CREATE INDEX idx_training_weeks_phase ON public.training_weeks(phase);

-- =====================================================
-- 3. PLANNED WORKOUTS TABLE (without auth.users FK)
-- =====================================================
CREATE TABLE public.planned_workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL, -- No FK constraint for mock auth compatibility
    scheduled_date TIMESTAMPTZ NOT NULL,
    session_number INTEGER NOT NULL CHECK (session_number > 0),
    workout_type TEXT NOT NULL CHECK (workout_type IN ('full_simulation', 'half_simulation', 'station_focus', 'running', 'strength', 'recovery')),
    name TEXT NOT NULL,
    description TEXT,
    estimated_duration INTEGER NOT NULL CHECK (estimated_duration > 0),
    intensity TEXT NOT NULL CHECK (intensity IN ('recovery', 'easy', 'moderate', 'hard', 'very_hard', 'max_effort')),
    ai_explanation TEXT,
    status TEXT NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'in_progress', 'completed', 'skipped')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_planned_workouts_user_id ON public.planned_workouts(user_id);
CREATE INDEX idx_planned_workouts_scheduled_date ON public.planned_workouts(scheduled_date);
CREATE INDEX idx_planned_workouts_status ON public.planned_workouts(status);
CREATE INDEX idx_planned_workouts_user_date ON public.planned_workouts(user_id, scheduled_date);

-- =====================================================
-- 4. ROW LEVEL SECURITY
-- =====================================================
ALTER TABLE public.training_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.training_weeks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.planned_workouts ENABLE ROW LEVEL SECURITY;

-- Service role bypass (edge functions use service_role)
CREATE POLICY "Service role full access training_plans"
    ON public.training_plans FOR ALL
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Service role full access training_weeks"
    ON public.training_weeks FOR ALL
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Service role full access planned_workouts"
    ON public.planned_workouts FOR ALL
    USING (true)
    WITH CHECK (true);

-- =====================================================
-- 5. TRIGGERS
-- =====================================================
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_training_plans_updated_at
    BEFORE UPDATE ON public.training_plans
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_training_weeks_updated_at
    BEFORE UPDATE ON public.training_weeks
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_planned_workouts_updated_at
    BEFORE UPDATE ON public.planned_workouts
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- =====================================================
-- 6. GRANTS
-- =====================================================
GRANT ALL ON public.training_plans TO authenticated;
GRANT ALL ON public.training_weeks TO authenticated;
GRANT ALL ON public.planned_workouts TO authenticated;
GRANT ALL ON public.training_plans TO service_role;
GRANT ALL ON public.training_weeks TO service_role;
GRANT ALL ON public.planned_workouts TO service_role;
GRANT ALL ON public.training_plans TO anon;
GRANT ALL ON public.training_weeks TO anon;
GRANT ALL ON public.planned_workouts TO anon;

-- Verify
DO $$
BEGIN
    RAISE NOTICE 'Migration 005 complete: Foreign key constraints removed for mock auth compatibility';
END $$;
