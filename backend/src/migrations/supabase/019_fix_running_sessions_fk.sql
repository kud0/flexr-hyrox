-- Migration: 019_fix_running_sessions_fk.sql
-- Description: Fix foreign key constraint in running_sessions table
-- Fixes: Migration 017 referenced wrong table name (workout_sessions instead of workouts)

-- Drop the incorrect foreign key constraint
ALTER TABLE public.running_sessions
DROP CONSTRAINT IF EXISTS running_sessions_workout_id_fkey;

-- Add the correct foreign key constraint
ALTER TABLE public.running_sessions
ADD CONSTRAINT running_sessions_workout_id_fkey
  FOREIGN KEY (workout_id)
  REFERENCES public.workouts(id)
  ON DELETE SET NULL;

-- Verify
DO $$
BEGIN
    RAISE NOTICE 'Fixed running_sessions foreign key constraint';
END $$;
