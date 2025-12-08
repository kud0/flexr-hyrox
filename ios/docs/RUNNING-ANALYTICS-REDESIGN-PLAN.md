# FLEXR Running Analytics Tab Redesign

## Executive Summary

Running is 50% of HYROX training. The current Running tab is basic - it shows weekly km, recent runs, and volume. This redesign transforms it into a comprehensive running analytics hub with rich data-driven insights.

**Current State:** "You ran. Here's your pace. Ciao!"
**Target State:** World-class running analytics for serious HYROX athletes.

---

## Phase 1: Quick Wins (Enhance Existing UI)

### 1.1 Enhanced This Week Summary
- Add week-over-week comparison (+/-%)
- Add weekly target progress bar
- Show zone distribution breakdown (Z1-2, Z3, Z4-5)
- Add training load status indicator

### 1.2 All Runs List
- Full history with infinite scroll/pagination
- Date grouping by month
- Filter by: date range, session type, distance
- Sort by: date, pace, distance, duration
- Search functionality
- PR badges on qualifying runs

### 1.3 Better Run Cards
- Show zone distribution mini-bar
- Add PR badge indicator
- Relative date display ("2 days ago")
- Tap to see full run details

**Files to modify:**
- `RunningWorkoutsView.swift` - enhance existing cards
- `RunningService.swift` - add filtering/pagination

**New files:**
- `AllRunsListView.swift`
- `RunningSessionFilterSheet.swift`

---

## Phase 2: HealthKit Data Extraction

### 2.1 New Data Types to Extract

| Data | HKQuantityType | Purpose |
|------|----------------|---------|
| Cadence | `.runningStrideLength` + duration | Form analysis (target 180 spm) |
| Stride Length | `.runningStrideLength` | Efficiency/power indicator |
| Ground Contact Time | `.runningGroundContactTime` | Form efficiency |
| Vertical Oscillation | `.runningVerticalOscillation` | Running economy |
| Running Power | `.runningPower` (iOS 16+) | Power-based training |
| Route Data | `HKWorkoutRoute` | GPS, elevation profile |
| VO2 Max | `.vo2Max` | Fitness trend (already fetched, not used) |

### 2.2 Model Updates

Add to `RunningSession`:
```swift
let cadenceAvg: Double?           // steps per minute
let strideLength: Double?         // meters
let groundContactTime: Double?    // milliseconds
let verticalOscillation: Double?  // centimeters
let runningPower: Double?         // watts
let elevationGain: Int?           // meters (fix current nil)
let elevationLoss: Int?           // meters
let trainingLoad: Double?         // TRIMP score
let efficiencyIndex: Double?      // pace / HR ratio
```

### 2.3 Database Migration

```sql
-- 022_enhanced_running_metrics.sql
ALTER TABLE running_sessions ADD COLUMN cadence_avg NUMERIC(5,1);
ALTER TABLE running_sessions ADD COLUMN stride_length_meters NUMERIC(4,2);
ALTER TABLE running_sessions ADD COLUMN ground_contact_time_ms INT;
ALTER TABLE running_sessions ADD COLUMN vertical_oscillation_cm NUMERIC(4,1);
ALTER TABLE running_sessions ADD COLUMN running_power_watts INT;
ALTER TABLE running_sessions ADD COLUMN training_load NUMERIC(6,1);
ALTER TABLE running_sessions ADD COLUMN efficiency_index NUMERIC(5,2);
ALTER TABLE running_sessions ADD COLUMN elevation_loss_meters INT;
```

**Files to modify:**
- `HealthKitService.swift` - request new data types
- `HealthKitRunningImport.swift` - extract new metrics
- `RunningSession.swift` - add new properties

---

## Phase 3: Analytics Engine

### 3.1 Training Load (TRIMP)

Calculate Training Impulse for each session:
```
TRIMP = Duration (min) × HR_ratio × 0.64 × e^(1.92 × HR_ratio)
where HR_ratio = (avgHR - restingHR) / (maxHR - restingHR)
```

### 3.2 Fitness Metrics (CTL/ATL/TSB)

- **CTL (Chronic Training Load)** = 42-day exponential weighted average of TRIMP
- **ATL (Acute Training Load)** = 7-day exponential weighted average of TRIMP
- **TSB (Training Stress Balance)** = CTL - ATL (positive = fresh, negative = fatigued)

### 3.3 HR Efficiency Index

```
Efficiency = (pace in sec/km) / avgHR
```
Lower is better. Track over time to show fitness improvements.

### 3.4 Acute:Chronic Workload Ratio (ACWR)

```
ACWR = ATL / CTL
```
- 0.8-1.3 = optimal training zone
- < 0.8 = under-training
- > 1.5 = injury risk

