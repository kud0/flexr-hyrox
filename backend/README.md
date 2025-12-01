# FLEXR Backend API

Production-ready Node.js + TypeScript backend for the FLEXR HYROX training app.

## Features

- **Authentication**: Apple Sign-In integration with JWT tokens
- **AI Workout Generation**: Grok AI-powered workout creation based on user profile and training architecture
- **Performance Learning**: Weekly performance profile updates with weighted learning (0.7 old + 0.3 new)
- **Compromised Running Detection**: Tracks sessions with insufficient running volume
- **Analytics**: Progress tracking, insights, and performance metrics
- **Database**: Supabase (PostgreSQL) with Row Level Security
- **Validation**: Zod schema validation
- **Security**: Helmet, CORS, JWT authentication, RLS policies
- **Logging**: Winston structured logging
- **TypeScript**: Strict mode with full type safety

## Tech Stack

- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Language**: TypeScript
- **Database**: Supabase (PostgreSQL)
- **AI**: Grok AI (X.AI)
- **Validation**: Zod
- **Authentication**: JWT + Apple Sign-In
- **Testing**: Jest + Supertest
- **Deployment**: Vercel (Serverless)

## Getting Started

### Prerequisites

- Node.js 18+
- Supabase account (free tier available)
- Grok API key from X.AI
- Apple Developer account (for Sign-In)

### Installation

```bash
# Install dependencies
npm install

# Copy environment template
cp .env.example .env

# Edit .env with your configuration
nano .env
```

### Supabase Setup

1. **Create Supabase Project**
   - Visit https://app.supabase.com
   - Create a new project
   - Wait for database provisioning

2. **Run Migrations**
   - Go to SQL Editor in Supabase dashboard
   - Run `src/migrations/supabase/001_initial_schema.sql`
   - Run `src/migrations/supabase/002_rls_policies.sql`

3. **Get API Credentials**
   - Go to Settings > API
   - Copy Project URL
   - Copy `anon` public key
   - Copy `service_role` key (keep secret!)

4. **Update .env**
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
   GROK_API_KEY=xai-your-grok-api-key
   ```

### Development

```bash
# Start development server with hot reload
npm run dev

# Build for production
npm run build

# Start production server
npm start
```

### Testing

```bash
# Run tests
npm test

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm test -- --coverage
```

## API Endpoints

### Authentication
- `POST /api/v1/auth/apple` - Apple Sign-In
- `POST /api/v1/auth/refresh` - Refresh JWT token
- `POST /api/v1/auth/logout` - Logout

### Users
- `GET /api/v1/users/me` - Get current user profile
- `PUT /api/v1/users/me` - Update current user
- `DELETE /api/v1/users/me` - Delete account

### Workouts
- `POST /api/v1/workouts/generate` - Generate AI workout
- `GET /api/v1/workouts` - Get user's workouts
- `GET /api/v1/workouts/:id` - Get workout details
- `POST /api/v1/workouts/:id/start` - Start workout
- `POST /api/v1/workouts/:id/complete` - Complete workout
- `PUT /api/v1/workouts/:id/segments/:segmentId` - Update segment
- `DELETE /api/v1/workouts/:id` - Delete workout
- `POST /api/v1/workouts/:id/skip` - Skip workout

### Analytics
- `GET /api/v1/analytics/progress` - Get progress metrics
- `GET /api/v1/analytics/performance-profile` - Get performance profile
- `GET /api/v1/analytics/weekly-summary` - Get weekly summary
- `GET /api/v1/analytics/insights` - Get AI insights
- `POST /api/v1/analytics/training-architecture` - Create training plan
- `GET /api/v1/analytics/training-architecture/:id` - Get training plan
- `PUT /api/v1/analytics/training-architecture/:id` - Update training plan

## Environment Variables

See `.env.example` for all required environment variables.

Key variables:
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_ANON_KEY` - Supabase anonymous key (public)
- `SUPABASE_SERVICE_ROLE_KEY` - Supabase service role key (secret!)
- `JWT_SECRET` - Secret for JWT signing (min 32 chars)
- `GROK_API_KEY` - Grok API key from X.AI
- `APPLE_CLIENT_ID`, `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY_PATH` - Apple Sign-In credentials

## Database Schema

### Tables
- `users` - User profiles and authentication
- `training_architectures` - Training plans
- `workouts` - Generated workouts
- `workout_segments` - Individual workout segments
- `performance_profiles` - Weekly AI learning data
- `weekly_summaries` - Weekly progress summaries

## AI Features

### Workout Generation
- Analyzes user profile, fitness level, goals, injuries
- Considers training architecture and race timeline
- Adapts to readiness score (0-100)
- Learns from performance profile confidence levels
- Ensures minimum running volume (3km for hybrid workouts)

### Learning Engine
- Weekly performance profile updates
- 0.7 old + 0.3 new weighted learning
- Tracks compromised running sessions
- Calculates confidence levels (running, strength, endurance)
- Provides AI-generated insights and recommendations

## Project Structure

```
backend/
├── src/
│   ├── api/
│   │   ├── controllers/     # Request handlers
│   │   ├── middleware/      # Auth, error handling
│   │   └── routes/          # Route definitions
│   ├── config/              # Database, environment
│   ├── migrations/          # Database migrations
│   ├── models/              # TypeScript interfaces
│   ├── services/
│   │   ├── ai/              # AI workout generation, learning
│   │   └── analytics/       # Progress calculations
│   └── utils/               # Logger, helpers
├── tests/                   # Test files
├── knexfile.ts              # Knex configuration
├── tsconfig.json            # TypeScript config
└── package.json
```

## Production Deployment

### Vercel Deployment

```bash
# Install Vercel CLI
npm i -g vercel

# Build the project
npm run build

# Deploy to Vercel
vercel --prod
```

### Environment Variables (Vercel Dashboard)
Set these in Vercel project settings:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `JWT_SECRET`
- `GROK_API_KEY`
- `GROK_MODEL`
- `APPLE_CLIENT_ID`
- `APPLE_TEAM_ID`
- `APPLE_KEY_ID`
- `APPLE_PRIVATE_KEY_PATH`
- `CORS_ORIGIN`
- `NODE_ENV=production`

### Production Checklist
1. ✅ Supabase project created and migrated
2. ✅ RLS policies enabled
3. ✅ Secure JWT_SECRET set (32+ characters)
4. ✅ Grok API key configured
5. ✅ CORS origins configured for production domain
6. ✅ Rate limiting enabled (implement if needed)
7. ✅ Logging configured (Vercel automatically captures logs)

## License

MIT
