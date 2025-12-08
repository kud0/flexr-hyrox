import { Router } from 'express';
import * as socialController from '../controllers/social.controller';
import { authenticateToken } from '../middleware/auth.middleware';
import { asyncHandler } from '../middleware/error.middleware';

const router = Router();

// All social routes require authentication
router.use(authenticateToken);

// ============================================================================
// ACTIVITY FEED
// ============================================================================

/**
 * GET /api/v1/social/feed
 * Get activity feed
 * Query: { activityType?, visibility?, gymId?, includeFriends?, includeGym?, limit?, offset? }
 */
router.get('/feed', asyncHandler(socialController.getActivityFeed));

/**
 * POST /api/v1/social/activities
 * Create activity (manual)
 * Body: { activityType, entityType?, entityId?, metadata, visibility?, gymId? }
 */
router.post('/activities', asyncHandler(socialController.createActivity));

/**
 * DELETE /api/v1/social/activities/:id
 * Delete activity
 */
router.delete('/activities/:id', asyncHandler(socialController.deleteActivity));

// ============================================================================
// KUDOS
// ============================================================================

/**
 * POST /api/v1/social/kudos
 * Give kudos to an activity
 * Body: { activityId, kudosType? }
 */
router.post('/kudos', asyncHandler(socialController.giveKudos));

/**
 * DELETE /api/v1/social/kudos/:id
 * Remove kudos (id = activity_id)
 */
router.delete('/kudos/:id', asyncHandler(socialController.removeKudos));

// ============================================================================
// COMMENTS
// ============================================================================

/**
 * GET /api/v1/social/activities/:id/comments
 * Get comments for an activity
 */
router.get('/activities/:id/comments', asyncHandler(socialController.getComments));

/**
 * POST /api/v1/social/comments
 * Create comment
 * Body: { activityId, commentText, parentCommentId? }
 */
router.post('/comments', asyncHandler(socialController.createComment));

/**
 * PUT /api/v1/social/comments/:id
 * Update comment
 * Body: { commentText }
 */
router.put('/comments/:id', asyncHandler(socialController.updateComment));

/**
 * DELETE /api/v1/social/comments/:id
 * Delete comment (soft delete)
 */
router.delete('/comments/:id', asyncHandler(socialController.deleteComment));

// ============================================================================
// WORKOUT COMPARISONS
// ============================================================================

/**
 * POST /api/v1/social/comparisons
 * Create workout comparison
 * Body: { workoutAId, workoutBId }
 */
router.post('/comparisons', asyncHandler(socialController.createComparison));

/**
 * GET /api/v1/social/comparisons/:id
 * Get workout comparison
 */
router.get('/comparisons/:id', asyncHandler(socialController.getComparison));

// ============================================================================
// LEADERBOARDS
// ============================================================================

/**
 * GET /api/v1/social/leaderboards
 * Get gym leaderboard
 * Query: { gymId, leaderboardType, period, limit? }
 */
router.get('/leaderboards', asyncHandler(socialController.getLeaderboard));

// ============================================================================
// PERSONAL RECORDS
// ============================================================================

/**
 * GET /api/v1/social/personal-records
 * Get my personal records
 */
router.get('/personal-records', asyncHandler(socialController.getMyPersonalRecords));

/**
 * POST /api/v1/social/personal-records
 * Create or update personal record
 * Body: { recordType, value, unit, workoutId?, segmentId?, verifiedByDevice?, metadata?, achievedAt? }
 */
router.post('/personal-records', asyncHandler(socialController.createPersonalRecord));

export default router;
