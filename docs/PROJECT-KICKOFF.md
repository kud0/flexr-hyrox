# FLEXR Project Kickoff
## Complete Roadmap to Build the App

---

# PHASE 0: DECISIONS & SETUP (Week 1)

## Immediate Decisions Required

### 1. Tech Stack

| Layer | Recommended | Alternative | Decision Needed |
|-------|-------------|-------------|-----------------|
| **iOS App** | SwiftUI | React Native | SwiftUI (native performance, Watch integration) |
| **watchOS App** | SwiftUI | - | SwiftUI (required for native Watch) |
| **Backend** | Node.js + TypeScript | Go, Python | Choose based on team |
| **Database** | PostgreSQL | - | PostgreSQL (relational, reliable) |
| **AI/ML** | OpenAI API + Custom | Claude API | OpenAI for workout generation |
| **Auth** | Firebase Auth | Auth0, Supabase | Firebase (easy, Apple Sign-in) |
| **Push Notifications** | Firebase + APNs | OneSignal | Firebase |
| **Analytics** | Mixpanel | Amplitude | Mixpanel |
| **Payments** | RevenueCat | StoreKit 2 | RevenueCat (easier) |
| **Hosting** | AWS | GCP, Vercel | AWS (scalable) |

### 2. Team Requirements

| Role | Need | Priority |
|------|------|----------|
| **iOS Developer** | Senior, SwiftUI + watchOS experience | P0 - Critical |
| **Backend Developer** | Node.js/TypeScript, API design | P0 - Critical |
| **AI/ML Engineer** | Workout generation, learning algorithms | P1 - High |
| **UI/UX Designer** | Mobile + Watch experience | P1 - High |
| **Product Manager** | You (founder) | P0 |

**Minimum Viable Team:** 1 iOS dev + 1 Backend dev + You
**Ideal Team:** Add AI engineer + Designer

### 3. Timeline Decision

| Option | Timeline | Trade-off |
|--------|----------|-----------|
| **MVP Fast** | 3-4 months | Core features only, iterate based on feedback |
| **MVP Complete** | 5-6 months | More polished, more features |
| **Full V1** | 8-10 months | Everything designed, higher quality |

**Recommendation:** MVP Fast (3-4 months), then iterate

---

## Week 1 Tasks

### Day 1-2: Repository & Environment Setup

```bash
# Create project structure
FLEXR/
├── ios/                    # iOS + watchOS app
│   ├── FLEXR/             # Main iOS app
│   ├── FLEXRWatch/        # watchOS app
│   └── Shared/            # Shared code
├── backend/               # API server
│   ├── src/
│   ├── tests/
│   └── package.json
├── ai/                    # AI/ML models and logic
│   ├── workout-generation/
│   └── learning-engine/
├── docs/                  # Documentation (already started!)
│   ├── design/
│   ├── research/
│   └── strategy/
└── scripts/               # Utility scripts
```

### Day 3-4: Design System & UI Kit

- [ ] Define color palette
- [ ] Define typography
- [ ] Create component library sketch
- [ ] Watch app design constraints
- [ ] Create Figma/Sketch project

### Day 5-7: Technical Architecture

- [ ] Database schema design
- [ ] API endpoint planning
- [ ] AI model architecture
- [ ] Apple Watch ↔ iPhone sync strategy
- [ ] HealthKit integration plan

---

# PHASE 1: FOUNDATION (Weeks 2-4)

## Backend Foundation

### Week 2: Core API

```
ENDPOINTS TO BUILD:

Auth:
POST   /auth/register
POST   /auth/login
POST   /auth/apple-signin
GET    /auth/me

User Profile:
GET    /users/profile
PUT    /users/profile
PUT    /users/training-architecture
PUT    /users/equipment
PUT    /users/goals

Workouts:
GET    /workouts/today
GET    /workouts/week
GET    /workouts/month
POST   /workouts/complete
POST   /workouts/feedback
POST   /workouts/swap

Progress:
GET    /progress/dashboard
GET    /progress/running
GET    /progress/stations
GET    /progress/trends
```

