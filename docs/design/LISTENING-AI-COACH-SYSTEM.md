# FLEXR: Listening AI Coach System

## Vision

**"A data-driven AI that makes users feel heard"**

The app collects objective metrics AND subjective feedback, then shows users exactly how their input shapes their training. Every workout explanation proves: "This is FOR YOU."

---

## The Three Pillars

```
┌─────────────────────────────────────────────────────────────────┐
│                    LISTENING AI COACH                           │
├───────────────────┬───────────────────┬─────────────────────────┤
│   1. COLLECT      │   2. ANALYZE      │   3. EXPLAIN            │
│   ──────────      │   ──────────      │   ──────────            │
│   Objective +     │   AI processes    │   Show the user         │
│   Subjective      │   both types      │   WHY this workout      │
│   feedback        │   of data         │   is for THEM           │
└───────────────────┴───────────────────┴─────────────────────────┘
```

---

## Pillar 1: COLLECT - The Feedback System

### A. Post-Workout Feedback (Required)

After every workout, collect:

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| RPE Score | 1-10 slider | Yes | Perceived difficulty |
| Completion | % | Auto | Did they finish? |
| Quick Tags | Multi-select | No | Structured insights |
| Free Text | Text field | No | Rich context |

**Quick Tags Options:**
- Difficulty: `too_easy`, `just_right`, `too_hard`
- Energy: `high_energy`, `normal`, `low_energy`, `exhausted`
- Body: `felt_strong`, `tight_muscles`, `minor_pain`, `injury_concern`
- Enjoyment: `loved_it`, `boring`, `hated_it`
- External: `time_pressed`, `bad_sleep`, `stressed`, `great_day`

### B. Objective Metrics (Automatic)

Collected from Apple Watch / HealthKit:

| Metric | Source | Usage |
|--------|--------|-------|
| Avg Heart Rate | Watch | Intensity validation |
| Max Heart Rate | Watch | Peak effort |
| Heart Rate Zones | Watch | Time in each zone |
| Actual Duration | App | vs. Prescribed |
| Calories | Watch | Energy expenditure |
| Pace (running) | Watch | Speed tracking |
| HRV | Watch | Recovery status |
| Sleep | HealthKit | Readiness |

### C. Pre-Workout Check (Optional - Phase 2)

Before starting a workout:

```
"How are you feeling today?"

😫 Terrible  →  "Got it. I'll suggest modifications."
😕 Not great →  "Let's take it easier on intensity."
😐 Normal    →  "Perfect, let's do this."
🙂 Good      →  "Great! Ready to push?"
💪 Amazing   →  "Let's make this count!"
```

---

## Pillar 2: ANALYZE - The AI Processing

### Weekly Analysis (Sunday Night)

Before generating Week N+2, AI receives:

```json
{
  "user_id": "uuid",
  "generating_week": 4,

  "user_profile": {
    "experience_level": "intermediate",
    "goal": "compete_race",
    "race_date": "2025-03-15",
    "weeks_until_race": 14,
    "weak_stations": ["sled_push", "wall_balls"],
    "strong_stations": ["rowing", "ski_erg"]
  },

  "week_2_summary": {
    "workouts_planned": 12,
    "workouts_completed": 11,
    "completion_rate": 0.92,
    "avg_rpe": 7.2,
    "rpe_trend": "stable",
    "common_tags": ["just_right", "low_energy"],
    "user_notes": [
      "Tuesday: felt tired, bad sleep night before",
      "Friday: loved the running intervals",
      "Saturday: shoulder tight during wall balls"
    ],
    "objective_metrics": {
      "avg_hr_vs_target": "+3%",
      "running_pace_vs_target": "-2%",
      "total_volume_completed": "95%"
    }
  },

  "week_3_summary": {
    "workouts_planned": 12,
    "workouts_completed": 10,
    "completion_rate": 0.83,
    "avg_rpe": 6.5,
    "rpe_trend": "decreasing",
    "common_tags": ["too_easy", "high_energy"],
    "user_notes": [
      "Everything felt easy this week",
      "Ready for more challenge"
    ],
    "objective_metrics": {
      "avg_hr_vs_target": "-5%",
      "running_pace_vs_target": "-4%",
      "total_volume_completed": "100%"
    }
  },

  "health_context": {
    "avg_hrv_trend": "improving",
    "avg_sleep_hours": 7.2,
    "sleep_trend": "stable"
  }
}
```

### AI Decision Matrix

| Signal | AI Response |
|--------|-------------|
| RPE decreasing + "too easy" tags | Increase intensity 5-10% |
| RPE increasing + "too hard" tags | Decrease intensity or add recovery |
| "low_energy" mid-week pattern | Make Wed/Thu lighter |
| "shoulder tight" mention | Add mobility, modify movements |
| High completion + low RPE | Progressive overload ready |
| Low completion + high RPE | Reduce volume, check recovery |
| Poor sleep trend | Reduce intensity, prioritize recovery |
| "loved X" feedback | Include more of X |
| "hated X" feedback | Reduce X or find alternatives |

