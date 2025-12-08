import { Response } from 'express';
import { z } from 'zod';
import supabaseAdmin from '../../config/supabase';
import { AuthRequest } from '../middleware/auth.middleware';
import { AppError } from '../middleware/error.middleware';
import { RelationshipType, RelationshipStatus } from '../../models/relationship.model';

// ============================================================================
// VALIDATION SCHEMAS
// ============================================================================

const createRelationshipSchema = z.object({
  otherUserId: z.string().uuid(),
  relationshipType: z.enum(['gym_member', 'friend', 'race_partner']),
  originGymId: z.string().uuid().optional(),
  racePartnerMetadata: z.object({
    raceDate: z.string().optional(),
    raceType: z.enum(['individual', 'doubles', 'relay']).optional(),
    raceLocation: z.string().optional(),
    raceName: z.string().optional(),
    targetTimeSeconds: z.number().positive().optional(),
  }).optional(),
});

const updateRelationshipSchema = z.object({
  status: z.enum(['pending', 'accepted', 'blocked', 'ended']).optional(),
  racePartnerMetadata: z.object({
    raceDate: z.string().optional(),
    raceType: z.enum(['individual', 'doubles', 'relay']).optional(),
    raceLocation: z.string().optional(),
    raceName: z.string().optional(),
    targetTimeSeconds: z.number().positive().optional(),
  }).optional(),
});

const sendRequestSchema = z.object({
  toUserId: z.string().uuid(),
  relationshipType: z.enum(['friend', 'race_partner']),
  message: z.string().max(500).optional(),
});

const respondToRequestSchema = z.object({
  status: z.enum(['accepted', 'declined']),
});

const createInviteCodeSchema = z.object({
  relationshipType: z.enum(['friend', 'race_partner']),
  maxUses: z.number().int().positive().optional(),
  expiresDays: z.number().int().positive().max(365).optional(),
  metadata: z.object({
    raceName: z.string().optional(),
    note: z.string().optional(),
  }).optional(),
});

const redeemInviteCodeSchema = z.object({
  code: z.string().min(1),
});

const updatePermissionsSchema = z.object({
  shareWorkoutHistory: z.boolean().optional(),
  shareWorkoutDetails: z.boolean().optional(),
  sharePerformanceStats: z.boolean().optional(),
  shareStationStrengths: z.boolean().optional(),
  shareTrainingPlan: z.boolean().optional(),
  shareRaceGoals: z.boolean().optional(),
  sharePersonalRecords: z.boolean().optional(),
  shareHeartRate: z.boolean().optional(),
  shareWorkoutVideos: z.boolean().optional(),
  shareLocation: z.boolean().optional(),
  allowWorkoutComparisons: z.boolean().optional(),
  allowKudos: z.boolean().optional(),
  allowComments: z.boolean().optional(),
  showOnLeaderboards: z.boolean().optional(),
});

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Ensure canonical ordering: user_a_id < user_b_id
 */
function canonicalOrder(userId1: string, userId2: string): [string, string] {
  return userId1 < userId2 ? [userId1, userId2] : [userId2, userId1];
}

/**
 * Get the "other user" in a relationship
 */
function getOtherUserId(relationship: any, currentUserId: string): string {
  return relationship.user_a_id === currentUserId
    ? relationship.user_b_id
    : relationship.user_a_id;
}

// ============================================================================
// RELATIONSHIP CONTROLLERS
// ============================================================================

/**
 * Get all relationships for current user
 */
