-- Migration: 007_add_run_station_segment_types.sql
-- Description: Add 'run' and 'station' to allowed segment_type values for HYROX workouts

-- Drop the old constraint
ALTER TABLE public.planned_workout_segments
DROP CONSTRAINT IF EXISTS planned_workout_segments_segment_type_check;

-- Add new constraint with run and station types
ALTER TABLE public.planned_workout_segments
ADD CONSTRAINT planned_workout_segments_segment_type_check
CHECK (segment_type IN ('warmup', 'main', 'cooldown', 'rest', 'transition', 'run', 'station'));

-- Verify
DO $$ BEGIN RAISE NOTICE 'Updated segment_type constraint to include run and station'; END $$;
