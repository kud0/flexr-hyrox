export type FitnessLevel = 'beginner' | 'intermediate' | 'advanced' | 'elite';
export type Gender = 'male' | 'female' | 'other';
export type TrainingBackground = 'new_to_fitness' | 'gym_regular' | 'runner' | 'crossfit' | 'hyrox_veteran';
export type PrimaryGoal = 'first_hyrox' | 'improve_time' | 'podium' | 'train_style' | 'multiple_races';
export type PreferredTime = 'morning' | 'afternoon' | 'evening' | 'flexible';
export type EquipmentLocation = 'hyrox_gym' | 'crossfit_gym' | 'commercial_gym' | 'home_gym' | 'minimal';

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

  // Enhanced onboarding fields
  training_background?: TrainingBackground;
  primary_goal?: PrimaryGoal;
  race_date?: Date;
  target_time_seconds?: number;
  weeks_to_race?: number;
  just_finished_race?: boolean;
  days_per_week?: number;
  sessions_per_day?: number;
  preferred_time?: PreferredTime;
  equipment_location?: EquipmentLocation;
  onboarding_completed_at?: Date;
  refinement_completed_at?: Date;

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

  // Core onboarding
  training_background?: TrainingBackground;
  primary_goal?: PrimaryGoal;
  race_date?: Date;
  target_time_seconds?: number;
  days_per_week?: number;
  sessions_per_day?: number;
  preferred_time?: PreferredTime;
  equipment_location?: EquipmentLocation;
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

  // Enhanced onboarding updates
  training_background?: TrainingBackground;
  primary_goal?: PrimaryGoal;
  race_date?: Date;
  target_time_seconds?: number;
  just_finished_race?: boolean;
  days_per_week?: number;
  sessions_per_day?: number;
  preferred_time?: PreferredTime;
  equipment_location?: EquipmentLocation;
}

export interface UserProfile extends User {
  total_workouts: number;
  completed_workouts: number;
  current_streak: number;
  total_distance_km: number;
  avg_readiness_score?: number;
}
