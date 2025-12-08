# Analytics Redesign - Integration Guide

## ✅ What We Built

### Phase 1: Foundation Components
All components in `/ios/FLEXR/Sources/Features/Analytics/Components/`:

1. **HeroMetricCard.swift** - 400pt hero cards with large metrics
2. **MetricBreakdownCard.swift** - 180pt detailed breakdown cards
3. **TrendLineChart.swift** - Line chart for trends
4. **ContributionBar.swift** - Impact/contribution indicators
5. **InsightBanner.swift** - Contextual insight messages

### Phase 2: Hero Cards & Main View
Hero cards in `/ios/FLEXR/Sources/Features/Analytics/HeroCards/`:

1. **ReadinessHeroCard.swift** - Circular readiness score (160pt ring)
2. **RacePredictionHeroCard.swift** - Large predicted time (72pt font)
3. **WeeklyTrainingHeroCard.swift** - Circular training progress (200pt ring)

Main view in `/ios/FLEXR/Sources/Features/Analytics/Views/`:

4. **AnalyticsHomeView.swift** - New single-screen analytics journey

---

## 🔌 How to Integrate (3 Options)

### Option 1: Replace Current Analytics (Recommended)

**File**: `ContentView.swift` or wherever analytics tab is defined

**Before:**
```swift
NavigationLink(destination: AnalyticsContainerView()) {
    Label("Analytics", systemImage: "chart.bar")
}
```

**After:**
```swift
NavigationLink(destination: AnalyticsHomeView()) {
    Label("Analytics", systemImage: "chart.bar")
}
```

### Option 2: Add as "Analytics v2" Tab

Keep old analytics during testing, add new version:

```swift
TabView {
    // ... existing tabs ...

    AnalyticsHomeView()
        .tabItem {
            Label("Analytics v2", systemImage: "chart.bar.fill")
        }
}
```

### Option 3: Feature Flag Toggle

```swift
@AppStorage("useNewAnalytics") var useNewAnalytics = false

var analyticsView: some View {
    if useNewAnalytics {
        AnalyticsHomeView()
    } else {
        AnalyticsContainerView() // Old 7-tab version
    }
}
```

---

## 📊 Connecting Real Data

### Current State (Mock Data)

`AnalyticsHomeViewModel` currently uses hardcoded mock data:

```swift
@Published var readinessScore: Int = 78
@Published var hrvScore: Int = 45
// ... etc
```

### Step 1: Update ViewModel to Use Real Services

**File**: `AnalyticsHomeView.swift` (lines ~240-280)

```swift
class AnalyticsHomeViewModel: ObservableObject {
    private let supabaseService = SupabaseService.shared
    private let analyticsService = WorkoutAnalyticsService()

    func loadData() async {
        // Fetch readiness
        if let readiness = await supabaseService.fetchReadiness() {
            self.readinessScore = readiness.score
            self.hrvScore = readiness.hrv
            self.sleepHours = readiness.sleepHours
            self.restingHR = readiness.restingHR
        }

        // Fetch race prediction
        if let prediction = await analyticsService.fetchRacePrediction() {
            self.predictedTime = prediction.timeString
            self.timeChangeMinutes = prediction.changeFromLastMonth
            self.sessionCount = prediction.basedOnSessions
        }

        // Fetch weekly training
        if let training = await supabaseService.fetchWeeklyTraining() {
            self.currentWeekHours = training.completedHours
            self.targetWeekHours = training.targetHours
        }

        // Fetch station improvements
        if let stations = await analyticsService.fetchStationTrends() {
            if let top = stations.max(by: { $0.improvement < $1.improvement }) {
                self.topImprovement = StationImprovement(
                    name: top.name,
                    emoji: top.emoji,
                    percentImprovement: top.improvement,
                    insight: top.insight
                )
            }

            if let weakest = stations.min(by: { $0.score < $1.score }) {
                self.focusArea = StationFocus(
                    name: weakest.name,
                    emoji: weakest.emoji,
                    improvementPotential: weakest.potential,
                    recommendation: weakest.recommendation
                )
            }
        }

        // Fetch recent workouts
        if let workouts = await supabaseService.fetchRecentWorkouts(limit: 3) {
            self.recentWorkouts = workouts.map { /* map to RecentWorkout */ }
        }
    }
}
```

