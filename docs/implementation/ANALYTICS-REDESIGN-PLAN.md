# FLEXR Analytics Redesign - Complete Implementation Plan

## 🎯 Vision
Transform analytics from "cold data dump" to "personal Hyrox intelligence companion"

---

## 📊 Current State Analysis

### Problems Identified:
- ❌ 7 fragmented tabs (Overview, History, Running, HYROX, Stations, HR, Recovery)
- ❌ 15+ metrics crammed on one dashboard
- ❌ Tiny fonts (10-13pt) trying to fit multi-column tables
- ❌ No breathing room (280pt cards side-by-side, 10pt row padding)
- ❌ Static snapshots only - no trends or timelines
- ❌ No storytelling or insights
- ❌ Feels like a spreadsheet, not an experience

### Current Files:
```
/ios/FLEXR/Sources/Features/Analytics/
├── Views/
│   ├── AnalyticsContainerView.swift (7-tab container)
│   ├── AnalyticsDashboardView.swift (main dashboard)
│   ├── StationAnalyticsView.swift
│   ├── HeartRateAnalyticsView.swift
│   ├── RecoveryAnalyticsView.swift
│   ├── HyroxRunningAnalyticsView.swift
│   └── RunningWorkoutsView.swift
├── Components/
│   └── MetricCard.swift
├── ViewModels/
│   └── AnalyticsData.swift
└── Models/
    └── AnalyticsTypes.swift
```

---

## 🎨 New Design Principles

### Typography Scale:
```swift
// HERO METRICS (main stat on screen)
metricHero: 96-120pt, Bold, Rounded Monospace

// LARGE METRICS (secondary stats)
metricLarge: 64-72pt, Bold, Rounded Monospace

// MEDIUM METRICS (tertiary stats)
metricMedium: 48pt, Semibold, Rounded Monospace

// SMALL METRICS (labels)
metricSmall: 32pt, Semibold, Rounded Monospace

// INSIGHTS (explanatory text)
insightLarge: 22pt, Bold
insightMedium: 17pt, Regular
insightSmall: 15pt, Regular, Secondary Gray

// SECTION HEADERS
sectionHeader: 17pt, Semibold

// LABELS
label: 15pt, Regular, Secondary Gray
labelSmall: 13pt, Regular, Tertiary Gray
```

### Spacing Scale:
```swift
xxSmall: 4pt   // Tight elements
xSmall: 8pt    // Related items
small: 12pt    // Default gap
medium: 16pt   // Between cards within section
large: 24pt    // Between sections
xLarge: 32pt   // Major section breaks
xxLarge: 48pt  // Hero spacing
```

### Card Heights:
```swift
compact: 140pt     // Workout history items
standard: 180pt    // Metric breakdown cards
featured: 240pt    // Top stat cards
hero: 360-400pt    // Main dashboard cards
```

---

## 🏗️ New Information Architecture

### Before (7 Tabs):
```
Overview | History | Running | HYROX | Stations | HR | Recovery
```

### After (Single Scrolling Journey):
```
Analytics Home (Progressive Disclosure)
├── Today's Readiness → ReadinessDetailView
├── Race Prediction → RacePredictionTimelineView
├── This Week's Training → WeeklyTrainingDetailView
├── Biggest Improvement → StationPerformanceView
├── Focus Area → StationPerformanceView (scrolled to weakness)
└── Recent Workouts → WorkoutHistoryView
```

---

## 📱 Screen-by-Screen Specifications

### SCREEN 1: Analytics Home (New Entry Point)

**File**: `AnalyticsHomeView.swift` (NEW)

