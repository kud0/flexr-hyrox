-- Migration: 018_workout_analytics.sql
-- Description: Workout analytics, PR tracking, and gym social features
-- Created: December 4, 2025

-- =====================================================
-- DESIGN DECISIONS
-- =====================================================

-- Q: Should we enhance existing workouts table or create separate analytics table?
-- A: Enhance existing table with new columns + create PR tracking table
--    Reason: Avoid duplication, keep related data together

-- Q: How to track PRs across different workout types?
-- A: Dedicated pr_records table with flexible metrics
--    Reason: Different workout types have different PR metrics (time, reps, weight, etc.)

-- Q: Should activity feed be materialized view or table?
-- A: Regular table with efficient indexes
--    Reason: Need to filter/query in real-time, not read-heavy enough for materialized view

-- =====================================================
-- 1. ENHANCE WORKOUTS TABLE
-- =====================================================

-- Add analytics columns to existing workouts table
ALTER TABLE public.workouts
ADD COLUMN IF NOT EXISTS gym_id UUID REFERENCES public.gyms(id),
ADD COLUMN IF NOT EXISTS visibility TEXT DEFAULT 'gym' CHECK (visibility IN ('private', 'friends', 'gym', 'public')),
ADD COLUMN IF NOT EXISTS is_pr BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS avg_heart_rate INTEGER CHECK (avg_heart_rate IS NULL OR (avg_heart_rate >= 40 AND avg_heart_rate <= 220)),
ADD COLUMN IF NOT EXISTS max_heart_rate INTEGER CHECK (max_heart_rate IS NULL OR (max_heart_rate >= 40 AND max_heart_rate <= 220)),
ADD COLUMN IF NOT EXISTS calories_burned INTEGER CHECK (calories_burned IS NULL OR calories_burned >= 0),
ADD COLUMN IF NOT EXISTS total_distance_meters INTEGER CHECK (total_distance_meters IS NULL OR total_distance_meters >= 0),
ADD COLUMN IF NOT EXISTS average_pace_per_km NUMERIC(6,2), -- seconds per km
ADD COLUMN IF NOT EXISTS performance_score NUMERIC(4,2), -- 0-100 score
ADD COLUMN IF NOT EXISTS notes TEXT;

-- Add indexes for analytics queries
CREATE INDEX IF NOT EXISTS idx_workouts_gym_visibility ON public.workouts(gym_id, visibility) WHERE gym_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_workouts_user_completed ON public.workouts(user_id, completed_at DESC) WHERE status = 'completed';
CREATE INDEX IF NOT EXISTS idx_workouts_pr ON public.workouts(user_id, is_pr) WHERE is_pr = true;

-- Only create type index if column exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'workouts'
        AND column_name = 'type'
    ) THEN
        CREATE INDEX IF NOT EXISTS idx_workouts_type_completed ON public.workouts("type", completed_at DESC) WHERE status = 'completed';
    END IF;
END $$;

COMMENT ON COLUMN public.workouts.gym_id IS 'Gym associated with this workout for social features';
COMMENT ON COLUMN public.workouts.visibility IS 'Who can see this workout: private, friends, gym, public';
COMMENT ON COLUMN public.workouts.is_pr IS 'Whether this workout is a personal record';
COMMENT ON COLUMN public.workouts.performance_score IS 'Overall performance score 0-100 based on metrics';

