import { Router } from 'express';
import * as gymsController from '../controllers/gyms.controller';
import { authenticateToken } from '../middleware/auth.middleware';
import { asyncHandler } from '../middleware/error.middleware';

const router = Router();

// All gym routes require authentication
router.use(authenticateToken);

/**
 * GET /api/v1/gyms/search
 * Search for gyms
 * Query: { query?, city?, state?, country?, gymType?, latitude?, longitude?, radiusKm?, isVerified?, limit?, offset? }
 */
router.get('/search', asyncHandler(gymsController.searchGyms));

/**
 * POST /api/v1/gyms
 * Create a new gym
 * Body: { name, description?, location*, gymType, contact*, settings* }
 */
router.post('/', asyncHandler(gymsController.createGym));

/**
 * GET /api/v1/gyms/:id
 * Get gym by ID
 */
router.get('/:id', asyncHandler(gymsController.getGymById));

/**
 * PUT /api/v1/gyms/:id
 * Update gym (admins/owners only)
 * Body: { name?, description?, location*, contact*, settings* }
 */
router.put('/:id', asyncHandler(gymsController.updateGym));

/**
 * POST /api/v1/gyms/join
 * Join a gym
 * Body: { gymId, privacySettings? }
 */
router.post('/join', asyncHandler(gymsController.joinGym));

/**
 * DELETE /api/v1/gyms/:id/leave
 * Leave a gym
 */
router.delete('/:id/leave', asyncHandler(gymsController.leaveGym));

/**
 * GET /api/v1/gyms/:id/members
 * Get gym members
 */
router.get('/:id/members', asyncHandler(gymsController.getGymMembers));

/**
 * PUT /api/v1/gyms/:id/membership
 * Update own gym membership settings
 * Body: { status?, role?, privacySettings? }
 */
router.put('/:id/membership', asyncHandler(gymsController.updateMembership));

export default router;
