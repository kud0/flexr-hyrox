# Run/Station Segmentation System
## Isolating Running Data from Station Work in HYROX Training

---

# THE PROBLEM

In HYROX and hybrid training, athletes alternate between running and station work. Current fitness apps fail because they:

1. **Blend all data together** - Average pace includes walking to stations
2. **Can't track "compromised running"** - The crucial skill of running on tired legs
3. **Don't understand HYROX patterns** - Run → Station → Run → Station
4. **Miss the key metric** - How much does your pace degrade after each station?

**FLEXR must solve this.**

---

# THE SOLUTION: SEGMENT-BASED TRACKING

## Core Concept

Every workout is divided into **segments**. Each segment is tagged with a type:

```
SEGMENT TYPES:
├── RUN (pure running)
│   ├── Fresh Run (first run, or after long rest)
│   ├── Compromised Run (after station work)
│   └── Recovery Run (intentionally easy)
│
├── STATION
│   ├── SkiErg
│   ├── Sled Push
│   ├── Sled Pull
│   ├── Burpee Broad Jumps
│   ├── Rowing
│   ├── Farmers Carry
│   ├── Sandbag Lunges
│   └── Wall Balls
│
├── TRANSITION (moving between stations, not tracked as performance)
│
└── REST (intentional rest periods)
```

---

# PART 1: APPLE WATCH SEGMENT INTERFACE

## 1.1 Segment Switching on Watch

### Method 1: Quick Tap Switch (Primary)

```
┌───────────────────────┐
│  HYROX DRILL          │
│  Segment 3: RUN       │
├───────────────────────┤
│                       │
│      4:42/km          │
│      156 bpm          │
│                       │
├───────────────────────┤
│  Distance: 0.8 km     │
│  Time: 3:45           │
├───────────────────────┤
│                       │
│  [TAP TO SWITCH]      │
│  → Next: WALL BALLS   │
│                       │
└───────────────────────┘

        ↓ TAP ↓

┌───────────────────────┐
│  HYROX DRILL          │
│  Segment 4: STATION   │
├───────────────────────┤
│                       │
│    WALL BALLS         │
│      0:00             │
│                       │
├───────────────────────┤
│  Target: 100 reps     │
│  HR: 162 bpm          │
├───────────────────────┤
│                       │
│  [TAP WHEN DONE]      │
│                       │
└───────────────────────┘
```

### Method 2: Crown Scroll Selection

For non-linear workouts where user picks the next segment:

```
┌───────────────────────┐
│  SELECT NEXT          │
│                       │
├───────────────────────┤
│                       │
│  ▲ Scroll Crown       │
│                       │
│  ○ RUN                │
│  ● SKIERG      ←      │
│  ○ SLED PUSH          │
│  ○ ROWING             │
│  ○ WALL BALLS         │
│                       │
│  ▼                    │
│                       │
├───────────────────────┤
│  [SELECT]             │
└───────────────────────┘
```

### Method 3: Voice Command (Hands-Free)

During workout, raise wrist and say:
- "Start run"
- "Start wall balls"
- "Done" (ends current segment)
- "Rest"

### Method 4: Auto-Detection (AI-Assisted)

For trained users, AI can detect transitions:
- GPS movement + pace = Running
- Stationary + high HR variability = Station work
- Stationary + dropping HR = Rest

**But always allow manual override.**

---

## 1.2 Watch Faces by Segment Type

### Running Segment Face

```
┌───────────────────────┐
│  RUN • Compromised    │
│  After: Wall Balls    │
├───────────────────────┤
│                       │
│      4:52/km          │
│    (Target: 4:45)     │
│                       │
├───────────────────────┤
│  ❤️ 168   🏃 0.6km    │
│  Zone 4   ⏱️ 2:55     │
├───────────────────────┤
│  [TAP → STATION]      │
└───────────────────────┘

HAPTIC ALERTS:
- Pace too fast after station: 🔴 Buzz
- Pace recovering well: 🟢 Double-tap
- Approaching target distance: ⏰ Tap
```

