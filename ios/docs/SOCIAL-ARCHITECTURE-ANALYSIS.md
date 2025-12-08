# FLEXR Social Features - Deep Architecture Analysis

## Executive Summary

FLEXR is NOT a social app - it's a **data-driven performance tracking app with selective sharing**. The "social" features should be reframed as **"Gym Analytics & Performance Comparison"**.

---

## 1. GYM CREATION & MANAGEMENT FLOW

### Current Database Schema Analysis
```typescript
// From backend/src/migrations/supabase/012_social_gyms.sql
gyms {
  id: UUID
  name: STRING
  gym_type: ENUM (crossfit, hyrox_affiliate, commercial_gym, boutique, home_gym, other)
  is_verified: BOOLEAN
  created_by_user_id: UUID  // ← WHO CREATED THIS GYM
  is_public: BOOLEAN        // ← CAN ANYONE FIND IT?
  allow_auto_join: BOOLEAN  // ← AUTO-APPROVE OR MANUAL?
  member_count: INT
  active_member_count: INT
}

gym_memberships {
  id: UUID
  user_id: UUID
  gym_id: UUID
  status: ENUM (pending, active, inactive, left)
  role: ENUM (member, coach, admin, owner)
  privacy_settings: JSONB
  joined_at: TIMESTAMP
  approved_at: TIMESTAMP
}
```

### The 3 Gym Creation Scenarios

#### Scenario A: Gym Owner Creates Account (BEST FOR MARKETING)
**User Journey:**
1. Gym owner signs up for FLEXR
2. Creates gym profile with details (address, type, amenities)
3. Becomes `role: owner` automatically
4. Sets `allow_auto_join: false` (manual approval)
5. Gets unique gym invite code
6. Markets to their members: "Join our gym on FLEXR with code: HYROX-NYC-001"
7. Members search, find gym, request to join
8. Owner approves/rejects via admin panel

**Business Benefits:**
- Direct relationship with gym owners
- Gym becomes distribution channel
- Gyms can verify their athletes
- Potential for gym-level subscriptions
- Creates local community hubs

**Technical Requirements:**
- Gym creation flow in app
- Admin panel for gym owners
- Push notifications for join requests
- Invite code system
- Verification badge process

#### Scenario B: User Creates Gym (Grassroots Growth)
**User Journey:**
1. User can't find their gym
2. Clicks "Create Gym"
3. Fills in gym details (becomes `role: admin`)
4. Gym is `is_verified: false` initially
5. Other members can join if they find it
6. Actual gym owner can claim it later

**Business Benefits:**
- Faster network growth
- User-driven expansion
- Lower barrier to entry

**Risks:**
- Duplicate gyms
- Incorrect information
- Need moderation

#### Scenario C: FLEXR Team Creates Gym (Curated Approach)
**User Journey:**
1. FLEXR team partners with gyms
2. Creates verified gym profiles
3. Provides gym with code/QR
4. Gym promotes to members
5. Members auto-join or request

**Business Benefits:**
- Higher quality data
- Verified from start
- Direct partnerships
- Potential revenue share

**Current Recommendation:**
**Start with Scenario A + B hybrid:**
- Allow users to create gyms (quick growth)
- Allow gym owners to create AND claim existing gyms
- Verification process for gym owners
- FLEXR team can create featured gyms

### Gym Member Approval Flow

```typescript
// Decision Tree
if (gym.allow_auto_join === true) {
  // Instant join
  membership.status = 'active'
  membership.approved_at = NOW()
} else {
  // Manual approval
  membership.status = 'pending'
  // Notify gym admins/owner
  // Wait for approval
}

// Who can approve?
function canApproveMember(user_role) {
  return ['owner', 'admin', 'coach'].includes(user_role)
}
```

**Privacy Levels:**
- **Public Gym** (`is_public: true`): Appears in search, anyone can request
- **Private Gym** (`is_public: false`): Invite-only, hidden from search
- **Auto-Join** (`allow_auto_join: true`): No approval needed
- **Manual Join** (`allow_auto_join: false`): Owner/admin must approve

---

## 2. RACE PARTNER BUSINESS MODEL

### Current Issues with Data Model

```typescript
// Problem: Current model allows MULTIPLE race partners
user_relationships {
  relationship_type: ENUM ('gym_member', 'friend', 'race_partner')
  // ❌ No constraint on number of race partners
}
```

