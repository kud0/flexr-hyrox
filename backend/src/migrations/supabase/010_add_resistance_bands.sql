-- ============================================================================
-- Add missing equipment column
-- Migration: 010_add_resistance_bands.sql
-- ============================================================================

ALTER TABLE user_equipment_access
ADD COLUMN IF NOT EXISTS has_resistance_bands BOOLEAN DEFAULT false;

COMMENT ON COLUMN user_equipment_access.has_resistance_bands IS 'Whether user has access to resistance bands';
