import { Response } from 'express';
import { z } from 'zod';
import supabaseAdmin from '../../config/supabase';
import { AuthRequest } from '../middleware/auth.middleware';
import { AppError } from '../middleware/error.middleware';
import { GymType, MembershipStatus, MembershipRole } from '../../models/gym.model';

// ============================================================================
// VALIDATION SCHEMAS
// ============================================================================

const createGymSchema = z.object({
  name: z.string().min(1).max(200),
  description: z.string().max(1000).optional(),

  // Location
  locationAddress: z.string().optional(),
  locationCity: z.string().optional(),
  locationState: z.string().optional(),
  locationCountry: z.string().optional(),
  locationPostalCode: z.string().optional(),
  latitude: z.number().min(-90).max(90).optional(),
  longitude: z.number().min(-180).max(180).optional(),

  // Type
  gymType: z.enum(['crossfit', 'hyrox_affiliate', 'commercial_gym', 'boutique', 'home_gym', 'other']),

  // Contact
  websiteUrl: z.string().url().optional(),
  phoneNumber: z.string().optional(),
  email: z.string().email().optional(),
  instagramHandle: z.string().optional(),

  // Settings
  isPublic: z.boolean().optional(),
  allowAutoJoin: z.boolean().optional(),
});

const updateGymSchema = createGymSchema.partial();

const searchGymsSchema = z.object({
  query: z.string().optional(),
  city: z.string().optional(),
  state: z.string().optional(),
  country: z.string().optional(),
  gymType: z.enum(['crossfit', 'hyrox_affiliate', 'commercial_gym', 'boutique', 'home_gym', 'other']).optional(),
  latitude: z.number().optional(),
  longitude: z.number().optional(),
  radiusKm: z.number().positive().optional(),
  isVerified: z.boolean().optional(),
  limit: z.number().int().positive().max(100).optional(),
  offset: z.number().int().nonnegative().optional(),
});

const joinGymSchema = z.object({
  gymId: z.string().uuid(),
  privacySettings: z.object({
    showOnLeaderboard: z.boolean().optional(),
    showInMemberList: z.boolean().optional(),
    showWorkoutActivity: z.boolean().optional(),
    allowWorkoutComparisons: z.boolean().optional(),
    showProfileToMembers: z.boolean().optional(),
  }).optional(),
});

const updateMembershipSchema = z.object({
  status: z.enum(['pending', 'active', 'inactive', 'left']).optional(),
  role: z.enum(['member', 'coach', 'admin', 'owner']).optional(),
  privacySettings: z.object({
    showOnLeaderboard: z.boolean().optional(),
    showInMemberList: z.boolean().optional(),
    showWorkoutActivity: z.boolean().optional(),
    allowWorkoutComparisons: z.boolean().optional(),
    showProfileToMembers: z.boolean().optional(),
  }).optional(),
});

// ============================================================================
// CONTROLLERS
// ============================================================================

/**
 * Search for gyms
 */
export const searchGyms = async (req: AuthRequest, res: Response): Promise<void> => {
  const filters = searchGymsSchema.parse(req.query);

  let query = supabaseAdmin
    .from('gyms')
    .select('*')
    .eq('is_public', true);

  // Apply filters
  if (filters.query) {
    query = query.textSearch('name', filters.query);
  }

  if (filters.city) {
    query = query.eq('location_city', filters.city);
  }

  if (filters.state) {
    query = query.eq('location_state', filters.state);
  }

  if (filters.country) {
    query = query.eq('location_country', filters.country);
  }

  if (filters.gymType) {
    query = query.eq('gym_type', filters.gymType);
  }

  if (filters.isVerified !== undefined) {
    query = query.eq('is_verified', filters.isVerified);
  }

  // Pagination
  const limit = filters.limit || 20;
  const offset = filters.offset || 0;
  query = query.range(offset, offset + limit - 1);

  const { data: gyms, error } = await query;

  if (error) {
    throw new AppError(500, 'Failed to search gyms', error);
  }

  // If lat/lng provided, calculate distance (simple calculation for now)
  let results = gyms;
  if (filters.latitude && filters.longitude && filters.radiusKm) {
    results = gyms?.filter(gym => {
      if (!gym.latitude || !gym.longitude) return false;
      const distance = calculateDistance(
        filters.latitude!,
        filters.longitude!,
        gym.latitude,
        gym.longitude
      );
      return distance <= filters.radiusKm!;
    });
  }

  res.json({
    success: true,
    data: {
      gyms: results?.map(g => ({
        id: g.id,
        name: g.name,
        description: g.description,
        locationCity: g.location_city,
        locationState: g.location_state,
        locationCountry: g.location_country,
        latitude: g.latitude,
        longitude: g.longitude,
        gymType: g.gym_type,
        isVerified: g.is_verified,
        memberCount: g.member_count,
        activeMemberCount: g.active_member_count,
        websiteUrl: g.website_url,
        instagramHandle: g.instagram_handle,
      })),
      count: results?.length || 0,
      limit,
      offset,
    },
  });
};

/**
 * Get gym by ID
 */