### Proposed Business Model

**Premium Feature: Race Partner Subscription**

**Tier Structure:**
```
Solo Plan ($9.99/mo)
└─ 1 user
└─ Individual analytics
└─ Can link with 1 race partner

Partner Plan ($14.99/mo for 2 users) ← 25% discount
├─ 2 users (both get full access)
├─ Shared training plan
├─ Individual analytics dashboards
├─ Partner comparison analytics
└─ Race day coordination features
```

**Technical Requirements:**

1. **Enforce 1 Race Partner Limit**
```typescript
// Add database constraint
ALTER TABLE user_relationships
ADD CONSTRAINT one_race_partner_per_user
CHECK (
  (SELECT COUNT(*)
   FROM user_relationships
   WHERE (user_a_id = NEW.user_a_id OR user_b_id = NEW.user_a_id)
   AND relationship_type = 'race_partner'
   AND status = 'accepted'
  ) <= 1
);
```

2. **Subscription Validation**
```typescript
async function linkRacePartner(userA: UUID, userB: UUID) {
  // Check if both users have Partner Plan or Premium
  const userASub = await getSubscription(userA)
  const userBSub = await getSubscription(userB)

  if (!userASub.allowsRacePartner || !userBSub.allowsRacePartner) {
    throw new Error('Both users need Partner Plan or higher')
  }

  // Check existing partner
  const existingPartner = await getRacePartner(userA)
  if (existingPartner) {
    throw new Error('Already have a race partner. Remove existing partner first.')
  }

  // Create bidirectional relationship
  await createRacePartnerRelationship(userA, userB)
}
```

3. **Shared Workout, Individual Experience**
```typescript
// Workout Plan is shared
shared_training_plan {
  partner_relationship_id: UUID  // Links to both users
  weekly_structure: JSONB
  race_date: DATE
  target_time: INT
}

// But analytics are individual
user_workout_sessions {
  user_id: UUID              // Individual
  shared_plan_id: UUID       // Shared reference
  performance_metrics: JSONB  // Individual data
}

// Partner comparison view
function getPartnerComparison(relationshipId: UUID) {
  return {
    userA: getMetrics(userA_id),
    userB: getMetrics(userB_id),
    comparison: {
      avgPace: { userA: 5.2, userB: 5.4 },
      totalVolume: { userA: 42km, userB: 38km },
      improvement: { userA: +8%, userB: +12% }
    }
  }
}
```

**Partner Features:**
- ✅ Shared weekly training plan
- ✅ Individual performance tracking
- ✅ Side-by-side analytics
- ✅ Coordinated race day prep
- ✅ Progress comparisons
- ✅ Motivation/accountability notifications

---

## 3. ANALYTICS-FIRST SOCIAL FEATURES

### Reframing: Not "Social Feed", but "Gym Performance Board"

**Current Problem:**
- Generic "Recent Activity" feed
- No data-driven insights
- Missing what HYROX athletes care about: **NUMBERS**

### What HYROX Athletes Actually Want to See

#### A. Running Analytics (Priority 1)

**Long Runs**
```typescript
interface LongRunStats {
  userId: UUID
  userName: string
  distance: number      // meters
  duration: number      // seconds
  avgPace: number       // min/km
  elevation: number     // meters
  heartRateAvg: number
  date: Date
  splits: {
    km: number
    pace: number
    heartRate: number
  }[]
}

// Gym Leaderboard View
function getGymLongRunLeaderboard(gymId: UUID, period: '7d' | '30d') {
  // Show top performers by:
  // - Total distance
  // - Fastest avg pace
  // - Most consistent (lowest pace variation)
  // - Longest single run
}
```

**Interval Training**
```typescript
interface IntervalSession {
  workIntervals: {
    distance: number
    pace: number        // Target pace
    actualPace: number  // What they ran
    heartRate: number
  }[]
  restIntervals: {
    duration: number
    heartRateRecovery: number  // How much HR dropped
  }[]

  // Key metrics
  avgWorkPace: number
  paceConsistency: number  // Std dev of paces
  recoveryQuality: number  // How well they recovered
}

// Gym Comparison
"Sarah averaged 3:45/km on 8x400m intervals (target 3:50)"
"Mike struggled on last 2 reps - pace dropped to 4:10"
```

