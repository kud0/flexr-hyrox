import { Response } from 'express';
import { z } from 'zod';
import supabaseAdmin from '../../config/supabase';
import { AuthRequest } from '../middleware/auth.middleware';
import { AppError } from '../middleware/error.middleware';

// ============================================================================
// VALIDATION SCHEMAS
// ============================================================================

const getActivityFeedSchema = z.object({
  activityType: z.enum([
    'workout_completed',
    'personal_record',
    'milestone_reached',
    'gym_joined',
    'achievement_unlocked',
    'workout_streak',
    'friend_added',
    'race_partner_linked',
  ]).optional(),
  visibility: z.enum(['private', 'gym', 'friends', 'public']).optional(),
  gymId: z.string().uuid().optional(),
  includeFriends: z.boolean().optional(),
  includeGym: z.boolean().optional(),
  limit: z.number().int().positive().max(100).optional(),
  offset: z.number().int().nonnegative().optional(),
});

const createActivitySchema = z.object({
  activityType: z.enum([
    'workout_completed',
    'personal_record',
    'milestone_reached',
    'gym_joined',
    'achievement_unlocked',
    'workout_streak',
    'friend_added',
    'race_partner_linked',
  ]),
  entityType: z.string().optional(),
  entityId: z.string().uuid().optional(),
  metadata: z.record(z.any()),
  visibility: z.enum(['private', 'gym', 'friends', 'public']).optional(),
  gymId: z.string().uuid().optional(),
});

const giveKudosSchema = z.object({
  activityId: z.string().uuid(),
  kudosType: z.enum(['kudos', 'fire', 'lightning', 'strong', 'bullseye', 'heart']).optional(),
});

const createCommentSchema = z.object({
  activityId: z.string().uuid(),
  commentText: z.string().min(1).max(1000),
  parentCommentId: z.string().uuid().optional(),
});

const updateCommentSchema = z.object({
  commentText: z.string().min(1).max(1000),
});

const createComparisonSchema = z.object({
  workoutAId: z.string().uuid(),
  workoutBId: z.string().uuid(),
});

const getLeaderboardSchema = z.object({
  gymId: z.string().uuid(),
  leaderboardType: z.enum([
    'overall_workouts',
    'overall_distance',
    'overall_time',
    'consistency',
    'station_1km_run',
    'station_sled_push',
    'station_sled_pull',
    'station_rowing',
    'station_ski_erg',
    'station_wall_balls',
    'station_burpee_broad_jump',
  ]),
  period: z.enum(['weekly', 'monthly', 'all_time']),
  limit: z.number().int().positive().max(100).optional(),
});

const createPersonalRecordSchema = z.object({
  recordType: z.enum([
    'fastest_1km_run',
    'fastest_sled_push_50m',
    'fastest_sled_pull_50m',
    'fastest_1000m_row',
    'fastest_1000m_ski_erg',
    'fastest_100_wall_balls',
    'fastest_80m_burpee_broad_jump',
    'fastest_full_hyrox',
    'longest_distance_single_workout',
    'longest_training_streak',
  ]),
  value: z.number().positive(),
  unit: z.enum(['seconds', 'meters', 'count', 'days']),
  workoutId: z.string().uuid().optional(),
  segmentId: z.string().uuid().optional(),
  verifiedByDevice: z.enum(['apple_watch', 'manual', 'video']).optional(),
  metadata: z.record(z.any()).optional(),
  achievedAt: z.string().datetime().optional(),
});

// ============================================================================
// ACTIVITY FEED CONTROLLERS
// ============================================================================

/**
 * Get activity feed for current user
 */
