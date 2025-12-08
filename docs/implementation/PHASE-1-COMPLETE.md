# Phase 1 Complete: Database Foundation ✅

## What We Just Built

### 1. Database Migration (008_enhanced_onboarding.sql)

**Extended `users` table** with minimal core onboarding:
- `training_background` - New/Gym/Runner/CrossFit/HYROX Veteran
- `primary_goal` - First HYROX/PR/Podium/Train Style
- `race_date` - When they're racing
- `target_time_seconds` - Goal finish time
- `weeks_to_race` - Auto-calculated
- `just_finished_race` - Recovery needed?
- `days_per_week` - 3-7 training days
- `sessions_per_day` - 1 or 2
- `preferred_time` - Morning/Afternoon/Evening/Flexible
- `equipment_location` - Quick gym type selection
- `onboarding_completed_at` - Timestamp
- `refinement_completed_at` - Timestamp

**Created `user_performance_benchmarks` table**:
- Running PRs (1km, 5km, Zone 2 pace)
- Strength PRs (squat, deadlift)
- HYROX station PRs (all 8 stations)
- Confidence score (how sure AI is)
- Source (user input vs AI learned)

**Created `user_equipment_access` table**:
- Location type (smart defaults)
- 16 equipment flags (SkiErg, Sled, Rower, etc.)
- Multiple locations support
- Substitution preference
- Smart defaults function included!

**Created `user_weaknesses` table**:
- Weak stations (up to 3)
- Strength ranking (drag-to-order)
- Injuries array
- Training split preference
- Motivation type

**Created `workout_feedback` table**:
- RPE (1-10)
- Could do more? (yes/maybe/no)
- Weights used (JSONB - flexible)
- Quick issue checkboxes
- Free text notes
- AI adjustments made

**Added helper view**: `user_complete_profile`
- Joins all tables for AI plan generation
- One query gets everything

---

### 2. TypeScript Models

**Updated `user.model.ts`**:
- Added all new user fields with types
- TrainingBackground, PrimaryGoal, PreferredTime enums
- Backward compatible (all optional)

**Created `onboarding.model.ts`**:
- `UserPerformanceBenchmarks` interface
- `UserEquipmentAccess` interface
- `UserWeaknesses` interface
- `WorkoutFeedback` interface
- `CompleteUserProfile` interface (for AI)
- Helper functions:
  - `calculateWeeksToRace()`
  - `paceToSeconds()` / `secondsToPace()`
  - `timeToSeconds()` / `secondsToTime()`

---

### 3. Weight Prescription Service

**Created `weight-prescription.ts`**:

**Smart weight calculation from:**
1. **User PRs** (most accurate)
   - Sled push = 60% of squat PR
   - Sled pull = 40% of squat PR
   - Farmers carry = 25% of deadlift PR each hand
   - Sandbag = 40% of deadlift PR

2. **Fitness Level Estimates** (if no PRs)
   - Beginner/Intermediate/Advanced/Elite
   - Gender-adjusted (female = 65% of male estimates)

3. **Conservative Start** (Week 1)
   - Reduces calculated weight by 20%
   - Learn from feedback, adjust Week 2+

**Feedback-Based Adjustment:**
```typescript
RPE 1-4: +20% (too easy)
RPE 5-6: +10% (a bit easy)
RPE 7-8: Perfect zone (maintain or +5%)
RPE 9: -5% (hard)
RPE 10: -10% (too hard)
```

**Progressive Overload:**
- Slow: +2.5%/week
- Moderate: +5%/week (default)
- Aggressive: +7.5%/week

**All weights rounded to 2.5kg** (practical gym loading)

---

## How It Works

### Example: Maria's First Workout

