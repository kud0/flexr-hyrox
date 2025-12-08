// User Relationship Models
// Represents gym connections, friendships, and race partnerships

export type RelationshipType = 'gym_member' | 'friend' | 'race_partner';

export type RelationshipStatus = 'pending' | 'accepted' | 'blocked' | 'ended';

export type RequestStatus = 'pending' | 'accepted' | 'declined' | 'cancelled';

// ============================================================================
// RELATIONSHIP PERMISSIONS
// ============================================================================

// Granular permissions for what each user shares with the other
export interface RelationshipPermissions {
  // Workout data
  share_workout_history: boolean;
  share_workout_details: boolean;
  share_performance_stats: boolean;
  share_station_strengths: boolean;

  // Training data
  share_training_plan: boolean;
  share_race_goals: boolean;
  share_personal_records: boolean;

  // Sensitive data
  share_heart_rate: boolean;
  share_workout_videos: boolean;
  share_location: boolean;

  // Social interactions
  allow_workout_comparisons: boolean;
  allow_kudos: boolean;
  allow_comments: boolean;
  show_on_leaderboards: boolean;
}

// Default permissions by relationship type
export const DEFAULT_PERMISSIONS: Record<RelationshipType, RelationshipPermissions> = {
  gym_member: {
    share_workout_history: false,
    share_workout_details: false,
    share_performance_stats: false,
    share_station_strengths: false,
    share_training_plan: false,
    share_race_goals: false,
    share_personal_records: false,
    share_heart_rate: false,
    share_workout_videos: false,
    share_location: false,
    allow_workout_comparisons: false,
    allow_kudos: true,
    show_on_leaderboards: true,
    allow_comments: false,
  },
  friend: {
    share_workout_history: true,
    share_workout_details: true,
    share_performance_stats: true,
    share_station_strengths: true,
    share_training_plan: false,
    share_race_goals: false,
    share_personal_records: true,
    share_heart_rate: false,
    share_workout_videos: false,
    share_location: false,
    allow_workout_comparisons: true,
    allow_kudos: true,
    allow_comments: true,
    show_on_leaderboards: true,
  },
  race_partner: {
    share_workout_history: true,
    share_workout_details: true,
    share_performance_stats: true,
    share_station_strengths: true,
    share_training_plan: true,
    share_race_goals: true,
    share_personal_records: true,
    share_heart_rate: true,
    share_workout_videos: false,
    share_location: false,
    allow_workout_comparisons: true,
    allow_kudos: true,
    allow_comments: true,
    show_on_leaderboards: true,
  },
};

// ============================================================================
// USER RELATIONSHIP MODEL
// ============================================================================

export interface UserRelationship {
  id: string;

  // Users in canonical order (user_a_id < user_b_id)
  user_a_id: string;
  user_b_id: string;

  // Relationship details
  relationship_type: RelationshipType;
  status: RelationshipStatus;

  // Metadata
  initiated_by_user_id: string;
  origin_gym_id?: string; // For gym_member type

  // Race partner specific
  race_partner_metadata?: {
    race_date?: string;
    race_type?: 'individual' | 'doubles' | 'relay';
    race_location?: string;
    race_name?: string;
    target_time_seconds?: number;
  };

  // Activity
  last_interaction_at?: Date;
  interaction_count: number;

  // Dates
  created_at: Date;
  accepted_at?: Date;
  ended_at?: Date;
  updated_at: Date;
}

export interface CreateRelationshipInput {
  other_user_id: string;
  relationship_type: RelationshipType;
  origin_gym_id?: string;
  race_partner_metadata?: UserRelationship['race_partner_metadata'];
}

export interface UpdateRelationshipInput {
  status?: RelationshipStatus;
  race_partner_metadata?: Partial<UserRelationship['race_partner_metadata']>;
}