**Layout**:
```
┌─────────────────────────────────┐
│ PERFORMANCE          [7d][30d]  │  13pt label + timeframe
│ Analytics                       │  34pt bold title
│                                 │
│ ┌─────────────────────────────┐ │
│ │   TODAY'S READINESS         │ │  Hero card (400pt)
│ │                             │ │
│ │        [  78  ]             │ │  120pt score
│ │       /  100                │ │  24pt gray
│ │                             │ │
│ │ You're ready for intensity  │ │  17pt insight
│ │ Based on HRV, sleep, RHR    │ │  15pt gray
│ │                             │ │
│ │      [See breakdown →]      │ │  Tap target
│ └─────────────────────────────┘ │
│                                 │  24pt spacing
│ ┌─────────────────────────────┐ │
│ │   RACE PREDICTION           │ │  Hero card (380pt)
│ │                             │ │
│ │       1:18:45               │ │  72pt monospace
│ │                             │ │
│ │ ↓ 2:15 faster this month    │ │  17pt green
│ │ Based on 47 sessions        │ │  15pt gray
│ │                             │ │
│ │ [See prediction timeline →] │ │
│ └─────────────────────────────┘ │
│                                 │
│ [Continue with 4 more cards...] │
└─────────────────────────────────┘
```

**Components Needed**:
1. `ReadinessHeroCard` (400pt)
2. `RacePredictionHeroCard` (380pt)
3. `WeeklyTrainingHeroCard` (360pt)
4. `ImprovementHeroCard` (340pt)
5. `FocusAreaHeroCard` (320pt)
6. `RecentWorkoutsPreview` (500pt)

---

### SCREEN 2: Readiness Detail View

**File**: `ReadinessDetailView.swift` (NEW)

**Layout**:
```
┌─────────────────────────────────┐
│ ← Readiness                     │  Back button
│                                 │
│        [  78  ]                 │  160pt score badge
│       /  100                    │
│                                 │
│   You're ready for intensity    │  22pt insight
│                                 │
│ ─────────────────────────────── │  32pt spacing
│                                 │
│ BREAKDOWN                       │  17pt semibold
│                                 │
│ ┌─────────────────────────────┐ │
│ │ 💚 HRV                       │ │  180pt card
│ │                             │ │
│ │     45 ms                   │ │  48pt value
│ │     ↑ 5ms from yesterday    │ │  17pt green
│ │                             │ │
│ │ ████████░░ 80% contribution │ │  Impact bar
│ └─────────────────────────────┘ │
│                                 │  16pt spacing
│ [Sleep card - 180pt]            │
│ [Resting HR card - 180pt]       │
│                                 │
│ ─────────────────────────────── │  32pt spacing
│                                 │
│ 7-DAY TREND                     │  17pt semibold
│                                 │
│ [Line chart - 280pt height]     │  Trend visualization
│                                 │
│ Mon  Tue  Wed  Thu  Fri  Sat    │  13pt labels
│  72   68   75   78   81   76    │  15pt values
└─────────────────────────────────┘
```

**Components Needed**:
1. `MetricBreakdownCard` (180pt) - Reusable
2. `TrendLineChart` - NEW chart component
3. `ContributionBar` - Impact indicator

---

### SCREEN 3: Race Prediction Timeline View

**File**: `RacePredictionTimelineView.swift` (NEW)

**Layout**:
```
┌─────────────────────────────────┐
│ ← Race Prediction               │
│                                 │
│       1:18:45                   │  96pt hero time
│                                 │
│ ↓ 2:15 faster than 30 days ago │  22pt green
│ Based on 47 training sessions   │  17pt gray
│                                 │
│ ─────────────────────────────── │
│                                 │
│ YOUR PROGRESSION                │  17pt semibold
│                                 │
│ [Timeline viz - 400pt]          │  Milestone timeline
│                                 │
│ 3 months ago    1:25:30         │
│ 2 months ago    1:22:15         │
│ 1 month ago     1:21:00         │
│ Today          1:18:45 ← You   │
│                                 │
│ ─────────────────────────────── │
│                                 │
│ RACE DAY PREDICTION (60 days)   │
│                                 │
│       1:15:30                   │  72pt projected
│                                 │
│ If you maintain current volume  │  15pt insight
│ and continue improving ski erg  │
│                                 │
│ ─────────────────────────────── │
│                                 │
│ WHAT'S DRIVING YOUR IMPROVEMENT │
│                                 │
│ [Correlation cards]             │  Insight cards
└─────────────────────────────────┘
```