### Week 3: Database Schema

```sql
-- Core Tables

CREATE TABLE users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE,
    apple_id VARCHAR(255),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE user_profiles (
    user_id UUID PRIMARY KEY REFERENCES users(id),
    name VARCHAR(255),
    age_group VARCHAR(20),
    fitness_level VARCHAR(20),
    background VARCHAR(20),
    hyrox_experience INTEGER,
    previous_race_time INTERVAL,
    equipment_access VARCHAR(20)
);

CREATE TABLE training_architecture (
    user_id UUID PRIMARY KEY REFERENCES users(id),
    days_per_week INTEGER,
    sessions_per_day INTEGER,
    session_1_type VARCHAR(20),
    session_2_type VARCHAR(20),
    preferred_duration INTEGER,
    variable_schedule BOOLEAN
);

CREATE TABLE goals (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    goal_type VARCHAR(20), -- lifestyle, race
    race_date DATE,
    race_location VARCHAR(255),
    division VARCHAR(20),
    target_time INTERVAL,
    created_at TIMESTAMP
);

CREATE TABLE workouts (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    date DATE,
    session_number INTEGER,
    workout_type VARCHAR(20),
    status VARCHAR(20), -- pending, completed, skipped
    planned_duration INTEGER,
    actual_duration INTEGER,
    created_at TIMESTAMP,
    completed_at TIMESTAMP
);

CREATE TABLE workout_segments (
    id UUID PRIMARY KEY,
    workout_id UUID REFERENCES workouts(id),
    segment_index INTEGER,
    segment_type VARCHAR(20), -- RUN, STATION, REST
    station_type VARCHAR(20),

    -- Targets
    target_distance INTEGER,
    target_duration INTEGER,
    target_reps INTEGER,
    target_pace_min INTEGER,
    target_pace_max INTEGER,

    -- Actuals
    actual_distance INTEGER,
    actual_duration INTEGER,
    actual_reps INTEGER,
    actual_pace INTEGER,

    -- HR data
    avg_heart_rate INTEGER,
    max_heart_rate INTEGER,
    hr_at_start INTEGER,
    hr_at_end INTEGER,

    -- Context
    is_fresh_run BOOLEAN,
    previous_station VARCHAR(20),
    cumulative_stations INTEGER,

    completed_at TIMESTAMP
);

CREATE TABLE user_performance_profile (
    user_id UUID PRIMARY KEY REFERENCES users(id),

    -- Fresh running
    fresh_pace_zone2 INTEGER,
    fresh_pace_threshold INTEGER,
    fresh_pace_race INTEGER,

    -- Compromised running (seconds degradation)
    degradation_skierg INTEGER,
    degradation_sled_push INTEGER,
    degradation_sled_pull INTEGER,
    degradation_burpees INTEGER,
    degradation_rowing INTEGER,
    degradation_farmers INTEGER,
    degradation_lunges INTEGER,
    degradation_wall_balls INTEGER,

    -- Confidence levels
    confidence_skierg VARCHAR(20),
    confidence_sled_push VARCHAR(20),
    -- ... etc

    -- Station times (seconds)
    best_skierg INTEGER,
    best_sled_push INTEGER,
    -- ... etc

    last_updated TIMESTAMP,
    sample_count INTEGER
);

CREATE TABLE daily_readiness (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    date DATE,
    hrv_ms INTEGER,
    resting_hr INTEGER,
    sleep_hours DECIMAL,
    sleep_quality INTEGER,
    readiness_score INTEGER,
    created_at TIMESTAMP
);
```

### Week 4: AI Workout Generation Engine

