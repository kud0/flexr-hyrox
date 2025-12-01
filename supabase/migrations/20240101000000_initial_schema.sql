-- FLEXR Database Schema
-- Supabase Migration: Initial Schema

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    apple_user_id TEXT UNIQUE,
    name TEXT,
    avatar_url TEXT,

    -- Training configuration
    training_goal TEXT CHECK (training_goal IN ('train_style', 'compete_race')) DEFAULT 'train_style',
    race_date DATE,
    experience_level TEXT CHECK (experience_level IN ('beginner', 'intermediate', 'advanced', 'elite')) DEFAULT 'intermediate',

    -- User preferences
    units TEXT CHECK (units IN ('metric', 'imperial')) DEFAULT 'metric',
    notifications_enabled BOOLEAN DEFAULT true,

    -- Subscription
    subscription_tier TEXT CHECK (subscription_tier IN ('free', 'tracker', 'ai_powered')) DEFAULT 'free',
    subscription_expires_at TIMESTAMPTZ,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TRAINING ARCHITECTURES TABLE
-- User-defined training structure
-- ============================================
CREATE TABLE training_architectures (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    name TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,

    -- Structure
    days_per_week INTEGER NOT NULL CHECK (days_per_week BETWEEN 1 AND 7),
    sessions_per_day INTEGER NOT NULL CHECK (sessions_per_day BETWEEN 1 AND 3),
    session_types JSONB NOT NULL DEFAULT '[]',
    -- Example: [{"day": 1, "sessions": [{"type": "run", "time": "AM"}, {"type": "strength", "time": "PM"}]}]

    -- Preferences
    preferred_workout_duration_minutes INTEGER DEFAULT 60,
    equipment_available JSONB DEFAULT '[]',
    -- Example: ["ski_erg", "rower", "sled", "wall_balls"]

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- WORKOUTS TABLE
-- ============================================
CREATE TABLE workouts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Basic info
    name TEXT NOT NULL,
    description TEXT,
    workout_type TEXT CHECK (workout_type IN (
        'full_simulation', 'half_simulation', 'station_focus',
        'running', 'strength', 'recovery', 'intervals',
        'ai_generated', 'custom'
    )) NOT NULL,

    -- Status
    status TEXT CHECK (status IN ('planned', 'in_progress', 'paused', 'completed', 'cancelled', 'skipped')) DEFAULT 'planned',

    -- Timing
    scheduled_at TIMESTAMPTZ,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,

    -- Metrics
    estimated_duration_minutes INTEGER,
    actual_duration_minutes INTEGER,
    estimated_calories INTEGER,
    actual_calories INTEGER,

    -- Context
    readiness_score INTEGER CHECK (readiness_score BETWEEN 0 AND 100),
    difficulty TEXT CHECK (difficulty IN ('easy', 'moderate', 'hard', 'very_hard')),

    -- AI metadata
    ai_context JSONB,
    -- Example: {"prompt_summary": "...", "model": "grok-4-1-fast", "confidence": 0.85}

    -- For custom workouts (BYOP feature)
    is_custom BOOLEAN DEFAULT false,
    template_id UUID, -- Reference to custom_workout_templates if from template

    -- Feedback
    user_rating INTEGER CHECK (user_rating BETWEEN 1 AND 5),
    user_notes TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- WORKOUT SEGMENTS TABLE
-- Individual exercises within a workout
-- ============================================
CREATE TABLE workout_segments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,

    -- Segment type
    segment_type TEXT NOT NULL CHECK (segment_type IN ('run', 'station', 'transition', 'rest', 'warmup', 'cooldown')),
    station_type TEXT CHECK (station_type IN (
        'ski_erg', 'sled_push', 'sled_pull', 'burpee_broad_jump',
        'rowing', 'farmers_carry', 'sandbag_lunges', 'wall_balls'
    )),

    -- Order
    order_index INTEGER NOT NULL,

    -- Targets
    target_duration_seconds INTEGER,
    target_distance_meters INTEGER,
    target_reps INTEGER,

    -- Actuals (filled during/after workout)
    actual_duration_seconds INTEGER,
    actual_distance_meters INTEGER,
    actual_reps INTEGER,

    -- Heart rate data
    avg_heart_rate INTEGER,
    max_heart_rate INTEGER,
    min_heart_rate INTEGER,

    -- Running-specific
    avg_pace_seconds_per_km INTEGER,
    max_pace_seconds_per_km INTEGER,
    min_pace_seconds_per_km INTEGER,
    is_compromised BOOLEAN DEFAULT false,

    -- Context
    previous_station TEXT, -- For compromised run tracking
    transition_time_seconds INTEGER,

    -- Notes
    notes TEXT,

    -- Status
    status TEXT CHECK (status IN ('pending', 'in_progress', 'completed', 'skipped')) DEFAULT 'pending',
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- PERFORMANCE PROFILES TABLE
-- AI-learned user performance data
-- ============================================
CREATE TABLE performance_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Running performance
    fresh_run_pace_per_km NUMERIC(5,2), -- minutes per km (e.g., 5.30)
    compromised_run_paces JSONB DEFAULT '{}',
    -- Example: {"ski_erg": 5.85, "sled_push": 6.10, "wall_balls": 5.95}

    -- Station performance
    station_benchmarks JSONB DEFAULT '{}',
    -- Example: {"ski_erg": {"avg_duration_seconds": 240, "best": 220, "trend": "improving"}}

    -- Recovery metrics
    recovery_profile JSONB DEFAULT '{}',
    -- Example: {"avg_transition_time_seconds": 45, "hr_recovery_rate": 12}

    -- Confidence levels
    confidence_levels JSONB DEFAULT '{}',
    -- Example: {"running": "high", "ski_erg": "medium", "wall_balls": "low"}

    -- Race predictions
    predicted_race_time_minutes INTEGER,
    predicted_race_time_confidence NUMERIC(3,2), -- 0.00 to 1.00

    -- Meta
    data_points_count INTEGER DEFAULT 0,
    last_updated TIMESTAMPTZ DEFAULT NOW(),

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- WEEKLY SUMMARIES TABLE
-- Aggregated weekly training data
-- ============================================
CREATE TABLE weekly_summaries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    week_start TIMESTAMPTZ NOT NULL,
    week_end TIMESTAMPTZ NOT NULL,

    -- Volume
    total_workouts INTEGER DEFAULT 0,
    total_duration_minutes INTEGER DEFAULT 0,
    total_distance_km NUMERIC(6,2) DEFAULT 0,
    total_calories INTEGER DEFAULT 0,

    -- Quality
    avg_readiness NUMERIC(4,1),
    completion_rate NUMERIC(3,2), -- 0.00 to 1.00

    -- Performance changes
    profile_changes JSONB DEFAULT '{}',
    -- Example: {"fresh_run_pace_change": -0.05, "wall_balls_improvement": 0.08}

    -- AI insights
    ai_summary TEXT,
    focus_areas JSONB DEFAULT '[]',

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- CUSTOM WORKOUT TEMPLATES TABLE
-- For BYOP (Bring Your Own Program) feature
-- ============================================
CREATE TABLE custom_workout_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    name TEXT NOT NULL,
    description TEXT,
    workout_type TEXT NOT NULL,

    -- Template segments (stored as JSON for flexibility)
    segments JSONB NOT NULL DEFAULT '[]',
    -- Example: [{"segment_type": "run", "target_distance_meters": 1000}, ...]

    -- Metadata
    estimated_duration_minutes INTEGER,
    difficulty TEXT CHECK (difficulty IN ('easy', 'moderate', 'hard', 'very_hard')),
    tags JSONB DEFAULT '[]', -- ["full_simulation", "station_focus", etc.]

    -- Sharing
    is_public BOOLEAN DEFAULT false,
    times_used INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- CUSTOM PROGRAMS TABLE
-- Multi-week training programs (BYOP)
-- ============================================
CREATE TABLE custom_programs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    name TEXT NOT NULL,
    description TEXT,

    -- Structure
    duration_weeks INTEGER NOT NULL,
    schedule JSONB NOT NULL DEFAULT '[]',
    -- Example: [{"week": 1, "workouts": [{"day": 1, "template_id": "..."}, ...]}]

    -- Progress
    current_week INTEGER DEFAULT 1,
    started_at TIMESTAMPTZ,

    -- Source
    source TEXT, -- "manual", "trainer", "gym", "imported"
    source_name TEXT, -- "John's Coaching", "HYROX Official", etc.

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- INDEXES
-- ============================================

-- Users
CREATE INDEX idx_users_apple_user_id ON users(apple_user_id);
CREATE INDEX idx_users_email ON users(email);

-- Workouts
CREATE INDEX idx_workouts_user_id ON workouts(user_id);
CREATE INDEX idx_workouts_status ON workouts(status);
CREATE INDEX idx_workouts_scheduled_at ON workouts(scheduled_at);
CREATE INDEX idx_workouts_created_at ON workouts(created_at DESC);

-- Segments
CREATE INDEX idx_segments_workout_id ON workout_segments(workout_id);
CREATE INDEX idx_segments_type ON workout_segments(segment_type);

-- Performance profiles
CREATE INDEX idx_performance_user_id ON performance_profiles(user_id);

-- Weekly summaries
CREATE INDEX idx_summaries_user_id ON weekly_summaries(user_id);
CREATE INDEX idx_summaries_week_end ON weekly_summaries(week_end DESC);

-- Custom templates
CREATE INDEX idx_templates_user_id ON custom_workout_templates(user_id);
CREATE INDEX idx_templates_public ON custom_workout_templates(is_public) WHERE is_public = true;

-- ============================================
-- FUNCTIONS
-- ============================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply to tables with updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_workouts_updated_at BEFORE UPDATE ON workouts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_architectures_updated_at BEFORE UPDATE ON training_architectures
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_templates_updated_at BEFORE UPDATE ON custom_workout_templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_programs_updated_at BEFORE UPDATE ON custom_programs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE training_architectures ENABLE ROW LEVEL SECURITY;
ALTER TABLE workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_segments ENABLE ROW LEVEL SECURITY;
ALTER TABLE performance_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_workout_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_programs ENABLE ROW LEVEL SECURITY;

-- Users: Can only read/write their own data
CREATE POLICY "Users can view own data" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own data" ON users
    FOR UPDATE USING (auth.uid() = id);

-- Training architectures
CREATE POLICY "Users can manage own architectures" ON training_architectures
    FOR ALL USING (auth.uid() = user_id);

-- Workouts
CREATE POLICY "Users can manage own workouts" ON workouts
    FOR ALL USING (auth.uid() = user_id);

-- Workout segments (through workout ownership)
CREATE POLICY "Users can manage own segments" ON workout_segments
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM workouts
            WHERE workouts.id = workout_segments.workout_id
            AND workouts.user_id = auth.uid()
        )
    );

