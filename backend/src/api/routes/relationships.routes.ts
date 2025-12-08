import { Router } from 'express';
import * as relationshipsController from '../controllers/relationships.controller';
import { authenticateToken } from '../middleware/auth.middleware';
import { asyncHandler } from '../middleware/error.middleware';

const router = Router();

// All relationship routes require authentication
router.use(authenticateToken);

// ============================================================================
// RELATIONSHIPS
// ============================================================================

/**
 * GET /api/v1/relationships
 * Get all relationships for current user
 * Query: { type?, status? }
 */
router.get('/', asyncHandler(relationshipsController.getMyRelationships));

/**
 * POST /api/v1/relationships
 * Create a direct relationship (for gym members)
 * Body: { otherUserId, relationshipType, originGymId?, racePartnerMetadata? }
 */
router.post('/', asyncHandler(relationshipsController.createRelationship));

/**
 * GET /api/v1/relationships/:id
 * Get relationship by ID
 */
router.get('/:id', asyncHandler(relationshipsController.getRelationshipById));

/**
 * PUT /api/v1/relationships/:id
 * Update relationship
 * Body: { status?, racePartnerMetadata? }
 */
router.put('/:id', asyncHandler(relationshipsController.updateRelationship));

/**
 * DELETE /api/v1/relationships/:id
 * End relationship
 */
router.delete('/:id', asyncHandler(relationshipsController.deleteRelationship));

// ============================================================================
// REQUESTS
// ============================================================================

/**
 * GET /api/v1/relationships/requests
 * Get pending requests (incoming and outgoing)
 */
router.get('/requests', asyncHandler(relationshipsController.getMyRequests));

/**
 * POST /api/v1/relationships/requests
 * Send friend/partner request
 * Body: { toUserId, relationshipType, message? }
 */
router.post('/requests', asyncHandler(relationshipsController.sendRequest));

/**
 * PUT /api/v1/relationships/requests/:id
 * Respond to request (accept/decline)
 * Body: { status: 'accepted' | 'declined' }
 */
router.put('/requests/:id', asyncHandler(relationshipsController.respondToRequest));

/**
 * DELETE /api/v1/relationships/requests/:id
 * Cancel request
 */
router.delete('/requests/:id', asyncHandler(relationshipsController.cancelRequest));

// ============================================================================
// INVITE CODES
// ============================================================================

/**
 * GET /api/v1/relationships/invite-codes
 * Get my invite codes
 */
router.get('/invite-codes', asyncHandler(relationshipsController.getMyInviteCodes));

/**
 * POST /api/v1/relationships/invite-codes
 * Create invite code
 * Body: { relationshipType, maxUses?, expiresDays?, metadata? }
 */
router.post('/invite-codes', asyncHandler(relationshipsController.createInviteCode));

/**
 * POST /api/v1/relationships/invite-codes/redeem
 * Redeem invite code
 * Body: { code }
 */
router.post('/invite-codes/redeem', asyncHandler(relationshipsController.redeemInviteCode));

/**
 * DELETE /api/v1/relationships/invite-codes/:id
 * Deactivate invite code
 */
router.delete('/invite-codes/:id', asyncHandler(relationshipsController.deactivateInviteCode));

// ============================================================================
// PERMISSIONS
// ============================================================================

/**
 * PUT /api/v1/relationships/:id/permissions
 * Update my permissions for a relationship
 * Body: { shareWorkoutHistory?, shareWorkoutDetails?, ... }
 */
router.put('/:id/permissions', asyncHandler(relationshipsController.updateMyPermissions));

export default router;