export const getMyRelationships = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;
  const { type, status } = req.query;

  // Build query using the helper function
  const { data: relationships, error } = await supabaseAdmin
    .rpc('get_user_relationships', { target_user_id: userId });

  if (error) {
    throw new AppError(500, 'Failed to fetch relationships', error);
  }

  // Filter by type and status if provided
  let filtered = relationships || [];
  if (type) {
    filtered = filtered.filter((r: any) => r.relationship_type === type);
  }
  if (status) {
    filtered = filtered.filter((r: any) => r.status === status);
  }

  // Get user details for each relationship
  const otherUserIds = filtered.map((r: any) => r.other_user_id);
  const { data: users } = await supabaseAdmin
    .from('users')
    .select('id, first_name, last_name, fitness_level, primary_goal')
    .in('id', otherUserIds);

  // Get permissions for each relationship
  const relationshipIds = filtered.map((r: any) => r.relationship_id);
  const { data: permissions } = await supabaseAdmin
    .from('relationship_permissions')
    .select('*')
    .in('relationship_id', relationshipIds);

  // Combine data
  const relationshipsWithDetails = filtered.map((rel: any) => {
    const otherUser = users?.find((u: any) => u.id === rel.other_user_id);
    const myPermissions = permissions?.find(
      (p: any) => p.relationship_id === rel.relationship_id && p.user_id === userId
    );
    const theirPermissions = permissions?.find(
      (p: any) => p.relationship_id === rel.relationship_id && p.user_id === rel.other_user_id
    );

    return {
      relationshipId: rel.relationship_id,
      relationshipType: rel.relationship_type,
      status: rel.status,
      initiatedByMe: rel.initiated_by_me,
      originGymId: rel.origin_gym_id,
      acceptedAt: rel.accepted_at,
      createdAt: rel.created_at,
      otherUser: {
        id: otherUser?.id,
        firstName: otherUser?.first_name,
        lastName: otherUser?.last_name,
        fitnessLevel: otherUser?.fitness_level,
        primaryGoal: otherUser?.primary_goal,
      },
      myPermissions: myPermissions ? {
        shareWorkoutHistory: myPermissions.share_workout_history,
        shareWorkoutDetails: myPermissions.share_workout_details,
        sharePerformanceStats: myPermissions.share_performance_stats,
        shareStationStrengths: myPermissions.share_station_strengths,
        shareTrainingPlan: myPermissions.share_training_plan,
        shareRaceGoals: myPermissions.share_race_goals,
        sharePersonalRecords: myPermissions.share_personal_records,
        shareHeartRate: myPermissions.share_heart_rate,
        shareWorkoutVideos: myPermissions.share_workout_videos,
        shareLocation: myPermissions.share_location,
        allowWorkoutComparisons: myPermissions.allow_workout_comparisons,
        allowKudos: myPermissions.allow_kudos,
        allowComments: myPermissions.allow_comments,
        showOnLeaderboards: myPermissions.show_on_leaderboards,
      } : null,
      theirPermissions: theirPermissions ? {
        shareWorkoutHistory: theirPermissions.share_workout_history,
        shareWorkoutDetails: theirPermissions.share_workout_details,
        sharePerformanceStats: theirPermissions.share_performance_stats,
        shareStationStrengths: theirPermissions.share_station_strengths,
        shareTrainingPlan: theirPermissions.share_training_plan,
        shareRaceGoals: theirPermissions.share_race_goals,
        sharePersonalRecords: theirPermissions.share_personal_records,
        shareHeartRate: theirPermissions.share_heart_rate,
        shareWorkoutVideos: theirPermissions.share_workout_videos,
        shareLocation: theirPermissions.share_location,
        allowWorkoutComparisons: theirPermissions.allow_workout_comparisons,
        allowKudos: theirPermissions.allow_kudos,
        allowComments: theirPermissions.allow_comments,
        showOnLeaderboards: theirPermissions.show_on_leaderboards,
      } : null,
    };
  });

  res.json({
    success: true,
    data: {
      relationships: relationshipsWithDetails,
      count: relationshipsWithDetails.length,
    },
  });
};

/**
 * Get specific relationship by ID
 */
