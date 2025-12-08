# FLEXR Social Features - Implementation Plan

## IMMEDIATE FIXES (This Week)

### 1. Enforce Single Race Partner Constraint

**Backend Change:**
```sql
-- File: backend/src/migrations/supabase/016_single_race_partner_constraint.sql

-- Add constraint to ensure only 1 active race partner
CREATE OR REPLACE FUNCTION check_single_race_partner()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.relationship_type = 'race_partner' AND NEW.status = 'accepted' THEN
    IF EXISTS (
      SELECT 1 FROM user_relationships
      WHERE (user_a_id = NEW.user_a_id OR user_b_id = NEW.user_a_id)
        AND relationship_type = 'race_partner'
        AND status = 'accepted'
        AND id != NEW.id
    ) THEN
      RAISE EXCEPTION 'User can only have one active race partner';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_single_race_partner
  BEFORE INSERT OR UPDATE ON user_relationships
  FOR EACH ROW
  EXECUTE FUNCTION check_single_race_partner();
```

**iOS Change:**
```swift
// File: RelationshipService.swift

func upgradeRelationship(withUserId userId: UUID, to type: RelationshipType) async throws -> UserRelationship {
    // Check for existing race partner before upgrading
    if type == .racePartner {
        let existing = try await getUserRelationships(type: .racePartner, status: .accepted)
        if !existing.isEmpty {
            throw RelationshipError.alreadyHasRacePartner
        }
    }

    // Continue with upgrade...
}

enum RelationshipError: Error {
    case alreadyHasRacePartner
    case subscriptionRequired
    case userNotFound

    var message: String {
        switch self {
        case .alreadyHasRacePartner:
            return "You can only have one race partner. Remove your current partner first."
        case .subscriptionRequired:
            return "Race Partner feature requires Partner Plan subscription."
        case .userNotFound:
            return "User not found."
        }
    }
}
```

### 2. Add Gym Creation Flow

**New View: GymCreationView.swift**
```swift
struct GymCreationView: View {
    @State private var gymName = ""
    @State private var gymType: GymType = .crossfit
    @State private var address = ""
    @State private var city = ""
    @State private var state = ""
    @State private var country = ""
    @State private var postalCode = ""
    @State private var isPublic = true
    @State private var allowAutoJoin = false
    @State private var description = ""

    // Contact info
    @State private var website = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var instagram = ""

    var body: some View {
        Form {
            Section("Basic Information") {
                TextField("Gym Name", text: $gymName)
                Picker("Gym Type", selection: $gymType) {
                    ForEach(GymType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                TextField("Description", text: $description, axis: .vertical)
                    .lineLimit(3...5)
            }

            Section("Location") {
                TextField("Street Address", text: $address)
                TextField("City", text: $city)
                TextField("State/Province", text: $state)
                TextField("Country", text: $country)
                TextField("Postal Code", text: $postalCode)
            }

            Section("Contact Information") {
                TextField("Website", text: $website)
                    .textContentType(.URL)
                TextField("Phone", text: $phone)
                    .textContentType(.telephoneNumber)
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                TextField("Instagram Handle", text: $instagram)
            }

            Section("Privacy & Access") {
                Toggle("Public (visible in search)", isOn: $isPublic)
                Toggle("Auto-approve members", isOn: $allowAutoJoin)

                if !allowAutoJoin {
                    Text("You'll need to manually approve member requests")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button("Create Gym") {
                    Task { await createGym() }
                }
                .disabled(gymName.isEmpty || city.isEmpty)
            }
        }
        .navigationTitle("Create Gym")
    }

    private func createGym() async {
        // Implementation
    }
}
```

**Update GymSearchView** to include "Create Gym" option:
```swift
// Add toolbar item
.toolbar {
    ToolbarItem(placement: .primaryAction) {
        NavigationLink {
            GymCreationView()
        } label: {
            Image(systemName: "plus")
        }
    }
}
```

### 3. Rename "Social" to "Gym" (Better UX)

**Changes:**
```swift
// ContentView.swift
enum Tab {
    case today
    case train
    case analytics
    case gym     // Changed from 'social'
    case profile
}

// Tab label
Label("Gym", systemImage: "building.2.fill")

// Navigation title in SocialHubView
.navigationTitle("My Gym")  // Changed from "Social"
```

### 4. Gym Admin Panel (Basic)

