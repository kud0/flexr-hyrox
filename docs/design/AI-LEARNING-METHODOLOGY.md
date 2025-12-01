# FLEXR AI Learning Methodology
## How the AI Builds and Updates Your Performance Profile

---

# THE CORE QUESTION

> **How does the AI learn your compromised running profile?**
> **How often does it update?**
> **What data does it need?**

This document defines the complete learning architecture.

---

# PART 1: THE LEARNING PROBLEM

## 1.1 What We're Trying to Learn

For each user, we need to build a **Personal Performance Model** that includes:

```
USER PERFORMANCE MODEL
│
├── RUNNING BASELINE
│   ├── Fresh pace (Zone 2, Tempo, Threshold, Race)
│   ├── HR at each pace zone
│   ├── Pace:HR relationship (running economy)
│   └── Fatigue patterns (how pace degrades over distance)
│
├── COMPROMISED RUNNING PROFILE
│   ├── Post-SkiErg degradation
│   ├── Post-Sled Push degradation
│   ├── Post-Sled Pull degradation
│   ├── Post-Burpees degradation
│   ├── Post-Rowing degradation
│   ├── Post-Farmers degradation
│   ├── Post-Lunges degradation
│   └── Post-Wall Balls degradation
│
├── STATION PERFORMANCE
│   ├── Expected time per station
│   ├── PR times
│   ├── Consistency (variance)
│   └── Fatigue impact (does it get worse through race?)
│
├── RECOVERY PROFILE
│   ├── HR recovery rate
│   ├── Pace recovery rate
│   ├── HRV baseline and sensitivity
│   └── Sleep impact on performance
│
└── TREND DATA
    ├── Fitness trajectory (improving/plateau/declining)
    ├── Rate of improvement
    └── Predicted future performance
```

---

## 1.2 The Challenge

### Why We Can't Just Average Everything

**Problem 1: Not Enough Data Initially**
- New user has zero data points
- Need 3-5+ samples per station type for statistical significance
- Can't wait weeks before giving useful targets

**Problem 2: Data is Noisy**
- Bad sleep = slower that day (not real fitness change)
- Hot weather = slower pace (not real fitness change)
- Different terrain = different pace
- Motivation varies day to day

**Problem 3: Fitness Changes Over Time**
- User improves with training
- Old data becomes less relevant
- But can't ignore all history

**Problem 4: Different Contexts**
- Fresh run in training ≠ Run 5 in a race simulation
- Post-SkiErg in isolation ≠ Post-SkiErg after 4 stations already done
- Need to account for cumulative fatigue

---

# PART 2: THE LEARNING ARCHITECTURE

## 2.1 Three-Tier Learning System

```
┌─────────────────────────────────────────────────────────────────┐
│                     AI LEARNING TIERS                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  TIER 1: REAL-TIME (During/After Each Session)                 │
│  ├── Capture all data points                                    │
│  ├── Flag anomalies (unusually good/bad)                       │
│  ├── Update running averages                                    │
│  └── NO profile changes (just data collection)                 │
│                                                                 │
│  TIER 2: WEEKLY RECALCULATION (Every Sunday)                   │
│  ├── Aggregate week's data                                      │
│  ├── Weight by recency and conditions                          │
│  ├── Update compromised running profile                        │
│  ├── Recalculate pace targets for next week                    │
│  └── Identify trends (improving/declining)                     │
│                                                                 │
│  TIER 3: MONTHLY DEEP ANALYSIS (1st of Month)                  │
│  ├── Full profile recalculation                                │
│  ├── Update confidence intervals                               │
│  ├── Recalculate fitness trajectory                            │
│  ├── Update race prediction model                              │
│  └── Generate monthly insights                                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2.2 Tier 1: Real-Time Data Capture

### What Happens After Every Session

```
SESSION COMPLETE
      │
      ▼
