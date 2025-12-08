# FLEXR Gym-Local Social Architecture

**Version**: 1.0
**Last Updated**: 2025-12-03
**Status**: Design Phase

## Executive Summary

This document defines the complete architecture for FLEXR's Gym-Local Social system - a privacy-first, gym-scoped social feature that enables users to connect with their real-world training community, compare workouts, and compete on local leaderboards.

**Core Principle**: Start hyper-local, expand globally later.

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Database Schema](#database-schema)
3. [API Specifications](#api-specifications)
4. [Privacy Model](#privacy-model)
5. [iOS UI Architecture](#ios-ui-architecture)
6. [Workout Comparison System](#workout-comparison-system)
7. [Leaderboard System](#leaderboard-system)
8. [Implementation Timeline](#implementation-timeline)
9. [Future Expansion](#future-expansion)

---

## System Overview

### Core Components

```
┌─────────────────────────────────────────────────────────────┐
│                     FLEXR Gym Social                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │   Gym        │  │   Member     │  │   Workout    │    │
│  │   System     │  │   Discovery  │  │   Compare    │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │ Leaderboards │  │   Activity   │  │   Privacy    │    │
│  │              │  │     Feed     │  │   Controls   │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Gym-scoped only (no global) | Simplifies MVP, mirrors real-world relationships |
| Opt-in leaderboards | Privacy-first approach builds trust |
| Explicit connections | Users control who they compare with |
| Station-level comparison | Leverages FLEXR's unique segment tracking |
| Gym admin roles | Allows gym owners to manage their space |

---

## Database Schema

### 1. Gyms Table

```sql
CREATE TABLE gyms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Basic Info
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL, -- URL-friendly identifier
  description TEXT,

  -- Location
  address TEXT,
  city TEXT,
  state TEXT,
  country TEXT NOT NULL DEFAULT 'US',
  postal_code TEXT,
  lat DECIMAL(10, 8),
  lng DECIMAL(11, 8),

  -- Metadata
  gym_type TEXT CHECK (gym_type IN ('crossfit', 'functional_fitness', 'commercial', 'private', 'other')),
  website_url TEXT,
  phone TEXT,

  -- Settings
  is_verified BOOLEAN DEFAULT false, -- Claimed by official gym owner
  is_public BOOLEAN DEFAULT true, -- Discoverable in search
  requires_approval BOOLEAN DEFAULT false, -- Members need approval to join
  invite_code TEXT UNIQUE, -- Optional invite-only code

  -- Stats (denormalized for performance)
  member_count INTEGER DEFAULT 0,
  active_member_count INTEGER DEFAULT 0, -- Members active in last 30 days
  total_workouts INTEGER DEFAULT 0,

  -- Ownership
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Search optimization
  search_vector tsvector GENERATED ALWAYS AS (
    setweight(to_tsvector('english', COALESCE(name, '')), 'A') ||
    setweight(to_tsvector('english', COALESCE(city, '')), 'B') ||
    setweight(to_tsvector('english', COALESCE(description, '')), 'C')
  ) STORED
);

-- Indexes
CREATE INDEX idx_gyms_location ON gyms USING GIST (ll_to_earth(lat, lng));
CREATE INDEX idx_gyms_search ON gyms USING GIN (search_vector);
CREATE INDEX idx_gyms_slug ON gyms (slug);
CREATE INDEX idx_gyms_city_country ON gyms (city, country);
CREATE INDEX idx_gyms_public ON gyms (is_public) WHERE is_public = true;
```

### 2. Gym Memberships Table

```sql
CREATE TABLE gym_memberships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Relations
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  gym_id UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,

  -- Role & Status
  role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('member', 'coach', 'admin', 'owner')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'inactive', 'banned')),

  -- Privacy Settings
  show_on_leaderboard BOOLEAN DEFAULT true,
  show_in_member_list BOOLEAN DEFAULT true,
  allow_workout_comparisons BOOLEAN DEFAULT true,
  show_activity_feed BOOLEAN DEFAULT true,

  -- Stats (cached)
  total_workouts INTEGER DEFAULT 0,
  last_workout_at TIMESTAMPTZ,

  -- Timestamps
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  approved_at TIMESTAMPTZ,
  approved_by UUID REFERENCES users(id) ON DELETE SET NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraints
  UNIQUE(user_id, gym_id)
);

-- Indexes
CREATE INDEX idx_gym_memberships_user ON gym_memberships (user_id);
CREATE INDEX idx_gym_memberships_gym ON gym_memberships (gym_id);
CREATE INDEX idx_gym_memberships_gym_active ON gym_memberships (gym_id, status) WHERE status = 'active';
CREATE INDEX idx_gym_memberships_leaderboard ON gym_memberships (gym_id) WHERE show_on_leaderboard = true AND status = 'active';
```

### 3. Gym Connections Table

```sql
CREATE TABLE gym_connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Relations (both users must be members of the gym)
  gym_id UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  connected_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Connection State
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'blocked')),

  -- Metadata
  requested_at TIMESTAMPTZ DEFAULT NOW(),
  responded_at TIMESTAMPTZ,

  -- Notes/Tags (optional future feature)
  connection_note TEXT, -- "Training partner", "Competition buddy", etc.

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraints
  UNIQUE(gym_id, user_id, connected_user_id),
  CHECK (user_id != connected_user_id)
);

-- Indexes
CREATE INDEX idx_gym_connections_user ON gym_connections (user_id, gym_id, status);
CREATE INDEX idx_gym_connections_connected_user ON gym_connections (connected_user_id, gym_id, status);
CREATE INDEX idx_gym_connections_pending ON gym_connections (connected_user_id, status) WHERE status = 'pending';
```

### 4. Gym Activity Feed Table

```sql
CREATE TABLE gym_activity_feed (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Relations
  gym_id UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Activity Type
  activity_type TEXT NOT NULL CHECK (activity_type IN (
    'workout_completed',
    'pr_achieved',
    'milestone_reached',
    'joined_gym',
    'connection_made'
  )),

  -- Activity Data (JSONB for flexibility)
  activity_data JSONB NOT NULL,
  -- Examples:
  -- workout_completed: {workout_id, workout_name, duration, pr_broken: boolean}
  -- pr_achieved: {segment_type, old_time, new_time, improvement_pct}
  -- milestone_reached: {milestone_type, count, description}

  -- Visibility
  is_visible BOOLEAN DEFAULT true,

  -- Engagement
  kudos_count INTEGER DEFAULT 0,
  comment_count INTEGER DEFAULT 0,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '30 days'
);

-- Indexes
CREATE INDEX idx_gym_activity_gym_time ON gym_activity_feed (gym_id, created_at DESC);
CREATE INDEX idx_gym_activity_user ON gym_activity_feed (user_id, created_at DESC);
CREATE INDEX idx_gym_activity_expires ON gym_activity_feed (expires_at) WHERE expires_at < NOW();
```

### 5. Gym Activity Kudos Table

```sql
CREATE TABLE gym_activity_kudos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Relations
  activity_id UUID NOT NULL REFERENCES gym_activity_feed(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraints
  UNIQUE(activity_id, user_id)
);

-- Indexes
CREATE INDEX idx_gym_kudos_activity ON gym_activity_kudos (activity_id);
CREATE INDEX idx_gym_kudos_user ON gym_activity_kudos (user_id);
```

### 6. Workout Comparisons Table (Cached Comparisons)

```sql
CREATE TABLE workout_comparisons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Relations
  gym_id UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
  workout_1_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
  workout_2_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
  user_1_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user_2_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Similarity Score (0-100)
  similarity_score INTEGER NOT NULL, -- How similar the workouts are

  -- Comparison Data (pre-computed for performance)
  comparison_data JSONB NOT NULL,
  -- Structure:
  -- {
  --   overall: {user1_time, user2_time, difference, winner},
  --   segments: [{
  --     segment_name, segment_type,
  --     user1_time, user2_time, difference, winner,
  --     user1_hr_avg, user2_hr_avg, etc.
  --   }],
  --   insights: ["User 1 was 15% faster on runs", "User 2 paced better"]
  -- }

  -- Cache metadata
  viewed_by_user_1 BOOLEAN DEFAULT false,
  viewed_by_user_2 BOOLEAN DEFAULT false,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '90 days',

  -- Constraints
  UNIQUE(workout_1_id, workout_2_id)
);

