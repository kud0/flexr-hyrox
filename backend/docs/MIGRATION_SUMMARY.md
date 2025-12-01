# FLEXR Backend Migration Summary

## Overview
Successfully migrated FLEXR backend from PostgreSQL/Knex/OpenAI to Supabase/Grok AI.

## Changes Made

### 1. Package Dependencies
**File:** `package.json`

**Removed:**
- `pg` (PostgreSQL driver)
- `knex` (Query builder)
- `openai` (OpenAI SDK)

**Added:**
- `@supabase/supabase-js@^2.39.0` (Supabase client)
- `@supabase/ssr@^0.0.10` (Server-side rendering helpers)

### 2. Configuration Files

#### /src/config/supabase.ts (NEW)
- Supabase client initialization
- TypeScript database types
- Admin and anon client exports
- Connection testing

#### /src/config/env.ts (UPDATED)
**Removed:**
- `DATABASE_URL`
- `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_SSL`
- `OPENAI_API_KEY`, `OPENAI_MODEL`

**Added:**
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `GROK_API_KEY`
- `GROK_API_URL`
- `GROK_MODEL`

### 3. AI Services

#### /src/services/ai/grok-client.ts (NEW)
- Grok API integration
- Chat completion interface
- JSON response parsing (handles markdown blocks)
- Rate limiting support
- Model: `grok-beta` or `grok-4-1-fast-non-reasoning`

#### /src/services/ai/workout-generator.ts (UPDATED)
- Replaced OpenAI calls with Grok
- Updated to use Supabase queries
- Same prompt structure maintained
- Enhanced JSON parsing for Grok responses

### 4. Controllers Updated

#### /src/api/controllers/auth.controller.ts
**Migration pattern:**
```typescript
// OLD (Knex)
const user = await db('users').where({ apple_user_id: appleUserId }).first();
await db('users').insert({ ... }).returning('*');

// NEW (Supabase)
const { data: user } = await supabaseAdmin
  .from('users')
  .select('*')
  .eq('apple_user_id', appleUserId)
  .single();

const { data: newUser } = await supabaseAdmin
  .from('users')
  .insert({ ... })
  .select()
  .single();
```

#### /src/api/controllers/users.controller.ts
**Key changes:**
- All `db()` calls replaced with `supabaseAdmin.from()`
- Error handling updated for Supabase error format
- Aggregations done in application layer (Supabase limitation)
- JSONB fields handled automatically

#### /src/api/controllers/workouts.controller.ts (NEEDS UPDATE)
**Required changes:**
- Replace `db('workouts')` with `supabaseAdmin.from('workouts')`
- Replace `db('workout_segments')` with `supabaseAdmin.from('workout_segments')`
- Update `.where()` to `.eq()` or `.filter()`
- Replace `.orderBy()` with `.order()`
- Replace `.returning('*')` with `.select()`
- Handle JSON serialization for `exercises` and `metadata` fields

### 5. Database Migrations

#### /src/migrations/supabase/001_initial_schema.sql
Complete database schema in pure SQL:
- All tables from Knex migration
- Triggers for `updated_at` columns
- Indexes for performance
- Foreign key constraints

#### /src/migrations/supabase/002_rls_policies.sql
Row Level Security policies:
- Users can only access their own data
- Service role bypasses RLS (for backend)
- Ready for future client-side integration

### 6. Deployment Configuration

#### /vercel.json (NEW)
- Node.js serverless deployment
- Routes configuration
- Environment variable handling

#### /.env.example (UPDATED)
Complete example with:
- Supabase credentials
- Grok API key
- All existing configuration

### 7. Documentation

#### /README.md (NEEDS UPDATE)
Should update:
- Tech stack (Supabase instead of PostgreSQL/Knex)
- AI (Grok instead of OpenAI)
- Setup instructions (Supabase dashboard)
- Migration instructions
- Deployment guide (Vercel)

## Migration Patterns

### Query Patterns

