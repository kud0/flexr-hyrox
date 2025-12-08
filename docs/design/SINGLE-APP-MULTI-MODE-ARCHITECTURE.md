# FLEXR Single-App Multi-Mode Architecture
## How to Build One App That Expands to Multiple Training Modes

**Strategy:** Launch as HYROX-focused, expand to gym/running modes later
**Domain:** flexr.app (no subdomains)
**Architecture:** Single codebase, mode-based content switching

---

## ✅ THIS IS THE RIGHT APPROACH

**Why this works:**
- ✅ Launch fast with HYROX focus
- ✅ Add modes incrementally (not all at once)
- ✅ Shared infrastructure (AI, HealthKit, Watch app)
- ✅ Single brand identity
- ✅ Cross-sell opportunities (HYROX athlete → add gym mode)
- ✅ No Under Armour multi-app failure risk

**Similar successful examples:**
- Nike Training Club (running, strength, yoga, mobility in ONE app)
- Peloton App (bike, tread, strength, yoga, meditation in ONE app)
- Apple Fitness+ (HIIT, strength, yoga, cycling, etc. in ONE app)

---

## 🏗️ TECHNICAL ARCHITECTURE

### Phase 1: Launch (HYROX Focus - Months 1-6)

```swift
// User Profile Model
struct User {
    var id: UUID
    var name: String
    var email: String

    // Training Mode (single mode at launch)
    var trainingMode: TrainingMode = .hyrox

    // HYROX-specific
    var hyroxProfile: HyroxProfile?

    // Future modes (optional, nil at launch)
    var gymProfile: GymProfile? = nil
    var runningProfile: RunningProfile? = nil
}

enum TrainingMode: String, Codable {
    case hyrox    // Launch mode
    case gym      // Phase 2
    case running  // Phase 3
    case nutrition  // Phase 4
}

// HYROX Profile (fully built)
struct HyroxProfile {
    var fitnessLevel: FitnessLevel
    var targetRaceDate: Date?
    var targetTime: TimeInterval?
    var division: HyroxDivision
    var weakStations: [HyroxStation]
    var equipmentAccess: EquipmentAccess
}

// Gym Profile (stub for future)
struct GymProfile {
    // TODO: Phase 2
    // var goals: [GymGoal]
    // var experience: ExperienceLevel
    // etc.
}
```

**Launch Experience:**
- User signs up → Onboarding asks HYROX-specific questions
- Training mode is LOCKED to `.hyrox` (no mode picker yet)
- All features built for HYROX
- Gym/running UI doesn't exist yet

---

### Phase 2: Add Gym Mode (Months 7-12)

```swift
// Onboarding Flow
struct OnboardingView: View {
    @State private var selectedMode: TrainingMode = .hyrox

    var body: some View {
        VStack {
            Text("What are you training for?")

            // Mode Selection (NOW VISIBLE)
            TrainingModeSelector(selection: $selectedMode)

            // Conditional onboarding based on mode
            switch selectedMode {
            case .hyrox:
                HyroxOnboardingFlow()
            case .gym:
                GymOnboardingFlow()  // NEW
            case .running:
                Text("Coming Soon")  // Future
            case .nutrition:
                Text("Coming Soon")  // Future
            }
        }
    }
}

// Mode Selector Component
struct TrainingModeSelector: View {
    @Binding var selection: TrainingMode

    var body: some View {
        VStack(spacing: 16) {
            ModeCard(
                mode: .hyrox,
                title: "HYROX",
                subtitle: "Race preparation & performance",
                icon: "hexagon.fill",
                color: .green,
                isSelected: selection == .hyrox
            )

            ModeCard(
                mode: .gym,
                title: "Gym",
                subtitle: "Strength & functional fitness",
                icon: "dumbbell.fill",
                color: .blue,
                isSelected: selection == .gym
            )

            // Add more modes as you build them
        }
    }
}
```

**User Experience:**
1. New users: See mode selection during onboarding
2. Existing HYROX users: See "Add Gym Mode" in settings
3. AI generates workouts based on selected mode
4. Can switch modes or use multiple simultaneously

---

### Phase 3: Multi-Mode Support (Year 2)

