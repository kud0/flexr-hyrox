# FLEXR Social & Community Architecture
**Comprehensive Design Document**
*Version 1.0 - December 2025*

## Executive Summary

This document defines the social and community architecture for FLEXR, balancing AI-driven personalization with meaningful social engagement. The design leverages FLEXR's unique position as a data-rich, HYROX-focused training platform to create social features that motivate through both competition AND collaboration.

**Core Philosophy**: Data-driven social features that enhance training without compromising privacy or personalization.

---

## 1. High-Level Architecture Overview

### 1.1 System Context Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         FLEXR Platform                          │
│                                                                 │
│  ┌──────────────┐        ┌──────────────┐     ┌─────────────┐ │
│  │   AI Engine  │◄──────►│   Social     │◄───►│   Privacy   │ │
│  │  (Training)  │        │   Engine     │     │   Manager   │ │
│  └──────────────┘        └──────────────┘     └─────────────┘ │
│         ▲                        ▲                     ▲        │
│         │                        │                     │        │
│         ▼                        ▼                     ▼        │
│  ┌──────────────┐        ┌──────────────┐     ┌─────────────┐ │
│  │   Workout    │◄──────►│   Activity   │◄───►│   User      │ │
│  │   Service    │        │    Feed      │     │  Profiles   │ │
│  └──────────────┘        └──────────────┘     └─────────────┘ │
│         ▲                        ▲                     ▲        │
│         │                        │                     │        │
│         ▼                        ▼                     ▼        │
│  ┌──────────────┐        ┌──────────────┐     ┌─────────────┐ │
│  │  Analytics   │◄──────►│   Social     │◄───►│   Notif.    │ │
│  │   Engine     │        │   Insights   │     │   Service   │ │
│  └──────────────┘        └──────────────┘     └─────────────┘ │
└─────────────────────────────────────────────────────────────────┘
         │                        │                     │
         ▼                        ▼                     ▼
┌─────────────┐         ┌─────────────┐       ┌─────────────┐
│    iOS      │         │   Watch     │       │   Backend   │
│    App      │         │    App      │       │     API     │
└─────────────┘         └─────────────┘       └─────────────┘
```

### 1.2 Core Components

1. **Social Engine**: Manages connections, follows, teams, and relationships
2. **Activity Feed**: Aggregates and displays social activities
3. **Competition System**: Handles leaderboards, challenges, and rankings
4. **Social Insights Engine**: Provides data-driven comparisons and benchmarks
5. **Gamification Engine**: Manages achievements, streaks, and rewards
6. **Privacy Manager**: Controls visibility and data sharing
7. **Notification Service**: Real-time updates and engagement

---

## 2. Social Connection Models

### 2.1 Connection Types

#### A. Follower/Following System (Asymmetric)
- Similar to Twitter/Strava model
- Users can follow without mutual acceptance
- Privacy controls determine what followers see
- Supports large-scale community building

**Use Cases**:
- Following elite athletes for inspiration
- Tracking gym buddies' progress
- Following local HYROX community

#### B. Friends System (Symmetric)
- Mutual acceptance required
- Higher visibility and deeper integration
- Private messaging and group chats
- Shared training programs

**Use Cases**:
- Close training partners
- Real-world friends using FLEXR
- Accountability partnerships

#### C. Teams & Clubs
- Group-based connections
- Admin/member hierarchy
- Shared goals and challenges
- Team leaderboards

**Types**:
- **Training Teams**: 5-20 members, focused on training together
- **Clubs**: 20-500+ members, gym-based or community-based
- **Race Teams**: Temporary teams for specific HYROX events

#### D. Coach-Athlete Relationships
- Special privileged connection
- Coach can view detailed analytics
- Program assignment and modification
- Performance tracking and feedback

**Features**:
- Workout review and comments
- Training plan adjustments
- Progress reports
- Video analysis (future)

### 2.2 Connection Discovery

**Discovery Methods**:
1. **Nearby Athletes**: Location-based discovery (gym check-ins)
2. **Suggested Connections**: AI-based on similar profiles
3. **QR Code Sharing**: Quick in-person connections
4. **Contacts Integration**: Find friends from phone contacts
5. **Search**: Username, name, or gym search
6. **Race Participants**: Connect with athletes from same HYROX events

---

## 3. Database Schema Design

### 3.1 Core Social Tables

```sql
-- ============================================================================
-- SOCIAL & COMMUNITY SCHEMA
-- ============================================================================

-- User Profiles (Extended)
CREATE TABLE user_social_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,

    -- Profile Info
    username TEXT UNIQUE NOT NULL, -- @username format
    display_name TEXT,
    bio TEXT,
    avatar_url TEXT,
    cover_photo_url TEXT,
    location TEXT, -- City/Region
    gym_affiliation TEXT,

    -- Public Stats (based on privacy settings)
    total_workouts INTEGER DEFAULT 0,
    total_distance_km DECIMAL(10,2) DEFAULT 0,
    current_streak_days INTEGER DEFAULT 0,
    longest_streak_days INTEGER DEFAULT 0,

    -- HYROX Specific
    hyrox_races_completed INTEGER DEFAULT 0,
    best_hyrox_time_seconds INTEGER,
    hyrox_division TEXT, -- 'singles', 'doubles', 'pro', etc.

    -- Social Counts
    follower_count INTEGER DEFAULT 0,
    following_count INTEGER DEFAULT 0,
    friend_count INTEGER DEFAULT 0,

    -- Privacy
    profile_visibility TEXT DEFAULT 'public', -- 'public', 'friends', 'private'
    allow_discovery BOOLEAN DEFAULT true,

    -- Verification
    is_verified BOOLEAN DEFAULT false, -- Verified athlete/coach
    is_coach BOOLEAN DEFAULT false,

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Connections (Followers/Following)
CREATE TABLE user_connections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    follower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    connection_type TEXT NOT NULL, -- 'follow', 'friend', 'blocked'
    status TEXT DEFAULT 'active', -- 'active', 'pending', 'blocked'

    -- Friend-specific
    is_mutual BOOLEAN DEFAULT false,
    friend_since TIMESTAMP,

    -- Permissions
    can_see_workouts BOOLEAN DEFAULT true,
    can_see_stats BOOLEAN DEFAULT true,
    can_see_location BOOLEAN DEFAULT false,

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),

    UNIQUE(follower_id, following_id)
);

CREATE INDEX idx_connections_follower ON user_connections(follower_id);
CREATE INDEX idx_connections_following ON user_connections(following_id);
CREATE INDEX idx_connections_mutual ON user_connections(is_mutual) WHERE is_mutual = true;

-- Teams & Clubs
CREATE TABLE teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    team_type TEXT NOT NULL, -- 'training', 'club', 'race', 'gym'

    -- Images
    logo_url TEXT,
    cover_photo_url TEXT,

    -- Location
    location TEXT,
    gym_affiliation TEXT,

    -- Settings
    is_private BOOLEAN DEFAULT false,
    requires_approval BOOLEAN DEFAULT true,
    max_members INTEGER DEFAULT 50,

    -- Stats
    member_count INTEGER DEFAULT 0,
    total_workouts INTEGER DEFAULT 0,

    -- Ownership
    created_by UUID NOT NULL REFERENCES users(id),

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_teams_type ON teams(team_type);
CREATE INDEX idx_teams_location ON teams(location);

-- Team Memberships
CREATE TABLE team_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    role TEXT DEFAULT 'member', -- 'admin', 'coach', 'member', 'pending'
    status TEXT DEFAULT 'active', -- 'active', 'pending', 'inactive'

    -- Permissions
    can_post BOOLEAN DEFAULT true,
    can_invite BOOLEAN DEFAULT false,
    can_manage BOOLEAN DEFAULT false,

    joined_at TIMESTAMP DEFAULT NOW(),

    UNIQUE(team_id, user_id)
);