```typescript
// workout-generator.ts

interface WorkoutGenerationInput {
    userId: string;
    date: Date;
    sessionNumber: 1 | 2;
    userProfile: UserProfile;
    trainingArchitecture: TrainingArchitecture;
    performanceProfile: PerformanceProfile;
    readinessScore: number;
    availableDuration: number;
    equipmentToday: Equipment[];
    goal: Goal;
    recentWorkouts: Workout[];
}

interface GeneratedWorkout {
    segments: WorkoutSegment[];
    totalDuration: number;
    explanation: string;
    aiReasoning: string;
}

async function generateWorkout(input: WorkoutGenerationInput): Promise<GeneratedWorkout> {
    // 1. Determine workout type based on architecture
    const workoutType = determineWorkoutType(input);

    // 2. Calculate training phase (base/build/peak/taper)
    const phase = calculatePhase(input.goal, input.date);

    // 3. Analyze recent load and adjust intensity
    const intensity = calculateIntensity(input.recentWorkouts, input.readinessScore);

    // 4. Generate segments with personalized targets
    const segments = generateSegments(workoutType, input.performanceProfile, intensity);

    // 5. Apply equipment substitutions if needed
    const adjustedSegments = applyEquipmentSubstitutions(segments, input.equipmentToday);

    // 6. Generate explanation
    const explanation = generateExplanation(adjustedSegments, input);

    return {
        segments: adjustedSegments,
        totalDuration: calculateTotalDuration(adjustedSegments),
        explanation,
        aiReasoning: generateDetailedReasoning(input, adjustedSegments)
    };
}
```

---

## iOS Foundation

### Week 2: Project Setup & Architecture

```
iOS APP STRUCTURE:

FLEXR/
├── App/
│   ├── FLEXRApp.swift
│   └── AppDelegate.swift
├── Core/
│   ├── Models/
│   │   ├── User.swift
│   │   ├── Workout.swift
│   │   ├── Segment.swift
│   │   └── PerformanceProfile.swift
│   ├── Services/
│   │   ├── APIService.swift
│   │   ├── HealthKitService.swift
│   │   ├── WorkoutService.swift
│   │   └── SyncService.swift
│   └── Managers/
│       ├── AuthManager.swift
│       ├── WorkoutManager.swift
│       └── ProfileManager.swift
├── Features/
│   ├── Onboarding/
│   ├── Home/
│   ├── Workout/
│   ├── Progress/
│   └── Profile/
├── Components/
│   ├── Charts/
│   ├── Cards/
│   └── Common/
└── Resources/
    ├── Assets.xcassets
    └── Localizable.strings
```

### Week 3: Core Features

- [ ] User authentication (Apple Sign-in)
- [ ] Onboarding flow screens
- [ ] Training architecture setup
- [ ] API client implementation
- [ ] Local data persistence (SwiftData/CoreData)

### Week 4: HealthKit Integration

```swift
// HealthKitService.swift

class HealthKitService {

    // Permissions
    func requestAuthorization() async throws {
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .vo2Max)!,
            HKObjectType.quantityType(forIdentifier: .runningSpeed)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.workoutType()
        ]

        try await healthStore.requestAuthorization(
            toShare: [HKObjectType.workoutType()],
            read: typesToRead
        )
    }

    // Get today's readiness data
    func getReadinessData() async throws -> ReadinessData {
        async let hrv = getLatestHRV()
        async let restingHR = getRestingHR()
        async let sleep = getLastNightSleep()

        return ReadinessData(
            hrv: try await hrv,
            restingHR: try await restingHR,
            sleep: try await sleep
        )
    }

    // Stream workout data
    func startWorkoutSession(type: WorkoutType) -> AsyncStream<WorkoutDataPoint> {
        // Real-time HR, pace, distance streaming
    }
}
```

---

## watchOS Foundation

### Week 3-4: Watch App Structure