// Relationship with user details (for displaying in lists)
export interface RelationshipWithUser extends UserRelationship {
  other_user: {
    id: string;
    first_name?: string;
    last_name?: string;
    fitness_level: string;
    primary_goal?: string;
  };
  my_permissions: RelationshipPermissions;
  their_permissions: RelationshipPermissions;
  initiated_by_me: boolean;
}

// ============================================================================
// RELATIONSHIP REQUEST MODEL
// ============================================================================

export interface RelationshipRequest {
  id: string;
  from_user_id: string;
  to_user_id: string;
  relationship_type: RelationshipType;
  message?: string;
  status: RequestStatus;
  expires_at: Date;
  created_at: Date;
  responded_at?: Date;
  updated_at: Date;
}

export interface CreateRelationshipRequestInput {
  to_user_id: string;
  relationship_type: RelationshipType;
  message?: string;
}

export interface UpdateRelationshipRequestInput {
  status: RequestStatus;
}

// Request with user details
export interface RelationshipRequestWithUser extends RelationshipRequest {
  from_user: {
    id: string;
    first_name?: string;
    last_name?: string;
    fitness_level: string;
    primary_goal?: string;
  };
  to_user: {
    id: string;
    first_name?: string;
    last_name?: string;
    fitness_level: string;
    primary_goal?: string;
  };
}

// ============================================================================
// INVITE CODE MODEL
// ============================================================================

export interface RelationshipInviteCode {
  id: string;
  user_id: string;
  code: string;
  relationship_type: RelationshipType;
  max_uses: number;
  current_uses: number;
  expires_at: Date;
  is_active: boolean;
  metadata?: {
    race_name?: string;
    note?: string;
    [key: string]: any;
  };
  created_at: Date;
  updated_at: Date;
}

export interface CreateInviteCodeInput {
  relationship_type: RelationshipType;
  max_uses?: number; // Defaults to 1
  expires_days?: number; // Defaults to 90
  metadata?: RelationshipInviteCode['metadata'];
}

export interface RedeemInviteCodeInput {
  code: string;
}

// ============================================================================
// PERMISSION MODELS
// ============================================================================

export interface UserRelationshipPermission {
  id: string;
  relationship_id: string;
  user_id: string; // Which user these permissions belong to
  ...RelationshipPermissions;
  created_at: Date;
  updated_at: Date;
}

export interface UpdatePermissionsInput {
  permissions: Partial<RelationshipPermissions>;
}

// ============================================================================
// UTILITY TYPES
// ============================================================================

// For displaying in friend/partner lists
export interface FriendListItem {
  user_id: string;
  first_name?: string;
  last_name?: string;
  fitness_level: string;
  primary_goal?: string;
  relationship_id: string;
  relationship_type: RelationshipType;
  since: Date; // accepted_at
  last_workout?: Date;
  current_streak?: number;
  is_active: boolean; // Worked out in last 7 days
}

// For displaying race partner dashboard
export interface RacePartnerSummary {
  partner_user_id: string;
  partner_first_name?: string;
  partner_last_name?: string;
  relationship_id: string;
  race_partner_metadata?: UserRelationship['race_partner_metadata'];

  // Training comparison
  my_workouts_this_week: number;
  partner_workouts_this_week: number;
  my_total_distance_km: number;
  partner_total_distance_km: number;
  my_current_streak: number;
  partner_current_streak: number;

  // Complementary strength score (0-1)
  complementary_score: number;

  // Combined readiness (0-100)
  combined_readiness: number;

  // Days until race
  days_until_race?: number;
}

// Relationship filters for queries
export interface RelationshipFilters {
  relationship_type?: RelationshipType;
  status?: RelationshipStatus;
  origin_gym_id?: string;
}

// Helper type to normalize relationship (handles canonical ordering)
export interface NormalizedRelationship {
  relationship_id: string;
  other_user_id: string;
  relationship_type: RelationshipType;
  status: RelationshipStatus;
  initiated_by_me: boolean;
  accepted_at?: Date;
  my_permissions: RelationshipPermissions;
  their_permissions: RelationshipPermissions;
}