### Station Segment Face

```
┌───────────────────────┐
│  STATION              │
│  Wall Balls           │
├───────────────────────┤
│                       │
│       2:15            │
│    (Best: 2:02)       │
│                       │
├───────────────────────┤
│  ❤️ 172 bpm           │
│  Peak: 178 bpm        │
├───────────────────────┤
│  [TAP WHEN DONE]      │
└───────────────────────┘
```

### Transition Segment Face

```
┌───────────────────────┐
│  TRANSITION           │
│  → Next: Sled Push    │
├───────────────────────┤
│                       │
│       0:45            │
│    Moving...          │
│                       │
├───────────────────────┤
│  ❤️ 155 bpm           │
│  (Recovering)         │
├───────────────────────┤
│  [START SLED PUSH]    │
└───────────────────────┘
```

---

## 1.3 Workout Flow Example: HYROX Simulation

```
FULL HYROX SIMULATION FLOW:

Start Workout
    ↓
[Segment 1: RUN] ← Fresh run, baseline pace
    │ 1km @ 4:35/km
    ↓ TAP
[Segment 2: STATION - SkiErg]
    │ 1000m @ 4:12
    ↓ TAP
[Segment 3: RUN] ← Compromised (post-SkiErg)
    │ 1km @ 4:48/km (+13 sec degradation)
    ↓ TAP
[Segment 4: STATION - Sled Push]
    │ 50m @ 2:35
    ↓ TAP
[Segment 5: RUN] ← Compromised (post-Sled)
    │ 1km @ 5:02/km (+27 sec degradation)
    ↓ TAP
... continues for all 16 segments ...
    ↓
[End Workout]
```

---

# PART 2: DATA MODEL

## 2.1 Segment Data Structure

```typescript
interface WorkoutSegment {
  id: string;
  type: 'RUN' | 'STATION' | 'TRANSITION' | 'REST';
  subtype?: RunSubtype | StationType;

  // Timing
  startTime: Date;
  endTime: Date;
  duration: number; // seconds

  // For RUN segments
  runData?: {
    distance: number; // meters
    avgPace: number; // seconds per km
    splits: PaceSplit[]; // per 100m or 200m
    avgHeartRate: number;
    maxHeartRate: number;
    heartRateZones: ZoneTime[];
    cadence?: number;
    elevationGain?: number;

    // CRITICAL: Context flags
    isFreshRun: boolean;
    isCompromisedRun: boolean;
    previousStation?: StationType; // What station preceded this run
    restBeforeRun?: number; // Seconds of rest before starting
  };

  // For STATION segments
  stationData?: {
    stationType: StationType;
    completionTime: number; // seconds
    reps?: number; // For wall balls, burpees
    distance?: number; // For SkiErg, row, carries
    weight?: number; // kg
    avgHeartRate: number;
    maxHeartRate: number;
    peakHeartRate: number; // Highest point
    heartRateAtEnd: number; // For recovery analysis
  };

  // For TRANSITION segments
  transitionData?: {
    fromStation?: StationType;
    toStation?: StationType;
    distance?: number;
    avgHeartRate: number; // Recovery tracking
  };
}

type RunSubtype = 'FRESH' | 'COMPROMISED' | 'RECOVERY' | 'INTERVAL';

type StationType =
  | 'SKIERG'
  | 'SLED_PUSH'
  | 'SLED_PULL'
  | 'BURPEE_BROAD_JUMP'
  | 'ROWING'
  | 'FARMERS_CARRY'
  | 'SANDBAG_LUNGES'
  | 'WALL_BALLS'
  | 'OTHER';
```

## 2.2 Workout Summary Structure