```
FLEXRWatch/
├── App/
│   └── FLEXRWatchApp.swift
├── Views/
│   ├── MainView.swift
│   ├── WorkoutListView.swift
│   ├── ActiveWorkoutView.swift
│   ├── SegmentView.swift
│   ├── RunningSegmentView.swift
│   ├── StationSegmentView.swift
│   ├── TransitionView.swift
│   └── SummaryView.swift
├── Services/
│   ├── WorkoutSessionManager.swift
│   ├── HealthKitManager.swift
│   └── PhoneConnectivity.swift
└── Models/
    └── WatchWorkout.swift
```

### Key Watch Features

```swift
// WorkoutSessionManager.swift

class WorkoutSessionManager: NSObject, ObservableObject {

    @Published var currentSegment: WorkoutSegment?
    @Published var segmentIndex: Int = 0
    @Published var heartRate: Double = 0
    @Published var currentPace: Double = 0
    @Published var distance: Double = 0
    @Published var elapsedTime: TimeInterval = 0

    private var workoutSession: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var workout: Workout?

    // Start workout with pre-loaded segments
    func startWorkout(_ workout: Workout) {
        self.workout = workout
        self.currentSegment = workout.segments.first

        let config = HKWorkoutConfiguration()
        config.activityType = .functionalStrengthTraining
        config.locationType = .indoor

        do {
            workoutSession = try HKWorkoutSession(
                healthStore: healthStore,
                configuration: config
            )
            builder = workoutSession?.associatedWorkoutBuilder()

            workoutSession?.delegate = self
            builder?.delegate = self

            workoutSession?.startActivity(with: Date())
            builder?.beginCollection(withStart: Date())

        } catch {
            // Handle error
        }
    }

    // User taps "Done" on current segment
    func completeCurrentSegment() {
        guard let segment = currentSegment else { return }

        // Save segment data
        segment.actualDuration = elapsedTime
        segment.actualDistance = distance
        segment.avgHeartRate = averageHR
        segment.maxHeartRate = maxHR
        segment.completedAt = Date()

        // Move to next segment
        segmentIndex += 1
        if segmentIndex < workout?.segments.count ?? 0 {
            currentSegment = workout?.segments[segmentIndex]
            resetSegmentMetrics()

            // Haptic feedback
            WKInterfaceDevice.current().play(.success)
        } else {
            // Workout complete
            endWorkout()
        }
    }

    // Haptic alerts for pacing
    func checkPaceAlert() {
        guard let target = currentSegment?.targetPace else { return }

        if currentPace < target.min {
            // Too fast
            WKInterfaceDevice.current().play(.notification)
        } else if currentPace > target.max {
            // Too slow
            WKInterfaceDevice.current().play(.directionUp)
        }
    }
}
```

---

# PHASE 2: CORE FEATURES (Weeks 5-8)

## Week 5-6: Workout Experience

### iPhone

- [ ] Today's workout view
- [ ] Workout detail/preview
- [ ] Workout player (basic)
- [ ] Segment navigation
- [ ] Post-workout feedback flow
- [ ] "Why this workout" explanation display

### Watch

- [ ] Workout list from phone
- [ ] Active workout display
- [ ] Running segment view (pace, HR, distance)
- [ ] Station segment view (timer, reps)
- [ ] Tap-to-complete interaction
- [ ] Transition screens
- [ ] Haptic feedback system

## Week 7-8: Data & Progress

### iPhone

- [ ] Main dashboard
- [ ] Weekly view
- [ ] Running analytics (compromised running!)
- [ ] Station analytics
- [ ] Progress charts
- [ ] HR analytics
- [ ] Single workout detail view

### Backend

- [ ] Weekly profile recalculation job
- [ ] Performance profile updates
- [ ] Trend calculations
- [ ] Race prediction engine

---

# PHASE 3: AI & INTELLIGENCE (Weeks 9-12)

## Week 9-10: AI Learning Engine

