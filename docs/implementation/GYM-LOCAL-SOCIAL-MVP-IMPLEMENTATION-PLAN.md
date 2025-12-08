# Gym-Local Social MVP - Implementation Plan

**Timeline**: 4-6 weeks
**Target**: Q1 2026 Launch
**Status**: Planning Phase

---

## Executive Summary

This plan delivers a privacy-first, gym-scoped social layer for FLEXR, enabling members to connect, compete, and progress together within their physical training community. The MVP focuses on local discovery, friendly competition, and collaborative training without global social noise.

### Core Value Proposition
- Find training partners at your gym
- Compare workout performance with gym members
- Track progress together through races
- Celebrate achievements within your community

---

## Table of Contents

1. [Phase Breakdown](#phase-breakdown)
2. [Technical Architecture](#technical-architecture)
3. [Week-by-Week Roadmap](#week-by-week-roadmap)
4. [Database Schema](#database-schema)
5. [API Endpoints](#api-endpoints)
6. [iOS Implementation](#ios-implementation)
7. [Testing Strategy](#testing-strategy)
8. [Risk Mitigation](#risk-mitigation)
9. [Success Metrics](#success-metrics)
10. [Future Expansion](#future-expansion)

---

## Phase Breakdown

### Phase 1A: Foundation (Week 1-2) - 70 hours
**Goal**: Gym system + member discovery
**Deliverable**: Users can join/claim gyms and see who trains there

**Features**:
- Gym profiles (name, location, logo, member count)
- Gym join/claim flow
- Member directory (privacy-respecting)
- Basic gym settings

**Why First**: Foundation for all social features. Cannot build leaderboards or comparisons without gym membership.

---

### Phase 1B: Comparison Tools (Week 3) - 35 hours
**Goal**: Workout comparison functionality
**Deliverable**: Side-by-side workout analysis for gym members

**Features**:
- Interval comparison (splits, paces)
- Station time comparison
- Workout summary comparison
- Performance delta visualization

**Why Second**: High value, low complexity. Uses existing workout data.

---

### Phase 2A: Leaderboards (Week 4) - 40 hours
**Goal**: Gym-scoped competitive rankings
**Deliverable**: Real leaderboards showing gym member rankings

**Features**:
- Weekly fastest times (Full Sim, Half Sim)
- Station-specific leaderboards (fastest SkiErg, Sled, etc.)
- All-time best performances
- Personal rank tracking

**Why Third**: Requires comparison tools to work. High engagement driver.

---

### Phase 2B: Race Partners (Week 5) - 35 hours
**Goal**: Long-term progression tracking with partners
**Deliverable**: Link with race partners and track mutual progress

**Features**:
- Partner linking (mutual approval)
- Shared race countdown
- Partner progress feed
- Weekly check-in notifications

**Why Fourth**: Builds on existing social foundation. Retention driver.

---

### Phase 3: Activity Feed (Week 6) - 30 hours
**Goal**: Gym-scoped activity stream
**Deliverable**: See recent workouts and achievements from gym members

**Features**:
- Workout posts (auto-generated from completed workouts)
- Achievement announcements (PRs, streaks)
- Kudos/reactions
- Privacy controls (who can see my activity)

**Why Last**: Polish feature that leverages all prior work. Can launch without if needed.

---

## Technical Architecture

### System Components

```
┌─────────────────────────────────────────────────┐
│              iOS App (Swift)                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │  Gym     │  │ Members  │  │ Activity │      │
│  │  Views   │  │  Views   │  │  Feed    │      │
│  └──────────┘  └──────────┘  └──────────┘      │
│         │              │              │         │
│         └──────────────┴──────────────┘         │
│                      │                          │
└──────────────────────┼──────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────┐
│         Backend API (Node.js/TypeScript)        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │   Gym    │  │  Social  │  │ Privacy  │      │
│  │ Service  │  │ Service  │  │  Layer   │      │
│  └──────────┘  └──────────┘  └──────────┘      │
└──────────────────────┼──────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────┐
│        Database (Supabase/PostgreSQL)           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │  Gyms    │  │ Members  │  │ Activity │      │
│  │  Table   │  │  Table   │  │  Table   │      │
│  └──────────┘  └──────────┘  └──────────┘      │
└─────────────────────────────────────────────────┘
```

### Privacy Architecture

**Core Principle**: Gym-scoped by default. No global leaderboards or discovery.

**Privacy Levels**:
1. **Public to Gym**: Default. Visible to all gym members
2. **Friends Only**: Only visible to race partners
3. **Private**: Hidden from all social features

**Implementation**:
- Row-Level Security (RLS) policies enforce gym boundaries
- User privacy settings stored in user_privacy_settings table
- All queries filtered by gym_id and privacy_level
- No cross-gym data leakage

---

## Week-by-Week Roadmap

### Week 1: Database + Gym System (35 hours)

**Monday-Tuesday: Database Schema (14h)**
- [ ] Design gym system tables (gyms, gym_memberships, gym_admins)
- [ ] Design privacy tables (user_privacy_settings, blocked_users)
- [ ] Design leaderboard tables (gym_leaderboards, leaderboard_entries)
- [ ] Design activity feed tables (gym_activities, activity_reactions)
- [ ] Design race partner tables (race_partnerships)
- [ ] Write migration 012_gym_social_foundation.sql
- [ ] Write RLS policies for gym-scoping
- [ ] Test migrations locally

**Wednesday: Gym Backend Services (7h)**
- [ ] Create gym model (backend/src/models/gym.model.ts)
- [ ] Create gym service (backend/src/services/gym.service.ts)
- [ ] Implement gym CRUD operations
- [ ] Implement gym claim logic (admin verification)
- [ ] Write unit tests

**Thursday-Friday: Gym iOS Models + UI (14h)**
- [ ] Create Gym.swift model
- [ ] Create GymMembership.swift model
- [ ] Create GymService.swift
- [ ] Build GymSearchView (search gyms by name/location)
- [ ] Build GymProfileView (show gym details, member count)
- [ ] Build JoinGymView (join flow)
- [ ] Build ClaimGymView (gym owner verification)

**Deliverable**: Users can search, join, and claim gyms.

---

### Week 2: Member Discovery (35 hours)

**Monday-Tuesday: Member Backend (14h)**
- [ ] Create member directory service
- [ ] Implement member search (filter by name, experience level)
- [ ] Implement privacy filtering (respect user settings)
- [ ] Create member profile endpoint
- [ ] Add member count aggregation
- [ ] Write unit tests

**Wednesday-Thursday: Member iOS Views (14h)**
- [ ] Create GymMemberListView (directory)
- [ ] Create GymMemberProfileView (public profile)
- [ ] Create MemberFilterSheet (filter by experience, activity level)
- [ ] Add search functionality
- [ ] Add privacy controls to user settings
- [ ] Implement profile privacy toggle

**Friday: Integration + Testing (7h)**
- [ ] End-to-end test: Join gym → See members → View profile
- [ ] Test privacy settings (private users hidden)
- [ ] Test performance (1000+ member gym)
- [ ] Fix bugs
- [ ] Update documentation

**Deliverable**: Users can see and search gym members with privacy controls.

---

### Week 3: Comparison Tools (35 hours)

**Monday: Comparison Data Model (7h)**
- [ ] Design WorkoutComparison model (backend + iOS)
- [ ] Create comparison service (backend/src/services/comparison.service.ts)
- [ ] Implement interval comparison logic
- [ ] Implement station comparison logic
- [ ] Write unit tests for delta calculations

**Tuesday-Wednesday: Comparison API (14h)**
- [ ] POST /api/v1/comparisons/create (create comparison session)
- [ ] GET /api/v1/comparisons/:id (get comparison data)
- [ ] POST /api/v1/comparisons/:id/workouts (add workout to comparison)
- [ ] GET /api/v1/comparisons/available-workouts (list comparable workouts)
- [ ] Implement caching for comparison data
- [ ] Write API tests

**Thursday-Friday: Comparison iOS Views (14h)**
- [ ] Create ComparisonSelectionView (select workouts to compare)
- [ ] Create WorkoutComparisonView (side-by-side view)
- [ ] Create IntervalComparisonRow (visual splits comparison)
- [ ] Create StationComparisonRow (station time deltas)
- [ ] Add performance delta indicators (+/- seconds, % difference)
- [ ] Add share comparison feature

**Deliverable**: Users can compare workouts side-by-side with gym members.

---

### Week 4: Leaderboards (40 hours)

**Monday-Tuesday: Leaderboard Backend (14h)**
- [ ] Create leaderboard service (backend/src/services/leaderboard.service.ts)
- [ ] Implement leaderboard calculation job (runs daily)
- [ ] Weekly fastest times (Full Sim, Half Sim, Station Focus)
- [ ] All-time PRs
- [ ] Station-specific leaderboards (SkiErg, Sled, Row, etc.)
- [ ] Personal rank calculation
- [ ] Write tests

**Wednesday: Leaderboard API (7h)**
- [ ] GET /api/v1/gyms/:id/leaderboards/weekly
- [ ] GET /api/v1/gyms/:id/leaderboards/all-time
- [ ] GET /api/v1/gyms/:id/leaderboards/stations/:station
- [ ] GET /api/v1/users/me/rankings (my ranks across all boards)
- [ ] Implement pagination (top 100 per board)
- [ ] Write API tests

**Thursday-Friday: Leaderboard iOS Views (19h)**
- [ ] Create GymLeaderboardsView (tab view: Weekly, All-Time, Stations)
- [ ] Create LeaderboardList (ranked list with avatars, times, deltas)
- [ ] Create LeaderboardEntryRow (single entry with rank, name, time)
- [ ] Create MyRankingsSummaryView (your position across boards)
- [ ] Create StationLeaderboardSelector (choose station)
- [ ] Add podium UI (1st, 2nd, 3rd special styling)
- [ ] Add "View Workout" deep link from leaderboard entry
- [ ] Polish animations and loading states

**Deliverable**: Real-time gym leaderboards with personal rankings.

---

### Week 5: Race Partners (35 hours)

**Monday: Partner Backend (7h)**
- [ ] Create race partnership service
- [ ] Implement partner request flow (send, accept, decline)
- [ ] Implement shared race countdown
- [ ] Create partner activity feed query
- [ ] Write tests

**Tuesday: Partner API (7h)**
- [ ] POST /api/v1/race-partners/request (send partner request)
- [ ] POST /api/v1/race-partners/:id/accept
- [ ] POST /api/v1/race-partners/:id/decline
- [ ] GET /api/v1/race-partners (my partners)
- [ ] GET /api/v1/race-partners/:id/progress (shared progress)
- [ ] DELETE /api/v1/race-partners/:id (remove partner)

**Wednesday-Thursday: Partner iOS Views (14h)**
- [ ] Create RacePartnersView (list of partners)
- [ ] Create PartnerRequestView (send request)
- [ ] Create PartnerProfileView (partner detail + shared race info)
- [ ] Create PartnerProgressView (shared countdown, recent workouts)
- [ ] Create PartnerActivityRow (partner workout summary)
- [ ] Add partner notification badges

**Friday: Integration + Testing (7h)**
- [ ] End-to-end test: Send request → Accept → View progress
- [ ] Test notification flow
- [ ] Test privacy (ensure only partners see private workouts)
- [ ] Fix bugs

**Deliverable**: Race partner linking with shared progress tracking.

---

### Week 6: Activity Feed + Polish (30 hours)

**Monday: Activity Feed Backend (7h)**
- [ ] Create activity feed service
- [ ] Implement auto-post on workout completion
- [ ] Implement achievement detection (PR, streak, etc.)
- [ ] Implement kudos/reactions
- [ ] Write tests

**Tuesday: Activity Feed API (7h)**
- [ ] GET /api/v1/gyms/:id/feed (gym activity feed)
- [ ] POST /api/v1/feed/posts (manual post)
- [ ] POST /api/v1/feed/:id/kudos (give kudos)
- [ ] DELETE /api/v1/feed/:id (delete post)
- [ ] Implement feed pagination (infinite scroll)

**Wednesday-Thursday: Activity Feed iOS Views (12h)**
- [ ] Create GymFeedView (scrollable feed)
- [ ] Create FeedItemRow (workout post, achievement post)
- [ ] Create KudosButton (animated kudos)
- [ ] Create PostDetailView (view full workout from feed)
- [ ] Add pull-to-refresh
- [ ] Add feed filters (workouts only, achievements only, partners only)

**Friday: Final Polish + Launch Prep (4h)**
- [ ] UI/UX polish (animations, transitions)
- [ ] Performance testing (large gyms, long feeds)
- [ ] Security audit (privacy leaks, SQL injection)
- [ ] Documentation (user guide, admin guide)
- [ ] App Store screenshots
- [ ] Submit for review

**Deliverable**: Complete gym-local social MVP ready for launch.

---

## Database Schema

### Migration 012: Gym Social Foundation

```sql
-- ============================================
-- GYMS SYSTEM
-- ============================================

-- Gyms table
CREATE TABLE IF NOT EXISTS gyms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  city TEXT NOT NULL,
  state TEXT,
  country TEXT NOT NULL,
  postal_code TEXT,
  latitude NUMERIC(10, 8),
  longitude NUMERIC(11, 8),
  logo_url TEXT,
  verified BOOLEAN DEFAULT false,
  member_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_gyms_location ON gyms(city, state, country);
CREATE INDEX idx_gyms_verified ON gyms(verified);

-- Gym memberships
CREATE TABLE IF NOT EXISTS gym_memberships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  gym_id UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  is_active BOOLEAN DEFAULT true,
  is_admin BOOLEAN DEFAULT false,
  UNIQUE(user_id, gym_id)
);

CREATE INDEX idx_gym_memberships_user ON gym_memberships(user_id);
CREATE INDEX idx_gym_memberships_gym ON gym_memberships(gym_id, is_active);
CREATE INDEX idx_gym_memberships_admin ON gym_memberships(gym_id, is_admin);

-- Update member count trigger
CREATE OR REPLACE FUNCTION update_gym_member_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.is_active THEN
    UPDATE gyms SET member_count = member_count + 1 WHERE id = NEW.gym_id;
  ELSIF TG_OP = 'UPDATE' AND NEW.is_active != OLD.is_active THEN
    IF NEW.is_active THEN
      UPDATE gyms SET member_count = member_count + 1 WHERE id = NEW.gym_id;
    ELSE
      UPDATE gyms SET member_count = member_count - 1 WHERE id = NEW.gym_id;
    END IF;
  ELSIF TG_OP = 'DELETE' AND OLD.is_active THEN
    UPDATE gyms SET member_count = member_count - 1 WHERE id = OLD.gym_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER gym_member_count_trigger
AFTER INSERT OR UPDATE OR DELETE ON gym_memberships
FOR EACH ROW EXECUTE FUNCTION update_gym_member_count();

-- ============================================
-- PRIVACY SYSTEM
-- ============================================

-- User privacy settings
CREATE TABLE IF NOT EXISTS user_privacy_settings (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  profile_visibility TEXT DEFAULT 'gym' CHECK (profile_visibility IN ('gym', 'friends', 'private')),
  workout_visibility TEXT DEFAULT 'gym' CHECK (workout_visibility IN ('gym', 'friends', 'private')),
  leaderboard_visible BOOLEAN DEFAULT true,
  allow_partner_requests BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Blocked users
CREATE TABLE IF NOT EXISTS blocked_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(blocker_id, blocked_id)
);

CREATE INDEX idx_blocked_users_blocker ON blocked_users(blocker_id);

-- ============================================
-- LEADERBOARDS
-- ============================================

-- Gym leaderboards (weekly, all-time, per-station)
CREATE TABLE IF NOT EXISTS gym_leaderboards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gym_id UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
  leaderboard_type TEXT NOT NULL CHECK (leaderboard_type IN ('weekly', 'all_time', 'station')),
  workout_type TEXT CHECK (workout_type IN ('full_simulation', 'half_simulation', 'station_focus', 'running', 'custom')),
  station_type TEXT CHECK (station_type IN ('skierg', 'sled_push', 'sled_pull', 'burpee_broad_jump', 'row', 'farmers_carry', 'sandbag_lunges', 'wall_balls')),
  week_starting DATE, -- NULL for all-time
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(gym_id, leaderboard_type, workout_type, station_type, week_starting)
);

CREATE INDEX idx_gym_leaderboards_gym_type ON gym_leaderboards(gym_id, leaderboard_type);
CREATE INDEX idx_gym_leaderboards_week ON gym_leaderboards(gym_id, week_starting);

-- Leaderboard entries
CREATE TABLE IF NOT EXISTS leaderboard_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  leaderboard_id UUID NOT NULL REFERENCES gym_leaderboards(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
  rank INTEGER NOT NULL,
  time_seconds NUMERIC(10, 2) NOT NULL,
  completed_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(leaderboard_id, user_id)
);

CREATE INDEX idx_leaderboard_entries_board ON leaderboard_entries(leaderboard_id, rank);
CREATE INDEX idx_leaderboard_entries_user ON leaderboard_entries(user_id);

-- ============================================
-- RACE PARTNERSHIPS
-- ============================================

-- Race partnerships
CREATE TABLE IF NOT EXISTS race_partnerships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  gym_id UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
  race_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  accepted_at TIMESTAMPTZ,
  UNIQUE(requester_id, receiver_id),
  CHECK(requester_id != receiver_id)
);

CREATE INDEX idx_race_partnerships_requester ON race_partnerships(requester_id, status);
CREATE INDEX idx_race_partnerships_receiver ON race_partnerships(receiver_id, status);
CREATE INDEX idx_race_partnerships_gym ON race_partnerships(gym_id);

-- ============================================
-- ACTIVITY FEED
-- ============================================

-- Gym activities
CREATE TABLE IF NOT EXISTS gym_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gym_id UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  activity_type TEXT NOT NULL CHECK (activity_type IN ('workout_completed', 'achievement', 'pr', 'streak', 'manual_post')),
  workout_id UUID REFERENCES workouts(id) ON DELETE CASCADE,
  content JSONB, -- Flexible content: { title, description, stats, etc. }
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_gym_activities_gym ON gym_activities(gym_id, created_at DESC);
CREATE INDEX idx_gym_activities_user ON gym_activities(user_id, created_at DESC);

-- Activity reactions (kudos)
CREATE TABLE IF NOT EXISTS activity_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  activity_id UUID NOT NULL REFERENCES gym_activities(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reaction_type TEXT DEFAULT 'kudos' CHECK (reaction_type IN ('kudos', 'fire', 'strong', 'fast')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(activity_id, user_id)
);

CREATE INDEX idx_activity_reactions_activity ON activity_reactions(activity_id);

-- ============================================
-- ROW-LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS on all social tables
ALTER TABLE gyms ENABLE ROW LEVEL SECURITY;
ALTER TABLE gym_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_privacy_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE gym_leaderboards ENABLE ROW LEVEL SECURITY;
ALTER TABLE leaderboard_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE race_partnerships ENABLE ROW LEVEL SECURITY;
ALTER TABLE gym_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_reactions ENABLE ROW LEVEL SECURITY;

-- Gyms: Public read, admin write
CREATE POLICY gyms_public_read ON gyms FOR SELECT USING (true);
CREATE POLICY gyms_admin_write ON gyms FOR ALL USING (
  id IN (SELECT gym_id FROM gym_memberships WHERE user_id = auth.uid() AND is_admin = true)
);

-- Gym memberships: Members can see gym members
CREATE POLICY gym_memberships_members_read ON gym_memberships FOR SELECT USING (
  gym_id IN (SELECT gym_id FROM gym_memberships WHERE user_id = auth.uid() AND is_active = true)
);
CREATE POLICY gym_memberships_self_write ON gym_memberships FOR ALL USING (user_id = auth.uid());

-- Privacy settings: Own settings only
CREATE POLICY privacy_settings_self ON user_privacy_settings FOR ALL USING (user_id = auth.uid());

-- Leaderboards: Gym members only
CREATE POLICY leaderboards_gym_read ON gym_leaderboards FOR SELECT USING (
  gym_id IN (SELECT gym_id FROM gym_memberships WHERE user_id = auth.uid() AND is_active = true)
);

CREATE POLICY leaderboard_entries_gym_read ON leaderboard_entries FOR SELECT USING (
  leaderboard_id IN (
    SELECT l.id FROM gym_leaderboards l
    JOIN gym_memberships m ON l.gym_id = m.gym_id
    WHERE m.user_id = auth.uid() AND m.is_active = true
  )
);

-- Race partnerships: Requester/receiver only
CREATE POLICY partnerships_self ON race_partnerships FOR ALL USING (
  requester_id = auth.uid() OR receiver_id = auth.uid()
);

-- Activities: Gym members only
CREATE POLICY activities_gym_read ON gym_activities FOR SELECT USING (
  gym_id IN (SELECT gym_id FROM gym_memberships WHERE user_id = auth.uid() AND is_active = true)
);
CREATE POLICY activities_self_write ON gym_activities FOR INSERT USING (user_id = auth.uid());
CREATE POLICY activities_self_delete ON gym_activities FOR DELETE USING (user_id = auth.uid());

-- Reactions: Gym members only
CREATE POLICY reactions_gym_read ON activity_reactions FOR SELECT USING (
  activity_id IN (
    SELECT a.id FROM gym_activities a
    JOIN gym_memberships m ON a.gym_id = m.gym_id
    WHERE m.user_id = auth.uid() AND m.is_active = true
  )
);
CREATE POLICY reactions_self_write ON activity_reactions FOR ALL USING (user_id = auth.uid());

-- ============================================
-- TRIGGERS
-- ============================================

-- Auto-create privacy settings for new users
CREATE OR REPLACE FUNCTION create_default_privacy_settings()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO user_privacy_settings (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER user_privacy_settings_trigger
AFTER INSERT ON users
FOR EACH ROW EXECUTE FUNCTION create_default_privacy_settings();

-- Auto-post workout completion to activity feed
CREATE OR REPLACE FUNCTION auto_post_workout_completion()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
    INSERT INTO gym_activities (gym_id, user_id, activity_type, workout_id, content)
    SELECT
      gm.gym_id,
      NEW.user_id,
      'workout_completed',
      NEW.id,
      jsonb_build_object(
        'workout_type', NEW.type,
        'duration_minutes', NEW.total_duration_minutes,
        'title', NEW.title
      )
    FROM gym_memberships gm
    WHERE gm.user_id = NEW.user_id AND gm.is_active = true;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER workout_completion_post_trigger
AFTER UPDATE ON workouts
FOR EACH ROW EXECUTE FUNCTION auto_post_workout_completion();
```

---

## API Endpoints

### Gym Endpoints

```typescript
// Gym Management
GET    /api/v1/gyms                        // Search gyms (query: name, city, country)
GET    /api/v1/gyms/:id                    // Get gym details
POST   /api/v1/gyms                        // Create gym (admin only)
PATCH  /api/v1/gyms/:id                    // Update gym (admin only)
DELETE /api/v1/gyms/:id                    // Delete gym (admin only)

// Gym Membership
GET    /api/v1/gyms/:id/members            // List gym members (paginated)
POST   /api/v1/gyms/:id/join               // Join gym
POST   /api/v1/gyms/:id/leave              // Leave gym
POST   /api/v1/gyms/:id/claim              // Claim gym ownership (requires verification)

// Gym Discovery
GET    /api/v1/gyms/nearby                 // Find gyms near lat/lng (query: latitude, longitude, radius)
GET    /api/v1/users/me/gyms               // My gym memberships
```

### Member Endpoints

```typescript
// Member Directory
GET    /api/v1/gyms/:id/members            // List gym members (paginated, filterable)
GET    /api/v1/gyms/:id/members/:userId    // Get member public profile

// Search & Filter
GET    /api/v1/gyms/:id/members/search     // Search members (query: name, experience_level)
```

### Comparison Endpoints

```typescript
// Workout Comparison
POST   /api/v1/comparisons                 // Create comparison session
GET    /api/v1/comparisons/:id             // Get comparison data
POST   /api/v1/comparisons/:id/workouts    // Add workout to comparison
GET    /api/v1/comparisons/available       // List comparable workouts (query: gym_id, workout_type)
```

### Leaderboard Endpoints

```typescript
// Leaderboards
GET    /api/v1/gyms/:id/leaderboards/weekly          // Weekly leaderboard
GET    /api/v1/gyms/:id/leaderboards/all-time        // All-time leaderboard
GET    /api/v1/gyms/:id/leaderboards/stations/:type  // Station-specific leaderboard
GET    /api/v1/users/me/rankings                     // My rankings across all boards

// Leaderboard Admin
POST   /api/v1/gyms/:id/leaderboards/recalculate     // Trigger recalculation (admin only)
```

### Race Partner Endpoints

```typescript
// Race Partnerships
GET    /api/v1/race-partners                // List my race partners
POST   /api/v1/race-partners/request        // Send partner request
POST   /api/v1/race-partners/:id/accept     // Accept partner request
POST   /api/v1/race-partners/:id/decline    // Decline partner request
DELETE /api/v1/race-partners/:id            // Remove partner
GET    /api/v1/race-partners/:id/progress   // Get shared progress
```

### Activity Feed Endpoints

```typescript
// Activity Feed
GET    /api/v1/gyms/:id/feed               // Gym activity feed (paginated)
POST   /api/v1/feed/posts                  // Create manual post
DELETE /api/v1/feed/:id                    // Delete post (own posts only)
POST   /api/v1/feed/:id/kudos              // Give kudos
DELETE /api/v1/feed/:id/kudos              // Remove kudos
```

### Privacy Endpoints

```typescript
// Privacy Settings
GET    /api/v1/users/me/privacy            // Get privacy settings
PATCH  /api/v1/users/me/privacy            // Update privacy settings
POST   /api/v1/users/block/:userId         // Block user
DELETE /api/v1/users/block/:userId         // Unblock user
GET    /api/v1/users/blocked               // List blocked users
```

---

## iOS Implementation

### New Files to Create

```
ios/FLEXR/Sources/
├── Features/
│   └── Social/
│       ├── Gym/
│       │   ├── GymSearchView.swift
│       │   ├── GymProfileView.swift
│       │   ├── JoinGymView.swift
│       │   ├── ClaimGymView.swift
│       │   └── GymMemberListView.swift
│       ├── Comparison/
│       │   ├── ComparisonSelectionView.swift
│       │   ├── WorkoutComparisonView.swift
│       │   ├── IntervalComparisonRow.swift
│       │   └── StationComparisonRow.swift
│       ├── Leaderboards/
│       │   ├── GymLeaderboardsView.swift
│       │   ├── LeaderboardList.swift
│       │   ├── LeaderboardEntryRow.swift
│       │   └── MyRankingsSummaryView.swift
│       ├── Partners/
│       │   ├── RacePartnersView.swift
│       │   ├── PartnerRequestView.swift
│       │   ├── PartnerProfileView.swift
│       │   └── PartnerProgressView.swift
│       └── Feed/
│           ├── GymFeedView.swift
│           ├── FeedItemRow.swift
│           ├── KudosButton.swift
│           └── PostDetailView.swift
├── Core/
│   ├── Models/
│   │   ├── Gym.swift
│   │   ├── GymMembership.swift
│   │   ├── WorkoutComparison.swift
│   │   ├── Leaderboard.swift
│   │   ├── RacePartnership.swift
│   │   ├── GymActivity.swift
│   │   └── UserPrivacySettings.swift
│   └── Services/
│       ├── GymService.swift
│       ├── SocialService.swift
│       └── PrivacyService.swift
└── UI/
    └── Components/
        ├── GymBadge.swift
        ├── MemberAvatar.swift
        ├── LeaderboardRankBadge.swift
        └── KudosAnimationView.swift
```

### Integration Points

**Existing Files to Modify**:

1. **SupabaseService.swift**
   - Add gym service methods
   - Add social service methods
   - Add privacy service methods

2. **User.swift**
   - Add `gym_id: UUID?` property
   - Add `privacy_settings: UserPrivacySettings?` property

3. **WorkoutSummary.swift**
   - Add `is_leaderboard_eligible: Bool` property
   - Add `share_to_feed: Bool` property

4. **ContentView.swift / MainTabView**
   - Add "Social" tab (SF Symbol: "person.3")
   - Route to GymProfileView or GymSearchView (if no gym)

5. **Settings/ProfileView**
   - Add "Privacy Settings" section
   - Add "My Gym" section
   - Add "Blocked Users" section

---

## Testing Strategy

### Unit Tests (60 tests total)

**Backend (30 tests)**:
- Gym service: CRUD operations, claim logic, member count updates
- Privacy service: Visibility filtering, blocking, RLS policy enforcement
- Leaderboard service: Ranking calculation, tie-breaking, weekly vs all-time
- Comparison service: Delta calculations, interval matching
- Partnership service: Request flow, mutual approval logic
- Feed service: Auto-posting, privacy filtering, kudos

**iOS (30 tests)**:
- Gym models: Encoding/decoding, validation
- Privacy models: Visibility levels, filtering logic
- Leaderboard models: Rank calculation, sorting
- Comparison models: Delta display, percentage calculation
- View models: Data loading, error handling, pagination
- Service mocks: API call verification

### Integration Tests (20 scenarios)

1. Join gym → See members → View member profile
2. Join gym → View leaderboards → See my rank
3. Send partner request → Receive acceptance → View shared progress
4. Complete workout → Auto-post to feed → Receive kudos
5. Set privacy to "Private" → Verify hidden from leaderboards
6. Block user → Verify hidden from directory and feed
7. Compare workout → See interval deltas → Share comparison
8. Claim gym → Verify admin status → Edit gym profile
9. Leave gym → Verify removed from leaderboards
10. Weekly leaderboard refresh → Verify correct rankings
11. Station leaderboard → Verify station-specific times
12. Partner workout comparison → Verify shared race countdown
13. Feed pagination → Load more activities
14. Privacy setting change → Verify immediate effect
15. Multiple gym memberships → Switch between gyms
16. Gym search → Join → Set as primary gym
17. Leaderboard entry click → View full workout
18. Partner progress → View partner's recent workouts
19. Activity feed filter → Show only workouts
20. Gym member count → Verify accurate after joins/leaves

### Performance Tests

**Database Performance**:
- Leaderboard query (1000 members): < 100ms
- Feed query (500 activities): < 150ms
- Member search (1000 members): < 80ms
- Comparison load (2 workouts): < 50ms

**iOS Performance**:
- Leaderboard scroll (100 entries): 60fps
- Feed infinite scroll: No lag
- Comparison view load: < 200ms
- Member directory search: Real-time (< 50ms debounced)

### Privacy Tests

**Critical Privacy Scenarios**:
1. Private profile → Not visible in member directory
2. Private workouts → Not on leaderboards
3. Blocked user → Hidden from all social features
4. Cross-gym leakage → No data visible outside gym
5. RLS policy enforcement → Verify all SQL queries filtered
6. Friends-only workouts → Only partners see activity
7. Public workouts → All gym members see activity
8. Deleted workout → Removed from leaderboards and feed
9. Left gym → Historical data remains but hidden
10. Admin-only endpoints → Regular users blocked

---

## Risk Mitigation

### Technical Risks

**Risk 1: Performance Degradation in Large Gyms**
- **Impact**: Slow leaderboards/feeds in gyms with 500+ members
- **Probability**: Medium
- **Mitigation**:
  - Implement aggressive caching (Redis)
  - Paginate all lists (25 entries per page)
  - Pre-calculate leaderboards daily (cron job)
  - Add database indexes on all query columns
- **Backup Plan**: Limit leaderboards to top 100, rest shown as "View Full Rankings"

**Risk 2: Privacy Data Leakage**
- **Impact**: Critical. Loss of user trust, legal issues
- **Probability**: Low
- **Mitigation**:
  - RLS policies on all social tables
  - Privacy filter layer in backend services
  - Security audit before launch (Week 6)
  - Unit tests for every privacy scenario
- **Backup Plan**: Disable social features immediately if leak detected

**Risk 3: Cross-Gym Data Leakage**
- **Impact**: High. Users see data from other gyms
- **Probability**: Low
- **Mitigation**:
  - All queries filtered by gym_id
  - RLS policies enforce gym boundaries
  - Integration tests for cross-gym isolation
- **Backup Plan**: Add application-level gym_id validation as double-check

**Risk 4: Apple Watch Data Sync Delays**
- **Impact**: Leaderboards out-of-date
- **Probability**: Medium
- **Mitigation**:
  - Optimistic UI updates (show immediately, sync later)
  - Retry logic for failed syncs
  - Background sync queue
- **Backup Plan**: Manual "Refresh Rankings" button

### Product Risks

**Risk 5: Low User Adoption (Ghost Town Effect)**
- **Impact**: No value if gym has < 5 active members
- **Probability**: Medium
- **Mitigation**:
  - Seed popular gyms with early access invites
  - Show "Invite Friends" flow prominently
  - Referral incentives (future)
  - Show progress even with 1 member ("Be the first!")
- **Backup Plan**: Allow cross-gym friendships if local gym is dead

**Risk 6: Scope Creep**
- **Impact**: Miss 6-week deadline
- **Probability**: High
- **Mitigation**:
  - Strict phase gating (no Phase 2 until Phase 1 complete)
  - Daily standups (15 min progress check)
  - TodoWrite tracking for all tasks
  - "MVP-only" mentality (defer all non-critical features)
- **Backup Plan**: Cut Phase 3 (Activity Feed) if needed

**Risk 7: Privacy Backlash**
- **Impact**: Users feel exposed, churn
- **Probability**: Low
- **Mitigation**:
  - Privacy-first marketing ("Your gym only, always")
  - Clear opt-out controls
  - Default to "gym-only" visibility
  - Educate users on privacy settings
- **Backup Plan**: Add "Invisible Mode" (100% private, no social)

### Timeline Risks

**Risk 8: Underestimated Effort**
- **Impact**: Miss deadline by 1-2 weeks
- **Probability**: Medium
- **Mitigation**:
  - 20% buffer built into estimates
  - Weekly progress reviews (Monday morning)
  - Cut scope early if behind (Week 3 checkpoint)
- **Backup Plan**: Ship without Activity Feed (Phase 3)

**Risk 9: External Dependencies (Supabase, Apple)**
- **Impact**: Blocked by third-party issues
- **Probability**: Low
- **Mitigation**:
  - Use stable APIs only (no beta features)
  - Test migrations on staging first
  - Monitor Supabase status page
- **Backup Plan**: Delay 1 week if major outage

---

## Success Metrics

### Launch Metrics (Week 6)

**Adoption**:
- 100+ gyms created
- 1,000+ users joined gyms
- 50+ gyms with 10+ active members
- 500+ race partnerships formed

**Engagement**:
- 60% of users check leaderboards weekly
- 40% of users compare workouts monthly
- 30% of users give kudos weekly
- 20% of users have 1+ race partner

**Technical**:
- API response times < 200ms (p95)
- Feed load time < 1s
- Zero privacy leaks
- 99.9% uptime

### 30-Day Post-Launch Metrics

**Retention**:
- 70% of gym members still active after 30 days
- 50% of race partners still training together

**Social Activity**:
- 10,000+ kudos given
- 5,000+ workouts compared
- 2,000+ leaderboard views per day

**Growth**:
- 50% MoM growth in gym memberships
- 30% referral rate (users invite friends)

### Qualitative Metrics

**User Feedback**:
- "I found a training partner at my gym!"
- "Leaderboards motivate me to push harder"
- "Love seeing my gym's progress"

**Support Tickets**:
- < 5% privacy-related complaints
- < 2% gym claim disputes
- < 1% leaderboard accuracy issues

---

## Future Expansion (Post-MVP)

### Phase 4: Enhanced Social (Week 7-10)

**Features**:
- Direct messaging (gym members only)
- Workout comments
- Photo sharing (workout selfies)
- Gym challenges (team competitions)
- Badges and achievements

### Phase 5: Cross-Gym Features (Week 11-14)

**Features**:
- Regional leaderboards (city, state, country)
- Global leaderboards (top 100 worldwide)
- Gym-to-gym challenges
- Virtual races (compete with other gyms)

### Phase 6: Community Features (Week 15-18)

**Features**:
- Gym events (HYROX prep sessions)
- Coach/trainer accounts (verified pros)
- Group training sessions
- Live leaderboards during events
- Spectator mode (watch live workouts)

### Phase 7: Monetization (Week 19-22)

**Features**:
- Gym Pro subscriptions (analytics, custom branding)
- Premium user features (detailed stats, coaching)
- Sponsored challenges
- Gym merchandise integration

---

## Appendix

### Estimated Hours Breakdown

| Phase | Backend | iOS | Testing | Total |
|-------|---------|-----|---------|-------|
| 1A: Foundation | 21h | 21h | 7h | 49h |
| 1B: Comparison | 14h | 14h | 7h | 35h |
| 2A: Leaderboards | 21h | 19h | 0h | 40h |
| 2B: Race Partners | 14h | 14h | 7h | 35h |
| 3: Activity Feed | 14h | 12h | 4h | 30h |
| **Total** | **84h** | **80h** | **25h** | **189h** |

**Weekly Hours**: 31.5h/week (5h/day, 6 days/week)
**Total Duration**: 6 weeks

### Team Requirements

**Minimum Viable Team**:
- 1 Full-Stack Developer (Backend + iOS)
- 1 Designer (Part-time, Weeks 1 & 6)
- 1 QA Tester (Part-time, Week 6)

**Recommended Team**:
- 1 Backend Developer (Node.js/TypeScript)
- 1 iOS Developer (Swift/SwiftUI)
- 1 Designer (UI/UX)
- 1 QA Engineer (Testing + Security)

### Dependencies

**External Services**:
- Supabase (Database, Auth, Storage)
- Apple Developer Account (App Store, TestFlight)
- MapKit (Gym location search)
- CloudKit (Optional: iCloud sync)

**Internal Dependencies**:
- Existing workout tracking system
- Existing user authentication
- Existing Apple Watch integration

### Open Questions

1. **Gym Verification**: How do we verify gym ownership claims?
   - Proposed: Email verification (send code to gym's public email)

2. **Gym Discovery**: Should we integrate with Google Places API?
   - Proposed: Start with manual gym creation, add API later

3. **Leaderboard Ties**: How do we break ties (same time)?
   - Proposed: Most recent completion wins

4. **Cross-Gym Memberships**: Can users join multiple gyms?
   - Proposed: Yes, but must set "primary gym" for leaderboards

5. **Inactive Members**: When do we hide inactive members?
   - Proposed: 90 days of no activity → marked inactive

6. **Leaderboard Eligibility**: What workouts count?
   - Proposed: Only Apple Watch-tracked, GPS-verified workouts

---

## Conclusion

This implementation plan delivers a fully-functional, privacy-first gym-local social MVP in 6 weeks. The phased approach allows for incremental delivery, early testing, and scope flexibility.

**Critical Success Factors**:
1. Strict scope control (no feature creep)
2. Privacy-first architecture (RLS + backend filters)
3. Performance optimization (caching, indexing)
4. Early user testing (Week 3 checkpoint)
5. Launch readiness (Week 6 polish)

**Next Steps**:
1. Review and approve this plan
2. Assign team members to phases
3. Set up project tracking (GitHub Projects or Jira)
4. Kick off Week 1 (Database design)
5. Daily standups starting Monday

**Questions or Concerns**: Contact the development team or product owner.

---

**Document Version**: 1.0
**Last Updated**: 2025-12-03
**Author**: FLEXR Engineering Team
**Status**: Draft - Awaiting Approval