┌─────────────────────────────────────────┐
│  CAPTURE ALL RAW DATA                   │
│                                         │
│  Per Run Segment:                       │
│  • Distance, duration, pace             │
│  • HR: avg, max, start, end             │
│  • Previous station type                │
│  • Time since station ended             │
│  • Cumulative fatigue (station # in     │
│    workout)                             │
│  • Conditions: temp, humidity, terrain  │
│  • User state: sleep, HRV, readiness    │
│  • RPE reported                         │
│                                         │
│  Per Station Segment:                   │
│  • Station type                         │
│  • Completion time                      │
│  • HR: avg, max, at end                 │
│  • Position in workout                  │
│                                         │
└─────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────┐
│  NORMALIZE DATA                         │
│                                         │
│  • Adjust pace for elevation            │
│  • Adjust for temperature (hot = slow)  │
│  • Flag low-readiness sessions          │
│  • Flag incomplete segments             │
│                                         │
└─────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────┐
│  STORE IN RAW DATA TABLE                │
│                                         │
│  • No profile updates yet               │
│  • Just accumulate data points          │
│  • Mark for weekly processing           │
│                                         │
└─────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────┐
│  SHOW USER: SESSION ANALYSIS            │
│                                         │
│  • Compare to CURRENT profile           │
│  • "Your post-sled pace was 5:05,       │
│     your profile says 5:07 - good!"     │
│  • This uses existing profile,          │
│    doesn't update it yet                │
│                                         │
└─────────────────────────────────────────┘
```

### Why Not Update Profile Immediately?

1. **Single session is noisy** - One bad run doesn't mean fitness dropped
2. **Need context** - Was it hot? Poor sleep? End of hard week?
3. **Statistical stability** - Profile should be stable, not jumping around
4. **User trust** - Targets that change daily feel unreliable

---

## 2.3 Tier 2: Weekly Recalculation

### When: Every Sunday Night (or user's chosen "week end")

### What Happens

```
WEEKLY RECALCULATION
        │
        ▼
┌─────────────────────────────────────────┐
│  GATHER THIS WEEK'S DATA                │
│                                         │
│  • All run segments from this week      │
│  • All station segments from this week  │
│  • Readiness scores each day            │
│  • Sleep data each night                │
│  • Any anomaly flags                    │
│                                         │
└─────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────┐
│  FILTER & WEIGHT DATA                   │
│                                         │
│  Exclude:                               │
│  • Sessions with readiness < 50%        │
│  • Sessions flagged as "bad day"        │
│  • Incomplete segments                  │
│  • Extreme outliers (> 2 std dev)       │
│                                         │
│  Weight by:                             │
│  • Recency (this week = 1.0)            │
│  • Conditions quality (good = 1.0)      │
│  • Workout type (simulation = 1.2x)     │
│  • Completion (full workout = 1.1x)     │
│                                         │
└─────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────┐
│  CALCULATE WEEKLY METRICS               │
│                                         │
│  For each station type with new data:   │
│  • This week's avg compromised pace     │
│  • This week's avg degradation %        │
│  • Sample count this week               │
│  • Variance this week                   │
│                                         │
│  For running baseline:                  │
│  • This week's fresh pace (if any)      │
│  • This week's Zone 2 avg               │
│  • This week's threshold avg            │
│                                         │
└─────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────┐
│  BLEND WITH HISTORICAL PROFILE          │
│                                         │
│  Formula:                               │
│  new_value = (old_value × decay) +      │
│              (this_week × (1 - decay))  │
│                                         │
│  Decay factor: 0.7 (keep 70% of old,    │
│  blend 30% new)                         │
│                                         │
│  But adjust decay based on:             │
│  • Sample count (more data = trust new) │
│  • Variance (stable = trust new)        │
│  • User experience (new user = learn    │
│    faster, decay = 0.5)                 │
│                                         │
└─────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────┐
│  UPDATE PROFILE                         │
│                                         │
│  Compromised Running Profile:           │
│  • Update each station degradation      │
│  • Update confidence interval           │
│  • Mark last_updated timestamp          │
│                                         │
│  Running Baseline:                      │
│  • Update pace zones if changed         │
│  • Update HR zones if needed            │
│                                         │
│  Station Performance:                   │
│  • Update expected times                │
│  • Update PRs if achieved               │
│                                         │
└─────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────┐
│  GENERATE NEXT WEEK'S TARGETS           │
│                                         │
│  Based on updated profile:              │
│  • New pace targets per segment type    │
│  • New station time targets             │
│  • Adjusted difficulty for workouts     │
│                                         │
└─────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────┐
│  NOTIFY USER                            │
│                                         │
│  "Your profile has been updated:        │
│   - Post-sled pace improved 3 sec       │
│   - Post-burpee pace needs work (+2s)   │
│   - Overall degradation: 12% → 11%      │
│                                         │
│   Next week's targets adjusted."        │
│                                         │
└─────────────────────────────────────────┘
```

---

## 2.4 Tier 3: Monthly Deep Analysis

### When: 1st of Each Month

### What Happens

```
MONTHLY DEEP ANALYSIS
        │
        ▼