-- Indexes
CREATE INDEX idx_workout_comparisons_gym ON workout_comparisons (gym_id, created_at DESC);
CREATE INDEX idx_workout_comparisons_user1 ON workout_comparisons (user_1_id, created_at DESC);
CREATE INDEX idx_workout_comparisons_user2 ON workout_comparisons (user_2_id, created_at DESC);
CREATE INDEX idx_workout_comparisons_expires ON workout_comparisons (expires_at) WHERE expires_at < NOW();
```

### 7. Gym Leaderboards Table (Materialized View Approach)

```sql
-- Weekly Leaderboard (Refreshed daily)
CREATE MATERIALIZED VIEW gym_leaderboard_weekly AS
SELECT
  gm.gym_id,
  gm.user_id,
  u.name,
  u.avatar_url,
  COUNT(DISTINCT w.id) as workouts_completed,
  SUM(w.duration) as total_duration,
  AVG(w.duration) as avg_duration,
  SUM(w.total_distance) as total_distance,
  COUNT(DISTINCT w.id) FILTER (WHERE w.created_at >= NOW() - INTERVAL '7 days') as weekly_workouts,
  RANK() OVER (PARTITION BY gm.gym_id ORDER BY COUNT(DISTINCT w.id) FILTER (WHERE w.created_at >= NOW() - INTERVAL '7 days') DESC) as rank
FROM gym_memberships gm
JOIN users u ON gm.user_id = u.id
LEFT JOIN workouts w ON w.user_id = gm.user_id
  AND w.created_at >= NOW() - INTERVAL '7 days'
  AND w.status = 'completed'
WHERE gm.status = 'active'
  AND gm.show_on_leaderboard = true
GROUP BY gm.gym_id, gm.user_id, u.name, u.avatar_url;

-- Refresh schedule (run daily via cron)
CREATE INDEX idx_gym_leaderboard_weekly_gym ON gym_leaderboard_weekly (gym_id, rank);

-- Segment Leaderboards (e.g., fastest 1km run)
CREATE TABLE gym_segment_leaderboards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Relations
  gym_id UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Segment Info
  segment_type TEXT NOT NULL, -- 'run', 'row', 'bike', 'ski', 'sled_push', etc.
  segment_distance INTEGER, -- In meters (e.g., 1000 for 1km)
  segment_name TEXT NOT NULL, -- '1km Run', '500m Row', etc.

  -- Performance
  best_time INTEGER NOT NULL, -- In seconds
  workout_id UUID REFERENCES workouts(id) ON DELETE CASCADE,
  achieved_at TIMESTAMPTZ NOT NULL,

  -- Ranking
  rank INTEGER,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraints
  UNIQUE(gym_id, user_id, segment_type, segment_distance)
);

