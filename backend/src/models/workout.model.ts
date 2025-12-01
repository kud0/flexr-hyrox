export type WorkoutType = 'strength' | 'running' | 'hybrid' | 'recovery' | 'race_sim';
export type WorkoutDifficulty = 'easy' | 'moderate' | 'hard' | 'very_hard';
export type WorkoutStatus = 'scheduled' | 'in_progress' | 'completed' | 'skipped';
export type SegmentType = 'warmup' | 'strength' | 'cardio' | 'hybrid' | 'cooldown';
export type CompletionStatus = 'not_started' | 'completed' | 'partial' | 'skipped';

export interface Workout {
  id: string;
  user_id: string;
  architecture_id?: string;
  title: string;
  description?: string;
  type: WorkoutType;
  scheduled_date?: Date;
  total_duration_minutes?: number;
  difficulty: WorkoutDifficulty;
  readiness_score?: number;
  status: WorkoutStatus;
  started_at?: Date;
  completed_at?: Date;
  ai_context?: Record<string, any>;
  created_at: Date;
  updated_at: Date;
}

export interface WorkoutSegment {
  id: string;
  workout_id: string;
  order_index: number;
  type: SegmentType;
  name: string;
  instructions?: string;
  duration_minutes?: number;
  sets?: number;
  reps?: number;
  distance_km?: number;
  target_pace?: string;
  target_heart_rate?: string;
  rest_seconds?: number;
  exercises?: Exercise[];
  metadata?: Record<string, any>;

  // Actual performance
  actual_distance_km?: number;
  actual_pace?: string;
  actual_duration_minutes?: number;
  actual_heart_rate_avg?: number;
  completion_status: CompletionStatus;
  notes?: string;

  created_at: Date;
  updated_at: Date;
}

export interface Exercise {
  name: string;
  sets: number;
  reps: number;
  weight_kg?: number;
  rest_seconds: number;
  instructions?: string;
  tempo?: string; // e.g., "3-0-1-0"
}

export interface WorkoutWithSegments extends Workout {
  segments: WorkoutSegment[];
}

export interface CreateWorkoutInput {
  user_id: string;
  architecture_id?: string;
  title: string;
  description?: string;
  type: WorkoutType;
  scheduled_date?: Date;
  difficulty: WorkoutDifficulty;
  readiness_score?: number;
  segments: CreateSegmentInput[];
  ai_context?: Record<string, any>;
}

export interface CreateSegmentInput {
  order_index: number;
  type: SegmentType;
  name: string;
  instructions?: string;
  duration_minutes?: number;
  sets?: number;
  reps?: number;
  distance_km?: number;
  target_pace?: string;
  target_heart_rate?: string;
  rest_seconds?: number;
  exercises?: Exercise[];
  metadata?: Record<string, any>;
}

export interface UpdateSegmentInput {
  actual_distance_km?: number;
  actual_pace?: string;
  actual_duration_minutes?: number;
  actual_heart_rate_avg?: number;
  completion_status?: CompletionStatus;
  notes?: string;
}

export interface GenerateWorkoutRequest {
  user_id: string;
  architecture_id: string;
  scheduled_date: Date;
  readiness_score: number;
  preferred_type?: WorkoutType;
  time_available_minutes?: number;
  location?: 'gym' | 'home' | 'outdoor';
}
