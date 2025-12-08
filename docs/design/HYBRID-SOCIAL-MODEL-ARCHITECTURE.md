# FLEXR Hybrid Social Model - Complete Architecture

**Version**: 1.0
**Last Updated**: 2025-12-03
**Status**: Design Phase

## Executive Summary

This document defines FLEXR's Hybrid Social Model - a 3-layer social system that maintains gym-local discovery while enabling cross-gym friendships and race partnerships. This architecture solves the real-world problem: "My friend trains at a different gym, but we're race partners."

**Core Philosophy**: Local-first discovery, global friendship capability, privacy-preserved.

---

## Table of Contents

1. [Problem Statement](#problem-statement)
2. [3-Layer Social Architecture](#3-layer-social-architecture)
3. [Unified Database Schema](#unified-database-schema)
4. [Privacy Permission Matrix](#privacy-permission-matrix)
5. [API Design](#api-design)
6. [Activity Feed Architecture](#activity-feed-architecture)
7. [iOS UI/UX Flows](#ios-uiux-flows)
8. [Edge Cases & Solutions](#edge-cases--solutions)
9. [Migration Strategy](#migration-strategy)
10. [Architecture Decision Records](#architecture-decision-records)

---

## Problem Statement

### Current Design Limitations

**Gym-Local Social (existing)**:
- Users at same gym can see each other
- Gym leaderboards and comparisons
- Problem: Doesn't support friends at different gyms

**Race Partner System (existing)**:
- Special partnership for doubles teams
- Works across gyms
- Problem: Too heavy for casual friendships

### Real-World Use Cases Not Supported

1. "My friend trains at CrossFit Box A, I'm at Box B, but we're not race partners"
2. "I have 3 training buddies - 1 at my gym, 2 at other gyms"
3. "I train at home but want to compare workouts with gym friends"
4. "My gym buddy moved cities but we still want to stay connected"
5. "I visit my friend's gym occasionally to train together"

### Requirements

1. **Maintain local-first philosophy** - No public profiles, no followers
2. **Enable cross-gym friendships** - Direct friend connections work anywhere
3. **Preserve race partner system** - Enhanced features for serious training
4. **Simple mental model** - Users understand the 3 layers intuitively
5. **Privacy-first** - Explicit connections required, granular permissions
6. **Expandable** - Can grow to global features later without refactoring

---

## 3-Layer Social Architecture

### Conceptual Model

```
┌─────────────────────────────────────────────────────────────┐
│                  FLEXR Social Layers                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Layer 1: GYM MEMBERS (Same Gym)                           │
│  ├─ Auto-discovery: See members at your gym(s)             │
│  ├─ Gym leaderboards                                        │
│  ├─ Low friction: Tap to connect                           │
│  ├─ Gym-scoped: Only visible when both are members         │
│  └─ Privacy: Can hide from gym member list                 │
│                                                             │
│  Layer 2: FRIENDS (Cross-Gym)                              │
│  ├─ Explicit connection: Must add each other               │
│  ├─ Discovery: Search, invite code, QR code                │
│  ├─ Works globally: Any gym, no gym, different gyms        │
│  ├─ Workout comparison: Just like gym members              │
│  ├─ Activity feed: See friend workouts                     │
│  └─ Privacy: Granular permissions per friend               │
│                                                             │
│  Layer 3: RACE PARTNERS (Enhanced Features)                │
│  ├─ Special friend type: Subset of friends                 │
│  ├─ Race preparation: Doubles strategy, team dashboard     │
│  ├─ Enhanced permissions: Share more data                  │
│  ├─ Team features: Combined analytics, race planning       │
│  └─ Most permissive: Highest trust level                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Relationship Hierarchy

```
Gym Member (at same gym)
    ↓ [Send friend request]
Friend (works anywhere)
    ↓ [Become race partners]
Race Partner (doubles team)
```

**Key Rules**:
- Gym members can become friends (promotes to Layer 2)
- Friends can become race partners (promotes to Layer 3)
- Race partners are always friends
- You can be friends without being gym members
- You can have multiple gyms, multiple friends, multiple race partners

### Comparison Matrix

| Feature | Gym Members | Friends | Race Partners |
|---------|-------------|---------|---------------|
| **Discovery** | Automatic (same gym) | Manual (search/invite) | Manual (from friends) |
| **Cross-gym** | No | Yes | Yes |
| **Workout comparison** | Yes (if connected) | Yes | Yes (enhanced) |
| **Activity feed** | Gym feed only | Personal feed | Personal feed |
| **Leaderboards** | Gym leaderboards | No | Partner leaderboard |
| **Shared dashboard** | No | No | Yes |
| **Strategy planning** | No | No | Yes |
| **Permission level** | Low | Medium | High |

---

## Unified Database Schema

### Design Philosophy

**Single Relationship Table Approach**: One `user_relationships` table handles all 3 layers with a `relationship_type` field. This:
- Simplifies queries (one table to check)
- Enables easy promotion (gym member → friend → partner)
- Reduces join complexity
- Maintains relationship history

### Core Tables

#### 1. `user_relationships` (Unified Relationship Table)

```sql
CREATE TABLE user_relationships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Participants (always user_a_id < user_b_id for consistency)
  user_a_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user_b_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Relationship Type (can evolve over time)
  relationship_type TEXT NOT NULL CHECK (relationship_type IN (
    'gym_member',      -- Layer 1: At same gym
    'friend',          -- Layer 2: Direct friend connection
    'race_partner'     -- Layer 3: Race partner (implies friend)
  )),

  -- Connection Context
  gym_id UUID REFERENCES gyms(id) ON DELETE SET NULL, -- Only for gym_member type

  -- Status
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending',    -- Friend/partner request sent, awaiting response
    'active',     -- Connection established
    'paused',     -- Temporarily disabled (race partner feature)
    'blocked',    -- One user blocked the other
    'ended'       -- Connection removed
  )),

  -- Race Partner Fields (only used if relationship_type = 'race_partner')
  team_name TEXT,
  target_race_date DATE,
  target_race_name TEXT,
  race_location TEXT,

  -- Metadata
  requested_by UUID REFERENCES users(id), -- Who initiated (for pending)
  requested_at TIMESTAMPTZ DEFAULT NOW(),
  accepted_at TIMESTAMPTZ,
  last_interaction_at TIMESTAMPTZ,
  total_interactions INTEGER DEFAULT 0,

  -- Relationship evolution tracking
  promoted_from TEXT, -- Previous type before upgrade
  promoted_at TIMESTAMPTZ,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraints
  UNIQUE(user_a_id, user_b_id, relationship_type, gym_id),
  CHECK (user_a_id < user_b_id)
);

-- Indexes for fast lookups
CREATE INDEX idx_relationships_user_a ON user_relationships(user_a_id, status);
CREATE INDEX idx_relationships_user_b ON user_relationships(user_b_id, status);
CREATE INDEX idx_relationships_type ON user_relationships(relationship_type, status);
CREATE INDEX idx_relationships_gym ON user_relationships(gym_id) WHERE gym_id IS NOT NULL;
CREATE INDEX idx_relationships_race_date ON user_relationships(target_race_date)
  WHERE relationship_type = 'race_partner' AND target_race_date IS NOT NULL;
```

**Why this design?**:
- Single source of truth for all relationships
- Easy to query "all friends of user X" regardless of type
- Relationship evolution tracked (gym member → friend → partner)
- Efficient: One table instead of 3+ separate tables
- Flexible: Add new relationship types without schema change

#### 2. `relationship_permissions` (Granular Privacy Control)

```sql
CREATE TABLE relationship_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- References
  relationship_id UUID NOT NULL REFERENCES user_relationships(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- What THIS user shares with the OTHER user in this relationship

  -- Workout Visibility
  share_workout_completion BOOLEAN DEFAULT true,   -- "I completed a workout"
  share_workout_details BOOLEAN DEFAULT true,      -- Segments, times, targets
  share_performance_metrics BOOLEAN DEFAULT true,  -- HR, pace, distance
  share_workout_videos BOOLEAN DEFAULT false,      -- Video recordings

  -- Training Data
  share_training_plan BOOLEAN DEFAULT false,       -- Weekly plan overview
  share_readiness_score BOOLEAN DEFAULT true,      -- Daily readiness
  share_benchmarks BOOLEAN DEFAULT true,           -- PRs, time trials
  share_injuries BOOLEAN DEFAULT false,            -- Injury/limitation info

  -- Profile Data
  share_equipment_access BOOLEAN DEFAULT true,     -- Gym/equipment availability
  share_location BOOLEAN DEFAULT false,            -- Training location

  -- Comparison Features
  allow_workout_comparison BOOLEAN DEFAULT true,   -- Can compare workouts
  show_in_activity_feed BOOLEAN DEFAULT true,      -- Show my activities

  -- Notification Preferences (what THIS user wants to be notified about)
  notify_workout_completed BOOLEAN DEFAULT true,
  notify_workout_started BOOLEAN DEFAULT false,
  notify_milestone_reached BOOLEAN DEFAULT true,
  notify_workout_missed BOOLEAN DEFAULT false,
  notify_race_countdown BOOLEAN DEFAULT true,      -- Only for race partners

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraints
  UNIQUE(relationship_id, user_id)
);

-- Index for fast permission checks
CREATE INDEX idx_rel_permissions_relationship ON relationship_permissions(relationship_id);
CREATE INDEX idx_rel_permissions_user ON relationship_permissions(user_id);
```

**Permission Defaults by Relationship Type**:
```sql
-- Function to create default permissions based on relationship type
CREATE OR REPLACE FUNCTION create_default_relationship_permissions()
RETURNS TRIGGER AS $$
DECLARE
  default_settings JSONB;
BEGIN
  -- Set defaults based on relationship type
  CASE NEW.relationship_type
    WHEN 'gym_member' THEN
      default_settings := '{
        "share_workout_completion": true,
        "share_workout_details": false,
        "share_performance_metrics": false,
        "allow_workout_comparison": true,
        "show_in_activity_feed": true
      }';
    WHEN 'friend' THEN
      default_settings := '{
        "share_workout_completion": true,
        "share_workout_details": true,
        "share_performance_metrics": true,
        "allow_workout_comparison": true,
        "show_in_activity_feed": true
      }';
    WHEN 'race_partner' THEN
      default_settings := '{
        "share_workout_completion": true,
        "share_workout_details": true,
        "share_performance_metrics": true,
        "share_training_plan": true,
        "share_readiness_score": true,
        "share_benchmarks": true,
        "allow_workout_comparison": true,
        "show_in_activity_feed": true
      }';
  END CASE;

  -- Create permissions for both users
  INSERT INTO relationship_permissions (relationship_id, user_id)
  VALUES (NEW.id, NEW.user_a_id);

  INSERT INTO relationship_permissions (relationship_id, user_id)
  VALUES (NEW.id, NEW.user_b_id);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER create_relationship_permissions_trigger
AFTER INSERT ON user_relationships
FOR EACH ROW
EXECUTE FUNCTION create_default_relationship_permissions();
```

#### 3. `friend_requests` (Separate from relationships for pending state)

```sql
CREATE TABLE friend_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Participants
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Request details
  relationship_type TEXT NOT NULL CHECK (relationship_type IN (
    'friend',
    'race_partner'
  )),

  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending',
    'accepted',
    'declined',
    'expired',
    'cancelled'
  )),

  -- Optional message and context
  message TEXT,
  proposed_team_name TEXT,        -- For race partner requests
  proposed_race_date DATE,
  proposed_race_name TEXT,

  -- Discovery method
  discovery_method TEXT CHECK (discovery_method IN (
    'search',           -- Found via search
    'invite_code',      -- Used invite code
    'qr_code',          -- Scanned QR code
    'gym_member',       -- From gym members list
    'suggested',        -- AI/system suggested
    'contacts_import'   -- From phone contacts (future)
  )),

  -- Timestamps
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  responded_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '30 days'),

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraints
  CHECK (sender_id != recipient_id)
);

