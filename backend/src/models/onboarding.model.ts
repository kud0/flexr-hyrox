// ============================================================================
// FLEXR Onboarding Models
// Enhanced onboarding system for personalized training plans
// ============================================================================

// ====================
// Performance Benchmarks
// ====================

export interface UserPerformanceBenchmarks {
  id: string;
  user_id: string;

  // Running PRs (in seconds)
  running_1km_seconds?: number;
  running_5km_seconds?: number;
  running_zone2_pace_seconds?: number;

  // Strength PRs (optional, in kg)
  squat_pr_kg?: number;
  deadlift_pr_kg?: number;

  // HYROX Station PRs
  skierg_1000m_seconds?: number;
  sled_push_50m_seconds?: number;
  sled_push_weight_kg?: number;
  sled_pull_50m_seconds?: number;
  sled_pull_weight_kg?: number;
  rowing_1000m_seconds?: number;
  wall_balls_unbroken?: number;
  burpee_broad_jumps_1min?: number;
  farmers_carry_distance_meters?: number;
  farmers_carry_weight_kg?: number;
  sandbag_lunges_status?: 'not_tried' | 'completed' | 'struggled';

  // Metadata
  source?: 'user_input' | 'ai_learned' | 'workout_data';
  confidence_score?: number; // 0.0 to 1.0

  created_at: Date;
  updated_at: Date;
}

export interface CreateBenchmarksInput {
  user_id: string;

  // Running
  running_1km_seconds?: number;
  running_5km_seconds?: number;
  running_zone2_pace_seconds?: number;

  // Strength
  squat_pr_kg?: number;
  deadlift_pr_kg?: number;

  // HYROX stations
  skierg_1000m_seconds?: number;
  sled_push_50m_seconds?: number;
  sled_push_weight_kg?: number;
  sled_pull_50m_seconds?: number;
  sled_pull_weight_kg?: number;
  rowing_1000m_seconds?: number;
  wall_balls_unbroken?: number;
  burpee_broad_jumps_1min?: number;
  farmers_carry_distance_meters?: number;
  farmers_carry_weight_kg?: number;
  sandbag_lunges_status?: 'not_tried' | 'completed' | 'struggled';

  source?: 'user_input' | 'ai_learned' | 'workout_data';
}

export interface UpdateBenchmarksInput extends Partial<CreateBenchmarksInput> {}

// ====================
// Equipment Access
// ====================

export type SubstitutionPreference = 'close_substitute' | 'use_what_i_have' | 'tell_me_to_buy';

export interface UserEquipmentAccess {
  id: string;
  user_id: string;

  // Location type
  location_type: 'hyrox_gym' | 'crossfit_gym' | 'commercial_gym' | 'home_gym' | 'minimal';

  // Equipment flags
  has_skierg: boolean;
  has_sled: boolean;
  has_rower: boolean;
  has_wall_ball: boolean;
  has_sandbag: boolean;
  has_farmers_handles: boolean;
  has_barbell: boolean;
  has_squat_rack: boolean;
  has_pullup_bar: boolean;
  has_kettlebells: boolean;
  has_dumbbells: boolean;
  has_assault_bike: boolean;
  has_plyo_box: boolean;
  has_battle_ropes: boolean;
  has_trx: boolean;
  has_mobility_tools: boolean;

  // Multiple locations
  has_multiple_locations: boolean;
  secondary_location_type?: string;

  // Preferences
  substitution_preference: SubstitutionPreference;

  created_at: Date;
  updated_at: Date;
}

export interface CreateEquipmentInput {
  user_id: string;
  location_type: 'hyrox_gym' | 'crossfit_gym' | 'commercial_gym' | 'home_gym' | 'minimal';

  // Optional overrides (smart defaults apply otherwise)
  has_skierg?: boolean;
  has_sled?: boolean;
  has_rower?: boolean;
  has_wall_ball?: boolean;
  has_sandbag?: boolean;
  has_farmers_handles?: boolean;
  has_barbell?: boolean;
  has_squat_rack?: boolean;
  has_pullup_bar?: boolean;
  has_kettlebells?: boolean;
  has_dumbbells?: boolean;
  has_assault_bike?: boolean;
  has_plyo_box?: boolean;
  has_battle_ropes?: boolean;
  has_trx?: boolean;
  has_mobility_tools?: boolean;

  has_multiple_locations?: boolean;
  secondary_location_type?: string;
  substitution_preference?: SubstitutionPreference;
}

export interface UpdateEquipmentInput extends Partial<CreateEquipmentInput> {}

// ====================
// Weaknesses & Focus
// ====================

export type StationWeakness =
  | 'skierg'
  | 'sled_push'
  | 'sled_pull'
  | 'burpee_broad_jumps'
  | 'rowing'
  | 'farmers_carry'
  | 'sandbag_lunges'
  | 'wall_balls'
  | 'running_after_stations';

export type StrengthArea =
  | 'leg_strength'
  | 'core'
  | 'upper_push'
  | 'upper_pull'
  | 'posterior_chain'
  | 'grip'
  | 'explosive_power';

export type TrainingSplitPreference = 'mixed' | 'compromised_focus' | 'dedicated_blocks' | 'ai_decide';
export type MotivationType = 'competition' | 'self_improvement' | 'health' | 'challenge';

export interface UserWeaknesses {
  id: string;
  user_id: string;

  // Station weaknesses (up to 3)
  weak_stations?: StationWeakness[];

  // Strength ranking (ordered from strongest to weakest)
  strength_ranking?: StrengthArea[];

  // Injuries and limitations
  injuries?: string[];

  // Training preferences (for refinement)
  training_split_preference?: TrainingSplitPreference;
  motivation_type?: MotivationType;