┌─────────────────────────────────────────┐
│  FULL DATA REVIEW (Last 90 days)        │
│                                         │
│  • All sessions in window               │
│  • Apply time-decay weighting           │
│  • Identify long-term trends            │
│                                         │
└─────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────┐
│  STATISTICAL ANALYSIS                   │
│                                         │
│  Per metric:                            │
│  • Mean                                 │
│  • Standard deviation                   │
│  • Confidence interval (95%)            │
│  • Trend line (improving/flat/declining)│
│  • Rate of change                       │
│                                         │
└─────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────┐
│  RECALCULATE FITNESS MODEL              │
│                                         │
│  • VO2max estimate                      │
│  • Threshold pace                       │
│  • Running economy curve                │
│  • Race prediction model                │
│                                         │
└─────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────┐
│  UPDATE CONFIDENCE LEVELS               │
│                                         │
│  Per station degradation:               │
│  • High confidence (10+ samples)        │
│  • Medium confidence (5-9 samples)      │
│  • Low confidence (< 5 samples)         │
│  • Uncertain (< 3 samples)              │
│                                         │
│  Show user confidence in predictions    │
│                                         │
└─────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────┐
│  GENERATE MONTHLY REPORT                │
│                                         │
│  • All metrics: start of month vs now   │
│  • Biggest improvements                 │
│  • Areas still needing work             │
│  • Race prediction change               │
│  • Recommended focus for next month     │
│                                         │
└─────────────────────────────────────────┘
```

---

# PART 3: THE MATH

## 3.1 Calculating Compromised Running Degradation

### For Each Station Type

```python
# Simplified algorithm

def calculate_degradation(user_id, station_type, time_window_days=90):

    # Get all run segments that followed this station type
    compromised_runs = get_runs_after_station(
        user_id,
        station_type,
        days=time_window_days
    )

    # Get user's current fresh pace baseline
    fresh_pace = get_fresh_pace_baseline(user_id)

    # Calculate degradation for each run
    degradations = []
    for run in compromised_runs:

        # Skip if data quality is poor
        if run.readiness_score < 50:
            continue
        if run.flagged_as_outlier:
            continue

        # Calculate degradation
        degradation_sec = run.pace - fresh_pace  # seconds/km
        degradation_pct = (degradation_sec / fresh_pace) * 100

        # Apply time decay weight (recent = more important)
        days_ago = (today - run.date).days
        recency_weight = 0.95 ** days_ago  # Exponential decay

        # Apply context weight
        context_weight = 1.0
        if run.workout_type == 'SIMULATION':
            context_weight = 1.2  # Race-like conditions more relevant
        if run.cumulative_stations > 4:
            context_weight *= 1.1  # Deep fatigue more relevant

        total_weight = recency_weight * context_weight

        degradations.append({
            'value': degradation_sec,
            'weight': total_weight
        })

    # Weighted average
    if len(degradations) < 3:
        return None  # Not enough data

    total_weight = sum(d['weight'] for d in degradations)
    weighted_avg = sum(d['value'] * d['weight'] for d in degradations) / total_weight

    # Calculate confidence
    sample_count = len(degradations)
    variance = calculate_variance(degradations)
    confidence = calculate_confidence(sample_count, variance)

    return {
        'degradation_sec': weighted_avg,
        'degradation_pct': (weighted_avg / fresh_pace) * 100,
        'confidence': confidence,
        'sample_count': sample_count,
        'last_updated': today
    }
