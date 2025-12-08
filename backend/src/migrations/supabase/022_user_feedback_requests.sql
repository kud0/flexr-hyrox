-- User Feedback & Feature Requests
-- Direct line to hear from users

CREATE TABLE IF NOT EXISTS user_feedback_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,

    -- Feedback type
    category TEXT NOT NULL CHECK (category IN ('feature_request', 'bug_report', 'general', 'pulse_check')),

    -- Content
    message TEXT NOT NULL,

    -- Context (optional - where in the app they were)
    app_context TEXT,  -- e.g., 'profile', 'workout_completion', 'training_plan'

    -- User info snapshot (helpful for context)
    training_week INTEGER,
    days_since_signup INTEGER,

    -- Status tracking (for you to manage)
    status TEXT DEFAULT 'new' CHECK (status IN ('new', 'read', 'responded', 'implemented', 'wont_do')),
    admin_notes TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for quick lookups
CREATE INDEX idx_user_feedback_requests_user ON user_feedback_requests(user_id);
CREATE INDEX idx_user_feedback_requests_status ON user_feedback_requests(status);
CREATE INDEX idx_user_feedback_requests_category ON user_feedback_requests(category);
CREATE INDEX idx_user_feedback_requests_created ON user_feedback_requests(created_at DESC);

-- RLS policies
ALTER TABLE user_feedback_requests ENABLE ROW LEVEL SECURITY;

-- Users can insert their own feedback
CREATE POLICY "Users can submit feedback"
    ON user_feedback_requests FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- Users can view their own feedback
CREATE POLICY "Users can view own feedback"
    ON user_feedback_requests FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

-- Trigger for updated_at
CREATE TRIGGER update_user_feedback_requests_updated_at
    BEFORE UPDATE ON user_feedback_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Quick Pulse tracking (to know when to show prompts)
CREATE TABLE IF NOT EXISTS user_pulse_prompts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,

    -- When we last showed a pulse prompt
    last_prompt_shown TIMESTAMPTZ,

    -- How many they've responded to (engagement tracking)
    prompts_shown INTEGER DEFAULT 0,
    prompts_responded INTEGER DEFAULT 0,

    -- Don't show again until this date
    snooze_until TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id)
);

-- RLS for pulse prompts
ALTER TABLE user_pulse_prompts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own pulse prompts"
    ON user_pulse_prompts FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
