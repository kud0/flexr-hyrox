-- ============================================================================
-- FLEXR Enhanced Onboarding - Minimal Core + Refinement
-- Migration: 008_enhanced_onboarding.sql
-- Created: December 2025
-- ============================================================================

-- PART 1: Extend users table with minimal core onboarding fields
-- ============================================================================

ALTER TABLE users
ADD COLUMN IF NOT EXISTS training_background VARCHAR(50),
ADD COLUMN IF NOT EXISTS primary_goal VARCHAR(50),
ADD COLUMN IF NOT EXISTS race_date DATE,
ADD COLUMN IF NOT EXISTS target_time_seconds INTEGER,
ADD COLUMN IF NOT EXISTS weeks_to_race INTEGER,
ADD COLUMN IF NOT EXISTS just_finished_race BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS days_per_week INTEGER DEFAULT 4,
ADD COLUMN IF NOT EXISTS sessions_per_day INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS preferred_time VARCHAR(20), -- 'morning', 'afternoon', 'evening', 'flexible'
ADD COLUMN IF NOT EXISTS equipment_location VARCHAR(50), -- 'hyrox_gym', 'crossfit_gym', 'commercial_gym', 'home_gym', 'minimal'
ADD COLUMN IF NOT EXISTS onboarding_completed_at TIMESTAMP,
ADD COLUMN IF NOT EXISTS refinement_completed_at TIMESTAMP;

-- Add indexes for common queries
CREATE INDEX IF NOT EXISTS idx_users_race_date ON users(race_date) WHERE race_date IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_users_primary_goal ON users(primary_goal);
CREATE INDEX IF NOT EXISTS idx_users_onboarding_completed ON users(onboarding_completed_at);

-- ============================================================================
-- PART 2: User Performance Benchmarks (Optional - for refinement)
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_performance_benchmarks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Running PRs (in seconds)
    running_1km_seconds DECIMAL(6,2), -- e.g., 240.50 = 4:00.5
    running_5km_seconds DECIMAL(7,2), -- e.g., 1350.00 = 22:30
    running_zone2_pace_seconds DECIMAL(6,2), -- seconds per km

    -- Strength PRs (optional, in kg)
    squat_pr_kg DECIMAL(6,2),
    deadlift_pr_kg DECIMAL(6,2),

    -- HYROX Station PRs
    skierg_1000m_seconds INTEGER,
    sled_push_50m_seconds INTEGER,
    sled_push_weight_kg DECIMAL(6,2),
    sled_pull_50m_seconds INTEGER,
    sled_pull_weight_kg DECIMAL(6,2),
    rowing_1000m_seconds INTEGER,
    wall_balls_unbroken INTEGER,
    burpee_broad_jumps_1min INTEGER,
    farmers_carry_distance_meters DECIMAL(6,2),
    farmers_carry_weight_kg DECIMAL(6,2),
    sandbag_lunges_status VARCHAR(20), -- 'not_tried', 'completed', 'struggled'

    -- Metadata
    source VARCHAR(20) DEFAULT 'user_input', -- 'user_input', 'ai_learned', 'workout_data'
    confidence_score DECIMAL(3,2) DEFAULT 0.5, -- 0.0 to 1.0 (how confident AI is in these numbers)

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_benchmarks_user ON user_performance_benchmarks(user_id);
CREATE INDEX IF NOT EXISTS idx_benchmarks_updated ON user_performance_benchmarks(updated_at DESC);

-- Trigger to update updated_at
CREATE OR REPLACE FUNCTION update_benchmarks_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_benchmarks_updated_at
    BEFORE UPDATE ON user_performance_benchmarks
    FOR EACH ROW
    EXECUTE FUNCTION update_benchmarks_updated_at();