export const getRelationshipById = async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params;
  const userId = req.user!.id;

  const { data: relationship, error } = await supabaseAdmin
    .from('user_relationships')
    .select('*')
    .eq('id', id)
    .single();

  if (error || !relationship) {
    throw new AppError(404, 'Relationship not found');
  }

  // Verify user is part of this relationship
  if (relationship.user_a_id !== userId && relationship.user_b_id !== userId) {
    throw new AppError(403, 'Not authorized to view this relationship');
  }

  const otherUserId = getOtherUserId(relationship, userId);

  // Get other user details
  const { data: otherUser } = await supabaseAdmin
    .from('users')
    .select('id, first_name, last_name, fitness_level, primary_goal')
    .eq('id', otherUserId)
    .single();

  // Get permissions
  const { data: permissions } = await supabaseAdmin
    .from('relationship_permissions')
    .select('*')
    .eq('relationship_id', id);

  const myPermissions = permissions?.find((p: any) => p.user_id === userId);
  const theirPermissions = permissions?.find((p: any) => p.user_id === otherUserId);

  res.json({
    success: true,
    data: {
      relationship: {
        id: relationship.id,
        relationshipType: relationship.relationship_type,
        status: relationship.status,
        initiatedByMe: relationship.initiated_by_user_id === userId,
        originGymId: relationship.origin_gym_id,
        racePartnerMetadata: relationship.race_partner_metadata,
        createdAt: relationship.created_at,
        acceptedAt: relationship.accepted_at,
        otherUser,
        myPermissions,
        theirPermissions,
      },
    },
  });
};

/**
 * Create a direct relationship (for gym members)
 */
export const createRelationship = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;
  const data = createRelationshipSchema.parse(req.body);

  if (data.otherUserId === userId) {
    throw new AppError(400, 'Cannot create relationship with yourself');
  }

  // Check if relationship already exists
  const [userA, userB] = canonicalOrder(userId, data.otherUserId);
  const { data: existing } = await supabaseAdmin
    .from('user_relationships')
    .select('id, status')
    .eq('user_a_id', userA)
    .eq('user_b_id', userB)
    .eq('relationship_type', data.relationshipType)
    .single();

  if (existing) {
    throw new AppError(400, 'Relationship already exists');
  }

  // For gym_member type, verify both users are in the same gym
  if (data.relationshipType === 'gym_member') {
    if (!data.originGymId) {
      throw new AppError(400, 'originGymId required for gym_member relationship');
    }

    const { data: memberships } = await supabaseAdmin
      .from('gym_memberships')
      .select('user_id')
      .eq('gym_id', data.originGymId)
      .eq('status', 'active')
      .in('user_id', [userId, data.otherUserId]);

    if (memberships?.length !== 2) {
      throw new AppError(400, 'Both users must be active members of the gym');
    }
  }

  // Create relationship
  const { data: relationship, error } = await supabaseAdmin
    .from('user_relationships')
    .insert({
      user_a_id: userA,
      user_b_id: userB,
      relationship_type: data.relationshipType,
      status: 'accepted', // Direct relationships are auto-accepted
      initiated_by_user_id: userId,
      origin_gym_id: data.originGymId,
      race_partner_metadata: data.racePartnerMetadata,
      accepted_at: new Date().toISOString(),
    })
    .select()
    .single();

  if (error) {
    throw new AppError(500, 'Failed to create relationship', error);
  }

  res.json({
    success: true,
    data: { relationship },
  });
};

/**
 * Update relationship
 */
export const updateRelationship = async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params;
  const userId = req.user!.id;
  const updates = updateRelationshipSchema.parse(req.body);

  // Verify user is part of relationship
  const { data: relationship, error: fetchError } = await supabaseAdmin
    .from('user_relationships')
    .select('user_a_id, user_b_id')
    .eq('id', id)
    .single();

  if (fetchError || !relationship) {
    throw new AppError(404, 'Relationship not found');
  }

  if (relationship.user_a_id !== userId && relationship.user_b_id !== userId) {
    throw new AppError(403, 'Not authorized to update this relationship');
  }

  const { data: updated, error } = await supabaseAdmin
    .from('user_relationships')
    .update({
      status: updates.status,
      race_partner_metadata: updates.racePartnerMetadata,
      ended_at: updates.status === 'ended' ? new Date().toISOString() : undefined,
    })
    .eq('id', id)
    .select()
    .single();

  if (error) {
    throw new AppError(500, 'Failed to update relationship', error);
  }

  res.json({
    success: true,
    data: { relationship: updated },
  });
};