```typescript
// learning-engine.ts

interface WeeklyUpdateResult {
    profileChanges: ProfileChange[];
    newTargets: TargetUpdate[];
    insights: Insight[];
    confidence: ConfidenceUpdate[];
}

async function runWeeklyProfileUpdate(userId: string): Promise<WeeklyUpdateResult> {

    // 1. Get this week's workout data
    const weekData = await getWeekWorkoutData(userId);

    // 2. Get current profile
    const currentProfile = await getPerformanceProfile(userId);

    // 3. Filter and weight data
    const qualityData = filterAndWeightData(weekData);

    // 4. Calculate new values per station type
    const newDegradations = calculateNewDegradations(qualityData, currentProfile);

    // 5. Blend with historical (decay factor)
    const blendedProfile = blendProfiles(currentProfile, newDegradations);

    // 6. Update confidence levels
    const confidence = updateConfidenceLevels(blendedProfile, qualityData);

    // 7. Generate new targets
    const newTargets = generateTargets(blendedProfile);

    // 8. Generate insights
    const insights = generateInsights(currentProfile, blendedProfile);

    // 9. Save updated profile
    await saveProfile(userId, blendedProfile);

    // 10. Notify user
    await notifyProfileUpdate(userId, insights);

    return {
        profileChanges: getChanges(currentProfile, blendedProfile),
        newTargets,
        insights,
        confidence
    };
}
```

## Week 11-12: Advanced Features

- [ ] Readiness score calculation
- [ ] Workout adaptation based on readiness
- [ ] Equipment substitution engine
- [ ] Race prediction model
- [ ] Monthly deep analysis
- [ ] Trend detection

---

# PHASE 4: POLISH & LAUNCH (Weeks 13-16)

## Week 13-14: Testing & Refinement

- [ ] Beta testing with 50-100 users
- [ ] Bug fixes
- [ ] Performance optimization
- [ ] AI tuning based on feedback
- [ ] Watch app stability
- [ ] Sync reliability

## Week 15: Launch Prep

- [ ] App Store assets (screenshots, video)
- [ ] App Store listing copy
- [ ] Privacy policy
- [ ] Terms of service
- [ ] Website/landing page
- [ ] Social media setup

## Week 16: Launch

- [ ] App Store submission
- [ ] Launch marketing
- [ ] Influencer outreach
- [ ] Community building
- [ ] Monitor & respond

---

# MVP FEATURE CHECKLIST

## Must Have (Launch)

### Onboarding
- [x] Goal selection (train/compete)
- [ ] Training architecture setup
- [ ] Experience level
- [ ] Equipment access
- [ ] Apple Watch pairing
- [ ] HealthKit permissions

### Workout Generation
- [ ] AI generates daily workouts
- [ ] User-defined structure respected
- [ ] Equipment substitutions
- [ ] "Why this workout" explanation

### Workout Execution (iPhone)
- [ ] Today's workout view
- [ ] Workout preview
- [ ] Start/complete workout
- [ ] Post-workout feedback (RPE)

### Workout Execution (Watch)
- [ ] Receive workout from phone
- [ ] Run segment tracking (pace, HR, distance)
- [ ] Station segment tracking (time)
- [ ] Tap-to-complete segments
- [ ] Haptic pace alerts
- [ ] Workout summary

### Data & Progress
- [ ] Dashboard with key metrics
- [ ] Weekly workout view
- [ ] Compromised running analysis
- [ ] Station time tracking
- [ ] Basic charts/trends

### AI Learning
- [ ] Weekly profile updates
- [ ] Degradation tracking per station
- [ ] Target adjustments
- [ ] Confidence levels

## Nice to Have (V1.1)

- [ ] Monthly deep analysis
- [ ] Race prediction
- [ ] Advanced charts
- [ ] Workout swap/modify
- [ ] Community features
- [ ] Sharing

---

# IMMEDIATE ACTION ITEMS

## This Week (Week 1)

### Day 1 (Today)
- [ ] Create GitHub repository
- [ ] Set up project structure
- [ ] Initialize iOS project (Xcode)
- [ ] Initialize backend project (Node.js)
- [ ] Set up development environment

