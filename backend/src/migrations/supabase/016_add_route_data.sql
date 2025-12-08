-- Migration 016: Add GPS Route Tracking to Workouts Table
-- Description: Adds route_data, gps_source, and elevation fields for GPS-tracked workouts
-- Date: 2025-12-04

-- Add route tracking columns to workouts table
ALTER TABLE workouts
  ADD COLUMN IF NOT EXISTS route_data JSONB,
  ADD COLUMN IF NOT EXISTS gps_source TEXT CHECK (gps_source IN ('watch', 'iphone')),
  ADD COLUMN IF NOT EXISTS elevation_gain DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS elevation_loss DOUBLE PRECISION;

-- Create index for efficient querying of workouts with routes
CREATE INDEX IF NOT EXISTS idx_workouts_route_data
  ON workouts ((route_data IS NOT NULL))
  WHERE route_data IS NOT NULL;

-- Create index for GPS source queries
CREATE INDEX IF NOT EXISTS idx_workouts_gps_source
  ON workouts (gps_source)
  WHERE gps_source IS NOT NULL;

-- Add comments for documentation
COMMENT ON COLUMN workouts.route_data IS 'GPS route coordinates and metadata stored as JSONB';
COMMENT ON COLUMN workouts.gps_source IS 'Device that tracked GPS: watch or iphone';
COMMENT ON COLUMN workouts.elevation_gain IS 'Total elevation gain in meters';
COMMENT ON COLUMN workouts.elevation_loss IS 'Total elevation loss in meters';