**Threshold Runs**
```typescript
interface ThresholdRun {
  duration: number          // Usually 20-40 min
  targetPace: number        // Lactate threshold pace
  actualPace: number[]      // Every km
  heartRate: number[]
  lactatePace: number       // Calculated threshold

  // Quality metrics
  paceDeviation: number     // How consistent
  fadeFactor: number        // Did they slow down
}

// Insight
"Emma held 4:15/km for 30min @ 165 bpm - excellent threshold work"
"James started too fast (3:55) and faded to 4:25 - pacing issue"
```

**Time Trials (5K, 10K)**
```typescript
interface TimeTrial {
  distance: number          // 5000m or 10000m
  totalTime: number
  splits: {
    km: number
    pace: number
    heartRate: number
  }[]

  // Comparison
  previousPR: number
  improvement: number
  percentileInGym: number
}

// Social Display
"🎉 NEW PR! Sarah: 5K in 19:42 (-34 seconds)"
"Mike finished 10K in 42:15 - Top 10% at HYROX Gym Downtown"
```

#### B. HYROX-Specific Metrics

**Station Performance**
```typescript
interface StationPerformance {
  stationType: 'skierg' | 'sled_push' | 'sled_pull' | 'burpee_broad_jump' |
               'rowing' | 'farmer_carry' | 'sandbag_lunges' | 'wall_balls'
  time: number
  heartRateStart: number
  heartRateEnd: number
  powerOutput: number  // For erg stations
  reps: number         // For wall balls/burpees

  // Gym comparison
  gymAverage: number
  percentile: number
  improvement: number
}

// Feed Display
"💪 Sarah crushed SkiErg: 3:24 (gym avg: 4:12)"
"🔥 Mike's sled push: 2:18 - New gym record!"
```

**Workout Pace Degradation**
```typescript
interface PaceDegradation {
  runSegments: {
    segment: 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8
    distance: 1000  // meters
    pace: number
    heartRate: number
  }[]

  // Analysis
  startPace: number
  endPace: number
  avgPace: number
  degradation: number  // % slower by end
  consistency: number  // Std dev of paces
}

// Insight
"Sarah maintained 4:05/km avg with only 6% degradation - excellent pacing!"
"Mike started 3:50 but finished 4:45 (25% degradation) - went out too hot"
```

### Proposed Analytics Tab Structure

```
Tab: "Gym" (not "Social")
├─ My Stats Summary
│  ├─ This Week's Volume
│  ├─ PRs This Month
│  └─ Current Training Phase
│
├─ Gym Leaderboards
│  ├─ Long Runs (Distance)
│  ├─ Interval Quality
│  ├─ Station Times
│  └─ Full Sim Times
│
├─ Live Gym Activity
│  ├─ "Sarah just finished Sled Push in 2:18"
│  ├─ "Mike set new 5K PR: 19:42"
│  └─ "Emma completed 8x400m @ 3:45 avg"
│
└─ Friends & Partners
   ├─ Race Partner Analytics (if premium)
   └─ Friend Comparisons
```

---

## 4. DATA PRIVACY & SHARING CONTROLS

### Current Privacy Model
```typescript
// From gym_privacy_settings
privacy_settings {
  show_on_leaderboard: boolean
  show_in_member_list: boolean
  show_workout_activity: boolean
  allow_workout_comparisons: boolean
  show_profile_to_members: boolean
}
```

### Enhanced Privacy Model Needed

```typescript
interface EnhancedPrivacySettings {
  // Gym visibility
  showOnLeaderboards: boolean
  showInMemberList: boolean
  showLiveActivity: boolean

  // What data to share
  shareableMetrics: {
    runningPace: boolean
    heartRate: boolean
    stationTimes: boolean
    workoutVolume: boolean
    personalRecords: boolean
  }

  // Who can see
  visibilityLevel: 'gym' | 'friends_only' | 'race_partner_only' | 'private'

  // Comparison permissions
  allowDirectComparisons: boolean
  allowAnonymousComparisons: boolean  // "You vs gym average"
}
```

### Privacy-First Design Principles

1. **Default to Private**: User must opt-in to sharing
2. **Granular Control**: Choose exactly what metrics to share
3. **Anonymous Options**: "Top 10% at your gym" without revealing exact numbers
4. **Easy Toggle**: One-tap to go private before/after workouts
5. **Partner Exception**: Race partner gets more access (with consent)

---

