import { Router } from 'express';
import * as authController from '../controllers/auth.controller';
import { asyncHandler } from '../middleware/error.middleware';

const router = Router();

/**
 * POST /api/v1/auth/apple
 * Apple Sign-In callback
 * Body: { identityToken: string, user?: { email, firstName, lastName } }
 */
router.post('/apple', asyncHandler(authController.appleSignIn));

/**
 * POST /api/v1/auth/refresh
 * Refresh JWT token
 * Body: { token: string }
 */
router.post('/refresh', asyncHandler(authController.refreshToken));

/**
 * POST /api/v1/auth/logout
 * Logout (invalidate token on client side, optional endpoint for future token blacklist)
 */
router.post('/logout', asyncHandler(authController.logout));

export default router;