-- Indexes
CREATE INDEX idx_friend_requests_recipient ON friend_requests(recipient_id, status);
CREATE INDEX idx_friend_requests_sender ON friend_requests(sender_id, status);
CREATE INDEX idx_friend_requests_expires ON friend_requests(expires_at)
  WHERE status = 'pending';
```

#### 4. `friend_invite_codes` (Enable easy friend discovery)

```sql
CREATE TABLE friend_invite_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Owner
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Code details
  code TEXT UNIQUE NOT NULL,  -- Short code: "ALEX-2025" or "FLEXR-JOHN-SF"
  code_type TEXT NOT NULL CHECK (code_type IN (
    'friend',          -- General friend invite
    'race_partner'     -- Race partner specific
  )),

  -- Usage limits
  max_uses INTEGER DEFAULT NULL,  -- NULL = unlimited
  current_uses INTEGER DEFAULT 0,

  -- Race context (optional, for race_partner codes)
  race_date DATE,
  race_name TEXT,
  team_name TEXT,

  -- Status
  is_active BOOLEAN DEFAULT true,
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '90 days'),

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraints
  CHECK (max_uses IS NULL OR current_uses <= max_uses)
);

-- Indexes
CREATE INDEX idx_invite_codes_code ON friend_invite_codes(code)
  WHERE is_active = true;
CREATE INDEX idx_invite_codes_user ON friend_invite_codes(user_id);
```

#### 5. `activity_feed` (Unified Feed for Friends + Gym)

```sql
CREATE TABLE activity_feed (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Actor (who did the activity)
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Activity type
  activity_type TEXT NOT NULL CHECK (activity_type IN (
    'workout_completed',
    'pr_achieved',
    'milestone_reached',
    'joined_gym',
    'friend_added',
    'partner_formed',
    'race_registered',
    'race_completed',
    'streak_milestone',
    'challenge_completed'
  )),

  -- Activity data
  activity_data JSONB NOT NULL,
  -- Examples:
  -- workout_completed: {workout_id, workout_name, duration, pr_broken}
  -- pr_achieved: {segment_type, old_time, new_time, improvement_pct}
  -- milestone_reached: {milestone_type, count, description}

  -- Visibility rules
  visibility TEXT NOT NULL DEFAULT 'friends' CHECK (visibility IN (
    'friends',      -- Only friends can see
    'gym_members',  -- Only gym members can see
    'both',         -- Both friends and gym members
    'private'       -- Hidden from everyone
  )),

  -- Context (optional)
  gym_id UUID REFERENCES gyms(id) ON DELETE SET NULL,  -- For gym-scoped activities

  -- Engagement
  kudos_count INTEGER DEFAULT 0,
  comment_count INTEGER DEFAULT 0,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '90 days')
);

-- Indexes
CREATE INDEX idx_activity_user ON activity_feed(user_id, created_at DESC);
CREATE INDEX idx_activity_gym ON activity_feed(gym_id, created_at DESC)
  WHERE gym_id IS NOT NULL;
CREATE INDEX idx_activity_created ON activity_feed(created_at DESC);
CREATE INDEX idx_activity_expires ON activity_feed(expires_at)
  WHERE expires_at < NOW();
```

#### 6. `activity_kudos` (Reactions to activities)

```sql
CREATE TABLE activity_kudos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- References
  activity_id UUID NOT NULL REFERENCES activity_feed(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Kudos type
  kudos_type TEXT DEFAULT 'default' CHECK (kudos_type IN (
    'default',    -- 👍 Nice work
    'fire',       -- 🔥 Crushing it
    'strong',     -- 💪 Great strength
    'fast',       -- ⚡ Speed demon
    'consistent', -- 📅 Showing up
    'comeback'    -- 💥 Back at it
  )),

  -- Timestamp
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraints
  UNIQUE(activity_id, user_id)
);

-- Indexes
CREATE INDEX idx_kudos_activity ON activity_kudos(activity_id);
CREATE INDEX idx_kudos_user ON activity_kudos(user_id, created_at DESC);
```

### Relationship Evolution Example

```sql
-- Example: User progression from gym member → friend → race partner