CREATE INDEX idx_team_members_team ON team_members(team_id);
CREATE INDEX idx_team_members_user ON team_members(user_id);
CREATE INDEX idx_team_members_role ON team_members(role);

-- Coach Relationships
CREATE TABLE coach_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    coach_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    athlete_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    status TEXT DEFAULT 'pending', -- 'pending', 'active', 'paused', 'ended'

    -- Permissions
    can_view_workouts BOOLEAN DEFAULT true,
    can_edit_programs BOOLEAN DEFAULT true,
    can_view_health_data BOOLEAN DEFAULT false,

    -- Subscription/Payment (future)
    is_paid BOOLEAN DEFAULT false,
    subscription_tier TEXT,

    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),

    UNIQUE(coach_id, athlete_id)
);

CREATE INDEX idx_coach_relationships_coach ON coach_relationships(coach_id);
CREATE INDEX idx_coach_relationships_athlete ON coach_relationships(athlete_id);
```

### 3.2 Activity Feed Schema

```sql
-- Activity Feed
CREATE TABLE activity_feed (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Activity Type
    activity_type TEXT NOT NULL,
    -- 'workout_completed', 'pr_achieved', 'streak_milestone',
    -- 'achievement_unlocked', 'challenge_completed', 'race_result'

    -- Related Entities
    workout_id UUID REFERENCES workouts(id) ON DELETE CASCADE,
    achievement_id UUID REFERENCES achievements(id),
    challenge_id UUID REFERENCES challenges(id),

    -- Activity Data (flexible JSON)
    activity_data JSONB NOT NULL,
    -- Examples:
    -- Workout: {type, duration, distance, pr_segments}
    -- PR: {segment_type, old_time, new_time, improvement_pct}
    -- Streak: {days, milestone}
    -- Achievement: {name, description, icon}

    -- Visibility
    visibility TEXT DEFAULT 'public', -- 'public', 'friends', 'team', 'private'

    -- Engagement
    kudos_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,

    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_activity_user ON activity_feed(user_id, created_at DESC);
CREATE INDEX idx_activity_type ON activity_feed(activity_type);
CREATE INDEX idx_activity_visibility ON activity_feed(visibility);
CREATE INDEX idx_activity_created ON activity_feed(created_at DESC);

-- Activity Kudos (Likes/Reactions)
CREATE TABLE activity_kudos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_id UUID NOT NULL REFERENCES activity_feed(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    reaction_type TEXT DEFAULT 'kudos', -- 'kudos', 'fire', 'strong', 'fast', 'inspiring'

    created_at TIMESTAMP DEFAULT NOW(),

    UNIQUE(activity_id, user_id)
);

CREATE INDEX idx_kudos_activity ON activity_kudos(activity_id);
CREATE INDEX idx_kudos_user ON activity_kudos(user_id);

-- Activity Comments
CREATE TABLE activity_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_id UUID NOT NULL REFERENCES activity_feed(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    comment_text TEXT NOT NULL,

    -- Thread support
    parent_comment_id UUID REFERENCES activity_comments(id) ON DELETE CASCADE,
    reply_count INTEGER DEFAULT 0,

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_comments_activity ON activity_comments(activity_id, created_at);
CREATE INDEX idx_comments_user ON activity_comments(user_id);
CREATE INDEX idx_comments_parent ON activity_comments(parent_comment_id);
```

### 3.3 Competition & Leaderboards Schema

```sql
-- Leaderboards
CREATE TABLE leaderboards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Leaderboard Definition
    name TEXT NOT NULL,
    description TEXT,
    leaderboard_type TEXT NOT NULL,
    -- 'global', 'friends', 'team', 'gym', 'age_group', 'division'

    -- Scope
    metric TEXT NOT NULL,
    -- 'total_workouts', 'total_distance', 'fastest_hyrox', 'station_time',
    -- 'monthly_workouts', 'streak', 'segment_pr'

    segment_type TEXT, -- For station-specific leaderboards

    -- Time Period
    time_period TEXT, -- 'all_time', 'monthly', 'weekly', 'yearly'
    period_start DATE,
    period_end DATE,

    -- Filters
    filter_criteria JSONB,
    -- {age_min: 25, age_max: 35, division: 'singles', gender: 'male'}

    -- Settings
    is_active BOOLEAN DEFAULT true,
    update_frequency TEXT DEFAULT 'daily', -- 'realtime', 'hourly', 'daily'

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_leaderboards_type ON leaderboards(leaderboard_type);
CREATE INDEX idx_leaderboards_metric ON leaderboards(metric);
CREATE INDEX idx_leaderboards_active ON leaderboards(is_active);

-- Leaderboard Entries
CREATE TABLE leaderboard_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    leaderboard_id UUID NOT NULL REFERENCES leaderboards(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Ranking
    rank INTEGER NOT NULL,
    previous_rank INTEGER,
    rank_change INTEGER, -- Calculated: previous_rank - rank

    -- Score/Value
    score_value DECIMAL(12,2) NOT NULL, -- Time, distance, count, etc.
    score_unit TEXT, -- 'seconds', 'km', 'count'

    -- Context
    workout_id UUID REFERENCES workouts(id),
    achieved_at TIMESTAMP,

    -- Metadata
    entry_data JSONB,

    updated_at TIMESTAMP DEFAULT NOW(),

    UNIQUE(leaderboard_id, user_id)
);

CREATE INDEX idx_entries_leaderboard_rank ON leaderboard_entries(leaderboard_id, rank);
CREATE INDEX idx_entries_user ON leaderboard_entries(user_id);
CREATE INDEX idx_entries_score ON leaderboard_entries(leaderboard_id, score_value);

-- Challenges
CREATE TABLE challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Challenge Info
    title TEXT NOT NULL,
    description TEXT,
    icon TEXT,

    -- Type
    challenge_type TEXT NOT NULL,
    -- 'time_based', 'distance', 'workout_count', 'streak', 'specific_workout'

    -- Goal
    goal_type TEXT NOT NULL,
    goal_value DECIMAL(12,2) NOT NULL,
    goal_unit TEXT, -- 'km', 'workouts', 'days', 'seconds'

    -- Scope
    scope TEXT DEFAULT 'individual', -- 'individual', 'team', 'global'
    team_id UUID REFERENCES teams(id),

    -- Duration
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,

    -- Participation
    participant_count INTEGER DEFAULT 0,
    completion_count INTEGER DEFAULT 0,

    -- Rewards (future)
    reward_type TEXT, -- 'badge', 'discount', 'feature_unlock'
    reward_data JSONB,

    -- Visibility
    is_public BOOLEAN DEFAULT true,
    created_by UUID REFERENCES users(id),

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_challenges_dates ON challenges(start_date, end_date);
CREATE INDEX idx_challenges_type ON challenges(challenge_type);
CREATE INDEX idx_challenges_scope ON challenges(scope);

-- Challenge Participation
CREATE TABLE challenge_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challenge_id UUID NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Progress
    current_value DECIMAL(12,2) DEFAULT 0,
    progress_percentage DECIMAL(5,2) DEFAULT 0, -- 0.00 to 100.00

    -- Status
    status TEXT DEFAULT 'active', -- 'active', 'completed', 'abandoned'
    completed_at TIMESTAMP,

    -- Ranking (for competitive challenges)
    rank INTEGER,

    joined_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),

    UNIQUE(challenge_id, user_id)
);

