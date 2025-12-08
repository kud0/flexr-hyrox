-- Migration: Add sections metadata support for workout UI grouping
-- This enables proper display of workout sections (warm-up, strength, WOD, finisher, cooldown)
-- with format information (EMOM, AMRAP, Tabata, etc.)

-- Add sections_metadata JSON field to workouts table
ALTER TABLE workouts
ADD COLUMN IF NOT EXISTS sections_metadata JSONB DEFAULT NULL;

-- Add section fields to workout_segments table for grouping
ALTER TABLE workout_segments
ADD COLUMN IF NOT EXISTS section_type TEXT DEFAULT NULL,
ADD COLUMN IF NOT EXISTS section_label TEXT DEFAULT NULL,
ADD COLUMN IF NOT EXISTS section_format TEXT DEFAULT NULL,
ADD COLUMN IF NOT EXISTS section_format_details JSONB DEFAULT NULL;

-- Add check constraint for valid section types
ALTER TABLE workout_segments
DROP CONSTRAINT IF EXISTS workout_segments_section_type_check;

ALTER TABLE workout_segments
ADD CONSTRAINT workout_segments_section_type_check
CHECK (section_type IS NULL OR section_type IN ('warmup', 'strength', 'wod', 'finisher', 'cooldown'));

-- Add check constraint for valid section formats
ALTER TABLE workout_segments
DROP CONSTRAINT IF EXISTS workout_segments_section_format_check;

ALTER TABLE workout_segments
ADD CONSTRAINT workout_segments_section_format_check
CHECK (section_format IS NULL OR section_format IN ('emom', 'amrap', 'for_time', 'tabata', 'rounds'));

-- Create index for efficient section-based queries
CREATE INDEX IF NOT EXISTS idx_workout_segments_section_type
ON workout_segments(workout_id, section_type);

-- Comment on new columns
COMMENT ON COLUMN workouts.sections_metadata IS 'JSON array of section metadata for UI grouping: [{type, label, format, format_details, segment_count}]';
COMMENT ON COLUMN workout_segments.section_type IS 'Section this segment belongs to: warmup, strength, wod, finisher, cooldown';
COMMENT ON COLUMN workout_segments.section_label IS 'Display label for the section (e.g., "WARM-UP", "WOD")';
COMMENT ON COLUMN workout_segments.section_format IS 'WOD format: emom, amrap, for_time, tabata, rounds';
COMMENT ON COLUMN workout_segments.section_format_details IS 'Format-specific details: {total_minutes, rounds, work_seconds, rest_seconds, etc.}';
