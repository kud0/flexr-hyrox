# FLEXR BYOP (Bring Your Own Program) Architecture
## Feature Design Document v1.0

**Status**: Draft
**Last Updated**: 2025-12-01
**Owner**: System Architecture
**Priority**: HIGH - Key Market Differentiator

---

## Executive Summary

FLEXR's BYOP feature addresses a critical market gap: athletes who already have training programs but need superior tracking technology. This feature transforms FLEXR from an AI-only platform into a comprehensive HYROX training ecosystem, capturing users from gyms, personal trainers, and existing programs who want world-class Apple Watch tracking without abandoning their current programming.

**Market Opportunity**: No dedicated watchOS HYROX tracking app exists. Athletes are using generic workout trackers that can't properly segment HYROX-specific activities (run → station transitions, compromised running analysis, etc.).

**Strategic Value**:
- Expands addressable market by 3-5x
- Lower barrier to entry (cheaper tier)
- Natural upsell path to AI features
- Network effects (program sharing)
- Data goldmine (real-world HYROX programs)

---

## 1. User Tier Architecture

### 1.1 Pricing Structure

```
┌─────────────────────────────────────────────────────────────┐
│                      FLEXR TIER SYSTEM                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  FREE TIER                                                  │
│  $0/month                                                   │
│  ├─ 3 tracked workouts per month                           │
│  ├─ Basic run/station segmentation                         │
│  ├─ Limited analytics (last 7 days)                        │
│  ├─ No workout templates                                   │
│  └─ "Try before you buy" experience                        │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  TRACKER TIER                          $9.99/month          │
│  "Pro Tracking, Your Programming"      $89/year (25% off)  │
│  ├─ ✓ Unlimited workout tracking                           │
│  ├─ ✓ Custom workout builder                               │
│  ├─ ✓ Program calendar & scheduling                        │
│  ├─ ✓ Workout templates library                            │
│  ├─ ✓ Full Apple Watch integration                         │
│  ├─ ✓ Advanced analytics & insights                        │
│  ├─ ✓ Compromised running analysis                         │
│  ├─ ✓ Progress tracking & visualization                    │
│  ├─ ✓ Program sharing with friends                         │
│  ├─ ✓ Export workout data                                  │
│  ├─ ~ AI insights (read-only suggestions)                  │
│  └─ ✗ AI workout generation                                │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  AI-POWERED TIER                       $19.99/month         │
│  "Everything + AI Coach"               $179/year (25% off) │
│  ├─ ✓ Everything in Tracker Tier                           │
│  ├─ ✓ AI workout generation                                │
│  ├─ ✓ Personalized training plans                          │
│  ├─ ✓ Adaptive programming (auto-adjusts)                  │
│  ├─ ✓ AI recovery recommendations                          │
│  ├─ ✓ Periodization planning                               │
│  ├─ ✓ Race preparation protocols                           │
│  └─ ✓ Priority support                                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Competitive Pricing Analysis

| Feature | FLEXR Tracker | Generic Fitness Apps | Training Platforms |
|---------|---------------|---------------------|-------------------|
| HYROX-Specific Tracking | ✓ | ✗ | ✗ |
| watchOS Integration | ✓ | Partial | ✗ |
| Custom Program Input | ✓ | Limited | ✓ |
| Price | $9.99/mo | $5-15/mo | $20-50/mo |
| Run/Station Segmentation | ✓ | ✗ | ✗ |
| Compromised Running | ✓ | ✗ | ✗ |

**Positioning**: Premium tracking technology at mid-market price.

### 1.3 Feature Matrix

| Feature | Free | Tracker | AI-Powered |
|---------|------|---------|------------|
| **Tracking** |
| Workouts per month | 3 | Unlimited | Unlimited |
| Apple Watch integration | Basic | Full | Full |
| Run/station segmentation | ✓ | ✓ | ✓ |
| Transition tracking | ✓ | ✓ | ✓ |
| Heart rate zones | ✓ | ✓ | ✓ |
| **Programming** |
| Custom workout builder | ✗ | ✓ | ✓ |
| Workout templates | ✗ | ✓ | ✓ |
| Program calendar | ✗ | ✓ | ✓ |
| Recurring schedules | ✗ | ✓ | ✓ |
| Program sharing | ✗ | ✓ | ✓ |
| Import workouts | ✗ | ✓ | ✓ |
| **AI Features** |
| AI workout generation | ✗ | ✗ | ✓ |
| AI training plans | ✗ | ✗ | ✓ |
| AI insights (view only) | ✗ | ✓ | ✓ |
| Adaptive programming | ✗ | ✗ | ✓ |
| **Analytics** |
| Analytics history | 7 days | Unlimited | Unlimited |
| Compromised running | ✗ | ✓ | ✓ |
| Progress tracking | ✗ | ✓ | ✓ |
| Performance trends | ✗ | ✓ | ✓ |
| Data export | ✗ | ✓ | ✓ |

---

## 2. Custom Workout Input System

### 2.1 Manual Workout Builder

#### User Flow
```
Start Building Workout
    │
    ├─> Choose Workout Type
    │   ├─ Full HYROX Simulation
    │   ├─ Half HYROX Simulation
    │   ├─ Station Focus
    │   ├─ Running Focus
    │   └─ Custom (blank canvas)
    │
    ├─> Add Segments (drag & drop)
    │   │
    │   ├─ Run Segment
    │   │   ├─ Distance target
    │   │   ├─ Time target
    │   │   ├─ Pace target
    │   │   └─ Effort level
    │   │
    │   ├─ Station Segment
    │   │   ├─ Station type (dropdown)
    │   │   ├─ Reps/weight target
    │   │   ├─ Time cap
    │   │   └─ Notes
    │   │
    │   ├─ Transition
    │   │   └─ Expected duration
    │   │
    │   └─ Rest Period
    │       ├─ Duration
    │       └─ Active/passive
    │
    ├─> Set Overall Parameters
    │   ├─ Workout name
    │   ├─ Description
    │   ├─ Estimated duration
    │   ├─ Difficulty level
    │   ├─ Tags (strength, endurance, etc.)
    │   └─ Notes from coach
    │
    ├─> Preview & Validate
    │   ├─ Visual timeline
    │   ├─ Total distance/time
    │   ├─ Estimated effort
    │   └─ Segment breakdown
    │
    └─> Save Options
        ├─ Save as template
        ├─ Add to calendar
        ├─ Share with others
        └─ Start workout now
```

#### UI Components

**Segment Builder (iOS)**
```
┌──────────────────────────────────────────┐
│  Create Workout                     ✕    │
├──────────────────────────────────────────┤
│                                          │
│  Workout Name: [Morning HYROX Sim    ]  │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ SEGMENTS                        +  │ │
│  ├────────────────────────────────────┤ │
│  │                                    │ │
│  │  1. RUN  1000m  ≈5:00  ⚡⚡⚡⚡○    │ │
│  │     [Target: 5:00/km]         ⋮   │ │
│  │                                    │ │
│  │  2. STATION  SkiErg  ≈3:00  💪💪💪  │ │
│  │     [1000m target]            ⋮   │ │
│  │                                    │ │
│  │  3. TRANSITION  ≈0:30              │ │
│  │                                ⋮   │ │
│  │                                    │ │
│  │  4. RUN  1000m  ≈5:15  ⚡⚡⚡○○    │ │
│  │     [Compromised pace]        ⋮   │ │
│  │                                    │ │
│  │  [+ Add Segment]                   │ │
│  │                                    │ │
│  └────────────────────────────────────┘ │
│                                          │
│  Total: 45 min  |  8.0 km  |  Hard      │
│                                          │
│  [ Save as Template ]  [ Add to Cal ]   │
│                                          │
└──────────────────────────────────────────┘
```

**Segment Detail Editor**
```
┌──────────────────────────────────────────┐
│  ← Run Segment                           │
├──────────────────────────────────────────┤
│                                          │
│  DISTANCE                                │
│  [1000]  meters  [○○○○○○●○○○]          │
│   500m              1500m                │
│                                          │
│  TARGET                                  │
│  ○ Distance only                         │
│  ● Time target    [5:00]                 │
│  ○ Pace target                           │
│                                          │
│  EFFORT LEVEL                            │
│  [⚡⚡⚡⚡○]  Threshold                    │
│                                          │
│  TERRAIN                                 │
│  ○ Flat  ● Treadmill  ○ Hills  ○ Track  │
│                                          │
│  NOTES                                   │
│  ┌────────────────────────────────────┐ │
│  │Focus on steady breathing. This is │ │
│  │pre-station, save energy for SkiErg│ │
│  └────────────────────────────────────┘ │
│                                          │
│  [Delete Segment]        [Save]          │
│                                          │
└──────────────────────────────────────────┘
```

### 2.2 Quick Templates Library

Pre-built workout structures that users can customize:

#### Template Categories

**1. HYROX Simulations**
```yaml
Full_HYROX_Simulation:
  segments:
    - run: 1000m
    - station: SkiErg_1000m
    - run: 1000m
    - station: Sled_Push_50m
    - run: 1000m
    - station: Sled_Pull_50m
    - run: 1000m
    - station: Burpee_Broad_Jump_80m
    - run: 1000m
    - station: Row_1000m
    - run: 1000m
    - station: Farmers_Carry_200m
    - run: 1000m
    - station: Sandbag_Lunges_100m
    - run: 1000m
    - station: Wall_Balls_100_reps
    - run: 1000m
  total_distance: 8000m
  estimated_time: 60-90min
  difficulty: Advanced

Half_HYROX_Simulation:
  segments: [First 4 stations + runs]
  total_distance: 4000m
  estimated_time: 30-45min
  difficulty: Intermediate
```

**2. Station-Focused Workouts**
```yaml
Upper_Body_Station_Focus:
  - SkiErg: 3x500m (rest 2min)
  - Row: 3x500m (rest 2min)
  - Wall Balls: 3x30 reps (rest 2min)
  - Burpees: 3x20 reps (rest 2min)

Lower_Body_Station_Focus:
  - Sled Push: 4x50m (rest 3min)
  - Sled Pull: 4x50m (rest 3min)
  - Farmers Carry: 4x50m (rest 2min)
  - Sandbag Lunges: 4x50m (rest 3min)

Full_Body_Circuit:
  3 rounds:
    - SkiErg: 250m
    - Sled Push: 25m
    - Row: 250m
    - Farmers Carry: 50m
    - Rest: 2min
```

**3. Running-Focused Workouts**
```yaml
Interval_Training:
  warmup: 1000m easy
  main:
    - 8x400m @ threshold (rest 90sec)
    - 4x200m @ max (rest 60sec)
  cooldown: 1000m easy

Compromised_Running_Practice:
  - Run 1000m @ race pace
  - SkiErg 500m @ hard
  - Run 1000m @ race pace (feeling compromised)
  - Row 500m @ hard
  - Run 1000m @ race pace (heavily compromised)
  - Burpees 30 reps
  - Run 1000m @ race pace (survival mode)

Long_Run:
  - 10km steady @ conversational pace
  - Optional: 4x1min pickups in final 2km
```

**4. Recovery & Skill Work**
```yaml
Active_Recovery:
  - 2000m easy run
  - Station technique work (light weight):
    - SkiErg: 3x200m
    - Sled: 3x25m
    - Farmers: 3x50m
  - Mobility: 20min

Skill_Development:
  - Station specific:
    - Wall Ball technique: 10x10 reps (focus form)
    - Burpee efficiency drills
    - Sled push technique (empty sled)
  - Light run: 2000m between stations
```

### 2.3 Import Methods (Phase 2 - Future)

#### Priority Order

**Phase 2.1: Text Parser (Q2 2026)**
```python
# Example input parsing
input_text = """
Workout: Thursday HYROX Prep
1. Run 1km @ 5:00/km
2. SkiErg 1000m
3. Run 1km (compromised)
4. Sled Push 50m x 2
5. Run 1km
6. Cool down 10min easy
"""