## 5. IMMEDIATE IMPLEMENTATION PRIORITIES

### Phase 1: Foundation (Current Sprint)
- [x] Basic gym search and join
- [x] Friend/partner relationships
- [x] Activity feed framework
- [ ] Fix: Enforce 1 race partner limit
- [ ] Fix: Proper privacy controls
- [ ] Fix: Gym creation flow

### Phase 2: Analytics Integration (Next Sprint)
- [ ] Running analytics data capture
- [ ] Station performance tracking
- [ ] Pace degradation analysis
- [ ] Gym leaderboards (real data, not mock)
- [ ] Partner comparison dashboard

### Phase 3: Premium Features (Future)
- [ ] Race partner subscription tier
- [ ] Shared training plans
- [ ] Advanced analytics
- [ ] Workout recommendations based on gym data

### Phase 4: Gym Ecosystem (Long-term)
- [ ] Gym admin panel
- [ ] Gym verification process
- [ ] Gym-level analytics
- [ ] Gym challenges/competitions
- [ ] Gym owner dashboard

---

## 6. TECHNICAL DEBT & REFACTORING NEEDED

### Database Schema Updates

```sql
-- 1. Enforce single race partner
ALTER TABLE user_relationships
ADD CONSTRAINT one_active_race_partner CHECK (
  (SELECT COUNT(*) FROM user_relationships r2
   WHERE (r2.user_a_id = user_relationships.user_a_id
          OR r2.user_b_id = user_relationships.user_a_id)
   AND r2.relationship_type = 'race_partner'
   AND r2.status = 'accepted') <= 1
);

-- 2. Add subscription tier to users
ALTER TABLE users
ADD COLUMN subscription_tier VARCHAR(50) DEFAULT 'free'
CHECK (subscription_tier IN ('free', 'solo', 'partner', 'premium'));

-- 3. Add running analytics table
CREATE TABLE running_sessions (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  session_type VARCHAR(50), -- 'long_run', 'intervals', 'threshold', 'time_trial'
  distance_meters INT,
  duration_seconds INT,
  avg_pace_per_km NUMERIC,
  elevation_gain_meters INT,
  heart_rate_avg INT,
  splits JSONB, -- Detailed km-by-km data
  created_at TIMESTAMP DEFAULT NOW()
);

-- 4. Add station performance table
CREATE TABLE station_performances (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  workout_id UUID,
  station_type VARCHAR(50),
  time_seconds INT,
  reps INT,
  power_output NUMERIC,
  heart_rate_start INT,
  heart_rate_end INT,
  gym_percentile NUMERIC,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### iOS Model Updates Needed

```swift
// 1. Running analytics models
struct RunningSession {
    let sessionType: RunningSessionType
    let distance: Double  // meters
    let duration: TimeInterval
    let avgPace: Double  // min/km
    let splits: [Split]
    let heartRateData: HeartRateData
}

enum RunningSessionType {
    case longRun
    case intervals(work: Int, rest: Int, reps: Int)
    case threshold(duration: TimeInterval)
    case timeTrial(distance: Double)  // 5K, 10K
}

// 2. Station performance
struct StationPerformance {
    let station: Station
    let time: TimeInterval
    let heartRate: HeartRateRange
    let powerOutput: Double?  // For erg stations
    let gymComparison: GymComparison
}

// 3. Enhanced privacy
struct UserPrivacySettings {
    var shareableMetrics: ShareableMetrics
    var visibilityLevel: VisibilityLevel
    var allowComparisons: Bool
}
```

---

## CONCLUSION

**The Vision:**
FLEXR is a **performance analytics platform** where data-driven athletes can:
1. Track their training with precision
2. Compare metrics with gym peers (anonymously or directly)
3. Link with a race partner for shared planning
4. See real-time gym activity (PRs, completions, achievements)
5. Use data to get better, faster

**NOT:**
- ❌ Generic social network
- ❌ Posting photos/stories
- ❌ Endless scrolling feed
- ❌ Likes and comments (kudos only)

**The Moat:**
- HYROX-specific data tracking
- Gym-based community (real, local connections)
- Partner training features (unique)
- Deep analytics that coaches would pay for

**Next Steps:**
1. Implement running analytics capture
2. Build gym leaderboards with real data
3. Add subscription tiers (free, solo, partner)
4. Create gym admin panel
5. Partner comparison dashboard