**New View: GymAdminView.swift**
```swift
struct GymAdminView: View {
    let gym: Gym

    @State private var pendingMembers: [GymMember] = []
    @State private var activeMembers: [GymMember] = []

    var body: some View {
        List {
            Section("Pending Requests") {
                if pendingMembers.isEmpty {
                    Text("No pending requests")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(pendingMembers) { member in
                        PendingMemberRow(
                            member: member,
                            onApprove: { await approveMember(member) },
                            onReject: { await rejectMember(member) }
                        )
                    }
                }
            }

            Section("Active Members (\(activeMembers.count))") {
                ForEach(activeMembers) { member in
                    MemberRow(member: member)
                }
            }

            Section("Gym Settings") {
                NavigationLink("Edit Gym Info") {
                    GymEditView(gym: gym)
                }

                NavigationLink("Privacy Settings") {
                    GymPrivacySettingsView(gym: gym)
                }
            }
        }
        .navigationTitle("\(gym.name) Admin")
    }
}

struct PendingMemberRow: View {
    let member: GymMember
    let onApprove: () async -> Void
    let onReject: () async -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(member.displayName)
                    .font(.headline)

                HStack {
                    Label(member.fitnessLevel.displayName, systemImage: "figure.run")
                    if let goal = member.primaryGoal {
                        Label(goal, systemImage: "target")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 12) {
                Button {
                    Task { await onReject() }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                }

                Button {
                    Task { await onApprove() }
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            .font(.title2)
        }
    }
}
```

---

## PHASE 2: RUNNING ANALYTICS (Next 2 Weeks)

### Database Schema

```sql
-- File: backend/src/migrations/supabase/017_running_analytics.sql

CREATE TYPE running_session_type AS ENUM (
  'long_run',
  'intervals',
  'threshold',
  'time_trial_5k',
  'time_trial_10k',
  'recovery',
  'easy'
);

CREATE TABLE running_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  gym_id UUID REFERENCES gyms(id),

  -- Session details
  session_type running_session_type NOT NULL,
  workout_id UUID REFERENCES workout_sessions(id),

  -- Basic metrics
  distance_meters INT NOT NULL,
  duration_seconds INT NOT NULL,
  elevation_gain_meters INT,

  -- Pace data
  avg_pace_per_km NUMERIC NOT NULL,  -- seconds per km
  fastest_km_pace NUMERIC,
  slowest_km_pace NUMERIC,

  -- Heart rate
  avg_heart_rate INT,
  max_heart_rate INT,
  heart_rate_zones JSONB,  -- Time in each zone

  -- Detailed data
  splits JSONB,  -- km-by-km breakdown
  route_data JSONB,  -- GPS coordinates if available

  -- Analysis
  pace_consistency NUMERIC,  -- Standard deviation
  fade_factor NUMERIC,  -- % slower in second half

  -- Metadata
  created_at TIMESTAMP DEFAULT NOW(),
  started_at TIMESTAMP,
  ended_at TIMESTAMP,

  -- Privacy
  visibility VARCHAR(20) DEFAULT 'gym' CHECK (visibility IN ('private', 'friends', 'gym', 'public'))
);

CREATE INDEX idx_running_sessions_user ON running_sessions(user_id);
CREATE INDEX idx_running_sessions_gym ON running_sessions(gym_id);
CREATE INDEX idx_running_sessions_type ON running_sessions(session_type);
CREATE INDEX idx_running_sessions_date ON running_sessions(created_at DESC);

-- Interval-specific table
CREATE TABLE interval_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  running_session_id UUID REFERENCES running_sessions(id) ON DELETE CASCADE,

  -- Interval structure
  work_distance_meters INT,
  rest_duration_seconds INT,
  target_pace_per_km NUMERIC,
  total_reps INT,

  -- Performance
  intervals JSONB, -- [{rep: 1, distance: 400, time: 75, pace: 3.125, hr_avg: 175}, ...]

  -- Analysis
  avg_work_pace NUMERIC,
  pace_drop_off NUMERIC,  -- % slower on last rep vs first
  recovery_quality NUMERIC  -- Avg HR drop during rest
);
```

### iOS Models