```swift
// Updated User Profile
struct User {
    // User can now have MULTIPLE active modes
    var activeModes: Set<TrainingMode> = [.hyrox]

    // Profiles for each mode
    var hyroxProfile: HyroxProfile?
    var gymProfile: GymProfile?
    var runningProfile: RunningProfile?
    var nutritionProfile: NutritionProfile?

    // Preference for primary mode (for dashboard)
    var primaryMode: TrainingMode = .hyrox
}

// AI Workout Generation
class WorkoutGenerator {
    func generateWorkout(for user: User, mode: TrainingMode) -> Workout {
        switch mode {
        case .hyrox:
            return generateHyroxWorkout(profile: user.hyroxProfile!)
        case .gym:
            return generateGymWorkout(profile: user.gymProfile!)
        case .running:
            return generateRunningWorkout(profile: user.runningProfile!)
        case .nutrition:
            return generateMealPlan(profile: user.nutritionProfile!)
        }
    }

    private func generateHyroxWorkout(profile: HyroxProfile) -> Workout {
        // Your existing HYROX AI logic
        // Dynamic generation based on:
        // - User structure (days/week, sessions/day)
        // - Apple Watch data
        // - Weakness targeting
        // - Race timeline
    }

    private func generateGymWorkout(profile: GymProfile) -> Workout {
        // NEW: Gym-specific AI logic
        // Generate based on:
        // - Goal (strength, hypertrophy, endurance)
        // - Experience level
        // - Available equipment
        // - Training split preference
    }
}
```

---

## 🎨 UI/UX ARCHITECTURE

### Navigation Structure

```
App Root
├── Tab 1: Home/Dashboard
│   ├── Mode-specific dashboard
│   ├── Today's workout (from active mode)
│   └── Quick stats
│
├── Tab 2: Training
│   ├── Workout calendar
│   ├── Mode filter (HYROX | Gym | Running)
│   ├── Workout player
│   └── History
│
├── Tab 3: Progress
│   ├── Mode-specific analytics
│   ├── Station/exercise tracking
│   ├── PRs and achievements
│   └── Body metrics
│
├── Tab 4: Community
│   ├── Mode-specific challenges
│   ├── Leaderboards per mode
│   ├── Activity feed
│   └── Friends
│
└── Tab 5: Profile
    ├── Active Modes (toggle on/off)
    ├── Settings per mode
    ├── Subscription management
    └── Account settings
```

---

### Home Dashboard (Mode-Aware)

```swift
struct HomeView: View {
    @EnvironmentObject var user: User

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Mode Indicator (if multiple modes active)
                if user.activeModes.count > 1 {
                    ModeToggle(
                        modes: user.activeModes,
                        selected: $user.primaryMode
                    )
                }

                // Mode-Specific Hero Section
                switch user.primaryMode {
                case .hyrox:
                    HyroxHeroCard()  // Race countdown, next workout
                case .gym:
                    GymHeroCard()    // Workout plan, progress
                case .running:
                    RunningHeroCard()  // Week mileage, next run
                case .nutrition:
                    NutritionHeroCard()  // Meal plan, macros
                }

                // Today's Workout (mode-specific)
                TodayWorkoutCard(mode: user.primaryMode)

                // Quick Stats (mode-specific)
                QuickStatsGrid(mode: user.primaryMode)

                // Recent Activity (across all active modes)
                RecentActivitySection(modes: user.activeModes)
            }
        }
    }
}
```

---

## 💰 MONETIZATION PER MODE

### Subscription Tiers with Mode Access

```
TRACK: €5.99/month
├── Analytics only (all modes)
└── No AI training

ATHLETE: €19.99/month
├── Choose 1 mode (HYROX OR Gym OR Running)
├── Full AI training for chosen mode
└── Can switch mode once per month

PRO: €34.99/month
├── ALL modes included
├── Video analysis
├── Race predictor
├── Advanced analytics
└── Priority support

DUO: €30-40/month
├── 2 Athlete accounts
├── Each person picks 1 mode
└── Can be different modes
```

**Why this works:**
- ✅ Natural upgrade path (Athlete 1 mode → Pro all modes)
- ✅ Users pay for what they use
- ✅ Incentive to upgrade when wanting 2+ modes
- ✅ Clear value proposition

---

## 🚀 LAUNCH ROADMAP

### Month 1-6: HYROX Launch
```
Product:
✅ HYROX mode fully built
✅ AI workout generation (HYROX-specific)
✅ Apple Watch integration
✅ User-defined training architecture
✅ Equipment substitutions
✅ Community features

Marketing:
✅ Brand: "FLEXR for HYROX Training"
✅ Positioning: "AI-Powered HYROX Training"
✅ Target: HYROX athletes only
✅ Domain: flexr.app (HYROX-focused)

App:
✅ Training mode LOCKED to .hyrox
✅ No mode picker visible yet
✅ Architecture supports future modes (but hidden)
```