# Parser extracts:
segments = [
  {type: "run", distance: 1000, target_pace: "5:00"},
  {type: "station", name: "SkiErg", distance: 1000},
  {type: "run", distance: 1000, notes: "compromised"},
  {type: "station", name: "Sled_Push", distance: 50, sets: 2},
  {type: "run", distance: 1000},
  {type: "run", distance: "10min", intensity: "easy"}
]
```

**Phase 2.2: Photo/PDF Scan (Q3 2026)**
- OCR integration (Apple Vision Framework)
- Smart workout plan detection
- Manual correction UI
- Save as template

**Phase 2.3: Platform Integrations (Q4 2026)**
```
Potential Integrations:
├─ TrainingPeaks API
├─ Final Surge
├─ Google Sheets (via URL)
├─ Coach emails (forward to FLEXR)
└─ Strava workout descriptions
```

---

## 3. Program Management System

### 3.1 Calendar Architecture

```
┌────────────────────────────────────────────────────────────┐
│  Training Calendar                              December    │
├────────────────────────────────────────────────────────────┤
│  Mon     Tue      Wed       Thu      Fri      Sat      Sun │
├────────────────────────────────────────────────────────────┤
│                                       1        2        3   │
│                                    [Race    [Recovery] [Long│
│                                     Sim]               Run] │
│                                                             │
│  4        5        6        7        8        9       10    │
│ [Inter- [Station [Rest]   [Tempo   [Station [Full   [Active│
│  vals]   Focus]            Run]     Circuit] HYROX]  Recov.]│
│                                                             │
│  11       12       13       14       15       16       17   │
│ [Easy   [Upper   [Rest]   [Fartlek [Lower   [Half   [Rest] │
│  Run]    Body]             Run]     Body]    HYROX]        │
│                                                             │
│  18       19       20       21       22       23       24   │
│ [○○○]   [○○○]   [○○○]   [○○○]   [○○○]   [○○○]   [RACE]  │
│                                                             │
│  Week Volume: 45km  |  4 Quality Sessions  |  2 Rest Days  │
└────────────────────────────────────────────────────────────┘

Drag & Drop:
- Move workouts between days
- Copy workout to multiple days
- Create recurring patterns
- Adjust rest days based on feel
```

### 3.2 Program Structure

```
Program (e.g., "12-Week Race Prep")
│
├─ Metadata
│  ├─ Name
│  ├─ Duration (12 weeks)
│  ├─ Goal (Race date: March 15)
│  ├─ Created by (Coach name / Self)
│  ├─ Difficulty level
│  └─ Tags
│
├─ Mesocycles (Training blocks)
│  │
│  ├─ Block 1: Base Building (Weeks 1-4)
│  │  ├─ Focus: Aerobic capacity
│  │  ├─ Volume: Progressive overload
│  │  └─ Intensity: 70-80% efforts
│  │
│  ├─ Block 2: Strength Phase (Weeks 5-8)
│  │  ├─ Focus: Station strength & power
│  │  ├─ Volume: Moderate
│  │  └─ Intensity: 80-90% efforts
│  │
│  ├─ Block 3: Race Specific (Weeks 9-11)
│  │  ├─ Focus: HYROX simulations
│  │  ├─ Volume: Decreasing
│  │  └─ Intensity: Race pace practice
│  │
│  └─ Block 4: Taper (Week 12)
│     ├─ Focus: Recovery & readiness
│     ├─ Volume: 40% reduction
│     └─ Intensity: Low, with short sharp efforts
│
├─ Weekly Templates
│  │
│  ├─ Week Structure
│  │  ├─ Monday: Intervals
│  │  ├─ Tuesday: Station Focus
│  │  ├─ Wednesday: Rest/Active Recovery
│  │  ├─ Thursday: Tempo Run
│  │  ├─ Friday: Station Circuit
│  │  ├─ Saturday: Long Session (simulation)
│  │  └─ Sunday: Recovery
│  │
│  └─ Progressive Variables
│     ├─ Distance increase (10% per week)
│     ├─ Intensity increase (RPE +0.5/week)
│     ├─ Recovery ratio adjustment
│     └─ Station complexity progression
│
└─ Workout Library (for this program)
   ├─ 45 unique workouts
   ├─ Linked to calendar dates
   ├─ Can be reused/modified
   └─ Notes from coach
```

### 3.3 Recurring Schedules

```python
# Pattern Examples

Weekly_Pattern:
  repeat: "weekly"
  days: ["Monday", "Wednesday", "Friday"]
  workout_template: "interval_training_v1"
  duration: "8 weeks"
  auto_progress: true
  progression_rules:
    - week_1_4: "80% intensity"
    - week_5_8: "90% intensity"

Alternating_Pattern:
  repeat: "every_2_days"
  workout_sequence: [
    "running_focused",
    "station_focused",
    "rest"
  ]
  duration: "indefinite"

Custom_Pattern:
  schedule:
    week_1: ["workout_a", "rest", "workout_b", "rest", "workout_c", "rest", "long"]
    week_2: ["workout_d", "rest", "workout_e", "rest", "workout_f", "rest", "recovery"]
  repeat_cycle: true
```

### 3.4 Drag & Drop Interface

**Interaction Behaviors:**

```
User Actions:
│
├─ Drag workout to new day
│  └─> Prompt: "Move or Copy?"
│
├─ Drag workout to multiple days
│  └─> Creates recurring pattern
│     └─> Options: Exact copy / Progressive overload
│
├─ Long-press workout
│  └─> Quick actions menu:
│     ├─ Edit
│     ├─ Duplicate
│     ├─ Delete
│     ├─ Mark complete
│     ├─ Swap with another day
│     └─ Add to templates
│
├─ Pinch gesture on calendar
│  └─> Zoom: Day → Week → Month → Program view
│
└─ Swipe workout card
   ├─> Swipe right: Complete
   ├─> Swipe left: Delete
   └─> Swipe up: Move to tomorrow
```

---

## 4. Data Architecture

### 4.1 Database Schema

```sql
-- ============================================
-- CUSTOM PROGRAMS & TEMPLATES
-- ============================================

-- Main program container (e.g., "12-Week Race Prep")
CREATE TABLE custom_programs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,

    -- Metadata
    name VARCHAR(255) NOT NULL,
    description TEXT,
    goal TEXT, -- e.g., "Sub 1:30 HYROX"
    difficulty_level VARCHAR(50), -- Beginner/Intermediate/Advanced/Elite

    -- Duration
    duration_weeks INTEGER,
    start_date DATE,
    end_date DATE,
    target_race_date DATE,

    -- Authorship
    created_by_type VARCHAR(50), -- 'self', 'coach', 'gym', 'imported'
    coach_name VARCHAR(255),
    source_organization VARCHAR(255), -- e.g., "HYROX Berlin"

    -- Structure
    mesocycles JSONB, -- Training block breakdown
    weekly_volume_target INTEGER, -- km per week
    quality_sessions_per_week INTEGER,

    -- Sharing
    is_public BOOLEAN DEFAULT false,
    is_template BOOLEAN DEFAULT false,
    shared_with UUID[], -- Array of user_ids
    times_cloned INTEGER DEFAULT 0,

    -- Metadata
    tags TEXT[],
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT valid_dates CHECK (end_date >= start_date)
);

CREATE INDEX idx_custom_programs_user ON custom_programs(user_id);
CREATE INDEX idx_custom_programs_public ON custom_programs(is_public) WHERE is_public = true;
CREATE INDEX idx_custom_programs_tags ON custom_programs USING GIN(tags);


-- Individual workout templates (reusable workouts)
CREATE TABLE custom_workout_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    program_id UUID REFERENCES custom_programs(id) ON DELETE CASCADE, -- NULL if standalone

    -- Metadata
    name VARCHAR(255) NOT NULL,
    description TEXT,
    workout_type VARCHAR(50), -- 'full_sim', 'half_sim', 'station_focus', 'running_focus', 'custom'
    difficulty_level VARCHAR(50),

    -- Segments (detailed structure)
    segments JSONB NOT NULL, -- Array of segment objects

    -- Estimated metrics
    estimated_duration_minutes INTEGER,
    estimated_distance_meters INTEGER,
    estimated_calories INTEGER,
    target_effort_level INTEGER, -- 1-10 scale

    -- Usage tracking
    times_used INTEGER DEFAULT 0,
    last_used_at TIMESTAMP,
    avg_completion_time_minutes INTEGER,

    -- Sharing
    is_public BOOLEAN DEFAULT false,
    is_system_template BOOLEAN DEFAULT false, -- FLEXR provided templates
    times_cloned INTEGER DEFAULT 0,

    -- Metadata
    tags TEXT[],
    notes TEXT, -- Coach notes
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_custom_workout_templates_user ON custom_workout_templates(user_id);
CREATE INDEX idx_custom_workout_templates_program ON custom_workout_templates(program_id);
CREATE INDEX idx_custom_workout_templates_type ON custom_workout_templates(workout_type);
CREATE INDEX idx_custom_workout_templates_public ON custom_workout_templates(is_public) WHERE is_public = true;


-- Segment structure example in JSONB
/*
segments: [
  {
    order: 1,
    type: "run",
    distance_meters: 1000,
    target_time_seconds: 300,
    target_pace_per_km: "5:00",
    effort_level: 4, // 1-5 scale
    terrain: "treadmill",
    notes: "Steady pace, pre-station"
  },
  {
    order: 2,
    type: "transition",
    expected_duration_seconds: 30
  },
  {
    order: 3,
    type: "station",
    station_name: "SkiErg",
    target_distance_meters: 1000,
    target_time_seconds: 210,
    target_reps: null,
    weight_kg: null,
    time_cap_seconds: 300,
    notes: "Focus on technique"
  },
  {
    order: 4,
    type: "rest",
    duration_seconds: 120,
    rest_type: "active" // or "passive"
  }
]
*/


-- Calendar scheduling (assigns workouts to specific dates)
CREATE TABLE program_schedule (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    program_id UUID REFERENCES custom_programs(id) ON DELETE CASCADE,
    workout_template_id UUID REFERENCES custom_workout_templates(id) ON DELETE CASCADE,

    -- Scheduling
    scheduled_date DATE NOT NULL,
    scheduled_time TIME, -- Optional specific time
    week_number INTEGER, -- Which week of the program
    day_of_week INTEGER, -- 1-7 (Monday-Sunday)

    -- Status
    status VARCHAR(50) DEFAULT 'scheduled', -- 'scheduled', 'completed', 'skipped', 'moved'
    completion_status VARCHAR(50), -- 'fully_completed', 'partially_completed', 'failed'
    actual_workout_id UUID REFERENCES workouts(id), -- Link to actual tracked workout

    -- Modifications
    is_modified BOOLEAN DEFAULT false,
    original_workout_template_id UUID REFERENCES custom_workout_templates(id),
    modifications JSONB, -- What changed from template

    -- Recurring pattern
    is_recurring BOOLEAN DEFAULT false,
    recurrence_rule JSONB, -- Frequency, end date, etc.
    parent_schedule_id UUID REFERENCES program_schedule(id), -- For recurring instances

    -- Notes
    pre_workout_notes TEXT, -- Instructions from coach
    post_workout_notes TEXT, -- Athlete's reflection

    -- Metadata
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP,

    CONSTRAINT unique_user_date_template UNIQUE(user_id, scheduled_date, workout_template_id)
);

CREATE INDEX idx_program_schedule_user_date ON program_schedule(user_id, scheduled_date);
CREATE INDEX idx_program_schedule_program ON program_schedule(program_id);
CREATE INDEX idx_program_schedule_status ON program_schedule(status);
CREATE INDEX idx_program_schedule_week ON program_schedule(program_id, week_number);