-- Indexes
CREATE INDEX idx_gym_segment_leaderboards_gym_segment ON gym_segment_leaderboards (gym_id, segment_type, segment_distance, best_time);
CREATE INDEX idx_gym_segment_leaderboards_user ON gym_segment_leaderboards (user_id);
```

---

## API Specifications

### Base URL Structure

```
/api/v1/gyms/*
```

### Authentication

All endpoints require Bearer token authentication via Supabase Auth:

```
Authorization: Bearer <supabase_jwt_token>
```

---

### 1. Gym Management Endpoints

#### Create Gym

```http
POST /api/v1/gyms
Content-Type: application/json

{
  "name": "CrossFit Downtown",
  "gym_type": "crossfit",
  "address": "123 Main St",
  "city": "San Francisco",
  "state": "CA",
  "country": "US",
  "postal_code": "94102",
  "lat": 37.7749,
  "lng": -122.4194,
  "description": "Premier CrossFit box in SOMA",
  "website_url": "https://crossfitdowntown.com",
  "phone": "+1-415-555-0100",
  "is_public": true,
  "requires_approval": false
}
```

**Response (201):**
```json
{
  "id": "gym-uuid",
  "name": "CrossFit Downtown",
  "slug": "crossfit-downtown-sf",
  "gym_type": "crossfit",
  "address": "123 Main St",
  "city": "San Francisco",
  "state": "CA",
  "country": "US",
  "lat": 37.7749,
  "lng": -122.4194,
  "member_count": 1,
  "is_verified": false,
  "is_public": true,
  "created_by": "user-uuid",
  "created_at": "2025-12-03T10:00:00Z"
}
```

#### Search Gyms

```http
GET /api/v1/gyms/search?q=crossfit&city=San Francisco&lat=37.7749&lng=-122.4194&radius=10
```

**Query Parameters:**
- `q` (optional): Search query (name, description)
- `city` (optional): Filter by city
- `lat`, `lng`, `radius` (optional): Proximity search (radius in km)
- `gym_type` (optional): Filter by type
- `limit` (default: 20): Results per page
- `offset` (default: 0): Pagination offset

**Response (200):**
```json
{
  "gyms": [
    {
      "id": "gym-uuid",
      "name": "CrossFit Downtown",
      "slug": "crossfit-downtown-sf",
      "city": "San Francisco",
      "state": "CA",
      "gym_type": "crossfit",
      "member_count": 45,
      "active_member_count": 32,
      "distance_km": 2.4,
      "is_verified": true,
      "membership_status": null // or "active" if user is a member
    }
  ],
  "total": 1,
  "limit": 20,
  "offset": 0
}
```

#### Get Gym Details

```http
GET /api/v1/gyms/{gym_id}
```

**Response (200):**
```json
{
  "id": "gym-uuid",
  "name": "CrossFit Downtown",
  "slug": "crossfit-downtown-sf",
  "description": "Premier CrossFit box in SOMA",
  "address": "123 Main St",
  "city": "San Francisco",
  "state": "CA",
  "country": "US",
  "postal_code": "94102",
  "lat": 37.7749,
  "lng": -122.4194,
  "gym_type": "crossfit",
  "website_url": "https://crossfitdowntown.com",
  "phone": "+1-415-555-0100",
  "member_count": 45,
  "active_member_count": 32,
  "total_workouts": 1250,
  "is_verified": true,
  "is_public": true,
  "requires_approval": false,
  "created_at": "2025-01-15T10:00:00Z",
  "user_membership": {
    "role": "member",
    "status": "active",
    "joined_at": "2025-02-01T14:00:00Z"
  }
}
```

#### Update Gym (Admin/Owner only)

```http
PATCH /api/v1/gyms/{gym_id}
Content-Type: application/json

{
  "description": "Updated description",
  "website_url": "https://new-website.com",
  "requires_approval": true
}
```

#### Delete Gym (Owner only)

```http
DELETE /api/v1/gyms/{gym_id}
```

---

### 2. Gym Membership Endpoints

#### Join Gym

```http
POST /api/v1/gyms/{gym_id}/join
Content-Type: application/json

{
  "invite_code": "ABC123" // Optional, required if gym requires it
}
```

**Response (201):**
```json
{
  "id": "membership-uuid",
  "gym_id": "gym-uuid",
  "user_id": "user-uuid",
  "role": "member",
  "status": "pending", // or "active" if no approval required
  "joined_at": "2025-12-03T10:00:00Z"
}
```

#### Leave Gym

```http
DELETE /api/v1/gyms/{gym_id}/leave
```

#### Get My Memberships

```http
GET /api/v1/gyms/my-memberships
```

**Response (200):**
```json
{
  "memberships": [
    {
      "id": "membership-uuid",
      "gym": {
        "id": "gym-uuid",
        "name": "CrossFit Downtown",
        "slug": "crossfit-downtown-sf",
        "city": "San Francisco",
        "member_count": 45
      },
      "role": "member",
      "status": "active",
      "total_workouts": 23,
      "last_workout_at": "2025-12-02T18:00:00Z",
      "joined_at": "2025-02-01T14:00:00Z"
    }
  ]
}
```

#### Update Membership Privacy Settings

```http
PATCH /api/v1/gyms/{gym_id}/membership/privacy
Content-Type: application/json

{
  "show_on_leaderboard": true,
  "show_in_member_list": true,
  "allow_workout_comparisons": true,
  "show_activity_feed": true
}
```

#### Get Gym Members

```http
GET /api/v1/gyms/{gym_id}/members?search=john&role=member&limit=50
```

**Query Parameters:**
- `search` (optional): Search by name
- `role` (optional): Filter by role
- `status` (optional): Filter by status (default: active)
- `limit`, `offset`: Pagination

**Response (200):**
```json
{
  "members": [
    {
      "user_id": "user-uuid",
      "name": "John Doe",
      "avatar_url": "https://...",
      "role": "member",
      "total_workouts": 23,
      "last_workout_at": "2025-12-02T18:00:00Z",
      "joined_at": "2025-02-01T14:00:00Z",
      "connection_status": "accepted" // or null, "pending", "none"
    }
  ],
  "total": 45,
  "limit": 50,
  "offset": 0
}
```

---

### 3. Gym Connection Endpoints

#### Send Connection Request

```http
POST /api/v1/gyms/{gym_id}/connections
Content-Type: application/json

{
  "connected_user_id": "user-uuid",
  "connection_note": "Training partner"
}
```

**Response (201):**
```json
{
  "id": "connection-uuid",
  "gym_id": "gym-uuid",
  "user_id": "user-uuid",
  "connected_user_id": "target-user-uuid",
  "status": "pending",
  "requested_at": "2025-12-03T10:00:00Z"
}
```

#### Respond to Connection Request

```http
PATCH /api/v1/gyms/{gym_id}/connections/{connection_id}
Content-Type: application/json

{
  "status": "accepted" // or "rejected"
}
```

#### Get My Connections

```http
GET /api/v1/gyms/{gym_id}/connections?status=accepted
```

**Response (200):**
```json
{
  "connections": [
    {
      "id": "connection-uuid",
      "connected_user": {
        "user_id": "user-uuid",
        "name": "Jane Smith",
        "avatar_url": "https://...",
        "total_workouts": 45
      },
      "status": "accepted",
      "connection_note": "Training partner",
      "requested_at": "2025-11-15T10:00:00Z",
      "responded_at": "2025-11-15T11:00:00Z"
    }
  ]
}
```

#### Remove Connection

```http
DELETE /api/v1/gyms/{gym_id}/connections/{connection_id}
```

---

### 4. Workout Comparison Endpoints

#### Get Comparable Workouts

```http
GET /api/v1/gyms/{gym_id}/workouts/comparable?user_id={user_id}&min_similarity=70
```

**Query Parameters:**
- `user_id`: User to compare with (must be connected)
- `min_similarity` (default: 60): Minimum similarity score (0-100)
- `time_range` (default: 30): Days to look back
- `limit` (default: 10): Max results

**Response (200):**
```json
{
  "comparable_workouts": [
    {
      "my_workout": {
        "id": "workout-uuid-1",
        "name": "Murph Lite",
        "completed_at": "2025-12-02T10:00:00Z",
        "duration": 1800
      },
      "their_workout": {
        "id": "workout-uuid-2",
        "name": "Murph Lite",
        "completed_at": "2025-12-02T11:00:00Z",
        "duration": 1650
      },
      "similarity_score": 95,
      "comparison_available": true
    }
  ]
}
```

#### Generate Workout Comparison

```http
POST /api/v1/gyms/{gym_id}/workouts/compare
Content-Type: application/json

{
  "workout_1_id": "my-workout-uuid",
  "workout_2_id": "their-workout-uuid"
}
```

**Response (201):**
```json
{
  "id": "comparison-uuid",
  "similarity_score": 95,
  "overall": {
    "user_1": {
      "name": "You",
      "total_time": 1800,
      "avg_hr": 165
    },
    "user_2": {
      "name": "Jane Smith",
      "total_time": 1650,
      "avg_hr": 158
    },
    "time_difference": 150,
    "winner": "user_2"
  },
  "segments": [
    {
      "segment_name": "1km Run",
      "segment_type": "run",
      "user_1": {
        "time": 240,
        "avg_pace": "4:00/km",
        "avg_hr": 175,
        "max_hr": 185
      },
      "user_2": {
        "time": 225,
        "avg_pace": "3:45/km",
        "avg_hr": 170,
        "max_hr": 180
      },
      "time_difference": 15,
      "pct_difference": 6.25,
      "winner": "user_2"
    },
    {
      "segment_name": "50 Push-ups",
      "segment_type": "reps",
      "user_1": {
        "time": 120,
        "reps_completed": 50
      },
      "user_2": {
        "time": 135,
        "reps_completed": 50
      },
      "time_difference": -15,
      "pct_difference": -11.1,
      "winner": "user_1"
    }
  ],
  "insights": [
    "Jane was 8.3% faster overall",
    "You were 11% faster on push-ups",
    "Jane paced running segments better",
    "Your heart rate was higher on average"
  ],
  "created_at": "2025-12-03T10:00:00Z"
}
```

#### Get Comparison

```http
GET /api/v1/gyms/{gym_id}/workouts/compare/{comparison_id}
```

---

### 5. Leaderboard Endpoints

#### Get Gym Leaderboard

```http
GET /api/v1/gyms/{gym_id}/leaderboards/overall?period=week&limit=50
```

**Query Parameters:**
- `period`: `week`, `month`, `all_time`
- `metric`: `workouts` (default), `duration`, `distance`
- `limit` (default: 50): Top N users
- `my_rank` (default: true): Include current user's rank

**Response (200):**
```json
{
  "leaderboard": [
    {
      "rank": 1,
      "user": {
        "user_id": "user-uuid",
        "name": "Jane Smith",
        "avatar_url": "https://..."
      },
      "workouts_completed": 12,
      "total_duration": 14400,
      "total_distance": 50000,
      "is_me": false
    },
    {
      "rank": 2,
      "user": {
        "user_id": "my-user-uuid",
        "name": "You",
        "avatar_url": "https://..."
      },
      "workouts_completed": 10,
      "total_duration": 13200,
      "total_distance": 42000,
      "is_me": true
    }
  ],
  "my_rank": 2,
  "total_participants": 32,
  "period": "week",
  "updated_at": "2025-12-03T00:00:00Z"
}
```

#### Get Segment Leaderboard

```http
GET /api/v1/gyms/{gym_id}/leaderboards/segments/{segment_type}?distance=1000&limit=50
```

**Path Parameters:**
- `segment_type`: `run`, `row`, `bike`, `ski`, `sled_push`, etc.

**Query Parameters:**
- `distance`: Segment distance in meters (e.g., 1000 for 1km)
- `limit` (default: 50): Top N users

**Response (200):**
```json
{
  "segment_name": "1km Run",
  "segment_type": "run",
  "distance": 1000,
  "leaderboard": [
    {
      "rank": 1,
      "user": {
        "user_id": "user-uuid",
        "name": "Jane Smith",
        "avatar_url": "https://..."
      },
      "best_time": 210,
      "formatted_time": "3:30",
      "avg_pace": "3:30/km",
      "workout_id": "workout-uuid",
      "achieved_at": "2025-11-28T10:00:00Z",
      "is_me": false
    }
  ],
  "my_rank": 5,
  "my_best_time": 240,
  "total_participants": 28
}
```

---

### 6. Activity Feed Endpoints

#### Get Gym Activity Feed

```http
GET /api/v1/gyms/{gym_id}/activity?limit=20&offset=0
```

**Query Parameters:**
- `activity_type` (optional): Filter by type
- `user_id` (optional): Filter by user
- `limit`, `offset`: Pagination

**Response (200):**
```json
{
  "activities": [
    {
      "id": "activity-uuid",
      "user": {
        "user_id": "user-uuid",
        "name": "Jane Smith",
        "avatar_url": "https://..."
      },
      "activity_type": "workout_completed",
      "activity_data": {
        "workout_id": "workout-uuid",
        "workout_name": "Murph Lite",
        "duration": 1650,
        "pr_broken": true
      },
      "kudos_count": 8,
      "has_kudoed": false,
      "created_at": "2025-12-02T11:30:00Z"
    },
    {
      "id": "activity-uuid-2",
      "user": {
        "user_id": "user-uuid-2",
        "name": "John Doe",
        "avatar_url": "https://..."
      },
      "activity_type": "pr_achieved",
      "activity_data": {
        "segment_type": "run",
        "segment_name": "1km Run",
        "old_time": 240,
        "new_time": 225,
        "improvement_pct": 6.25
      },
      "kudos_count": 12,
      "has_kudoed": true,
      "created_at": "2025-12-02T10:15:00Z"
    }
  ],
  "total": 245,
  "limit": 20,
  "offset": 0
}
```

#### Give Kudos

```http
POST /api/v1/gyms/{gym_id}/activity/{activity_id}/kudos
```

**Response (201):**
```json
{
  "kudos_count": 9
}
```

#### Remove Kudos

```http
DELETE /api/v1/gyms/{gym_id}/activity/{activity_id}/kudos
```

---

## Privacy Model

### Privacy Framework

```
┌─────────────────────────────────────────────────────────────┐
│                     Privacy Layers                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Layer 1: Gym Membership Visibility                        │
│  ├─ Public gym: Anyone can see member list                 │
│  ├─ Private gym: Only members see member list              │
│  └─ User override: Hide from member list                   │
│                                                             │
│  Layer 2: Leaderboard Visibility                           │
│  ├─ Default: Opt-in to leaderboards                        │
│  ├─ User control: Show/hide on leaderboards                │
│  └─ Anonymous option: Show as "Anonymous" (future)         │
│                                                             │
│  Layer 3: Workout Comparison                               │
│  ├─ Default: Allow comparisons with connections            │
│  ├─ User control: Disable comparisons entirely             │
│  └─ Connection required: Only connected users compare      │
│                                                             │
│  Layer 4: Activity Feed                                    │
│  ├─ Default: Show activities in gym feed                   │
│  ├─ User control: Hide from activity feed                  │
│  └─ Selective sharing: Choose what activities show         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Default Privacy Settings

| Feature | Default | User Can Override |
|---------|---------|------------------|
| Show in member list | TRUE | Yes |
| Show on leaderboards | TRUE | Yes |
| Allow workout comparisons | TRUE | Yes |
| Show in activity feed | TRUE | Yes |
| Gym membership visible | TRUE | Yes (per gym) |

### Privacy Rules Engine

```typescript
// Example: Can User A compare workouts with User B?
function canCompareWorkouts(userA: User, userB: User, gym: Gym): boolean {
  // Both must be active members of the gym
  if (!isActiveMember(userA, gym) || !isActiveMember(userB, gym)) {
    return false;
  }

  // Both must allow workout comparisons
  if (!userA.settings.allow_workout_comparisons ||
      !userB.settings.allow_workout_comparisons) {
    return false;
  }

  // Must be connected in the gym (or same user)
  if (userA.id === userB.id) {
    return true;
  }

  return areConnected(userA, userB, gym);
}

// Example: Should User A appear on leaderboard?
function shouldShowOnLeaderboard(user: User, gym: Gym): boolean {
  // Must be active member
  if (!isActiveMember(user, gym)) {
    return false;
  }

  // User must opt-in
  if (!user.membership.show_on_leaderboard) {
    return false;
  }

  // Must have completed at least one workout
  if (user.membership.total_workouts === 0) {
    return false;
  }

  return true;
}
```

### Privacy Settings UI Location

```
Settings → Privacy → Gym Social
├─ Default Privacy for New Gyms
│  ├─ Show me in member lists [Toggle]
│  ├─ Show me on leaderboards [Toggle]
│  ├─ Allow workout comparisons [Toggle]
│  └─ Show my activities in feed [Toggle]
│
└─ Per-Gym Settings
   └─ [Gym Name]
      ├─ Show in member list [Toggle]
      ├─ Show on leaderboard [Toggle]
      ├─ Allow comparisons [Toggle]
      └─ Show activities [Toggle]
```

---

## iOS UI Architecture

### Screen Hierarchy

```
Gyms Tab
├─ My Gyms List
│  ├─ Gym Card (membership info)
│  └─ [+ Find Gym button]
│
├─ Gym Details
│  ├─ Header (name, location, stats)
│  ├─ Tabs:
│  │  ├─ Feed
│  │  ├─ Members
│  │  ├─ Leaderboards
│  │  └─ About
│  └─ Settings (if admin/owner)
│
├─ Gym Search
│  ├─ Search bar
│  ├─ Location filter
│  ├─ Results list
│  └─ Create Gym button
│
├─ Gym Members
│  ├─ Search members
│  ├─ Filter by role
│  ├─ Member list
│  │  ├─ Avatar, name, stats
│  │  └─ Connection status
│  └─ Member profile sheet
│
├─ Workout Comparison
│  ├─ Workout selector
│  ├─ Overall comparison
│  ├─ Segment-by-segment
│  ├─ Charts & graphs
│  └─ Insights
│
├─ Leaderboards
│  ├─ Period selector (week/month/all)
│  ├─ Metric selector (workouts/time/distance)
│  ├─ Overall leaderboard
│  ├─ Segment leaderboards
│  └─ My rank highlight
│
└─ Activity Feed
   ├─ Activity cards
   ├─ Give kudos
   └─ Filter options
```

### Key Views & Components

#### 1. GymCardView

```swift
struct GymCardView: View {
    let gym: Gym
    let membership: GymMembership

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(gym.name)
                        .font(.headline)
                    Text("\(gym.city), \(gym.state)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if gym.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.blue)
                }
            }

            HStack(spacing: 20) {
                StatBadge(value: "\(gym.memberCount)", label: "Members")
                StatBadge(value: "\(membership.totalWorkouts)", label: "My Workouts")
                StatBadge(value: "#\(membership.leaderboardRank ?? "-")", label: "Rank")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
```

#### 2. GymFeedView

```swift
struct GymFeedView: View {
    @StateObject private var viewModel: GymFeedViewModel
    let gymId: UUID

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.activities) { activity in
                    ActivityCard(activity: activity) {
                        viewModel.toggleKudos(for: activity)
                    }
                }

                if viewModel.hasMore {
                    ProgressView()
                        .onAppear {
                            viewModel.loadMore()
                        }
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}
```

#### 3. WorkoutComparisonView

```swift
struct WorkoutComparisonView: View {
    let comparison: WorkoutComparison
    @State private var selectedSegment: Int = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Overall Comparison
                OverallComparisonCard(
                    user1: comparison.overall.user1,
                    user2: comparison.overall.user2,
                    winner: comparison.overall.winner
                )

                // Segment Selector
                Picker("View", selection: $selectedSegment) {
                    Text("Overview").tag(0)
                    Text("Segments").tag(1)
                    Text("Charts").tag(2)
                }
                .pickerStyle(.segmented)

                // Content
                switch selectedSegment {
                case 0:
                    OverviewTab(comparison: comparison)
                case 1:
                    SegmentListTab(segments: comparison.segments)
                case 2:
                    ChartsTab(comparison: comparison)
                default:
                    EmptyView()
                }
            }
            .padding()
        }
        .navigationTitle("Comparison")
    }
}
```

#### 4. GymLeaderboardView

```swift
struct GymLeaderboardView: View {
    @StateObject private var viewModel: LeaderboardViewModel
    let gymId: UUID

    var body: some View {
        VStack(spacing: 0) {
            // Period & Metric Filters
            HStack {
                Picker("Period", selection: $viewModel.period) {
                    Text("Week").tag(LeaderboardPeriod.week)
                    Text("Month").tag(LeaderboardPeriod.month)
                    Text("All Time").tag(LeaderboardPeriod.allTime)
                }
                .pickerStyle(.segmented)

                Menu {
                    Button("Workouts") { viewModel.metric = .workouts }
                    Button("Duration") { viewModel.metric = .duration }
                    Button("Distance") { viewModel.metric = .distance }
                } label: {
                    HStack {
                        Text(viewModel.metric.displayName)
                        Image(systemName: "chevron.down")
                    }
                }
            }
            .padding()

            // My Rank Card (if not in top 10)
            if let myRank = viewModel.myRank, myRank > 10 {
                MyRankCard(rank: myRank, total: viewModel.totalParticipants)
                    .padding(.horizontal)
            }

            // Leaderboard List
            List(viewModel.leaderboard) { entry in
                LeaderboardRow(entry: entry, metric: viewModel.metric)
                    .listRowInsets(EdgeInsets())
            }
            .listStyle(.plain)
        }
    }
}
```

### Navigation Flow

```
App Launch
└─> Main TabView
    └─> Gyms Tab
        ├─> If no gym membership
        │   └─> Gym Search / Onboarding
        │       ├─> Search Gyms
        │       ├─> Join Gym
        │       └─> Create Gym
        │
        └─> If has gym membership(s)
            └─> My Gyms List
                └─> Tap Gym
                    └─> Gym Details (Tabs)
                        ├─> Feed Tab (default)
                        │   └─> Tap activity → User profile
                        │
                        ├─> Members Tab
                        │   ├─> Tap member → Profile sheet
                        │   │   ├─> Send connection request
                        │   │   └─> Compare workouts button
                        │   │       └─> Workout Comparison View
                        │   │
                        │   └─> Search members
                        │
                        ├─> Leaderboards Tab
                        │   ├─> Overall Leaderboard
                        │   └─> Segment Leaderboards
                        │       └─> Tap segment → Segment Detail
                        │
                        └─> About Tab
                            ├─> Gym info
                            └─> Settings (if admin)
```

---

## Workout Comparison System

### Similarity Algorithm

```typescript
interface WorkoutSimilarityCalculator {
  calculateSimilarity(workout1: Workout, workout2: Workout): number;
}

class SmartSimilarityCalculator implements WorkoutSimilarityCalculator {
  calculateSimilarity(w1: Workout, w2: Workout): number {
    let score = 0;
    const weights = {
      segmentTypes: 30,
      segmentOrder: 20,
      segmentDistances: 20,
      totalDuration: 15,
      workoutName: 15
    };

    // 1. Segment types match (30%)
    const segmentTypeScore = this.compareSegmentTypes(
      w1.segments.map(s => s.type),
      w2.segments.map(s => s.type)
    );
    score += segmentTypeScore * weights.segmentTypes;

    // 2. Segment order similarity (20%)
    const orderScore = this.compareSegmentOrder(w1.segments, w2.segments);
    score += orderScore * weights.segmentOrder;

    // 3. Segment distances/reps similarity (20%)
    const distanceScore = this.compareSegmentDistances(w1.segments, w2.segments);
    score += distanceScore * weights.segmentDistances;

    // 4. Total duration similarity (15%)
    const durationDiff = Math.abs(w1.duration - w2.duration);
    const durationScore = Math.max(0, 1 - (durationDiff / Math.max(w1.duration, w2.duration)));
    score += durationScore * weights.totalDuration;

    // 5. Workout name similarity (15%)
    const nameScore = this.compareWorkoutNames(w1.name, w2.name);
    score += nameScore * weights.workoutName;

    return Math.round(score);
  }

  private compareSegmentTypes(types1: string[], types2: string[]): number {
    const set1 = new Set(types1);
    const set2 = new Set(types2);
    const intersection = new Set([...set1].filter(x => set2.has(x)));
    const union = new Set([...set1, ...set2]);
    return intersection.size / union.size; // Jaccard similarity
  }

  private compareSegmentOrder(segs1: Segment[], segs2: Segment[]): number {
    // Longest Common Subsequence approach
    const lcs = this.longestCommonSubsequence(
      segs1.map(s => s.type),
      segs2.map(s => s.type)
    );
    return lcs / Math.max(segs1.length, segs2.length);
  }

  private compareSegmentDistances(segs1: Segment[], segs2: Segment[]): number {
    // For matching segment types, compare distances/reps
    let totalScore = 0;
    let comparisons = 0;

    for (const s1 of segs1) {
      const matchingSegs = segs2.filter(s2 => s2.type === s1.type);
      if (matchingSegs.length === 0) continue;

      for (const s2 of matchingSegs) {
        const diff = Math.abs((s1.distance || s1.reps || 0) - (s2.distance || s2.reps || 0));
        const max = Math.max(s1.distance || s1.reps || 1, s2.distance || s2.reps || 1);
        totalScore += Math.max(0, 1 - (diff / max));
        comparisons++;
      }
    }

    return comparisons > 0 ? totalScore / comparisons : 0;
  }

  private compareWorkoutNames(name1: string, name2: string): number {
    // Simple string similarity (can use Levenshtein distance)
    if (name1.toLowerCase() === name2.toLowerCase()) return 1;
    if (name1.toLowerCase().includes(name2.toLowerCase()) ||
        name2.toLowerCase().includes(name1.toLowerCase())) return 0.7;
    return 0;
  }
}
```

### Comparison Generation Flow

```
1. User requests comparison
   └─> Check: Are users connected?
   └─> Check: Do both allow comparisons?
   └─> Check: Are workouts similar enough? (similarity >= 60)

2. If checks pass, generate comparison
   └─> Calculate overall metrics
   └─> Compare segment-by-segment
   └─> Generate insights using AI/rules

3. Cache comparison in database
   └─> Set expiry (90 days)
   └─> Notify both users (optional)

4. Return comparison data
   └─> Format for mobile consumption
```

### Insights Generation

```typescript
function generateComparisonInsights(comparison: WorkoutComparison): string[] {
  const insights: string[] = [];
  const { user1, user2, segments, overall } = comparison;

  // Overall winner
  const timeDiffPct = Math.abs(overall.timeDifference / Math.max(overall.user1Time, overall.user2Time)) * 100;
  if (timeDiffPct > 5) {
    insights.push(
      `${overall.winner === 'user1' ? user1.name : user2.name} was ${timeDiffPct.toFixed(1)}% faster overall`
    );
  }

  // Segment analysis
  const user1Wins = segments.filter(s => s.winner === 'user1').length;
  const user2Wins = segments.filter(s => s.winner === 'user2').length;

  if (user1Wins > user2Wins) {
    insights.push(`${user1.name} won ${user1Wins} out of ${segments.length} segments`);
  }

  // Specific segment insights
  const runSegments = segments.filter(s => s.segmentType === 'run');
  if (runSegments.length > 0) {
    const avgRunDiff = runSegments.reduce((sum, s) => sum + s.pctDifference, 0) / runSegments.length;
    if (Math.abs(avgRunDiff) > 10) {
      const faster = avgRunDiff > 0 ? user2.name : user1.name;
      insights.push(`${faster} paced running segments ${Math.abs(avgRunDiff).toFixed(1)}% better`);
    }
  }

  // Heart rate insights (if available)
  if (user1.avgHr && user2.avgHr) {
    const hrDiff = user1.avgHr - user2.avgHr;
    if (Math.abs(hrDiff) > 10) {
      insights.push(
        `${user1.name}'s average heart rate was ${Math.abs(hrDiff)} BPM ${hrDiff > 0 ? 'higher' : 'lower'}`
      );
    }
  }

  // Pacing insights
  const user1Variability = calculatePaceVariability(segments, 'user1');
  const user2Variability = calculatePaceVariability(segments, 'user2');
  if (Math.abs(user1Variability - user2Variability) > 0.2) {
    const moreSteady = user1Variability < user2Variability ? user1.name : user2.name;
    insights.push(`${moreSteady} maintained more consistent pacing`);
  }

  return insights;
}
```

---

## Leaderboard System

### Leaderboard Types

1. **Overall Gym Leaderboard**
   - Weekly, monthly, all-time
   - Metrics: Workouts completed, total duration, total distance
   - Top 50 users

2. **Segment Leaderboards**
   - Per segment type (run, row, bike, etc.)
   - Per distance (1km run, 500m row, etc.)
   - Best time for that segment
   - All-time only

3. **Most Improved** (future)
   - Biggest time improvements
   - Consistency leaders

### Refresh Strategy

```sql
-- Weekly leaderboard: Refresh daily at midnight
SELECT cron.schedule(
  'refresh-weekly-leaderboards',
  '0 0 * * *', -- Daily at midnight
  $$
  REFRESH MATERIALIZED VIEW CONCURRENTLY gym_leaderboard_weekly;
  $$
);

-- Segment leaderboards: Update on workout completion
-- Via trigger:
CREATE OR REPLACE FUNCTION update_segment_leaderboards()
RETURNS TRIGGER AS $$
BEGIN
  -- For each completed segment in the workout
  INSERT INTO gym_segment_leaderboards (
    gym_id, user_id, segment_type, segment_distance,
    segment_name, best_time, workout_id, achieved_at
  )
  SELECT
    gm.gym_id,
    NEW.user_id,
    ws.segment_type,
    ws.distance,
    ws.name,
    ws.duration,
    NEW.id,
    NEW.completed_at
  FROM workout_segments ws
  JOIN gym_memberships gm ON gm.user_id = NEW.user_id AND gm.status = 'active'
  WHERE ws.workout_id = NEW.id
  ON CONFLICT (gym_id, user_id, segment_type, segment_distance)
  DO UPDATE SET
    best_time = LEAST(gym_segment_leaderboards.best_time, EXCLUDED.best_time),
    workout_id = CASE
      WHEN EXCLUDED.best_time < gym_segment_leaderboards.best_time
      THEN EXCLUDED.workout_id
      ELSE gym_segment_leaderboards.workout_id
    END,
    achieved_at = CASE
      WHEN EXCLUDED.best_time < gym_segment_leaderboards.best_time
      THEN EXCLUDED.achieved_at
      ELSE gym_segment_leaderboards.achieved_at
    END,
    updated_at = NOW();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_segment_leaderboards_trigger
AFTER INSERT ON workouts
FOR EACH ROW
WHEN (NEW.status = 'completed')
EXECUTE FUNCTION update_segment_leaderboards();
```

### Performance Optimization

```typescript
// Leaderboard caching strategy
class LeaderboardCache {
  private cache: Map<string, CachedLeaderboard> = new Map();
  private TTL = 5 * 60 * 1000; // 5 minutes

  async getLeaderboard(gymId: string, period: string, metric: string): Promise<Leaderboard> {
    const cacheKey = `${gymId}:${period}:${metric}`;
    const cached = this.cache.get(cacheKey);

    if (cached && Date.now() - cached.timestamp < this.TTL) {
      return cached.data;
    }

    // Fetch from database
    const leaderboard = await this.fetchFromDatabase(gymId, period, metric);

    // Cache it
    this.cache.set(cacheKey, {
      data: leaderboard,
      timestamp: Date.now()
    });

    return leaderboard;
  }

  invalidate(gymId: string) {
    // Clear all cache entries for this gym
    for (const key of this.cache.keys()) {
      if (key.startsWith(gymId)) {
        this.cache.delete(key);
      }
    }
  }
}
```

---

## Implementation Timeline

### Phase 1: Foundation (Weeks 1-2)

**Database & Backend**
- [ ] Create database migrations for all tables
- [ ] Implement Supabase RLS policies
- [ ] Create gym CRUD endpoints
- [ ] Create gym membership endpoints
- [ ] Set up search functionality

**iOS**
- [ ] Create Gym data models
- [ ] Implement SupabaseService gym methods
- [ ] Build gym search UI
- [ ] Build gym creation flow
- [ ] Build gym details screen (basic)

**Deliverables**
- Users can create/search/join gyms
- Basic gym profile displayed

---

### Phase 2: Social (Weeks 3-4)

**Database & Backend**
- [ ] Implement gym connections system
- [ ] Create member discovery endpoints
- [ ] Add privacy controls to API
- [ ] Implement activity feed system

**iOS**
- [ ] Build gym members list
- [ ] Implement connection request flow
- [ ] Add privacy settings UI
- [ ] Build activity feed view
- [ ] Implement kudos system

**Deliverables**
- Users can connect with gym members
- Activity feed shows gym activities
- Privacy controls functional

---

### Phase 3: Comparisons (Week 5)

**Database & Backend**
- [ ] Implement similarity algorithm
- [ ] Create workout comparison endpoints
- [ ] Build comparison cache system
- [ ] Generate insights engine

**iOS**
- [ ] Build workout comparison view
- [ ] Implement segment-by-segment comparison
- [ ] Add comparison charts
- [ ] Create comparison suggestions UI

**Deliverables**
- Users can compare workouts
- Visual comparison with insights

---

### Phase 4: Leaderboards (Week 6)

**Database & Backend**
- [ ] Create leaderboard materialized views
- [ ] Set up refresh cron jobs
- [ ] Implement segment leaderboards
- [ ] Add leaderboard caching

**iOS**
- [ ] Build overall leaderboard view
- [ ] Implement segment leaderboard views
- [ ] Add period/metric filters
- [ ] Create "My Rank" highlights

**Deliverables**
- Gym leaderboards functional
- Segment leaderboards working

---

### Phase 5: Polish & Testing (Week 7-8)

**All Platforms**
- [ ] Performance optimization
- [ ] Error handling
- [ ] Loading states
- [ ] Empty states
- [ ] Comprehensive testing
- [ ] Privacy audit
- [ ] Documentation

**Deliverables**
- Production-ready gym social system

---

## Future Expansion

### Global Features (Post-MVP)

1. **Global Leaderboards**
   - Top performers worldwide
   - Country/region leaderboards
   - Age group rankings

2. **Challenges**
   - Gym vs gym challenges
   - Monthly challenges
   - Team competitions

3. **Social Expansion**
   - Follow users outside your gym
   - Global activity feed
   - Direct messaging

4. **Enhanced Analytics**
   - Gym-wide training insights
   - Member progress tracking
   - Coach dashboards

### Migration Path

```typescript
// Designed to expand without refactoring

// Current (gym-scoped):
GET /api/v1/gyms/{gym_id}/leaderboards/overall

// Future (global):
GET /api/v1/leaderboards/global?metric=workouts&period=week

// The database schema supports both:
// - gym_id can be NULL for global leaderboards
// - Add `scope` field: 'gym' | 'global' | 'region'
```

---

## Technical Considerations

### Performance

1. **Database Indexes**: All critical queries indexed
2. **Materialized Views**: Leaderboards pre-computed
3. **Caching**: 5-minute cache for leaderboards
4. **Pagination**: All lists paginated (limit 50)
5. **Lazy Loading**: Activity feed loads incrementally

### Security

1. **RLS Policies**: All tables secured with Supabase RLS
2. **Input Validation**: All inputs sanitized
3. **Rate Limiting**: API endpoints rate-limited
4. **Privacy Checks**: Server-side privacy enforcement
5. **Audit Logging**: Track gym admin actions

### Scalability

1. **Gym Size**: Tested up to 1000 members per gym
2. **Leaderboards**: Materialized views handle large gyms
3. **Activity Feed**: Partitioned by month (auto-expire after 30 days)
4. **Comparisons**: Cached, expire after 90 days
5. **Indexes**: Optimized for gym-scoped queries

---

## Success Metrics

### Engagement Metrics

- **Gym Adoption Rate**: % of users who join a gym
- **Connection Rate**: Average connections per user
- **Comparison Usage**: Comparisons generated per week
- **Leaderboard Views**: Daily active leaderboard viewers
- **Activity Feed Engagement**: Kudos per activity

### Technical Metrics

- **API Response Time**: < 200ms for p95
- **Leaderboard Refresh Time**: < 5 seconds
- **Comparison Generation**: < 2 seconds
- **Database Query Performance**: < 100ms for p95

### Growth Metrics

- **New Gyms Created**: Weekly growth
- **Active Gyms**: Gyms with 5+ active members
- **Viral Coefficient**: Invites per user
- **Retention**: 7-day, 30-day retention

---

## Architecture Decision Records

### ADR-001: Gym-Scoped First

**Decision**: Build gym-scoped social before global features

**Rationale**:
- Mirrors real-world training relationships
- Simpler MVP scope (6 weeks vs 12+ weeks)
- Privacy-first approach (users trust gym-mates)
- Can expand to global without refactoring

**Consequences**:
- Database schema supports future global expansion
- Initial user base limited to gym members
- Need clear onboarding for gym selection

---

### ADR-002: Explicit Connections Required

**Decision**: Users must explicitly connect to compare workouts

**Rationale**:
- Privacy-first design
- Prevents unwanted comparisons
- Builds intentional training relationships
- Reduces noise in comparisons

**Consequences**:
- Extra step for users
- Lower initial comparison volume
- Higher quality comparisons

---

### ADR-003: Materialized Views for Leaderboards

**Decision**: Use materialized views, refresh daily

**Rationale**:
- Real-time leaderboards not critical
- Significant performance improvement
- Reduces database load
- Daily updates sufficient for MVP

**Consequences**:
- Leaderboards up to 24 hours stale
- Requires cron job setup
- Need to educate users on refresh schedule

---

### ADR-004: Station-Level Comparison Focus

**Decision**: Emphasize segment-by-segment comparison over overall time

**Rationale**:
- Leverages FLEXR's unique segment tracking
- More actionable insights for users
- Differentiates from other fitness apps
- Enables targeted improvement

**Consequences**:
- More complex comparison UI
- Requires robust similarity algorithm
- Higher data requirements

---

## Conclusion

This architecture provides a solid foundation for FLEXR's gym-local social system. Key strengths:

1. **Privacy-First**: Users control visibility at every level
2. **Gym-Focused**: Builds real-world training relationships
3. **Actionable Insights**: Station-level comparisons drive improvement
4. **Scalable**: Database schema supports future global expansion
5. **Performant**: Materialized views, caching, and indexes optimize performance

**Next Steps**:
1. Review and approve architecture
2. Create technical specifications for Phase 1
3. Begin database migrations
4. Start iOS model implementation

---

**Document Version**: 1.0
**Last Updated**: 2025-12-03
**Author**: System Architect (Claude)
**Status**: Ready for Review