export const getGymById = async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params;
  const userId = req.user!.id;

  const { data: gym, error } = await supabaseAdmin
    .from('gyms')
    .select('*')
    .eq('id', id)
    .single();

  if (error || !gym) {
    throw new AppError(404, 'Gym not found');
  }

  // Check if user is a member
  const { data: membership } = await supabaseAdmin
    .from('gym_memberships')
    .select('*')
    .eq('gym_id', id)
    .eq('user_id', userId)
    .single();

  res.json({
    success: true,
    data: {
      gym: {
        id: gym.id,
        name: gym.name,
        description: gym.description,
        locationAddress: gym.location_address,
        locationCity: gym.location_city,
        locationState: gym.location_state,
        locationCountry: gym.location_country,
        locationPostalCode: gym.location_postal_code,
        latitude: gym.latitude,
        longitude: gym.longitude,
        gymType: gym.gym_type,
        isVerified: gym.is_verified,
        verifiedAt: gym.verified_at,
        websiteUrl: gym.website_url,
        phoneNumber: gym.phone_number,
        email: gym.email,
        instagramHandle: gym.instagram_handle,
        memberCount: gym.member_count,
        activeMemberCount: gym.active_member_count,
        isPublic: gym.is_public,
        allowAutoJoin: gym.allow_auto_join,
        createdAt: gym.created_at,
      },
      userMembership: membership ? {
        id: membership.id,
        status: membership.status,
        role: membership.role,
        privacySettings: membership.privacy_settings,
        joinedAt: membership.joined_at,
        totalWorkoutsAtGym: membership.total_workouts_at_gym,
      } : null,
    },
  });
};

/**
 * Create a new gym
 */
export const createGym = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;
  const gymData = createGymSchema.parse(req.body);

  const { data: gym, error } = await supabaseAdmin
    .from('gyms')
    .insert({
      name: gymData.name,
      description: gymData.description,
      location_address: gymData.locationAddress,
      location_city: gymData.locationCity,
      location_state: gymData.locationState,
      location_country: gymData.locationCountry,
      location_postal_code: gymData.locationPostalCode,
      latitude: gymData.latitude,
      longitude: gymData.longitude,
      gym_type: gymData.gymType,
      website_url: gymData.websiteUrl,
      phone_number: gymData.phoneNumber,
      email: gymData.email,
      instagram_handle: gymData.instagramHandle,
      is_public: gymData.isPublic ?? true,
      allow_auto_join: gymData.allowAutoJoin ?? true,
      created_by_user_id: userId,
    })
    .select()
    .single();

  if (error) {
    throw new AppError(500, 'Failed to create gym', error);
  }

  // Automatically make creator an owner and member
  await supabaseAdmin
    .from('gym_memberships')
    .insert({
      user_id: userId,
      gym_id: gym.id,
      status: 'active',
      role: 'owner',
      approved_at: new Date().toISOString(),
    });

  res.json({
    success: true,
    data: { gym },
  });
};

/**
 * Update gym
 */
export const updateGym = async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params;
  const userId = req.user!.id;
  const updates = updateGymSchema.parse(req.body);

  // Check if user is admin/owner
  const { data: membership } = await supabaseAdmin
    .from('gym_memberships')
    .select('role')
    .eq('gym_id', id)
    .eq('user_id', userId)
    .eq('status', 'active')
    .single();

  if (!membership || !['admin', 'owner'].includes(membership.role)) {
    throw new AppError(403, 'Only gym admins/owners can update gym details');
  }

  const { data: gym, error } = await supabaseAdmin
    .from('gyms')
    .update({
      name: updates.name,
      description: updates.description,
      location_address: updates.locationAddress,
      location_city: updates.locationCity,
      location_state: updates.locationState,
      location_country: updates.locationCountry,
      location_postal_code: updates.locationPostalCode,
      latitude: updates.latitude,
      longitude: updates.longitude,
      gym_type: updates.gymType,
      website_url: updates.websiteUrl,
      phone_number: updates.phoneNumber,
      email: updates.email,
      instagram_handle: updates.instagramHandle,
      is_public: updates.isPublic,
      allow_auto_join: updates.allowAutoJoin,
    })
    .eq('id', id)
    .select()
    .single();

  if (error) {
    throw new AppError(500, 'Failed to update gym', error);
  }

  res.json({
    success: true,
    data: { gym },
  });
};

/**
 * Join a gym
 */
