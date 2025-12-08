# FLEXR Race Partner System - Complete Architecture

## Executive Summary

The Race Partner system enables FLEXR users to connect, compare training progress, and strategize for HYROX doubles races. This document defines the complete technical architecture, database schema, API design, UI flows, and privacy model.

## Table of Contents

1. [System Overview](#system-overview)
2. [Database Schema](#database-schema)
3. [API Architecture](#api-architecture)
4. [Privacy & Permissions Model](#privacy--permissions-model)
5. [iOS UI Architecture](#ios-ui-architecture)
6. [Partner Analytics Engine](#partner-analytics-engine)
7. [Real-Time Features](#real-time-features)
8. [Implementation Phases](#implementation-phases)
9. [Architecture Decision Records](#architecture-decision-records)

---

## System Overview

### Core Concept

Users can link as "race partners" to:
- Share training progress with opt-in permissions
- Compare workout performance side-by-side
- Identify complementary strengths for race strategy
- Track combined race readiness
- Motivate each other with real-time updates

### Partnership Types

1. **Training Partner** - General training buddies, basic sharing
2. **Race Partner (Doubles)** - Full race preparation, strategy planning
3. **Relay Team Member** - 4-person relay (future v2)
4. **Coach-Athlete** - Enhanced permissions for coaches (future v2)

### Key Success Metrics

- Partner connection rate: >40% of active users
- Daily partner engagement: >3 interactions/day
- Partner retention: +25% compared to solo users
- Race completion rate: +15% for partnered users

---

## Database Schema

### 1. Core Partnership Tables

#### `partnerships`
Manages the relationship between two users.

```sql
CREATE TABLE partnerships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Partner identifiers (always user_a_id < user_b_id for consistency)
  user_a_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user_b_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Partnership metadata
  partnership_type TEXT NOT NULL CHECK (partnership_type IN (
    'training_partner',
    'race_partner_doubles',
    'relay_team',
    'coach_athlete'
  )),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN (
    'active',
    'paused',
    'ended'
  )),

  -- Display customization
  nickname_a TEXT, -- What user_a calls this partnership (e.g., "John - Race Day")
  nickname_b TEXT, -- What user_b calls this partnership

  -- Race-specific fields (for doubles/relay)
  target_race_date DATE,
  target_race_name TEXT,
  race_location TEXT,
  team_name TEXT, -- For doubles/relay display

  -- Activity tracking
  last_interaction_at TIMESTAMPTZ,
  total_interactions INTEGER DEFAULT 0,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraints
  UNIQUE(user_a_id, user_b_id),
  CHECK (user_a_id < user_b_id) -- Enforce canonical ordering
);

-- Indexes for fast lookups
CREATE INDEX idx_partnerships_user_a ON partnerships(user_a_id, status);
CREATE INDEX idx_partnerships_user_b ON partnerships(user_b_id, status);
CREATE INDEX idx_partnerships_type ON partnerships(partnership_type, status);
CREATE INDEX idx_partnerships_race_date ON partnerships(target_race_date) WHERE target_race_date IS NOT NULL;
```

#### `partner_requests`
Handles the invitation/acceptance flow.

```sql
CREATE TABLE partner_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Request participants
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Request details
  partnership_type TEXT NOT NULL CHECK (partnership_type IN (
    'training_partner',
    'race_partner_doubles',
    'relay_team',
    'coach_athlete'
  )),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending',
    'accepted',
    'declined',
    'expired',
    'cancelled'
  )),

  -- Optional message
  message TEXT,

  -- Race context (optional)
  proposed_race_date DATE,
  proposed_race_name TEXT,
  proposed_team_name TEXT,

  -- Timestamps
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  responded_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days'),

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraints
  CHECK (sender_id != recipient_id)
);

-- Indexes
CREATE INDEX idx_partner_requests_recipient ON partner_requests(recipient_id, status);
CREATE INDEX idx_partner_requests_sender ON partner_requests(sender_id, status);
CREATE INDEX idx_partner_requests_expires ON partner_requests(expires_at) WHERE status = 'pending';
```

#### `partner_permissions`
Granular control over what data each partner can see.

```sql
CREATE TABLE partner_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- References
  partnership_id UUID NOT NULL REFERENCES partnerships(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Visibility settings (what THIS user shares with their partner)
  share_workout_details BOOLEAN DEFAULT true, -- Segments, times, targets
  share_workout_completion BOOLEAN DEFAULT true, -- Just completion status
  share_performance_metrics BOOLEAN DEFAULT true, -- Heart rate, pace, distance
  share_readiness_score BOOLEAN DEFAULT true,
  share_workout_videos BOOLEAN DEFAULT false, -- Video recordings
  share_benchmarks BOOLEAN DEFAULT true, -- PRs, time trials
  share_equipment_access BOOLEAN DEFAULT true,
  share_training_plan BOOLEAN DEFAULT true, -- Weekly plan overview
  share_injuries BOOLEAN DEFAULT false, -- Injury/limitation info

  -- Notification preferences (what THIS user wants to be notified about)
  notify_workout_completed BOOLEAN DEFAULT true,
  notify_workout_started BOOLEAN DEFAULT false,
  notify_milestone_reached BOOLEAN DEFAULT true, -- PR, streak, etc.
  notify_workout_missed BOOLEAN DEFAULT false,
  notify_race_countdown BOOLEAN DEFAULT true,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraints
  UNIQUE(partnership_id, user_id)
);

-- Index for fast permission lookups
CREATE INDEX idx_partner_permissions_partnership ON partner_permissions(partnership_id);
```

#### `partner_invite_codes`
Enable easy partner linking via shareable codes.

```sql
CREATE TABLE partner_invite_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Owner
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Code details
  code TEXT UNIQUE NOT NULL, -- Short alphanumeric code (e.g., "ALEX-RACE-2025")
  partnership_type TEXT NOT NULL CHECK (partnership_type IN (
    'training_partner',
    'race_partner_doubles',
    'relay_team',
    'coach_athlete'
  )),

  -- Usage limits
  max_uses INTEGER DEFAULT 1, -- Usually 1 for specific partner, NULL for unlimited
  current_uses INTEGER DEFAULT 0,

  -- Race context (optional)
  race_date DATE,
  race_name TEXT,
  team_name TEXT,

  -- Expiration
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '30 days'),

  -- Status
  is_active BOOLEAN DEFAULT true,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraints
  CHECK (max_uses IS NULL OR current_uses <= max_uses)
);

-- Indexes
CREATE INDEX idx_partner_invite_codes_code ON partner_invite_codes(code) WHERE is_active = true;
CREATE INDEX idx_partner_invite_codes_user ON partner_invite_codes(user_id);
```

### 2. Partner Activity & Engagement Tables

#### `partner_interactions`
Track all partner engagements for analytics and motivation.

```sql
CREATE TABLE partner_interactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Participants
  partnership_id UUID NOT NULL REFERENCES partnerships(id) ON DELETE CASCADE,
  initiator_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Interaction type
  interaction_type TEXT NOT NULL CHECK (interaction_type IN (
    'kudos_given', -- Simple "nice work!" reaction
    'comment_posted', -- Comment on partner's workout
    'workout_compared', -- Viewed side-by-side comparison
    'strategy_viewed', -- Viewed doubles strategy
    'message_sent', -- In-app message (future)
    'challenge_created', -- Friendly challenge (future)
    'plan_shared', -- Shared training plan
    'dashboard_viewed' -- Viewed partner dashboard
  )),

  -- Context
  related_workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL,
  content TEXT, -- For comments, messages
  metadata JSONB, -- Additional context

  -- Timestamp
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_partner_interactions_partnership ON partner_interactions(partnership_id, created_at DESC);
CREATE INDEX idx_partner_interactions_workout ON partner_interactions(related_workout_id) WHERE related_workout_id IS NOT NULL;
```

#### `partner_kudos`
Simple encouragement system (like/high-five for workouts).

```sql
CREATE TABLE partner_kudos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Who gave kudos to whom
  giver_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  receiver_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,

  -- Kudos type (optional emoji-like reactions)
  kudos_type TEXT DEFAULT 'default' CHECK (kudos_type IN (
    'default', -- Generic "nice work"
    'fire', -- Crushing it
    'strong', -- Great strength work
    'fast', -- Speed demon
    'consistent', -- Showing up every day
    'comeback' -- After missed session
  )),

  -- Timestamp
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraints
  UNIQUE(giver_user_id, workout_id),
  CHECK (giver_user_id != receiver_user_id)
);

-- Indexes
CREATE INDEX idx_partner_kudos_receiver ON partner_kudos(receiver_user_id, created_at DESC);
CREATE INDEX idx_partner_kudos_workout ON partner_kudos(workout_id);
```

### 3. Partner Analytics & Insights Tables

#### `partner_comparison_snapshots`
Pre-computed weekly comparisons for fast dashboard loading.

```sql
CREATE TABLE partner_comparison_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Partnership reference
  partnership_id UUID NOT NULL REFERENCES partnerships(id) ON DELETE CASCADE,

  -- Time period
  week_starting DATE NOT NULL,
  week_ending DATE NOT NULL,

  -- User A stats
  user_a_workouts_completed INTEGER DEFAULT 0,
  user_a_total_distance_km NUMERIC(6, 2) DEFAULT 0,
  user_a_total_duration_minutes INTEGER DEFAULT 0,
  user_a_avg_readiness NUMERIC(3, 1),
  user_a_station_strengths JSONB, -- {"ski_erg": 0.85, "sled_push": 0.72, ...}
  user_a_consistency_score NUMERIC(3, 2), -- 0.00 to 1.00

  -- User B stats
  user_b_workouts_completed INTEGER DEFAULT 0,
  user_b_total_distance_km NUMERIC(6, 2) DEFAULT 0,
  user_b_total_duration_minutes INTEGER DEFAULT 0,
  user_b_avg_readiness NUMERIC(3, 1),
  user_b_station_strengths JSONB,
  user_b_consistency_score NUMERIC(3, 2),

  -- Combined insights
  combined_readiness_score NUMERIC(3, 1), -- Average readiness
  complementary_strength_score NUMERIC(3, 2), -- How well they complement each other
  training_gap_score NUMERIC(3, 2), -- How aligned their training is
  recommended_strategy JSONB, -- AI-generated doubles strategy

  -- Metadata
  generated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraints
  UNIQUE(partnership_id, week_starting)
);

-- Indexes
CREATE INDEX idx_partner_snapshots_partnership ON partner_comparison_snapshots(partnership_id, week_starting DESC);
```

#### `doubles_strategy_recommendations`
AI-generated strategy for HYROX Doubles based on partner strengths.

```sql
CREATE TABLE doubles_strategy_recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Partnership reference
  partnership_id UUID NOT NULL REFERENCES partnerships(id) ON DELETE CASCADE,

  -- Strategy version (updated as training progresses)
  version INTEGER NOT NULL DEFAULT 1,
  is_current BOOLEAN DEFAULT true,

  -- Station assignments (who does what)
  station_assignments JSONB NOT NULL, -- {"ski_erg": "user_a_id", "sled_push": "user_b_id", ...}

  -- Reasoning for assignments
  assignment_reasoning JSONB NOT NULL, -- {"ski_erg": "User A 15% faster on average", ...}

  -- Predicted times
  predicted_total_time_seconds INTEGER,
  predicted_station_times JSONB, -- {"ski_erg": 180, "sled_push": 240, ...}
  confidence_score NUMERIC(3, 2), -- 0.00 to 1.00

  -- Alternative strategies (if primary fails)
  alternative_strategies JSONB, -- Array of other viable strategies

  -- Race-day tips
  warmup_recommendations TEXT,
  transition_tips TEXT,
  pacing_strategy TEXT,

  -- Metadata
  generated_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '14 days'), -- Re-generate bi-weekly

  -- Constraints
  UNIQUE(partnership_id, version)
);

-- Indexes
CREATE INDEX idx_doubles_strategy_partnership ON doubles_strategy_recommendations(partnership_id, is_current);
```

### 4. Supporting Tables

#### `partner_milestones`
Track and celebrate partner achievements together.

```sql
CREATE TABLE partner_milestones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Partnership reference
  partnership_id UUID NOT NULL REFERENCES partnerships(id) ON DELETE CASCADE,

  -- Milestone details
  milestone_type TEXT NOT NULL CHECK (milestone_type IN (
    'first_workout_together', -- Both completed workouts same day
    'week_complete', -- Both completed all planned workouts this week
    'combined_distance', -- Combined distance milestone (e.g., 100km together)
    'streak_milestone', -- Both maintained X-day streak
    'race_registered', -- Both registered for same race
    'race_completed', -- Completed doubles race together
    'pr_together', -- Both set PRs same week
    'consistent_month' -- Both trained consistently for a month
  )),

  -- Milestone data
  title TEXT NOT NULL,
  description TEXT,
  achieved_value NUMERIC, -- e.g., 100.5 for 100.5km combined distance
  achieved_at DATE NOT NULL,

  -- Visibility
  is_celebrated BOOLEAN DEFAULT false, -- Has been shown to users

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_partner_milestones_partnership ON partner_milestones(partnership_id, achieved_at DESC);
```

### 5. Migration SQL

Create a new migration file: `012_partner_system.sql`

```sql
-- FLEXR Partner System Schema
-- Migration 012: Complete partner system implementation

-- Enable UUID extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- [Include all table creation SQL from above]

-- Create triggers for updated_at
CREATE TRIGGER update_partnerships_updated_at
  BEFORE UPDATE ON partnerships
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_partner_requests_updated_at
  BEFORE UPDATE ON partner_requests
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_partner_permissions_updated_at
  BEFORE UPDATE ON partner_permissions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_partner_invite_codes_updated_at
  BEFORE UPDATE ON partner_invite_codes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to automatically create default permissions when partnership is created
CREATE OR REPLACE FUNCTION create_default_partner_permissions()
RETURNS TRIGGER AS $$
BEGIN
  -- Create default permissions for user_a
  INSERT INTO partner_permissions (partnership_id, user_id)
  VALUES (NEW.id, NEW.user_a_id);

  -- Create default permissions for user_b
  INSERT INTO partner_permissions (partnership_id, user_id)
  VALUES (NEW.id, NEW.user_b_id);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER create_partnership_permissions
  AFTER INSERT ON partnerships
  FOR EACH ROW EXECUTE FUNCTION create_default_partner_permissions();

-- Function to automatically create partnership when request is accepted
CREATE OR REPLACE FUNCTION handle_partner_request_acceptance()
RETURNS TRIGGER AS $$
DECLARE
  user_a UUID;
  user_b UUID;
BEGIN
  -- Only trigger on acceptance
  IF NEW.status = 'accepted' AND OLD.status = 'pending' THEN
    -- Ensure canonical ordering (smaller UUID first)
    IF NEW.sender_id < NEW.recipient_id THEN
      user_a := NEW.sender_id;
      user_b := NEW.recipient_id;
    ELSE
      user_a := NEW.recipient_id;
      user_b := NEW.sender_id;
    END IF;

    -- Create partnership (if not exists)
    INSERT INTO partnerships (
      user_a_id,
      user_b_id,
      partnership_type,
      target_race_date,
      target_race_name,
      team_name
    ) VALUES (
      user_a,
      user_b,
      NEW.partnership_type,
      NEW.proposed_race_date,
      NEW.proposed_race_name,
      NEW.proposed_team_name
    )
    ON CONFLICT (user_a_id, user_b_id) DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER handle_request_acceptance
  AFTER UPDATE ON partner_requests
  FOR EACH ROW EXECUTE FUNCTION handle_partner_request_acceptance();

-- Function to expire old pending requests
CREATE OR REPLACE FUNCTION expire_old_partner_requests()
RETURNS INTEGER AS $$
DECLARE
  expired_count INTEGER;
BEGIN
  UPDATE partner_requests
  SET status = 'expired'
  WHERE status = 'pending'
    AND expires_at < NOW();

  GET DIAGNOSTICS expired_count = ROW_COUNT;
  RETURN expired_count;
END;
$$ LANGUAGE plpgsql;

-- View for easy partner lookup (abstracts canonical ordering)
CREATE OR REPLACE VIEW user_partnerships AS
SELECT
  p.id,
  CASE
    WHEN p.user_a_id = u.id THEN p.user_a_id
    ELSE p.user_b_id
  END AS user_id,
  CASE
    WHEN p.user_a_id = u.id THEN p.user_b_id
    ELSE p.user_a_id
  END AS partner_id,
  CASE
    WHEN p.user_a_id = u.id THEN p.nickname_a
    ELSE p.nickname_b
  END AS my_nickname,
  CASE
    WHEN p.user_a_id = u.id THEN p.nickname_b
    ELSE p.nickname_a
  END AS partner_nickname,
  p.partnership_type,
  p.status,
  p.target_race_date,
  p.target_race_name,
  p.team_name,
  p.created_at,
  p.last_interaction_at
FROM partnerships p
CROSS JOIN users u
WHERE u.id IN (p.user_a_id, p.user_b_id);
```

---

## API Architecture

### REST Endpoints

#### Partner Management

```typescript
// POST /api/v1/partners/request
// Send a partner request
interface SendPartnerRequestPayload {
  recipientUserId: string;
  partnershipType: 'training_partner' | 'race_partner_doubles' | 'relay_team';
  message?: string;
  proposedRaceDate?: string; // ISO 8601
  proposedRaceName?: string;
  proposedTeamName?: string;
}

interface SendPartnerRequestResponse {
  requestId: string;
  status: 'sent' | 'already_partners' | 'already_requested';
  expiresAt: string;
}

// POST /api/v1/partners/request/:requestId/respond
// Accept or decline a partner request
interface RespondToRequestPayload {
  action: 'accept' | 'decline';
}

interface RespondToRequestResponse {
  status: 'accepted' | 'declined';
  partnershipId?: string; // Only present if accepted
}

// GET /api/v1/partners/requests
// Get pending partner requests
interface GetPartnerRequestsResponse {
  incoming: PartnerRequest[];
  outgoing: PartnerRequest[];
}

interface PartnerRequest {
  id: string;
  senderId: string;
  senderName: string;
  senderAvatar?: string;
  recipientId: string;
  partnershipType: string;
  message?: string;
  proposedRaceDate?: string;
  proposedRaceName?: string;
  sentAt: string;
  expiresAt: string;
  status: 'pending' | 'accepted' | 'declined' | 'expired';
}

// POST /api/v1/partners/invite-code
// Generate a shareable invite code
interface GenerateInviteCodePayload {
  partnershipType: 'training_partner' | 'race_partner_doubles';
  raceDate?: string;
  raceName?: string;
  teamName?: string;
  expiresIn?: number; // Days, default 30
}

interface GenerateInviteCodeResponse {
  code: string; // e.g., "ALEX-RACE-2025"
  shareUrl: string; // Deep link to app
  expiresAt: string;
}

// POST /api/v1/partners/invite-code/:code/redeem
// Redeem an invite code to become partners
interface RedeemInviteCodeResponse {
  status: 'success' | 'already_partners' | 'expired' | 'invalid';
  partnershipId?: string;
  partnerName?: string;
}

// GET /api/v1/partners
// Get all partnerships for current user
interface GetPartnershipsResponse {
  partnerships: Partnership[];
}

interface Partnership {
  id: string;
  partnerId: string;
  partnerName: string;
  partnerAvatar?: string;
  partnershipType: string;
  status: 'active' | 'paused' | 'ended';
  myNickname?: string;
  targetRaceDate?: string;
  targetRaceName?: string;
  teamName?: string;
  createdAt: string;
  lastInteractionAt?: string;
}

// PATCH /api/v1/partners/:partnershipId
// Update partnership settings
interface UpdatePartnershipPayload {
  myNickname?: string;
  targetRaceDate?: string;
  targetRaceName?: string;
  teamName?: string;
  status?: 'active' | 'paused' | 'ended';
}

// DELETE /api/v1/partners/:partnershipId
// End a partnership
interface EndPartnershipResponse {
  status: 'ended';
}
```

#### Partner Permissions

```typescript
// GET /api/v1/partners/:partnershipId/permissions
// Get my sharing permissions for this partnership
interface GetPermissionsResponse {
  permissions: PartnerPermissions;
}

interface PartnerPermissions {
  shareWorkoutDetails: boolean;
  shareWorkoutCompletion: boolean;
  sharePerformanceMetrics: boolean;
  shareReadinessScore: boolean;
  shareWorkoutVideos: boolean;
  shareBenchmarks: boolean;
  shareEquipmentAccess: boolean;
  shareTrainingPlan: boolean;
  shareInjuries: boolean;
  notifyWorkoutCompleted: boolean;
  notifyWorkoutStarted: boolean;
  notifyMilestoneReached: boolean;
  notifyWorkoutMissed: boolean;
  notifyRaceCountdown: boolean;
}

// PATCH /api/v1/partners/:partnershipId/permissions
// Update sharing permissions
interface UpdatePermissionsPayload {
  [key: string]: boolean; // Any combination of permission fields
}

// GET /api/v1/partners/:partnershipId/partner-permissions
// Get what my partner is sharing with me
interface GetPartnerPermissionsResponse {
  permissions: PartnerPermissions;
}
```

#### Partner Dashboard

```typescript
// GET /api/v1/partners/:partnershipId/dashboard
// Get comprehensive partner comparison dashboard
interface GetPartnerDashboardResponse {
  partnership: Partnership;
  currentWeek: PartnerWeekComparison;
  recentWeeks: PartnerWeekComparison[];
  combinedStats: CombinedStats;
  milestones: Milestone[];
  doublesStrategy?: DoublesStrategy; // Only for race_partner_doubles
}

interface PartnerWeekComparison {
  weekStarting: string;
  weekEnding: string;
  myStats: UserWeekStats;
  partnerStats: UserWeekStats;
  combined: {
    totalWorkouts: number;
    totalDistance: number;
    totalDuration: number;
    avgReadiness: number;
    consistencyScore: number; // 0-100
    trainingGapScore: number; // How aligned, 0-100
  };
}

interface UserWeekStats {
  workoutsCompleted: number;
  workoutsPlanned: number;
  totalDistanceKm: number;
  totalDurationMinutes: number;
  avgReadiness: number;
  stationStrengths: Record<string, number>; // 0-1 score per station
  consistencyScore: number; // 0-1
}

interface CombinedStats {
  daysUntilRace?: number;
  combinedReadiness: number; // 0-100
  complementaryStrength: number; // How well you complement each other, 0-100
  totalWorkoutsTogether: number;
  currentStreak: number; // Days both trained
  longestStreak: number;
}

interface Milestone {
  id: string;
  type: string;
  title: string;
  description: string;
  achievedAt: string;
  achievedValue?: number;
  isCelebrated: boolean;
}

interface DoublesStrategy {
  version: number;
  stationAssignments: Record<string, string>; // station -> userId
  reasoning: Record<string, string>; // station -> reason
  predictedTotalTime: number; // seconds
  predictedStationTimes: Record<string, number>;
  confidenceScore: number; // 0-1
  warmupRecommendations: string;
  transitionTips: string;
  pacingStrategy: string;
  generatedAt: string;
}

// GET /api/v1/partners/:partnershipId/workouts/compare
// Compare specific workouts between partners
interface CompareWorkoutsQuery {
  myWorkoutId: string;
  partnerWorkoutId?: string; // If omitted, find similar workout
  dateRange?: { start: string; end: string };
}

interface CompareWorkoutsResponse {
  myWorkout: WorkoutComparison;
  partnerWorkout?: WorkoutComparison;
  insights: ComparisonInsight[];
}

interface WorkoutComparison {
  id: string;
  userId: string;
  date: string;
  type: string;
  totalDuration: number;
  totalDistance: number;
  avgHeartRate: number;
  segments: SegmentComparison[];
}

interface SegmentComparison {
  name: string;
  type: string;
  myTime?: number;
  partnerTime?: number;
  myReps?: number;
  partnerReps?: number;
  myDistance?: number;
  partnerDistance?: number;
  percentageDifference?: number;
  whoIsFaster?: 'me' | 'partner' | 'equal';
}

interface ComparisonInsight {
  type: 'strength_advantage' | 'pace_difference' | 'complementary' | 'improvement_opportunity';
  message: string;
  data?: any;
}
```

#### Partner Activity Feed

```typescript
// GET /api/v1/partners/:partnershipId/activity
// Get recent partner activity
interface GetPartnerActivityQuery {
  limit?: number; // Default 20
  before?: string; // Pagination cursor
}

interface GetPartnerActivityResponse {
  activities: PartnerActivity[];
  nextCursor?: string;
}

interface PartnerActivity {
  id: string;
  type: 'workout_completed' | 'milestone_reached' | 'pr_set' | 'workout_started' | 'streak_milestone';
  userId: string;
  userName: string;
  message: string;
  timestamp: string;
  workoutId?: string;
  metadata?: any;
  kudosCount?: number;
  hasGivenKudos?: boolean; // Current user has given kudos
}

// POST /api/v1/partners/:partnershipId/kudos
// Give kudos to partner's workout
interface GiveKudosPayload {
  workoutId: string;
  kudosType?: 'default' | 'fire' | 'strong' | 'fast' | 'consistent' | 'comeback';
}

interface GiveKudosResponse {
  status: 'success' | 'already_given';
  totalKudos: number;
}

// GET /api/v1/partners/:partnershipId/stats
// Get partnership statistics
interface GetPartnershipStatsResponse {
  totalDaysAsPartners: number;
  totalWorkoutsTogether: number; // Completed on same days
  totalInteractions: number;
  kudosExchanged: number;
  milestonesAchieved: number;
  currentStreak: number;
  longestStreak: number;
  upcomingRace?: {
    name: string;
    date: string;
    daysUntil: number;
  };
}
```

#### Doubles Strategy (Race Partner Specific)

```typescript
// GET /api/v1/partners/:partnershipId/doubles-strategy
// Get current doubles strategy recommendation
interface GetDoublesStrategyResponse {
  strategy: DoublesStrategy;
  alternatives: DoublesStrategy[];
  lastUpdated: string;
  nextUpdateIn: number; // days
}

// POST /api/v1/partners/:partnershipId/doubles-strategy/regenerate
// Force regeneration of doubles strategy (max once per week)
interface RegenerateStrategyResponse {
  strategy: DoublesStrategy;
  canRegenerateAgainAt: string;
}

// PATCH /api/v1/partners/:partnershipId/doubles-strategy
// Override AI strategy with manual preferences
interface OverrideStrategyPayload {
  stationAssignments: Record<string, string>; // station -> userId
  notes?: string;
}

interface OverrideStrategyResponse {
  strategy: DoublesStrategy;
  isCustom: true;
}
```

### Supabase Edge Functions

#### `generate-doubles-strategy`
Analyzes both partners' performance and generates optimal station assignments.

```typescript
// Input
interface GenerateDoublesStrategyInput {
  partnership_id: string;
  user_a_id: string;
  user_b_id: string;
  race_date?: string;
}

// Processing Steps:
// 1. Fetch last 12 weeks of workout data for both users
// 2. Calculate station-specific performance metrics
// 3. Identify strengths and weaknesses
// 4. Generate 3-5 strategy options
// 5. Rank by predicted total time
// 6. Generate reasoning and tips
// 7. Store in doubles_strategy_recommendations table

// Output
interface GenerateDoublesStrategyOutput {
  success: boolean;
  strategy: DoublesStrategy;
  alternatives: DoublesStrategy[];
}
```

#### `calculate-partner-comparison`
Weekly cron job to pre-compute partner comparison data.

```typescript
// Runs every Monday at 00:00 UTC
// For each active partnership:
// 1. Aggregate previous week's stats for both users
// 2. Calculate station strengths
// 3. Compute consistency scores
// 4. Calculate training gap
// 5. Store in partner_comparison_snapshots
// 6. Check for milestones
// 7. Trigger notifications if needed
```

#### `expire-partner-requests`
Daily cron job to clean up old requests.

```typescript
// Runs daily at 00:00 UTC
// Marks requests as expired if past expiration date
// Sends notification to sender if request went unanswered
```

---

## Privacy & Permissions Model

### Privacy Levels

#### Level 1: No Sharing (Default for non-partners)
- User profile (name, avatar)
- Public achievements only
- No workout details

#### Level 2: Limited Sharing (Training Partner)
- Workout completion status
- Basic stats (duration, distance)
- Readiness score
- No detailed segments or performance

#### Level 3: Full Sharing (Race Partner Doubles)
- Complete workout details
- Segment-by-segment performance
- Heart rate and pace data
- Benchmarks and PRs
- Training plan overview
- Strategy recommendations

#### Level 4: Enhanced Sharing (Coach-Athlete, future)
- Everything from Level 3
- Injury and limitation data
- Video recordings
- Real-time workout tracking
- Ability to prescribe workouts

### Permission Inheritance

```typescript
// Default permissions by partnership type
const DEFAULT_PERMISSIONS = {
  training_partner: {
    shareWorkoutDetails: false,
    shareWorkoutCompletion: true,
    sharePerformanceMetrics: false,
    shareReadinessScore: true,
    shareWorkoutVideos: false,
    shareBenchmarks: true,
    shareEquipmentAccess: true,
    shareTrainingPlan: false,
    shareInjuries: false,
    notifyWorkoutCompleted: true,
    notifyMilestoneReached: true,
  },
  race_partner_doubles: {
    shareWorkoutDetails: true,
    shareWorkoutCompletion: true,
    sharePerformanceMetrics: true,
    shareReadinessScore: true,
    shareWorkoutVideos: false,
    shareBenchmarks: true,
    shareEquipmentAccess: true,
    shareTrainingPlan: true,
    shareInjuries: false,
    notifyWorkoutCompleted: true,
    notifyMilestoneReached: true,
  },
};
```

### Permission Checks

```typescript
// Server-side permission checking middleware
async function checkPartnerPermission(
  partnershipId: string,
  requestingUserId: string,
  dataOwnerUserId: string,
  requiredPermission: keyof PartnerPermissions
): Promise<boolean> {
  // 1. Verify partnership exists and is active
  // 2. Verify requestingUserId is part of partnership
  // 3. Fetch permissions for dataOwnerUserId
  // 4. Check if requiredPermission is enabled
  // 5. Return true/false
}

// Example usage in API endpoint:
async function getPartnerWorkoutDetails(
  partnershipId: string,
  workoutId: string,
  requestingUserId: string
) {
  const workout = await fetchWorkout(workoutId);
  const hasPermission = await checkPartnerPermission(
    partnershipId,
    requestingUserId,
    workout.user_id,
    'shareWorkoutDetails'
  );

  if (!hasPermission) {
    // Return limited data only
    return {
      id: workout.id,
      type: workout.type,
      completedAt: workout.completed_at,
      status: workout.status,
      // NO detailed segments, metrics, etc.
    };
  }

  // Return full workout data
  return workout;
}
```

### Data Visibility Matrix

| Data Type | Public | Gym Member | Training Partner | Race Partner | Coach |
|-----------|--------|------------|------------------|--------------|-------|
| Name, Avatar | Yes | Yes | Yes | Yes | Yes |
| Workout Completion | No | Yes | Yes | Yes | Yes |
| Workout Type | No | Yes | Yes | Yes | Yes |
| Duration, Distance | No | No | Basic | Full | Full |
| Segment Details | No | No | No | Yes | Yes |
| Heart Rate | No | No | No | Opt-in | Yes |
| Readiness Score | No | No | Yes | Yes | Yes |
| Training Plan | No | No | No | Opt-in | Yes |
| Injuries | No | No | No | Opt-in | Yes |
| Videos | No | No | No | Opt-in | Opt-in |
| Benchmarks | No | No | Yes | Yes | Yes |

---

## iOS UI Architecture

### Navigation Structure

```
App Root
└── TabView
    ├── Home
    ├── Workouts
    ├── Partners (NEW)
    │   ├── Partner List
    │   ├── Partner Dashboard (per partner)
    │   ├── Partner Requests
    │   └── Add Partner
    ├── Progress
    └── Profile
```

### SwiftUI Views

#### 1. Partner List View (`PartnersView.swift`)

```swift
struct PartnersView: View {
    @StateObject private var viewModel = PartnersViewModel()
    @State private var showingAddPartner = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Pending requests badge
                    if viewModel.pendingRequestsCount > 0 {
                        PendingRequestsBanner(count: viewModel.pendingRequestsCount)
                            .onTapGesture {
                                viewModel.showingRequests = true
                            }
                    }

                    // Active partnerships
                    ForEach(viewModel.partnerships) { partnership in
                        NavigationLink(value: partnership) {
                            PartnershipCard(partnership: partnership)
                        }
                    }

                    // Add partner button
                    AddPartnerButton {
                        showingAddPartner = true
                    }
                }
                .padding()
            }
            .navigationTitle("Race Partners")
            .navigationDestination(for: Partnership.self) { partnership in
                PartnerDashboardView(partnership: partnership)
            }
            .sheet(isPresented: $showingAddPartner) {
                AddPartnerView()
            }
            .sheet(isPresented: $viewModel.showingRequests) {
                PartnerRequestsView()
            }
        }
        .onAppear {
            viewModel.loadPartnerships()
        }
    }
}

struct PartnershipCard: View {
    let partnership: Partnership

    var body: some View {
        HStack(spacing: 16) {
            // Partner avatar
            AsyncImage(url: URL(string: partnership.partnerAvatar ?? "")) { image in
                image.resizable()
            } placeholder: {
                Circle()
                    .fill(Color.gray)
                    .overlay(Text(partnership.partnerName.prefix(1)))
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(partnership.partnerName)
                    .font(.headline)

                HStack {
                    Image(systemName: partnershipTypeIcon)
                    Text(partnership.partnershipType.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if let raceName = partnership.targetRaceName,
                   let raceDate = partnership.targetRaceDate {
                    Text("\(raceName) · \(daysUntil(raceDate))d")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private var partnershipTypeIcon: String {
        switch partnership.partnershipType {
        case .trainingPartner: return "figure.run"
        case .racePartnerDoubles: return "figure.2.run"
        case .relayTeam: return "figure.4.run"
        case .coachAthlete: return "person.crop.circle.badge.checkmark"
        }
    }

    private func daysUntil(_ date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
    }
}
```

#### 2. Partner Dashboard View (`PartnerDashboardView.swift`)

```swift
struct PartnerDashboardView: View {
    let partnership: Partnership
    @StateObject private var viewModel: PartnerDashboardViewModel

    init(partnership: Partnership) {
        self.partnership = partnership
        _viewModel = StateObject(wrappedValue: PartnerDashboardViewModel(partnership: partnership))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with race countdown
                if let raceDate = partnership.targetRaceDate {
                    RaceCountdownCard(
                        raceName: partnership.targetRaceName ?? "HYROX Doubles",
                        raceDate: raceDate,
                        combinedReadiness: viewModel.dashboard?.combinedStats.combinedReadiness ?? 0
                    )
                }

                // This Week Comparison
                if let currentWeek = viewModel.dashboard?.currentWeek {
                    WeekComparisonCard(
                        title: "This Week",
                        weekData: currentWeek,
                        myName: "You",
                        partnerName: partnership.partnerName
                    )
                }

                // Station Strengths (for doubles)
                if partnership.partnershipType == .racePartnerDoubles,
                   let strategy = viewModel.dashboard?.doublesStrategy {
                    DoublesStrategyCard(strategy: strategy)
                }

                // Recent Activity Feed
                ActivityFeedSection(
                    activities: viewModel.recentActivities,
                    onKudosTap: { activityId in
                        viewModel.giveKudos(to: activityId)
                    }
                )

                // Milestones
                if let milestones = viewModel.dashboard?.milestones, !milestones.isEmpty {
                    MilestonesSection(milestones: milestones)
                }

                // Recent Weeks (past 4 weeks)
                if let recentWeeks = viewModel.dashboard?.recentWeeks {
                    ForEach(recentWeeks) { week in
                        WeekComparisonCard(
                            title: "Week of \(formattedDate(week.weekStarting))",
                            weekData: week,
                            myName: "You",
                            partnerName: partnership.partnerName
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle(partnership.partnerName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("View Strategy", systemImage: "chart.bar.fill") {
                        viewModel.showingStrategy = true
                    }
                    Button("Compare Workouts", systemImage: "arrow.left.arrow.right") {
                        viewModel.showingComparison = true
                    }
                    Button("Settings", systemImage: "gearshape") {
                        viewModel.showingSettings = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $viewModel.showingStrategy) {
            if let strategy = viewModel.dashboard?.doublesStrategy {
                DoublesStrategyDetailView(strategy: strategy)
            }
        }
        .sheet(isPresented: $viewModel.showingSettings) {
            PartnerSettingsView(partnership: partnership)
        }
        .onAppear {
            viewModel.loadDashboard()
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct RaceCountdownCard: View {
    let raceName: String
    let raceDate: Date
    let combinedReadiness: Double

    private var daysUntil: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: raceDate).day ?? 0
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(raceName)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack {
                    Text("\(daysUntil)")
                        .font(.system(size: 48, weight: .bold))
                    Text("DAYS")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Combined readiness gauge
            HStack {
                Text("Combined Readiness")
                    .font(.subheadline)
                Spacer()
                ReadinessGauge(score: combinedReadiness)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: raceDate)
    }
}

struct WeekComparisonCard: View {
    let title: String
    let weekData: PartnerWeekComparison
    let myName: String
    let partnerName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)

            // Side-by-side stats
            HStack(spacing: 20) {
                VStack(spacing: 12) {
                    Text(myName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    StatRow(label: "Workouts", value: "\(weekData.myStats.workoutsCompleted)/\(weekData.myStats.workoutsPlanned)")
                    StatRow(label: "Distance", value: String(format: "%.1f km", weekData.myStats.totalDistanceKm))
                    StatRow(label: "Duration", value: "\(weekData.myStats.totalDurationMinutes) min")
                    StatRow(label: "Readiness", value: String(format: "%.0f", weekData.myStats.avgReadiness))
                }

                Divider()

                VStack(spacing: 12) {
                    Text(partnerName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    StatRow(label: "Workouts", value: "\(weekData.partnerStats.workoutsCompleted)/\(weekData.partnerStats.workoutsPlanned)")
                    StatRow(label: "Distance", value: String(format: "%.1f km", weekData.partnerStats.totalDistanceKm))
                    StatRow(label: "Duration", value: "\(weekData.partnerStats.totalDurationMinutes) min")
                    StatRow(label: "Readiness", value: String(format: "%.0f", weekData.partnerStats.avgReadiness))
                }
            }

            // Combined insights
            Divider()

            HStack {
                InsightBadge(
                    label: "Consistency",
                    value: String(format: "%.0f%%", weekData.combined.consistencyScore),
                    color: weekData.combined.consistencyScore > 80 ? .green : .orange
                )

                InsightBadge(
                    label: "Training Alignment",
                    value: String(format: "%.0f%%", weekData.combined.trainingGapScore),
                    color: weekData.combined.trainingGapScore > 70 ? .green : .yellow
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct DoublesStrategyCard: View {
    let strategy: DoublesStrategy

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Doubles Strategy")
                    .font(.headline)
                Spacer()
                Text("v\(strategy.version)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Predicted time
            HStack {
                Text("Predicted Time")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(formatTime(strategy.predictedTotalTime))
                    .font(.title2)
                    .fontWeight(.bold)
            }

            // Station assignments (first 3)
            VStack(alignment: .leading, spacing: 8) {
                Text("Optimal Assignments")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ForEach(Array(strategy.stationAssignments.prefix(3)), id: \.key) { station, userId in
                    StationAssignmentRow(
                        station: station,
                        assignedTo: userId == viewModel.currentUserId ? "You" : partnerName,
                        reason: strategy.reasoning[station] ?? ""
                    )
                }

                Button("View Full Strategy") {
                    // Navigate to detailed strategy view
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
```

#### 3. Add Partner View (`AddPartnerView.swift`)

```swift
struct AddPartnerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddPartnerViewModel()
    @State private var selectedMethod: AddMethod = .search

    enum AddMethod {
        case search
        case code
        case qr
        case createCode
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Method selector
                Picker("Add Method", selection: $selectedMethod) {
                    Text("Search").tag(AddMethod.search)
                    Text("Code").tag(AddMethod.code)
                    Text("QR").tag(AddMethod.qr)
                    Text("Share").tag(AddMethod.createCode)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Content based on selected method
                switch selectedMethod {
                case .search:
                    SearchPartnerView(viewModel: viewModel)
                case .code:
                    EnterCodeView(viewModel: viewModel)
                case .qr:
                    ScanQRCodeView(viewModel: viewModel)
                case .createCode:
                    CreateInviteCodeView(viewModel: viewModel)
                }

                Spacer()
            }
            .navigationTitle("Add Partner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Success!", isPresented: $viewModel.showingSuccess) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text(viewModel.successMessage)
            }
        }
    }
}

struct SearchPartnerView: View {
    @ObservedObject var viewModel: AddPartnerViewModel
    @State private var searchText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Search by name or email")
                .font(.headline)
                .padding(.horizontal)

            SearchField(text: $searchText, placeholder: "Enter name or email")
                .padding(.horizontal)
                .onChange(of: searchText) { newValue in
                    viewModel.searchUsers(query: newValue)
                }

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.searchResults) { user in
                        UserSearchResultRow(user: user) {
                            viewModel.sendPartnerRequest(to: user)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct EnterCodeView: View {
    @ObservedObject var viewModel: AddPartnerViewModel
    @State private var code = ""

    var body: some View {
        VStack(spacing: 24) {
            Text("Enter partner code")
                .font(.headline)

            TextField("Code", text: $code)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .padding(.horizontal)

            Button("Connect") {
                viewModel.redeemInviteCode(code)
            }
            .buttonStyle(.borderedProminent)
            .disabled(code.isEmpty)
        }
        .padding()
    }
}

struct CreateInviteCodeView: View {
    @ObservedObject var viewModel: AddPartnerViewModel
    @State private var partnershipType: PartnershipType = .racePartnerDoubles
    @State private var raceName = ""
    @State private var raceDate = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Create Invite Link")
                .font(.headline)

            Picker("Partnership Type", selection: $partnershipType) {
                Text("Training Partner").tag(PartnershipType.trainingPartner)
                Text("Race Partner (Doubles)").tag(PartnershipType.racePartnerDoubles)
            }
            .pickerStyle(.segmented)

            if partnershipType == .racePartnerDoubles {
                TextField("Race Name", text: $raceName)
                    .textFieldStyle(.roundedBorder)

                DatePicker("Race Date", selection: $raceDate, displayedComponents: .date)
            }

            Button("Generate Code") {
                viewModel.generateInviteCode(
                    type: partnershipType,
                    raceName: raceName.isEmpty ? nil : raceName,
                    raceDate: partnershipType == .racePartnerDoubles ? raceDate : nil
                )
            }
            .buttonStyle(.borderedProminent)

            if let inviteCode = viewModel.generatedInviteCode {
                InviteCodeDisplay(code: inviteCode)
            }
        }
        .padding()
    }
}

struct InviteCodeDisplay: View {
    let code: String

    var body: some View {
        VStack(spacing: 16) {
            Text("Share this code with your partner:")
                .font(.caption)

            Text(code)
                .font(.title)
                .fontWeight(.bold)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

            ShareLink(item: "Join me on FLEXR! Use code: \(code)\nflexr://partner/join?code=\(code)") {
                Label("Share Code", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
```

#### 4. Partner Requests View (`PartnerRequestsView.swift`)

```swift
struct PartnerRequestsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PartnerRequestsViewModel()

    var body: some View {
        NavigationStack {
            List {
                if !viewModel.incomingRequests.isEmpty {
                    Section("Incoming Requests") {
                        ForEach(viewModel.incomingRequests) { request in
                            IncomingRequestRow(request: request) { action in
                                viewModel.respondToRequest(request.id, action: action)
                            }
                        }
                    }
                }

                if !viewModel.outgoingRequests.isEmpty {
                    Section("Pending Requests") {
                        ForEach(viewModel.outgoingRequests) { request in
                            OutgoingRequestRow(request: request) {
                                viewModel.cancelRequest(request.id)
                            }
                        }
                    }
                }

                if viewModel.incomingRequests.isEmpty && viewModel.outgoingRequests.isEmpty {
                    ContentUnavailableView(
                        "No Requests",
                        systemImage: "person.2.slash",
                        description: Text("You don't have any pending partner requests")
                    )
                }
            }
            .navigationTitle("Partner Requests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadRequests()
        }
    }
}

struct IncomingRequestRow: View {
    let request: PartnerRequest
    let onRespond: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                AsyncImage(url: URL(string: request.senderAvatar ?? "")) { image in
                    image.resizable()
                } placeholder: {
                    Circle().fill(Color.gray)
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(request.senderName)
                        .font(.headline)
                    Text(request.partnershipType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            if let message = request.message {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if let raceName = request.proposedRaceName {
                HStack {
                    Image(systemName: "flag.fill")
                    Text(raceName)
                    if let raceDate = request.proposedRaceDate {
                        Text("·")
                        Text(formatDate(raceDate))
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }

            HStack(spacing: 12) {
                Button("Accept") {
                    onRespond("accept")
                }
                .buttonStyle(.borderedProminent)

                Button("Decline") {
                    onRespond("decline")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 8)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}
```

#### 5. Partner Settings View (`PartnerSettingsView.swift`)

```swift
struct PartnerSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let partnership: Partnership
    @StateObject private var viewModel: PartnerSettingsViewModel

    init(partnership: Partnership) {
        self.partnership = partnership
        _viewModel = StateObject(wrappedValue: PartnerSettingsViewModel(partnership: partnership))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Partnership Details") {
                    TextField("Nickname", text: $viewModel.nickname)

                    if partnership.partnershipType == .racePartnerDoubles {
                        TextField("Team Name", text: $viewModel.teamName)
                        DatePicker("Race Date", selection: $viewModel.raceDate, displayedComponents: .date)
                        TextField("Race Name", text: $viewModel.raceName)
                    }
                }

                Section("What I Share") {
                    Toggle("Workout Details", isOn: $viewModel.permissions.shareWorkoutDetails)
                    Toggle("Performance Metrics", isOn: $viewModel.permissions.sharePerformanceMetrics)
                    Toggle("Readiness Score", isOn: $viewModel.permissions.shareReadinessScore)
                    Toggle("Training Plan", isOn: $viewModel.permissions.shareTrainingPlan)
                    Toggle("Benchmarks & PRs", isOn: $viewModel.permissions.shareBenchmarks)
                    Toggle("Workout Videos", isOn: $viewModel.permissions.shareWorkoutVideos)
                    Toggle("Injuries/Limitations", isOn: $viewModel.permissions.shareInjuries)
                }

                Section("Notifications") {
                    Toggle("Workout Completed", isOn: $viewModel.permissions.notifyWorkoutCompleted)
                    Toggle("Workout Started", isOn: $viewModel.permissions.notifyWorkoutStarted)
                    Toggle("Milestone Reached", isOn: $viewModel.permissions.notifyMilestoneReached)
                    Toggle("Workout Missed", isOn: $viewModel.permissions.notifyWorkoutMissed)
                    Toggle("Race Countdown", isOn: $viewModel.permissions.notifyRaceCountdown)
                }

                Section("Partnership Status") {
                    Picker("Status", selection: $viewModel.status) {
                        Text("Active").tag(PartnershipStatus.active)
                        Text("Paused").tag(PartnershipStatus.paused)
                    }
                }

                Section {
                    Button("End Partnership", role: .destructive) {
                        viewModel.showingEndConfirmation = true
                    }
                }
            }
            .navigationTitle("Partnership Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.save()
                            dismiss()
                        }
                    }
                }
            }
            .confirmationDialog(
                "End Partnership?",
                isPresented: $viewModel.showingEndConfirmation,
                titleVisibility: .visible
            ) {
                Button("End Partnership", role: .destructive) {
                    Task {
                        await viewModel.endPartnership()
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You can always reconnect with \(partnership.partnerName) later.")
            }
        }
        .onAppear {
            viewModel.loadSettings()
        }
    }
}
```

### View Models

#### `PartnersViewModel.swift`

```swift
@MainActor
class PartnersViewModel: ObservableObject {
    @Published var partnerships: [Partnership] = []
    @Published var pendingRequestsCount: Int = 0
    @Published var showingRequests = false
    @Published var isLoading = false
    @Published var error: Error?

    private let supabaseService = SupabaseService.shared

    func loadPartnerships() {
        isLoading = true
        Task {
            do {
                partnerships = try await supabaseService.getPartnerships()
                pendingRequestsCount = try await supabaseService.getPendingRequestsCount()
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }

    func refreshData() async {
        do {
            partnerships = try await supabaseService.getPartnerships()
            pendingRequestsCount = try await supabaseService.getPendingRequestsCount()
        } catch {
            self.error = error
        }
    }
}
```

#### `PartnerDashboardViewModel.swift`

```swift
@MainActor
class PartnerDashboardViewModel: ObservableObject {
    let partnership: Partnership

    @Published var dashboard: PartnerDashboard?
    @Published var recentActivities: [PartnerActivity] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showingStrategy = false
    @Published var showingComparison = false
    @Published var showingSettings = false

    private let supabaseService = SupabaseService.shared
    var currentUserId: String { supabaseService.currentUser?.id.uuidString ?? "" }

    init(partnership: Partnership) {
        self.partnership = partnership
    }

    func loadDashboard() {
        isLoading = true
        Task {
            do {
                dashboard = try await supabaseService.getPartnerDashboard(partnershipId: partnership.id)
                recentActivities = try await supabaseService.getPartnerActivity(partnershipId: partnership.id)
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }

    func giveKudos(to activityId: String) {
        Task {
            do {
                guard let workoutId = recentActivities.first(where: { $0.id == activityId })?.workoutId else { return }
                try await supabaseService.giveKudos(partnershipId: partnership.id, workoutId: workoutId)
                await loadDashboard() // Refresh to show kudos
            } catch {
                self.error = error
            }
        }
    }
}
```

---

## Partner Analytics Engine

### Weekly Comparison Algorithm

```typescript
// Pseudo-code for weekly comparison calculation
interface WeeklyComparisonInput {
  partnership_id: string;
  week_starting: Date;
  week_ending: Date;
}

async function calculateWeeklyComparison(input: WeeklyComparisonInput) {
  // 1. Fetch both users' workouts for the week
  const partnership = await getPartnership(input.partnership_id);
  const userAWorkouts = await getWorkoutsForWeek(partnership.user_a_id, input.week_starting, input.week_ending);
  const userBWorkouts = await getWorkoutsForWeek(partnership.user_b_id, input.week_starting, input.week_ending);

  // 2. Calculate basic stats for each user
  const userAStats = {
    workoutsCompleted: userAWorkouts.filter(w => w.status === 'completed').length,
    workoutsPlanned: userAWorkouts.length,
    totalDistanceKm: sumField(userAWorkouts, 'total_distance_km'),
    totalDurationMinutes: sumField(userAWorkouts, 'total_duration_minutes'),
    avgReadiness: avgField(userAWorkouts, 'readiness_score'),
    stationStrengths: await calculateStationStrengths(userAWorkouts),
    consistencyScore: calculateConsistency(userAWorkouts, input.week_starting, input.week_ending)
  };

  const userBStats = { /* same for user B */ };

  // 3. Calculate combined insights
  const combined = {
    totalWorkouts: userAStats.workoutsCompleted + userBStats.workoutsCompleted,
    totalDistance: userAStats.totalDistanceKm + userBStats.totalDistanceKm,
    totalDuration: userAStats.totalDurationMinutes + userBStats.totalDurationMinutes,
    avgReadiness: (userAStats.avgReadiness + userBStats.avgReadiness) / 2,
    consistencyScore: (userAStats.consistencyScore + userBStats.consistencyScore) / 2,
    trainingGapScore: calculateTrainingGap(userAStats, userBStats),
    complementaryStrength: calculateComplementaryStrength(userAStats.stationStrengths, userBStats.stationStrengths)
  };

  // 4. Store snapshot
  await storeComparisonSnapshot({
    partnership_id: input.partnership_id,
    week_starting: input.week_starting,
    week_ending: input.week_ending,
    user_a_stats: userAStats,
    user_b_stats: userBStats,
    combined
  });

  // 5. Check for milestones
  await checkForMilestones(input.partnership_id, combined);
}

// Calculate how well partners' station strengths complement each other
function calculateComplementaryStrength(
  userAStrengths: Record<string, number>,
  userBStrengths: Record<string, number>
): number {
  // Higher score if one partner is strong where the other is weak
  const stations = Object.keys(userAStrengths);
  let complementaryScore = 0;

  for (const station of stations) {
    const strengthA = userAStrengths[station] || 0.5;
    const strengthB = userBStrengths[station] || 0.5;

    // Ideal: one at 0.9, other at 0.6 (complementary)
    // Poor: both at 0.9 or both at 0.5 (not complementary)
    const diff = Math.abs(strengthA - strengthB);
    const avg = (strengthA + strengthB) / 2;

    // Higher diff with high avg is good
    complementaryScore += diff * avg;
  }

  // Normalize to 0-1
  return Math.min(complementaryScore / stations.length, 1.0);
}

// Calculate training alignment (how similar their training is)
function calculateTrainingGap(
  userAStats: UserWeekStats,
  userBStats: UserWeekStats
): number {
  // Lower gap means more aligned training
  const workoutGap = Math.abs(userAStats.workoutsCompleted - userBStats.workoutsCompleted);
  const distanceGap = Math.abs(userAStats.totalDistanceKm - userBStats.totalDistanceKm);
  const readinessGap = Math.abs(userAStats.avgReadiness - userBStats.avgReadiness);

  // Normalize and invert (higher score = more aligned)
  const alignmentScore = 1 - (
    (workoutGap / 7) * 0.4 + // Max 7 workouts difference
    (distanceGap / 50) * 0.3 + // Max 50km difference
    (readinessGap / 10) * 0.3 // Max 10 point readiness difference
  );

  return Math.max(0, alignmentScore);
}

// Calculate station-specific strength scores
async function calculateStationStrengths(workouts: Workout[]): Promise<Record<string, number>> {
  const stationPerformance: Record<string, number[]> = {};

  for (const workout of workouts) {
    const segments = await getWorkoutSegments(workout.id);

    for (const segment of segments) {
      if (segment.station_type) {
        const performance = calculateSegmentPerformance(segment);

        if (!stationPerformance[segment.station_type]) {
          stationPerformance[segment.station_type] = [];
        }
        stationPerformance[segment.station_type].push(performance);
      }
    }
  }

  // Calculate average strength per station (0-1 scale)
  const strengths: Record<string, number> = {};
  for (const [station, performances] of Object.entries(stationPerformance)) {
    strengths[station] = average(performances);
  }

  return strengths;
}

// Calculate performance score for a segment (0-1 scale)
function calculateSegmentPerformance(segment: WorkoutSegment): number {
  // Compare actual vs target
  if (segment.target_duration_seconds && segment.actual_duration_seconds) {
    const ratio = segment.actual_duration_seconds / segment.target_duration_seconds;
    // Faster is better, but within reason (0.8-1.2 is ideal)
    if (ratio >= 0.8 && ratio <= 1.2) {
      return 1.0;
    } else if (ratio < 0.8) {
      return Math.max(0.5, ratio / 0.8); // Too fast might be cutting corners
    } else {
      return Math.max(0, 1 - (ratio - 1.2) * 2); // Too slow is bad
    }
  }

  // If no comparison available, assume moderate performance
  return 0.7;
}
```

### Doubles Strategy Generation

```typescript
// AI-powered doubles strategy recommendation
interface DoublesStrategyInput {
  partnership_id: string;
  race_date?: Date;
}

async function generateDoublesStrategy(input: DoublesStrategyInput) {
  // 1. Get partnership and user data
  const partnership = await getPartnership(input.partnership_id);
  const userA = await getUser(partnership.user_a_id);
  const userB = await getUser(partnership.user_b_id);

  // 2. Get last 12 weeks of performance data
  const userAWorkouts = await getRecentWorkouts(userA.id, 12);
  const userBWorkouts = await getRecentWorkouts(userB.id, 12);

  // 3. Calculate station strengths for both
  const userAStrengths = await calculateStationStrengths(userAWorkouts);
  const userBStrengths = await calculateStationStrengths(userBWorkouts);

  // 4. HYROX Doubles stations (8 stations, alternating)
  const stations = [
    'ski_erg',
    'sled_push',
    'sled_pull',
    'burpee_broad_jump',
    'rowing',
    'farmers_carry',
    'sandbag_lunges',
    'wall_balls'
  ];

  // 5. Assign each station to the stronger partner
  const assignments: Record<string, string> = {};
  const reasoning: Record<string, string> = {};

  for (const station of stations) {
    const strengthA = userAStrengths[station] || 0.5;
    const strengthB = userBStrengths[station] || 0.5;

    if (strengthA > strengthB) {
      assignments[station] = userA.id;
      const advantage = ((strengthA - strengthB) / strengthB * 100).toFixed(0);
      reasoning[station] = `${userA.name} is ${advantage}% stronger on this station`;
    } else {
      assignments[station] = userB.id;
      const advantage = ((strengthB - strengthA) / strengthA * 100).toFixed(0);
      reasoning[station] = `${userB.name} is ${advantage}% stronger on this station`;
    }
  }

  // 6. Predict times based on historical performance
  const predictedStationTimes: Record<string, number> = {};
  let predictedTotalTime = 0;

  for (const station of stations) {
    const assignedUserId = assignments[station];
    const assignedStrength = assignedUserId === userA.id ? userAStrengths[station] : userBStrengths[station];

    // Benchmark time for each station (elite level)
    const benchmarkTimes = {
      ski_erg: 240, // 4:00
      sled_push: 120, // 2:00
      sled_pull: 180, // 3:00
      burpee_broad_jump: 420, // 7:00
      rowing: 270, // 4:30
      farmers_carry: 150, // 2:30
      sandbag_lunges: 300, // 5:00
      wall_balls: 360 // 6:00
    };

    // Adjust benchmark based on strength (0.5 strength = 2x benchmark, 1.0 strength = benchmark)
    const adjustedTime = benchmarkTimes[station] / assignedStrength;
    predictedStationTimes[station] = Math.round(adjustedTime);
    predictedTotalTime += adjustedTime;
  }

  // Add running time estimate (8km total, alternating 1km segments)
  const avgPace = (userA.avg_pace_per_km + userB.avg_pace_per_km) / 2; // seconds per km
  const runningTime = avgPace * 8;
  predictedTotalTime += runningTime;

  // 7. Generate race-day tips
  const warmupRecommendations = generateWarmupTips(assignments, userA, userB);
  const transitionTips = generateTransitionTips();
  const pacingStrategy = generatePacingStrategy(predictedTotalTime);

  // 8. Calculate confidence based on data quality
  const totalWorkouts = userAWorkouts.length + userBWorkouts.length;
  const confidenceScore = Math.min(totalWorkouts / 24, 1.0); // Full confidence with 12 weeks each

  // 9. Generate alternative strategies (e.g., swap 2-3 stations)
  const alternatives = generateAlternativeStrategies(assignments, userAStrengths, userBStrengths);

  // 10. Store strategy
  const version = await getNextStrategyVersion(input.partnership_id);
  await storeDoublesStrategy({
    partnership_id: input.partnership_id,
    version,
    is_current: true,
    station_assignments: assignments,
    assignment_reasoning: reasoning,
    predicted_total_time_seconds: Math.round(predictedTotalTime),
    predicted_station_times: predictedStationTimes,
    confidence_score: confidenceScore,
    alternative_strategies: alternatives,
    warmup_recommendations: warmupRecommendations,
    transition_tips: transitionTips,
    pacing_strategy: pacingStrategy
  });

  return {
    success: true,
    strategy: { /* full strategy object */ }
  };
}

function generateWarmupTips(assignments: Record<string, string>, userA: User, userB: User): string {
  const userAStations = Object.entries(assignments).filter(([_, userId]) => userId === userA.id).map(([station]) => station);
  const userBStations = Object.entries(assignments).filter(([_, userId]) => userId === userB.id).map(([station]) => station);

  return `
**${userA.name}'s warmup focus:**
- Emphasize ${userAStations.slice(0, 2).join(' and ')} movements
- Dynamic stretching for stations: ${userAStations.join(', ')}

**${userB.name}'s warmup focus:**
- Emphasize ${userBStations.slice(0, 2).join(' and ')} movements
- Dynamic stretching for stations: ${userBStations.join(', ')}

**Joint warmup:**
- 5min easy run together
- Practice transitions
- Communication check
  `.trim();
}

function generateTransitionTips(): string {
  return `
**Transition Strategy:**
1. **Hand-off communication**: Call out "30 seconds!" before finishing your station
2. **Staging**: Incoming runner should be at station entry 10 seconds before hand-off
3. **Quick start**: Outgoing runner hits the station immediately, no rest
4. **Hydration**: Grab water during partner's run, not during stations
5. **Gear prep**: Set up your next station during partner's current station

**Target transition time**: <10 seconds per hand-off
  `.trim();
}

function generatePacingStrategy(predictedTime: number): string {
  const targetPacePerKm = Math.round(predictedTime / 8 / 60 * 100) / 100; // minutes per km

  return `
**Pacing Guidelines:**
- **Target overall time**: ${formatTime(predictedTime)}
- **Target run pace**: ${targetPacePerKm} min/km (comfortable but controlled)
- **First 1km**: Go 5-10s slower than target pace (warm-up effect)
- **Middle 5km**: Hit target pace consistently
- **Last 2km**: Give it everything you have

**Station pacing:**
- Don't red-line early stations
- Consistent effort across all 8 stations
- Final 2 stations can be max effort
  `.trim();
}
```

### Milestone Detection

```typescript
// Check for partner milestones after each week's workouts
async function checkForMilestones(partnershipId: string, weekData: WeeklyComparisonData) {
  const milestones: Milestone[] = [];

  // 1. Check combined distance milestones (50km, 100km, 250km, 500km)
  const totalDistance = await getTotalCombinedDistance(partnershipId);
  const distanceMilestones = [50, 100, 250, 500, 1000];
  for (const milestone of distanceMilestones) {
    if (totalDistance >= milestone && !await hasMilestone(partnershipId, `combined_distance_${milestone}`)) {
      milestones.push({
        partnership_id: partnershipId,
        milestone_type: 'combined_distance',
        title: `${milestone}km Together!`,
        description: `You've trained ${milestone}km together as race partners`,
        achieved_value: totalDistance,
        achieved_at: new Date()
      });
    }
  }

  // 2. Check week completion (both completed all planned workouts)
  if (weekData.userAStats.workoutsCompleted === weekData.userAStats.workoutsPlanned &&
      weekData.userBStats.workoutsCompleted === weekData.userBStats.workoutsPlanned &&
      weekData.userAStats.workoutsCompleted > 0) {
    milestones.push({
      partnership_id: partnershipId,
      milestone_type: 'week_complete',
      title: 'Perfect Week!',
      description: 'Both of you completed all planned workouts this week',
      achieved_at: new Date()
    });
  }

  // 3. Check streak milestones (7 days, 14 days, 30 days)
  const currentStreak = await getCurrentStreak(partnershipId);
  const streakMilestones = [7, 14, 30, 60, 90];
  for (const milestone of streakMilestones) {
    if (currentStreak >= milestone && !await hasMilestone(partnershipId, `streak_${milestone}`)) {
      milestones.push({
        partnership_id: partnershipId,
        milestone_type: 'streak_milestone',
        title: `${milestone}-Day Streak!`,
        description: `You've both trained for ${milestone} consecutive days`,
        achieved_value: currentStreak,
        achieved_at: new Date()
      });
    }
  }

  // 4. Check if both set PRs in the same week
  if (await bothSetPRsThisWeek(partnershipId, weekData.week_starting)) {
    milestones.push({
      partnership_id: partnershipId,
      milestone_type: 'pr_together',
      title: 'PRs Together!',
      description: 'Both of you set personal records this week',
      achieved_at: new Date()
    });
  }

  // 5. Store all new milestones
  for (const milestone of milestones) {
    await storeMilestone(milestone);
    await sendMilestoneNotification(partnershipId, milestone);
  }
}
```

---

## Real-Time Features

### Push Notifications

```typescript
// Notification triggers
enum PartnerNotificationType {
  WORKOUT_COMPLETED = 'workout_completed',
  WORKOUT_STARTED = 'workout_started',
  MILESTONE_REACHED = 'milestone_reached',
  KUDOS_RECEIVED = 'kudos_received',
  PARTNER_REQUEST = 'partner_request',
  REQUEST_ACCEPTED = 'request_accepted',
  RACE_COUNTDOWN = 'race_countdown',
  TRAINING_GAP = 'training_gap',
  STRATEGY_UPDATED = 'strategy_updated'
}

interface PartnerNotification {
  type: PartnerNotificationType;
  partnershipId: string;
  senderId: string;
  recipientId: string;
  title: string;
  body: string;
  data?: any;
}

// Example: Send workout completion notification
async function notifyWorkoutCompleted(
  workoutId: string,
  userId: string
) {
  // Find active partnerships where notifications are enabled
  const partnerships = await getActivePartnerships(userId);

  for (const partnership of partnerships) {
    const partnerId = partnership.user_a_id === userId ? partnership.user_b_id : partnership.user_a_id;
    const permissions = await getPartnerPermissions(partnership.id, userId);
    const partnerPermissions = await getPartnerPermissions(partnership.id, partnerId);

    // Check if partner wants to be notified AND user has sharing enabled
    if (partnerPermissions.notifyWorkoutCompleted && permissions.shareWorkoutCompletion) {
      const user = await getUser(userId);
      const workout = await getWorkout(workoutId);

      await sendPushNotification({
        type: PartnerNotificationType.WORKOUT_COMPLETED,
        partnershipId: partnership.id,
        senderId: userId,
        recipientId: partnerId,
        title: `${user.name} completed a workout`,
        body: `${workout.type} · ${workout.total_duration_minutes} min`,
        data: {
          workoutId,
          partnershipId: partnership.id
        }
      });
    }
  }
}

// Race countdown notifications (3 days before, 1 day before, race day)
async function sendRaceCountdownNotifications() {
  const upcomingRaces = await getUpcomingRaces([3, 1, 0]); // 3 days, 1 day, today

  for (const race of upcomingRaces) {
    const partnership = race.partnership;
    const daysUntil = race.days_until;

    let message = '';
    if (daysUntil === 3) {
      message = '3 days until race day! Time to taper and prepare.';
    } else if (daysUntil === 1) {
      message = 'Race day tomorrow! Get your gear ready and visualize success.';
    } else {
      message = 'Race day is here! Go crush it together!';
    }

    await sendPushNotificationToBoth(partnership, {
      type: PartnerNotificationType.RACE_COUNTDOWN,
      title: race.race_name || 'HYROX Doubles',
      body: message,
      data: {
        partnershipId: partnership.id,
        raceDate: race.race_date
      }
    });
  }
}
```

### Real-Time Activity Feed (Supabase Realtime)

```typescript
// Subscribe to partner activity updates
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// iOS: Subscribe to partner interactions
supabase
  .channel('partner-activity')
  .on(
    'postgres_changes',
    {
      event: 'INSERT',
      schema: 'public',
      table: 'partner_interactions',
      filter: `partnership_id=eq.${partnershipId}`
    },
    (payload) => {
      // New activity from partner
      console.log('New partner activity:', payload.new);
      // Update UI with new activity
      updateActivityFeed(payload.new);
    }
  )
  .on(
    'postgres_changes',
    {
      event: 'INSERT',
      schema: 'public',
      table: 'partner_kudos',
      filter: `receiver_user_id=eq.${currentUserId}`
    },
    (payload) => {
      // Received kudos from partner
      console.log('Kudos received:', payload.new);
      showKudosNotification(payload.new);
    }
  )
  .subscribe();
```

---

## Implementation Phases

### Phase 1: Core Partnership (Week 1-2)
- Database schema setup (migrations)
- Basic API endpoints (request, accept, list)
- iOS: Partner list view
- iOS: Add partner view (search only)
- iOS: Partner request view
- Testing: Create and accept partnerships

### Phase 2: Dashboard & Permissions (Week 3-4)
- Permission system implementation
- Partner dashboard API
- Weekly comparison snapshots (cron job)
- iOS: Partner dashboard view
- iOS: Partner settings view
- Testing: Dashboard loading and permissions

### Phase 3: Activity Feed & Engagement (Week 5)
- Partner interactions tracking
- Kudos system
- Activity feed API
- iOS: Activity feed in dashboard
- Push notifications for major events
- Testing: Real-time updates

### Phase 4: Analytics & Insights (Week 6-7)
- Station strength calculation
- Complementary strength algorithm
- Training gap scoring
- Milestone detection
- iOS: Week comparison cards
- iOS: Milestone celebrations
- Testing: Analytics accuracy

### Phase 5: Doubles Strategy (Week 8-9)
- Doubles strategy generation (Edge Function)
- Strategy recommendation storage
- Alternative strategies
- iOS: Doubles strategy view
- iOS: Strategy detail view
- Testing: Strategy accuracy and updates

### Phase 6: Invite Codes & QR (Week 10)
- Invite code generation
- QR code support
- Deep linking
- iOS: Create invite code view
- iOS: QR scanner
- Testing: Code redemption flow

### Phase 7: Polish & Optimization (Week 11-12)
- Performance optimization
- UI polish and animations
- Error handling improvements
- Comprehensive testing
- Beta testing with real users
- Documentation

---

## Architecture Decision Records

### ADR-001: Partnership Canonical Ordering

**Status**: Accepted

**Context**:
We need to store partnerships between two users. A naive approach would create two rows (A→B and B→A), but this complicates queries and can cause data inconsistency.

**Decision**:
Enforce canonical ordering where `user_a_id < user_b_id` (UUID comparison). Add database constraint to enforce this. Create a view `user_partnerships` to abstract the ordering complexity from clients.

**Consequences**:
- **Positive**: Single source of truth, no duplicate partnerships, simpler queries
- **Negative**: Clients must handle ordering logic (mitigated by view)
- **Mitigation**: Provide helper functions in API layer

---

### ADR-002: Permission Model - Per-User, Not Per-Partnership

**Status**: Accepted

**Context**:
Partners may want asymmetric sharing (e.g., User A shares videos, User B doesn't). Should permissions be per-partnership or per-user?

**Decision**:
Store permissions per-user within a partnership (`partner_permissions` has one row per user, keyed by `partnership_id + user_id`). Each user controls what THEY share.

**Consequences**:
- **Positive**: Maximum flexibility, clear ownership, easy to understand
- **Negative**: Slightly more complex queries (need to join twice to get both users' permissions)
- **Mitigation**: API layer abstracts this complexity

---

### ADR-003: Pre-Computed Weekly Snapshots

**Status**: Accepted

**Context**:
Calculating partner comparisons on-demand (aggregating weeks of workout data) is expensive and slow. Users expect instant dashboard loading.

**Decision**:
Run a weekly cron job (Supabase Edge Function) to pre-compute comparison snapshots and store in `partner_comparison_snapshots` table. Dashboard queries this table.

**Consequences**:
- **Positive**: Fast dashboard loading (<100ms), consistent calculations
- **Negative**: Data is up to 1 week stale, requires cron job maintenance
- **Mitigation**: Show "current week in progress" separately with live data

---

### ADR-004: Doubles Strategy Versioning

**Status**: Accepted

**Context**:
Doubles strategy should evolve as partners train. But we don't want to constantly re-generate (expensive AI calls) or lose historical strategies.

**Decision**:
Store strategy versions in `doubles_strategy_recommendations` with `version` and `is_current` fields. Generate new version every 2 weeks or on manual request (rate-limited to once per week). Keep last 5 versions for history.

**Consequences**:
- **Positive**: Strategy improves over time, users can see progression, rate-limiting controls costs
- **Negative**: More complex queries (need `WHERE is_current = true`)
- **Mitigation**: Index on `(partnership_id, is_current)`

---

### ADR-005: Milestone Detection via Cron, Not Triggers

**Status**: Accepted

**Context**:
Milestones (e.g., "100km together") could be detected via database triggers or via periodic batch processing.

**Decision**:
Use weekly cron job to check for milestones. Store in `partner_milestones` table and send notifications asynchronously.

**Consequences**:
- **Positive**: Simpler architecture, no complex triggers, easier to test
- **Negative**: Milestones detected with up to 1-week delay
- **Mitigation**: For critical milestones (e.g., perfect week), check during snapshot calculation

---

### ADR-006: Activity Feed Real-Time via Supabase Realtime

**Status**: Accepted

**Context**:
Partner activity feed should feel live (e.g., "Your partner just completed a workout"). Options: polling, WebSockets, or Supabase Realtime.

**Decision**:
Use Supabase Realtime subscriptions to `partner_interactions` and `partner_kudos` tables. iOS app subscribes when partner dashboard is visible.

**Consequences**:
- **Positive**: True real-time updates, leverages Supabase infrastructure, low latency
- **Negative**: Requires connection management, potential battery impact
- **Mitigation**: Only subscribe when dashboard is active, unsubscribe on background

---

### ADR-007: Invite Codes as First-Class Feature

**Status**: Accepted

**Context**:
Searching for partners by name/email has privacy concerns (enumeration attacks). QR codes work in-person but not remotely.

**Decision**:
Implement shareable invite codes as the PRIMARY partner linking method. Codes are short (e.g., "ALEX-RACE-2025"), user-friendly, and work via deep links.

**Consequences**:
- **Positive**: Privacy-friendly, works in all contexts, shareable via any channel
- **Negative**: Requires code generation logic, potential for code collisions (mitigated by UNIQUE constraint)
- **Mitigation**: Generate codes with format `{FIRST_NAME}-{WORD}-{YEAR}` for memorability

---

### ADR-008: Station Strengths Normalized 0-1

**Status**: Accepted

**Context**:
Station strengths can be measured in absolute terms (seconds per rep) or relative terms (percentile vs benchmark). How to store?

**Decision**:
Store as normalized 0-1 score where 1.0 = elite level (top 5%), 0.7 = average, 0.5 = beginner. Calculate based on ratio of actual vs benchmark times.

**Consequences**:
- **Positive**: Comparable across stations, easy to visualize, language-agnostic
- **Negative**: Requires benchmark data for each station
- **Mitigation**: Use HYROX official times as benchmarks, adjust over time with user data

---

## Success Metrics & KPIs

### Adoption Metrics
- **Partner Connection Rate**: % of users with at least 1 active partnership (Target: 40%)
- **Doubles vs Training Partner Ratio**: % of partnerships that are race-focused (Target: 60%)
- **Invite Code Redemption Rate**: % of generated codes that are redeemed (Target: 70%)

### Engagement Metrics
- **Daily Partner Dashboard Views**: Avg views per user per day (Target: 2+)
- **Kudos Exchange Rate**: % of workouts that receive kudos from partner (Target: 30%)
- **Weekly Comparison Views**: % of users viewing comparisons (Target: 80%)

### Retention Metrics
- **Partner Retention**: % of partnerships still active after 90 days (Target: 75%)
- **Partnered vs Solo Retention**: Lift in 90-day retention for partnered users (Target: +25%)
- **Race Completion Rate**: % of doubled partnerships that complete their target race (Target: 85%)

### Performance Metrics
- **Dashboard Load Time**: P95 load time for partner dashboard (Target: <500ms)
- **Notification Delivery**: % of notifications delivered within 30s (Target: 95%)
- **Strategy Generation Time**: Avg time to generate doubles strategy (Target: <15s)

---

## Security Considerations

### Data Privacy
1. **Explicit Consent**: All data sharing requires explicit permission flags
2. **Granular Controls**: Users control exactly what they share (not all-or-nothing)
3. **Revocable Access**: Ending a partnership immediately revokes all data access
4. **Audit Trail**: Log all partner data accesses for security review

### API Security
1. **Authentication**: All endpoints require valid Supabase session
2. **Authorization**: Server-side permission checks on every data request
3. **Rate Limiting**: Limit API calls to prevent abuse (100 req/min per user)
4. **Input Validation**: Validate all inputs (partnership IDs, permissions, etc.)

### Database Security
1. **Row-Level Security (RLS)**: Enable RLS on all partner tables
2. **RLS Policies**: Users can only access partnerships they're part of
3. **Cascade Deletes**: Deleting user removes all partnership data
4. **Encrypted PII**: Email and names encrypted at rest

---

## Conclusion

The Race Partner system is a comprehensive feature that enhances FLEXR's value proposition by adding social accountability and strategic planning for HYROX Doubles athletes. The architecture balances real-time engagement with performance optimization, provides granular privacy controls, and leverages AI for meaningful insights.

**Key Differentiators**:
1. **Complementary Strength Analysis**: Unique algorithm to identify optimal doubles pairings
2. **AI-Powered Strategy**: Automated race strategy based on actual performance data
3. **Privacy-First**: Granular permissions with sensible defaults
4. **Engagement-Focused**: Real-time activity feed, kudos system, milestone celebrations

**Technical Highlights**:
- Pre-computed snapshots for instant dashboard loading
- Supabase Realtime for live activity updates
- Versioned AI strategies that evolve with training
- Invite codes as primary linking mechanism (privacy-friendly)

This system is production-ready and can be implemented in ~12 weeks following the phased rollout plan.

---

**Document Version**: 1.0
**Last Updated**: 2025-12-03
**Author**: System Architecture Team
**Status**: Ready for Implementation