---

## Pillar 3: EXPLAIN - The Coach Notes

### Where Coach Explains

| Location | What to Explain | Example |
|----------|-----------------|---------|
| Week Header | Week's overall approach | "Building on last week's strong running - adding speed work" |
| Workout Card | Why this workout today | "Station focus on your weakest: sled push" |
| Segment Detail | Why these specific targets | "Pace 5:10/km - 5s faster than last week" |
| Rest Day | Why rest matters | "Your HRV dropped 12%. Recovery = gains." |
| Adaptation Notice | When plan changed | "Moved Thursday's HIIT - you mentioned fatigue" |

### Coach Note Structure

```swift
struct CoachNote {
    let headline: String      // Short, punchy
    let explanation: String   // 1-2 sentences why
    let basedOn: [DataPoint]  // What data drove this
}

struct DataPoint {
    let type: DataPointType   // .feedback, .metric, .trend
    let label: String         // "Last week's RPE"
    let value: String         // "7.2 avg"
}
```

### Example Coach Notes

**Week Overview:**
```
"Week 4: Time to Push"

Your RPE dropped from 7.2 to 6.5 last week and you tagged
workouts as "too easy." Your body is adapting - let's
challenge it. Intensity up 8%, plus a tempo run on Saturday.

Based on: RPE trend ↓, "too easy" tags (3x), HR 5% below target
```

**Workout Card:**
```
"Sled & Wall Ball Focus"

These are your two weakest stations (23% and 18% below target).
Today's session is technique-heavy with progressive loading.

Based on: Station performance data, 6 weeks to race
```

**Rest Day:**
```
"Active Recovery"

Yesterday was tough (RPE 8) and you mentioned tight shoulders.
Light mobility today, focusing on upper body.

Based on: Yesterday's RPE 8, "tight shoulders" note
```

**Adaptation:**
```
"Plan Adjusted"

I moved Thursday's interval session to Friday. You've
mentioned low energy mid-week twice - let's fix that pattern.

Based on: "low_energy" tags (Tue, Wed), workout timing analysis
```

---

## Database Schema

### New Tables

```sql
-- User feedback after each workout
CREATE TABLE workout_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) NOT NULL,
    workout_id UUID REFERENCES planned_workouts(id) NOT NULL,

    -- Subjective
    rpe_score INTEGER CHECK (rpe_score >= 1 AND rpe_score <= 10),
    mood_score INTEGER CHECK (mood_score >= 1 AND mood_score <= 5),
    tags TEXT[] DEFAULT '{}',
    free_text TEXT,

    -- Objective (from HealthKit)
    actual_duration_seconds INTEGER,
    avg_heart_rate INTEGER,
    max_heart_rate INTEGER,
    calories_burned INTEGER,
    completion_percentage DECIMAL(5,2),

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(workout_id)  -- One feedback per workout
);

-- Weekly AI analysis summary
CREATE TABLE weekly_analysis (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) NOT NULL,
    week_number INTEGER NOT NULL,

    -- Aggregated data
    workouts_completed INTEGER,
    workouts_planned INTEGER,
    avg_rpe DECIMAL(3,1),
    rpe_trend TEXT,  -- 'increasing', 'stable', 'decreasing'
    common_tags TEXT[],
    user_notes_summary TEXT,  -- AI-summarized notes

    -- AI recommendations
    ai_recommendations JSONB,
    /*
    {
        "intensity_adjustment": "+8%",
        "focus_areas": ["sled_push", "running_speed"],
        "avoid": ["high_volume_burpees"],
        "notes": "User adapting well, ready for progression"
    }
    */

    -- Metadata
    analyzed_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id, week_number)
);

-- Coach notes for display
CREATE TABLE coach_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) NOT NULL,

    -- What this note is for
    note_type TEXT NOT NULL,  -- 'week', 'workout', 'segment', 'rest_day', 'adaptation'
    reference_id UUID,  -- week_id, workout_id, or segment_id

    -- The note content
    headline TEXT NOT NULL,
    explanation TEXT NOT NULL,
    based_on JSONB,  -- Array of data points

    -- Display
    is_read BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Updates to Existing Tables

```sql
-- Add to planned_workouts
ALTER TABLE planned_workouts
ADD COLUMN coach_note_headline TEXT,
ADD COLUMN coach_note_explanation TEXT,
ADD COLUMN coach_note_data_points JSONB;

-- Add to training_weeks
ALTER TABLE training_weeks
ADD COLUMN week_coach_note TEXT,
ADD COLUMN week_adjustments JSONB;
```

---

## User Flows

### Flow 1: Post-Workout Feedback

```
[Workout Complete Screen]
         │
         ▼