```typescript
interface HYROXWorkoutSummary {
  // Overall
  totalDuration: number;
  totalDistance: number;
  avgHeartRate: number;
  calories: number;

  // ISOLATED RUNNING METRICS (THE KEY!)
  runningMetrics: {
    totalRunDistance: number;
    totalRunTime: number;

    // Fresh vs Compromised comparison
    freshRunPace: number; // Average of fresh runs
    compromisedRunPace: number; // Average of post-station runs
    paceDegradation: number; // Difference in seconds/km
    paceDegradationPercent: number; // % slower when compromised

    // Per-run breakdown
    runs: {
      segmentNumber: number;
      distance: number;
      pace: number;
      isFresh: boolean;
      previousStation?: StationType;
      paceVsFresh: number; // +/- seconds compared to fresh
    }[];

    // Trends
    paceByRunNumber: number[]; // How pace degrades over workout
    worstRunAfterStation: StationType; // Which station hurts running most
    bestRecoveryAfterStation: StationType; // Which station you recover from fastest
  };

  // ISOLATED STATION METRICS
  stationMetrics: {
    totalStationTime: number;

    stations: {
      type: StationType;
      time: number;
      reps?: number;
      avgHeartRate: number;
      peakHeartRate: number;
      percentOfTotal: number; // What % of workout was this station
    }[];

    // Comparisons to benchmarks
    stationVsBenchmark: {
      type: StationType;
      time: number;
      benchmarkTime: number;
      difference: number; // +/- seconds
      percentDiff: number;
    }[];
  };

  // Transition analysis
  transitionMetrics: {
    totalTransitionTime: number;
    avgTransitionTime: number;
    transitionsByStation: {
      toStation: StationType;
      avgTime: number;
    }[];
  };
}
```

---

# PART 3: AI LEARNING FROM SEGMENTED DATA

## 3.1 What AI Learns from Run Segments

```
PER-USER RUNNING PROFILE:

Fresh Running Baseline:
├── Zone 2 pace: 5:15/km
├── Threshold pace: 4:40/km
├── Race pace: 4:45/km
└── Max sustainable pace: 4:20/km

Compromised Running Profile:
├── Post-SkiErg pace: +8 sec/km (4:53/km)
├── Post-Sled Push pace: +22 sec/km (5:07/km)
├── Post-Sled Pull pace: +15 sec/km (5:00/km)
├── Post-Burpees pace: +18 sec/km (5:03/km)
├── Post-Rowing pace: +10 sec/km (4:55/km)
├── Post-Farmers pace: +12 sec/km (4:57/km)
├── Post-Lunges pace: +25 sec/km (5:10/km)
└── Post-Wall Balls pace: +20 sec/km (5:05/km)

Recovery Profile:
├── Time to recover to threshold: 2.5 min
├── HR recovery rate: 15 bpm/min
└── Pace recovery pattern: Exponential (fast initial, slow final)
```

## 3.2 AI Uses This Data To:

### 1. Predict Race Performance

```
RACE PREDICTION MODEL:

Based on your segmented data:

Fresh 1km: 4:35 (warm-up benefit)
Post-SkiErg: 4:48 (+13s)
Post-Sled Push: 5:02 (+27s)
Post-Sled Pull: 4:58 (+23s)
Post-Burpees: 5:05 (+30s)
Post-Rowing: 4:50 (+15s)
Post-Farmers: 4:55 (+20s)
Post-Lunges: 5:08 (+33s)
Post-Wall Balls: 5:02 (+27s)

Total run time: 39:23
Station time (from benchmarks): 32:45
Transitions: ~3:00

PREDICTED FINISH: 1:15:08 ± 2 minutes
```

### 2. Generate Targeted Training

```
WEAKNESS IDENTIFICATION:

Your biggest pace degradation is after:
1. Lunges (+33 sec) ← PRIORITY
2. Burpees (+30 sec)
3. Sled Push (+27 sec)

AI RESPONSE:
"This week I'm adding:
- Extra lunge capacity work (Thursday)
- Compromised running drills post-lunges (Saturday)
- Hip flexor mobility (daily)

Your leg endurance is the limiter. Let's fix it."
```

### 3. Set Realistic Pace Targets