CREATE INDEX idx_participants_challenge ON challenge_participants(challenge_id);
CREATE INDEX idx_participants_user ON challenge_participants(user_id);
CREATE INDEX idx_participants_rank ON challenge_participants(challenge_id, rank);
```

### 3.4 Gamification Schema

```sql
-- Achievements
CREATE TABLE achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Achievement Definition
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    icon TEXT,
    category TEXT, -- 'workouts', 'distance', 'streak', 'pr', 'social', 'special'

    -- Unlock Criteria
    unlock_type TEXT NOT NULL,
    -- 'workout_count', 'distance_total', 'streak_days', 'pr_count',
    -- 'race_completion', 'social_engagement'

    unlock_criteria JSONB NOT NULL,
    -- Examples:
    -- {workouts: 10}
    -- {distance_km: 100}
    -- {streak_days: 30}
    -- {pr_count: 5}

    -- Rarity
    tier TEXT DEFAULT 'bronze', -- 'bronze', 'silver', 'gold', 'platinum', 'legendary'
    points INTEGER DEFAULT 0, -- Achievement points

    -- Visibility
    is_hidden BOOLEAN DEFAULT false, -- Hidden until unlocked
    is_active BOOLEAN DEFAULT true,

    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_achievements_category ON achievements(category);
CREATE INDEX idx_achievements_tier ON achievements(tier);

-- User Achievements
CREATE TABLE user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_id UUID NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,

    -- Unlock Info
    unlocked_at TIMESTAMP DEFAULT NOW(),
    progress_at_unlock JSONB, -- What triggered the unlock

    -- Display
    is_featured BOOLEAN DEFAULT false, -- Featured on profile

    UNIQUE(user_id, achievement_id)
);

CREATE INDEX idx_user_achievements_user ON user_achievements(user_id);
CREATE INDEX idx_user_achievements_unlocked ON user_achievements(unlocked_at DESC);

-- User Streaks
CREATE TABLE user_streaks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,

    -- Current Streak
    current_streak_days INTEGER DEFAULT 0,
    current_streak_start DATE,
    last_activity_date DATE,

    -- Best Streaks
    longest_streak_days INTEGER DEFAULT 0,
    longest_streak_start DATE,
    longest_streak_end DATE,

    -- Weekly Goals
    weekly_workout_goal INTEGER DEFAULT 4,
    current_week_workouts INTEGER DEFAULT 0,
    weeks_goal_met INTEGER DEFAULT 0,

    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_streaks_current ON user_streaks(current_streak_days DESC);
CREATE INDEX idx_streaks_longest ON user_streaks(longest_streak_days DESC);

-- Personal Records
CREATE TABLE personal_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Record Type
    record_type TEXT NOT NULL,
    -- 'full_hyrox', 'half_hyrox', 'station', 'segment', 'distance', 'pace'

    station_type TEXT, -- For station-specific PRs
    distance_km DECIMAL(6,2), -- For distance PRs

    -- Record Value
    record_value DECIMAL(12,2) NOT NULL,
    record_unit TEXT NOT NULL, -- 'seconds', 'meters', 'reps', 'kg'

    -- Context
    workout_id UUID REFERENCES workouts(id),
    achieved_at TIMESTAMP NOT NULL,

    -- Previous Record
    previous_record_value DECIMAL(12,2),
    improvement_percentage DECIMAL(5,2),

    -- Validation
    is_verified BOOLEAN DEFAULT false, -- For race results

    created_at TIMESTAMP DEFAULT NOW(),

    UNIQUE(user_id, record_type, station_type, distance_km)
);

CREATE INDEX idx_prs_user ON personal_records(user_id);
CREATE INDEX idx_prs_type ON personal_records(record_type);
CREATE INDEX idx_prs_achieved ON personal_records(achieved_at DESC);
```

### 3.5 Privacy & Settings Schema

```sql
-- User Privacy Settings
CREATE TABLE user_privacy_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,

    -- Profile Visibility
    profile_visibility TEXT DEFAULT 'public', -- 'public', 'friends', 'private'
    show_real_name BOOLEAN DEFAULT true,
    show_location BOOLEAN DEFAULT true,
    show_age BOOLEAN DEFAULT false,
    show_gym BOOLEAN DEFAULT true,

    -- Activity Visibility
    default_activity_visibility TEXT DEFAULT 'public',
    show_workouts BOOLEAN DEFAULT true,
    show_stats BOOLEAN DEFAULT true,
    show_prs BOOLEAN DEFAULT true,
    show_achievements BOOLEAN DEFAULT true,

    -- Leaderboard Participation
    allow_global_leaderboards BOOLEAN DEFAULT true,
    allow_local_leaderboards BOOLEAN DEFAULT true,
    allow_age_group_leaderboards BOOLEAN DEFAULT false,

    -- Social Features
    allow_friend_requests BOOLEAN DEFAULT true,
    allow_follow BOOLEAN DEFAULT true,
    allow_team_invites BOOLEAN DEFAULT true,
    allow_coach_requests BOOLEAN DEFAULT true,
    allow_messages BOOLEAN DEFAULT true,

    -- Discovery
    discoverable_by_username BOOLEAN DEFAULT true,
    discoverable_by_location BOOLEAN DEFAULT true,
    discoverable_by_contacts BOOLEAN DEFAULT true,
    show_in_suggestions BOOLEAN DEFAULT true,

    -- Notifications
    notify_new_follower BOOLEAN DEFAULT true,
    notify_friend_request BOOLEAN DEFAULT true,
    notify_kudos BOOLEAN DEFAULT true,
    notify_comments BOOLEAN DEFAULT true,
    notify_challenge_invite BOOLEAN DEFAULT true,
    notify_team_activity BOOLEAN DEFAULT false,

    updated_at TIMESTAMP DEFAULT NOW()
);

-- Blocked Users
CREATE TABLE blocked_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    blocker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    reason TEXT,
    created_at TIMESTAMP DEFAULT NOW(),

    UNIQUE(blocker_id, blocked_id)
);