export const getActivityFeed = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;
  const filters = getActivityFeedSchema.parse(req.query);

  const limit = filters.limit || 20;
  const offset = filters.offset || 0;

  let query = supabaseAdmin
    .from('gym_activity_feed')
    .select(`
      *,
      user:user_id (id, first_name, last_name, fitness_level),
      gym:gym_id (id, name)
    `)
    .order('created_at', { ascending: false })
    .range(offset, offset + limit - 1);

  // Build visibility filter
  const orConditions: string[] = [];

  // Always include own activities
  orConditions.push(`user_id.eq.${userId}`);

  // Include gym activities if requested
  if (filters.includeGym !== false) {
    // Get user's gyms
    const { data: userGyms } = await supabaseAdmin
      .from('gym_memberships')
      .select('gym_id')
      .eq('user_id', userId)
      .eq('status', 'active');

    if (userGyms && userGyms.length > 0) {
      const gymIds = userGyms.map(g => g.gym_id);
      orConditions.push(`and(visibility.eq.gym,gym_id.in.(${gymIds.join(',')}))`);
    }
  }

  // Include friends' activities if requested
  if (filters.includeFriends !== false) {
    // Get user's friends
    const { data: friendships } = await supabaseAdmin
      .rpc('get_user_relationships', { target_user_id: userId });

    if (friendships && friendships.length > 0) {
      const friendIds = friendships
        .filter((f: any) => f.status === 'accepted' && f.relationship_type !== 'gym_member')
        .map((f: any) => f.other_user_id);

      if (friendIds.length > 0) {
        orConditions.push(`and(visibility.in.(friends,public),user_id.in.(${friendIds.join(',')}))`);
      }
    }
  }

  // Apply OR filter
  if (orConditions.length > 0) {
    query = query.or(orConditions.join(','));
  }

  // Additional filters
  if (filters.activityType) {
    query = query.eq('activity_type', filters.activityType);
  }

  if (filters.gymId) {
    query = query.eq('gym_id', filters.gymId);
  }

  const { data: activities, error } = await query;

  if (error) {
    throw new AppError(500, 'Failed to fetch activity feed', error);
  }

  // Check if user has given kudos to each activity
  if (activities && activities.length > 0) {
    const activityIds = activities.map((a: any) => a.id);
    const { data: userKudos } = await supabaseAdmin
      .from('activity_kudos')
      .select('activity_id, kudos_type')
      .eq('user_id', userId)
      .in('activity_id', activityIds);

    const kudosMap = new Map(userKudos?.map(k => [k.activity_id, k.kudos_type]));

    const enrichedActivities = activities.map((activity: any) => ({
      id: activity.id,
      userId: activity.user_id,
      user: {
        id: activity.user?.id,
        firstName: activity.user?.first_name,
        lastName: activity.user?.last_name,
        fitnessLevel: activity.user?.fitness_level,
      },
      gym: activity.gym ? {
        id: activity.gym.id,
        name: activity.gym.name,
      } : null,
      activityType: activity.activity_type,
      entityType: activity.entity_type,
      entityId: activity.entity_id,
      metadata: activity.metadata,
      visibility: activity.visibility,
      kudosCount: activity.kudos_count,
      commentCount: activity.comment_count,
      userHasGivenKudos: kudosMap.has(activity.id),
      userKudosType: kudosMap.get(activity.id),
      createdAt: activity.created_at,
    }));

    return res.json({
      success: true,
      data: {
        activities: enrichedActivities,
        count: enrichedActivities.length,
        limit,
        offset,
      },
    });
  }

  res.json({
    success: true,
    data: {
      activities: [],
      count: 0,
      limit,
      offset,
    },
  });
};

/**
 * Create activity (usually auto-created by triggers, but can be manual)
 */
export const createActivity = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;
  const data = createActivitySchema.parse(req.body);

  const { data: activity, error } = await supabaseAdmin
    .from('gym_activity_feed')
    .insert({
      user_id: userId,
      gym_id: data.gymId,
      activity_type: data.activityType,
      entity_type: data.entityType,
      entity_id: data.entityId,
      metadata: data.metadata,
      visibility: data.visibility || 'gym',
    })
    .select()
    .single();

  if (error) {
    throw new AppError(500, 'Failed to create activity', error);
  }

  res.json({
    success: true,
    data: { activity },
  });
};

/**
 * Delete activity
 */
export const deleteActivity = async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params;
  const userId = req.user!.id;

  const { error } = await supabaseAdmin
    .from('gym_activity_feed')
    .delete()
    .eq('id', id)
    .eq('user_id', userId);

  if (error) {
    throw new AppError(500, 'Failed to delete activity', error);
  }

  res.json({
    success: true,
    message: 'Activity deleted',
  });
};

