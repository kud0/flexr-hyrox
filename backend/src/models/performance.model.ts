export interface PerformanceProfile {
  id: string;
  user_id: string;
  week_starting: Date;

  // Running performance
  avg_pace_km?: number;
  total_running_distance_km?: number;
  compromised_running_count: number;

  // Strength performance
  strength_sessions_completed?: number;
  strength_progression?: Record<string, any>;

  // Recovery metrics
  avg_readiness_score?: number;
  recovery_sessions_completed?: number;

  // Confidence metrics (0-1 scale)
  running_confidence: number;
  strength_confidence: number;
  endurance_confidence: number;

  // Learning metadata
  workout_completion_rate?: Record<string, number>;
  ai_adjustments?: Record<string, any>;
  version: number;

  created_at: Date;
  updated_at: Date;
}

export interface WeeklySummary {
  id: string;
  user_id: string;
  week_starting: Date;
  week_ending: Date;

  workouts_planned?: number;
  workouts_completed?: number;
  total_duration_minutes?: number;
  total_distance_km?: number;
  avg_readiness_score?: number;

  workout_breakdown?: Record<string, number>;
  performance_insights?: string[];
  notes?: string;

  created_at: Date;
  updated_at: Date;
}

export interface TrainingArchitecture {
  id: string;
  user_id: string;
  name: string;
  description?: string;
  weeks_to_race: number;
  race_date?: Date;
  workouts_per_week: number;
  weekly_structure: WeeklyStructure[];
  focus_areas: string[];
  is_active: boolean;
  created_at: Date;
  updated_at: Date;
}

export interface WeeklyStructure {
  day_of_week: number; // 0-6 (Sunday-Saturday)
  workout_type: string;
  duration_minutes?: number;
  focus?: string;
}

export interface CreateArchitectureInput {
  user_id: string;
  name: string;
  description?: string;
  weeks_to_race: number;
  race_date?: Date;
  workouts_per_week: number;
  weekly_structure: WeeklyStructure[];
  focus_areas: string[];
}

export interface PerformanceInsight {
  type: 'improvement' | 'warning' | 'milestone' | 'recommendation';
  category: 'running' | 'strength' | 'recovery' | 'overall';
  title: string;
  description: string;
  confidence: number;
  action_items?: string[];
}

export interface LearningContext {
  user_id: string;
  current_profile?: PerformanceProfile;
  previous_profiles: PerformanceProfile[];
  recent_workouts: any[];
  compromised_running_sessions: number;
  fitness_level: string;
  goals: string[];
  injuries: string[];
}