**Maria's Profile:**
- CrossFit background → Intermediate level
- No PRs entered (doesn't know yet)
- Female
- Week 1

**AI Prescribes:**
```typescript
Sled Push:
  Base: 70kg (intermediate female = 70 × 0.65 = 45.5kg)
  Week 1 conservative: 45.5 × 0.8 = 36.4kg
  Rounded: 35kg
  Confidence: 60%
  Notes: "Estimated for intermediate female | Week 1: Starting conservative"

Farmers Carry:
  Base: 24kg each (intermediate female = 24 × 0.65 = 15.6kg)
  Week 1: 15.6 × 0.8 = 12.5kg
  Rounded: 12.5kg each
  Confidence: 60%
```

**Maria completes workout, feedback:**
- Sled Push: RPE 4/10, "Too easy"
- Farmers Carry: RPE 7/10, "Perfect"

**AI Adjusts Week 2:**
```typescript
Sled Push:
  RPE ≤4 → +20%
  35kg × 1.2 = 42kg
  Rounded: 42.5kg
  Notes: "RPE too low - increasing 20%"

Farmers Carry:
  RPE 7-8 → maintain + small progression
  12.5kg × 1.05 = 13.1kg
  Rounded: 12.5kg (stays same, will increase Week 3)
```

---

## Next Steps

### Phase 2: API Endpoints (Week 2-3)

**Need to create:**
1. `POST /api/users/onboarding` - Save core onboarding
2. `POST /api/users/:id/benchmarks` - Save/update PRs
3. `POST /api/users/:id/equipment` - Save equipment access
4. `POST /api/users/:id/weaknesses` - Save weaknesses
5. `POST /api/workouts/:id/feedback` - Post-workout feedback
6. `GET /api/users/:id/profile` - Get complete profile for AI

### Phase 3: iOS Onboarding UI (Week 3-4)

**Build SwiftUI screens:**
1. Basic profile (age, gender, background)
2. Goal & race date
3. Training availability
4. Equipment quick select
5. Optional: Running PRs
6. Generate first week

### Phase 4: Refinement Flow (Week 4-5)

**Optional refinement after Week 1:**
1. Performance numbers
2. Weaknesses & focus
3. Training style
4. Strength ranking

### Phase 5: Feedback System (Week 5-6)

**Post-workout:**
1. RPE slider
2. Weights used (pre-filled from last time)
3. Quick issues
4. AI learns and adjusts

---

## File Structure

```
backend/
  src/
    migrations/
      supabase/
        008_enhanced_onboarding.sql ✅ NEW
    models/
      user.model.ts ✅ UPDATED
      onboarding.model.ts ✅ NEW
    services/
      ai/
        weight-prescription.ts ✅ NEW
```

---

## Database Schema Summary

```sql
-- 5 new/updated tables
users (extended with 12 new columns)
user_performance_benchmarks (16 PR fields)
user_equipment_access (18 equipment flags)
user_weaknesses (JSONB for flexibility)
workout_feedback (RPE + weights tracking)

-- 1 helper view
user_complete_profile (joins all data)

-- 1 smart function
apply_equipment_defaults() (auto-checks based on gym type)
```

---

## Key Features

✅ **Smart Defaults** - Check "CrossFit Gym", get all equipment auto-selected
✅ **PR-Based Weights** - Squat/DL PRs calculate sled, farmers, sandbag weights
✅ **Level-Based Estimates** - No PRs? Use fitness level + gender
✅ **Conservative Week 1** - Start 20% lighter, learn, adjust
✅ **Feedback Learning** - RPE drives automatic weight adjustments
✅ **Progressive Overload** - Weekly progression built-in
✅ **Backward Compatible** - All new fields optional, won't break existing data

---

## What Makes This Special

**Before (Old System):**
- Basic user profile
- Generic workouts
- No weight prescriptions
- No learning from feedback
- One-size-fits-all

**After (New System):**
- Complete athlete profile
- Personalized from Day 1
- Smart weight calculations
- Learns from every workout
- Truly adaptive training

**User Experience:**
```
Week 1: "Start conservative, we'll learn together"
  ↓
Post-Workout Feedback (30 sec)
  ↓
Week 2: "Based on your feedback, increasing sled push to 42.5kg"
  ↓
Week 4: "Want a better plan? 5 min refinement unlocks more personalization"
  ↓
Continuous Improvement (no more questions needed)
```

---

## Ready for Prime Time?

**What's Live:**
- ✅ Database schema
- ✅ TypeScript models
- ✅ Weight prescription logic

**What's Next:**
- 🔨 API endpoints
- 🔨 iOS onboarding UI
- 🔨 Refinement flow
- 🔨 Feedback system

---

**LET'S KEEP BUILDING!** 🚀

*Phase 1 Complete: December 2025*
*Status: Database Foundation Ready*
*Next: API Endpoints*