### Step 2: Update onAppear to Use Async

**File**: `AnalyticsHomeView.swift` (line ~80)

**Before:**
```swift
.onAppear {
    viewModel.loadData()
}
```

**After:**
```swift
.task {
    await viewModel.loadData()
}
```

---

## 🎨 Design System Usage Reference

### Typography Hierarchy

```swift
// Hero metrics (main stat)
.font(DesignSystem.Typography.metricHero)        // 120pt
.font(DesignSystem.Typography.metricHeroLarge)   // 96pt

// Breakdown metrics
.font(DesignSystem.Typography.metricBreakdown)   // 72pt
.font(DesignSystem.Typography.metricBreakdownMedium) // 64pt

// Insights
.font(DesignSystem.Typography.insightLarge)      // 22pt bold
.font(DesignSystem.Typography.insightMedium)     // 17pt regular
.font(DesignSystem.Typography.insightSmall)      // 15pt regular

// Section headers
.font(DesignSystem.Typography.sectionHeader)     // 17pt semibold
```

### Spacing System

```swift
// Analytics-specific spacing
DesignSystem.Spacing.analyticsCardPadding       // 24pt (inside cards)
DesignSystem.Spacing.analyticsSectionSpacing    // 32pt (between major sections)
DesignSystem.Spacing.analyticsCardSpacing       // 24pt (between hero cards)
DesignSystem.Spacing.analyticsBreakdownSpacing  // 16pt (between breakdown items)
```

### Card Heights

```swift
DesignSystem.CardHeight.compact      // 140pt (workout items)
DesignSystem.CardHeight.standard     // 180pt (breakdown cards)
DesignSystem.CardHeight.featured     // 240pt (featured stations)
DesignSystem.CardHeight.hero         // 360pt (dashboard cards)
DesignSystem.CardHeight.heroLarge    // 400pt (extra large cards)
```

---

## 🧪 Testing the New Analytics

### In Xcode Previews

Each component has a preview. To test:

1. Open any component file (e.g., `ReadinessHeroCard.swift`)
2. Click "Resume" in the canvas (Cmd+Option+P)
3. See live preview with sample data

### In Simulator

1. **Build the project**: Cmd+B in Xcode
2. **Run in simulator**: Cmd+R
3. **Navigate to Analytics tab**
4. **See the new design**

### With Real Data

1. Update `AnalyticsHomeViewModel.loadData()` to fetch from Supabase
2. Test with your real workout data
3. Verify all metrics display correctly

---

## 🎯 Key Differences from Old Design

### Before (AnalyticsContainerView)

```
7 Horizontal Tabs:
├─ Overview (cramped dashboard, 15+ metrics)
├─ History
├─ Running
├─ HYROX
├─ Stations (8-station table, tiny fonts)
├─ HR (zone table)
└─ Recovery

Problems:
- 10-13pt fonts in tables
- 280pt cards side-by-side (cramped)
- No breathing room (10-12pt spacing)
- Static snapshots, no trends
- Tab overload (7 navigation items)
```

### After (AnalyticsHomeView)

```
Single Scrolling Journey:
├─ Today's Readiness (400pt card, 120pt score)
├─ Race Prediction (380pt card, 72pt time)
├─ Weekly Training (360pt card, 200pt ring)
├─ Biggest Improvement (340pt card, station insight)
├─ Focus Area (320pt card, recommendation)
└─ Recent Workouts (3 compact cards)

Benefits:
- 72-120pt hero fonts (emotional impact)
- 24pt spacing minimum (breathing room)
- ONE metric per card (clear focus)
- Progressive disclosure (tap for details)
- Contextual insights (storytelling)
```

---

## 🚀 Next Steps (Phase 3)

The following detail views are stubbed and need implementation:

### 1. ReadinessDetailView
**Purpose**: Breakdown of HRV, Sleep, RHR with 7-day trends

**Components to use**:
- MetricBreakdownCard (for HRV, Sleep, RHR)
- TrendLineChart (for 7-day readiness trend)
- ContributionBar (for impact indicators)

**Location**: Create in `/Features/Analytics/Views/ReadinessDetailView.swift`

