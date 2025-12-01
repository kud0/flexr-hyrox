export type FitnessLevel = 'beginner' | 'intermediate' | 'advanced' | 'elite';
export type Gender = 'male' | 'female' | 'other';

export interface User {
  id: string;
  apple_user_id: string;
  email?: string;
  first_name?: string;
  last_name?: string;
  fitness_level: FitnessLevel;
  age?: number;
  gender?: Gender;
  weight_kg?: number;
  height_cm?: number;
  goals: string[];
  injuries: string[];
  time_zone: string;
  created_at: Date;
  updated_at: Date;
  last_login_at?: Date;
}

export interface CreateUserInput {
  apple_user_id: string;
  email?: string;
  first_name?: string;
  last_name?: string;
  fitness_level?: FitnessLevel;
  age?: number;
  gender?: Gender;
  weight_kg?: number;
  height_cm?: number;
  goals?: string[];
  injuries?: string[];
  time_zone?: string;
}

export interface UpdateUserInput {
  email?: string;
  first_name?: string;
  last_name?: string;
  fitness_level?: FitnessLevel;
  age?: number;
  gender?: Gender;
  weight_kg?: number;
  height_cm?: number;
  goals?: string[];
  injuries?: string[];
  time_zone?: string;
}

export interface UserProfile extends User {
  total_workouts: number;
  completed_workouts: number;
  current_streak: number;
  total_distance_km: number;
  avg_readiness_score?: number;
}