-- =====================================================
-- 2. PERSONAL RECORDS (PR) TRACKING TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.pr_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    workout_id UUID NOT NULL REFERENCES public.workouts(id) ON DELETE CASCADE,

    -- PR Category
    pr_type TEXT NOT NULL CHECK (pr_type IN (
        'fastest_time',        -- Fastest completion time for workout type
        'longest_distance',    -- Longest distance covered
        'highest_reps',        -- Most reps completed
        'heaviest_weight',     -- Heaviest weight lifted
        'best_pace',           -- Best average pace
        'highest_score'        -- Highest performance score
    )),

    -- Workout categorization
    workout_type TEXT NOT NULL,  -- Same as workouts.type
    workout_subtype TEXT,        -- e.g., "full_simulation", "5K_run", "wall_balls"

    -- PR Value
    metric_value NUMERIC(12, 4) NOT NULL,  -- The actual PR value
    metric_unit TEXT NOT NULL,             -- Unit: seconds, meters, reps, kg, score

    -- Context
    previous_pr_id UUID REFERENCES public.pr_records(id),  -- Link to previous PR
    improvement_percentage NUMERIC(6, 2),                  -- % improvement over previous

    -- Metadata
    achieved_at TIMESTAMPTZ NOT NULL,
    conditions JSONB,  -- Weather, equipment, gym, etc.
    notes TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints
    CONSTRAINT unique_user_pr_category UNIQUE (user_id, pr_type, workout_type, workout_subtype),
    CONSTRAINT valid_metric_value CHECK (metric_value > 0)
);

-- Indexes for PR queries
CREATE INDEX idx_pr_records_user_type ON public.pr_records(user_id, pr_type, workout_type);
CREATE INDEX idx_pr_records_achieved ON public.pr_records(user_id, achieved_at DESC);
CREATE INDEX idx_pr_records_workout ON public.pr_records(workout_id);

COMMENT ON TABLE public.pr_records IS 'Personal records tracking across different workout types and metrics';
COMMENT ON COLUMN public.pr_records.pr_type IS 'Type of PR: time, distance, reps, weight, pace, score';
COMMENT ON COLUMN public.pr_records.workout_subtype IS 'Specific workout variation for granular PR tracking';
COMMENT ON COLUMN public.pr_records.improvement_percentage IS 'Percentage improvement over previous PR (negative for time-based PRs)';

-- =====================================================
-- 3. GYM ACTIVITY FEED TABLE
-- =====================================================