### 2. RacePredictionTimelineView
**Purpose**: Timeline showing progression + future projection

**Components to use**:
- TrendLineChart (for 90-day progression)
- InsightBanner (for "what's driving improvement")
- Custom timeline visualization

**Location**: Create in `/Features/Analytics/Views/RacePredictionTimelineView.swift`

### 3. WeeklyTrainingDetailView
**Purpose**: Daily breakdown + week-over-week comparison

**Components to use**:
- Custom bar chart (vertical bars for each day)
- InsightBanner (for comparison insights)
- TrendLineChart (for 4-week trend)

**Location**: Create in `/Features/Analytics/Views/WeeklyTrainingDetailView.swift`

### 4. Update Existing Views

The following existing views should be redesigned to match new style:

- `StationAnalyticsView.swift` - Use MetricBreakdownCard + TrendLineChart
- `HeartRateAnalyticsView.swift` - Use stacked zone bar + breakdown cards
- `WorkoutHistoryView.swift` - Use compact workout cards

---

## 📝 File Structure Summary

```
/ios/FLEXR/Sources/
├── UI/Styles/
│   └── DesignSystem.swift ✅ (UPDATED with analytics tokens)
│
└── Features/Analytics/
    ├── Components/ ✅ (NEW - Phase 1)
    │   ├── HeroMetricCard.swift
    │   ├── MetricBreakdownCard.swift
    │   ├── TrendLineChart.swift
    │   ├── ContributionBar.swift
    │   └── InsightBanner.swift
    │
    ├── HeroCards/ ✅ (NEW - Phase 2)
    │   ├── ReadinessHeroCard.swift
    │   ├── RacePredictionHeroCard.swift
    │   └── WeeklyTrainingHeroCard.swift
    │
    ├── Views/
    │   ├── AnalyticsHomeView.swift ✅ (NEW - Phase 2)
    │   ├── AnalyticsContainerView.swift (OLD - keep for reference)
    │   ├── AnalyticsDashboardView.swift (OLD)
    │   ├── StationAnalyticsView.swift (TODO: Redesign)
    │   ├── HeartRateAnalyticsView.swift (TODO: Redesign)
    │   ├── RecoveryAnalyticsView.swift (Keep as-is)
    │   └── WorkoutHistoryView.swift (TODO: Redesign)
    │
    ├── ViewModels/
    │   └── AnalyticsData.swift (Keep for now)
    │
    └── Models/
        └── AnalyticsTypes.swift (Keep for now)
```

---

## ⚠️ Important Notes

### 1. Don't Delete Old Code Yet

Keep `AnalyticsContainerView` and related files during transition. You might want to A/B test or reference the old implementation.

### 2. Build Issues with SPM

If you see errors about `swift-clocks` dependencies:

1. In Xcode: **File → Packages → Reset Package Caches**
2. Then: **Product → Clean Build Folder** (Shift+Cmd+K)
3. Then: **Product → Build** (Cmd+B)

This is a known SPM cache issue, not related to our code.

### 3. Preview Canvas

To see component previews:
- Open any `.swift` file with `#Preview`
- Press **Cmd+Option+P** to show preview
- Adjust preview data in the `#Preview` block

### 4. Dark Mode Only

Current design is optimized for dark mode (OLED black backgrounds). Light mode support can be added later if needed.

---

## 🎨 Design Philosophy

### Progressive Disclosure
- **Home**: ONE metric per card, glanceable summary
- **Detail**: Tap card → See breakdown + trends
- **Deep Dive**: Tap again → Full history + correlations

### Emotional Impact
- **Large fonts** (72-120pt) create visceral response
- **Breathing room** (24-32pt spacing) feels premium
- **Storytelling** ("You're ready for intensity") vs data dump

### Apple Fitness-Style UX
- Clean, focused, ONE thing at a time
- Big rings and progress indicators
- Subtle insights, not overwhelming
- Smooth navigation, clear hierarchy

---

**Status**: Ready to integrate! ✅
**Next Step**: Wire AnalyticsHomeView into your app navigation.
**Build Issue**: Fix SPM cache (see above) if needed.

**Questions?** Check `/docs/implementation/ANALYTICS-REDESIGN-PLAN.md` for full details.