-- Recurrence rule example in JSONB
/*
recurrence_rule: {
  frequency: "weekly", // daily, weekly, biweekly, monthly
  interval: 1, // Every 1 week
  days_of_week: [1, 3, 5], // Monday, Wednesday, Friday
  end_type: "date", // "date", "count", "never"
  end_date: "2026-03-01",
  occurrences: null,
  progression: {
    type: "auto", // "none", "auto", "custom"
    increment_type: "percentage", // "percentage", "absolute"
    increment_value: 5, // 5% increase per week
    applies_to: ["distance", "reps"] // What to progress
  }
}
*/


-- Workout segment tracking (links schedule to actual tracked segments)
CREATE TABLE custom_workout_segments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workout_id UUID REFERENCES workouts(id) ON DELETE CASCADE,
    schedule_id UUID REFERENCES program_schedule(id),

    -- Segment definition (from template)
    segment_order INTEGER NOT NULL,
    segment_type VARCHAR(50) NOT NULL, -- 'run', 'station', 'transition', 'rest'

    -- Planned targets (from template)
    planned_distance_meters INTEGER,
    planned_duration_seconds INTEGER,
    planned_reps INTEGER,
    planned_weight_kg DECIMAL(5,2),

    -- Actual results (from tracking)
    actual_distance_meters INTEGER,
    actual_duration_seconds INTEGER,
    actual_reps INTEGER,
    actual_weight_kg DECIMAL(5,2),

    -- Performance metrics
    avg_heart_rate INTEGER,
    max_heart_rate INTEGER,
    avg_power_watts INTEGER,
    calories_burned INTEGER,
    avg_pace_per_km INTERVAL, -- For runs

    -- Status
    completed BOOLEAN DEFAULT false,
    notes TEXT,

    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_custom_workout_segments_workout ON custom_workout_segments(workout_id);
CREATE INDEX idx_custom_workout_segments_schedule ON custom_workout_segments(schedule_id);


-- Program analytics & progress tracking
CREATE TABLE program_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    program_id UUID REFERENCES custom_programs(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,

    -- Week-by-week rollup
    week_number INTEGER NOT NULL,
    week_start_date DATE NOT NULL,

    -- Volume metrics
    planned_workouts INTEGER,
    completed_workouts INTEGER,
    skipped_workouts INTEGER,
    completion_rate DECIMAL(5,2), -- Percentage

    total_distance_meters INTEGER,
    total_duration_minutes INTEGER,
    total_calories INTEGER,

    -- Quality metrics
    avg_heart_rate INTEGER,
    avg_effort_level DECIMAL(3,2),
    time_in_zones JSONB, -- Heart rate zone distribution

    -- Performance trends
    avg_run_pace_per_km INTERVAL,
    compromised_run_ratio DECIMAL(3,2), -- vs baseline
    station_times JSONB, -- Average time per station type

    -- Recovery indicators
    avg_resting_hr INTEGER,
    hrv_score INTEGER,
    subjective_fatigue INTEGER, -- 1-10 scale (if user logs)

    -- AI insights (if user has read-only AI)
    ai_insights JSONB,

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT unique_program_week UNIQUE(program_id, week_number)
);

CREATE INDEX idx_program_analytics_program ON program_analytics(program_id);
CREATE INDEX idx_program_analytics_user_date ON program_analytics(user_id, week_start_date);


-- Shared programs (for program sharing feature)
CREATE TABLE program_shares (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    program_id UUID REFERENCES custom_programs(id) ON DELETE CASCADE,
    shared_by_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    shared_with_user_id UUID REFERENCES users(id) ON DELETE CASCADE,

    -- Permissions
    can_view BOOLEAN DEFAULT true,
    can_edit BOOLEAN DEFAULT false,
    can_clone BOOLEAN DEFAULT true,

    -- Tracking
    viewed_at TIMESTAMP,
    cloned_at TIMESTAMP,

    created_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT unique_program_share UNIQUE(program_id, shared_by_user_id, shared_with_user_id)
);

CREATE INDEX idx_program_shares_program ON program_shares(program_id);
CREATE INDEX idx_program_shares_recipient ON program_shares(shared_with_user_id);


-- ============================================
-- INTEGRATION WITH EXISTING SCHEMA
-- ============================================

-- Add columns to existing workouts table
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS
    is_custom_workout BOOLEAN DEFAULT false,
    custom_workout_template_id UUID REFERENCES custom_workout_templates(id),
    program_schedule_id UUID REFERENCES program_schedule(id);

CREATE INDEX idx_workouts_custom_template ON workouts(custom_workout_template_id);
CREATE INDEX idx_workouts_program_schedule ON workouts(program_schedule_id);


-- Add subscription tier tracking to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS
    subscription_tier VARCHAR(50) DEFAULT 'free', -- 'free', 'tracker', 'ai_powered'
    subscription_start_date TIMESTAMP,
    subscription_end_date TIMESTAMP,
    subscription_status VARCHAR(50) DEFAULT 'active', -- 'active', 'cancelled', 'expired'
    stripe_customer_id VARCHAR(255),
    stripe_subscription_id VARCHAR(255);

CREATE INDEX idx_users_subscription_tier ON users(subscription_tier);
CREATE INDEX idx_users_subscription_status ON users(subscription_status);


-- Track feature usage for conversion optimization
CREATE TABLE feature_usage_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,

    subscription_tier VARCHAR(50),

    -- Usage metrics
    workouts_tracked_count INTEGER DEFAULT 0,
    custom_workouts_created_count INTEGER DEFAULT 0,
    templates_used_count INTEGER DEFAULT 0,
    programs_created_count INTEGER DEFAULT 0,

    -- Engagement signals
    ai_insights_viewed_count INTEGER DEFAULT 0, -- Tracker tier views AI suggestions
    upgrade_prompts_seen_count INTEGER DEFAULT 0,
    upgrade_prompts_clicked_count INTEGER DEFAULT 0,

    -- Time-based
    date DATE NOT NULL,

    created_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT unique_user_date UNIQUE(user_id, date)
);

CREATE INDEX idx_feature_usage_user_date ON feature_usage_analytics(user_id, date);
CREATE INDEX idx_feature_usage_tier ON feature_usage_analytics(subscription_tier);


