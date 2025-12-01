-- FLEXR Backend Initial Schema for Supabase
-- Run this migration in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  apple_user_id TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE,
  first_name TEXT,
  last_name TEXT,
  fitness_level TEXT DEFAULT 'intermediate' CHECK (fitness_level IN ('beginner', 'intermediate', 'advanced', 'elite')),
  age INTEGER,
  gender TEXT CHECK (gender IN ('male', 'female', 'other')),
  weight_kg NUMERIC(5, 2),
  height_cm NUMERIC(5, 2),
  goals JSONB DEFAULT '[]'::jsonb,
  injuries JSONB DEFAULT '[]'::jsonb,
  time_zone TEXT DEFAULT 'UTC',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_login_at TIMESTAMPTZ
);

-- Training architectures table
CREATE TABLE IF NOT EXISTS training_architectures (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  weeks_to_race INTEGER NOT NULL,
  race_date DATE,
  workouts_per_week INTEGER NOT NULL DEFAULT 4,
  weekly_structure JSONB NOT NULL,
  focus_areas JSONB DEFAULT '[]'::jsonb,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Workouts table
CREATE TABLE IF NOT EXISTS workouts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  architecture_id UUID REFERENCES training_architectures(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  type TEXT NOT NULL CHECK (type IN ('strength', 'running', 'hybrid', 'recovery', 'race_sim')),
  scheduled_date DATE,
  total_duration_minutes INTEGER,
  difficulty TEXT NOT NULL CHECK (difficulty IN ('easy', 'moderate', 'hard', 'very_hard')),
  readiness_score INTEGER,
  status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'skipped')),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  ai_context JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for workouts
CREATE INDEX IF NOT EXISTS idx_workouts_user_scheduled ON workouts(user_id, scheduled_date);
CREATE INDEX IF NOT EXISTS idx_workouts_user_status ON workouts(user_id, status);

-- Workout segments table
CREATE TABLE IF NOT EXISTS workout_segments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
  order_index INTEGER NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('warmup', 'strength', 'cardio', 'hybrid', 'cooldown')),
  name TEXT NOT NULL,
  instructions TEXT,
  duration_minutes INTEGER,
  sets INTEGER,
  reps INTEGER,
  distance_km NUMERIC(6, 2),
  target_pace TEXT,
  target_heart_rate TEXT,
  rest_seconds INTEGER,
  exercises JSONB,
  metadata JSONB,
  actual_distance_km NUMERIC(6, 2),
  actual_pace TEXT,
  actual_duration_minutes INTEGER,
  actual_heart_rate_avg INTEGER,
  completion_status TEXT DEFAULT 'not_started' CHECK (completion_status IN ('not_started', 'completed', 'partial', 'skipped')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for workout segments
CREATE INDEX IF NOT EXISTS idx_workout_segments_workout ON workout_segments(workout_id, order_index);

-- Performance profiles table (AI learning)
CREATE TABLE IF NOT EXISTS performance_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  week_starting DATE NOT NULL,
  avg_pace_km NUMERIC(4, 2),
  total_running_distance_km INTEGER,
  compromised_running_count INTEGER DEFAULT 0,
  strength_sessions_completed INTEGER,
  strength_progression JSONB,
  avg_readiness_score NUMERIC(3, 1),
  recovery_sessions_completed INTEGER,
  running_confidence NUMERIC(3, 2) DEFAULT 0.5,
  strength_confidence NUMERIC(3, 2) DEFAULT 0.5,
  endurance_confidence NUMERIC(3, 2) DEFAULT 0.5,
  workout_completion_rate JSONB,
  ai_adjustments JSONB,
  version INTEGER DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, week_starting)
);

-- Create index for performance profiles
CREATE INDEX IF NOT EXISTS idx_performance_profiles_user_week ON performance_profiles(user_id, week_starting);

-- Weekly summaries table
CREATE TABLE IF NOT EXISTS weekly_summaries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  week_starting DATE NOT NULL,
  week_ending DATE NOT NULL,
  workouts_planned INTEGER,
  workouts_completed INTEGER,
  total_duration_minutes INTEGER,
  total_distance_km NUMERIC(6, 2),
  avg_readiness_score NUMERIC(3, 1),
  workout_breakdown JSONB,
  performance_insights JSONB,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, week_starting)
);

-- Create index for weekly summaries
CREATE INDEX IF NOT EXISTS idx_weekly_summaries_user_week ON weekly_summaries(user_id, week_starting);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Add triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_training_architectures_updated_at BEFORE UPDATE ON training_architectures FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_workouts_updated_at BEFORE UPDATE ON workouts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_workout_segments_updated_at BEFORE UPDATE ON workout_segments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_performance_profiles_updated_at BEFORE UPDATE ON performance_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_weekly_summaries_updated_at BEFORE UPDATE ON weekly_summaries FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