-- Create or update gym_activity_feed table
CREATE TABLE IF NOT EXISTS public.gym_activity_feed (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gym_id UUID NOT NULL REFERENCES public.gyms(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Activity details
    activity_type TEXT NOT NULL CHECK (activity_type IN (
        'workout_completed',
        'pr_achieved',
        'challenge_joined',
        'challenge_completed',
        'milestone_reached'
    )),

    -- References
    workout_id UUID REFERENCES public.workouts(id) ON DELETE CASCADE,
    pr_id UUID REFERENCES public.pr_records(id) ON DELETE CASCADE,

    -- Display data (denormalized for performance)
    title TEXT NOT NULL,
    description TEXT,

    -- Engagement
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add columns if they don't exist (in case table was created earlier)
ALTER TABLE public.gym_activity_feed
ADD COLUMN IF NOT EXISTS running_session_id UUID REFERENCES public.running_sessions(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS metrics JSONB;

-- Drop old constraint if exists and add new one
DO $$
BEGIN
    ALTER TABLE public.gym_activity_feed DROP CONSTRAINT IF EXISTS activity_has_reference;
    ALTER TABLE public.gym_activity_feed ADD CONSTRAINT activity_has_reference CHECK (
        (activity_type = 'workout_completed' AND workout_id IS NOT NULL) OR
        (activity_type = 'pr_achieved' AND pr_id IS NOT NULL) OR
        activity_type IN ('challenge_joined', 'challenge_completed', 'milestone_reached')
    );
EXCEPTION
    WHEN OTHERS THEN NULL;
END $$;

-- Indexes for feed queries
CREATE INDEX idx_gym_feed_gym_created ON public.gym_activity_feed(gym_id, created_at DESC);
CREATE INDEX idx_gym_feed_user ON public.gym_activity_feed(user_id, created_at DESC);
CREATE INDEX idx_gym_feed_type ON public.gym_activity_feed(gym_id, activity_type, created_at DESC);

COMMENT ON TABLE public.gym_activity_feed IS 'Activity feed for gym members to see each others achievements';
COMMENT ON COLUMN public.gym_activity_feed.metrics IS 'JSON object with key metrics for display (e.g., {"time": 4523, "distance": 5000})';

-- =====================================================
-- 4. WORKOUT COMPARISONS TABLE
-- =====================================================

-- Update workout_comparisons table if it exists (from migration 014)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = 'workout_comparisons'
    ) THEN
        ALTER TABLE public.workout_comparisons
        ADD COLUMN IF NOT EXISTS performance_diff NUMERIC(6,2),
        ADD COLUMN IF NOT EXISTS segment_comparison JSONB;

        COMMENT ON COLUMN public.workout_comparisons.performance_diff IS 'Performance difference as percentage';
        COMMENT ON COLUMN public.workout_comparisons.segment_comparison IS 'Detailed comparison of each segment';
    END IF;
END $$;

-- =====================================================
-- 5. MATERIALIZED VIEW: WORKOUT STATS SUMMARY
-- =====================================================

-- Aggregated stats for quick dashboard loading
-- Skip if type column doesn't exist
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'workouts'
        AND column_name = 'type'
    ) THEN
        EXECUTE '
        CREATE MATERIALIZED VIEW IF NOT EXISTS public.workout_stats_summary AS
        SELECT
            user_id,
            DATE_TRUNC(''month'', completed_at) as month,
            "type" as workout_type,

            -- Counts
            COUNT(*) as total_workouts,
            COUNT(*) FILTER (WHERE is_pr = true) as total_prs,

            -- Time metrics
            AVG(total_duration_minutes) as avg_duration_minutes,
            MIN(total_duration_minutes) as best_time_minutes,
            SUM(total_duration_minutes) as total_training_minutes,

            -- Distance metrics
            SUM(total_distance_meters) as total_distance_meters,
            AVG(average_pace_per_km) as avg_pace_per_km,

            -- Performance metrics
            AVG(performance_score) as avg_performance_score,
            AVG(avg_heart_rate) as avg_heart_rate,

            -- Latest workout
            MAX(completed_at) as last_workout_at

        FROM public.workouts
        WHERE status = ''completed''
          AND completed_at IS NOT NULL
        GROUP BY user_id, DATE_TRUNC(''month'', completed_at), "type"
        ';
    END IF;
END $$;

-- Index for fast queries (only if view exists)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_matviews
        WHERE schemaname = 'public'
        AND matviewname = 'workout_stats_summary'
    ) THEN
        CREATE INDEX IF NOT EXISTS idx_workout_stats_user_month ON public.workout_stats_summary(user_id, month DESC);
        CREATE INDEX IF NOT EXISTS idx_workout_stats_type ON public.workout_stats_summary(workout_type, month DESC);
    END IF;
END $$;

-- Comment on view only if it exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_matviews
        WHERE schemaname = 'public'
        AND matviewname = 'workout_stats_summary'
    ) THEN
        COMMENT ON MATERIALIZED VIEW public.workout_stats_summary IS 'Pre-aggregated workout statistics for dashboard performance';
    END IF;
END $$;

-- =====================================================
-- 6. HELPER FUNCTIONS
-- =====================================================