```

---

## 3.2 Weekly Profile Update Formula

```python
def weekly_update(current_profile, this_week_data, user_experience_level):

    # Determine decay factor based on user experience
    if user_experience_level == 'NEW':  # < 4 weeks of data
        decay = 0.5  # Learn fast, trust new data more
    elif user_experience_level == 'DEVELOPING':  # 4-12 weeks
        decay = 0.65
    else:  # ESTABLISHED: > 12 weeks
        decay = 0.75  # Stable profile, change slowly

    # Adjust decay based on this week's data quality
    if this_week_data.sample_count >= 5:
        decay -= 0.1  # More data = trust it more
    if this_week_data.variance < current_profile.variance:
        decay -= 0.05  # More consistent = trust it more

    # Blend old and new
    new_value = (current_profile.value * decay) + \
                (this_week_data.value * (1 - decay))

    return new_value
```

---

## 3.3 New User Cold Start

### Problem: New user has no data

### Solution: Population-Based Starting Profile

```python
def initialize_profile(user):

    # Get user's background
    fitness_level = user.onboarding.fitness_level  # beginner/intermediate/advanced
    background = user.onboarding.background  # runner/crossfit/gym/new

    # Start with population averages based on segment
    base_profile = get_population_profile(fitness_level, background)

    # Example population profiles:
    #
    # INTERMEDIATE + RUNNER background:
    # Fresh pace: ~5:00/km
    # Post-SkiErg: +10 sec (runners handle SkiErg okay)
    # Post-Sled: +30 sec (runners struggle with legs)
    # Post-Burpees: +25 sec
    # Post-Row: +8 sec (similar to running)
    # etc.
    #
    # INTERMEDIATE + CROSSFIT background:
    # Fresh pace: ~5:30/km (usually slower runners)
    # Post-SkiErg: +8 sec (good at SkiErg)
    # Post-Sled: +15 sec (strong legs)
    # Post-Burpees: +12 sec (used to burpees)
    # Post-Row: +10 sec
    # etc.

    # Mark as LOW CONFIDENCE
    for station in base_profile.stations:
        station.confidence = 'LOW'
        station.sample_count = 0
        station.source = 'POPULATION_ESTIMATE'

    # Tell user
    user.notify(
        "Your targets are based on athletes like you. "
        "They'll become personalized after a few workouts."
    )

    return base_profile
```

### Rapid Learning Phase (First 4 Weeks)

```
Week 1:
  - Using population estimates
  - Every session updates profile aggressively (decay = 0.3)
  - Targets may shift significantly

Week 2:
  - Blend of population + actual data
  - Profile stabilizing
  - Decay = 0.4

Week 3-4:
  - Mostly personal data now
  - Decay = 0.5
  - Confidence increasing

Week 5+:
  - Fully personalized
  - Normal decay = 0.7
  - High confidence (if enough variety in workouts)
```

---

## 3.4 Handling Different Contexts

### Cumulative Fatigue Adjustment

Not all "post-SkiErg" runs are equal:

```python
def adjust_for_cumulative_fatigue(run, workout_context):

    # How many stations before this run?
    stations_completed = workout_context.stations_before_this_run

    # Cumulative fatigue factor
    # Run after station 1 = 1.0x degradation
    # Run after station 4 = 1.3x degradation (more tired)
    # Run after station 7 = 1.5x degradation

    fatigue_multiplier = 1.0 + (stations_completed - 1) * 0.1

    # When comparing to profile, normalize:
    # If profile was built on early-workout runs,
    # adjust expectations for late-workout runs

    return run.degradation / fatigue_multiplier
```

### Example:

```
Profile says: Post-Sled degradation = +25 sec

In a workout:
- Run after Sled (station 2): Expect +25 sec
- Run after Sled (station 6): Expect +25 × 1.4 = +35 sec

AI adjusts targets accordingly.
```

---

## 3.5 Handling Conditions

### Temperature Adjustment

```python
def adjust_for_temperature(pace, temperature_c):

    # Running is slower in heat
    # Baseline: 15°C (optimal)
    # Every 5°C above = ~2% slower

    if temperature_c <= 15:
        return pace  # No adjustment

    degrees_above = temperature_c - 15
    adjustment_pct = (degrees_above / 5) * 0.02

    adjusted_pace = pace / (1 + adjustment_pct)

    return adjusted_pace

