-- Migration: 007_add_watch_name.sql
-- Description: Add watch_name column for short Apple Watch display names
-- Created: 2025-12-02

-- Add watch_name column to planned_workouts
-- Max 12 characters for Watch display
ALTER TABLE public.planned_workouts
ADD COLUMN IF NOT EXISTS watch_name VARCHAR(12);

-- Comment
COMMENT ON COLUMN public.planned_workouts.watch_name IS 'Short name (max 12 chars) for Apple Watch display';

-- Verify
DO $$
BEGIN
    RAISE NOTICE 'Migration 007_add_watch_name.sql completed';
    RAISE NOTICE 'Added watch_name column to planned_workouts';
END $$;