/**
 * Delete (end) relationship
 */
export const deleteRelationship = async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params;
  const userId = req.user!.id;

  // Verify user is part of relationship
  const { data: relationship } = await supabaseAdmin
    .from('user_relationships')
    .select('user_a_id, user_b_id')
    .eq('id', id)
    .single();

  if (!relationship) {
    throw new AppError(404, 'Relationship not found');
  }

  if (relationship.user_a_id !== userId && relationship.user_b_id !== userId) {
    throw new AppError(403, 'Not authorized to delete this relationship');
  }

  // Soft delete by setting status to 'ended'
  const { error } = await supabaseAdmin
    .from('user_relationships')
    .update({
      status: 'ended',
      ended_at: new Date().toISOString(),
    })
    .eq('id', id);

  if (error) {
    throw new AppError(500, 'Failed to delete relationship', error);
  }

  res.json({
    success: true,
    message: 'Relationship ended',
  });
};

// ============================================================================
// RELATIONSHIP REQUEST CONTROLLERS
// ============================================================================

/**
 * Get pending requests (sent and received)
 */
export const getMyRequests = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;

  // Get requests sent to me
  const { data: incoming } = await supabaseAdmin
    .from('relationship_requests')
    .select(`
      *,
      from_user:from_user_id (id, first_name, last_name, fitness_level, primary_goal)
    `)
    .eq('to_user_id', userId)
    .eq('status', 'pending');

  // Get requests I sent
  const { data: outgoing } = await supabaseAdmin
    .from('relationship_requests')
    .select(`
      *,
      to_user:to_user_id (id, first_name, last_name, fitness_level, primary_goal)
    `)
    .eq('from_user_id', userId)
    .eq('status', 'pending');

  res.json({
    success: true,
    data: {
      incoming: incoming?.map((r: any) => ({
        id: r.id,
        fromUser: {
          id: r.from_user.id,
          firstName: r.from_user.first_name,
          lastName: r.from_user.last_name,
          fitnessLevel: r.from_user.fitness_level,
          primaryGoal: r.from_user.primary_goal,
        },
        relationshipType: r.relationship_type,
        message: r.message,
        createdAt: r.created_at,
        expiresAt: r.expires_at,
      })) || [],
      outgoing: outgoing?.map((r: any) => ({
        id: r.id,
        toUser: {
          id: r.to_user.id,
          firstName: r.to_user.first_name,
          lastName: r.to_user.last_name,
          fitnessLevel: r.to_user.fitness_level,
          primaryGoal: r.to_user.primary_goal,
        },
        relationshipType: r.relationship_type,
        message: r.message,
        createdAt: r.created_at,
        expiresAt: r.expires_at,
      })) || [],
    },
  });
};

/**
 * Send friend/partner request
 */
export const sendRequest = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;
  const data = sendRequestSchema.parse(req.body);

  if (data.toUserId === userId) {
    throw new AppError(400, 'Cannot send request to yourself');
  }

  // Check if request already exists
  const { data: existing } = await supabaseAdmin
    .from('relationship_requests')
    .select('id, status')
    .eq('from_user_id', userId)
    .eq('to_user_id', data.toUserId)
    .eq('relationship_type', data.relationshipType)
    .eq('status', 'pending')
    .single();

  if (existing) {
    throw new AppError(400, 'Request already sent');
  }

  // Check if relationship already exists
  const [userA, userB] = canonicalOrder(userId, data.toUserId);
  const { data: existingRelationship } = await supabaseAdmin
    .from('user_relationships')
    .select('id')
    .eq('user_a_id', userA)
    .eq('user_b_id', userB)
    .eq('relationship_type', data.relationshipType)
    .single();

  if (existingRelationship) {
    throw new AppError(400, 'Relationship already exists');
  }

  // Create request
  const { data: request, error } = await supabaseAdmin
    .from('relationship_requests')
    .insert({
      from_user_id: userId,
      to_user_id: data.toUserId,
      relationship_type: data.relationshipType,
      message: data.message,
      status: 'pending',
    })
    .select()
    .single();

  if (error) {
    throw new AppError(500, 'Failed to send request', error);
  }

  res.json({
    success: true,
    data: { request },
  });
};