---

### Month 7-12: Gym Mode Beta
```
Product:
✅ Gym profile onboarding
✅ Gym workout generation (strength, hypertrophy, endurance)
✅ Exercise library (200+ gym exercises)
✅ Training split support (PPL, Upper/Lower, Full Body)
✅ Progressive overload tracking
✅ Equipment customization (home gym, commercial gym)

Marketing:
✅ Announcement: "FLEXR expands to Gym Training"
✅ Beta testers: Existing HYROX users who cross-train
✅ Positioning: "Multi-sport training platform"
✅ Target: Functional fitness / CrossFit athletes

App:
✅ Mode picker now visible in onboarding
✅ Existing users see "Add Gym Mode" prompt
✅ Settings: Toggle between modes
✅ Dashboard adapts based on primary mode
```

---

### Year 2: Running & Nutrition Modes
```
Product:
✅ Running mode (race training, base building, speed work)
✅ Nutrition mode (meal planning, macro tracking, recipes)
✅ Mode combinations (HYROX + Gym, Running + Nutrition)
✅ AI learns cross-mode patterns

Marketing:
✅ "FLEXR: Complete Training Ecosystem"
✅ "Train Your Way: HYROX, Gym, Running, Nutrition"
✅ Expand target market significantly

App:
✅ Multi-mode dashboard
✅ Cross-mode analytics
✅ PRO tier value clear (all modes included)
```

---

## 🎯 BRANDING STRATEGY PER PHASE

### Phase 1: HYROX-Focused Brand

**flexr.app:**
- Hero: "AI-Powered HYROX Training"
- Subheadline: "Train Smarter. Race Faster."
- Imagery: 100% HYROX athletes, races, stations
- Messaging: HYROX-specific throughout