// ============================================================================
// KUDOS CONTROLLERS
// ============================================================================

/**
 * Give kudos to an activity
 */
export const giveKudos = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;
  const { activityId, kudosType } = giveKudosSchema.parse(req.body);

  // Check if activity exists and is visible to user
  const { data: activity, error: activityError } = await supabaseAdmin
    .from('gym_activity_feed')
    .select('id, user_id')
    .eq('id', activityId)
    .single();

  if (activityError || !activity) {
    throw new AppError(404, 'Activity not found');
  }

  // Check if already given kudos
  const { data: existing } = await supabaseAdmin
    .from('activity_kudos')
    .select('id')
    .eq('activity_id', activityId)
    .eq('user_id', userId)
    .eq('kudos_type', kudosType || 'kudos')
    .single();

  if (existing) {
    throw new AppError(400, 'Already gave this kudos');
  }

  const { data: kudos, error } = await supabaseAdmin
    .from('activity_kudos')
    .insert({
      activity_id: activityId,
      user_id: userId,
      kudos_type: kudosType || 'kudos',
    })
    .select()
    .single();

  if (error) {
    throw new AppError(500, 'Failed to give kudos', error);
  }

  res.json({
    success: true,
    data: { kudos },
  });
};

/**
 * Remove kudos
 */
export const removeKudos = async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params; // activity_id
  const userId = req.user!.id;

  const { error } = await supabaseAdmin
    .from('activity_kudos')
    .delete()
    .eq('activity_id', id)
    .eq('user_id', userId);

  if (error) {
    throw new AppError(500, 'Failed to remove kudos', error);
  }

  res.json({
    success: true,
    message: 'Kudos removed',
  });
};

// ============================================================================
// COMMENT CONTROLLERS
// ============================================================================

/**
 * Get comments for an activity
 */
export const getComments = async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params; // activity_id

  const { data: comments, error } = await supabaseAdmin
    .from('activity_comments')
    .select(`
      *,
      user:user_id (id, first_name, last_name)
    `)
    .eq('activity_id', id)
    .eq('is_deleted', false)
    .order('created_at', { ascending: true });

  if (error) {
    throw new AppError(500, 'Failed to fetch comments', error);
  }

  res.json({
    success: true,
    data: {
      comments: comments?.map((c: any) => ({
        id: c.id,
        activityId: c.activity_id,
        userId: c.user_id,
        user: {
          id: c.user?.id,
          firstName: c.user?.first_name,
          lastName: c.user?.last_name,
        },
        commentText: c.comment_text,
        parentCommentId: c.parent_comment_id,
        createdAt: c.created_at,
        updatedAt: c.updated_at,
      })) || [],
    },
  });
};

/**
 * Create comment
 */
export const createComment = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;
  const data = createCommentSchema.parse(req.body);

  const { data: comment, error } = await supabaseAdmin
    .from('activity_comments')
    .insert({
      activity_id: data.activityId,
      user_id: userId,
      comment_text: data.commentText,
      parent_comment_id: data.parentCommentId,
    })
    .select()
    .single();

  if (error) {
    throw new AppError(500, 'Failed to create comment', error);
  }

  res.json({
    success: true,
    data: { comment },
  });
};

/**
 * Update comment
 */
export const updateComment = async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params;
  const userId = req.user!.id;
  const { commentText } = updateCommentSchema.parse(req.body);

  const { data: comment, error } = await supabaseAdmin
    .from('activity_comments')
    .update({ comment_text: commentText })
    .eq('id', id)
    .eq('user_id', userId)
    .select()
    .single();

  if (error) {
    throw new AppError(500, 'Failed to update comment', error);
  }

  res.json({
    success: true,
    data: { comment },
  });
};

/**
 * Delete comment (soft delete)
 */