### Day 2
- [ ] Design database schema (finalize)
- [ ] Set up PostgreSQL database
- [ ] Create initial migrations
- [ ] Set up API project structure

### Day 3
- [ ] Start iOS app structure
- [ ] Create navigation skeleton
- [ ] Set up SwiftUI previews
- [ ] Design color palette/typography

### Day 4
- [ ] Start onboarding screens
- [ ] Build training architecture setup UI
- [ ] Create API client foundation

### Day 5
- [ ] Start watchOS app
- [ ] Basic watch navigation
- [ ] Phone ↔ Watch connectivity setup

### Day 6-7
- [ ] Authentication setup (Firebase)
- [ ] Apple Sign-in implementation
- [ ] API auth endpoints

---

# BUDGET CONSIDERATIONS

## Development Costs (Estimate)

| Item | Monthly | Duration | Total |
|------|---------|----------|-------|
| iOS Developer | $8-15K | 4 months | $32-60K |
| Backend Developer | $6-12K | 4 months | $24-48K |
| Designer | $4-8K | 2 months | $8-16K |
| **Total Dev** | | | **$64-124K** |

## Infrastructure (Monthly)

| Service | Cost |
|---------|------|
| AWS (startup) | $100-500 |
| Firebase | $0-100 |
| OpenAI API | $100-500 |
| Mixpanel | $0 (free tier) |
| RevenueCat | $0 (free tier) |
| **Total** | **$200-1100/mo** |

## Alternative: Solo/Small Team

If building with minimal team:
- You + 1 iOS developer: $32-60K
- Use no-code/low-code where possible
- Start with simpler AI (rule-based → ML later)
- MVP in 3-4 months for $40-70K

---

# SUCCESS METRICS

## Pre-Launch (Beta)

| Metric | Target |
|--------|--------|
| Beta users | 100+ |
| Completed workouts | 500+ |
| Watch workout completion rate | >80% |
| Crash-free sessions | >99% |
| NPS from beta users | >40 |

## Launch (Month 1)

| Metric | Target |
|--------|--------|
| Downloads | 1,000+ |
| Registrations | 500+ |
| Day 7 retention | >40% |
| Paid conversions | 5%+ |
| App Store rating | 4.5+ |

## Growth (Month 3)

| Metric | Target |
|--------|--------|
| Monthly Active Users | 2,000+ |
| Paid subscribers | 200+ |
| MRR | $4,000+ |
| Day 30 retention | >25% |

---

# DOCUMENTS CREATED

```
/docs/
├── strategy/
│   └── FLEXR-Strategic-Plan.md         ✅
├── research/
│   ├── hyrox-market-research-2025.md   ✅
│   ├── HYROX_TRAINING_METHODOLOGY.md   ✅
│   ├── business-model-research.md      ✅
│   └── hyrox-user-research.md          ✅
├── design/
│   ├── APP-FLOW-DESIGN.md              ✅
│   ├── RUN-STATION-SEGMENTATION.md     ✅
│   ├── WATCH-GUIDED-WORKOUT-FLOW.md    ✅
│   ├── DATA-ANALYTICS-VISUALIZATION.md ✅
│   └── AI-LEARNING-METHODOLOGY.md      ✅
└── PROJECT-KICKOFF.md                  ✅ (this file)
```

---

# LET'S GO! 🚀

You have everything documented. Now execute:

1. **Today:** Set up repos, start coding
2. **This week:** Foundation in place
3. **Month 1:** Core features working
4. **Month 2:** Watch integration complete
5. **Month 3:** AI learning operational
6. **Month 4:** Beta launch
7. **Month 5:** App Store launch

**The market is waiting. No one else is doing this. Build it.**

---

*Document Version: 1.0*
*Created: December 2025*
*Status: PROJECT KICKOFF - READY TO BUILD*