```swift
// File: RunningSession.swift

struct RunningSession: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let gymId: UUID?
    let sessionType: RunningSessionType
    let workoutId: UUID?

    // Metrics
    let distanceMeters: Int
    let durationSeconds: TimeInterval
    let elevationGainMeters: Int?

    // Pace
    let avgPacePerKm: TimeInterval
    let fastestKmPace: TimeInterval?
    let slowestKmPace: TimeInterval?

    // Heart Rate
    let avgHeartRate: Int?
    let maxHeartRate: Int?
    let heartRateZones: HeartRateZones?

    // Detailed data
    let splits: [Split]
    let routeData: RouteData?

    // Analysis
    let paceConsistency: Double?
    let fadeFactor: Double?  // 0.15 = 15% slower in second half

    let createdAt: Date
    let visibility: ActivityVisibility

    var displayDistance: String {
        let km = Double(distanceMeters) / 1000.0
        return String(format: "%.2f km", km)
    }

    var displayPace: String {
        let mins = Int(avgPacePerKm) / 60
        let secs = Int(avgPacePerKm) % 60
        return String(format: "%d:%02d /km", mins, secs)
    }

    var displayDuration: String {
        let hours = Int(durationSeconds) / 3600
        let minutes = (Int(durationSeconds) % 3600) / 60
        let seconds = Int(durationSeconds) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

enum RunningSessionType: String, Codable {
    case longRun = "long_run"
    case intervals
    case threshold
    case timeTrial5k = "time_trial_5k"
    case timeTrial10k = "time_trial_10k"
    case recovery
    case easy
}

struct Split: Codable {
    let km: Int
    let timeSeconds: TimeInterval
    let pacePerKm: TimeInterval
    let heartRate: Int?
    let elevationGain: Int?

    var displayPace: String {
        let mins = Int(pacePerKm) / 60
        let secs = Int(pacePerKm) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

struct HeartRateZones: Codable {
    let zone1Seconds: TimeInterval  // Recovery (<60% max)
    let zone2Seconds: TimeInterval  // Aerobic (60-70%)
    let zone3Seconds: TimeInterval  // Tempo (70-80%)
    let zone4Seconds: TimeInterval  // Threshold (80-90%)
    let zone5Seconds: TimeInterval  // Max (90%+)

    var totalTime: TimeInterval {
        zone1Seconds + zone2Seconds + zone3Seconds + zone4Seconds + zone5Seconds
    }

    func percentInZone(_ zone: Int) -> Double {
        let time: TimeInterval
        switch zone {
        case 1: time = zone1Seconds
        case 2: time = zone2Seconds
        case 3: time = zone3Seconds
        case 4: time = zone4Seconds
        case 5: time = zone5Seconds
        default: return 0
        }
        return (time / totalTime) * 100
    }
}

struct IntervalSession: Codable {
    let workDistanceMeters: Int
    let restDurationSeconds: TimeInterval
    let targetPacePerKm: TimeInterval
    let totalReps: Int

    let intervals: [IntervalRep]

    // Calculated
    let avgWorkPace: TimeInterval
    let paceDropOff: Double  // % slower on last vs first
    let recoveryQuality: Double  // How well HR recovered

    var displayTargetPace: String {
        let mins = Int(targetPacePerKm) / 60
        let secs = Int(targetPacePerKm) % 60
        return String(format: "%d:%02d /km", mins, secs)
    }
}

struct IntervalRep: Codable {
    let rep: Int
    let distanceMeters: Int
    let timeSeconds: TimeInterval
    let pacePerKm: TimeInterval
    let avgHeartRate: Int?

    var displayPace: String {
        let mins = Int(pacePerKm) / 60
        let secs = Int(pacePerKm) % 60
        return String(format: "%d:%02d /km", mins, secs)
    }
}
```

### UI: Running Analytics View

```swift
// File: RunningAnalyticsView.swift

struct RunningAnalyticsView: View {
    let gymId: UUID

    @State private var sessions: [RunningSession] = []
    @State private var selectedType: RunningSessionType?

    var body: some View {
        List {
            Section("My Recent Runs") {
                ForEach(sessions.prefix(5)) { session in
                    NavigationLink {
                        RunningSessionDetailView(session: session)
                    } label: {
                        RunningSessionRow(session: session)
                    }
                }
            }

            Section("Gym Leaderboards") {
                NavigationLink("Long Runs") {
                    GymRunningLeaderboardView(
                        gymId: gymId,
                        type: .longRun
                    )
                }

                NavigationLink("Fastest 5K") {
                    GymRunningLeaderboardView(
                        gymId: gymId,
                        type: .timeTrial5k
                    )
                }

                NavigationLink("Fastest 10K") {
                    GymRunningLeaderboardView(
                        gymId: gymId,
                        type: .timeTrial10k
                    )
                }
            }
        }
        .navigationTitle("Running Analytics")
    }
}

struct RunningSessionRow: View {
    let session: RunningSession

    var body: some View {
        HStack {
            Image(systemName: session.sessionType.icon)
                .font(.title2)
                .foregroundStyle(session.sessionType.color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.sessionType.displayName)
                    .font(.headline)

                HStack(spacing: 12) {
                    Label(session.displayDistance, systemImage: "figure.run")
                    Label(session.displayPace, systemImage: "timer")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text(session.displayDuration)
                    .font(.title3)

                Text(session.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
```

---

## SUMMARY OF CHANGES

### Week 1 (Immediate)
- [ ] Add single race partner constraint (backend + iOS)
- [ ] Create GymCreationView
- [ ] Add gym creation to GymSearchView
- [ ] Rename "Social" tab to "Gym"
- [ ] Build GymAdminView for gym owners/admins
- [ ] Fix title duplication (✅ already done)

### Week 2 (Running Analytics)
- [ ] Create running analytics database tables
- [ ] Build iOS models for running sessions
- [ ] Create RunningAnalyticsView
- [ ] Implement gym running leaderboards
- [ ] Add running session detail view
- [ ] Integrate with HealthKit for automatic run import

### Week 3-4 (Partner Features)
- [ ] Add subscription tier to users table
- [ ] Build subscription check logic
- [ ] Create shared training plan models
- [ ] Build partner comparison dashboard
- [ ] Add partner workout sync
- [ ] Create partner analytics views

This is a data-driven performance platform, not a social network. Every feature should answer: "Does this make athletes faster?"
