// Social Activity Feed and Engagement Models
// Represents activity feed, kudos, comments, comparisons, and leaderboards

export type ActivityType =
  | 'workout_completed'
  | 'personal_record'
  | 'milestone_reached'
  | 'gym_joined'
  | 'achievement_unlocked'
  | 'workout_streak'
  | 'friend_added'
  | 'race_partner_linked';

export type ActivityVisibility = 'private' | 'gym' | 'friends' | 'public';

export type KudosType = 'kudos' | 'fire' | 'lightning' | 'strong' | 'bullseye' | 'heart';

// ============================================================================
// ACTIVITY FEED MODEL
// ============================================================================

export interface GymActivityFeed {
  id: string;
  user_id: string;
  gym_id?: string;

  // Activity details
  activity_type: ActivityType;
  entity_type?: string; // 'workout', 'achievement', etc.
  entity_id?: string;

  // Flexible metadata based on activity type
  metadata: {
    workout_title?: string;
    workout_type?: string;
    duration_minutes?: number;
    total_distance_km?: number;
    difficulty?: string;
    record_type?: string;
    time_seconds?: number;
    previous_best?: number;
    improvement?: number;
    milestone_type?: string;
    value?: number;
    [key: string]: any;
  };

  // Visibility and engagement
  visibility: ActivityVisibility;
  kudos_count: number;
  comment_count: number;

  // Expiration
  expires_at: Date;
  created_at: Date;
}

export interface CreateActivityInput {
  activity_type: ActivityType;
  entity_type?: string;
  entity_id?: string;
  metadata: GymActivityFeed['metadata'];
  visibility?: ActivityVisibility;
  gym_id?: string;
}

// Activity with user details for feed display
export interface ActivityFeedItem extends GymActivityFeed {
  user: {
    id: string;
    first_name?: string;
    last_name?: string;
    fitness_level: string;
  };
  gym?: {
    id: string;
    name: string;
  };
  user_has_given_kudos: boolean;
  user_kudos_type?: KudosType;
}

// Activity feed filters
export interface ActivityFeedFilters {
  activity_type?: ActivityType;
  visibility?: ActivityVisibility;
  gym_id?: string;
  user_id?: string;
  include_friends?: boolean;
  include_gym?: boolean;
  limit?: number;
  offset?: number;
}

// ============================================================================
// KUDOS MODEL
// ============================================================================

export interface ActivityKudos {
  id: string;
  activity_id: string;
  user_id: string;
  kudos_type: KudosType;
  created_at: Date;
}

export interface CreateKudosInput {
  activity_id: string;
  kudos_type?: KudosType; // Defaults to 'kudos'
}

// ============================================================================
// COMMENTS MODEL
// ============================================================================

export interface ActivityComment {
  id: string;
  activity_id: string;
  user_id: string;
  comment_text: string;
  parent_comment_id?: string; // For threading
  is_deleted: boolean;
  deleted_at?: Date;
  created_at: Date;
  updated_at: Date;
}

export interface CreateCommentInput {
  activity_id: string;
  comment_text: string;
  parent_comment_id?: string;
}

export interface UpdateCommentInput {
  comment_text: string;
}

// Comment with user details
export interface CommentWithUser extends ActivityComment {
  user: {
    id: string;
    first_name?: string;
    last_name?: string;
  };
  replies?: CommentWithUser[]; // For threaded comments
}

// ============================================================================
// WORKOUT COMPARISON MODEL
// ============================================================================

export interface WorkoutComparison {
  id: string;
  workout_a_id: string;
  workout_b_id: string;
  user_a_id: string;
  user_b_id: string;

  // Similarity score (0-1)
  similarity_score: number;

  // Detailed comparison results
  comparison_data: {
    segment_comparisons: SegmentComparison[];
    total_time_difference?: number; // seconds
    total_distance_difference?: number; // km
    winner?: 'user_a' | 'user_b' | 'tie';
    insights: string[]; // AI-generated insights
    strengths_a: string[]; // Where user A was stronger
    strengths_b: string[]; // Where user B was stronger
  };

  expires_at: Date;
  created_at: Date;
  updated_at: Date;
}

export interface SegmentComparison {
  segment_type: string;
  segment_name: string;
  user_a_time?: number; // seconds
  user_b_time?: number; // seconds
  user_a_distance?: number; // km
  user_b_distance?: number; // km
  difference: number; // positive = user_a faster/further
  percentage_difference: number;
}

