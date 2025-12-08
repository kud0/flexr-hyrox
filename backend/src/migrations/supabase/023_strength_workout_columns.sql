-- Add columns for gym-based strength workouts to workout_segments table
-- These support the new strength workout type with exercises like Squats, Bench Press, etc.

ALTER TABLE workout_segments
ADD COLUMN IF NOT EXISTS exercise_name TEXT,
ADD COLUMN IF NOT EXISTS sets INTEGER,
ADD COLUMN IF NOT EXISTS reps_per_set INTEGER,
ADD COLUMN IF NOT EXISTS weight_suggestion TEXT;

-- Add comment for documentation
COMMENT ON COLUMN workout_segments.exercise_name IS 'Name of the exercise for strength workouts (e.g., Barbell Back Squat)';
COMMENT ON COLUMN workout_segments.sets IS 'Number of sets for strength exercises';
COMMENT ON COLUMN workout_segments.reps_per_set IS 'Number of reps per set for strength exercises';
COMMENT ON COLUMN workout_segments.weight_suggestion IS 'Weight guidance (e.g., 75% 1RM, RPE 7-8)';