```
TODAY'S HYBRID WORKOUT:

Run 1 (Fresh): Target 4:40-4:50/km
→ Wall Balls (50 reps)
Run 2 (Compromised): Target 5:00-5:10/km ← ADJUSTED
→ Rowing (500m)
Run 3 (Compromised): Target 4:55-5:05/km
→ Sled Push (25m)
Run 4 (Compromised): Target 5:10-5:20/km ← YOUR HARDEST COMBO

AI knows your post-sled running is weak.
Targets are personalized to YOUR data.
```

---

# PART 4: USER INTERFACE FOR VIEWING SEGMENTED DATA

## 4.1 Post-Workout Summary

### Screen: Workout Complete - Segmented View

```
┌─────────────────────────────────────────┐
│  HYROX DRILL COMPLETE                   │
│  Total: 52:15                           │
├─────────────────────────────────────────┤
│                                         │
│  SEGMENT BREAKDOWN                      │
│                                         │
│  ┌─────────────────────────────────────┐│
│  │ 1. 🏃 RUN (Fresh)         4:35/km  ││
│  │    1.0 km • 4:35 • HR 158          ││
│  ├─────────────────────────────────────┤│
│  │ 2. 🎿 SkiErg              4:12     ││
│  │    1000m • HR peak 172             ││
│  ├─────────────────────────────────────┤│
│  │ 3. 🏃 RUN (Compromised)   4:52/km  ││
│  │    1.0 km • 4:52 • HR 165          ││
│  │    ⚠️ +17 sec vs fresh              ││
│  ├─────────────────────────────────────┤│
│  │ 4. 🛷 Sled Push           2:28     ││
│  │    50m • HR peak 178               ││
│  ├─────────────────────────────────────┤│
│  │ 5. 🏃 RUN (Compromised)   5:08/km  ││
│  │    1.0 km • 5:08 • HR 170          ││
│  │    ⚠️ +33 sec vs fresh              ││
│  └─────────────────────────────────────┘│
│                                         │
│  [See Full Analysis]                    │
│                                         │
└─────────────────────────────────────────┘
```

### Screen: Running Analysis (Isolated)

```
┌─────────────────────────────────────────┐
│  ← Back              RUNNING ANALYSIS   │
├─────────────────────────────────────────┤
│                                         │
│  RUNNING ONLY (stations excluded)       │
│                                         │
│  Total Run Distance: 4.0 km             │
│  Total Run Time: 19:27                  │
│  Average Pace: 4:52/km                  │
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  FRESH vs COMPROMISED               ││
│  │                                     ││
│  │  Fresh Pace:       4:35/km          ││
│  │  Compromised Avg:  5:00/km          ││
│  │  Degradation:      +25 sec (9%)     ││
│  │                                     ││
│  │  ████████████████░░░░ Good!         ││
│  │  (Elite: <10%, You: 9%)             ││
│  └─────────────────────────────────────┘│
│                                         │
│  PACE BY RUN                            │
│  ┌─────────────────────────────────────┐│
│  │                                     ││
│  │  Run 1 (Fresh)    ████████ 4:35    ││
│  │  Run 2 (SkiErg)   █████████ 4:52   ││
│  │  Run 3 (Sled)     ██████████ 5:08  ││
│  │  Run 4 (Row)      █████████ 4:55   ││
│  │                                     ││
│  └─────────────────────────────────────┘│
│                                         │
│  WORST RECOVERY AFTER: Sled Push       │
│  BEST RECOVERY AFTER: Rowing           │
│                                         │
└─────────────────────────────────────────┘
```

### Screen: Station Analysis (Isolated)