CREATE INDEX idx_blocked_blocker ON blocked_users(blocker_id);
CREATE INDEX idx_blocked_blocked ON blocked_users(blocked_id);
```

---

## 4. Competition & Comparison Systems

### 4.1 Leaderboard Types

#### Global Leaderboards
- **All-Time Best**: Fastest HYROX times, longest distances
- **Monthly Rankings**: Reset each month for fresh competition
- **Weekly Leaders**: High engagement, frequent updates

#### Segmented Leaderboards
- **Age Groups**: 18-24, 25-29, 30-34, 35-39, 40-44, 45-49, 50+
- **Division**: Singles Men, Singles Women, Doubles, Pro
- **Experience Level**: Beginner, Intermediate, Advanced, Elite
- **Station-Specific**: Best times for each HYROX station

#### Social Leaderboards
- **Friends Only**: Compare with your network
- **Team Rankings**: Team vs team competitions
- **Gym-Specific**: Local competition within your gym
- **Training Partners**: Small group competitions

### 4.2 Challenge System

#### Challenge Types

**1. Time-Based Challenges**
```
Example: "30-Day Consistency Challenge"
- Complete at least 4 workouts per week for 4 weeks
- Earn "Consistent Athlete" badge
- Team participation optional
```

**2. Distance Challenges**
```
Example: "100km in May"
- Accumulate 100km of running this month
- Individual or team-based
- Progress tracking and milestones
```

**3. Workout Count Challenges**
```
Example: "25 Workouts in 12 Weeks"
- Complete 25 workouts before race day
- Recommended for race prep
- Accountability partners
```

**4. Station Mastery Challenges**
```
Example: "Sled Push Progression"
- Improve sled push time by 10%
- 4-week timeframe
- Coaching tips included
```

**5. Social Challenges**
```
Example: "Share the Grind"
- Give 100 kudos to teammates
- Comment on 20 workouts
- Invite 3 friends
```

### 4.3 Segment Comparisons (Strava-style)

**Concept**: Users can compare their performance on specific segments against:
- Friends who completed the same segment
- Global athletes
- Athletes with similar profiles (AI-matched)

**Segment Types**:
- HYROX Stations (SkiErg 1000m, Sled Push 50m, etc.)
- Running segments (1km, 5km, 8km race sim)
- Combined segments (Run + Station combos)
- Custom workout templates

**Comparison Views**:
```
┌───────────────────────────────────────────┐
│  SkiErg 1000m - Your Performance          │
├───────────────────────────────────────────┤
│  Your Time:           3:45 (#2 in friends)│
│  Personal Best:       3:42 (2 weeks ago)  │
│  Friend Average:      4:12                │
│  Similar Athletes:    3:58                │
│  Global Average:      4:30                │
│  Top 10%:            <3:20                │
│                                           │
│  [View Full Leaderboard] [View Attempts]  │
└───────────────────────────────────────────┘
```

---

## 5. Data-Driven Social Insights

### 5.1 AI-Powered Comparisons

**Similar Athlete Matching**
```typescript
interface SimilarAthleteProfile {
  age_range: number; // ±5 years
  experience_level: ExperienceLevel;
  training_volume: number; // ±20%
  primary_goal: PrimaryGoal;
  race_proximity: number; // weeks to race ±4
}
```

**Insights Provided**:
- "Athletes similar to you average 4:15 on SkiErg 1000m"
- "You're in the top 15% for your age group in Sled Push"
- "Your running pace is 12% faster than similar athletes"
- "Your training volume is optimal for your experience level"

### 5.2 Community Benchmarks

**Performance Distribution Visualizations**
```
┌─────────────────────────────────────────────────┐
│  HYROX Full Race Times - Your Age Group (30-34) │
├─────────────────────────────────────────────────┤
│                                                 │
│  95th %ile  ───────────○  1:15:00              │
│  75th %ile  ─────────────────○  1:30:00        │
│  50th %ile  ───────────────────────○  1:45:00  │
│  25th %ile  ─────────────────────────────○  2:00│
│  You        ────────────────○  1:38:22 (65th)  │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Training Intensity Heatmaps**
```
When do athletes in your gym train most?

      Mon  Tue  Wed  Thu  Fri  Sat  Sun
5am   ██   ███  ██   ███  █    ░░   ░░
6am   ████ ████ ███  ████ ███  ██   ░
7am   ███  ███  ███  ███  ██   ███  █
12pm  █    █    █    █    █    ██   ██
6pm   ████ ███  ████ ███  ██   ░    ░
```

### 5.3 Progress Comparisons

**Week-over-Week Trends**
- Volume comparison (you vs network average)
- Intensity comparison
- Consistency metrics
- Recovery patterns

**Predictive Insights**
- "At your current pace, you're on track for a 1:35 HYROX"
- "You're progressing 8% faster than athletes at this stage of prep"
- "Consider adding 1 more recovery session based on your intensity"

---

## 6. Engagement Features

### 6.1 Activity Feed Architecture

**Feed Algorithm** (Priority Ranking):
1. **Friends' Major Achievements** (PR, race finish, streak milestone)
2. **Teammates' Activities** (workouts, comments, challenges)
3. **Following: High Engagement Content** (lots of kudos/comments)
4. **Suggested Content** (athletes you might want to follow)
5. **Sponsored/Featured** (community challenges, gym events)

**Feed Types**:
- **Home Feed**: Personalized mix of all content
- **Friends Feed**: Friends-only content
- **Teams Feed**: Your team's activities
- **Discover Feed**: Find new athletes and content

### 6.2 Kudos & Reactions System

**Reaction Types**:
- 💪 Kudos (general encouragement)
- 🔥 Fire (intense workout, great effort)
- ⚡ Lightning (fast time, impressive speed)
- 💎 Strong (heavy lifts, strength achievement)
- 🎯 Bullseye (perfect execution, technique)

**Gamification**:
- "Super Fan" achievement: Give 100 kudos in a month
- "Team Motivator": Most kudos given within a team
- Kudos received contributes to weekly engagement score

### 6.3 Comments & Encouragement

**Comment Features**:
- Threaded replies
- Mention system (@username)
- Emoji reactions to comments
- Coach/trainer badges on comments
- "Workout buddy" context (if you've done similar workouts)

**Smart Suggestions** (AI-generated encouragement):
- "Great effort on those sled pushes!"
- "You beat your previous time by 30 seconds!"
- "Consistency is key - that's 3 weeks straight!"

### 6.4 Workout Sharing & Templates

**Shareable Content**:
- Completed workouts (full details or summary)
- Workout templates ("Try my leg day workout!")
- Training programs (weekly plans)
- Race day strategies

**Template Library**:
- User-created templates
- Coach-shared programs
- Community-voted best workouts
- FLEXR official programs

**Sharing Options**:
- Share to feed
- Send directly to friend/teammate
- Export to other platforms (Strava integration)
- Generate shareable link/QR code

---

## 7. Privacy & Control Framework

### 7.1 Privacy Levels

**Three-Tier System**:

**Public**:
- Profile visible to everyone
- Workouts appear in public feeds
- Included in global leaderboards
- Discoverable in search

**Friends Only**:
- Profile visible to accepted friends
- Workouts visible to friends only
- Friends leaderboards only
- No public search

**Private**:
- Profile not visible to others
- No workout sharing
- No leaderboards
- Solo training mode

### 7.2 Granular Controls

**Per-Activity Visibility**:
Users can set default and override per workout:
```
Default: Public
Override specific workouts:
- Race simulation: Friends only
- Recovery session: Private
- PR attempt: Public
```

**Data Sharing Controls**:
- Share workout metrics (Y/N)
- Share location/gym (Y/N)
- Share heart rate data (Y/N)
- Share training plan (Y/N)
- Share performance insights (Y/N)

### 7.3 Leaderboard Opt-In/Opt-Out

**Flexible Participation**:
- Global leaderboards: Opt-in
- Age group leaderboards: Opt-in
- Friends leaderboards: Auto-included (can opt-out)
- Team leaderboards: Auto-included if in team
- Gym leaderboards: Opt-in

**Anonymous Options**:
- Participate in leaderboards anonymously
- Show rank without showing name
- "Ghost mode" for elite athletes training

---

## 8. API Endpoint Structure

### 8.1 Social Profile Endpoints

```typescript
// Profile Management
GET    /api/v1/social/profile/:userId
PUT    /api/v1/social/profile/:userId
PATCH  /api/v1/social/profile/:userId/avatar
GET    /api/v1/social/profile/:userId/stats
GET    /api/v1/social/profile/:userId/achievements

// Username & Discovery
POST   /api/v1/social/profile/check-username
GET    /api/v1/social/search/users?q={query}
GET    /api/v1/social/suggestions/users
GET    /api/v1/social/nearby/users?lat={lat}&lng={lng}
```

### 8.2 Connection Endpoints

```typescript
// Followers & Following
POST   /api/v1/social/connections/follow/:userId
DELETE /api/v1/social/connections/unfollow/:userId
GET    /api/v1/social/connections/followers/:userId
GET    /api/v1/social/connections/following/:userId

// Friends
POST   /api/v1/social/friends/request/:userId
PUT    /api/v1/social/friends/accept/:requestId
DELETE /api/v1/social/friends/reject/:requestId
DELETE /api/v1/social/friends/remove/:userId
GET    /api/v1/social/friends

// Blocking
POST   /api/v1/social/blocks/:userId
DELETE /api/v1/social/blocks/:userId
GET    /api/v1/social/blocks
```

### 8.3 Activity Feed Endpoints

```typescript
// Feed Retrieval
GET    /api/v1/social/feed/home?limit={n}&offset={n}
GET    /api/v1/social/feed/friends?limit={n}&offset={n}
GET    /api/v1/social/feed/team/:teamId?limit={n}
GET    /api/v1/social/feed/discover?limit={n}
GET    /api/v1/social/feed/user/:userId?limit={n}

// Activity Posting
POST   /api/v1/social/activities
DELETE /api/v1/social/activities/:activityId
PATCH  /api/v1/social/activities/:activityId/visibility

// Engagement
POST   /api/v1/social/activities/:activityId/kudos
DELETE /api/v1/social/activities/:activityId/kudos
POST   /api/v1/social/activities/:activityId/comments
PUT    /api/v1/social/activities/comments/:commentId
DELETE /api/v1/social/activities/comments/:commentId
```

### 8.4 Leaderboard & Competition Endpoints

```typescript
// Leaderboards
GET    /api/v1/leaderboards?type={type}&period={period}
GET    /api/v1/leaderboards/:leaderboardId/entries?limit={n}
GET    /api/v1/leaderboards/:leaderboardId/user/:userId
GET    /api/v1/leaderboards/user/:userId/all

// Segment Comparisons
GET    /api/v1/segments/:segmentType/compare/:userId
GET    /api/v1/segments/:segmentType/leaderboard?scope={scope}
GET    /api/v1/segments/user/:userId/best

// Personal Records
GET    /api/v1/prs/user/:userId?type={type}
POST   /api/v1/prs/user/:userId
GET    /api/v1/prs/compare/:prId/similar-athletes
```

### 8.5 Challenge Endpoints

```typescript
// Challenge Discovery
GET    /api/v1/challenges/active?scope={scope}
GET    /api/v1/challenges/recommended
GET    /api/v1/challenges/:challengeId

// Challenge Participation
POST   /api/v1/challenges/:challengeId/join
DELETE /api/v1/challenges/:challengeId/leave
GET    /api/v1/challenges/:challengeId/participants
GET    /api/v1/challenges/:challengeId/leaderboard
GET    /api/v1/challenges/user/:userId/active

// Challenge Creation
POST   /api/v1/challenges
PUT    /api/v1/challenges/:challengeId
DELETE /api/v1/challenges/:challengeId

// Progress Tracking
GET    /api/v1/challenges/:challengeId/progress/:userId
PATCH  /api/v1/challenges/:challengeId/progress/:userId
```

### 8.6 Team Endpoints

```typescript
// Team Management
GET    /api/v1/teams?search={query}
GET    /api/v1/teams/:teamId
POST   /api/v1/teams
PUT    /api/v1/teams/:teamId
DELETE /api/v1/teams/:teamId
GET    /api/v1/teams/:teamId/stats

// Team Membership
POST   /api/v1/teams/:teamId/join
POST   /api/v1/teams/:teamId/invite/:userId
PUT    /api/v1/teams/:teamId/members/:userId/role
DELETE /api/v1/teams/:teamId/members/:userId
GET    /api/v1/teams/:teamId/members
GET    /api/v1/teams/user/:userId

// Team Activity
GET    /api/v1/teams/:teamId/activity
GET    /api/v1/teams/:teamId/leaderboard
POST   /api/v1/teams/:teamId/posts
```

### 8.7 Gamification Endpoints

```typescript
// Achievements
GET    /api/v1/achievements
GET    /api/v1/achievements/user/:userId
GET    /api/v1/achievements/:achievementId
POST   /api/v1/achievements/check/:userId // Trigger check

// Streaks
GET    /api/v1/streaks/user/:userId
GET    /api/v1/streaks/leaderboard?scope={scope}
PATCH  /api/v1/streaks/user/:userId/goal

// Stats & Insights
GET    /api/v1/insights/user/:userId/summary
GET    /api/v1/insights/user/:userId/comparisons
GET    /api/v1/insights/user/:userId/predictions
GET    /api/v1/insights/community/benchmarks?filter={filter}
```

### 8.8 Privacy Endpoints

```typescript
// Privacy Settings
GET    /api/v1/social/privacy/:userId
PUT    /api/v1/social/privacy/:userId
PATCH  /api/v1/social/privacy/:userId/specific

// Visibility Controls
PUT    /api/v1/social/visibility/default
PUT    /api/v1/social/visibility/activity/:activityId

// Leaderboard Preferences
PUT    /api/v1/social/leaderboards/opt-in
PUT    /api/v1/social/leaderboards/opt-out
```

---

## 9. UI/UX Flow Suggestions

### 9.1 Profile Screen Architecture

```
┌─────────────────────────────────────────┐
│ ← Back          @username       [⚙️]    │
├─────────────────────────────────────────┤
│        [Cover Photo/Banner]             │
│                                         │
│     [Avatar]    John Doe                │
│                 📍 Boston, MA            │
│                 💪 Elite HYROX Athlete   │
│                                         │
│  [Edit Profile]    [Follow]    [•••]    │
├─────────────────────────────────────────┤
│  Stats ─────────────────────────────    │
│  ┌──────┐  ┌──────┐  ┌──────┐          │
│  │ 247  │  │ 15   │  │ 42   │          │
│  │Wrkts │  │Races │  │Streak│          │
│  └──────┘  └──────┘  └──────┘          │
├─────────────────────────────────────────┤
│  [Activities] [Stats] [Achievements]    │
├─────────────────────────────────────────┤
│  Recent Activities:                     │
│  ┌───────────────────────────────────┐ │
│  │ 🏃 Full HYROX Simulation           │ │
│  │ 1:38:22 • 2 days ago              │ │
│  │ 💪 45 kudos • 12 comments          │ │
│  └───────────────────────────────────┘ │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │ 💎 New PR: SkiErg 1000m           │ │
│  │ 3:42 (-8s) • 5 days ago           │ │
│  │ 🔥 78 kudos • 23 comments          │ │
│  └───────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

### 9.2 Activity Feed Flow

```
┌─────────────────────────────────────────┐
│  Feed         🔍         [Profile Icon]  │
├─────────────────────────────────────────┤
│  [Home] [Friends] [Teams] [Discover]    │
├─────────────────────────────────────────┤
│                                         │
│  👤 @sarah_runs • Following • 2h ago    │
│  ┌───────────────────────────────────┐ │
│  │ 🔥 Crushed a Half Simulation!     │ │
│  │                                   │ │
│  │ 📊 42:15 total time              │ │
│  │ 🏃 4:15/km avg pace               │ │
│  │ 💓 165 avg HR                     │ │
│  │                                   │ │
│  │ New PR on SkiErg! -12 seconds 💪  │ │
│  │                                   │ │
│  │ [View Workout Details]            │ │
│  └───────────────────────────────────┘ │
│  💪 45   💬 12   ↗️ Share               │
│                                         │
├─────────────────────────────────────────┤
│  👤 @mike_crossfit • Teammate • 4h     │
│  ┌───────────────────────────────────┐ │
│  │ 🎯 Achievement Unlocked!           │ │
│  │ "Century Club" - 100 Workouts     │ │
│  │                                   │ │
│  │ [🏆 Badge Display]                 │ │
│  └───────────────────────────────────┘ │
│  💪 23   💬 5   ↗️ Share                │
│                                         │
└─────────────────────────────────────────┘
```

### 9.3 Leaderboard Screen

```
┌─────────────────────────────────────────┐
│  ← Leaderboards              [Filter]   │
├─────────────────────────────────────────┤
│  [Global] [Friends] [Team] [Gym]        │
├─────────────────────────────────────────┤
│  SkiErg 1000m - This Month              │
│  Age Group: 30-34 • Men's Singles       │
├─────────────────────────────────────────┤
│  Your Rank: #47 / 2,384 (Top 2%)       │
│  ┌───────────────────────────────────┐ │
│  │ You: 3:45                         │ │
│  │ Personal Best: 3:42               │ │
│  │ [View Your Stats]                 │ │
│  └───────────────────────────────────┘ │
├─────────────────────────────────────────┤
│  🥇 1  @elitePete      3:12  ↑ 2        │
│  🥈 2  @crossfitSam    3:15  NEW        │
│  🥉 3  @runner_alex    3:18  ↓ 1        │
│     4  @fit_jenny      3:21  -          │
│     5  @hyrox_hero     3:24  ↑ 3        │
│     ...                                 │
│     45 @gym_buddy      3:44  ↑ 12  👥   │
│  ➡️ 47 You              3:45  ↑ 5        │
│     48 @local_runner   3:46  ↓ 2   📍   │
│     ...                                 │
│                                         │
│  [Load More]                            │
└─────────────────────────────────────────┘
```

### 9.4 Challenge Screen

```
┌─────────────────────────────────────────┐
│  ← Challenges                 [+ Create] │
├─────────────────────────────────────────┤
│  [Active] [Discover] [Completed]        │
├─────────────────────────────────────────┤
│  Your Active Challenges (2)             │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │ 🔥 30-Day Consistency Challenge    │ │
│  │                                   │ │
│  │ Progress: 18 / 24 workouts        │ │
│  │ [████████████░░░░░░] 75%          │ │
│  │                                   │ │
│  │ 📅 12 days remaining              │ │
│  │ 👥 342 participants               │ │
│  │ 🏆 Your rank: #23                 │ │
│  │                                   │ │
│  │ [View Leaderboard]                │ │
│  └───────────────────────────────────┘ │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │ ⚡ Team Challenge: 500km Total     │ │
│  │                                   │ │
│  │ Team Progress: 387 / 500 km       │ │
│  │ [████████████████░░░░] 77%        │ │
│  │                                   │ │
│  │ Your contribution: 45km (12%)     │ │
│  │ Top contributor: @sarah_runs 78km │ │
│  │                                   │ │
│  │ [View Team Stats]                 │ │
│  └───────────────────────────────────┘ │
│                                         │
├─────────────────────────────────────────┤
│  Recommended Challenges                 │
│  ┌───────────────────────────────────┐ │
│  │ 💪 Station Mastery: Sled Push     │ │
│  │ Improve by 10% in 4 weeks         │ │
│  │ [Join Challenge]                  │ │
│  └───────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

---

## 10. Implementation Phases

### Phase 1: MVP (3-4 months)

**Core Social Features**:
- ✅ User profiles with username system
- ✅ Follow/unfollow functionality
- ✅ Basic activity feed (workout completions)
- ✅ Kudos system (single reaction type)
- ✅ Basic comments
- ✅ Profile privacy settings (3 levels)
- ✅ Personal records tracking
- ✅ Basic streak tracking

**Database**:
- User social profiles table
- Connections table (followers)
- Activity feed table
- Kudos table
- Comments table
- Personal records table
- User streaks table
- Privacy settings table

**API Endpoints**:
- Profile CRUD
- Follow/unfollow
- Activity feed retrieval
- Kudos and comments
- Privacy controls

**UI Components**:
- Profile screen
- Activity feed
- Workout detail with social actions
- Settings screen

**Success Metrics**:
- 30% user profile completion
- 15% daily active users engaging with feed
- Average 2 kudos per workout posted

---

### Phase 2: Competition & Gamification (2-3 months)

**Features**:
- ✅ Global and friends leaderboards
- ✅ Segment-specific leaderboards
- ✅ Achievement system (15-20 achievements)
- ✅ Multiple reaction types (5 types)
- ✅ Team/club creation and management
- ✅ Basic challenges (time-based, distance)
- ✅ Enhanced streak system with goals

**Database**:
- Leaderboards table
- Leaderboard entries table
- Achievements table
- User achievements table
- Teams table
- Team members table
- Challenges table
- Challenge participants table

**API Endpoints**:
- Leaderboard endpoints
- Achievement endpoints
- Team management endpoints
- Challenge endpoints

**UI Components**:
- Leaderboard screen
- Team management UI
- Challenge discovery and tracking
- Achievement showcase

**Success Metrics**:
- 40% users on at least one leaderboard
- 25% users join a team
- 20% users participate in a challenge
- 50% users unlock at least one achievement

---

### Phase 3: Advanced Social & Insights (2-3 months)

**Features**:
- ✅ Similar athlete comparisons (AI-powered)
- ✅ Community benchmarks and distributions
- ✅ Friends system (mutual connections)
- ✅ Coach-athlete relationships
- ✅ Segment comparisons (Strava-style)
- ✅ Workout template sharing
- ✅ Advanced privacy controls
- ✅ Team challenges
- ✅ Threaded comments

**Database**:
- Coach relationships table
- Segment comparisons table
- Social insights cache table
- Workout templates table

**AI/ML Components**:
- Similar athlete matching algorithm
- Performance prediction models
- Personalized recommendations

**API Endpoints**:
- Insights and comparisons endpoints
- Coach relationship endpoints
- Template sharing endpoints
- Advanced search endpoints

**UI Components**:
- Insights dashboard
- Comparison views
- Coach management UI
- Template library

**Success Metrics**:
- 35% users view insights weekly
- 15% users share workout templates
- 10% users establish coach relationships
- 25% users compare segments

---

### Phase 4: Scale & Optimization (Ongoing)

**Features**:
- ✅ Real-time notifications
- ✅ Push notification system
- ✅ Advanced feed algorithms (ML-powered)
- ✅ Verified accounts (athletes, coaches)
- ✅ Sponsored challenges and partnerships
- ✅ Live race tracking and social features
- ✅ Video sharing (future)
- ✅ Messaging system (direct and group)

**Infrastructure**:
- Real-time WebSocket connections
- Feed caching and optimization
- CDN for media content
- Advanced analytics and tracking
- A/B testing framework

**Success Metrics**:
- Sub-2 second feed load times
- 99.9% uptime
- 50% MAU engage with social features
- 70% user retention month-over-month

---

## 11. Technical Considerations & Scaling

### 11.1 Real-Time Updates

**Technologies**:
- **WebSockets**: Live feed updates, kudos, comments
- **Server-Sent Events (SSE)**: Notifications
- **Firebase Cloud Messaging**: Push notifications

**Implementation**:
```typescript
// WebSocket connection for live updates
const socialSocket = new WebSocket('wss://api.flexr.app/social/live');

socialSocket.on('new_activity', (activity) => {
  updateFeed(activity);
});

socialSocket.on('new_kudos', (kudos) => {
  incrementKudosCount(kudos.activity_id);
});

socialSocket.on('new_comment', (comment) => {
  addCommentToActivity(comment);
});
```

### 11.2 Feed Generation & Caching

**Strategy**: Pre-computed timelines + real-time updates

**Feed Algorithm**:
```typescript
interface FeedGenerationParams {
  user_id: string;
  feed_type: 'home' | 'friends' | 'team' | 'discover';
  limit: number;
  offset: number;
}

async function generateFeed(params: FeedGenerationParams) {
  // 1. Fetch from pre-computed timeline cache
  const cachedActivities = await redis.zrange(
    `feed:${params.user_id}:${params.feed_type}`,
    params.offset,
    params.offset + params.limit
  );

  // 2. If cache miss or stale, regenerate
  if (!cachedActivities || isCacheStale(cachedActivities)) {
    const activities = await computeFeed(params);
    await cacheFeed(params.user_id, params.feed_type, activities);
    return activities;
  }

  // 3. Enrich with real-time data (kudos counts, etc.)
  return enrichActivities(cachedActivities);
}
```

**Cache Invalidation**:
- New activity posted: Invalidate followers' feeds
- Privacy change: Invalidate all relevant feeds
- User unfollows: Remove activities from feed
- TTL: 15 minutes for home feed, 5 minutes for discover

### 11.3 Database Indexing Strategy

**Critical Indexes**:
```sql
-- Feed retrieval (most frequent query)
CREATE INDEX idx_activity_feed_user_created
ON activity_feed(user_id, created_at DESC);

-- Social graph queries
CREATE INDEX idx_connections_follower_following
ON user_connections(follower_id, following_id);

-- Leaderboard queries
CREATE INDEX idx_leaderboard_entries_rank
ON leaderboard_entries(leaderboard_id, rank);

-- Challenge queries
CREATE INDEX idx_challenge_participants_challenge_rank
ON challenge_participants(challenge_id, rank);

-- Privacy checks
CREATE INDEX idx_privacy_user
ON user_privacy_settings(user_id);
```

### 11.4 Notification System

**Notification Types**:
1. **Social Notifications**:
   - New follower
   - Friend request
   - Kudos on your workout
   - Comment on your workout
   - Mention in comment

2. **Competition Notifications**:
   - Challenge milestone reached
   - Leaderboard rank change
   - PR beaten by friend
   - New challenge invitation

3. **Team Notifications**:
   - Team invitation
   - Team member achievement
   - Team challenge update

**Delivery Channels**:
- In-app notifications (badge + list)
- Push notifications (iOS, watchOS)
- Email digests (weekly summary)

**Implementation**:
```typescript
interface Notification {
  id: string;
  user_id: string;
  type: NotificationType;
  title: string;
  body: string;
  action_url?: string;
  is_read: boolean;
  created_at: Date;
}

async function sendNotification(
  userId: string,
  type: NotificationType,
  data: any
) {
  // 1. Create in-app notification
  await db.notifications.insert({
    user_id: userId,
    type: type,
    ...data
  });

  // 2. Send push notification (if enabled)
  const settings = await getUserNotificationSettings(userId);
  if (settings[type] && settings.push_enabled) {
    await pushService.send({
      user_id: userId,
      title: data.title,
      body: data.body,
      badge: await getUnreadCount(userId)
    });
  }

  // 3. WebSocket update (if online)
  if (isUserOnline(userId)) {
    socketService.emit(userId, 'new_notification', data);
  }
}
```

### 11.5 Analytics & Tracking

**Key Metrics to Track**:

**Engagement Metrics**:
- Daily/Monthly Active Users (DAU/MAU)
- Social engagement rate (% users who interact)
- Average kudos per workout
- Average comments per activity
- Feed scroll depth
- Time spent on social features

**Growth Metrics**:
- New profiles created per day
- Follow/unfollow rate
- Team/club creation rate
- Challenge participation rate

**Content Metrics**:
- Workout sharing rate
- Template usage
- Most popular leaderboards
- Most active challenges

**Technical Metrics**:
- Feed load times
- API response times
- Cache hit rates
- WebSocket connection stability

**Implementation**:
```typescript
// Analytics event tracking
analytics.track('activity_posted', {
  user_id: userId,
  activity_type: 'workout_completed',
  visibility: 'public',
  has_prs: true
});

analytics.track('social_interaction', {
  user_id: userId,
  interaction_type: 'kudos',
  target_activity_id: activityId
});

analytics.track('leaderboard_view', {
  user_id: userId,
  leaderboard_type: 'global',
  metric: 'skierg_1000m'
});
```

### 11.6 Scaling Considerations

**Database Sharding**:
- Shard by `user_id` for user-specific tables
- Separate read replicas for feeds and leaderboards
- Time-series data in separate partition

**Microservices Architecture**:
```
┌─────────────────────┐
│   API Gateway       │
└──────────┬──────────┘
           │
     ┌─────┴─────┬──────────┬──────────┐
     ▼           ▼          ▼          ▼
┌─────────┐ ┌────────┐ ┌────────┐ ┌───────────┐
│ Social  │ │ Feed   │ │ Comp.  │ │ Notif.    │
│ Service │ │Service │ │Service │ │ Service   │
└─────────┘ └────────┘ └────────┘ └───────────┘
     │           │          │          │
     └───────────┴──────────┴──────────┘
                    │
              ┌─────▼─────┐
              │  Database │
              │  (Postgres)│
              └───────────┘
```

**Caching Strategy**:
- **Redis**: Feed caches, session data, real-time counters
- **CDN**: User avatars, workout images, static assets
- **In-memory**: Leaderboard rankings (with periodic DB sync)

**Rate Limiting**:
```typescript
// API rate limits
const rateLimits = {
  'post_activity': { max: 50, window: '1h' },
  'send_kudos': { max: 200, window: '1h' },
  'post_comment': { max: 100, window: '1h' },
  'follow_user': { max: 50, window: '1h' },
  'api_read': { max: 1000, window: '15m' }
};
```

### 11.7 Privacy & GDPR Compliance

**Data Handling**:
- User consent for data sharing
- Right to be forgotten (account deletion)
- Data export functionality
- Granular privacy controls
- Audit logs for data access

**Implementation**:
```typescript
// GDPR compliance functions
async function exportUserData(userId: string) {
  return {
    profile: await db.profiles.find(userId),
    activities: await db.activities.find({ user_id: userId }),
    connections: await db.connections.find({ user_id: userId }),
    achievements: await db.achievements.find({ user_id: userId }),
    // ... all user data
  };
}

async function deleteUserAccount(userId: string) {
  await db.transaction(async (trx) => {
    // Anonymize or delete all user data
    await trx.profiles.delete(userId);
    await trx.activities.update({ user_id: userId }, { user_id: null, anonymized: true });
    await trx.connections.delete({ user_id: userId });
    // ... cascade delete all related data
  });
}
```

---

## 12. Success Metrics & KPIs

### 12.1 MVP Success Criteria (Phase 1)

**Adoption Metrics**:
- **Target**: 30% of users complete social profile
- **Target**: 25% of users follow at least one other user
- **Target**: 15% daily active engagement with feed

**Engagement Metrics**:
- **Target**: 2 kudos per workout on average
- **Target**: 1 comment per 5 workouts
- **Target**: 50% of workouts shared publicly

**Retention Impact**:
- **Target**: 5% increase in 7-day retention
- **Target**: 10% increase in 30-day retention

### 12.2 Growth Metrics (Phase 2-3)

**Competition & Gamification**:
- **Target**: 40% users on leaderboards
- **Target**: 25% users in a team
- **Target**: 20% challenge participation rate
- **Target**: 60% users with at least one achievement

**Social Network Effects**:
- **Target**: Average 5 connections per user
- **Target**: 30% users have "similar athletes" comparisons
- **Target**: 15% template sharing rate

### 12.3 Business Impact Metrics

**User Acquisition**:
- Viral coefficient: 0.3-0.5 (organic invites)
- Referral conversion rate: 15%
- Social share to download rate: 5%

**Monetization Enablers** (Future):
- Coach account adoption: 5% of users
- Premium feature adoption: 20% of users
- Team/club subscription rate: 10%

**Engagement & Retention**:
- Sessions per week: +25% with social features
- Average session duration: +30%
- Churn rate: -15%

---

## 13. Risks & Mitigation Strategies

### 13.1 Technical Risks

**Risk 1: Feed Performance Degradation**
- **Impact**: Slow feed loads, poor UX
- **Mitigation**: Pre-computed timelines, aggressive caching, pagination
- **Monitoring**: Track p95 load times, set alerts at 2s

**Risk 2: Database Scaling Issues**
- **Impact**: Slow queries, downtime
- **Mitigation**: Read replicas, connection pooling, query optimization
- **Monitoring**: Track slow queries, connection pool usage

**Risk 3: Real-time System Overload**
- **Impact**: WebSocket disconnections, missed notifications
- **Mitigation**: Load balancing, graceful degradation, fallback to polling
- **Monitoring**: Track WebSocket connection rates, error rates

### 13.2 Product Risks

**Risk 1: Low Social Adoption**
- **Impact**: Features unused, wasted development
- **Mitigation**: Phased rollout, user research, A/B testing
- **Monitoring**: Track adoption metrics, survey users

**Risk 2: Privacy Concerns**
- **Impact**: User backlash, churn
- **Mitigation**: Clear privacy controls, education, opt-in by default
- **Monitoring**: Privacy-related support tickets, sentiment analysis

**Risk 3: Toxic Community Behavior**
- **Impact**: Negative experiences, platform reputation
- **Mitigation**: Reporting system, moderation tools, community guidelines
- **Monitoring**: Report rates, blocked users, sentiment

### 13.3 Business Risks

**Risk 1: Competitive Pressure**
- **Impact**: Users prefer existing platforms (Strava, TrainingPeaks)
- **Mitigation**: Differentiate with HYROX-specific features, AI insights
- **Strategy**: Focus on niche, build community

**Risk 2: Regulatory Compliance**
- **Impact**: GDPR/CCPA violations, fines
- **Mitigation**: Privacy-first design, legal review, compliance audits
- **Strategy**: Build compliance into architecture from day one

---

## 14. Conclusion & Recommendations

### 14.1 Key Architectural Decisions

**1. Asymmetric Follow Model** (Not Mutual Friends Only)
- **Rationale**: Enables broader community, allows following elite athletes
- **Trade-off**: More complex privacy management
- **Recommendation**: Implement with strong privacy controls

**2. Pre-Computed Feed Timelines** (Not Real-Time Only)
- **Rationale**: Better performance at scale, lower cost
- **Trade-off**: Slight delay in activity appearing in feeds
- **Recommendation**: Hybrid approach with real-time updates for critical actions

**3. Segment-Based Comparisons** (Not Full Workout Comparisons)
- **Rationale**: More actionable insights, easier to understand
- **Trade-off**: Requires segment tagging and classification
- **Recommendation**: Start with HYROX stations, expand to custom segments

**4. Opt-In Leaderboards** (Not Automatic Inclusion)
- **Rationale**: Respects privacy, reduces competitive pressure
- **Trade-off**: Lower leaderboard participation initially
- **Recommendation**: Make opt-in easy, educate users on benefits

### 14.2 Strategic Recommendations

**1. Start Small, Scale Smart**
- Launch MVP with core features (profiles, follow, feed, kudos)
- Validate engagement before building advanced features
- Use analytics to guide feature prioritization

**2. Leverage FLEXR's Unique Data**
- Differentiate with AI-powered insights
- Focus on HYROX-specific competitions and comparisons
- Build community around shared training goals

**3. Balance Competition & Collaboration**
- Not everyone wants to compete publicly
- Provide multiple engagement pathways (social, gamification, insights)
- Support both individual achievement and team camaraderie

**4. Privacy-First Design**
- Make privacy controls intuitive and accessible
- Default to more private settings
- Educate users on what's shared and why

**5. Build for Scale from Day One**
- Use caching, indexing, and optimization early
- Plan database schema for future growth
- Implement monitoring and observability

### 14.3 Next Steps

**Immediate (Week 1-2)**:
1. Review and validate schema design with engineering team
2. Create API specification and documentation
3. Design mockups for MVP screens
4. Set up development environment and tooling

**Short-Term (Month 1-2)**:
1. Implement MVP database schema and migrations
2. Build core API endpoints (profile, follow, feed)
3. Develop iOS UI components for social features
4. Set up analytics and monitoring infrastructure

**Medium-Term (Month 3-4)**:
1. Beta test with select users
2. Iterate based on feedback
3. Implement Phase 2 features (leaderboards, achievements)
4. Launch MVP to all users

**Long-Term (Month 5+)**:
1. Monitor engagement and retention metrics
2. Build advanced features based on usage data
3. Scale infrastructure as user base grows
4. Explore monetization opportunities (coach accounts, premium features)

---

## Appendix A: Sample Data Structures

### Activity Feed Item
```typescript
interface ActivityFeedItem {
  id: string;
  user: {
    id: string;
    username: string;
    display_name: string;
    avatar_url: string;
    is_verified: boolean;
  };
  activity_type: 'workout_completed' | 'pr_achieved' | 'streak_milestone' | 'achievement_unlocked';
  activity_data: {
    workout?: {
      id: string;
      type: string;
      duration_minutes: number;
      distance_km?: number;
      segments: Array<{
        name: string;
        type: string;
        time_seconds?: number;
        is_pr: boolean;
      }>;
    };
    pr?: {
      segment_type: string;
      old_value: number;
      new_value: number;
      improvement_pct: number;
    };
    streak?: {
      days: number;
      milestone: string;
    };
    achievement?: {
      id: string;
      name: string;
      icon: string;
      tier: string;
    };
  };
  engagement: {
    kudos_count: number;
    comment_count: number;
    user_has_kudos: boolean;
  };
  visibility: 'public' | 'friends' | 'team';
  created_at: string;
}
```

### Leaderboard Entry
```typescript
interface LeaderboardEntry {
  rank: number;
  previous_rank?: number;
  rank_change: number;
  user: {
    id: string;
    username: string;
    display_name: string;
    avatar_url: string;
    is_friend: boolean;
    is_local: boolean;
  };
  score: {
    value: number;
    unit: string;
    formatted: string;
  };
  context: {
    workout_id?: string;
    achieved_at: string;
  };
  is_current_user: boolean;
}
```

### Challenge Progress
```typescript
interface ChallengeProgress {
  challenge: {
    id: string;
    title: string;
    description: string;
    icon: string;
    goal_value: number;
    goal_unit: string;
    start_date: string;
    end_date: string;
  };
  user_progress: {
    current_value: number;
    progress_percentage: number;
    status: 'active' | 'completed' | 'abandoned';
    rank?: number;
    rank_change?: number;
  };
  milestones: Array<{
    value: number;
    is_reached: boolean;
    reward?: string;
  }>;
  top_participants: Array<{
    username: string;
    avatar_url: string;
    value: number;
  }>;
}
```

---

## Appendix B: API Request/Response Examples

### GET /api/v1/social/feed/home

**Request**:
```http
GET /api/v1/social/feed/home?limit=20&offset=0
Authorization: Bearer <token>
```

**Response**:
```json
{
  "activities": [
    {
      "id": "act_123abc",
      "user": {
        "id": "user_456def",
        "username": "sarah_runs",
        "display_name": "Sarah Johnson",
        "avatar_url": "https://cdn.flexr.app/avatars/user_456def.jpg",
        "is_verified": false
      },
      "activity_type": "workout_completed",
      "activity_data": {
        "workout": {
          "id": "workout_789ghi",
          "type": "half_simulation",
          "duration_minutes": 42,
          "distance_km": 4.0,
          "segments": [
            {
              "name": "SkiErg 500m",
              "type": "station",
              "time_seconds": 115,
              "is_pr": true
            }
          ]
        }
      },
      "engagement": {
        "kudos_count": 45,
        "comment_count": 12,
        "user_has_kudos": false
      },
      "visibility": "public",
      "created_at": "2025-12-02T14:23:00Z"
    }
  ],
  "pagination": {
    "limit": 20,
    "offset": 0,
    "total": 127,
    "has_more": true
  }
}
```

### POST /api/v1/social/activities/:activityId/kudos

**Request**:
```http
POST /api/v1/social/activities/act_123abc/kudos
Authorization: Bearer <token>
Content-Type: application/json

{
  "reaction_type": "fire"
}
```

**Response**:
```json
{
  "success": true,
  "kudos": {
    "id": "kudos_xyz789",
    "activity_id": "act_123abc",
    "user_id": "user_current",
    "reaction_type": "fire",
    "created_at": "2025-12-02T15:10:00Z"
  },
  "activity_stats": {
    "kudos_count": 46,
    "reactions": {
      "kudos": 30,
      "fire": 10,
      "strong": 4,
      "fast": 2
    }
  }
}
```

---

**Document Version**: 1.0
**Last Updated**: December 2025
**Author**: System Architecture Team
**Status**: Ready for Implementation

---

*This architecture document is designed to be a living document that evolves with the product. Regular reviews and updates are recommended as features are implemented and user feedback is incorporated.*