export interface CreateComparisonInput {
  workout_a_id: string;
  workout_b_id: string;
}

// Comparison with workout and user details
export interface ComparisonWithDetails extends WorkoutComparison {
  workout_a: {
    id: string;
    title: string;
    type: string;
    completed_at?: Date;
  };
  workout_b: {
    id: string;
    title: string;
    type: string;
    completed_at?: Date;
  };
  user_a: {
    id: string;
    first_name?: string;
    last_name?: string;
  };
  user_b: {
    id: string;
    first_name?: string;
    last_name?: string;
  };
}

// ============================================================================
// LEADERBOARD MODEL
// ============================================================================

export type LeaderboardType =
  | 'overall_workouts'
  | 'overall_distance'
  | 'overall_time'
  | 'consistency'
  | 'station_1km_run'
  | 'station_sled_push'
  | 'station_sled_pull'
  | 'station_rowing'
  | 'station_ski_erg'
  | 'station_wall_balls'
  | 'station_burpee_broad_jump';

export type LeaderboardPeriod = 'weekly' | 'monthly' | 'all_time';

export interface GymLeaderboard {
  id: string;
  gym_id: string;
  leaderboard_type: LeaderboardType;
  period: LeaderboardPeriod;
  period_start: Date;
  period_end: Date;

  // Rankings array
  rankings: LeaderboardEntry[];

  total_participants: number;
  last_computed_at: Date;
  created_at: Date;
  updated_at: Date;
}

export interface LeaderboardEntry {
  rank: number;
  user_id: string;
  value: number; // Time in seconds, distance in km, count, etc.
  metadata?: {
    workout_count?: number;
    total_distance_km?: number;
    total_time_minutes?: number;
    streak_days?: number;
    [key: string]: any;
  };
}

// Leaderboard with user details for display
export interface LeaderboardWithUsers extends GymLeaderboard {
  rankings: LeaderboardEntryWithUser[];
}

export interface LeaderboardEntryWithUser extends LeaderboardEntry {
  user: {
    id: string;
    first_name?: string;
    last_name?: string;
    fitness_level: string;
  };
  is_current_user: boolean;
}

// Leaderboard filters
export interface LeaderboardFilters {
  gym_id: string;
  leaderboard_type: LeaderboardType;
  period: LeaderboardPeriod;
  limit?: number;
}

// ============================================================================
// PERSONAL RECORDS MODEL
// ============================================================================

export type RecordType =
  | 'fastest_1km_run'
  | 'fastest_sled_push_50m'
  | 'fastest_sled_pull_50m'
  | 'fastest_1000m_row'
  | 'fastest_1000m_ski_erg'
  | 'fastest_100_wall_balls'
  | 'fastest_80m_burpee_broad_jump'
  | 'fastest_full_hyrox'
  | 'longest_distance_single_workout'
  | 'longest_training_streak';

export type RecordUnit = 'seconds' | 'meters' | 'count' | 'days';

export interface UserPersonalRecord {
  id: string;
  user_id: string;
  record_type: RecordType;

  // Record value and unit
  value: number;
  unit: RecordUnit;

  // References
  workout_id?: string;
  segment_id?: string;

  // History
  previous_value?: number;
  improvement?: number; // Calculated: previous_value - value

  // Verification
  is_verified: boolean;
  verified_by_device?: 'apple_watch' | 'manual' | 'video';

  // Metadata
  metadata?: {
    conditions?: string;
    notes?: string;
    [key: string]: any;
  };

  achieved_at: Date;
  created_at: Date;
}

export interface CreatePersonalRecordInput {
  record_type: RecordType;
  value: number;
  unit: RecordUnit;
  workout_id?: string;
  segment_id?: string;
  verified_by_device?: UserPersonalRecord['verified_by_device'];
  metadata?: UserPersonalRecord['metadata'];
  achieved_at?: Date;
}

export interface UpdatePersonalRecordInput {
  value?: number;
  is_verified?: boolean;
  metadata?: UserPersonalRecord['metadata'];
}

// PR with improvement details
export interface PersonalRecordWithHistory extends UserPersonalRecord {
  improvement_percentage?: number;
  rank_in_gym?: number; // If part of gym leaderboard
  rank_in_age_group?: number;
}

// User's PR summary
export interface UserPRSummary {
  user_id: string;
  total_prs: number;
  recent_prs: UserPersonalRecord[]; // Last 5
  station_prs: {
    [key in RecordType]?: UserPersonalRecord;
  };
}