export const deleteComment = async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params;
  const userId = req.user!.id;

  const { error } = await supabaseAdmin
    .from('activity_comments')
    .update({
      is_deleted: true,
      deleted_at: new Date().toISOString(),
    })
    .eq('id', id)
    .eq('user_id', userId);

  if (error) {
    throw new AppError(500, 'Failed to delete comment', error);
  }

  res.json({
    success: true,
    message: 'Comment deleted',
  });
};

// ============================================================================
// WORKOUT COMPARISON CONTROLLERS
// ============================================================================

/**
 * Create workout comparison
 */
export const createComparison = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;
  const { workoutAId, workoutBId } = createComparisonSchema.parse(req.body);

  if (workoutAId === workoutBId) {
    throw new AppError(400, 'Cannot compare workout with itself');
  }

  // Get both workouts
  const { data: workouts, error: workoutsError } = await supabaseAdmin
    .from('workouts')
    .select('id, user_id, title, type, total_duration_minutes, completed_at')
    .in('id', [workoutAId, workoutBId]);

  if (workoutsError || !workouts || workouts.length !== 2) {
    throw new AppError(404, 'One or both workouts not found');
  }

  const workoutA = workouts.find(w => w.id === workoutAId);
  const workoutB = workouts.find(w => w.id === workoutBId);

  // Verify user has permission to view both workouts
  // (This would need proper permission checking based on relationships)

  // Get segments for both workouts
  const { data: segmentsA } = await supabaseAdmin
    .from('workout_segments')
    .select('*')
    .eq('workout_id', workoutAId)
    .order('order_index');

  const { data: segmentsB } = await supabaseAdmin
    .from('workout_segments')
    .select('*')
    .eq('workout_id', workoutBId)
    .order('order_index');

  // Calculate similarity and comparison
  const { similarity, comparisonData } = calculateWorkoutComparison(
    workoutA,
    workoutB,
    segmentsA || [],
    segmentsB || []
  );

  // Check if comparison already exists
  const { data: existing } = await supabaseAdmin
    .from('workout_comparisons')
    .select('id')
    .eq('workout_a_id', workoutAId)
    .eq('workout_b_id', workoutBId)
    .single();

  if (existing) {
    // Update existing
    const { data: comparison, error } = await supabaseAdmin
      .from('workout_comparisons')
      .update({
        similarity_score: similarity,
        comparison_data: comparisonData,
      })
      .eq('id', existing.id)
      .select()
      .single();

    if (error) {
      throw new AppError(500, 'Failed to update comparison', error);
    }

    return res.json({
      success: true,
      data: { comparison },
    });
  }

  // Create new comparison
  const { data: comparison, error } = await supabaseAdmin
    .from('workout_comparisons')
    .insert({
      workout_a_id: workoutAId,
      workout_b_id: workoutBId,
      user_a_id: workoutA!.user_id,
      user_b_id: workoutB!.user_id,
      similarity_score: similarity,
      comparison_data: comparisonData,
    })
    .select()
    .single();

  if (error) {
    throw new AppError(500, 'Failed to create comparison', error);
  }

  res.json({
    success: true,
    data: { comparison },
  });
};

/**
 * Get workout comparison
 */
export const getComparison = async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params;
  const userId = req.user!.id;

  const { data: comparison, error } = await supabaseAdmin
    .from('workout_comparisons')
    .select(`
      *,
      workout_a:workout_a_id (id, title, type, completed_at),
      workout_b:workout_b_id (id, title, type, completed_at),
      user_a:user_a_id (id, first_name, last_name),
      user_b:user_b_id (id, first_name, last_name)
    `)
    .eq('id', id)
    .single();

  if (error || !comparison) {
    throw new AppError(404, 'Comparison not found');
  }

  // Verify user has access
  if (comparison.user_a_id !== userId && comparison.user_b_id !== userId) {
    throw new AppError(403, 'Not authorized to view this comparison');
  }

  res.json({
    success: true,
    data: { comparison },
  });
};

// ============================================================================
// LEADERBOARD CONTROLLERS
// ============================================================================

/**
 * Get gym leaderboard
 */
