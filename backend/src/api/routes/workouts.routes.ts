import { Router } from 'express';
import * as workoutsController from '../controllers/workouts.controller';
import { authenticateToken } from '../middleware/auth.middleware';
import { asyncHandler } from '../middleware/error.middleware';

const router = Router();

// All workout routes require authentication
router.use(authenticateToken);

/**
 * POST /api/v1/workouts/generate
 * Generate AI workout
 * Body: { architectureId, scheduledDate, readinessScore, preferredType?, timeAvailable?, location? }
 */
router.post('/generate', asyncHandler(workoutsController.generateWorkout));

/**
 * GET /api/v1/workouts
 * Get user's workouts
 * Query: ?status=scheduled&startDate=2024-01-01&endDate=2024-01-31
 */
router.get('/', asyncHandler(workoutsController.getWorkouts));

/**
 * GET /api/v1/workouts/:id
 * Get workout by ID with segments
 */
router.get('/:id', asyncHandler(workoutsController.getWorkoutById));

/**
 * POST /api/v1/workouts/:id/start
 * Mark workout as started
 */
router.post('/:id/start', asyncHandler(workoutsController.startWorkout));

/**
 * POST /api/v1/workouts/:id/complete
 * Mark workout as completed
 * Body: { segments: [{ id, actualDistance?, actualPace?, etc. }] }
 */
router.post('/:id/complete', asyncHandler(workoutsController.completeWorkout));

/**
 * PUT /api/v1/workouts/:id/segments/:segmentId
 * Update workout segment
 * Body: { actualDistance?, actualPace?, completionStatus?, notes? }
 */
router.put('/:id/segments/:segmentId', asyncHandler(workoutsController.updateSegment));

/**
 * DELETE /api/v1/workouts/:id
 * Delete workout
 */
router.delete('/:id', asyncHandler(workoutsController.deleteWorkout));

/**
 * POST /api/v1/workouts/:id/skip
 * Skip workout
 * Body: { reason?: string }
 */
router.post('/:id/skip', asyncHandler(workoutsController.skipWorkout));

export default router;