# Example:
# Ran 5:20/km at 25°C
# Adjusted = 5:20 / 1.04 = 5:08/km equivalent
# Use 5:08 for profile building, not 5:20
```

### Elevation Adjustment

```python
def adjust_for_elevation(pace, elevation_gain_per_km):

    # Rule of thumb: +1 sec per meter of climb
    adjustment_sec = elevation_gain_per_km * 1

    adjusted_pace = pace - adjustment_sec

    return adjusted_pace
```

---

# PART 4: CONFIDENCE & UNCERTAINTY

## 4.1 Confidence Levels

```
┌─────────────────────────────────────────────────────────────────┐
│  CONFIDENCE LEVELS FOR EACH METRIC                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  HIGH CONFIDENCE                                                │
│  • 10+ quality samples                                          │
│  • Low variance (consistent results)                            │
│  • Recent data (within 30 days)                                 │
│  • Show: "Post-SkiErg: +15 sec"                                │
│                                                                 │
│  MEDIUM CONFIDENCE                                              │
│  • 5-9 quality samples                                          │
│  • Moderate variance                                            │
│  • Show: "Post-SkiErg: +15 sec (±5 sec)"                       │
│                                                                 │
│  LOW CONFIDENCE                                                 │
│  • 3-4 quality samples                                          │
│  • Higher variance or old data                                  │
│  • Show: "Post-SkiErg: ~15 sec (limited data)"                 │
│                                                                 │
│  UNCERTAIN / ESTIMATED                                          │
│  • < 3 samples                                                  │
│  • Using population estimate                                    │
│  • Show: "Post-SkiErg: ~15 sec (estimated)"                    │
│  • Encourage user to do more of this type                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 4.2 Showing Uncertainty to User

### In Targets

```
┌─────────────────────────────────────────┐
│  TODAY'S RUN TARGETS                    │
├─────────────────────────────────────────┤
│                                         │
│  Run 1 (Fresh):                         │
│  4:35-4:45/km                          │
│  Confidence: ●●●●● High                │
│                                         │
│  Run 2 (Post-SkiErg):                  │
│  4:48-4:58/km                          │
│  Confidence: ●●●●○ Good                │
│                                         │
│  Run 3 (Post-Sled):                    │
│  5:00-5:15/km                          │
│  Confidence: ●●●○○ Medium              │
│  (Only 4 samples - keep training this!) │
│                                         │
│  Run 4 (Post-Burpees):                 │
│  5:05-5:25/km                          │
│  Confidence: ●●○○○ Low                 │
│  (Based on estimate - need more data)  │
│                                         │
└─────────────────────────────────────────┘
```

### In Race Predictions

```
┌─────────────────────────────────────────┐
│  RACE PREDICTION                        │
├─────────────────────────────────────────┤
│                                         │
│  Predicted Time: 1:12:30               │
│                                         │
│  Confidence Range:                      │
│  ├── Best case:  1:09:45              │
│  ├── Expected:   1:12:30              │
│  └── Worst case: 1:15:15              │
│                                         │
│  Why the range?                         │
│  • Post-sled data: Medium confidence   │
│  • Post-burpee data: Low confidence    │
│  • Station times: High confidence      │
│                                         │
│  Do more compromised drills to         │
│  narrow this prediction.               │
│                                         │
└─────────────────────────────────────────┘
```

---

# PART 5: SPECIAL EVENTS

## 5.1 After a Real HYROX Race