  // Metadata
  source?: 'user_input' | 'ai_learned';

  created_at: Date;
  updated_at: Date;
}

export interface CreateWeaknessesInput {
  user_id: string;
  weak_stations?: StationWeakness[];
  strength_ranking?: StrengthArea[];
  injuries?: string[];
  training_split_preference?: TrainingSplitPreference;
  motivation_type?: MotivationType;
  source?: 'user_input' | 'ai_learned';
}

export interface UpdateWeaknessesInput extends Partial<CreateWeaknessesInput> {}

// ====================
// Workout Feedback
// ====================

export interface WorkoutFeedback {
  id: string;
  workout_id: string;
  user_id: string;

  // RPE (Rate of Perceived Exertion) 1-10
  rpe: number;

  // Could do more?
  could_do_more: 'yes' | 'maybe' | 'no';

  // Weights used (flexible structure)
  weights_used?: {
    sled_push_kg?: number;
    sled_pull_kg?: number;
    farmers_carry_kg?: number;
    kettlebell_kg?: number;
    dumbbell_kg?: number;
    sandbag_kg?: number;
    wall_ball_kg?: number;
    [key: string]: number | undefined;
  };

  // Issues
  felt_too_easy: boolean;
  felt_too_hard: boolean;
  pace_targets_off: boolean;
  ran_out_of_time: boolean;
  equipment_issue: boolean;
  pain_discomfort: boolean;
  pain_location?: string;

  // Notes
  notes?: string;

  // AI adjustments made based on this feedback
  ai_adjustments_made?: {
    weight_changes?: Record<string, number>;
    volume_adjustment?: number;
    intensity_adjustment?: number;
    notes?: string;
  };

  created_at: Date;
}

export interface CreateFeedbackInput {
  workout_id: string;
  user_id: string;
  rpe: number;
  could_do_more: 'yes' | 'maybe' | 'no';
  weights_used?: Record<string, number>;
  felt_too_easy?: boolean;
  felt_too_hard?: boolean;
  pace_targets_off?: boolean;
  ran_out_of_time?: boolean;
  equipment_issue?: boolean;
  pain_discomfort?: boolean;
  pain_location?: string;
  notes?: string;
}

// ====================
// Complete User Profile
// (For AI plan generation)
// ====================

export interface CompleteUserProfile {
  // Basic user info
  id: string;
  apple_user_id: string;
  email?: string;
  first_name?: string;
  last_name?: string;
  fitness_level: string;
  age?: number;
  gender?: string;
  weight_kg?: number;
  height_cm?: number;

  // Core onboarding
  training_background?: string;
  primary_goal?: string;
  race_date?: Date;
  target_time_seconds?: number;
  weeks_to_race?: number;
  just_finished_race?: boolean;
  days_per_week?: number;
  sessions_per_day?: number;
  preferred_time?: string;
  equipment_location?: string;
  onboarding_completed_at?: Date;
  refinement_completed_at?: Date;

  // Benchmarks (nullable if not provided)
  running_1km_seconds?: number;
  running_5km_seconds?: number;
  running_zone2_pace_seconds?: number;
  squat_pr_kg?: number;
  deadlift_pr_kg?: number;
  skierg_1000m_seconds?: number;
  sled_push_50m_seconds?: number;
  sled_push_weight_kg?: number;
  sled_pull_50m_seconds?: number;
  sled_pull_weight_kg?: number;
  rowing_1000m_seconds?: number;
  wall_balls_unbroken?: number;
  burpee_broad_jumps_1min?: number;
  farmers_carry_distance_meters?: number;
  farmers_carry_weight_kg?: number;
  benchmarks_confidence?: number;

  // Equipment
  equipment_location_type?: string;
  has_skierg?: boolean;
  has_sled?: boolean;
  has_rower?: boolean;
  has_barbell?: boolean;
  substitution_preference?: string;

  // Weaknesses
  weak_stations?: StationWeakness[];
  strength_ranking?: StrengthArea[];
  injuries?: string[];
  training_split_preference?: string;
  motivation_type?: string;

  created_at: Date;
  updated_at: Date;
}

// ====================
// Helper Functions
// ====================

/**
 * Calculate weeks to race from current date
 */
export function calculateWeeksToRace(raceDate: Date): number {
  const now = new Date();
  const diffTime = raceDate.getTime() - now.getTime();
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  return Math.ceil(diffDays / 7);
}

/**
 * Convert pace string (mm:ss) to seconds
 */
export function paceToSeconds(paceString: string): number {
  const [minutes, seconds] = paceString.split(':').map(Number);
  return minutes * 60 + seconds;
}

/**
 * Convert seconds to pace string (mm:ss)
 */
export function secondsToPace(seconds: number): string {
  const minutes = Math.floor(seconds / 60);
  const secs = Math.round(seconds % 60);
  return `${minutes}:${secs.toString().padStart(2, '0')}`;
}

/**
 * Convert time string (mm:ss or hh:mm:ss) to seconds
 */
export function timeToSeconds(timeString: string): number {
  const parts = timeString.split(':').map(Number);
  if (parts.length === 2) {
    return parts[0] * 60 + parts[1];
  } else if (parts.length === 3) {
    return parts[0] * 3600 + parts[1] * 60 + parts[2];
  }
  return 0;
}

/**
 * Convert seconds to time string (mm:ss or hh:mm:ss)
 */
export function secondsToTime(seconds: number, includeHours: boolean = false): string {
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = Math.round(seconds % 60);

  if (includeHours || hours > 0) {
    return `${hours}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }
  return `${minutes}:${secs.toString().padStart(2, '0')}`;
}
