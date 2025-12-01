# FLEXR - HYROX Training App

AI-powered HYROX training for iPhone and Apple Watch. The only app that truly understands compromised running.

## Features

- **AI-Native Workout Generation**: Every workout generated dynamically by Grok AI based on your data
- **Compromised Running Analytics**: Track how your pace degrades after each station
- **Apple Watch Integration**: Full workout tracking with segment switching
- **Bring Your Own Program**: Use your own training plan with our world-class tracking
- **Weekly AI Learning**: Your profile improves every week based on your performance

## Tech Stack

- **iOS/watchOS**: SwiftUI, HealthKit, WatchConnectivity
- **Backend**: Supabase (Database, Auth, Edge Functions)
- **AI**: Grok AI (x.ai) via `grok-4-1-fast-non-reasoning`
- **Push Notifications**: APNs via Supabase Edge Functions

## Project Structure

```
FLEXR/
├── ios/
│   ├── FLEXR/                    # iOS App
│   │   ├── Sources/
│   │   │   ├── App/              # Main app files
│   │   │   ├── Core/
│   │   │   │   ├── Models/       # Data models
│   │   │   │   └── Services/     # HealthKit, Supabase
│   │   │   ├── Features/         # Feature modules
│   │   │   └── UI/               # Components, styles
│   │   └── FLEXR.xcodeproj
│   └── FLEXRWatch/               # watchOS App
│       └── Sources/
├── supabase/
│   ├── functions/                # Edge Functions
│   │   ├── generate-workout/     # AI workout generation
│   │   ├── weekly-learning/      # Profile updates
│   │   ├── get-insights/         # AI insights
│   │   └── send-notification/    # Push notifications
│   ├── migrations/               # Database schema
│   └── config.toml
├── docs/
│   ├── design/                   # Design documents
│   └── strategy/                 # Business strategy
└── backend/                      # Legacy Node.js (optional)
```

## Quick Start

### Prerequisites

- Xcode 15+
- Supabase CLI (`brew install supabase/tap/supabase`)
- Node.js 18+ (for local Supabase)

### 1. Clone the repository

```bash
git clone git@github.com:kud0/flexr-hyrox.git
cd flexr-hyrox
```

### 2. Set up Supabase

```bash
# Login to Supabase
supabase login

# Link to your project (or create new one at supabase.com)
supabase link --project-ref your-project-ref

# Push database schema
supabase db push

# Deploy Edge Functions
supabase functions deploy generate-workout
supabase functions deploy weekly-learning
supabase functions deploy get-insights
supabase functions deploy send-notification
```

### 3. Configure Environment Variables

In your Supabase dashboard, go to Settings > Edge Functions and add:

```
GROK_API_KEY=your-grok-api-key
APNS_KEY_ID=your-apns-key-id
APNS_TEAM_ID=your-apple-team-id
APNS_PRIVATE_KEY=your-apns-private-key
APNS_BUNDLE_ID=com.flexr.app
```

### 4. Configure iOS App

Update `ios/FLEXR/Sources/Core/Services/SupabaseService.swift`:

```swift
enum SupabaseConfig {
    static let url = URL(string: "https://your-project.supabase.co")!
    static let anonKey = "your-anon-key"
}
```

Or use environment variables in your Xcode scheme.

### 5. Open in Xcode

```bash
open ios/FLEXR.xcodeproj
```

### 6. Configure Signing

1. Select the FLEXR target
2. Go to Signing & Capabilities
3. Select your Team
4. Update Bundle Identifier if needed

### 7. Run the app

- Select your device/simulator
- Press Cmd+R to build and run

## Supabase Edge Functions

### generate-workout

Generates AI-powered workouts using Grok.

```typescript
// Request
{
  "user_id": "uuid",
  "readiness_score": 75,
  "workout_type": "full_simulation" // optional
}

// Response
{
  "success": true,
  "workout": {
    "id": "uuid",
    "name": "Full HYROX Simulation",
    "segments": [...]
  }
}
```

### weekly-learning

Updates user performance profiles with weekly training data.

```typescript
// Request
{
  "user_id": "uuid"
}

// Response
{
  "success": true,
  "updated": true,
  "summary": {
    "workouts_processed": 5,
    "fresh_run_pace_change": -0.05
  }
}
```

### get-insights

Generates AI insights about training.

```typescript
// Request
{
  "user_id": "uuid",
  "insight_type": "weekly_summary" | "training_balance" | "race_readiness" | "recovery" | "compromised_running"
}
```

## Database Schema

Key tables:

- `users` - User profiles and preferences
- `training_architectures` - User-defined training structure
- `workouts` - All workouts (AI-generated and custom)
- `workout_segments` - Individual exercises within workouts
- `performance_profiles` - AI-learned user performance data
- `weekly_summaries` - Aggregated weekly training data
- `custom_workout_templates` - BYOP templates
- `custom_programs` - Multi-week training programs

## Subscription Tiers

| Feature | Free | Tracker ($9.99) | AI-Powered ($19.99) |
|---------|------|-----------------|---------------------|
| Workout Tracking | 3/month | Unlimited | Unlimited |
| Apple Watch | Basic | Full | Full |
| Custom Workouts | ❌ | ✅ | ✅ |
| AI Generation | ❌ | ❌ | ✅ |
| Compromised Running | Preview | Full | Full |
| AI Insights | ❌ | Read-only | Full |
| Program Builder | ❌ | ✅ | ✅ |

## Development

### Running locally

```bash
# Start Supabase locally
supabase start

# Test Edge Functions locally
supabase functions serve generate-workout --env-file .env.local
```

### Testing

```bash
# iOS tests
xcodebuild test -scheme FLEXR -destination 'platform=iOS Simulator,name=iPhone 15'
```

## API Keys Required

1. **Supabase**: Create project at [supabase.com](https://supabase.com)
2. **Grok AI**: Get API key from [x.ai](https://x.ai)
3. **Apple Developer**: For Sign in with Apple and APNs

## Documentation

- [Strategic Plan](docs/strategy/FLEXR-Strategic-Plan.md)
- [App Flow Design](docs/design/APP-FLOW-DESIGN.md)
- [Run/Station Segmentation](docs/design/RUN-STATION-SEGMENTATION.md)
- [Watch Guided Workout Flow](docs/design/WATCH-GUIDED-WORKOUT-FLOW.md)
- [Data Analytics & Visualization](docs/design/DATA-ANALYTICS-VISUALIZATION.md)
- [AI Learning Methodology](docs/design/AI-LEARNING-METHODOLOGY.md)
- [Bring Your Own Program](docs/design/BRING-YOUR-OWN-PROGRAM.md)
- [Project Kickoff](docs/PROJECT-KICKOFF.md)

## License

Proprietary - All rights reserved

## Contact

- GitHub: [@kud0](https://github.com/kud0)