-- Function to check if workout is a PR
CREATE OR REPLACE FUNCTION public.check_and_create_pr(
    p_workout_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
    v_workout RECORD;
    v_existing_pr RECORD;
    v_is_pr BOOLEAN := false;
    v_improvement NUMERIC;
BEGIN
    -- Get workout details
    SELECT * INTO v_workout
    FROM public.workouts
    WHERE id = p_workout_id;

    -- Check for time-based PR (fastest time)
    IF v_workout.total_duration_minutes IS NOT NULL THEN
        SELECT * INTO v_existing_pr
        FROM public.pr_records
        WHERE user_id = v_workout.user_id
          AND pr_type = 'fastest_time'
          AND workout_type = v_workout."type"
        ORDER BY metric_value ASC
        LIMIT 1;

        -- If no existing PR or this is faster
        IF v_existing_pr IS NULL OR v_workout.total_duration_minutes < v_existing_pr.metric_value THEN
            v_is_pr := true;

            -- Calculate improvement
            IF v_existing_pr IS NOT NULL THEN
                v_improvement := ((v_existing_pr.metric_value - v_workout.total_duration_minutes) / v_existing_pr.metric_value) * 100;
            END IF;

            -- Create PR record
            INSERT INTO public.pr_records (
                user_id, workout_id, pr_type, workout_type,
                metric_value, metric_unit, previous_pr_id,
                improvement_percentage, achieved_at
            ) VALUES (
                v_workout.user_id, p_workout_id, 'fastest_time', v_workout."type",
                v_workout.total_duration_minutes, 'minutes', v_existing_pr.id,
                v_improvement, v_workout.completed_at
            )
            ON CONFLICT (user_id, pr_type, workout_type, workout_subtype)
            DO UPDATE SET
                workout_id = p_workout_id,
                metric_value = v_workout.total_duration_minutes,
                previous_pr_id = v_existing_pr.id,
                improvement_percentage = v_improvement,
                achieved_at = v_workout.completed_at;

            -- Update workout is_pr flag
            UPDATE public.workouts SET is_pr = true WHERE id = p_workout_id;
        END IF;
    END IF;

    RETURN v_is_pr;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.check_and_create_pr(UUID) IS 'Checks if workout is a PR and creates PR record if so';

-- Function to create activity feed item
CREATE OR REPLACE FUNCTION public.create_activity_feed_item(
    p_workout_id UUID
) RETURNS UUID AS $$
DECLARE
    v_workout RECORD;
    v_pr RECORD;
    v_feed_id UUID;
    v_title TEXT;
    v_description TEXT;
    v_metrics JSONB;
BEGIN
    -- Get workout details
    SELECT w.*, u.first_name, u.last_name
    INTO v_workout
    FROM public.workouts w
    JOIN auth.users u ON u.id = w.user_id
    WHERE w.id = p_workout_id;

    -- Only create feed items for gym workouts with appropriate visibility
    IF v_workout.gym_id IS NULL OR v_workout.visibility = 'private' THEN
        RETURN NULL;
    END IF;

    -- Build metrics JSON
    v_metrics := jsonb_build_object(
        'duration_minutes', v_workout.total_duration_minutes,
        'distance_meters', v_workout.total_distance_meters,
        'avg_heart_rate', v_workout.avg_heart_rate,
        'calories', v_workout.calories_burned
    );

    -- Check if this is a PR
    IF v_workout.is_pr THEN
        SELECT * INTO v_pr FROM public.pr_records WHERE workout_id = p_workout_id LIMIT 1;

        IF v_pr IS NOT NULL THEN
            v_title := v_workout.first_name || ' set new ' || v_workout."type" || ' PR!';
            v_description := format('Completed in %s minutes', v_workout.total_duration_minutes);
            IF v_pr.improvement_percentage IS NOT NULL THEN
                v_description := v_description || format(' (%.1f%% improvement)', v_pr.improvement_percentage);
            END IF;

            INSERT INTO public.gym_activity_feed (
                gym_id, user_id, activity_type, workout_id, pr_id,
                title, description, metrics
            ) VALUES (
                v_workout.gym_id, v_workout.user_id, 'pr_achieved',
                p_workout_id, v_pr.id, v_title, v_description, v_metrics
            ) RETURNING id INTO v_feed_id;
        END IF;
    ELSE
        -- Regular workout completion
        v_title := v_workout.first_name || ' completed ' || v_workout.title;
        v_description := format('Finished in %s minutes', v_workout.total_duration_minutes);

        INSERT INTO public.gym_activity_feed (
            gym_id, user_id, activity_type, workout_id,
            title, description, metrics
        ) VALUES (
            v_workout.gym_id, v_workout.user_id, 'workout_completed',
            p_workout_id, v_title, v_description, v_metrics
        ) RETURNING id INTO v_feed_id;
    END IF;

    RETURN v_feed_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.create_activity_feed_item(UUID) IS 'Creates gym activity feed item when workout is completed';

-- =====================================================
-- 7. ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on new tables
ALTER TABLE public.pr_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gym_activity_feed ENABLE ROW LEVEL SECURITY;

-- PR Records Policies
CREATE POLICY "Users can view own PR records"
    ON public.pr_records FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own PR records"
    ON public.pr_records FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own PR records"
    ON public.pr_records FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own PR records"
    ON public.pr_records FOR DELETE
    USING (auth.uid() = user_id);

-- Gym Activity Feed Policies (only if gym_members table exists)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = 'gym_members'
    ) THEN
        -- Drop existing policies if they exist
        DROP POLICY IF EXISTS "Gym members can view gym feed" ON public.gym_activity_feed;
        DROP POLICY IF EXISTS "Users can create own feed items" ON public.gym_activity_feed;

        -- Create policies
        CREATE POLICY "Gym members can view gym feed"
            ON public.gym_activity_feed FOR SELECT
            USING (
                gym_id IN (
                    SELECT gym_id FROM public.gym_members
                    WHERE user_id = auth.uid() AND status = 'active'
                )
            );

        CREATE POLICY "Users can create own feed items"
            ON public.gym_activity_feed FOR INSERT
            WITH CHECK (auth.uid() = user_id);
    ELSE
        -- Fallback: allow all authenticated users to view and insert
        DROP POLICY IF EXISTS "Gym members can view gym feed" ON public.gym_activity_feed;
        DROP POLICY IF EXISTS "Users can create own feed items" ON public.gym_activity_feed;

        CREATE POLICY "Authenticated users can view feed"
            ON public.gym_activity_feed FOR SELECT
            USING (auth.uid() IS NOT NULL);

        CREATE POLICY "Users can create own feed items"
            ON public.gym_activity_feed FOR INSERT
            WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