**Components Needed**:
1. `TimelineVisualization` - NEW
2. `ProjectionCard` - Future prediction
3. `CorrelationInsightCard` - Reusable

---

### SCREEN 4: Weekly Training Detail View

**File**: `WeeklyTrainingDetailView.swift` (NEW)

**Layout**:
```
┌─────────────────────────────────┐
│ ← This Week's Training          │
│                                 │
│    ╭───────────╮                │  200pt ring
│    │    6.2    │                │  64pt value
│    │   / 8.0h  │                │  32pt target
│    ╰───────────╯                │
│                                 │
│      78% complete               │  22pt
│      1.8h remaining             │  17pt gray
│                                 │
│ ─────────────────────────────── │
│                                 │
│ DAILY BREAKDOWN                 │
│                                 │
│ [Vertical bar chart - 360pt]    │  Big visible bars
│                                 │
│ Mon   Tue   Wed   Thu   Fri     │  15pt labels
│ 1.2h  0.8h  1.5h  1.2h  1.0h   │  Bars + values
│                                 │
│ ─────────────────────────────── │
│                                 │
│ COMPARED TO LAST WEEK           │
│                                 │
│      +1.2 hours                 │  48pt green
│      ↑ 24% increase             │  22pt
│                                 │
│ You're building consistently    │  15pt insight
└─────────────────────────────────┘
```

**Components Needed**:
1. `WeeklyProgressRing` - Large ring (200pt)
2. `DailyBarChart` - Vertical bars (360pt)
3. `ComparisonCard` - Week-over-week

---

### SCREEN 5: Station Performance View (Redesigned)

**File**: `StationPerformanceView.swift` (REPLACE EXISTING)

**Layout**:
```
┌─────────────────────────────────┐
│ ← Station Performance           │
│                                 │
│ YOUR STRONGEST                  │  17pt semibold
│                                 │
│ ┌─────────────────────────────┐ │
│ │ 🏋️ Sled Push                 │ │  240pt featured card
│ │                             │ │
│ │     1:24                    │ │  64pt best time
│ │     personal best           │ │  17pt
│ │                             │ │
│ │     ↑ 18% improvement       │ │  32pt green
│ │     this month              │ │  17pt
│ │                             │ │
│ │ [30-day trend chart]        │ │  120pt chart
│ └─────────────────────────────┘ │
│                                 │
│ YOUR FOCUS AREA                 │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ 🚣 Ski Erg                   │ │  240pt featured card
│ │                             │ │
│ │     1:18                    │ │  64pt best time
│ │     20% slower than avg     │ │  17pt orange
│ │                             │ │
│ │     +2s potential           │ │  22pt
│ │     = 40s off race time     │ │  17pt insight
│ │                             │ │
│ │ [30-day trend chart]        │ │  120pt chart
│ └─────────────────────────────┘ │
│                                 │
│ ALL STATIONS                    │
│                                 │
│ [6 compact cards - 160pt each]  │  Remaining stations
└─────────────────────────────────┘
```

**Components Needed**:
1. `StationFeaturedCard` (240pt) - Top 2 stations
2. `StationCompactCard` (160pt) - Others
3. `MiniTrendChart` (120pt) - Small chart

---

### SCREEN 6: Heart Rate Zones View (Redesigned)

**File**: `HeartRateZonesView.swift` (REPLACE EXISTING)