-- Performance profiles
CREATE POLICY "Users can view own profile" ON performance_profiles
    FOR SELECT USING (auth.uid() = user_id);

-- Weekly summaries
CREATE POLICY "Users can view own summaries" ON weekly_summaries
    FOR SELECT USING (auth.uid() = user_id);

-- Custom templates (own + public)
CREATE POLICY "Users can manage own templates" ON custom_workout_templates
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view public templates" ON custom_workout_templates
    FOR SELECT USING (is_public = true);

-- Custom programs
CREATE POLICY "Users can manage own programs" ON custom_programs
    FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- SERVICE ROLE POLICIES
-- For Edge Functions
-- ============================================

-- Allow service role to manage all data (for Edge Functions)
CREATE POLICY "Service role has full access to users" ON users
    FOR ALL TO service_role USING (true);

CREATE POLICY "Service role has full access to workouts" ON workouts
    FOR ALL TO service_role USING (true);

CREATE POLICY "Service role has full access to segments" ON workout_segments
    FOR ALL TO service_role USING (true);

CREATE POLICY "Service role has full access to profiles" ON performance_profiles
    FOR ALL TO service_role USING (true);

CREATE POLICY "Service role has full access to summaries" ON weekly_summaries
    FOR ALL TO service_role USING (true);