-- ============================================================================
-- PART 3: User Equipment Access (Smart defaults)
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_equipment_access (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Location type determines smart defaults
    location_type VARCHAR(50) NOT NULL, -- 'hyrox_gym', 'crossfit_gym', 'commercial_gym', 'home_gym', 'minimal'

    -- Equipment flags (user can override defaults)
    has_skierg BOOLEAN DEFAULT false,
    has_sled BOOLEAN DEFAULT false,
    has_rower BOOLEAN DEFAULT false,
    has_wall_ball BOOLEAN DEFAULT false,
    has_sandbag BOOLEAN DEFAULT false,
    has_farmers_handles BOOLEAN DEFAULT false,
    has_barbell BOOLEAN DEFAULT false,
    has_squat_rack BOOLEAN DEFAULT false,
    has_pullup_bar BOOLEAN DEFAULT false,
    has_kettlebells BOOLEAN DEFAULT false,
    has_dumbbells BOOLEAN DEFAULT false,
    has_assault_bike BOOLEAN DEFAULT false,
    has_plyo_box BOOLEAN DEFAULT false,
    has_battle_ropes BOOLEAN DEFAULT false,
    has_trx BOOLEAN DEFAULT false,
    has_mobility_tools BOOLEAN DEFAULT false,

    -- Multiple locations support
    has_multiple_locations BOOLEAN DEFAULT false,
    secondary_location_type VARCHAR(50),

    -- Substitution preference
    substitution_preference VARCHAR(30) DEFAULT 'close_substitute', -- 'close_substitute', 'use_what_i_have', 'tell_me_to_buy'

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_equipment_user ON user_equipment_access(user_id);

-- Trigger to update updated_at
CREATE OR REPLACE FUNCTION update_equipment_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_equipment_updated_at
    BEFORE UPDATE ON user_equipment_access
    FOR EACH ROW
    EXECUTE FUNCTION update_equipment_updated_at();

-- ============================================================================
-- PART 4: User Weaknesses & Focus Areas (For refinement)
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_weaknesses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Station weaknesses (up to 3)
    weak_stations JSONB, -- Array: ['skierg', 'sled_push', 'farmers_carry']

    -- Strength ranking (ordered array from strongest to weakest)
    strength_ranking JSONB, -- Array: ['leg_strength', 'core', 'upper_push', ...]

    -- Injuries and limitations
    injuries JSONB, -- Array: ['knee_pain', 'lower_back', 'shoulder']

    -- Training style preferences (for refinement)
    training_split_preference VARCHAR(50), -- 'mixed', 'compromised_focus', 'dedicated_blocks', 'ai_decide'
    motivation_type VARCHAR(50), -- 'competition', 'self_improvement', 'health', 'challenge'

    -- Metadata
    source VARCHAR(20) DEFAULT 'user_input', -- 'user_input', 'ai_learned'

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_weaknesses_user ON user_weaknesses(user_id);

-- Trigger to update updated_at
CREATE OR REPLACE FUNCTION update_weaknesses_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_weaknesses_updated_at
    BEFORE UPDATE ON user_weaknesses
    FOR EACH ROW
    EXECUTE FUNCTION update_weaknesses_updated_at();

-- ============================================================================
-- PART 5: Workout Feedback (Post-workout learning)
-- ============================================================================

CREATE TABLE IF NOT EXISTS workout_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- RPE (Rate of Perceived Exertion) 1-10
    rpe INTEGER CHECK (rpe >= 1 AND rpe <= 10),

    -- Could do more?
    could_do_more VARCHAR(20), -- 'yes', 'maybe', 'no'

    -- Weights used (JSONB for flexibility)
    weights_used JSONB,
    -- Example: {"sled_push_kg": 220, "farmers_carry_kg": 40, "kettlebell_kg": 24}

    -- Issues (quick checkboxes)
    felt_too_easy BOOLEAN DEFAULT false,
    felt_too_hard BOOLEAN DEFAULT false,
    pace_targets_off BOOLEAN DEFAULT false,
    ran_out_of_time BOOLEAN DEFAULT false,
    equipment_issue BOOLEAN DEFAULT false,
    pain_discomfort BOOLEAN DEFAULT false,
    pain_location VARCHAR(100),

    -- Free text notes
    notes TEXT,

    -- AI learning from this feedback
    ai_adjustments_made JSONB, -- What AI changed based on this feedback

    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_feedback_workout ON workout_feedback(workout_id);
CREATE INDEX IF NOT EXISTS idx_feedback_user ON workout_feedback(user_id);
CREATE INDEX IF NOT EXISTS idx_feedback_created ON workout_feedback(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_feedback_rpe ON workout_feedback(rpe);

-- ============================================================================
-- PART 6: Smart Defaults Function
-- ============================================================================

-- Function to apply smart equipment defaults based on location type
CREATE OR REPLACE FUNCTION apply_equipment_defaults(location VARCHAR, equipment_row user_equipment_access)
RETURNS user_equipment_access AS $$
BEGIN
    CASE location
        WHEN 'hyrox_gym' THEN
            equipment_row.has_skierg := true;
            equipment_row.has_sled := true;
            equipment_row.has_rower := true;
            equipment_row.has_wall_ball := true;
            equipment_row.has_sandbag := true;
            equipment_row.has_farmers_handles := true;
            equipment_row.has_barbell := true;
            equipment_row.has_squat_rack := true;
            equipment_row.has_pullup_bar := true;
            equipment_row.has_kettlebells := true;
            equipment_row.has_dumbbells := true;
            equipment_row.has_assault_bike := true;
            equipment_row.has_plyo_box := true;

        WHEN 'crossfit_gym' THEN
            equipment_row.has_skierg := true;
            equipment_row.has_sled := false; -- Maybe not
            equipment_row.has_rower := true;
            equipment_row.has_wall_ball := true;
            equipment_row.has_sandbag := true;
            equipment_row.has_farmers_handles := true;
            equipment_row.has_barbell := true;
            equipment_row.has_squat_rack := true;
            equipment_row.has_pullup_bar := true;
            equipment_row.has_kettlebells := true;
            equipment_row.has_dumbbells := true;
            equipment_row.has_assault_bike := true;
            equipment_row.has_plyo_box := true;
            equipment_row.has_battle_ropes := true;
            equipment_row.has_trx := true;

        WHEN 'commercial_gym' THEN
            equipment_row.has_skierg := false;
            equipment_row.has_sled := false;
            equipment_row.has_rower := true;
            equipment_row.has_wall_ball := false;
            equipment_row.has_sandbag := false;
            equipment_row.has_farmers_handles := false;
            equipment_row.has_barbell := true;
            equipment_row.has_squat_rack := true;
            equipment_row.has_pullup_bar := true;
            equipment_row.has_kettlebells := true;
            equipment_row.has_dumbbells := true;
            equipment_row.has_assault_bike := false;
            equipment_row.has_plyo_box := false;

        WHEN 'home_gym' THEN
            -- Nothing auto-checked, user selects
            NULL;

        WHEN 'minimal' THEN
            -- Outdoor/bodyweight only
            equipment_row.has_pullup_bar := false; -- Might have outdoor
            equipment_row.has_mobility_tools := true;

        ELSE
            NULL;
    END CASE;

    RETURN equipment_row;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- PART 7: Helper Views for Common Queries
-- ============================================================================

-- Complete user profile view (for AI plan generation)
-- COMMENTED OUT - Will create after verifying users table schema
-- Uncomment and adjust column names based on your actual users table

/*
CREATE OR REPLACE VIEW user_complete_profile AS
SELECT
    u.id,
    u.apple_user_id,
    u.email,
    -- u.first_name,  -- Verify this column exists
    -- u.last_name,   -- Verify this column exists
    u.fitness_level,
    u.age,
    u.gender,
    u.weight_kg,
    u.height_cm,
    u.training_background,
    u.primary_goal,
    u.race_date,
    u.target_time_seconds,
    u.weeks_to_race,
    u.just_finished_race,
    u.days_per_week,
    u.sessions_per_day,
    u.preferred_time,
    u.equipment_location,
    u.onboarding_completed_at,
    u.refinement_completed_at,
    b.running_1km_seconds,
    b.running_5km_seconds,
    b.running_zone2_pace_seconds,
    b.squat_pr_kg,
    b.deadlift_pr_kg,
    b.skierg_1000m_seconds,
    b.sled_push_50m_seconds,
    b.sled_push_weight_kg,
    b.sled_pull_50m_seconds,
    b.sled_pull_weight_kg,
    b.rowing_1000m_seconds,
    b.wall_balls_unbroken,
    b.burpee_broad_jumps_1min,
    b.farmers_carry_distance_meters,
    b.farmers_carry_weight_kg,
    b.confidence_score as benchmarks_confidence,
    e.location_type as equipment_location_type,
    e.has_skierg,
    e.has_sled,
    e.has_rower,
    e.has_barbell,
    e.substitution_preference,
    w.weak_stations,
    w.strength_ranking,
    w.injuries,
    w.training_split_preference,
    w.motivation_type,
    u.created_at,
    u.updated_at
FROM users u
LEFT JOIN user_performance_benchmarks b ON u.id = b.user_id
LEFT JOIN user_equipment_access e ON u.id = e.user_id
LEFT JOIN user_weaknesses w ON u.id = w.user_id;
*/

-- ============================================================================
-- PART 8: Sample Data (Development Only - Remove in Production)
-- ============================================================================

-- This would be removed in production, just for testing
COMMENT ON TABLE user_performance_benchmarks IS 'Stores user PRs and performance benchmarks for personalized training';
COMMENT ON TABLE user_equipment_access IS 'Tracks equipment availability with smart defaults based on gym type';
COMMENT ON TABLE user_weaknesses IS 'User-identified weaknesses and training preferences for focused improvement';
COMMENT ON TABLE workout_feedback IS 'Post-workout feedback for AI learning and plan adaptation';

-- ============================================================================
-- Migration Complete
-- ============================================================================

-- Add migration record (commented out - uncomment if you have schema_migrations table)
-- INSERT INTO schema_migrations (version, name, applied_at)
-- VALUES (8, '008_enhanced_onboarding', NOW())
-- ON CONFLICT (version) DO NOTHING;