| Knex | Supabase |
|------|----------|
| `db('table')` | `supabaseAdmin.from('table')` |
| `.where({ id })` | `.eq('id', id)` |
| `.where('date', '>=', value)` | `.gte('date', value)` |
| `.orderBy('date', 'desc')` | `.order('date', { ascending: false })` |
| `.first()` | `.single()` |
| `.insert(data).returning('*')` | `.insert(data).select()` |
| `.update(data).returning('*')` | `.update(data).select()` |
| `.delete()` | `.delete()` |

### Error Handling

```typescript
// Knex - throws on error
try {
  const data = await db('table').where({ id }).first();
} catch (error) {
  // handle error
}

// Supabase - returns { data, error }
const { data, error } = await supabaseAdmin
  .from('table')
  .select('*')
  .eq('id', id)
  .single();

if (error) {
  // handle error
}
```

### JSON Fields

```typescript
// Knex - manual serialization
await db('table').insert({
  metadata: JSON.stringify(data)
});

// Supabase - automatic
await supabaseAdmin.from('table').insert({
  metadata: data  // Automatically serialized
});
```

## Files Still Requiring Updates

### High Priority
1. **src/api/controllers/workouts.controller.ts**
   - Convert all Knex queries to Supabase
   - ~350 lines of code
   - Complex joins and transactions

2. **src/api/controllers/analytics.controller.ts**
   - Convert Knex queries
   - Update progress calculations

3. **src/services/analytics/progress.service.ts**
   - Convert Knex queries
   - May need to rethink aggregations

4. **src/services/ai/learning-engine.ts**
   - Convert Knex queries
   - Update performance profile updates

### Low Priority
5. **src/index.ts**
   - Remove Knex/database import if present
   - Verify Supabase initialization

6. **src/api/middleware/auth.middleware.ts**
   - May need updates if it queries database

7. **Remove obsolete files:**
   - `src/config/database.ts` (old Knex config)
   - `knexfile.ts` (Knex migrations config)
   - `src/migrations/001_initial_schema.ts` (Knex migration)

## Setup Instructions for New Environment

### 1. Create Supabase Project
```bash
# Visit https://app.supabase.com
# Create new project
# Copy URL and keys
```

### 2. Run SQL Migrations
```sql
-- In Supabase SQL Editor
-- Run: src/migrations/supabase/001_initial_schema.sql
-- Run: src/migrations/supabase/002_rls_policies.sql
```

### 3. Configure Environment
```bash
cp .env.example .env
# Update with Supabase credentials
# Add Grok API key
```

### 4. Install Dependencies
```bash
npm install
```

### 5. Test Connection
```bash
npm run dev
# Should see: "✅ Supabase connection established"
```

## Deployment to Vercel

```bash
# Install Vercel CLI
npm i -g vercel

# Login
vercel login

# Deploy
vercel --prod

# Set environment variables in Vercel dashboard
```

## Testing Checklist

- [ ] Auth endpoints (Apple Sign-In)
- [ ] User CRUD operations
- [ ] Workout generation (Grok AI)
- [ ] Workout CRUD operations
- [ ] Analytics endpoints
- [ ] Performance profile updates
- [ ] Weekly summaries

## Known Issues / TODOs

1. **Aggregation queries** - Supabase doesn't support complex aggregations like Knex. Some queries need application-layer computation.

2. **Transactions** - Supabase doesn't support multi-table transactions. Consider:
   - Using database functions for critical operations
   - Accept eventual consistency for non-critical operations

3. **Date filtering** - Ensure proper timezone handling with Supabase timestamps.

4. **JSON serialization** - Verify JSONB fields are properly handled in all controllers.

## Rollback Plan

If migration fails:

1. Keep old `package.json` backed up
2. Keep old controller files in `src/api/controllers/backup/`
3. Restore from git: `git checkout HEAD~1 -- src/`
4. Run `npm install` to restore old dependencies

## Support Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase JS Client](https://supabase.com/docs/reference/javascript/introduction)
- [Grok API Documentation](https://x.ai/api)
- [Vercel Deployment](https://vercel.com/docs)