export const getLeaderboard = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;
  const { gymId, leaderboardType, period, limit } = getLeaderboardSchema.parse(req.query);

  // Verify user is member of gym
  const { data: membership } = await supabaseAdmin
    .from('gym_memberships')
    .select('id')
    .eq('gym_id', gymId)
    .eq('user_id', userId)
    .eq('status', 'active')
    .single();

  if (!membership) {
    throw new AppError(403, 'Must be a gym member to view leaderboards');
  }

  // Get current period dates
  const { periodStart, periodEnd } = getCurrentPeriod(period);

  // Get leaderboard
  const { data: leaderboard, error } = await supabaseAdmin
    .from('gym_leaderboards')
    .select('*')
    .eq('gym_id', gymId)
    .eq('leaderboard_type', leaderboardType)
    .eq('period', period)
    .gte('period_start', periodStart.toISOString().split('T')[0])
    .lte('period_end', periodEnd.toISOString().split('T')[0])
    .single();

  if (error || !leaderboard) {
    // Leaderboard not computed yet
    return res.json({
      success: true,
      data: {
        leaderboard: null,
        message: 'Leaderboard not yet computed',
      },
    });
  }

  // Get user details for rankings
  const userIds = leaderboard.rankings.map((r: any) => r.user_id);
  const { data: users } = await supabaseAdmin
    .from('users')
    .select('id, first_name, last_name, fitness_level')
    .in('id', userIds);

  const usersMap = new Map(users?.map(u => [u.id, u]));

  const rankingsWithUsers = leaderboard.rankings
    .slice(0, limit || 50)
    .map((ranking: any) => {
      const user = usersMap.get(ranking.user_id);
      return {
        ...ranking,
        user: user ? {
          id: user.id,
          firstName: user.first_name,
          lastName: user.last_name,
          fitnessLevel: user.fitness_level,
        } : null,
        isCurrentUser: ranking.user_id === userId,
      };
    });

  res.json({
    success: true,
    data: {
      leaderboard: {
        id: leaderboard.id,
        gymId: leaderboard.gym_id,
        leaderboardType: leaderboard.leaderboard_type,
        period: leaderboard.period,
        periodStart: leaderboard.period_start,
        periodEnd: leaderboard.period_end,
        rankings: rankingsWithUsers,
        totalParticipants: leaderboard.total_participants,
        lastComputedAt: leaderboard.last_computed_at,
      },
    },
  });
};

// ============================================================================
// PERSONAL RECORDS CONTROLLERS
// ============================================================================

/**
 * Get my personal records
 */
export const getMyPersonalRecords = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;

  const { data: records, error } = await supabaseAdmin
    .from('user_personal_records')
    .select('*')
    .eq('user_id', userId)
    .order('achieved_at', { ascending: false });

  if (error) {
    throw new AppError(500, 'Failed to fetch personal records', error);
  }

  res.json({
    success: true,
    data: { records: records || [] },
  });
};

/**
 * Create or update personal record
 */
export const createPersonalRecord = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;
  const data = createPersonalRecordSchema.parse(req.body);

  // Check if record exists
  const { data: existing } = await supabaseAdmin
    .from('user_personal_records')
    .select('*')
    .eq('user_id', userId)
    .eq('record_type', data.recordType)
    .single();

  if (existing) {
    // Check if new value is better
    const isBetter = data.value < existing.value; // Lower is better for time-based records

    if (!isBetter) {
      return res.json({
        success: false,
        message: 'New value is not better than existing record',
        data: { existingRecord: existing },
      });
    }

    // Update record
    const { data: record, error } = await supabaseAdmin
      .from('user_personal_records')
      .update({
        value: data.value,
        previous_value: existing.value,
        workout_id: data.workoutId,
        segment_id: data.segmentId,
        verified_by_device: data.verifiedByDevice,
        metadata: data.metadata,
        achieved_at: data.achievedAt || new Date().toISOString(),
      })
      .eq('id', existing.id)
      .select()
      .single();

    if (error) {
      throw new AppError(500, 'Failed to update personal record', error);
    }

    return res.json({
      success: true,
      data: { record },
      message: 'Personal record updated!',
    });
  }

  // Create new record
  const { data: record, error } = await supabaseAdmin
    .from('user_personal_records')
    .insert({
      user_id: userId,
      record_type: data.recordType,
      value: data.value,
      unit: data.unit,
      workout_id: data.workoutId,
      segment_id: data.segmentId,
      verified_by_device: data.verifiedByDevice || 'manual',
      metadata: data.metadata,
      achieved_at: data.achievedAt || new Date().toISOString(),
    })
    .select()
    .single();

  if (error) {
    throw new AppError(500, 'Failed to create personal record', error);
  }

  res.json({
    success: true,
    data: { record },
    message: 'Personal record created!',
  });
};

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/**
 * Calculate workout comparison
 */
