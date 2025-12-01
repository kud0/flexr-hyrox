# Supabase Migrations

## Setup Instructions

1. Create a new Supabase project at https://app.supabase.com

2. Go to SQL Editor in your Supabase dashboard

3. Run migrations in order:
   - `001_initial_schema.sql` - Creates all tables, indexes, and triggers
   - `002_rls_policies.sql` - Enables Row Level Security policies

4. Copy your Supabase credentials:
   - Project URL: Settings > API > Project URL
   - Anon Key: Settings > API > Project API keys > anon public
   - Service Role Key: Settings > API > Project API keys > service_role

5. Add credentials to your `.env` file:
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
   ```

## Migration Files

### 001_initial_schema.sql
Creates the complete database schema:
- `users` - User profiles and authentication
- `training_architectures` - Training plans
- `workouts` - Generated workouts
- `workout_segments` - Individual workout segments
- `performance_profiles` - Weekly AI learning data
- `weekly_summaries` - Weekly progress summaries

### 002_rls_policies.sql
Enables Row Level Security (RLS) to ensure:
- Users can only access their own data
- Service role key (backend) bypasses RLS for admin operations
- Anon key respects RLS for client-side security

## Notes

- The backend uses the **service role key** which bypasses RLS
- RLS is enabled for future client-side Supabase integration
- All tables have automatic `updated_at` triggers
- Foreign keys enforce referential integrity
- Cascading deletes clean up related data

## Rollback

To rollback the migrations, run in reverse order:

```sql
-- Drop all tables
DROP TABLE IF EXISTS weekly_summaries CASCADE;
DROP TABLE IF EXISTS performance_profiles CASCADE;
DROP TABLE IF EXISTS workout_segments CASCADE;
DROP TABLE IF EXISTS workouts CASCADE;
DROP TABLE IF EXISTS training_architectures CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Drop trigger function
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
```