-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Auto-update completion rate when workouts are completed
CREATE OR REPLACE FUNCTION update_program_completion_rate()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE program_analytics
    SET
        completion_rate = (
            completed_workouts::DECIMAL / NULLIF(planned_workouts, 0)
        ) * 100,
        updated_at = NOW()
    WHERE program_id = (
        SELECT program_id FROM program_schedule WHERE id = NEW.schedule_id
    )
    AND week_number = (
        SELECT week_number FROM program_schedule WHERE id = NEW.schedule_id
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_completion_rate
    AFTER UPDATE OF status ON program_schedule
    FOR EACH ROW
    WHEN (NEW.status = 'completed')
    EXECUTE FUNCTION update_program_completion_rate();


-- Auto-create analytics rows for new program weeks
CREATE OR REPLACE FUNCTION initialize_program_week_analytics()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO program_analytics (
        program_id,
        user_id,
        week_number,
        week_start_date,
        planned_workouts
    )
    SELECT
        NEW.program_id,
        NEW.user_id,
        NEW.week_number,
        DATE_TRUNC('week', NEW.scheduled_date),
        COUNT(*)
    FROM program_schedule
    WHERE program_id = NEW.program_id
        AND week_number = NEW.week_number
    GROUP BY program_id, week_number
    ON CONFLICT (program_id, week_number) DO UPDATE
        SET planned_workouts = program_analytics.planned_workouts + 1;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_init_week_analytics
    AFTER INSERT ON program_schedule
    FOR EACH ROW
    EXECUTE FUNCTION initialize_program_week_analytics();


-- Track template usage
CREATE OR REPLACE FUNCTION increment_template_usage()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE custom_workout_templates
    SET
        times_used = times_used + 1,
        last_used_at = NOW()
    WHERE id = NEW.workout_template_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_track_template_usage
    AFTER INSERT ON program_schedule
    FOR EACH ROW
    EXECUTE FUNCTION increment_template_usage();
```

### 4.2 Data Flow

```
User Creates Custom Workout
    │
    ├─> Save to custom_workout_templates
    │   ├─ segments stored as JSONB
    │   ├─ metadata captured
    │   └─ tagged for search
    │
    ├─> (Optional) Add to program
    │   └─> custom_programs record created/updated
    │
    └─> Schedule on calendar
        └─> program_schedule record created
            ├─ Links template to date
            ├─ Can be recurring
            └─> Triggers analytics initialization

User Starts Workout (watchOS)
    │
    ├─> Load from program_schedule
    │   └─> Fetch custom_workout_template
    │       └─> Parse segments JSONB
    │
    ├─> Begin tracking
    │   └─> Create workouts record
    │       ├─ is_custom_workout = true
    │       ├─ custom_workout_template_id = X
    │       └─ program_schedule_id = Y
    │
    ├─> Track each segment
    │   └─> Create custom_workout_segments records
    │       ├─ Planned metrics (from template)
    │       ├─ Actual metrics (from watch)
    │       └─ Performance data
    │
    └─> Complete workout
        └─> Update program_schedule status
            └─> Triggers completion rate update
                └─> Updates program_analytics

Analytics Engine Runs (Nightly)
    │
    ├─> Aggregate weekly metrics
    │   └─> Update program_analytics
    │       ├─ Volume totals
    │       ├─ Performance trends
    │       └─ Completion rates
    │
    ├─> Generate AI insights (if applicable)
    │   └─> Store in program_analytics.ai_insights
    │       ├─ Training balance analysis
    │       ├─ Recovery recommendations
    │       ├─ Progression suggestions
    │       └─> Conversion opportunities flagged
    │
    └─> Update feature_usage_analytics
        └─> Track engagement for tier optimization
```

---

## 5. Apple Watch Experience

### 5.1 Custom Workout Flow

```
Watch Face
    │
    ├─> Tap FLEXR Complication
    │
    ├─> Today's Workout Card
    │   ┌────────────────────────────────┐
    │   │ Morning HYROX Sim              │
    │   │ 8 segments · 45 min · Hard     │
    │   │                                │
    │   │ 1. Run 1000m @ 5:00/km        │
    │   │ 2. SkiErg 1000m                │
    │   │ 3. Run 1000m (compromised)     │
    │   │ ...                            │
    │   │                                │
    │   │ [Start Workout] [View Full]    │
    │   └────────────────────────────────┘
    │
    ├─> Tap [Start Workout]
    │
    ├─> Pre-Workout Screen
    │   ┌────────────────────────────────┐
    │   │ Ready to Start?                │
    │   │                                │
    │   │ Segment 1: Run 1000m           │
    │   │ Target: 5:00 pace              │
    │   │                                │
    │   │ ♥ HR Connected                 │
    │   │ 📍 GPS Ready                   │
    │   │                                │
    │   │ [Begin]                        │
    │   └────────────────────────────────┘
    │
    └─> Workout Active
        │
        ├─> Current Segment View (IDENTICAL to AI workouts)
        │   ┌────────────────────────────────┐
        │   │ RUN · Segment 1/8              │
        │   │                                │
        │   │ 485m  [━━━━━○○○]  1000m       │
        │   │                                │
        │   │ 4:52 /km    2:28 elapsed      │
        │   │                                │
        │   │ ♥ 165 bpm   Zone 4            │
        │   │                                │
        │   │ Next: SkiErg 1000m             │
        │   │                                │
        │   │ [Pause] [Digital Crown:Next]   │
        │   └────────────────────────────────┘
        │
        ├─> Auto-Advance to Next Segment
        │   (Digital Crown rotate or tap [Next])
        │
        ├─> Station Segment
        │   ┌────────────────────────────────┐
        │   │ SKI ERG · Segment 2/8          │
        │   │                                │
        │   │ 620m  [━━━━━━○○]  1000m       │
        │   │                                │
        │   │ 2:05 elapsed  ~0:55 remain    │
        │   │                                │
        │   │ ♥ 178 bpm   Zone 5            │
        │   │                                │
        │   │ Next: Run 1000m (compromised)  │
        │   │                                │
        │   │ [Complete] [Crown:Next]        │
        │   └────────────────────────────────┘
        │
        ├─> Compromised Run Tracking
        │   ┌────────────────────────────────┐
        │   │ RUN · Segment 3/8              │
        │   │ ⚠️ Post-Station Run            │
        │   │                                │
        │   │ 5:28 /km  ↓12% vs baseline    │
        │   │                                │
        │   │ ♥ 172 bpm   Elevated          │
        │   │                                │
        │   │ Compromised Running Active     │
        │   │                                │
        │   └────────────────────────────────┘
        │
        └─> Workout Complete
            ┌────────────────────────────────┐
            │ Workout Complete! 🎉            │
            │                                │
            │ 44:32 total time               │
            │ 8/8 segments completed         │
            │                                │
            │ vs Planned:                    │
            │ ⚡ 2:15 faster                 │
            │ ♥ Avg HR 168 (target: 165)    │
            │                                │
            │ [Save] [View Summary]          │
            └────────────────────────────────┘
```

### 5.2 Smart Features

**Segment Auto-Detection** (Optional, off by default)
- Detects when user switches activities
- "Looks like you started SkiErg, advance to next segment?"
- Machine learning improves over time

**Haptic Feedback**
- Gentle tap at segment targets (500m, 750m checkpoints)
- Strong tap at segment completion
- Triple tap for final segment

**Voice Coaching** (optional)
- "1000m run complete, moving to SkiErg"
- "Pace is 15 seconds slower than target"
- "Heart rate in Zone 5, consider backing off"

**Smart Metrics Display**
- Contextual: Shows distance for runs, time for stations
- Adaptive: Highlights what matters (pace lag, HR spike)
- Predictive: "On pace to finish 2 minutes fast"

---

## 6. AI Enhancement for Tracker Tier

### 6.1 Read-Only AI Insights

**Philosophy**: Tracker tier users see what AI *would* suggest, without AI controlling their program.

#### Insight Types

**1. Training Balance Analysis**
```
┌──────────────────────────────────────────┐
│  AI Insight · Training Balance            │
├──────────────────────────────────────────┤
│                                          │
│  Your last 4 weeks:                      │
│  🏃 Running: 68% of volume               │
│  💪 Stations: 32% of volume              │
│                                          │
│  ⚠️ Recommendation:                      │
│  Your station work is below optimal     │
│  ratio (target: 40-45%). Consider       │
│  adding 1-2 station-focused sessions    │
│  per week for balanced development.     │
│                                          │
│  [Tell Me More]  [Dismiss]              │
│                                          │
│  🔓 Upgrade to AI-Powered:               │
│  Auto-balance your program              │
│                                          │
└──────────────────────────────────────────┘
```

**2. Recovery Insights**
```
┌──────────────────────────────────────────┐
│  AI Insight · Recovery Status             │
├──────────────────────────────────────────┤
│                                          │
│  Based on your recent workouts:          │
│  • 4 high-intensity days in a row       │
│  • Avg HR up 6 bpm                      │
│  • Pace declining on easy runs          │
│                                          │
│  🟡 Fatigue Score: Moderate-High         │
│                                          │
│  Suggestion:                             │
│  Tomorrow's planned interval session    │
│  may be too aggressive. Consider:       │
│  • Swapping for easy run, OR            │
│  • Taking a rest day                    │
│                                          │
│  🔓 AI-Powered tier auto-adjusts        │
│     intensity based on recovery         │
│                                          │
└──────────────────────────────────────────┘
```

**3. Performance Trends**
```
┌──────────────────────────────────────────┐
│  AI Insight · Performance Pattern         │
├──────────────────────────────────────────┤
│                                          │
│  📊 Run Pace Trend (Last 6 Weeks)        │
│                                          │
│  5:10 ┤                            ╭─╮  │
│       │                        ╭───╯ │  │
│  5:20 │                    ╭───╯     │  │
│       │                ╭───╯         │  │
│  5:30 ├────────────────╯             │  │
│       └──────────────────────────────┘  │
│       Week 1                    Week 6  │
│                                          │
│  💪 Great progress! Avg pace improved   │
│  20 sec/km. Pattern suggests you're     │
│  ready for next progression:            │
│                                          │
│  • Increase interval intensity, OR      │
│  • Add volume to long runs              │
│                                          │
│  🔓 AI tier creates progressive plan    │
│                                          │
└──────────────────────────────────────────┘
```

**4. Compromised Running Analysis**
```
┌──────────────────────────────────────────┐
│  AI Insight · Compromised Running         │
├──────────────────────────────────────────┤
│                                          │
│  Your post-station pace drop pattern:    │
│                                          │
│  After SkiErg:    ↓8%                   │
│  After Sled Push: ↓15%  ⚠️              │
│  After Row:       ↓6%                   │
│  After Lunges:    ↓18%  ⚠️              │
│                                          │
│  Lower body stations impact you most.   │
│                                          │
│  Training focus:                         │
│  • More sled/lunge conditioning         │
│  • Practice runs after leg stations     │
│  • Strength endurance work              │
│                                          │
│  🔓 AI tier generates specific          │
│     compromised run workouts            │
│                                          │
└──────────────────────────────────────────┘
```

**5. Race Readiness**
```
┌──────────────────────────────────────────┐
│  AI Insight · Race Day Prediction         │
├──────────────────────────────────────────┤
│                                          │
│  Based on your training (12 weeks):     │
│                                          │
│  Predicted HYROX Time: 1:28:45          │
│  Confidence: 85%                         │
│                                          │
│  Breakdown:                              │
│  🏃 Running (8km):    42:30             │
│  💪 Stations:         38:15             │
│  ⏱️  Transitions:      8:00             │
│                                          │
│  Biggest opportunity:                    │
│  Sled Push (currently +2:30 vs target) │
│                                          │
│  🔓 AI tier creates race-specific       │
│     taper & strategy plan               │
│                                          │
└──────────────────────────────────────────┘
```

### 6.2 Insight Delivery Strategy

**Frequency**: Max 2-3 insights per week (not overwhelming)

**Timing**:
- Sunday evening (weekly review)
- After particularly hard/easy weeks
- When patterns emerge (e.g., consistent pace drop)
- Before planned rest weeks or races

**Opt-Out**: Users can disable AI insights completely

**Engagement Tracking**:
```python
# Track what leads to conversion
insight_engagement = {
    "insight_type": "recovery_status",
    "user_id": "uuid",
    "tier": "tracker",
    "action": "clicked_tell_me_more",
    "showed_upgrade_prompt": true,
    "upgraded_within_7_days": false  # Track conversion
}
```

---

## 7. Conversion Optimization

### 7.1 Upsell Opportunities

**Strategic Moments to Show Upgrade Prompts**:

#### A. During Planning
```
User creates 12-week program manually
    ↓
After saving:
┌──────────────────────────────────────────┐
│  Program Saved!                           │
│                                          │
│  🤖 Want AI to handle the details?      │
│                                          │
│  AI-Powered tier would:                  │
│  ✓ Generate 84 unique workouts           │
│  ✓ Auto-adjust based on progress        │
│  ✓ Balance volume & intensity            │
│  ✓ Optimize for your race date          │
│                                          │
│  Try free for 7 days                     │
│  [Upgrade to AI] [Stay with Tracker]    │
└──────────────────────────────────────────┘
```

#### B. During Insights
```
User views AI insight about training balance
    ↓
At bottom of insight:
┌──────────────────────────────────────────┐
│  Want AI to fix this automatically?      │
│                                          │
│  AI-Powered tier:                        │
│  • Rebalances your program               │
│  • Adjusts future workouts               │
│  • Maintains your race goal              │
│                                          │
│  [Upgrade Now] [Maybe Later]            │
└──────────────────────────────────────────┘
```

#### C. After Tough Workouts
```
User completes workout, marks as "very hard"
    ↓
Post-workout screen:
┌──────────────────────────────────────────┐
│  Workout Complete · That was tough! 💪   │
│                                          │
│  📊 Fatigue detected:                    │
│  Tomorrow's planned session is           │
│  high-intensity again.                   │
│                                          │
│  🤖 AI would adjust tomorrow to:         │
│  Easy recovery run (30min, easy pace)   │
│                                          │
│  Let AI manage your recovery?           │
│  [Try AI Free for 7 Days]               │
└──────────────────────────────────────────┘
```

#### D. When Skipping Workouts
```
User skips 2+ workouts in a week
    ↓
Weekly summary email:
┌──────────────────────────────────────────┐
│  Week 4 Summary                           │
│                                          │
│  You skipped 2 of 5 planned workouts.   │
│  Life gets busy - we get it!             │
│                                          │
│  🤖 AI-Powered tier adapts:              │
│  • Reschedules missed work               │
│  • Adjusts intensity to maintain gains  │
│  • Keeps you on track for race day      │
│                                          │
│  Never fall behind again.                │
│  [Upgrade to AI] [View Week 5]          │
└──────────────────────────────────────────┘
```

#### E. Feature Gates (Gentle)
```
User tries to create 4th program
    ↓
Soft gate:
┌──────────────────────────────────────────┐
│  You're a power user! 🔥                 │
│                                          │
│  Tracker tier: 3 active programs         │
│  AI-Powered tier: Unlimited programs     │
│                                          │
│  Plus AI handles the heavy lifting:      │
│  • Auto-generates workouts               │
│  • Manages multiple training blocks     │
│  • Periodization built-in                │
│                                          │
│  [Upgrade] [Delete Old Program]         │
└──────────────────────────────────────────┘
```

### 7.2 Conversion Funnel

```
Free Tier User Journey
    │
    ├─> Tries 3 workouts
    │   └─> Prompt: "Upgrade to track unlimited"
    │       ├─ Converts → Tracker Tier (60%)
    │       └─ Churns (40%)
    │
Tracker Tier User Journey
    │
    ├─> Uses for 2 weeks
    │   ├─ Engaged: Creates custom workouts (70%)
    │   └─ At-risk: Only uses templates (30%)
    │
    ├─> Sees first AI insight (Week 3)
    │   └─> Conversion rate: 8-12%
    │
    ├─> Experiences pain point (Week 4-6)
    │   ├─ Manual planning tedious
    │   ├─ Skips workouts, no adaptation
    │   ├─ Unsure about progression
    │   └─> Targeted upgrade prompt
    │       └─> Conversion rate: 15-20%
    │
    ├─> Race day approaching (6 weeks out)
    │   └─> "AI creates your taper plan"
    │       └─> Conversion rate: 25-30%
    │
    └─> Long-term (3+ months)
        └─> Habitual users who love tracking
            ├─ Retain as Tracker (50%)
            └─ Eventually upgrade (50% over 12mo)

Target Conversion Rates:
├─ Free → Tracker: 60% (within 30 days)
├─ Tracker → AI: 40% (within 90 days)
└─ Overall Free → AI: 24% (within 120 days)
```

### 7.3 A/B Testing Strategy

**Test Variables**:

1. **Insight Frequency**
   - A: 1/week
   - B: 2-3/week
   - C: 5/week
   - *Hypothesis*: Moderate frequency (B) maximizes engagement without annoyance

2. **Upgrade Prompt Timing**
   - A: Immediately after insight
   - B: 24 hours after insight
   - C: In weekly summary only
   - *Hypothesis*: B allows user to reflect on value

3. **Pricing Display**
   - A: Monthly price emphasized ($19.99/mo)
   - B: Annual savings emphasized ($179/yr - save $60!)
   - C: Daily cost frame ($0.66/day)
   - *Hypothesis*: C creates perception of affordability

4. **Free Trial Length**
   - A: 7 days
   - B: 14 days
   - C: 30 days
   - *Hypothesis*: 14 days (B) balances trial depth with conversion urgency

---

## 8. API Endpoints

### 8.1 Custom Workout Management

```typescript
// Create custom workout template
POST /api/v1/workouts/custom/templates
{
  name: string;
  description?: string;
  workout_type: 'full_sim' | 'half_sim' | 'station_focus' | 'running_focus' | 'custom';
  difficulty_level: 'beginner' | 'intermediate' | 'advanced' | 'elite';
  segments: Array<{
    order: number;
    type: 'run' | 'station' | 'transition' | 'rest';
    // Type-specific fields
    distance_meters?: number;
    target_time_seconds?: number;
    target_pace_per_km?: string;
    station_name?: string;
    target_reps?: number;
    weight_kg?: number;
    effort_level?: 1 | 2 | 3 | 4 | 5;
    notes?: string;
  }>;
  tags?: string[];
  is_public?: boolean;
}

Response: {
  template_id: uuid;
  estimated_duration_minutes: number;
  estimated_distance_meters: number;
}


// Get user's templates
GET /api/v1/workouts/custom/templates?
  user_id=uuid&
  workout_type=string&
  tags=csv&
  limit=20&
  offset=0

Response: {
  templates: Array<CustomWorkoutTemplate>;
  total_count: number;
  has_more: boolean;
}


// Get public/shared templates (discover)
GET /api/v1/workouts/custom/templates/discover?
  difficulty=string&
  workout_type=string&
  tags=csv&
  sort=popularity|recent|rating

Response: {
  templates: Array<CustomWorkoutTemplate & {
    author_name: string;
    times_used: number;
    avg_rating: number;
  }>;
}


// Clone template
POST /api/v1/workouts/custom/templates/:id/clone
{
  customize?: {
    name?: string;
    segments?: Partial<SegmentChanges>[];
  };
}

Response: {
  new_template_id: uuid;
}


// Update template
PATCH /api/v1/workouts/custom/templates/:id
{
  name?: string;
  segments?: Array<Segment>;
  tags?: string[];
  // ... other fields
}


// Delete template
DELETE /api/v1/workouts/custom/templates/:id
```

### 8.2 Program Management

```typescript
// Create program
POST /api/v1/programs/custom
{
  name: string;
  description?: string;
  goal?: string;
  duration_weeks: number;
  start_date: date;
  target_race_date?: date;
  difficulty_level: string;
  created_by_type: 'self' | 'coach' | 'gym' | 'imported';
  coach_name?: string;
  source_organization?: string;
  mesocycles?: Array<{
    block_number: number;
    name: string;
    weeks: number[];
    focus: string;
    volume_target: string;
    intensity_target: string;
  }>;
  tags?: string[];
  is_public?: boolean;
}

Response: {
  program_id: uuid;
}


// Get user's programs
GET /api/v1/programs/custom?
  user_id=uuid&
  status=active|completed|archived&
  sort=recent|start_date

Response: {
  programs: Array<CustomProgram & {
    completion_percentage: number;
    current_week: number;
    next_workout_date: date;
  }>;
}


// Get program details
GET /api/v1/programs/custom/:id

Response: {
  program: CustomProgram;
  scheduled_workouts: Array<ProgramSchedule>;
  analytics: {
    weeks_completed: number;
    total_workouts_completed: number;
    total_distance_meters: number;
    avg_completion_rate: number;
  };
}


// Update program
PATCH /api/v1/programs/custom/:id
{
  name?: string;
  mesocycles?: Array<Mesocycle>;
  end_date?: date;
  // ... other fields
}


// Delete program
DELETE /api/v1/programs/custom/:id
```

### 8.3 Schedule Management

```typescript
// Add workout to calendar
POST /api/v1/programs/schedule
{
  program_id: uuid;
  workout_template_id: uuid;
  scheduled_date: date;
  scheduled_time?: time;
  week_number: number;
  is_recurring?: boolean;
  recurrence_rule?: {
    frequency: 'daily' | 'weekly' | 'biweekly' | 'monthly';
    interval: number;
    days_of_week?: number[];
    end_date?: date;
    progression?: {
      type: 'none' | 'auto' | 'custom';
      increment_type?: 'percentage' | 'absolute';
      increment_value?: number;
      applies_to?: string[];
    };
  };
  pre_workout_notes?: string;
}

Response: {
  schedule_id: uuid;
  instances_created?: number; // If recurring
}


// Get calendar (week/month view)
GET /api/v1/programs/schedule/calendar?
  user_id=uuid&
  start_date=date&
  end_date=date&
  program_id=uuid

Response: {
  scheduled_workouts: Array<{
    schedule_id: uuid;
    workout_template: CustomWorkoutTemplate;
    scheduled_date: date;
    status: string;
    completion_status?: string;
    actual_workout_id?: uuid;
  }>;
}


// Update scheduled workout
PATCH /api/v1/programs/schedule/:id
{
  scheduled_date?: date;
  status?: 'scheduled' | 'completed' | 'skipped' | 'moved';
  post_workout_notes?: string;
  modifications?: {
    segments?: Partial<Segment>[];
  };
}


// Move workout (drag & drop)
POST /api/v1/programs/schedule/:id/move
{
  new_date: date;
  swap_with_schedule_id?: uuid; // If swapping
}


// Complete workout (link to tracking)
POST /api/v1/programs/schedule/:id/complete
{
  actual_workout_id: uuid; // From workouts table
}

Response: {
  schedule_id: uuid;
  completion_status: string;
  vs_planned: {
    time_difference_seconds: number;
    distance_difference_meters: number;
    effort_comparison: string;
  };
}


// Skip workout
POST /api/v1/programs/schedule/:id/skip
{
  reason?: string;
  reschedule_to?: date;
}


// Delete scheduled workout
DELETE /api/v1/programs/schedule/:id?delete_series=boolean
```

### 8.4 Analytics & Insights

```typescript
// Get program analytics
GET /api/v1/programs/:id/analytics?
  week_number=int&
  start_date=date&
  end_date=date

Response: {
  weekly_analytics: Array<{
    week_number: number;
    week_start_date: date;
    completed_workouts: number;
    completion_rate: number;
    total_distance_meters: number;
    total_duration_minutes: number;
    avg_heart_rate: number;
    avg_effort_level: number;
    performance_trends: {
      avg_run_pace_per_km: string;
      compromised_run_ratio: number;
      station_times: Record<string, number>;
    };
  }>;
  overall_summary: {
    total_weeks: number;
    total_workouts_completed: number;
    total_distance_meters: number;
    avg_weekly_volume: number;
    progression_trend: 'improving' | 'plateauing' | 'declining';
  };
}


// Get AI insights (Tracker tier)
GET /api/v1/programs/:id/ai-insights?
  user_id=uuid&
  insight_types=training_balance,recovery,performance,race_readiness

Response: {
  insights: Array<{
    insight_type: string;
    title: string;
    description: string;
    recommendations: string[];
    data: Record<string, any>;
    severity: 'info' | 'warning' | 'urgent';
    created_at: timestamp;
    expires_at: timestamp;
    upgrade_prompt?: {
      message: string;
      cta: string;
    };
  }>;
  has_more: boolean;
}


// Dismiss insight
POST /api/v1/programs/ai-insights/:id/dismiss


// Track insight engagement
POST /api/v1/programs/ai-insights/:id/engage
{
  action: 'viewed' | 'clicked_tell_me_more' | 'clicked_upgrade' | 'dismissed';
}
```

### 8.5 Sharing & Social

```typescript
// Share program
POST /api/v1/programs/:id/share
{
  share_with_user_ids: uuid[];
  can_view: boolean;
  can_edit: boolean;
  can_clone: boolean;
  message?: string;
}

Response: {
  shares_created: number;
}


// Get shared programs
GET /api/v1/programs/shared?user_id=uuid

Response: {
  shared_programs: Array<{
    program: CustomProgram;
    shared_by: {
      user_id: uuid;
      name: string;
    };
    permissions: {
      can_view: boolean;
      can_edit: boolean;
      can_clone: boolean;
    };
    shared_at: timestamp;
  }>;
}


// Clone shared program
POST /api/v1/programs/:id/clone
{
  start_date?: date;
  customize?: {
    name?: string;
    target_race_date?: date;
  };
}


// Make program public
PATCH /api/v1/programs/:id/visibility
{
  is_public: boolean;
}


// Rate/review program (for public templates)
POST /api/v1/programs/:id/review
{
  rating: 1 | 2 | 3 | 4 | 5;
  review?: string;
}
```

### 8.6 Subscription & Billing

```typescript
// Check subscription status
GET /api/v1/users/:id/subscription

Response: {
  tier: 'free' | 'tracker' | 'ai_powered';
  status: 'active' | 'cancelled' | 'expired' | 'trial';
  trial_ends_at?: timestamp;
  renews_at?: timestamp;
  features: {
    unlimited_tracking: boolean;
    custom_workouts: boolean;
    program_calendar: boolean;
    ai_insights_read_only: boolean;
    ai_workout_generation: boolean;
    // ... full feature list
  };
  usage: {
    workouts_tracked_this_month: number;
    limit: number | null;
  };
}


// Start subscription
POST /api/v1/subscriptions/start
{
  tier: 'tracker' | 'ai_powered';
  billing_period: 'monthly' | 'annual';
  payment_method_id: string; // Stripe token
  start_trial?: boolean;
}

Response: {
  subscription_id: uuid;
  stripe_subscription_id: string;
  trial_ends_at?: timestamp;
  next_billing_date: timestamp;
}


// Upgrade subscription
POST /api/v1/subscriptions/upgrade
{
  new_tier: 'ai_powered';
  immediate?: boolean; // Pro-rate or wait for cycle?
}


// Cancel subscription
POST /api/v1/subscriptions/cancel
{
  reason?: string;
  feedback?: string;
  cancel_immediately?: boolean; // Or end of billing period
}


// Reactivate subscription
POST /api/v1/subscriptions/reactivate
```

### 8.7 Import/Export (Phase 2)

```typescript
// Import workout from text
POST /api/v1/workouts/custom/import/text
{
  text: string;
  source?: string;
}

Response: {
  parsed_workout: CustomWorkoutTemplate;
  confidence_score: number; // 0-1
  needs_review: boolean;
  suggestions?: string[];
}


// Import from photo/PDF
POST /api/v1/workouts/custom/import/document
{
  document_url: string;
  document_type: 'image' | 'pdf';
}

Response: {
  parsed_workouts: Array<CustomWorkoutTemplate>;
  // ... same as text import
}


// Export program
GET /api/v1/programs/:id/export?
  format=json|pdf|csv|ics

Response: {
  export_url: string;
  expires_at: timestamp;
}
```

---

## 9. UI Wireframes

### 9.1 Custom Workout Builder (iOS)

```
┌──────────────────────────────────────────────────────────┐
│  ← Workout Builder                                   ✓   │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  Workout Name                                            │
│  ┌────────────────────────────────────────────────────┐ │
│  │  Morning HYROX Simulation                          │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  Type: [Full HYROX Sim ▼]  Difficulty: [Hard ▼]        │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │  WORKOUT TIMELINE                               +  │ │
│  ├────────────────────────────────────────────────────┤ │
│  │                                                    │ │
│  │  ┌──────────────────────────────────────┐  ⋮     │ │
│  │  │ 1. RUN · 1000m                       │        │ │
│  │  │    Target: 5:00/km · ⚡⚡⚡⚡○         │        │ │
│  │  │    ≈ 5:00                            │        │ │
│  │  └──────────────────────────────────────┘        │ │
│  │                                                    │ │
│  │  ┌──────────────────────────────────────┐  ⋮     │ │
│  │  │ 2. STATION · SkiErg                  │        │ │
│  │  │    1000m · 💪💪💪                      │        │ │
│  │  │    ≈ 3:30                            │        │ │
│  │  └──────────────────────────────────────┘        │ │
│  │                                                    │ │
│  │  ┌──────────────────────────────────────┐  ⋮     │ │
│  │  │ 3. TRANSITION                        │        │ │
│  │  │    ≈ 0:30                            │        │ │
│  │  └──────────────────────────────────────┘        │ │
│  │                                                    │ │
│  │  ┌──────────────────────────────────────┐  ⋮     │ │
│  │  │ 4. RUN · 1000m (Compromised)         │        │ │
│  │  │    Target: 5:15/km · ⚡⚡⚡○○         │        │ │
│  │  │    ≈ 5:15                            │        │ │
│  │  └──────────────────────────────────────┘        │ │
│  │                                                    │ │
│  │  ┌──────────────────────────────────────┐        │ │
│  │  │ [+ Add Segment]                      │        │ │
│  │  └──────────────────────────────────────┘        │ │
│  │                                                    │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │  TOTALS                                            │ │
│  │  ⏱️  45 min    🏃 8.0 km    🔥 620 cal            │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  Notes (optional)                                        │
│  ┌────────────────────────────────────────────────────┐ │
│  │  Focus on pacing. This is a test run for race     │ │
│  │  day strategy.                                     │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  Tags:  [full-sim] [race-pace] [+ Add Tag]             │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │  [ Save as Template ]    [ Add to Calendar ]      │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
└──────────────────────────────────────────────────────────┘

Tap segment → Edit details
Drag segment ⋮ icon → Reorder
Swipe left on segment → Delete
Tap [+] → Add new segment (modal)
```

### 9.2 Program Calendar (iOS)

```
┌──────────────────────────────────────────────────────────┐
│  ☰  Programs                              + ⚙️           │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  12-Week Race Prep                                       │
│  Week 4 of 12  ·  Race day: March 15                    │
│  ━━━━━━━━━━━━━━━━○○○○○○○○ 33%                         │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │  December 2025              < ━━━ >                │ │
│  ├────────────────────────────────────────────────────┤ │
│  │  S   M   T   W   T   F   S                         │ │
│  ├────────────────────────────────────────────────────┤ │
│  │ 30   1   2   3   4   5   6                         │ │
│  │          🏃  💪  🏃  💪 🏁                          │ │
│  │                                                    │ │
│  │  7   8   9  10  11  12  13                         │ │
│  │ 🏃  💪  ─  🏃  💪  ⭐  ─                           │ │
│  │                                                    │ │
│  │ 14  15  16  17  18  19  20  ← This week           │ │
│  │ 🏃  💪  ─  🏃  💪  ⭐  ─                           │ │
│  │                  ↑ TODAY                           │ │
│  │                                                    │ │
│  │ 21  22  23  24  25  26  27                         │ │
│  │ ○   ○   ─   ○   ○   ○   ─                         │ │
│  │                                                    │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  Legend:                                                 │
│  🏃 Run Focus  💪 Station Focus  ⭐ Simulation  ─ Rest  │
│  ✓ Completed   ○ Planned   ⚠️ Skipped                  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │  TODAY'S WORKOUT                                   │ │
│  ├────────────────────────────────────────────────────┤ │
│  │                                                    │ │
│  │  Interval Training                                 │ │
│  │  ⏱️  45 min  ·  🏃 8km  ·  🔥 Hard                 │ │
│  │                                                    │ │
│  │  8x400m @ threshold + 4x200m @ max                │ │
│  │                                                    │ │
│  │  Notes from coach:                                 │ │
│  │  "Focus on recovery between reps. These           │ │
│  │  should feel controlled, not all-out."            │ │
│  │                                                    │ │
│  │  [View Full Workout]      [Start on Watch]        │ │
│  │                                                    │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │  WEEK 4 SUMMARY                                    │ │
│  │  3/5 workouts complete  ·  60% completion rate    │ │
│  │  18.5 km total  ·  2h 15min training time         │ │
│  │  [View Week Details]                               │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │  💡 AI INSIGHT                                     │ │
│  │  Your completion rate dropped from 80% to 60%.    │ │
│  │  Life happens! Consider adjusting next week's     │ │
│  │  volume to stay on track.                         │ │
│  │  [Tell Me More]                                    │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
└──────────────────────────────────────────────────────────┘

Interactions:
- Tap date → View day details
- Long-press workout → Quick actions (edit, move, skip)
- Drag workout → Move to different day
- Pinch calendar → Zoom month view
- Swipe week → Previous/next week
```

### 9.3 Template Library (iOS)

```
┌──────────────────────────────────────────────────────────┐
│  ← Templates                                🔍  ⋮        │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  Search templates...                                     │
│  ┌────────────────────────────────────────────────────┐ │
│  │  🔎  "station focus"                               │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  Filter: [All ▼] [Any Difficulty ▼] [Popular ▼]        │
│                                                          │
│  ┌─ MY TEMPLATES ─────────────────────────────────────┐ │
│  │                                                    │ │
│  │  ┌──────────────────────────────────────┐         │ │
│  │  │  Morning HYROX Sim          ⭐ 4.5   │   →    │ │
│  │  │  8 segments · 45 min · Hard          │         │ │
│  │  │  Used 12 times · Last: Dec 10        │         │ │
│  │  └──────────────────────────────────────┘         │ │
│  │                                                    │ │
│  │  ┌──────────────────────────────────────┐         │ │
│  │  │  Station Circuit                     │   →    │ │
│  │  │  12 segments · 60 min · Hard         │         │ │
│  │  │  Used 8 times · Last: Dec 8          │         │ │
│  │  └──────────────────────────────────────┘         │ │
│  │                                                    │ │
│  │  [+ Create New Template]                           │ │
│  │                                                    │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌─ FLEXR TEMPLATES ──────────────────────────────────┐ │
│  │                                                    │ │
│  │  ┌──────────────────────────────────────┐         │ │
│  │  │  Official Full HYROX Sim    ⭐ 4.8   │   →    │ │
│  │  │  17 segments · 75 min · Advanced     │         │ │
│  │  │  Used by 12.4k athletes              │         │ │
│  │  └──────────────────────────────────────┘         │ │
│  │                                                    │ │
│  │  ┌──────────────────────────────────────┐         │ │
│  │  │  Beginner HYROX Intro       ⭐ 4.9   │   →    │ │
│  │  │  10 segments · 35 min · Beginner     │         │ │
│  │  │  Used by 8.2k athletes               │         │ │
│  │  └──────────────────────────────────────┘         │ │
│  │                                                    │ │
│  │  ┌──────────────────────────────────────┐         │ │
│  │  │  Station Strength Builder   ⭐ 4.7   │   →    │ │
│  │  │  8 segments · 50 min · Intermediate  │         │ │
│  │  │  Used by 5.9k athletes               │         │ │
│  │  └──────────────────────────────────────┘         │ │
│  │                                                    │ │
│  │  [Browse All FLEXR Templates]                      │ │
│  │                                                    │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌─ SHARED WITH ME ───────────────────────────────────┐ │
│  │                                                    │ │
│  │  ┌──────────────────────────────────────┐         │ │
│  │  │  Coach Sarah's Taper Week   ⭐ 5.0   │   →    │ │
│  │  │  5 segments · 30 min · Moderate      │         │ │
│  │  │  Shared by: Sarah M.                 │         │ │
│  │  └──────────────────────────────────────┘         │ │
│  │                                                    │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
└──────────────────────────────────────────────────────────┘

Tap template → Preview details
Long-press → Quick actions (clone, share, delete)
Swipe left → Delete (for own templates)
```

### 9.4 Workout Detail View

```
┌──────────────────────────────────────────────────────────┐
│  ← Morning HYROX Sim                          ⋮  ⭐      │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │  OVERVIEW                                          │ │
│  ├────────────────────────────────────────────────────┤ │
│  │  Type: Full HYROX Simulation                       │ │
│  │  Difficulty: Hard                                  │ │
│  │  ⏱️  45 min  ·  🏃 8.0 km  ·  🔥 620 cal          │ │
│  │                                                    │ │
│  │  Created: Dec 1, 2025                              │ │
│  │  Used: 12 times  ·  Last: Dec 10                  │ │
│  │  Avg completion: 44:15                             │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │  SEGMENTS (8)                                      │ │
│  ├────────────────────────────────────────────────────┤ │
│  │                                                    │ │
│  │  1. RUN · 1000m                                    │ │
│  │     Target: 5:00/km · ⚡⚡⚡⚡○                     │ │
│  │     Terrain: Treadmill                             │ │
│  │     ≈ 5:00                                         │ │
│  │                                                    │ │
│  │  2. STATION · SkiErg                               │ │
│  │     Distance: 1000m                                │ │
│  │     Intensity: 💪💪💪                               │ │
│  │     ≈ 3:30                                         │ │
│  │     Note: "Focus on technique"                     │ │
│  │                                                    │ │
│  │  3. TRANSITION                                     │ │
│  │     ≈ 0:30                                         │ │
│  │                                                    │ │
│  │  4. RUN · 1000m (Compromised)                      │ │
│  │     Target: 5:15/km · ⚡⚡⚡○○                     │ │
│  │     Note: "Post-station, expect pace drop"         │ │
│  │     ≈ 5:15                                         │ │
│  │                                                    │ │
│  │  5. STATION · Sled Push                            │ │
│  │     Distance: 50m x 2                              │ │
│  │     Weight: 102kg                                  │ │
│  │     ≈ 2:00 per rep                                 │ │
│  │                                                    │ │
│  │  [View All 8 Segments]                             │ │
│  │                                                    │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │  NOTES                                             │ │
│  │  This is a race-pace simulation. Focus on:        │ │
│  │  • Steady pacing on runs                          │ │
│  │  • Quick transitions                               │ │
│  │  • Managing effort on stations                     │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │  HISTORY (Last 5)                                  │ │
│  ├────────────────────────────────────────────────────┤ │
│  │  Dec 10  ·  44:15  ·  ✓ Complete  ·  💪💪💪       │ │
│  │  Dec 3   ·  45:02  ·  ✓ Complete  ·  💪💪💪💪     │ │
│  │  Nov 26  ·  46:30  ·  ⚠️ Partial  ·  💪💪         │ │
│  │  Nov 19  ·  47:15  ·  ✓ Complete  ·  💪💪💪       │ │
│  │  Nov 12  ·  48:00  ·  ✓ Complete  ·  💪💪💪       │ │
│  │                                                    │ │
│  │  [View All History]                                │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │  [Edit Template]       [Clone]       [Share]      │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │           [Add to Calendar]                        │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │           [Start Workout on Watch]                 │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

---

## 10. Competitive Analysis

### 10.1 Market Landscape

**Current Solutions for HYROX Training:**

1. **Generic Fitness Apps**
   - Strava, Nike Run Club, Apple Fitness+
   - **Pros**: Great for running, established user bases
   - **Cons**: No HYROX-specific features, can't track stations, no segmentation
   - **Price**: Free - $10/mo
   - **Market position**: Mass market fitness

2. **Strength Training Apps**
   - Strong, JEFIT, Fitbod
   - **Pros**: Great for station tracking
   - **Cons**: Poor running integration, no HYROX structure, separate from running apps
   - **Price**: $5-15/mo
   - **Market position**: Gym-focused

3. **Training Platforms**
   - TrainingPeaks, Final Surge, Today's Plan
   - **Pros**: Full program management, coach integration
   - **Cons**: No watchOS tracking, not HYROX-specific, expensive, coach-focused
   - **Price**: $20-50/mo
   - **Market position**: Serious athletes, coach-athlete

4. **HYROX-Adjacent Apps**
   - CrossFit tracking apps (Beyond the Whiteboard, SugarWOD)
   - **Pros**: Understand hybrid fitness
   - **Cons**: CrossFit-focused (not HYROX), limited running features
   - **Price**: $10-20/mo
   - **Market position**: CrossFit gyms

5. **Manual Tracking**
   - Notes apps, spreadsheets, workout journals
   - **Pros**: Free, flexible
   - **Cons**: No tracking, no analytics, tedious
   - **Price**: Free
   - **Market position**: DIY athletes

### 10.2 FLEXR's Unique Position

**What Makes FLEXR+BYOP Unique:**

| Feature | FLEXR | Competitors |
|---------|-------|-------------|
| **HYROX-Specific** | ✓ Native | ✗ Generic or adapted |
| **Run/Station Segmentation** | ✓ Automatic | ✗ Manual or none |
| **Compromised Running** | ✓ Tracked & analyzed | ✗ Not a concept |
| **watchOS Integration** | ✓ Full, native | Partial or none |
| **Custom Programs** | ✓ Easy builder | Complex or absent |
| **AI + Manual Modes** | ✓ Both tiers | Either/or |
| **Price for Tracking Only** | $9.99/mo | $0-15/mo (less features) |
| **Program Import** | ✓ Planned | Limited |

**Positioning Statement:**
> "FLEXR is the only app that combines world-class HYROX tracking with the flexibility to bring your own program or let AI handle it. Whether you're coached by a HYROX gym, training yourself, or want AI guidance, FLEXR adapts to you."

### 10.3 Competitive Advantages

**1. HYROX Specificity**
- Only app built FOR HYROX, not adapted from running or CrossFit
- Understands the unique demands (compromised running, station-to-run transitions)
- Community of HYROX athletes (not diluted with general fitness users)

**2. Apple Watch Excellence**
- Native watchOS app (not an iPhone companion)
- Automatic segment switching
- Haptic feedback tuned for HYROX
- Best-in-class on-wrist experience

**3. Flexible Tier System**
- Only platform offering BOTH AI and manual modes
- Tracker tier is affordable entry point
- Natural upsell path (not forced)
- Users choose their level of automation

**4. Data Superiority**
- Compromised running is unique to FLEXR
- Station-specific analytics (not generic "strength")
- HYROX race predictions (based on real HYROX data)
- Transition time tracking

**5. Community & Content**
- Program sharing between athletes
- Public template library
- Gym/coach partnerships for official programs
- HYROX-specific insights (not generic fitness advice)

### 10.4 Threats & Mitigations

| Threat | Mitigation |
|--------|-----------|
| **Generic apps add HYROX features** | First-mover advantage, community lock-in, superior tracking |
| **HYROX official app launches** | Partner with HYROX, emphasize flexibility, deeper features |
| **Strava adds station tracking** | Our Apple Watch experience is better, HYROX-specific analytics |
| **Free alternatives** | Free tier for trial, cheap Tracker tier, network effects |
| **Athletes don't want to pay** | Focus on serious HYROX athletes (not casual), ROI from better training |

---

## 11. Implementation Phases

### Phase 1: MVP (Q1 2026) - Core BYOP

**Timeline**: 12 weeks

**Features**:
- ✓ Manual workout builder (iOS)
- ✓ 5-10 FLEXR system templates
- ✓ Basic calendar (weekly view)
- ✓ Single program support
- ✓ Custom workout tracking on watchOS
- ✓ Database schema (core tables)
- ✓ Tracker tier subscription (Stripe)
- ✓ Basic analytics (segment tracking)

**Success Criteria**:
- 100 beta users create custom workouts
- 70%+ complete at least 5 custom workouts
- <5% critical bugs
- Apple Watch tracking works seamlessly

### Phase 2: Program Management (Q2 2026)

**Timeline**: 8 weeks

**Features**:
- ✓ Multi-program support
- ✓ Calendar: Drag & drop, recurring patterns
- ✓ Program structure (mesocycles, weekly templates)
- ✓ Template library (discover & clone)
- ✓ Program sharing (friends)
- ✓ AI insights (read-only for Tracker tier)
- ✓ Weekly analytics & completion tracking

**Success Criteria**:
- 40%+ of Tracker users create programs
- Avg 3+ weeks of scheduled workouts
- 15%+ share programs with friends
- 10%+ Tracker → AI conversion from insights

### Phase 3: AI Enhancement & Social (Q3 2026)

**Timeline**: 10 weeks

**Features**:
- ✓ Advanced AI insights (5 types)
- ✓ Upgrade prompts (A/B tested)
- ✓ Public program templates
- ✓ Rating & review system
- ✓ Coach profiles (verified)
- ✓ Program analytics dashboard
- ✓ Export workouts (PDF, CSV, ICS)
- ✓ In-app notifications for insights

**Success Criteria**:
- 25%+ Tracker → AI conversion rate
- 20%+ users browse public templates
- 1000+ public templates created
- 4.5+ avg rating on templates

### Phase 4: Import & Integrations (Q4 2026)

**Timeline**: 12 weeks

**Features**:
- ✓ Text parser (copy/paste workouts)
- ✓ Photo/PDF import (OCR)
- ✓ TrainingPeaks integration
- ✓ Google Sheets import
- ✓ Email forwarding (coach plans)
- ✓ Batch import for full programs
- ✓ API for gym/coach platforms

**Success Criteria**:
- 30%+ of custom workouts are imported
- 90%+ parse accuracy for text
- 75%+ parse accuracy for OCR
- 5+ gym partnerships using API

### Phase 5: Advanced Features (Q1 2027)

**Timeline**: Ongoing

**Features**:
- ✓ Video library for station form
- ✓ Community forum/groups
- ✓ Challenges & leaderboards (custom programs)
- ✓ Wearable integrations (Garmin, Whoop)
- ✓ Nutrition tracking (basic)
- ✓ Advanced biomechanics (power, cadence)
- ✓ VR/AR workout previews

---

## 12. Success Metrics & KPIs

### 12.1 Product Metrics

**Adoption**
```yaml
Target Metrics (Year 1):
  total_users: 50,000
  tracker_tier_users: 15,000 (30%)
  ai_powered_tier_users: 10,000 (20%)
  free_tier_users: 25,000 (50%)

  conversion_funnel:
    free_to_tracker: 60% (within 30 days)
    tracker_to_ai: 40% (within 90 days)
    free_to_ai_direct: 10%
```

**Engagement**
```yaml
Target Metrics:
  custom_workouts_created_per_user: 8 (avg, Tracker tier)
  programs_created_per_user: 2 (avg, Tracker tier)
  workouts_tracked_per_month: 12 (avg, active users)
  templates_cloned_per_user: 3 (avg)

  retention:
    day_7: 75%
    day_30: 60%
    month_3: 50%
    month_6: 40%
    month_12: 30%
```

**Feature Usage**
```yaml
Target Metrics:
  users_with_custom_workouts: 85% (Tracker + AI tiers)
  users_with_programs: 60% (Tracker + AI tiers)
  users_sharing_programs: 25%
  users_viewing_ai_insights: 70% (Tracker tier)

  avg_calendar_weeks_scheduled: 4
  avg_program_completion_rate: 65%
```

### 12.2 Business Metrics

**Revenue**
```yaml
Target Metrics (Year 1):
  MRR: $200,000
  ARR: $2,400,000

  revenue_breakdown:
    tracker_tier: 40%
    ai_tier: 60%

  ARPU:
    tracker: $9.99/mo
    ai: $19.99/mo
    blended: $14.50/mo

  LTV:
    tracker: $240 (24 months avg)
    ai: $480 (24 months avg)
```

**Growth**
```yaml
Target Metrics:
  MoM_user_growth: 15%
  MoM_revenue_growth: 18%

  viral_coefficient: 0.3 (from program sharing)
  referral_rate: 12%
```

**Churn**
```yaml
Target Metrics:
  monthly_churn:
    tracker: 8%
    ai: 5%

  annual_churn:
    tracker: 45%
    ai: 35%

  reasons_for_churn:
    - race_completed: 30%
    - too_expensive: 25%
    - not_using: 20%
    - switched_platform: 15%
    - other: 10%
```

### 12.3 Conversion Metrics

**Free → Tracker**
```yaml
Conversion Points:
  workout_limit_reached: 40% CVR
  feature_gate_templates: 35% CVR
  week_2_engagement_prompt: 15% CVR

Avg Time to Convert: 12 days
```

**Tracker → AI**
```yaml
Conversion Points:
  ai_insight_engagement: 20% CVR
  manual_planning_fatigue: 15% CVR
  race_prep_6_weeks_out: 30% CVR
  long_term_user_3mo: 25% CVR

Avg Time to Convert: 45 days
```

**Conversion Optimization**
```yaml
A/B Tests:
  - insight_frequency
  - upgrade_prompt_timing
  - pricing_display
  - free_trial_length
  - feature_gate_placement

Target: 50% improvement in CVR over 6 months
```

---

## 13. Technical Considerations

### 13.1 Performance

**Database Query Optimization**
- Index all foreign keys
- Materialized views for analytics
- Caching for template library (Redis)
- Pagination for long lists

**API Response Times**
- GET templates: <200ms
- GET calendar (month): <300ms
- POST create workout: <500ms
- GET analytics: <1s (complex aggregations)

**watchOS Sync**
- Workout segments pre-cached on watch
- Offline mode for tracking (sync later)
- Incremental sync (not full reload)
- Background refresh for scheduled workouts

### 13.2 Scalability

**Data Volume Projections**
```yaml
Year 1 (50k users):
  custom_workout_templates: 400k (8 per user)
  programs: 100k (2 per user)
  scheduled_workouts: 5M (100 per user)
  tracked_workouts: 3M (60 per user)
  segment_records: 30M (10 segments per workout)

Storage: ~500GB (including analytics)
Database: PostgreSQL (managed, scalable)
```

**Scaling Strategy**
- Horizontal scaling for API servers
- Read replicas for analytics queries
- CDN for template images/icons
- Object storage (S3) for exports/backups
- Background job processing (Redis queue)

### 13.3 Security & Privacy

**Data Protection**
- Encryption at rest (database)
- Encryption in transit (TLS)
- User data isolation (row-level security)
- GDPR compliant (data export, deletion)

**Sharing Permissions**
- Granular controls (view/edit/clone)
- Revocable sharing links
- Private by default
- Audit logs for shared programs

**Payment Security**
- Stripe for all transactions
- No credit card storage
- PCI DSS compliant
- Webhook signature verification

---

## 14. Go-To-Market Strategy

### 14.1 Launch Plan

**Pre-Launch (4 weeks before)**
- Beta with 100 users (select HYROX athletes)
- Collect feedback & testimonials
- Create demo videos (workout builder, calendar)
- PR outreach (fitness tech press)
- Social media teasers

**Launch Week**
- Product Hunt launch (target #1-3 of day)
- Blog post announcement
- Email to waitlist (10k+ emails)
- HYROX gym partnerships (5-10 gyms)
- Influencer seeding (10 athletes)

**Post-Launch (4 weeks)**
- Onboarding optimization (reduce drop-off)
- User interviews (10-20 per week)
- Rapid iteration on feedback
- Community building (Discord/forum)
- Content marketing (blog, YouTube)

### 14.2 Marketing Channels

**Paid Acquisition**
- Facebook/Instagram ads (HYROX interest targeting)
- Google Search (HYROX training app keywords)
- YouTube ads (fitness channels)
- Podcast sponsorships (running, fitness)

**Organic Growth**
- SEO (HYROX training content)
- YouTube (workout tutorials, app walkthroughs)
- Instagram (transformation stories, tips)
- TikTok (short workout clips, hacks)
- Blog (training guides, race prep)

**Partnerships**
- HYROX gyms (official app partner)
- Personal trainers (coach program)
- Running stores (affiliate)
- Fitness influencers (ambassador program)

**Viral Mechanics**
- Program sharing (invite friends)
- Referral rewards (1 month free)
- Leaderboards & challenges
- Social proof (X athletes using FLEXR)

### 14.3 Messaging

**Tracker Tier Positioning**
```
Headline: "Your Program, Your Way. World-Class Tracking."

Subheadline: "Already have a training program? FLEXR gives you the best
Apple Watch HYROX tracking experience—without changing your plan."

Key Points:
• Build custom workouts in minutes
• Track every run, station, transition
• Compromised running analysis
• Program calendar & scheduling
• All for less than a coffee per week

CTA: "Start Tracking Free" (7-day trial)
```

**AI-Powered Tier Positioning**
```
Headline: "AI Coach + Elite Tracking = Your Best HYROX"

Subheadline: "Let AI handle your programming while you focus on training.
Adaptive plans that adjust to your progress, recovery, and race goals."

Key Points:
• AI generates personalized workouts
• Auto-adjusts based on performance
• Race-specific taper & strategy
• Everything in Tracker tier
• Trusted by 10k+ HYROX athletes

CTA: "Upgrade to AI" (7-day free trial)
```

**Conversion Messaging (Tracker → AI)**
```
Headline: "Imagine if your training adapted to you."

Subheadline: "You're doing the hard work manually. AI-Powered tier
automatically balances volume, intensity, and recovery—so you can focus
on showing up and crushing workouts."

Key Points:
• Stop planning, start training
• Auto-adjusts when you're tired
• Optimizes for your race date
• Keep all your data & progress

CTA: "Try AI Free for 7 Days"
```

---

## 15. Risks & Mitigation

### 15.1 Product Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **Workout builder too complex** | High | Medium | Extensive usability testing, simple default flows |
| **Manual tracking tedious vs AI** | High | High | Make templates & import easy, show AI value clearly |
| **Poor watchOS sync** | Critical | Low | Thorough testing, offline mode, incremental sync |
| **Data migration issues** | High | Medium | Robust import validation, manual review step |
| **Feature creep delays launch** | Medium | High | Strict MVP scope, phased rollout |

### 15.2 Business Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **Low Tracker tier retention** | High | Medium | Engagement features, AI insights to upsell, community |
| **Tracker → AI conversion too low** | High | Medium | A/B test prompts, timing, pricing; improve AI value prop |
| **Cannibalization of AI tier** | Critical | Medium | Make AI tier clearly superior, limit Tracker features |
| **Price sensitivity** | Medium | High | Free tier for trial, emphasize value, annual discount |
| **Competitor launches HYROX app** | High | Medium | First-mover advantage, superior features, community lock-in |

### 15.3 Market Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **HYROX is a fad** | Critical | Low | Grow with sport, diversify to functional fitness |
| **Athletes prefer manual tracking** | Medium | Low | Show value of data-driven training, easy export |
| **Gym partnerships fail** | Medium | Medium | Direct-to-consumer focus, influencer marketing |
| **Apple Watch loses market share** | High | Low | Multi-platform (Garmin, Whoop) in Phase 5 |

---

## 16. Future Enhancements (Post-BYOP)

**Phase 6+: Advanced Program Features**
- AI hybrid mode (AI + manual control)
- Coaching marketplace (sell programs)
- Team/group programs (gyms, clubs)
- Race day pacing calculator
- Virtual race simulations (compete with others)

**Platform Expansion**
- Android/WearOS support
- Garmin Connect IQ app
- Whoop integration
- Peloton Tread integration

**Ecosystem**
- FLEXR coaching certification
- Gym/coach dashboard (manage athletes)
- Nutrition planning integration
- Physical therapy/injury prevention
- Equipment tracking (sled, SkiErg at home)

---

## Appendix A: Sample JSON Structures

### Custom Workout Template (JSONB)

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Morning HYROX Simulation",
  "workout_type": "full_sim",
  "difficulty_level": "hard",
  "segments": [
    {
      "order": 1,
      "type": "run",
      "distance_meters": 1000,
      "target_time_seconds": 300,
      "target_pace_per_km": "5:00",
      "effort_level": 4,
      "terrain": "treadmill",
      "notes": "Steady pace, warm up first 200m"
    },
    {
      "order": 2,
      "type": "transition",
      "expected_duration_seconds": 30
    },
    {
      "order": 3,
      "type": "station",
      "station_name": "SkiErg",
      "target_distance_meters": 1000,
      "target_time_seconds": 210,
      "effort_level": 5,
      "notes": "Focus on technique, long pulls"
    },
    {
      "order": 4,
      "type": "transition",
      "expected_duration_seconds": 30
    },
    {
      "order": 5,
      "type": "run",
      "distance_meters": 1000,
      "target_pace_per_km": "5:15",
      "effort_level": 3,
      "notes": "Compromised run, expect slower pace"
    },
    {
      "order": 6,
      "type": "rest",
      "duration_seconds": 120,
      "rest_type": "active"
    }
  ],
  "estimated_duration_minutes": 45,
  "estimated_distance_meters": 8000,
  "tags": ["full-sim", "race-pace", "treadmill"],
  "notes": "Race simulation. Focus on transitions and pacing."
}
```

### Program Schedule (Recurrence Rule)

```json
{
  "recurrence_rule": {
    "frequency": "weekly",
    "interval": 1,
    "days_of_week": [1, 3, 5],
    "end_type": "date",
    "end_date": "2026-03-01",
    "progression": {
      "type": "auto",
      "increment_type": "percentage",
      "increment_value": 5,
      "applies_to": ["distance_meters", "target_time_seconds"]
    }
  }
}
```

### AI Insight

```json
{
  "insight_type": "training_balance",
  "title": "Station Volume Below Optimal",
  "description": "Your last 4 weeks show 68% running vs 32% station work. HYROX athletes perform best with 55-60% running, 40-45% stations.",
  "recommendations": [
    "Add 1-2 station-focused sessions per week",
    "Consider replacing one easy run with station circuit",
    "Focus on lower body stations (sled, lunges) for balance"
  ],
  "data": {
    "running_percentage": 68,
    "station_percentage": 32,
    "target_running": 57.5,
    "target_station": 42.5,
    "weeks_analyzed": 4
  },
  "severity": "warning",
  "upgrade_prompt": {
    "message": "AI-Powered tier would automatically balance your program to optimize for HYROX performance.",
    "cta": "Upgrade to AI Coach"
  }
}
```

---

## Appendix B: Database Migration Script

```sql
-- Migration: Add BYOP tables to existing FLEXR schema
-- Version: 1.0.0
-- Date: 2026-01-01

BEGIN;

-- Create custom programs table
CREATE TABLE IF NOT EXISTS custom_programs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    goal TEXT,
    difficulty_level VARCHAR(50),
    duration_weeks INTEGER,
    start_date DATE,
    end_date DATE,
    target_race_date DATE,
    created_by_type VARCHAR(50),
    coach_name VARCHAR(255),
    source_organization VARCHAR(255),
    mesocycles JSONB,
    weekly_volume_target INTEGER,
    quality_sessions_per_week INTEGER,
    is_public BOOLEAN DEFAULT false,
    is_template BOOLEAN DEFAULT false,
    shared_with UUID[],
    times_cloned INTEGER DEFAULT 0,
    tags TEXT[],
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT valid_dates CHECK (end_date >= start_date)
);