/**
 * Respond to request (accept/decline)
 */
export const respondToRequest = async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params;
  const userId = req.user!.id;
  const { status } = respondToRequestSchema.parse(req.body);

  // Get request
  const { data: request, error: fetchError } = await supabaseAdmin
    .from('relationship_requests')
    .select('*')
    .eq('id', id)
    .eq('to_user_id', userId)
    .eq('status', 'pending')
    .single();

  if (fetchError || !request) {
    throw new AppError(404, 'Request not found or already responded to');
  }

  // Update request status
  await supabaseAdmin
    .from('relationship_requests')
    .update({
      status,
      responded_at: new Date().toISOString(),
    })
    .eq('id', id);

  // If accepted, create relationship
  if (status === 'accepted') {
    const [userA, userB] = canonicalOrder(request.from_user_id, request.to_user_id);

    const { data: relationship, error: relationshipError } = await supabaseAdmin
      .from('user_relationships')
      .insert({
        user_a_id: userA,
        user_b_id: userB,
        relationship_type: request.relationship_type,
        status: 'accepted',
        initiated_by_user_id: request.from_user_id,
        accepted_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (relationshipError) {
      throw new AppError(500, 'Failed to create relationship', relationshipError);
    }

    return res.json({
      success: true,
      data: { relationship },
      message: 'Request accepted',
    });
  }

  res.json({
    success: true,
    message: 'Request declined',
  });
};

/**
 * Cancel request
 */
export const cancelRequest = async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params;
  const userId = req.user!.id;

  const { error } = await supabaseAdmin
    .from('relationship_requests')
    .update({ status: 'cancelled' })
    .eq('id', id)
    .eq('from_user_id', userId)
    .eq('status', 'pending');

  if (error) {
    throw new AppError(500, 'Failed to cancel request', error);
  }

  res.json({
    success: true,
    message: 'Request cancelled',
  });
};

// ============================================================================
// INVITE CODE CONTROLLERS
// ============================================================================

/**
 * Create invite code
 */
export const createInviteCode = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;
  const data = createInviteCodeSchema.parse(req.body);

  // Generate unique code
  const code = generateInviteCode();

  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + (data.expiresDays || 90));

  const { data: inviteCode, error } = await supabaseAdmin
    .from('relationship_invite_codes')
    .insert({
      user_id: userId,
      code,
      relationship_type: data.relationshipType,
      max_uses: data.maxUses || 1,
      expires_at: expiresAt.toISOString(),
      metadata: data.metadata,
    })
    .select()
    .single();

  if (error) {
    throw new AppError(500, 'Failed to create invite code', error);
  }

  res.json({
    success: true,
    data: { inviteCode },
  });
};

/**
 * Redeem invite code
 */
