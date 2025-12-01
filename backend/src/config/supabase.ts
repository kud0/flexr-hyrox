import { createClient, SupabaseClient } from '@supabase/supabase-js';
import env from './env';
import logger from '../utils/logger';

// Define database types
export interface Database {
  public: {
    Tables: {
      users: {
        Row: {
          id: string;
          apple_user_id: string;
          email: string | null;
          first_name: string | null;
          last_name: string | null;
          fitness_level: 'beginner' | 'intermediate' | 'advanced' | 'elite';
          age: number | null;
          gender: 'male' | 'female' | 'other' | null;
          weight_kg: number | null;
          height_cm: number | null;
          goals: string[] | null;
          injuries: string[] | null;
          time_zone: string;
          created_at: string;
          updated_at: string;
          last_login_at: string | null;
        };
        Insert: Omit<Database['public']['Tables']['users']['Row'], 'id' | 'created_at' | 'updated_at'>;
        Update: Partial<Database['public']['Tables']['users']['Insert']>;
      };
      training_architectures: {
        Row: {
          id: string;
          user_id: string;
          name: string;
          description: string | null;
          weeks_to_race: number;
          race_date: string | null;
          workouts_per_week: number;
          weekly_structure: any;
          focus_areas: string[] | null;
          is_active: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: Omit<Database['public']['Tables']['training_architectures']['Row'], 'id' | 'created_at' | 'updated_at'>;
        Update: Partial<Database['public']['Tables']['training_architectures']['Insert']>;
      };
      workouts: {
        Row: {
          id: string;
          user_id: string;
          architecture_id: string | null;
          title: string;
          description: string | null;
          type: 'strength' | 'running' | 'hybrid' | 'recovery' | 'race_sim';
          scheduled_date: string | null;
          total_duration_minutes: number | null;
          difficulty: 'easy' | 'moderate' | 'hard' | 'very_hard';
          readiness_score: number | null;
          status: 'scheduled' | 'in_progress' | 'completed' | 'skipped';
          started_at: string | null;
          completed_at: string | null;
          ai_context: any | null;
          created_at: string;
          updated_at: string;
        };
        Insert: Omit<Database['public']['Tables']['workouts']['Row'], 'id' | 'created_at' | 'updated_at'>;
        Update: Partial<Database['public']['Tables']['workouts']['Insert']>;
      };
      workout_segments: {
        Row: {
          id: string;
          workout_id: string;
          order_index: number;
          type: 'warmup' | 'strength' | 'cardio' | 'hybrid' | 'cooldown';
          name: string;
          instructions: string | null;
          duration_minutes: number | null;
          sets: number | null;
          reps: number | null;
          distance_km: number | null;
          target_pace: string | null;
          target_heart_rate: string | null;
          rest_seconds: number | null;
          exercises: any | null;
          metadata: any | null;
          actual_distance_km: number | null;
          actual_pace: string | null;
          actual_duration_minutes: number | null;
          actual_heart_rate_avg: number | null;
          completion_status: 'not_started' | 'completed' | 'partial' | 'skipped';
          notes: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: Omit<Database['public']['Tables']['workout_segments']['Row'], 'id' | 'created_at' | 'updated_at'>;
        Update: Partial<Database['public']['Tables']['workout_segments']['Insert']>;
      };
      performance_profiles: {
        Row: {
          id: string;
          user_id: string;
          week_starting: string;
          avg_pace_km: number | null;
          total_running_distance_km: number | null;
          compromised_running_count: number;
          strength_sessions_completed: number | null;
          strength_progression: any | null;
          avg_readiness_score: number | null;
          recovery_sessions_completed: number | null;
          running_confidence: number;
          strength_confidence: number;
          endurance_confidence: number;
          workout_completion_rate: any | null;
          ai_adjustments: any | null;
          version: number;
          created_at: string;
          updated_at: string;
        };
        Insert: Omit<Database['public']['Tables']['performance_profiles']['Row'], 'id' | 'created_at' | 'updated_at'>;
        Update: Partial<Database['public']['Tables']['performance_profiles']['Insert']>;
      };
      weekly_summaries: {
        Row: {
          id: string;
          user_id: string;
          week_starting: string;
          week_ending: string;
          workouts_planned: number | null;
          workouts_completed: number | null;
          total_duration_minutes: number | null;
          total_distance_km: number | null;
          avg_readiness_score: number | null;
          workout_breakdown: any | null;
          performance_insights: any | null;
          notes: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: Omit<Database['public']['Tables']['weekly_summaries']['Row'], 'id' | 'created_at' | 'updated_at'>;
        Update: Partial<Database['public']['Tables']['weekly_summaries']['Insert']>;
      };
    };
  };
}

// Supabase client with service role key (for admin operations)
export const supabaseAdmin: SupabaseClient<Database> = createClient<Database>(
  env.SUPABASE_URL,
  env.SUPABASE_SERVICE_ROLE_KEY,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  }
);

// Supabase client with anon key (for client-side operations)
export const supabase: SupabaseClient<Database> = createClient<Database>(
  env.SUPABASE_URL,
  env.SUPABASE_ANON_KEY,
  {
    auth: {
      autoRefreshToken: true,
      persistSession: true,
    },
  }
);

// Test connection
supabaseAdmin
  .from('users')
  .select('count')
  .limit(1)
  .then(() => {
    logger.info('✅ Supabase connection established');
  })
  .catch((err) => {
    logger.error('❌ Supabase connection failed:', err);
    process.exit(1);
  });

export default supabaseAdmin;