**Layout**:
```
┌─────────────────────────────────┐
│ ← Heart Rate                    │
│                                 │
│      186 bpm                    │  96pt max HR
│      your maximum               │  17pt gray
│                                 │
│ ─────────────────────────────── │
│                                 │
│ THIS WEEK'S ZONES               │
│                                 │
│ [Stacked bar - 60pt]            │  Full width
│ │Z1│Z2: 35%│Z3│Z4│Z5│          │  Color coded
│                                 │
│ ─────────────────────────────── │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ 💙 Zone 2 (Easy)             │ │  220pt card
│ │                             │ │
│ │     35%                     │ │  72pt percentage
│ │     of training time        │ │  17pt
│ │                             │ │
│ │ 112-130 bpm                 │ │  22pt range
│ │                             │ │
│ │ This is your aerobic base   │ │  15pt insight
│ │ building zone. Sweet spot.  │ │
│ └─────────────────────────────┘ │
│                                 │
│ [4 more zone cards - 180pt]     │  Scrollable
│                                 │
│ ─────────────────────────────── │
│                                 │
│ RECOMMENDATION                  │
│                                 │
│ Add 15% more Zone 2 volume      │  22pt
│ for better endurance base       │  17pt
└─────────────────────────────────┘
```

**Components Needed**:
1. `StackedZoneBar` - Horizontal distribution
2. `HRZoneCard` (180-220pt) - Per-zone details
3. `RecommendationBanner` - Actionable advice

---

## 🔧 Implementation Phases

### Phase 1: Foundation (Week 1)
**Goal**: Update design system and create base components

1. **Update DesignSystem.swift**
   - Add new typography scale
   - Update spacing system
   - Add card height constants

2. **Create Base Components** (in `/Features/Analytics/Components/`)
   - `HeroMetricCard.swift` - 400pt card with large metric
   - `MetricBreakdownCard.swift` - 180pt card for details
   - `TrendLineChart.swift` - Reusable line chart
   - `ContributionBar.swift` - Impact indicator
   - `InsightBanner.swift` - Contextual insights

3. **Build & Test** ✅

---

### Phase 2: Analytics Home (Week 1-2)
**Goal**: Create new analytics home screen

1. **Create AnalyticsHomeView.swift** (NEW)
   - Replace AnalyticsContainerView as entry point
   - Single scrolling view with 6 hero cards

2. **Create Hero Card Components**:
   - `ReadinessHeroCard.swift`
   - `RacePredictionHeroCard.swift`
   - `WeeklyTrainingHeroCard.swift`
   - `ImprovementHeroCard.swift`
   - `FocusAreaHeroCard.swift`
   - `RecentWorkoutsPreview.swift`

3. **Update Navigation**
   - Modify ContentView.swift to use AnalyticsHomeView
   - Keep old views for detail screens

4. **Build & Test** ✅

---

### Phase 3: Detail Screens (Week 2-3)
**Goal**: Create drill-down detail views

1. **ReadinessDetailView.swift** (NEW)
   - HRV/Sleep/RHR breakdown cards
   - 7-day trend chart
   - Navigation from ReadinessHeroCard

2. **RacePredictionTimelineView.swift** (NEW)
   - Timeline visualization
   - Future projection
   - Correlation insights

3. **WeeklyTrainingDetailView.swift** (NEW)
   - Daily bar chart
   - Week-over-week comparison
   - Training insights

4. **Redesign Existing Views**:
   - Update `StationPerformanceView.swift`
   - Update `HeartRateZonesView.swift`

5. **Build & Test** ✅

---

### Phase 4: Intelligence Layer (Week 3-4)
**Goal**: Add insights and recommendations

1. **Create AnalyticsInsightsService.swift**
   - Generate contextual insights
   - Detect trends (improving/declining)
   - Calculate week-over-week changes
   - Identify correlations

2. **Update ViewModels**
   - Add insight generation to AnalyticsData
   - Add comparison logic
   - Add recommendation engine

3. **Enhance Charts**
   - Add trend annotations
   - Add comparison overlays
   - Add target zones

4. **Build & Test** ✅

---

## 📁 New File Structure

