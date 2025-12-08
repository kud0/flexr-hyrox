-- Migration: 006_planned_workout_segments.sql
-- Description: Add detailed segments to planned workouts for precise instructions

CREATE TABLE IF NOT EXISTS public.planned_workout_segments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    planned_workout_id UUID NOT NULL REFERENCES public.planned_workouts(id) ON DELETE CASCADE,
    order_index INTEGER NOT NULL,
    segment_type TEXT NOT NULL CHECK (segment_type IN ('warmup', 'main', 'cooldown', 'rest', 'transition')),

    -- What to do
    name TEXT NOT NULL,
    instructions TEXT NOT NULL,

    -- Specific targets (at least one should be set)
    target_duration_seconds INTEGER,      -- e.g., 300 for 5 minutes
    target_distance_meters INTEGER,       -- e.g., 1000 for 1km
    target_reps INTEGER,                  -- e.g., 100 for wall balls
    target_calories INTEGER,              -- e.g., 50 cal on ski erg

    -- For intervals/sets
    sets INTEGER DEFAULT 1,
    rest_between_sets_seconds INTEGER,

    -- Intensity guidance
    target_pace TEXT,                     -- e.g., "5:30/km", "2:00/500m"
    target_heart_rate_zone INTEGER CHECK (target_heart_rate_zone BETWEEN 1 AND 5),
    intensity_description TEXT,           -- e.g., "Conversational pace", "85% effort"

    -- Equipment/Station
    equipment TEXT,                       -- e.g., "Ski Erg", "Sled 100kg", "Sandbag 20kg"
    station_type TEXT,                    -- Links to HYROX station if applicable

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_pws_planned_workout_id ON public.planned_workout_segments(planned_workout_id);
CREATE INDEX idx_pws_order ON public.planned_workout_segments(planned_workout_id, order_index);

-- RLS
ALTER TABLE public.planned_workout_segments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "full_access_planned_workout_segments"
    ON public.planned_workout_segments FOR ALL
    USING (true) WITH CHECK (true);

GRANT ALL ON public.planned_workout_segments TO authenticated, service_role, anon;

-- Verify
DO $$ BEGIN RAISE NOTICE 'Created planned_workout_segments table'; END $$;
