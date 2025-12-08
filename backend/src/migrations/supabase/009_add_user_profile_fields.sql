-- ============================================================================
-- FLEXR User Profile Fields
-- Migration: 009_add_user_profile_fields.sql
-- Created: December 2025
-- Purpose: Add basic profile fields (age, weight, height, gender) to users table
-- ============================================================================

-- Add basic profile fields to users table
ALTER TABLE users
ADD COLUMN IF NOT EXISTS age INTEGER CHECK (age >= 10 AND age <= 120),
ADD COLUMN IF NOT EXISTS weight_kg DECIMAL(5,2) CHECK (weight_kg >= 20 AND weight_kg <= 300),
ADD COLUMN IF NOT EXISTS height_cm DECIMAL(5,2) CHECK (height_cm >= 100 AND height_cm <= 250),
ADD COLUMN IF NOT EXISTS gender VARCHAR(20) DEFAULT 'male';

-- Add previous HYROX race history fields
ALTER TABLE users
ADD COLUMN IF NOT EXISTS has_completed_hyrox_before BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS number_of_hyrox_races INTEGER,
ADD COLUMN IF NOT EXISTS best_hyrox_time_seconds INTEGER,
ADD COLUMN IF NOT EXISTS best_hyrox_division VARCHAR(50),
ADD COLUMN IF NOT EXISTS fitness_level VARCHAR(50);

-- Add workout preferences
ALTER TABLE users
ADD COLUMN IF NOT EXISTS preferred_workout_duration_minutes INTEGER,
ADD COLUMN IF NOT EXISTS preferred_workout_types JSONB;

-- Add device setup
ALTER TABLE users
ADD COLUMN IF NOT EXISTS has_apple_watch BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS healthkit_enabled BOOLEAN DEFAULT false;

-- Add indexes for common queries
CREATE INDEX IF NOT EXISTS idx_users_age ON users(age);
CREATE INDEX IF NOT EXISTS idx_users_gender ON users(gender);
CREATE INDEX IF NOT EXISTS idx_users_fitness_level ON users(fitness_level);
CREATE INDEX IF NOT EXISTS idx_users_has_watch ON users(has_apple_watch);

-- ============================================================================
-- Migration Complete
-- ============================================================================

COMMENT ON COLUMN users.age IS 'User age in years';
COMMENT ON COLUMN users.weight_kg IS 'User weight in kilograms';
COMMENT ON COLUMN users.height_cm IS 'User height in centimeters';
COMMENT ON COLUMN users.gender IS 'User gender: male, female, other';
COMMENT ON COLUMN users.has_completed_hyrox_before IS 'Whether user has completed HYROX races before';
COMMENT ON COLUMN users.number_of_hyrox_races IS 'Number of HYROX races completed';
COMMENT ON COLUMN users.best_hyrox_time_seconds IS 'Best HYROX finishing time in seconds';
COMMENT ON COLUMN users.best_hyrox_division IS 'Division of best HYROX race: men_open, women_open, men_pro, women_pro, doubles, relay';