┌─────────────────────────┐
│  "How did that feel?"   │
│                         │
│  [1-10 RPE Slider]      │
│                         │
│  Quick tags:            │
│  [Too easy] [Just right]│
│  [Too hard] [Low energy]│
│                         │
│  "Anything else?"       │
│  [________________]     │
│                         │
│  [Save & Done]          │
└─────────────────────────┘
         │
         ▼
┌─────────────────────────┐
│  "Thanks! This helps    │
│   me build your perfect │
│   Week 4."              │
│                         │
│   [See Week Summary]    │
└─────────────────────────┘
```

### Flow 2: Viewing Coach Insights

```
[Weekly Plan View]
         │
         ▼
┌─────────────────────────────────────┐
│ Week 4: Time to Push                │
│ ─────────────────────────           │
│ 🧠 "Your RPE dropped to 6.5 and     │
│    you tagged 'too easy' 3x.        │
│    Intensity up 8% this week."      │
│                                     │
│ Based on: [RPE↓] [Tags] [HR data]   │
└─────────────────────────────────────┘
         │
         ▼
[Workout Card]
┌─────────────────────────────────────┐
│ Sled & Wall Ball Focus              │
│ 45 min • Hard                       │
│ ─────────────────────────           │
│ ✨ "Your two weakest stations.      │
│    Technique focus with             │
│    progressive loading."            │
│                                     │
│ [View Details →]                    │
└─────────────────────────────────────┘
```

### Flow 3: Plan Adaptation Notification

```
[Push Notification]
"🔄 Plan adjusted based on your feedback"
         │
         ▼
[Adaptation Detail Screen]
┌─────────────────────────────────────┐
│ 🔄 Your Plan Adapted                │
│ ─────────────────────────           │
│                                     │
│ What changed:                       │
│ • Thursday HIIT → Friday            │
│ • Wednesday now recovery run        │
│ • Added shoulder mobility           │
│                                     │
│ Why:                                │
│ "You mentioned low energy mid-week  │
│  and tight shoulders. This schedule │
│  gives you recovery when you need   │
│  it."                               │
│                                     │
│ Based on:                           │
│ [RPE 8 Tue] ["tight shoulders"]     │
│ ["low_energy" x2]                   │
│                                     │
│ [Looks good!]  [Undo changes]       │
└─────────────────────────────────────┘
```

---

## Implementation Phases

### Phase 1: Feedback Collection (Week 1)
- [ ] Database migration for `workout_feedback` table
- [ ] Post-workout feedback UI (RPE + tags + text)
- [ ] Save feedback to database
- [ ] Basic feedback history view

### Phase 2: Coach Notes Display (Week 2)
- [ ] Update `planned_workouts` schema for coach notes
- [ ] Enhance workout cards to show coach notes
- [ ] Week overview coach note
- [ ] Rest day explanations

### Phase 3: AI Integration (Week 3)
- [ ] Weekly analysis aggregation query
- [ ] Modify edge function to receive feedback data
- [ ] AI prompt engineering for personalized notes
- [ ] Generate and save coach notes

### Phase 4: Week N+2 Generation (Week 4)
- [ ] Cron job setup (Sunday night)
- [ ] Feedback-aware week generation
- [ ] Adaptation notifications
- [ ] "What changed" UI

### Phase 5: Polish (Week 5)
- [ ] Pre-workout readiness check
- [ ] Trend visualizations
- [ ] "AI learned this about you" summary
- [ ] Undo adaptation feature

---

## Success Metrics

| Metric | Target | Why |
|--------|--------|-----|
| Feedback completion rate | >70% | Users engaging with system |
| Coach note read rate | >50% | Users value explanations |
| "Too hard/easy" frequency | <20% | AI calibrating correctly |
| Week completion rate | >85% | Sustainable programming |
| NPS improvement | +15 | Users feel heard |

---

## Open Questions

1. **How much explanation is too much?**
   - Risk of overwhelming users with text
   - Solution: Collapsible sections, progressive disclosure

2. **What if user ignores feedback prompts?**
   - Fall back to objective data only
   - Gentle reminders, not blocking

3. **Handling contradictory signals?**
   - User says "too easy" but HR was maxed
   - AI should note discrepancy, maybe ask follow-up

4. **Privacy of free-text notes?**
   - AI reads them for training
   - Be transparent about this

---

## Summary

```
COLLECT          →    ANALYZE         →    EXPLAIN
────────              ────────              ────────
RPE scores            Weekly summary        Coach notes
Quick tags            AI processing         "Why this workout"
Free text             Trend detection       "Based on: [data]"
HealthKit data        Recommendations       Adaptation alerts

        ↑                                         │
        └─────────────────────────────────────────┘
                    Feedback Loop
```

**The magic**: Users give 30 seconds of feedback → AI gives them a plan that feels personally crafted.