export const joinGym = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;
  const { gymId, privacySettings } = joinGymSchema.parse(req.body);

  // Check if gym exists
  const { data: gym, error: gymError } = await supabaseAdmin
    .from('gyms')
    .select('allow_auto_join')
    .eq('id', gymId)
    .single();

  if (gymError || !gym) {
    throw new AppError(404, 'Gym not found');
  }

  // Check if already a member
  const { data: existingMembership } = await supabaseAdmin
    .from('gym_memberships')
    .select('id, status')
    .eq('gym_id', gymId)
    .eq('user_id', userId)
    .single();

  if (existingMembership) {
    if (existingMembership.status === 'active') {
      throw new AppError(400, 'Already a member of this gym');
    }
    // Reactivate if previously left
    const { data: membership, error } = await supabaseAdmin
      .from('gym_memberships')
      .update({
        status: 'active',
        joined_at: new Date().toISOString(),
        approved_at: gym.allow_auto_join ? new Date().toISOString() : null,
      })
      .eq('id', existingMembership.id)
      .select()
      .single();

    if (error) {
      throw new AppError(500, 'Failed to rejoin gym', error);
    }

    return res.json({
      success: true,
      data: { membership },
    });
  }

  // Create new membership
  const defaultPrivacy = {
    show_on_leaderboard: true,
    show_in_member_list: true,
    show_workout_activity: true,
    allow_workout_comparisons: true,
    show_profile_to_members: true,
    ...privacySettings,
  };

  const { data: membership, error } = await supabaseAdmin
    .from('gym_memberships')
    .insert({
      user_id: userId,
      gym_id: gymId,
      status: gym.allow_auto_join ? 'active' : 'pending',
      role: 'member',
      privacy_settings: defaultPrivacy,
      approved_at: gym.allow_auto_join ? new Date().toISOString() : null,
    })
    .select()
    .single();

  if (error) {
    throw new AppError(500, 'Failed to join gym', error);
  }

  res.json({
    success: true,
    data: { membership },
  });
};

/**
 * Leave a gym
 */
export const leaveGym = async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params;
  const userId = req.user!.id;

  // Check if member
  const { data: membership, error: membershipError } = await supabaseAdmin
    .from('gym_memberships')
    .select('id, role')
    .eq('gym_id', id)
    .eq('user_id', userId)
    .eq('status', 'active')
    .single();

  if (membershipError || !membership) {
    throw new AppError(404, 'Not a member of this gym');
  }

  // Check if owner (prevent leaving if sole owner)
  if (membership.role === 'owner') {
    const { data: otherOwners } = await supabaseAdmin
      .from('gym_memberships')
      .select('id')
      .eq('gym_id', id)
      .eq('role', 'owner')
      .eq('status', 'active')
      .neq('user_id', userId);

    if (!otherOwners || otherOwners.length === 0) {
      throw new AppError(400, 'Cannot leave gym as the sole owner. Transfer ownership first.');
    }
  }

  // Update membership status to 'left'
  const { error } = await supabaseAdmin
    .from('gym_memberships')
    .update({
      status: 'left',
      left_at: new Date().toISOString(),
    })
    .eq('id', membership.id);

  if (error) {
    throw new AppError(500, 'Failed to leave gym', error);
  }

  res.json({
    success: true,
    message: 'Successfully left gym',
  });
};

/**
 * Get gym members
 */
export const getGymMembers = async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params;
  const userId = req.user!.id;

  // Check if user is a member
  const { data: userMembership } = await supabaseAdmin
    .from('gym_memberships')
    .select('id')
    .eq('gym_id', id)
    .eq('user_id', userId)
    .eq('status', 'active')
    .single();

  if (!userMembership) {
    throw new AppError(403, 'Must be a gym member to view members');
  }

  // Get members who allow being shown in member list
  const { data: memberships, error } = await supabaseAdmin
    .from('gym_memberships')
    .select(`
      id,
      user_id,
      role,
      joined_at,
      total_workouts_at_gym,
      privacy_settings,
      users:user_id (
        id,
        first_name,
        last_name,
        fitness_level,
        primary_goal
      )
    `)
    .eq('gym_id', id)
    .eq('status', 'active');

  if (error) {
    throw new AppError(500, 'Failed to fetch gym members', error);
  }

  // Filter by privacy settings
  const visibleMembers = memberships?.filter(m =>
    m.privacy_settings?.show_in_member_list !== false
  );

  res.json({
    success: true,
    data: {
      members: visibleMembers?.map(m => ({
        userId: m.user_id,
        firstName: m.users?.first_name,
        lastName: m.users?.last_name,
        fitnessLevel: m.users?.fitness_level,
        primaryGoal: m.users?.primary_goal,
        role: m.role,
        joinedAt: m.joined_at,
        totalWorkoutsAtGym: m.total_workouts_at_gym,
      })),
      count: visibleMembers?.length || 0,
    },
  });
};

/**
 * Update user's gym membership
 */
export const updateMembership = async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params; // gym_id
  const userId = req.user!.id;
  const updates = updateMembershipSchema.parse(req.body);

  const { data: membership, error } = await supabaseAdmin
    .from('gym_memberships')
    .update({
      status: updates.status,
      role: updates.role,
      privacy_settings: updates.privacySettings,
    })
    .eq('gym_id', id)
    .eq('user_id', userId)
    .select()
    .single();

  if (error) {
    throw new AppError(500, 'Failed to update membership', error);
  }

  res.json({
    success: true,
    data: { membership },
  });
};

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/**
 * Calculate distance between two lat/lng points using Haversine formula
 */
function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371; // Earth's radius in km
  const dLat = toRadians(lat2 - lat1);
  const dLon = toRadians(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function toRadians(degrees: number): number {
  return degrees * (Math.PI / 180);
}