export const redeemInviteCode = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;
  const { code } = redeemInviteCodeSchema.parse(req.body);

  // Get invite code
  const { data: inviteCode, error: fetchError } = await supabaseAdmin
    .from('relationship_invite_codes')
    .select('*')
    .eq('code', code)
    .eq('is_active', true)
    .single();

  if (fetchError || !inviteCode) {
    throw new AppError(404, 'Invalid or expired invite code');
  }

  // Check if expired
  if (new Date(inviteCode.expires_at) < new Date()) {
    throw new AppError(400, 'Invite code has expired');
  }

  // Check if max uses reached
  if (inviteCode.current_uses >= inviteCode.max_uses) {
    throw new AppError(400, 'Invite code has reached maximum uses');
  }

  // Check if trying to add yourself
  if (inviteCode.user_id === userId) {
    throw new AppError(400, 'Cannot use your own invite code');
  }

  // Check if relationship already exists
  const [userA, userB] = canonicalOrder(userId, inviteCode.user_id);
  const { data: existing } = await supabaseAdmin
    .from('user_relationships')
    .select('id')
    .eq('user_a_id', userA)
    .eq('user_b_id', userB)
    .eq('relationship_type', inviteCode.relationship_type)
    .single();

  if (existing) {
    throw new AppError(400, 'Relationship already exists');
  }

  // Create relationship
  const { data: relationship, error: relationshipError } = await supabaseAdmin
    .from('user_relationships')
    .insert({
      user_a_id: userA,
      user_b_id: userB,
      relationship_type: inviteCode.relationship_type,
      status: 'accepted',
      initiated_by_user_id: inviteCode.user_id,
      accepted_at: new Date().toISOString(),
    })
    .select()
    .single();

  if (relationshipError) {
    throw new AppError(500, 'Failed to create relationship', relationshipError);
  }

  // Increment uses
  await supabaseAdmin
    .from('relationship_invite_codes')
    .update({ current_uses: inviteCode.current_uses + 1 })
    .eq('id', inviteCode.id);

  res.json({
    success: true,
    data: { relationship },
    message: 'Invite code redeemed successfully',
  });
};

/**
 * Get my invite codes
 */
export const getMyInviteCodes = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;

  const { data: codes } = await supabaseAdmin
    .from('relationship_invite_codes')
    .select('*')
    .eq('user_id', userId)
    .eq('is_active', true)
    .order('created_at', { ascending: false });

  res.json({
    success: true,
    data: { inviteCodes: codes || [] },
  });
};

/**
 * Deactivate invite code
 */
export const deactivateInviteCode = async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params;
  const userId = req.user!.id;

  const { error } = await supabaseAdmin
    .from('relationship_invite_codes')
    .update({ is_active: false })
    .eq('id', id)
    .eq('user_id', userId);

  if (error) {
    throw new AppError(500, 'Failed to deactivate invite code', error);
  }

  res.json({
    success: true,
    message: 'Invite code deactivated',
  });
};

// ============================================================================
// PERMISSION CONTROLLERS
// ============================================================================

/**
 * Update my permissions for a relationship
 */
export const updateMyPermissions = async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params; // relationship_id
  const userId = req.user!.id;
  const updates = updatePermissionsSchema.parse(req.body);

  // Verify user is part of relationship
  const { data: relationship } = await supabaseAdmin
    .from('user_relationships')
    .select('user_a_id, user_b_id')
    .eq('id', id)
    .single();

  if (!relationship) {
    throw new AppError(404, 'Relationship not found');
  }

  if (relationship.user_a_id !== userId && relationship.user_b_id !== userId) {
    throw new AppError(403, 'Not authorized to update permissions');
  }

  // Update permissions
  const { data: permissions, error } = await supabaseAdmin
    .from('relationship_permissions')
    .update({
      share_workout_history: updates.shareWorkoutHistory,
      share_workout_details: updates.shareWorkoutDetails,
      share_performance_stats: updates.sharePerformanceStats,
      share_station_strengths: updates.shareStationStrengths,
      share_training_plan: updates.shareTrainingPlan,
      share_race_goals: updates.shareRaceGoals,
      share_personal_records: updates.sharePersonalRecords,
      share_heart_rate: updates.shareHeartRate,
      share_workout_videos: updates.shareWorkoutVideos,
      share_location: updates.shareLocation,
      allow_workout_comparisons: updates.allowWorkoutComparisons,
      allow_kudos: updates.allowKudos,
      allow_comments: updates.allowComments,
      show_on_leaderboards: updates.showOnLeaderboards,
    })
    .eq('relationship_id', id)
    .eq('user_id', userId)
    .select()
    .single();

  if (error) {
    throw new AppError(500, 'Failed to update permissions', error);
  }

  res.json({
    success: true,
    data: { permissions },
  });
};

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/**
 * Generate unique invite code
 */
function generateInviteCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 12; i++) {
    if (i > 0 && i % 4 === 0) code += '-';
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code; // Format: XXXX-XXXX-XXXX
}