```
/ios/FLEXR/Sources/Features/Analytics/
├── Views/
│   ├── AnalyticsHomeView.swift (NEW - main entry)
│   ├── ReadinessDetailView.swift (NEW)
│   ├── RacePredictionTimelineView.swift (NEW)
│   ├── WeeklyTrainingDetailView.swift (NEW)
│   ├── StationPerformanceView.swift (REDESIGNED)
│   ├── HeartRateZonesView.swift (REDESIGNED)
│   ├── RecoveryAnalyticsView.swift (KEEP)
│   └── WorkoutHistoryView.swift (KEEP)
│
├── HeroCards/ (NEW)
│   ├── ReadinessHeroCard.swift
│   ├── RacePredictionHeroCard.swift
│   ├── WeeklyTrainingHeroCard.swift
│   ├── ImprovementHeroCard.swift
│   ├── FocusAreaHeroCard.swift
│   └── RecentWorkoutsPreview.swift
│
├── Components/
│   ├── HeroMetricCard.swift (NEW)
│   ├── MetricBreakdownCard.swift (NEW)
│   ├── TrendLineChart.swift (NEW)
│   ├── ContributionBar.swift (NEW)
│   ├── InsightBanner.swift (NEW)
│   ├── StackedZoneBar.swift (NEW)
│   ├── TimelineVisualization.swift (NEW)
│   ├── DailyBarChart.swift (NEW)
│   ├── WeeklyProgressRing.swift (NEW)
│   └── MetricCard.swift (EXISTING - keep for compatibility)
│
├── ViewModels/
│   ├── AnalyticsData.swift (UPDATE)
│   └── AnalyticsHomeViewModel.swift (NEW)
│
├── Services/
│   └── AnalyticsInsightsService.swift (NEW)
│
└── Models/
    ├── AnalyticsTypes.swift (UPDATE)
    └── AnalyticsInsight.swift (NEW)
```

---

## 🎯 Key Design Decisions

### Progressive Disclosure
- **Home**: ONE metric per card, glanceable
- **Detail**: Breakdown + trends
- **Deep Dive**: Full history + correlations

### Typography Hierarchy
- **Hero numbers**: 96-120pt (emotional impact)
- **Large numbers**: 64-72pt (secondary stats)
- **Medium numbers**: 48pt (breakdown values)
- **Insights**: 17-22pt (readable, conversational)

### Spacing Philosophy
- **24pt minimum** between cards (vs current 12-16pt)
- **32pt** between major sections
- **24pt padding** inside cards (vs current 16pt)

### Card Height Strategy
- **400pt hero cards** on home (vs current 280pt cramped)
- **180-240pt detail cards** (breathing room)
- **ONE metric focus** per card (vs multi-metric tables)

### Color Strategy
- Keep existing electric blue brand (#0A84FF)
- Use semantic colors (green=improving, orange=warning, red=declining)
- Use HR zone colors for zone visualization

---

## ✅ Success Criteria

### User Experience
- [ ] Users understand their state in <3 seconds
- [ ] Analytics feel inspiring, not overwhelming
- [ ] Clear progression storytelling
- [ ] Actionable insights on every screen

### Design Quality
- [ ] 72pt+ hero metrics on every main screen
- [ ] 24pt+ spacing between sections
- [ ] No cramped tables or tiny fonts
- [ ] Progressive disclosure working smoothly

### Technical Quality
- [ ] Clean, DRY code
- [ ] Reusable components
- [ ] No duplicate files
- [ ] Builds succeed after each phase
- [ ] Smooth animations/transitions

---

## 🚀 Quick Start Commands

```bash
# Build after each phase
cd /Users/alexsolecarretero/Public/projects/FLEXR/ios
xcodebuild -project FLEXR.xcodeproj -target FLEXR -sdk iphonesimulator clean build

# Preview in Xcode
# Open FLEXR.xcodeproj and run in simulator
```

---

## 📝 Notes

- Keep old views temporarily for reference
- Migrate data gradually (don't break existing analytics)
- Test on multiple screen sizes (iPhone SE, Pro, Pro Max)
- Ensure dark mode looks perfect (OLED black background)
- Add haptic feedback for interactions
- Consider accessibility (VoiceOver, Dynamic Type)

---

**Last Updated**: 2025-12-06
**Status**: Ready to implement
**Next Step**: Phase 1 - Foundation