**App Icon:**
- F-Power design (angular F)
- Neon green (#00FF41) + black
- No mode indicators yet

**App Store:**
- Title: "FLEXR: HYROX Training"
- Subtitle: "AI-Powered Race Preparation"
- Keywords: HYROX, functional fitness, race training

---

### Phase 2: Multi-Mode Expansion

**flexr.app:**
- Hero: "AI Training for Every Athlete"
- Subheadline: "HYROX. Gym. Running. Your Way."
- Imagery: Mix of workout types
- Section per mode explaining features

**App Icon:**
- Same F-Power base
- Subtle mode indicators (small icons) in corners?
- OR keep simple, let sub-brands differentiate

**App Store:**
- Title: "FLEXR: AI Training Platform"
- Subtitle: "HYROX, Gym & Running Programs"
- Keywords: HYROX, gym training, running coach, AI fitness

---

## 🔧 TECHNICAL IMPLEMENTATION TIPS

### 1. Feature Flags for Modes

```swift
enum FeatureFlag {
    static let gymModeEnabled = false  // Set true when ready
    static let runningModeEnabled = false
    static let nutritionModeEnabled = false
}

// In UI:
if FeatureFlag.gymModeEnabled {
    // Show gym mode option
}
```

**Benefits:**
- ✅ Build gym mode in codebase without exposing to users
- ✅ Test internally before launch
- ✅ Roll out gradually (beta testers first)
- ✅ Easy to disable if issues found

---

### 2. Shared Components, Mode-Specific Content

```swift
// Shared UI Components
struct WorkoutPlayerView: View {
    let workout: Workout  // Generic workout model

    // Works for HYROX, Gym, Running
    // Adapts UI based on workout.mode
}

// Mode-Specific Content
protocol WorkoutContent {
    var mode: TrainingMode { get }
    var exercises: [Exercise] { get }
    var duration: TimeInterval { get }
}

struct HyroxWorkout: WorkoutContent {
    let mode = TrainingMode.hyrox
    var stations: [HyroxStation]
    var runs: [RunSegment]
    // HYROX-specific
}

struct GymWorkout: WorkoutContent {
    let mode = TrainingMode.gym
    var sets: [ExerciseSet]
    var restPeriods: [TimeInterval]
    // Gym-specific
}
```

---

### 3. AI Model Architecture

```
AI Core Engine (shared)
├── User data processing
├── Apple Watch integration
├── Readiness scoring (HRV, sleep)
├── Weekly learning cycles
└── Monthly planning

Mode-Specific AI Modules
├── HYROX AI
│   ├── Station weakness detection
│   ├── Race-specific pacing
│   ├── Compromised running models
│   └── HYROX periodization
│
├── Gym AI (Phase 2)
│   ├── Progressive overload
│   ├── Volume/intensity balance
│   ├── Recovery optimization
│   └── Split selection
│
└── Running AI (Phase 3)
    ├── Race-specific plans
    ├── Base building
    ├── Speed work prescription
    └── Injury prevention
```

**Benefits:**
- ✅ Shared learnings (HRV patterns, sleep impact, etc.)
- ✅ Mode-specific expertise where needed
- ✅ Efficient development (don't rebuild everything)

---

## 📊 SUCCESS METRICS PER PHASE

### Phase 1 (HYROX) - Month 1-6
- [ ] 1,000 paid HYROX users
- [ ] 20%+ Day 30 retention
- [ ] 7%+ trial-to-paid conversion
- [ ] NPS 40+
- [ ] Clear PMF signals

### Phase 2 (Add Gym) - Month 7-12
- [ ] 200+ gym mode users (beta)
- [ ] 15%+ of HYROX users add gym mode
- [ ] Gym mode retention matches HYROX
- [ ] Cross-mode users have higher LTV
- [ ] No negative impact on HYROX core

### Phase 3 (Scale Multi-Mode) - Year 2
- [ ] 5,000 total users across all modes
- [ ] 25%+ using multiple modes
- [ ] PRO tier upgrades (all modes) at 20%+
- [ ] Each mode has distinct content/value
- [ ] No mode cannibalization

---

## ✅ FINAL RECOMMENDATIONS

### How to Build This RIGHT:

**1. Architecture from Day 1:**
```swift
// Build mode enum and profile structs NOW
enum TrainingMode { case hyrox, gym, running, nutrition }

// But only implement HYROX content
// Leave others as stubs with "Coming Soon"
```

**2. UI Design:**
- Design mode picker UI NOW (but hide it)
- Use feature flags to control visibility
- Test internally with gym mode before public launch

**3. Launch Messaging:**
- **Phase 1:** "FLEXR for HYROX Training" (focused)
- **Phase 2:** "FLEXR: HYROX & Gym Training" (expansion clear)
- **Phase 3:** "FLEXR: Complete Training Platform" (ecosystem)

**4. Domain Strategy:**
- ✅ **flexr.app** (primary domain, all modes)
- ✅ **/hyrox**, **/gym**, **/running** (URL paths for SEO)
- ❌ **NOT** hyrox.flexr.app (subdomains = separate apps feel)

**5. Pricing:**
- Launch: Athlete (1 mode) + Pro (all modes)
- Athlete = €19.99 (HYROX only at launch)
- Pro = €34.99 (future-proofed for multi-mode)
- When gym launches: Pro value becomes obvious

---

## 🎯 YOUR QUESTION ANSWERED

> "i think for now we will use flexr.app as hyrox but we have the ability in short term to make a 'gym' one. how would you do it?"

**EXACTLY LIKE THIS:**

1. ✅ **Launch flexr.app as HYROX-focused** (Month 1-6)
   - Marketing, messaging, content = 100% HYROX
   - Architecture supports modes (hidden)
   - Users don't see mode picker yet

2. ✅ **Build gym mode in codebase** (Month 4-9)
   - Use feature flags to hide from production
   - Test internally with beta users
   - Develop AI, content, UI in parallel to HYROX

3. ✅ **Launch gym mode expansion** (Month 7-12)
   - Enable feature flag → mode picker appears
   - Announce expansion ("FLEXR now supports Gym Training!")
   - Existing users see "Add Gym Mode" in settings
   - New users choose mode during onboarding

4. ✅ **Scale multi-mode platform** (Year 2+)
   - Add running, nutrition modes
   - Position as complete training ecosystem
   - PRO tier = access to all modes
   - Cross-mode analytics and insights

---

**This is THE RIGHT WAY to do multi-vertical.** You're not building 4 separate apps (Under Armour failure), you're building ONE flexible platform that expands intelligently.

---

**Document Version:** 1.0
**Status:** Ready for Implementation
**Next Action:** Build HYROX mode first, add gym mode in 6-9 months