```
┌─────────────────────────────────────────┐
│  ← Back              STATION ANALYSIS   │
├─────────────────────────────────────────┤
│                                         │
│  STATIONS ONLY (running excluded)       │
│                                         │
│  Total Station Time: 12:45              │
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  STATION        TIME    vs BEST    ││
│  │                                     ││
│  │  🎿 SkiErg      4:12    +0:08      ││
│  │  🛷 Sled Push   2:28    +0:15      ││
│  │  🚣 Rowing      1:52    -0:03 PR!  ││
│  │  🎯 Wall Balls  4:13    +0:22      ││
│  └─────────────────────────────────────┘│
│                                         │
│  TIME DISTRIBUTION                      │
│  ┌─────────────────────────────────────┐│
│  │  SkiErg    ████████████ 33%        ││
│  │  Wall Balls████████████ 33%        ││
│  │  Sled Push █████░░░░░░░ 19%        ││
│  │  Rowing    ████░░░░░░░░ 15%        ││
│  └─────────────────────────────────────┘│
│                                         │
│  💡 Wall balls taking same time as      │
│     SkiErg - focus area identified.     │
│                                         │
└─────────────────────────────────────────┘
```

---

## 4.2 Progress Over Time

### Screen: Running Progression

```
┌─────────────────────────────────────────┐
│  ← Back           RUNNING PROGRESS      │
├─────────────────────────────────────────┤
│                                         │
│  COMPROMISED RUNNING TREND              │
│  (Last 8 weeks)                         │
│                                         │
│  ┌─────────────────────────────────────┐│
│  │                                     ││
│  │  Degradation %                      ││
│  │  15%│    ╭──╮                       ││
│  │     │   ╭╯  ╰──╮                    ││
│  │  10%│──╯       ╰──╮                 ││
│  │     │             ╰──╮    ╭╮        ││
│  │   5%│                ╰────╯╰──      ││
│  │     └─────────────────────────      ││
│  │     W1  W2  W3  W4  W5  W6  W7  W8  ││
│  │                                     ││
│  └─────────────────────────────────────┘│
│                                         │
│  You started at 14% degradation.        │
│  Now at 8%. Improving!                  │
│                                         │
│  POST-STATION IMPROVEMENT               │
│  ┌─────────────────────────────────────┐│
│  │  Post-Sled:  +33s → +22s  ▼ 33%    ││
│  │  Post-Lunges: +28s → +18s  ▼ 36%   ││
│  │  Post-Burpees: +25s → +20s ▼ 20%   ││
│  └─────────────────────────────────────┘│
│                                         │
└─────────────────────────────────────────┘
```

---

# PART 5: WORKOUT TYPES USING SEGMENTATION

## 5.1 Workout Modes

### Mode 1: HYROX Simulation (Full/Half)

```
FULL SIM: 8 runs + 8 stations
HALF SIM: 4 runs + 4 stations

Segments are pre-defined:
Run → SkiErg → Run → Sled Push → Run → ...

User just taps to switch.
All data isolated and compared.
```

### Mode 2: HYROX Drill (Flexible)

```
User picks segments as they go:
- Start with Run
- Switch to any station
- Switch back to Run
- Etc.

AI tracks whatever order they do.
Still isolates all run data.
```

### Mode 3: Transitions Workout (Stations Only)

```
No running segments.
Pure station work.
Tracks time + HR per station.
```

### Mode 4: Compromised Running Drill

```
Specific workout type:
- Station work (60-90 sec)
- Immediate run (400m-1km)
- Repeat

Designed to train the run-after-station skill.
AI compares pace degradation over sets.
```

### Mode 5: Pure Run (Traditional)

```
Standard running workout.
No station segments.
All data is "fresh" running.
Used to establish baseline.
```

---

# PART 6: IMPLEMENTATION PLAN

## 6.1 Apple Watch Technical Requirements

```
WATCH APP ARCHITECTURE:

SegmentManager
├── currentSegment: WorkoutSegment
├── segmentHistory: WorkoutSegment[]
├── startSegment(type, subtype)
├── endCurrentSegment()
├── switchToSegment(type, subtype)
└── getSegmentedSummary()

HealthKit Integration:
├── HKWorkoutActivity for each segment
├── HKWorkoutEvent for segment boundaries
├── Continuous HR streaming
├── GPS for run segments
└── Motion data for station detection

Watch UI:
├── Single-tap segment switching
├── Crown scroll for segment selection
├── Haptic feedback per segment type
├── Voice command integration
└── Complication for quick-start
```

## 6.2 Data Sync Strategy