### 3.5 Pace Zones Auto-Calculation

Based on 5K time trial or best efforts:
- Zone 1 (Recovery): > 130% of threshold pace
- Zone 2 (Easy): 115-130% of threshold
- Zone 3 (Tempo): 100-115% of threshold
- Zone 4 (Threshold): 95-100% of threshold
- Zone 5 (VO2max): < 95% of threshold

**New files:**
- `RunningMetricsCalculator.swift`
- `RunningAnalyticsViewModel.swift`

---

## Phase 4: Visualizations (Swift Charts)

### 4.1 Split Pace Chart
- km-by-km pace bars
- HR overlay line
- Average pace reference line
- Highlight negative/positive splits
- Interactive: tap split for details

### 4.2 HR Efficiency Trend
- 90-day efficiency trend line
- Highlight improvement percentage
- Annotations for key milestones

### 4.3 Training Load Chart
- Weekly TRIMP bars
- CTL/ATL/TSB line overlay
- ACWR indicator with color zones

### 4.4 VO2 Max Trend
- VO2max over time
- Fitness correlation

### 4.5 Pace Zone Distribution
- Horizontal stacked bars
- Target vs actual overlay
- Weekly/monthly toggle

### 4.6 PR Progression
- Line chart per distance
- Highlight PR dates
- Target projection

**New files in `/Charts/`:**
- `SplitPaceChartView.swift`
- `HREfficiencyTrendChart.swift`
- `TrainingLoadChart.swift`
- `VO2MaxTrendChart.swift`
- `PaceZoneDistributionChart.swift`
- `PRProgressionChart.swift`

---

## Phase 5: UI Components

### 5.1 Card Components

| Card | Purpose | Key Metrics |
|------|---------|-------------|
| Enhanced Week Summary | Weekly overview | Volume, zone %, load status |
| HR Efficiency | Fitness improvement | Efficiency trend, % change |
| Running Form | Form analysis | Cadence, stride, GCT, VO |
| Training Load | Load management | TRIMP, CTL/ATL, ACWR |
| Personal Records | PR tracking | All distance PRs, progression |
| Fitness Trends | Long-term progress | VO2max, rolling averages |
| Pace Zones | Zone distribution | Auto-calculated zones, time in zone |

### 5.2 Run Detail View Enhancements

- Interactive split chart (tap for details)
- Running form section with ratings
- HR efficiency vs historical comparison
- Weather conditions (if available)
- Route map with pace coloring
- Comparison to similar runs

**New files in `/Cards/`:**
- `EnhancedWeekSummaryCard.swift`
- `HREfficiencyCard.swift`
- `RunningFormCard.swift`
- `TrainingLoadCard.swift`
- `PersonalRecordsDashboard.swift`
- `FitnessTrendsCard.swift`
- `PaceZonesCard.swift`

---

## File Structure

```
ios/FLEXR/Sources/Features/Analytics/Running/
├── ViewModels/
│   └── RunningAnalyticsViewModel.swift
├── Cards/
│   ├── EnhancedWeekSummaryCard.swift
│   ├── HREfficiencyCard.swift
│   ├── RunningFormCard.swift
│   ├── TrainingLoadCard.swift
│   ├── PersonalRecordsDashboard.swift
│   ├── FitnessTrendsCard.swift
│   └── PaceZonesCard.swift
├── Charts/
│   ├── SplitPaceChartView.swift
│   ├── HREfficiencyTrendChart.swift
│   ├── TrainingLoadChart.swift
│   ├── VO2MaxTrendChart.swift
│   ├── PaceZoneDistributionChart.swift
│   └── PRProgressionChart.swift
├── AllRunsListView.swift
├── RunningSessionFilterSheet.swift
└── RunningSessionDetailView.swift (enhance existing)

ios/FLEXR/Sources/Core/Services/
└── RunningMetricsCalculator.swift
```

---

## Implementation Order

1. **Phase 1** - All Runs List + Enhanced Week Card (quick wins)
2. **Phase 2** - HealthKit extraction enhancements
3. **Phase 3** - Analytics calculations (TRIMP, efficiency, etc.)
4. **Phase 4** - Chart components
5. **Phase 5** - Polish, animations, error states

---

## Success Metrics

After implementation, the Running tab should answer:
- "How much did I run this week vs my target?"
- "Am I getting fitter? (efficiency trend)"
- "Is my running form improving? (cadence, stride)"
- "Am I training too hard or too easy? (load management)"
- "What are my PRs and how am I progressing?"
- "What's my optimal training zone distribution?"
- "How does this run compare to my previous similar runs?"