```
RACE RESULT INTEGRATION
        │
        ▼
┌─────────────────────────────────────────┐
│  USER UPLOADS RACE RESULT               │
│                                         │
│  • Official time: 1:14:22              │
│  • Split times (if available)           │
│  • Conditions noted                     │
│                                         │
└─────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────┐
│  MAJOR PROFILE RECALIBRATION            │
│                                         │
│  Race data is GOLD - real conditions:   │
│  • Weight race data 3x normal           │
│  • Update all predictions               │
│  • Recalibrate expectations             │
│                                         │
│  If race was significantly different    │
│  from prediction:                       │
│  • Analyze why (pacing? station issue?) │
│  • Adjust model accordingly             │
│                                         │
└─────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────┐
│  POST-RACE ANALYSIS                     │
│                                         │
│  "Your race was 2:08 slower than        │
│   predicted. Analysis:                  │
│                                         │
│   - Runs were 1:30 slower than expected │
│   - Sled push was 45 sec slower         │
│   - Wall balls on target                │
│                                         │
│   It looks like race-day nerves         │
│   affected your pacing. Your post-sled  │
│   running was significantly worse than  │
│   training (-38 sec vs usual -25 sec).  │
│                                         │
│   Suggestion: More race simulations     │
│   to practice pacing under pressure."   │
│                                         │
└─────────────────────────────────────────┘
```

## 5.2 After Time Off (Detraining)

```
USER RETURNS AFTER 2+ WEEKS OFF
        │
        ▼
┌─────────────────────────────────────────┐
│  DETRAINING ADJUSTMENT                  │
│                                         │
│  Fitness declines ~3% per week off      │
│                                         │
│  If user was off 3 weeks:               │
│  • Expect ~9% slower paces              │
│  • Adjust all targets temporarily       │
│  • Enter "rebuild" mode                 │
│                                         │
└─────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────┐
│  ACCELERATED RELEARNING                 │
│                                         │
│  First 2 weeks back:                    │
│  • Use faster decay (0.4) to relearn    │
│  • Don't trust old profile fully        │
│  • Quickly establish new baseline       │
│                                         │
└─────────────────────────────────────────┘
```

## 5.3 Significant Fitness Jump

```
USER SUDDENLY MUCH FASTER
        │
        ▼
┌─────────────────────────────────────────┐
│  BREAKTHROUGH DETECTION                 │
│                                         │
│  If this week's data is >1 std dev      │
│  better than profile:                   │
│                                         │
│  Option A: Outlier (ignore)             │
│  - Check: bad conditions last time?     │
│  - Check: exceptional conditions now?   │
│                                         │
│  Option B: Real breakthrough            │
│  - Multiple sessions confirm it         │
│  - Update profile more aggressively     │
│  - Notify user of improvement           │
│                                         │
└─────────────────────────────────────────┘
```

---

# PART 6: DATA REQUIREMENTS

## 6.1 Minimum Data for Reliable Profile

```
┌─────────────────────────────────────────────────────────────────┐
│  MINIMUM DATA REQUIREMENTS                                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  FOR BASIC PROFILE (Low confidence):                           │
│  • 3+ fresh runs                                                │
│  • 2+ runs per station type                                     │
│  • 2+ weeks of training                                         │
│                                                                 │
│  FOR GOOD PROFILE (Medium confidence):                          │
│  • 8+ fresh runs                                                │
│  • 4+ runs per station type                                     │
│  • 1+ full or half simulation                                   │
│  • 4-6 weeks of training                                        │
│                                                                 │
│  FOR EXCELLENT PROFILE (High confidence):                       │
│  • 15+ fresh runs                                               │
│  • 8+ runs per station type                                     │
│  • 3+ simulations                                               │
│  • 8+ weeks of training                                         │
│  • Variety of conditions                                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 6.2 Profile Staleness

```
DATA FRESHNESS RULES:

• Data > 90 days old: Weighted at 50%
• Data > 60 days old: Weighted at 75%
• Data > 30 days old: Weighted at 90%
• Data < 30 days old: Weighted at 100%

IF no data for a station type in 30 days:
• Mark as "stale"
• Suggest including it in upcoming workouts
• Widen confidence interval