function calculateWorkoutComparison(
  workoutA: any,
  workoutB: any,
  segmentsA: any[],
  segmentsB: any[]
): { similarity: number; comparisonData: any } {
  // Simple similarity calculation
  // In production, this would be more sophisticated
  let similarity = 0;

  // Compare workout types
  if (workoutA.type === workoutB.type) similarity += 0.3;

  // Compare segment count
  const segmentDiff = Math.abs(segmentsA.length - segmentsB.length);
  similarity += Math.max(0, 0.3 - (segmentDiff * 0.05));

  // Compare segment types
  const typesA = new Set(segmentsA.map(s => s.type));
  const typesB = new Set(segmentsB.map(s => s.type));
  const commonTypes = [...typesA].filter(t => typesB.has(t));
  similarity += (commonTypes.length / Math.max(typesA.size, typesB.size)) * 0.4;

  // Build comparison data
  const segmentComparisons = [];
  const insights = [];

  // Compare similar segments
  for (const segA of segmentsA) {
    const matchingSegB = segmentsB.find(s => s.type === segA.type);
    if (matchingSegB) {
      const timeDiff = (segA.actual_duration_minutes || 0) - (matchingSegB.actual_duration_minutes || 0);
      segmentComparisons.push({
        segment_type: segA.type,
        segment_name: segA.name,
        user_a_time: segA.actual_duration_minutes,
        user_b_time: matchingSegB.actual_duration_minutes,
        difference: timeDiff,
        percentage_difference: matchingSegB.actual_duration_minutes ?
          (timeDiff / matchingSegB.actual_duration_minutes) * 100 : 0,
      });

      if (Math.abs(timeDiff) > 1) {
        const faster = timeDiff < 0 ? 'User A' : 'User B';
        insights.push(`${faster} was ${Math.abs(timeDiff).toFixed(1)} minutes faster on ${segA.name}`);
      }
    }
  }

  const totalTimeDiff = (workoutA.total_duration_minutes || 0) - (workoutB.total_duration_minutes || 0);
  const winner = totalTimeDiff < 0 ? 'user_a' : totalTimeDiff > 0 ? 'user_b' : 'tie';

  return {
    similarity: Math.min(1, Math.max(0, similarity)),
    comparisonData: {
      segment_comparisons: segmentComparisons,
      total_time_difference: totalTimeDiff,
      winner,
      insights,
      strengths_a: segmentComparisons.filter(s => s.difference < 0).map(s => s.segment_name),
      strengths_b: segmentComparisons.filter(s => s.difference > 0).map(s => s.segment_name),
    },
  };
}

/**
 * Get current period start/end dates
 */
function getCurrentPeriod(period: string): { periodStart: Date; periodEnd: Date } {
  const now = new Date();

  if (period === 'weekly') {
    const start = new Date(now);
    start.setDate(now.getDate() - now.getDay()); // Start of week (Sunday)
    start.setHours(0, 0, 0, 0);

    const end = new Date(start);
    end.setDate(start.getDate() + 6); // End of week (Saturday)
    end.setHours(23, 59, 59, 999);

    return { periodStart: start, periodEnd: end };
  }

  if (period === 'monthly') {
    const start = new Date(now.getFullYear(), now.getMonth(), 1);
    const end = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);

    return { periodStart: start, periodEnd: end };
  }

  // all_time
  return {
    periodStart: new Date('2020-01-01'),
    periodEnd: new Date('2030-12-31'),
  };
}
