import { Router } from 'express';
import * as analyticsController from '../controllers/analytics.controller';
import { authenticateToken } from '../middleware/auth.middleware';
import { asyncHandler } from '../middleware/error.middleware';

const router = Router();

// All analytics routes require authentication
router.use(authenticateToken);

/**
 * GET /api/v1/analytics/progress
 * Get user progress metrics
 * Query: ?startDate=2024-01-01&endDate=2024-01-31&granularity=week
 */
router.get('/progress', asyncHandler(analyticsController.getProgress));

/**
 * GET /api/v1/analytics/performance-profile
 * Get current performance profile
 */
router.get('/performance-profile', asyncHandler(analyticsController.getPerformanceProfile));

/**
 * GET /api/v1/analytics/weekly-summary
 * Get weekly summary
 * Query: ?weekStarting=2024-01-01
 */
router.get('/weekly-summary', asyncHandler(analyticsController.getWeeklySummary));

/**
 * GET /api/v1/analytics/insights
 * Get AI-generated performance insights
 */
router.get('/insights', asyncHandler(analyticsController.getInsights));

/**
 * GET /api/v1/analytics/training-architecture/:id
 * Get training architecture details
 */
router.get('/training-architecture/:id', asyncHandler(analyticsController.getTrainingArchitecture));

/**
 * POST /api/v1/analytics/training-architecture
 * Create training architecture
 * Body: { name, description, weeksToRace, raceDate?, workoutsPerWeek, weeklyStructure, focusAreas }
 */
router.post('/training-architecture', asyncHandler(analyticsController.createTrainingArchitecture));

/**
 * PUT /api/v1/analytics/training-architecture/:id
 * Update training architecture
 */
router.put('/training-architecture/:id', asyncHandler(analyticsController.updateTrainingArchitecture));

export default router;