IF no data for a station type in 60 days:
• Revert to blended population estimate
• Mark as "needs revalidation"
```

---

# PART 7: USER-FACING COMMUNICATION

## 7.1 Weekly Update Notification

```
┌─────────────────────────────────────────┐
│  WEEKLY PROFILE UPDATE                  │
│  Sunday, Jan 7                          │
├─────────────────────────────────────────┤
│                                         │
│  Your profile has been updated based    │
│  on this week's training.               │
│                                         │
│  CHANGES:                               │
│                                         │
│  Post-Sled Running:                     │
│  +32 sec → +28 sec                      │
│  ▼ 4 sec improvement 🎉                 │
│                                         │
│  Post-Burpee Running:                   │
│  +38 sec → +40 sec                      │
│  ▲ 2 sec decline ⚠️                     │
│  (Only 1 sample this week - may be noise)│
│                                         │
│  Fresh Pace:                            │
│  4:38/km → 4:35/km                      │
│  ▼ 3 sec faster 🎉                      │
│                                         │
│  NEXT WEEK'S TARGETS ADJUSTED           │
│  Your workouts will use these new       │
│  numbers for pacing guidance.           │
│                                         │
│  [View Full Profile]                    │
│                                         │
└─────────────────────────────────────────┘
```

## 7.2 Data Quality Prompts

```
┌─────────────────────────────────────────┐
│  💡 PROFILE TIP                         │
├─────────────────────────────────────────┤
│                                         │
│  Your post-burpee running profile has   │
│  low confidence (only 2 samples).       │
│                                         │
│  This week includes a compromised       │
│  running drill with burpees to help     │
│  build more accurate targets.           │
│                                         │
│  [Got it]                               │
│                                         │
└─────────────────────────────────────────┘
```

## 7.3 Showing the Learning

```
┌─────────────────────────────────────────┐
│  YOUR AI PROFILE                        │
├─────────────────────────────────────────┤
│                                         │
│  COMPROMISED RUNNING                    │
│                                         │
│  Station          Degradation  Confidence│
│  ───────────────────────────────────────│
│  Post-SkiErg      +15 sec     ●●●●●    │
│  Post-Sled Push   +28 sec     ●●●●○    │
│  Post-Sled Pull   +20 sec     ●●●○○    │
│  Post-Burpees     +40 sec     ●●○○○    │
│  Post-Rowing      +12 sec     ●●●●●    │
│  Post-Farmers     +22 sec     ●●●○○    │
│  Post-Lunges      +35 sec     ●●●●○    │
│  Post-Wall Balls  +25 sec     ●●●●○    │
│                                         │
│  Overall: 8.5% avg degradation          │
│                                         │
│  ───────────────────────────────────────│
│                                         │
│  HOW THIS WAS LEARNED                   │
│                                         │
│  Total run segments analyzed: 47        │
│  Date range: Nov 15 - Jan 7             │
│  Simulations included: 4                │
│                                         │
│  Last updated: Today (weekly update)    │
│  Next update: Jan 14                    │
│                                         │
│  [View Learning History]                │
│                                         │
└─────────────────────────────────────────┘
```

---

# SUMMARY

## Learning Cycles

| Cycle | Frequency | What Happens |
|-------|-----------|--------------|
| **Real-Time** | Every session | Capture data, show vs current profile |
| **Weekly** | Every Sunday | Update profile, adjust targets |
| **Monthly** | 1st of month | Deep analysis, confidence recalc, trends |

## Key Principles

1. **Don't update on single sessions** - Too noisy
2. **Weight recent data more** - Fitness changes
3. **Account for context** - Conditions, fatigue, readiness
4. **Show confidence** - User knows what's reliable
5. **Learn fast for new users** - Quick personalization
6. **Stabilize for experienced users** - Consistent targets
7. **Explain changes** - User understands their profile

## Data Requirements

| Confidence | Samples Needed | Timeline |
|------------|---------------|----------|
| Estimated | 0 | Day 1 |
| Low | 3+ per type | ~2 weeks |
| Medium | 5+ per type | ~4-6 weeks |
| High | 10+ per type | ~8+ weeks |

## The Result

User gets a profile that:
- Starts useful immediately (population estimates)
- Becomes personalized quickly (2-4 weeks)
- Stays stable but responsive (weekly updates)
- Shows clear improvement over time (monthly trends)
- Explains itself (confidence, learning history)

---

*Document Version: 1.0*
*Created: December 2025*
*Status: AI Architecture - Ready for Development*