```
REAL-TIME SYNC:
Watch → iPhone (during workout)
├── Segment boundaries
├── HR data stream
├── GPS coordinates (runs)
└── Duration/distance

POST-WORKOUT SYNC:
iPhone → Backend
├── Full segment array
├── Computed metrics
├── AI analysis triggers
└── Progress updates

OFFLINE SUPPORT:
├── Watch stores all data locally
├── Syncs when connection available
├── Never loses a workout
```

## 6.3 MVP Feature Set

### Phase 1: Basic Segmentation
- [ ] Manual tap-to-switch segments
- [ ] Run vs Station distinction
- [ ] Post-workout segment summary
- [ ] Basic pace isolation

### Phase 2: Smart Segmentation
- [ ] Pre-defined workout templates (sim, drill)
- [ ] Auto-detect running vs stationary
- [ ] Compromised run tagging
- [ ] Per-station pace analysis

### Phase 3: AI Integration
- [ ] Personal degradation profile
- [ ] Weakness identification
- [ ] Personalized pace targets
- [ ] Race time prediction

### Phase 4: Advanced
- [ ] Voice commands
- [ ] Predictive segment switching
- [ ] Real-time coaching per segment
- [ ] Compare to global benchmarks

---

# PART 7: USER STORIES

## Story 1: Race Simulation

```
Alex does a half-HYROX simulation on Saturday.

1. Opens FLEXR, selects "HYROX Simulation - Half"
2. App shows: "4 runs + 4 stations. Ready?"
3. Starts workout on Apple Watch
4. Watch shows "RUN 1 - Fresh" with pace targets
5. Completes 1km, taps watch
6. Watch switches to "SKIERG" with timer
7. Completes SkiErg, taps watch
8. Watch shows "RUN 2 - Compromised (post-SkiErg)"
9. Pace target adjusted (+10 sec based on Alex's profile)
10. Continues through all 8 segments...

POST-WORKOUT:
- Total time: 38:45
- Running isolated: 19:20 (4 km @ 4:50 avg)
- Stations isolated: 16:25
- Transitions: 3:00
- Pace degradation: 11% (good!)
- AI notes: "Sled push still your hardest recovery"
```

## Story 2: Compromised Running Drill

```
Wednesday workout: Compromised Running Focus

1. Workout shows: "6 rounds: Station → 600m Run"
2. Round 1: Wall Balls (30 reps) → Run
3. Watch tracks: Station time, then run pace
4. Round 2: Burpees (15 reps) → Run
5. Continues...

POST-WORKOUT:
- Average compromised pace: 4:58/km
- Best recovery: After rowing (4:48/km)
- Worst recovery: After burpees (5:12/km)
- AI: "Burpee recovery improving. Was 5:25 last week."
```

## Story 3: Progress Check

```
After 8 weeks, Alex checks progress:

RUNNING DASHBOARD:
- Fresh pace: 4:30/km → 4:22/km (improved 8 sec)
- Compromised pace: 5:05/km → 4:45/km (improved 20 sec!)
- Degradation: 13% → 9% (massive improvement)

AI INSIGHT:
"Your compromised running has improved more than
your fresh running. This is exactly what HYROX
training should do. Your race prediction improved
from 1:18 to 1:12 based on these gains."
```

---

# SUMMARY

## The Key Innovation

**FLEXR is the ONLY app that isolates running data from station work.**

This enables:
1. True compromised running analysis
2. Per-station recovery profiling
3. Personalized pace targets that account for fatigue
4. Accurate race predictions based on segmented data
5. Targeted training to improve weakest transitions

## Technical Foundation

- Apple Watch segment switching (tap, crown, voice)
- Real-time data streaming per segment type
- Isolated metrics for runs vs stations
- AI learning from segmented patterns
- Progress tracking over time

## Competitive Advantage

No other app does this. Not Strava. Not TrainingPeaks. Not any HYROX tracker.

**This is our moat.**

---

*Document Version: 1.0*
*Created: December 2025*
*Status: Technical Design - Ready for Development*