-- =====================================================
-- 8. GRANTS
-- =====================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON public.pr_records TO authenticated;
GRANT SELECT, INSERT ON public.gym_activity_feed TO authenticated;

-- Grant on view only if it exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_matviews
        WHERE schemaname = 'public'
        AND matviewname = 'workout_stats_summary'
    ) THEN
        GRANT SELECT ON public.workout_stats_summary TO authenticated;
    END IF;
END $$;

-- =====================================================
-- 9. REFRESH FUNCTION FOR MATERIALIZED VIEW
-- =====================================================

-- Refresh function only if view exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_matviews
        WHERE schemaname = 'public'
        AND matviewname = 'workout_stats_summary'
    ) THEN
        CREATE OR REPLACE FUNCTION public.refresh_workout_stats()
        RETURNS void AS $func$
        BEGIN
            REFRESH MATERIALIZED VIEW CONCURRENTLY public.workout_stats_summary;
        END;
        $func$ LANGUAGE plpgsql SECURITY DEFINER;

        COMMENT ON FUNCTION public.refresh_workout_stats() IS 'Refreshes workout statistics materialized view';
    END IF;
END $$;

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE 'Migration 018_workout_analytics.sql completed successfully';
    RAISE NOTICE 'Added columns to workouts table for analytics';
    RAISE NOTICE 'Created pr_records table for personal record tracking';
    RAISE NOTICE 'Created gym_activity_feed table for social features';
    RAISE NOTICE 'Created workout_stats_summary materialized view';
    RAISE NOTICE 'Added helper functions for PR checking and feed creation';
    RAISE NOTICE 'RLS policies configured for security';
END $$;
