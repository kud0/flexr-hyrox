-- Row Level Security (RLS) Policies for FLEXR Backend
-- Run this after the initial schema migration

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE training_architectures ENABLE ROW LEVEL SECURITY;
ALTER TABLE workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_segments ENABLE ROW LEVEL SECURITY;
ALTER TABLE performance_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_summaries ENABLE ROW LEVEL SECURITY;

-- Users policies
-- Users can read their own data
CREATE POLICY "Users can view own profile"
  ON users FOR SELECT
  USING (auth.uid()::text = id::text);

-- Users can update their own data
CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  USING (auth.uid()::text = id::text);

-- Users can delete their own account
CREATE POLICY "Users can delete own account"
  ON users FOR DELETE
  USING (auth.uid()::text = id::text);

-- Training architectures policies
CREATE POLICY "Users can view own training architectures"
  ON training_architectures FOR SELECT
  USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can create own training architectures"
  ON training_architectures FOR INSERT
  WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can update own training architectures"
  ON training_architectures FOR UPDATE
  USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can delete own training architectures"
  ON training_architectures FOR DELETE
  USING (auth.uid()::text = user_id::text);

-- Workouts policies
CREATE POLICY "Users can view own workouts"
  ON workouts FOR SELECT
  USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can create own workouts"
  ON workouts FOR INSERT
  WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can update own workouts"
  ON workouts FOR UPDATE
  USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can delete own workouts"
  ON workouts FOR DELETE
  USING (auth.uid()::text = user_id::text);

-- Workout segments policies
CREATE POLICY "Users can view segments of own workouts"
  ON workout_segments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM workouts
      WHERE workouts.id = workout_segments.workout_id
      AND workouts.user_id::text = auth.uid()::text
    )
  );

CREATE POLICY "Users can create segments for own workouts"
  ON workout_segments FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM workouts
      WHERE workouts.id = workout_segments.workout_id
      AND workouts.user_id::text = auth.uid()::text
    )
  );

CREATE POLICY "Users can update segments of own workouts"
  ON workout_segments FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM workouts
      WHERE workouts.id = workout_segments.workout_id
      AND workouts.user_id::text = auth.uid()::text
    )
  );

CREATE POLICY "Users can delete segments of own workouts"
  ON workout_segments FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM workouts
      WHERE workouts.id = workout_segments.workout_id
      AND workouts.user_id::text = auth.uid()::text
    )
  );

-- Performance profiles policies
CREATE POLICY "Users can view own performance profiles"
  ON performance_profiles FOR SELECT
  USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can create own performance profiles"
  ON performance_profiles FOR INSERT
  WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can update own performance profiles"
  ON performance_profiles FOR UPDATE
  USING (auth.uid()::text = user_id::text);

-- Weekly summaries policies
CREATE POLICY "Users can view own weekly summaries"
  ON weekly_summaries FOR SELECT
  USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can create own weekly summaries"
  ON weekly_summaries FOR INSERT
  WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can update own weekly summaries"
  ON weekly_summaries FOR UPDATE
  USING (auth.uid()::text = user_id::text);

-- Note: Service role key bypasses RLS, so backend can manage all data
-- Anon key respects RLS, useful for future client-side operations
