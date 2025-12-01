import { Router } from 'express';
import * as usersController from '../controllers/users.controller';
import { authenticateToken } from '../middleware/auth.middleware';
import { asyncHandler } from '../middleware/error.middleware';

const router = Router();

// All user routes require authentication
router.use(authenticateToken);

/**
 * GET /api/v1/users/me
 * Get current user profile
 */
router.get('/me', asyncHandler(usersController.getCurrentUser));

/**
 * PUT /api/v1/users/me
 * Update current user profile
 * Body: { firstName?, lastName?, fitnessLevel?, age?, gender?, etc. }
 */
router.put('/me', asyncHandler(usersController.updateCurrentUser));

/**
 * DELETE /api/v1/users/me
 * Delete current user account
 */
router.delete('/me', asyncHandler(usersController.deleteCurrentUser));

/**
 * GET /api/v1/users/:id
 * Get user by ID (admin or own profile)
 */
router.get('/:id', asyncHandler(usersController.getUserById));

export default router;