-- Create indexes
CREATE INDEX idx_custom_programs_user ON custom_programs(user_id);
CREATE INDEX idx_custom_programs_public ON custom_programs(is_public) WHERE is_public = true;
CREATE INDEX idx_custom_programs_tags ON custom_programs USING GIN(tags);

-- Create custom_workout_templates table
CREATE TABLE IF NOT EXISTS custom_workout_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    program_id UUID REFERENCES custom_programs(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    workout_type VARCHAR(50),
    difficulty_level VARCHAR(50),
    segments JSONB NOT NULL,
    estimated_duration_minutes INTEGER,
    estimated_distance_meters INTEGER,
    estimated_calories INTEGER,
    target_effort_level INTEGER,
    times_used INTEGER DEFAULT 0,
    last_used_at TIMESTAMP,
    avg_completion_time_minutes INTEGER,
    is_public BOOLEAN DEFAULT false,
    is_system_template BOOLEAN DEFAULT false,
    times_cloned INTEGER DEFAULT 0,
    tags TEXT[],
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_custom_workout_templates_user ON custom_workout_templates(user_id);
CREATE INDEX idx_custom_workout_templates_program ON custom_workout_templates(program_id);
CREATE INDEX idx_custom_workout_templates_type ON custom_workout_templates(workout_type);
CREATE INDEX idx_custom_workout_templates_public ON custom_workout_templates(is_public) WHERE is_public = true;

-- Create program_schedule table
CREATE TABLE IF NOT EXISTS program_schedule (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    program_id UUID REFERENCES custom_programs(id) ON DELETE CASCADE,
    workout_template_id UUID REFERENCES custom_workout_templates(id) ON DELETE CASCADE,
    scheduled_date DATE NOT NULL,
    scheduled_time TIME,
    week_number INTEGER,
    day_of_week INTEGER,
    status VARCHAR(50) DEFAULT 'scheduled',
    completion_status VARCHAR(50),
    actual_workout_id UUID REFERENCES workouts(id),
    is_modified BOOLEAN DEFAULT false,
    original_workout_template_id UUID REFERENCES custom_workout_templates(id),
    modifications JSONB,
    is_recurring BOOLEAN DEFAULT false,
    recurrence_rule JSONB,
    parent_schedule_id UUID REFERENCES program_schedule(id),
    pre_workout_notes TEXT,
    post_workout_notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP,
    CONSTRAINT unique_user_date_template UNIQUE(user_id, scheduled_date, workout_template_id)
);

-- Create indexes
CREATE INDEX idx_program_schedule_user_date ON program_schedule(user_id, scheduled_date);
CREATE INDEX idx_program_schedule_program ON program_schedule(program_id);
CREATE INDEX idx_program_schedule_status ON program_schedule(status);
CREATE INDEX idx_program_schedule_week ON program_schedule(program_id, week_number);

-- Add columns to existing workouts table
ALTER TABLE workouts
ADD COLUMN IF NOT EXISTS is_custom_workout BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS custom_workout_template_id UUID REFERENCES custom_workout_templates(id),
ADD COLUMN IF NOT EXISTS program_schedule_id UUID REFERENCES program_schedule(id);

CREATE INDEX idx_workouts_custom_template ON workouts(custom_workout_template_id);
CREATE INDEX idx_workouts_program_schedule ON workouts(program_schedule_id);

-- Add subscription columns to users table
ALTER TABLE users
ADD COLUMN IF NOT EXISTS subscription_tier VARCHAR(50) DEFAULT 'free',
ADD COLUMN IF NOT EXISTS subscription_start_date TIMESTAMP,
ADD COLUMN IF NOT EXISTS subscription_end_date TIMESTAMP,
ADD COLUMN IF NOT EXISTS subscription_status VARCHAR(50) DEFAULT 'active',
ADD COLUMN IF NOT EXISTS stripe_customer_id VARCHAR(255),
ADD COLUMN IF NOT EXISTS stripe_subscription_id VARCHAR(255);

CREATE INDEX idx_users_subscription_tier ON users(subscription_tier);
CREATE INDEX idx_users_subscription_status ON users(subscription_status);

-- Create remaining tables (analytics, shares, usage tracking)
-- ... (see full schema in Section 4.1)

COMMIT;
```

---

## Document Status

**Current Version**: 1.0 (Draft)
**Last Updated**: 2025-12-01
**Next Review**: After Phase 1 MVP completion

**Feedback & Questions**: Contact architecture team

**Related Documents**:
- `/docs/api/BYOP-API-Spec.md`
- `/docs/design/USER-FLOWS.md`
- `/docs/business/PRICING-STRATEGY.md`
- `/docs/engineering/BYOP-IMPLEMENTATION.md`

---

**END OF DOCUMENT**
