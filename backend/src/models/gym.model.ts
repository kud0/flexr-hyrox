// Gym and Gym Membership Models
// Represents gyms, CrossFit boxes, and training facilities

export type GymType =
  | 'crossfit'
  | 'hyrox_affiliate'
  | 'commercial_gym'
  | 'boutique'
  | 'home_gym'
  | 'other';

export type MembershipStatus = 'pending' | 'active' | 'inactive' | 'left';

export type MembershipRole = 'member' | 'coach' | 'admin' | 'owner';

// Privacy settings for gym membership
export interface GymPrivacySettings {
  show_on_leaderboard: boolean;
  show_in_member_list: boolean;
  show_workout_activity: boolean;
  allow_workout_comparisons: boolean;
  show_profile_to_members: boolean;
}

// Default privacy settings by membership type
export const DEFAULT_PRIVACY_SETTINGS: GymPrivacySettings = {
  show_on_leaderboard: true,
  show_in_member_list: true,
  show_workout_activity: true,
  allow_workout_comparisons: true,
  show_profile_to_members: true,
};

// ============================================================================
// GYM MODEL
// ============================================================================

export interface Gym {
  id: string;
  name: string;
  description?: string;

  // Location
  location_address?: string;
  location_city?: string;
  location_state?: string;
  location_country?: string;
  location_postal_code?: string;
  latitude?: number;
  longitude?: number;

  // Type and verification
  gym_type: GymType;
  is_verified: boolean;
  verified_at?: Date;

  // Contact and social
  website_url?: string;
  phone_number?: string;
  email?: string;
  instagram_handle?: string;

  // Stats
  member_count: number;
  active_member_count: number;

  // Settings
  is_public: boolean;
  allow_auto_join: boolean;

  // Metadata
  created_by_user_id?: string;
  created_at: Date;
  updated_at: Date;
}

export interface CreateGymInput {
  name: string;
  description?: string;

  // Location
  location_address?: string;
  location_city?: string;
  location_state?: string;
  location_country?: string;
  location_postal_code?: string;
  latitude?: number;
  longitude?: number;

  // Type
  gym_type: GymType;

  // Contact
  website_url?: string;
  phone_number?: string;
  email?: string;
  instagram_handle?: string;

  // Settings
  is_public?: boolean;
  allow_auto_join?: boolean;
}

export interface UpdateGymInput {
  name?: string;
  description?: string;

  // Location
  location_address?: string;
  location_city?: string;
  location_state?: string;
  location_country?: string;
  location_postal_code?: string;
  latitude?: number;
  longitude?: number;

  // Type
  gym_type?: GymType;

  // Contact
  website_url?: string;
  phone_number?: string;
  email?: string;
  instagram_handle?: string;

  // Settings
  is_public?: boolean;
  allow_auto_join?: boolean;
}

// Extended gym with membership info
export interface GymWithMembership extends Gym {
  user_membership?: GymMembership;
  user_role?: MembershipRole;
  user_joined_at?: Date;
}

// Gym search filters
export interface GymSearchFilters {
  query?: string; // Search by name
  city?: string;
  state?: string;
  country?: string;
  gym_type?: GymType;
  latitude?: number;
  longitude?: number;
  radius_km?: number; // For nearby search
  is_verified?: boolean;
  min_members?: number;
}

// ============================================================================
// GYM MEMBERSHIP MODEL
// ============================================================================

export interface GymMembership {
  id: string;
  user_id: string;
  gym_id: string;

  // Status and role
  status: MembershipStatus;
  role: MembershipRole;

  // Privacy settings
  privacy_settings: GymPrivacySettings;

  // Activity
  last_activity_at?: Date;
  total_workouts_at_gym: number;

  // Dates
  joined_at: Date;
  approved_at?: Date;
  left_at?: Date;
  created_at: Date;
  updated_at: Date;
}

export interface CreateGymMembershipInput {
  gym_id: string;
  role?: MembershipRole; // Defaults to 'member'
  privacy_settings?: Partial<GymPrivacySettings>;
}

export interface UpdateGymMembershipInput {
  status?: MembershipStatus;
  role?: MembershipRole;
  privacy_settings?: Partial<GymPrivacySettings>;
}

// Membership with user and gym details
export interface GymMembershipWithDetails extends GymMembership {
  user?: {
    id: string;
    first_name?: string;
    last_name?: string;
    fitness_level: string;
    primary_goal?: string;
  };
  gym?: Gym;
}

// Gym member list item (for member directory)
export interface GymMember {
  user_id: string;
  first_name?: string;
  last_name?: string;
  fitness_level: string;
  primary_goal?: string;
  role: MembershipRole;
  joined_at: Date;
  total_workouts_at_gym: number;
  is_friend?: boolean; // If current user is friends with this member
  is_partner?: boolean; // If current user is race partners with this member
}

// ============================================================================
// UTILITY TYPES
// ============================================================================

export interface GymStats {
  total_members: number;
  active_members: number;
  total_workouts_this_week: number;
  total_workouts_this_month: number;
  average_workouts_per_member: number;
  most_active_members: GymMember[];
}

export interface NearbyGym extends Gym {
  distance_km: number;
}