-- 1. Both users join same gym (automatic gym member relationship)
INSERT INTO user_relationships (user_a_id, user_b_id, relationship_type, gym_id, status)
VALUES ('alice-id', 'bob-id', 'gym_member', 'crossfit-downtown-id', 'active');

-- 2. Alice sends friend request to Bob
INSERT INTO friend_requests (sender_id, recipient_id, relationship_type, discovery_method)
VALUES ('alice-id', 'bob-id', 'friend', 'gym_member');

-- 3. Bob accepts → Create friend relationship
INSERT INTO user_relationships (
  user_a_id, user_b_id, relationship_type, status,
  requested_by, accepted_at, promoted_from, promoted_at
)
VALUES (
  'alice-id', 'bob-id', 'friend', 'active',
  'alice-id', NOW(), 'gym_member', NOW()
);

-- 4. Later, they decide to race together → Promote to race partner
UPDATE user_relationships
SET
  relationship_type = 'race_partner',
  promoted_from = 'friend',
  promoted_at = NOW(),
  team_name = 'Team Thunder',
  target_race_date = '2025-09-15',
  target_race_name = 'HYROX Los Angeles'
WHERE user_a_id = 'alice-id' AND user_b_id = 'bob-id';
```

---

## Privacy Permission Matrix

### Permission Levels by Relationship Type

| Feature | Gym Member | Friend | Race Partner |
|---------|------------|--------|--------------|
| **Discovery** |
| Visible in member list | Yes (default) | N/A | N/A |
| Searchable by name | No | Yes (if friends) | Yes |
| QR code sharing | No | Yes | Yes |
| **Workout Data** |
| See completion | No (unless friends) | Yes (default) | Yes (default) |
| See workout details | No | Yes (default) | Yes (default) |
| See segments | No | Yes (default) | Yes (default) |
| See performance metrics | No | Yes (default) | Yes (default) |
| See workout videos | No | No (default) | No (default) |
| **Training Data** |
| See training plan | No | No (default) | Yes (default) |
| See readiness score | No | Yes (default) | Yes (default) |
| See PRs/benchmarks | No | Yes (default) | Yes (default) |
| See injuries | No | No (default) | No (default) |
| **Features** |
| Workout comparison | Yes (if connected) | Yes (default) | Yes (default) |
| Activity feed | Gym feed only | Personal feed | Personal feed |
| Kudos/reactions | Yes | Yes | Yes |
| Direct messaging | No | No (future) | Yes (future) |
| Shared dashboard | No | No | Yes |
| Strategy planning | No | No | Yes |

### Permission Override Rules

```typescript
// Server-side permission check function
function canViewWorkoutDetails(
  viewer: User,
  owner: User,
  workout: Workout
): boolean {
  // 1. Owner can always see their own workouts
  if (viewer.id === owner.id) return true;

  // 2. Check if there's an active relationship
  const relationship = getActiveRelationship(viewer.id, owner.id);
  if (!relationship) return false;

  // 3. Get owner's permissions for this relationship
  const permissions = getPermissions(relationship.id, owner.id);

  // 4. Check specific permission
  if (!permissions.share_workout_details) return false;

  // 5. Relationship-type specific rules
  switch (relationship.relationship_type) {
    case 'gym_member':
      // Gym members need explicit connection OR both must allow comparisons
      const gymConnection = getGymConnection(viewer.id, owner.id, relationship.gym_id);
      return gymConnection?.status === 'accepted' ||
             (permissions.allow_workout_comparison && viewer.allowsComparisons);

    case 'friend':
      // Friends can see if owner shares workout details
      return true;

    case 'race_partner':
      // Race partners have highest access
      return true;

    default:
      return false;
  }
}
```

### Default Privacy Settings

Users can set default privacy for new relationships:

```sql
-- Add to users table
ALTER TABLE users ADD COLUMN default_friend_privacy JSONB DEFAULT '{
  "share_workout_completion": true,
  "share_workout_details": true,
  "share_performance_metrics": true,
  "share_training_plan": false,
  "share_readiness_score": true,
  "share_benchmarks": true,
  "share_injuries": false,
  "share_workout_videos": false,
  "allow_workout_comparison": true,
  "show_in_activity_feed": true
}';
```

---

## API Design

### Base URL Structure

```
/api/v1/relationships/*  - Unified relationship management
/api/v1/friends/*        - Friend-specific features
/api/v1/gyms/*           - Gym member features (existing)
/api/v1/partners/*       - Race partner features (existing, enhanced)
```

### Core Relationship Endpoints

#### Get My Relationships

```http
GET /api/v1/relationships?type=friend&status=active
```

**Query Parameters**:
- `type` (optional): Filter by relationship_type (gym_member, friend, race_partner)
- `status` (optional): Filter by status (active, pending, etc.)
- `gym_id` (optional): Filter by specific gym
- `limit`, `offset`: Pagination

**Response (200)**:
```json
{
  "relationships": [
    {
      "id": "rel-uuid",
      "relationship_type": "friend",
      "status": "active",
      "connected_user": {
        "user_id": "user-uuid",
        "name": "Jane Smith",
        "avatar_url": "https://...",
        "total_workouts": 45,
        "current_streak": 12
      },
      "gym_id": null,
      "created_at": "2025-11-15T10:00:00Z",
      "last_interaction_at": "2025-12-02T18:30:00Z",
      "can_compare_workouts": true,
      "can_view_details": true
    },
    {
      "id": "rel-uuid-2",
      "relationship_type": "gym_member",
      "status": "active",
      "connected_user": {
        "user_id": "user-uuid-2",
        "name": "John Doe",
        "avatar_url": "https://..."
      },
      "gym": {
        "gym_id": "gym-uuid",
        "name": "CrossFit Downtown"
      },
      "created_at": "2025-10-01T14:00:00Z"
    }
  ],
  "counts": {
    "friends": 8,
    "gym_members": 12,
    "race_partners": 1,
    "pending_requests": 2
  }
}
```

#### Send Friend Request

```http
POST /api/v1/relationships/request
Content-Type: application/json

{
  "recipient_id": "user-uuid",
  "relationship_type": "friend",  // or "race_partner"
  "message": "Hey! Let's train together!",
  "discovery_method": "search",   // or "invite_code", "qr_code", "gym_member"

  // Optional: For race partner requests
  "proposed_team_name": "Team Thunder",
  "proposed_race_date": "2025-09-15",
  "proposed_race_name": "HYROX Los Angeles"
}
```

**Response (201)**:
```json
{
  "request_id": "request-uuid",
  "sender_id": "my-user-id",
  "recipient_id": "user-uuid",
  "relationship_type": "friend",
  "status": "pending",
  "message": "Hey! Let's train together!",
  "sent_at": "2025-12-03T10:00:00Z",
  "expires_at": "2026-01-02T10:00:00Z"
}
```

#### Accept/Decline Friend Request

```http
PATCH /api/v1/relationships/request/{request_id}
Content-Type: application/json

{
  "action": "accept"  // or "decline"
}
```

**Response (200)** (if accepted):
```json
{
  "relationship_id": "rel-uuid",
  "relationship_type": "friend",
  "status": "active",
  "connected_user": {
    "user_id": "sender-user-id",
    "name": "John Doe",
    "avatar_url": "https://..."
  },
  "created_at": "2025-12-03T10:05:00Z"
}
```

#### Promote Relationship

```http
PATCH /api/v1/relationships/{relationship_id}/promote
Content-Type: application/json

{
  "to_type": "race_partner",  // Promote friend → race_partner
  "team_name": "Team Thunder",
  "target_race_date": "2025-09-15",
  "target_race_name": "HYROX Los Angeles"
}
```

**Response (200)**:
```json
{
  "relationship_id": "rel-uuid",
  "relationship_type": "race_partner",
  "promoted_from": "friend",
  "promoted_at": "2025-12-03T10:10:00Z",
  "team_name": "Team Thunder",
  "target_race_date": "2025-09-15"
}
```

#### Update Relationship Permissions

```http
PATCH /api/v1/relationships/{relationship_id}/permissions
Content-Type: application/json

{
  "share_workout_details": true,
  "share_performance_metrics": true,
  "share_training_plan": false,
  "allow_workout_comparison": true,
  "notify_workout_completed": true
}
```

#### Remove Relationship

```http
DELETE /api/v1/relationships/{relationship_id}
```

**Response (200)**:
```json
{
  "message": "Relationship ended successfully",
  "relationship_id": "rel-uuid"
}
```

### Friend Discovery Endpoints

#### Search for Friends

```http
GET /api/v1/friends/search?q=john&limit=20
```

**Query Parameters**:
- `q`: Search query (name, email)
- `limit`, `offset`: Pagination

**Response (200)**:
```json
{
  "results": [
    {
      "user_id": "user-uuid",
      "name": "John Doe",
      "avatar_url": "https://...",
      "shared_gyms": [
        {
          "gym_id": "gym-uuid",
          "name": "CrossFit Downtown"
        }
      ],
      "relationship_status": null,  // or "pending", "active"
      "mutual_friends_count": 3
    }
  ],
  "total": 1
}
```

#### Generate Invite Code

```http
POST /api/v1/friends/invite-code
Content-Type: application/json

{
  "code_type": "friend",  // or "race_partner"
  "max_uses": 1,          // null for unlimited
  "expires_in_days": 30,

  // Optional: For race partner codes
  "race_date": "2025-09-15",
  "race_name": "HYROX Los Angeles",
  "team_name": "Team Thunder"
}
```

**Response (201)**:
```json
{
  "invite_code": "ALEX-FLEXR-2025",
  "code_type": "friend",
  "max_uses": 1,
  "current_uses": 0,
  "expires_at": "2026-01-02T10:00:00Z",
  "share_url": "https://flexr.app/invite/ALEX-FLEXR-2025",
  "qr_code_url": "https://api.flexr.app/v1/friends/qr/ALEX-FLEXR-2025"
}
```

#### Use Invite Code

```http
POST /api/v1/friends/invite-code/use
Content-Type: application/json

{
  "code": "ALEX-FLEXR-2025"
}
```

**Response (200)**:
```json
{
  "request_id": "request-uuid",
  "code_owner": {
    "user_id": "owner-user-id",
    "name": "Alex Smith",
    "avatar_url": "https://..."
  },
  "relationship_type": "friend",
  "status": "pending",
  "message": "Friend request sent via invite code"
}
```

### Activity Feed Endpoints

#### Get My Activity Feed (Friends + Gym)

```http
GET /api/v1/feed?filter=all&limit=20&offset=0
```

**Query Parameters**:
- `filter`: `all`, `friends`, `gym`, `partners`
- `limit`, `offset`: Pagination

**Response (200)**:
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
      "visibility": "friends",
      "relationship_type": "friend",  // or "gym_member", "race_partner"
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
      "visibility": "both",
      "relationship_type": "gym_member",
      "gym": {
        "gym_id": "gym-uuid",
        "name": "CrossFit Downtown"
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
POST /api/v1/feed/{activity_id}/kudos
Content-Type: application/json

{
  "kudos_type": "fire"  // or "default", "strong", "fast", etc.
}
```

**Response (201)**:
```json
{
  "kudos_count": 9,
  "kudos_type": "fire"
}
```

---

## Activity Feed Architecture

### Feed Generation Strategy

The hybrid social model requires a smart feed that combines:
1. **Friend activities** (across all gyms)
2. **Gym member activities** (at my gym(s))
3. **Race partner activities** (highest priority)

### Feed Query Logic

```sql
-- Get unified activity feed for a user
CREATE OR REPLACE FUNCTION get_user_activity_feed(
  p_user_id UUID,
  p_filter TEXT DEFAULT 'all',  -- 'all', 'friends', 'gym', 'partners'
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  activity_id UUID,
  user_id UUID,
  activity_type TEXT,
  activity_data JSONB,
  visibility TEXT,
  relationship_type TEXT,
  gym_id UUID,
  kudos_count INTEGER,
  has_kudoed BOOLEAN,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    af.id,
    af.user_id,
    af.activity_type,
    af.activity_data,
    af.visibility,
    ur.relationship_type,
    af.gym_id,
    af.kudos_count,
    EXISTS(
      SELECT 1 FROM activity_kudos ak
      WHERE ak.activity_id = af.id AND ak.user_id = p_user_id
    ) as has_kudoed,
    af.created_at
  FROM activity_feed af
  INNER JOIN user_relationships ur ON (
    (ur.user_a_id = p_user_id AND ur.user_b_id = af.user_id) OR
    (ur.user_b_id = p_user_id AND ur.user_a_id = af.user_id)
  )
  WHERE
    ur.status = 'active'
    AND af.expires_at > NOW()
    AND (
      -- Friend activities
      (ur.relationship_type IN ('friend', 'race_partner') AND af.visibility IN ('friends', 'both'))
      OR
      -- Gym activities
      (ur.relationship_type = 'gym_member' AND af.gym_id = ur.gym_id AND af.visibility IN ('gym_members', 'both'))
    )
    AND (
      p_filter = 'all'
      OR (p_filter = 'friends' AND ur.relationship_type = 'friend')
      OR (p_filter = 'gym' AND ur.relationship_type = 'gym_member')
      OR (p_filter = 'partners' AND ur.relationship_type = 'race_partner')
    )
  ORDER BY
    -- Race partners first, then friends, then gym members
    CASE ur.relationship_type
      WHEN 'race_partner' THEN 1
      WHEN 'friend' THEN 2
      WHEN 'gym_member' THEN 3
    END,
    af.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;
```

### Activity Publishing Rules

```typescript
// When a user completes a workout, determine visibility
async function publishWorkoutActivity(
  userId: string,
  workout: Workout
): Promise<void> {
  // Determine visibility based on user's privacy settings
  const user = await getUser(userId);
  const gymMemberships = await getUserGymMemberships(userId);

  let visibility: ActivityVisibility;

  if (user.privacy.shareWithFriends && user.privacy.shareWithGym) {
    visibility = 'both';
  } else if (user.privacy.shareWithFriends) {
    visibility = 'friends';
  } else if (user.privacy.shareWithGym) {
    visibility = 'gym_members';
  } else {
    visibility = 'private';
  }

  // Create activity
  await createActivity({
    user_id: userId,
    activity_type: 'workout_completed',
    activity_data: {
      workout_id: workout.id,
      workout_name: workout.title,
      duration: workout.total_duration_minutes * 60,
      pr_broken: workout.broke_pr
    },
    visibility,
    gym_id: workout.gym_id || null
  });

  // Send notifications to friends/partners
  await notifyConnections(userId, 'workout_completed', workout);
}
```

### Feed Caching Strategy

```typescript
// Redis-based feed caching
class ActivityFeedCache {
  private redis: Redis;
  private TTL = 5 * 60; // 5 minutes

  async getUserFeed(userId: string, filter: string, offset: number = 0): Promise<Activity[]> {
    const cacheKey = `feed:${userId}:${filter}:${offset}`;

    // Try cache first
    const cached = await this.redis.get(cacheKey);
    if (cached) {
      return JSON.parse(cached);
    }

    // Fetch from database
    const feed = await db.query(
      'SELECT * FROM get_user_activity_feed($1, $2, 20, $3)',
      [userId, filter, offset]
    );

    // Cache for 5 minutes
    await this.redis.setex(cacheKey, this.TTL, JSON.stringify(feed));

    return feed;
  }

  async invalidateUserFeed(userId: string): Promise<void> {
    // Clear all feed caches for this user
    const keys = await this.redis.keys(`feed:${userId}:*`);
    if (keys.length > 0) {
      await this.redis.del(...keys);
    }
  }
}
```

---

## iOS UI/UX Flows

### Main Navigation Structure

```
Main TabView
├─ Home Tab
│  └─ Activity Feed (Friends + Gym)
│
├─ Training Tab
│  └─ Workouts & Plan
│
├─ Social Tab (NEW)
│  ├─ My Friends List
│  │  ├─ Filter: All / Friends / Gym Members / Race Partners
│  │  ├─ Search friends
│  │  └─ [+ Add Friend button]
│  │
│  ├─ Friend Profile Sheet
│  │  ├─ User info & stats
│  │  ├─ Recent workouts
│  │  ├─ Compare workouts button
│  │  └─ Manage relationship menu
│  │
│  ├─ Find Friends
│  │  ├─ Search by name
│  │  ├─ Scan QR code
│  │  ├─ Enter invite code
│  │  └─ Gym members suggestions
│  │
│  └─ Pending Requests (badge count)
│
├─ Gyms Tab
│  └─ (Existing gym social features)
│
└─ Profile Tab
   └─ Settings
      └─ Privacy & Sharing
         ├─ Default Friend Privacy
         └─ Per-Relationship Settings
```

### Key UI Screens

#### 1. Social Tab - Friends List

```swift
struct SocialView: View {
    @StateObject private var viewModel: SocialViewModel
    @State private var selectedFilter: RelationshipFilter = .all

    enum RelationshipFilter: String, CaseIterable {
        case all = "All"
        case friends = "Friends"
        case gym = "Gym Members"
        case partners = "Race Partners"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(RelationshipFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Friends List
                if viewModel.filteredRelationships.isEmpty {
                    EmptyStateView(filter: selectedFilter)
                } else {
                    List {
                        // Race Partners Section (if any)
                        if selectedFilter == .all && !viewModel.racePartners.isEmpty {
                            Section(header: Text("Race Partners")) {
                                ForEach(viewModel.racePartners) { relationship in
                                    RelationshipRow(relationship: relationship)
                                }
                            }
                        }

                        // Friends Section
                        if !viewModel.friends.isEmpty {
                            Section(header: Text(selectedFilter == .all ? "Friends" : "")) {
                                ForEach(viewModel.friends) { relationship in
                                    RelationshipRow(relationship: relationship)
                                }
                            }
                        }

                        // Gym Members Section
                        if selectedFilter == .all || selectedFilter == .gym {
                            ForEach(viewModel.gymMemberships.keys.sorted(), id: \.self) { gymName in
                                Section(header: Text(gymName)) {
                                    ForEach(viewModel.gymMemberships[gymName] ?? []) { relationship in
                                        RelationshipRow(relationship: relationship)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Social")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Search Friends") {
                            viewModel.showFriendSearch = true
                        }
                        Button("Scan QR Code") {
                            viewModel.showQRScanner = true
                        }
                        Button("Enter Invite Code") {
                            viewModel.showInviteCodeEntry = true
                        }
                        Divider()
                        Button("My Invite Code") {
                            viewModel.showMyInviteCode = true
                        }
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .badge(viewModel.pendingRequestsCount)
        }
    }
}

struct RelationshipRow: View {
    let relationship: UserRelationship

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            AsyncImage(url: URL(string: relationship.connectedUser.avatarUrl)) { image in
                image.resizable()
            } placeholder: {
                Circle().fill(Color.gray.opacity(0.3))
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())

            // User Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(relationship.connectedUser.name)
                        .font(.headline)

                    // Relationship badge
                    RelationshipBadge(type: relationship.relationshipType)
                }

                HStack(spacing: 8) {
                    // Stats
                    Label("\(relationship.connectedUser.totalWorkouts)",
                          systemImage: "figure.run")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let streak = relationship.connectedUser.currentStreak, streak > 0 {
                        Label("\(streak) day streak", systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                // Gym info (if gym member)
                if relationship.relationshipType == .gymMember,
                   let gymName = relationship.gym?.name {
                    Text(gymName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // Race info (if race partner)
                if relationship.relationshipType == .racePartner,
                   let raceName = relationship.targetRaceName {
                    Text("🏁 \(raceName)")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }

            Spacer()

            // Last interaction
            if let lastInteraction = relationship.lastInteractionAt {
                Text(lastInteraction.timeAgo())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct RelationshipBadge: View {
    let type: RelationshipType

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
            Text(label)
        }
        .font(.caption2)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.2))
        .foregroundColor(color)
        .cornerRadius(4)
    }

    private var icon: String {
        switch type {
        case .gymMember: return "building.2.fill"
        case .friend: return "person.2.fill"
        case .racePartner: return "flag.checkered"
        }
    }

    private var label: String {
        switch type {
        case .gymMember: return "Gym"
        case .friend: return "Friend"
        case .racePartner: return "Partner"
        }
    }

    private var color: Color {
        switch type {
        case .gymMember: return .blue
        case .friend: return .green
        case .racePartner: return .orange
        }
    }
}
```

#### 2. Friend Profile Sheet

```swift
struct FriendProfileSheet: View {
    let relationship: UserRelationship
    @StateObject private var viewModel: FriendProfileViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        AsyncImage(url: URL(string: relationship.connectedUser.avatarUrl)) { image in
                            image.resizable()
                        } placeholder: {
                            Circle().fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())

                        Text(relationship.connectedUser.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        RelationshipBadge(type: relationship.relationshipType)

                        // Stats Row
                        HStack(spacing: 30) {
                            StatColumn(value: "\(relationship.connectedUser.totalWorkouts)",
                                     label: "Workouts")
                            StatColumn(value: "\(relationship.connectedUser.currentStreak)",
                                     label: "Day Streak")
                            StatColumn(value: "#\(viewModel.leaderboardRank ?? "-")",
                                     label: "Rank")
                        }
                    }
                    .padding()

                    // Quick Actions
                    HStack(spacing: 12) {
                        ActionButton(
                            icon: "chart.bar.xaxis",
                            label: "Compare",
                            action: { viewModel.showWorkoutComparison = true }
                        )

                        ActionButton(
                            icon: "hand.thumbsup.fill",
                            label: "Kudos",
                            action: { viewModel.sendKudos() }
                        )

                        if relationship.relationshipType == .friend {
                            ActionButton(
                                icon: "flag.checkered",
                                label: "Race Partner",
                                action: { viewModel.promoteToRacePartner() }
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Recent Workouts
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Workouts")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(viewModel.recentWorkouts) { workout in
                            WorkoutCard(workout: workout)
                                .padding(.horizontal)
                        }
                    }

                    // Privacy Settings (if applicable)
                    if relationship.canManagePermissions {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Privacy Settings")
                                .font(.headline)
                                .padding(.horizontal)

                            NavigationLink(destination: RelationshipPrivacyView(relationship: relationship)) {
                                HStack {
                                    Label("Manage what you share", systemImage: "lock.fill")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if relationship.relationshipType == .friend {
                            Button("Promote to Race Partner") {
                                viewModel.promoteToRacePartner()
                            }
                        }

                        Button("Manage Privacy") {
                            viewModel.showPrivacySettings = true
                        }

                        Divider()

                        Button("Remove \(relationship.relationshipType.displayName)", role: .destructive) {
                            viewModel.removeRelationship()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
}
```

#### 3. Add Friend Flow

```swift
struct AddFriendView: View {
    @StateObject private var viewModel: AddFriendViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMethod: AddFriendMethod = .search

    enum AddFriendMethod: String, CaseIterable {
        case search = "Search"
        case inviteCode = "Invite Code"
        case qrCode = "QR Code"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Method Picker
                Picker("Method", selection: $selectedMethod) {
                    ForEach(AddFriendMethod.allCases, id: \.self) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Content based on selected method
                switch selectedMethod {
                case .search:
                    SearchFriendView(viewModel: viewModel)
                case .inviteCode:
                    InviteCodeEntryView(viewModel: viewModel)
                case .qrCode:
                    QRCodeScannerView(viewModel: viewModel)
                }
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SearchFriendView: View {
    @ObservedObject var viewModel: AddFriendViewModel
    @State private var searchQuery = ""

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search by name or email", text: $searchQuery)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding()

            // Results
            if viewModel.isSearching {
                ProgressView()
                    .padding()
            } else if viewModel.searchResults.isEmpty && !searchQuery.isEmpty {
                EmptySearchResultsView()
            } else {
                List(viewModel.searchResults) { result in
                    SearchResultRow(result: result) {
                        viewModel.sendFriendRequest(to: result.userId)
                    }
                }
                .listStyle(.plain)
            }
        }
        .onChange(of: searchQuery) { newValue in
            if newValue.count >= 3 {
                viewModel.search(query: newValue)
            }
        }
    }
}

struct SearchResultRow: View {
    let result: UserSearchResult
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: result.avatarUrl)) { image in
                image.resizable()
            } placeholder: {
                Circle().fill(Color.gray.opacity(0.3))
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(result.name)
                    .font(.headline)

                if !result.sharedGyms.isEmpty {
                    Text("🏋️ \(result.sharedGyms.first!.name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if result.mutualFriendsCount > 0 {
                    Text("\(result.mutualFriendsCount) mutual friends")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }

            Spacer()

            // Add button or status
            switch result.relationshipStatus {
            case .none:
                Button(action: onAdd) {
                    Text("Add")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            case .pending:
                Text("Pending")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(6)
            case .active:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}
```

#### 4. Unified Activity Feed

```swift
struct ActivityFeedView: View {
    @StateObject private var viewModel: ActivityFeedViewModel
    @State private var selectedFilter: FeedFilter = .all

    enum FeedFilter: String, CaseIterable {
        case all = "All"
        case friends = "Friends"
        case gym = "Gym"
        case partners = "Partners"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(FeedFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Activity Feed
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
            .navigationTitle("Activity")
        }
        .onChange(of: selectedFilter) { newFilter in
            viewModel.filterFeed(by: newFilter)
        }
    }
}

struct ActivityCard: View {
    let activity: Activity
    let onKudos: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: activity.user.avatarUrl)) { image in
                    image.resizable()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(activity.user.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        RelationshipBadge(type: activity.relationshipType)
                    }

                    Text(activity.createdAt.timeAgo())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Gym badge (if applicable)
                if let gym = activity.gym {
                    Text(gym.name)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
            }

            // Activity Content
            ActivityContentView(activity: activity)

            // Actions
            HStack(spacing: 20) {
                Button(action: onKudos) {
                    HStack(spacing: 4) {
                        Image(systemName: activity.hasKudoed ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .foregroundColor(activity.hasKudoed ? .green : .secondary)
                        Text("\(activity.kudosCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if activity.canCompare {
                    NavigationLink(destination: WorkoutComparisonView(
                        workoutId: activity.workoutId
                    )) {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.bar.xaxis")
                            Text("Compare")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
```

---

## Edge Cases & Solutions

### 1. User Changes Gyms

**Scenario**: Alice is a member of CrossFit Downtown. She has gym connections with Bob and Charlie. Alice moves and joins CrossFit Uptown.

**Solution**:
```typescript
// When user leaves a gym
async function handleGymLeave(userId: string, gymId: string) {
  // 1. Deactivate gym_member relationships for this gym
  await db.query(`
    UPDATE user_relationships
    SET status = 'ended'
    WHERE gym_id = $1
      AND (user_a_id = $2 OR user_b_id = $2)
      AND relationship_type = 'gym_member'
  `, [gymId, userId]);

  // 2. Check if any gym connections are ALSO friends
  const dualRelationships = await db.query(`
    SELECT * FROM user_relationships
    WHERE gym_id = $1
      AND (user_a_id = $2 OR user_b_id = $2)
      AND relationship_type = 'gym_member'
      AND EXISTS (
        SELECT 1 FROM user_relationships ur2
        WHERE ur2.relationship_type = 'friend'
          AND ur2.status = 'active'
          AND (
            (ur2.user_a_id = user_relationships.user_a_id AND ur2.user_b_id = user_relationships.user_b_id)
            OR (ur2.user_b_id = user_relationships.user_a_id AND ur2.user_a_id = user_relationships.user_b_id)
          )
      )
  `, [gymId, userId]);

  // 3. For dual relationships, friendship persists
  // User sees notification: "You left CrossFit Downtown but you're still friends with Bob and Charlie"

  return {
    ended_gym_connections: gymConnections.length,
    preserved_friendships: dualRelationships.length
  };
}
```

**UI Behavior**:
- Show notification: "You left CrossFit Downtown. You're no longer gym members with 3 people, but you're still friends with Bob and Charlie."
- Offer quick action: "Want to add John as a friend too?"

### 2. User Has No Gym But Has Friends

**Scenario**: Dave trains at home/park. He has no gym membership but wants to use FLEXR and have friends.

**Solution**:
- **Friend system works independently** - No gym required
- Dave can:
  - Search for friends by name
  - Use invite codes
  - Compare workouts with friends
  - See friends' activity feed
- Dave **cannot**:
  - See gym leaderboards
  - Join gym-specific activities
  - Be discovered by gym members (unless they're friends)

**Onboarding**:
```swift
// During onboarding
if user.hasNoGym {
    showScreen(.homeTraining) // Configure home/park training
    showPrompt("Want to add friends?") // Optional friend setup
}
```

### 3. Friend is at Same Gym (Duplicate Relationship)

**Scenario**: Alice and Bob are gym members at CrossFit Downtown. Bob sends Alice a friend request.

**Solution**:
```sql
-- When friend request is accepted, check for existing gym_member relationship
CREATE OR REPLACE FUNCTION handle_friend_request_acceptance(
  p_request_id UUID
)
RETURNS VOID AS $$
DECLARE
  v_sender_id UUID;
  v_recipient_id UUID;
  v_relationship_type TEXT;
  v_existing_gym_rel UUID;
BEGIN
  -- Get request details
  SELECT sender_id, recipient_id, relationship_type
  INTO v_sender_id, v_recipient_id, v_relationship_type
  FROM friend_requests
  WHERE id = p_request_id;

  -- Check if they're already gym members together
  SELECT id INTO v_existing_gym_rel
  FROM user_relationships
  WHERE (user_a_id = LEAST(v_sender_id, v_recipient_id)
         AND user_b_id = GREATEST(v_sender_id, v_recipient_id))
    AND relationship_type = 'gym_member'
    AND status = 'active';

  -- Create friend relationship
  INSERT INTO user_relationships (
    user_a_id, user_b_id, relationship_type, status,
    requested_by, accepted_at, promoted_from, promoted_at
  ) VALUES (
    LEAST(v_sender_id, v_recipient_id),
    GREATEST(v_sender_id, v_recipient_id),
    v_relationship_type,
    'active',
    v_sender_id,
    NOW(),
    CASE WHEN v_existing_gym_rel IS NOT NULL THEN 'gym_member' ELSE NULL END,
    CASE WHEN v_existing_gym_rel IS NOT NULL THEN NOW() ELSE NULL END
  );

  -- Update request status
  UPDATE friend_requests
  SET status = 'accepted', responded_at = NOW()
  WHERE id = p_request_id;
END;
$$ LANGUAGE plpgsql;
```

**UI Behavior**:
- Bob sees Alice in both "Friends" and "Gym Members" lists (deduplicated in UI)
- Alice's profile shows both badges: "Friend • Gym Member"
- In gym leaderboard, Alice shows as "Friend" (priority badge)

### 4. Multiple Gym Memberships

**Scenario**: Alice trains at 2 gyms: CrossFit Downtown and LA Fitness. Bob is at CrossFit Downtown, Charlie is at LA Fitness.

**Solution**:
```typescript
// User can have multiple gym memberships
interface User {
  id: string;
  gymMemberships: GymMembership[];
}

// Relationships track which gym they met at
interface GymMemberRelationship {
  gym_id: string;
  relationship_type: 'gym_member';
  // ... other fields
}

// Query for gym members across all user's gyms
async function getMyGymMembers(userId: string): Promise<GymMember[]> {
  return db.query(`
    SELECT DISTINCT
      ur.*,
      g.name as gym_name,
      CASE
        WHEN ur.user_a_id = $1 THEN ur.user_b_id
        ELSE ur.user_a_id
      END as connected_user_id
    FROM user_relationships ur
    JOIN gyms g ON ur.gym_id = g.id
    WHERE (ur.user_a_id = $1 OR ur.user_b_id = $1)
      AND ur.relationship_type = 'gym_member'
      AND ur.status = 'active'
      AND ur.gym_id IN (
        SELECT gym_id FROM gym_memberships
        WHERE user_id = $1 AND status = 'active'
      )
    ORDER BY ur.last_interaction_at DESC
  `, [userId]);
}
```

**UI Behavior**:
- Social tab groups gym members by gym
- "CrossFit Downtown (12 members)"
- "LA Fitness (8 members)"
- If Bob is at both gyms, show once with both gym badges

### 5. User Removes Friend (Data Retention)

**Scenario**: Alice removes Bob as a friend. What happens to shared data, comparisons, activity history?

**Solution**:
```typescript
async function removeRelationship(
  relationshipId: string,
  requestingUserId: string
) {
  // 1. Soft delete relationship
  await db.query(`
    UPDATE user_relationships
    SET status = 'ended', updated_at = NOW()
    WHERE id = $1
  `, [relationshipId]);

  // 2. Remove from activity feeds (hide, don't delete)
  await db.query(`
    UPDATE activity_feed
    SET visibility = 'private'
    WHERE user_id IN (
      SELECT user_a_id FROM user_relationships WHERE id = $1
      UNION
      SELECT user_b_id FROM user_relationships WHERE id = $1
    )
  `, [relationshipId]);

  // 3. Keep historical data for analytics
  // - Workout comparisons: Keep but mark as archived
  // - Kudos history: Keep (they gave kudos genuinely)
  // - Interaction history: Keep for analytics

  // 4. Remove permissions
  await db.query(`
    DELETE FROM relationship_permissions
    WHERE relationship_id = $1
  `, [relationshipId]);

  // 5. Can re-add later (relationship history preserved)
  return {
    success: true,
    message: "Friend removed. You can add them back anytime."
  };
}
```

**Data Retention Policy**:
- Workout comparisons: Archived, can be deleted after 90 days
- Activity feed posts: Hidden from feed, deleted after 30 days
- Kudos/interactions: Kept indefinitely for analytics
- Relationship record: Kept with status='ended' for re-add tracking

### 6. Friend at Different Gym Visits My Gym

**Scenario**: Alice (CrossFit Downtown) and Bob (CrossFit Uptown) are friends. Bob visits Alice's gym for a workout.

**Solution**:
```typescript
// Option 1: Temporary gym membership (guest pass)
async function createGuestGymSession(
  userId: string,
  gymId: string,
  invitedBy?: string
) {
  await db.query(`
    INSERT INTO gym_guest_sessions (
      user_id, gym_id, invited_by,
      session_date, expires_at
    )
    VALUES ($1, $2, $3, NOW(), NOW() + INTERVAL '1 day')
  `, [userId, gymId, invitedBy]);

  // Bob now appears in CrossFit Downtown leaderboard for today
  // Bob can compare workouts with Downtown members today
}

// Option 2: Workout location tagging
interface Workout {
  // ... other fields
  location_type: 'home_gym' | 'primary_gym' | 'guest_gym';
  location_gym_id?: string;
}

// In activity feed
"Bob completed a workout at CrossFit Downtown (visiting)"
```

**UI Flow**:
1. Bob logs workout
2. App detects location near CrossFit Downtown
3. Prompt: "Are you visiting CrossFit Downtown? Your friend Alice trains here!"
4. Bob accepts → Workout tagged as guest session
5. Alice gets notification: "Bob worked out at your gym today! 🎉"

---

## Migration Strategy

### Phase 1: Extend Existing Schema (Week 1)

**Goals**:
- Add friend relationships alongside existing gym system
- Don't break existing features
- Enable basic friend connections

**Database Changes**:
```sql
-- Migration 013_hybrid_social_model.sql

-- 1. Create new unified relationships table
-- (Full schema from section above)

-- 2. Migrate existing gym connections to new system
INSERT INTO user_relationships (
  user_a_id, user_b_id, relationship_type, gym_id, status,
  created_at, accepted_at, last_interaction_at
)
SELECT
  LEAST(user_id, connected_user_id),
  GREATEST(user_id, connected_user_id),
  'gym_member',
  gym_id,
  CASE status
    WHEN 'accepted' THEN 'active'
    WHEN 'pending' THEN 'pending'
    WHEN 'rejected' THEN 'ended'
    WHEN 'blocked' THEN 'blocked'
    ELSE 'ended'
  END,
  created_at,
  responded_at,
  created_at
FROM gym_connections
WHERE status = 'accepted';

-- 3. Keep gym_connections table temporarily for backward compatibility

-- 4. Create new friend-specific tables
-- (friend_requests, friend_invite_codes, etc. from schema above)
```

**Backend Changes**:
```typescript
// Phase 1: Dual-write pattern (write to both old and new tables)
class RelationshipService {
  async createGymConnection(userId: string, connectedUserId: string, gymId: string) {
    // Write to old table (for backward compatibility)
    await legacyGymConnectionService.create({
      user_id: userId,
      connected_user_id: connectedUserId,
      gym_id: gymId
    });

    // Write to new unified table
    await db.query(`
      INSERT INTO user_relationships (
        user_a_id, user_b_id, relationship_type, gym_id, status
      ) VALUES (
        LEAST($1, $2), GREATEST($1, $2), 'gym_member', $3, 'active'
      )
    `, [userId, connectedUserId, gymId]);
  }
}
```

**iOS Changes**:
- No breaking changes to existing UI
- Social tab added (new feature)
- Existing gym features work as before

### Phase 2: Enable Friend Features (Week 2-3)

**Goals**:
- Launch friend request system
- Enable cross-gym friendships
- Test with beta users

**Database**:
- All new tables live
- Dual-write still active

**Backend**:
```typescript
// New API endpoints for friends
router.post('/api/v1/relationships/request', createFriendRequest);
router.patch('/api/v1/relationships/request/:id', respondToRequest);
router.get('/api/v1/friends/search', searchFriends);
router.post('/api/v1/friends/invite-code', generateInviteCode);
```

**iOS**:
- Social tab goes live
- Friend search and invite codes
- Friend request notifications
- Activity feed shows friends + gym

**Rollout**:
1. Beta testers only (10% of users)
2. Monitor: friend adoption rate, cross-gym connections
3. Gather feedback on UI/UX

### Phase 3: Unified Feed & Permissions (Week 4)

**Goals**:
- Launch unified activity feed
- Granular privacy controls
- Full friend feature parity

**Backend**:
```typescript
// Migrate to single source of truth
class RelationshipService {
  async getRelationships(userId: string, filters: RelationshipFilter) {
    // Read from unified table only
    return db.query(`
      SELECT * FROM get_user_relationships($1, $2, $3)
    `, [userId, filters.type, filters.status]);
  }
}

// Deprecate old gym_connections table (read-only)
```

**iOS**:
- Unified activity feed (friends + gym)
- Filter tabs work correctly
- Privacy settings per relationship
- Promote gym member → friend flow

### Phase 4: Cleanup & Optimize (Week 5)

**Goals**:
- Remove dual-write
- Delete deprecated tables
- Performance optimization

**Database**:
```sql
-- Final migration: 014_remove_legacy_tables.sql

-- 1. Verify data migration complete
SELECT COUNT(*) FROM gym_connections gc
WHERE NOT EXISTS (
  SELECT 1 FROM user_relationships ur
  WHERE ur.gym_id = gc.gym_id
    AND ((ur.user_a_id = gc.user_id AND ur.user_b_id = gc.connected_user_id)
      OR (ur.user_b_id = gc.user_id AND ur.user_a_id = gc.connected_user_id))
);
-- Should return 0

-- 2. Drop legacy table
DROP TABLE gym_connections;

-- 3. Optimize indexes
ANALYZE user_relationships;
VACUUM user_relationships;
```

**Backend**:
```typescript
// Remove all legacy code
// Unified API only
```

**Monitoring**:
- API response times < 200ms
- Feed load time < 1s
- Zero migration data loss

### Rollback Plan

If critical issues arise:

```sql
-- Emergency rollback: Re-enable gym_connections table
-- 1. Restore from backup
-- 2. Re-sync from user_relationships

INSERT INTO gym_connections (
  user_id, connected_user_id, gym_id, status, created_at, responded_at
)
SELECT
  user_a_id, user_b_id, gym_id,
  CASE status
    WHEN 'active' THEN 'accepted'
    WHEN 'pending' THEN 'pending'
    WHEN 'blocked' THEN 'blocked'
    ELSE 'rejected'
  END,
  created_at, accepted_at
FROM user_relationships
WHERE relationship_type = 'gym_member'
  AND created_at > '2025-12-01'; -- Only new data
```

---

## Architecture Decision Records

### ADR-001: Unified Relationship Table

**Decision**: Use single `user_relationships` table for all 3 layers instead of separate tables.

**Context**:
- Need to support gym members, friends, and race partners
- Relationships can evolve (gym member → friend → partner)
- Want efficient queries for "all my connections"

**Alternatives Considered**:
1. **Separate tables** (`gym_members`, `friends`, `race_partners`)
   - ❌ Complex queries (3-way JOINs)
   - ❌ Duplication when user is both gym member AND friend
   - ❌ Hard to track relationship evolution

2. **Polymorphic relationships** (relationable_type + relationable_id)
   - ❌ Loss of referential integrity
   - ❌ Complex queries
   - ❌ Type-checking issues

3. **Unified table with relationship_type** ✅
   - ✅ Single source of truth
   - ✅ Simple queries
   - ✅ Easy to evolve relationships
   - ✅ Maintains referential integrity
   - ⚠️ Need to handle type-specific fields (race partner data)

**Decision Rationale**:
- Relationship evolution is core feature ("promote to friend")
- Most queries need "all relationships" regardless of type
- Type-specific data (race info) is optional and infrequent
- Performance: Single index lookup vs 3 table scans

**Consequences**:
- Simpler codebase (one set of CRUD operations)
- Easier to add new relationship types
- Some nullable fields for type-specific data
- Need clear documentation on field usage by type

### ADR-002: Separate Gym Members from Friends

**Decision**: Gym membership creates 'gym_member' relationships, distinct from 'friend' relationships.

**Context**:
- Gym members should see each other with low friction
- Not all gym members want to be "friends"
- Friends should work cross-gym

**Alternatives Considered**:
1. **Auto-friend all gym members**
   - ❌ Privacy concerns (forced connections)
   - ❌ Can't distinguish gym-only vs personal friends

2. **No gym member concept, only friends**
   - ❌ Loses gym-local discovery
   - ❌ Doesn't support gym leaderboards well

3. **Separate layers with promotion path** ✅
   - ✅ Privacy-preserved (gym member ≠ friend automatically)
   - ✅ Clear mental model (3 layers)
   - ✅ Can promote gym member → friend
   - ✅ Supports both local and global use cases

**Decision Rationale**:
- Real-world behavior: People at same gym aren't automatically friends
- Privacy: Users control friend status explicitly
- Flexibility: Supports gym-only users AND cross-gym friends

**Consequences**:
- Two-step flow for gym members to become friends
- UI must clearly distinguish gym members vs friends
- More complex permission system (gym vs friend permissions)

### ADR-003: Permissions Per Relationship, Not Global

**Decision**: Privacy permissions are per-relationship, not global user settings.

**Context**:
- Users may want to share more with race partners than gym members
- Cross-gym friends may have different trust levels
- Need granular control

**Alternatives Considered**:
1. **Global privacy settings**
   - ❌ Can't differentiate between relationship types
   - ❌ All-or-nothing approach
   - ❌ Doesn't support "share more with partner" use case

2. **Per-relationship permissions** ✅
   - ✅ Maximum flexibility
   - ✅ Different defaults by relationship type
   - ✅ Users can override per person
   - ⚠️ More complex UI

3. **Tiered system** (public/friends/partners)
   - ⚠️ Not flexible enough for real-world needs
   - ⚠️ Can't handle "share with this friend but not that one"

**Decision Rationale**:
- Real-world: Trust levels vary by person
- Race partners need more data than casual friends
- User feedback: Wants control over individual sharing

**Consequences**:
- More database rows (permissions per relationship)
- UI complexity: Need good defaults + override flow
- Performance: Join on permissions table for every query
- Benefit: Maximum user control and trust

### ADR-004: Activity Feed Combines Friends and Gym

**Decision**: Single unified activity feed showing both friend and gym activities, with filters.

**Context**:
- Users have connections across 3 layers
- Want cohesive social experience
- Need to reduce app complexity

**Alternatives Considered**:
1. **Separate feeds** (Friends tab, Gym tab)
   - ❌ Users have to check multiple places
   - ❌ Fragments social experience
   - ❌ More navigation complexity

2. **Unified feed with smart filters** ✅
   - ✅ One place to see all social activity
   - ✅ Can filter by relationship type
   - ✅ Prioritizes race partners automatically
   - ✅ Familiar pattern (Instagram, Facebook)

3. **Algorithmic feed** (no manual filtering)
   - ⚠️ Less user control
   - ⚠️ Complex ranking algorithm needed
   - ⚠️ May hide important activities

**Decision Rationale**:
- Reduces cognitive load (one feed to check)
- Filters give control when needed
- Prioritization ensures important activities surface
- Aligns with established social media patterns

**Consequences**:
- Complex feed query (JOINs across relationships)
- Need caching for performance
- Filter state management in UI
- Benefit: Cohesive social experience

### ADR-005: Friend Discovery via Multiple Methods

**Decision**: Support search, invite codes, QR codes, and gym member suggestions.

**Context**:
- No public profiles (privacy-first)
- Need multiple discovery methods for different scenarios
- Want frictionless friend connections

**Alternatives Considered**:
1. **Search only**
   - ❌ Requires knowing friend's exact name/email
   - ❌ Privacy leak (anyone can search anyone)

2. **Invite codes only**
   - ❌ Too much friction for casual connections
   - ❌ Requires coordination (send code out of band)

3. **Multiple methods** ✅
   - ✅ Search: Quick for known contacts
   - ✅ Invite codes: Privacy-preserved sharing
   - ✅ QR codes: In-person connections
   - ✅ Gym suggestions: Low-friction for existing members
   - ⚠️ More implementation work

**Decision Rationale**:
- Different use cases need different methods
- In-person: QR code (at gym, race event)
- Remote: Invite code (text message, social media)
- Known contact: Search by name
- Serendipity: Gym member suggestions

**Consequences**:
- 4 different UI flows to build
- Backend support for all methods
- Need good defaults (which method to show first)
- Benefit: Works for all real-world scenarios

---

## Conclusion

This Hybrid Social Model architecture provides:

1. **3-Layer System**: Gym Members → Friends → Race Partners
2. **Unified Backend**: Single relationships table, simple queries
3. **Granular Privacy**: Per-relationship permissions with smart defaults
4. **Cross-Gym Support**: Friends work anywhere, not tied to gym
5. **Evolution Path**: Gym members can become friends, friends can become partners
6. **Activity Feed**: Unified feed showing all social activity with filters
7. **Discovery Methods**: Search, invite codes, QR codes, gym suggestions
8. **Privacy-First**: No public profiles, explicit connections required
9. **Scalable**: Can expand to global features without refactoring

**Success Criteria**:
- 40%+ of users have at least 1 friend connection
- 20%+ of friendships are cross-gym
- 60%+ of gym members promote to friends
- Activity feed engagement: 5+ views per day
- Zero data privacy incidents

**Next Steps**:
1. Review and approve architecture
2. Create database migrations
3. Begin backend API implementation
4. Start iOS UI development
5. Beta test with 10% of users
6. Full rollout after validation

---

**Document Version**: 1.0
**Last Updated**: 2025-12-03
**Author**: System Architect (Claude)
**Status**: Ready for Review
