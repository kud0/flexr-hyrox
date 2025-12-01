import { Response } from 'express';
import { z } from 'zod';
import db from '../../config/database';
import { AuthRequest } from '../middleware/auth.middleware';
import { AppError } from '../middleware/error.middleware';
import { generateAIWorkout } from '../../services/ai/workout-generator';
import logger from '../../utils/logger';

const generateWorkoutSchema = z.object({
  architectureId: z.string().uuid(),
  scheduledDate: z.string().transform((val) => new Date(val)),
  readinessScore: z.number().min(0).max(100),
  preferredType: z.enum(['strength', 'running', 'hybrid', 'recovery', 'race_sim']).optional(),
  timeAvailableMinutes: z.number().positive().optional(),
  location: z.enum(['gym', 'home', 'outdoor']).optional(),
});

const completeWorkoutSchema = z.object({
  segments: z.array(
    z.object({
      id: z.string().uuid(),
      actualDistanceKm: z.number().positive().optional(),
      actualPace: z.string().optional(),
      actualDurationMinutes: z.number().positive().optional(),
      actualHeartRateAvg: z.number().positive().optional(),
      completionStatus: z.enum(['completed', 'partial', 'skipped']),
      notes: z.string().optional(),
    })
  ),
});

const updateSegmentSchema = z.object({
  actualDistanceKm: z.number().positive().optional(),
  actualPace: z.string().optional(),
  actualDurationMinutes: z.number().positive().optional(),
  actualHeartRateAvg: z.number().positive().optional(),
  completionStatus: z.enum(['completed', 'partial', 'skipped']).optional(),
  notes: z.string().optional(),
});

/**
 * Generate AI-powered workout
 */
export const generateWorkout = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;
  const input = generateWorkoutSchema.parse(req.body);

  // Verify architecture belongs to user
  const architecture = await db('training_architectures')
    .where({ id: input.architectureId, user_id: userId })
    .first();

  if (!architecture) {
    throw new AppError(404, 'Training architecture not found');
  }

  // Get user profile
  const user = await db('users').where({ id: userId }).first();

  // Generate workout using AI
  const generatedWorkout = await generateAIWorkout({
    user_id: userId,
    architecture_id: input.architectureId,
    scheduled_date: input.scheduledDate,
    readiness_score: input.readinessScore,
    preferred_type: input.preferredType,
    time_available_minutes: input.timeAvailableMinutes,
    location: input.location,
  }, user, architecture);

  // Insert workout into database
  const [workout] = await db('workouts')
    .insert({
      user_id: userId,
      architecture_id: input.architectureId,
      title: generatedWorkout.title,
      description: generatedWorkout.description,
      type: generatedWorkout.type,
      scheduled_date: input.scheduledDate,
      total_duration_minutes: generatedWorkout.total_duration_minutes,
      difficulty: generatedWorkout.difficulty,
      readiness_score: input.readinessScore,
      status: 'scheduled',
      ai_context: generatedWorkout.ai_context,
    })
    .returning('*');

  // Insert segments
  const segments = await Promise.all(
    generatedWorkout.segments.map((segment, index) =>
      db('workout_segments').insert({
        workout_id: workout.id,
        order_index: index,
        type: segment.type,
        name: segment.name,
        instructions: segment.instructions,
        duration_minutes: segment.duration_minutes,
        sets: segment.sets,
        reps: segment.reps,
        distance_km: segment.distance_km,
        target_pace: segment.target_pace,
        target_heart_rate: segment.target_heart_rate,
        rest_seconds: segment.rest_seconds,
        exercises: segment.exercises ? JSON.stringify(segment.exercises) : null,
        metadata: segment.metadata ? JSON.stringify(segment.metadata) : null,
      }).returning('*')
    )
  );

  logger.info(`Generated workout ${workout.id} for user ${userId}`);

  res.json({
    success: true,
    data: {
      workout: {
        ...workout,
        segments: segments.map((s) => s[0]),
      },
    },
  });
};

/**
 * Get user's workouts
 */
export const getWorkouts = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;
  const { status, startDate, endDate } = req.query;

  let query = db('workouts').where({ user_id: userId });

  if (status) {
    query = query.where({ status: status as string });
  }

  if (startDate) {
    query = query.where('scheduled_date', '>=', startDate as string);
  }

  if (endDate) {
    query = query.where('scheduled_date', '<=', endDate as string);
  }

  const workouts = await query.orderBy('scheduled_date', 'desc');

  res.json({
    success: true,
    data: {
      workouts,
    },
  });
};

/**
 * Get workout by ID with segments
 */
export const getWorkoutById = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;
  const { id } = req.params;

  const workout = await db('workouts')
    .where({ id, user_id: userId })
    .first();

  if (!workout) {
    throw new AppError(404, 'Workout not found');
  }

  const segments = await db('workout_segments')
    .where({ workout_id: id })
    .orderBy('order_index', 'asc');

  res.json({
    success: true,
    data: {
      workout: {
        ...workout,
        segments,
      },
    },
  });
};

/**
 * Start workout
 */
export const startWorkout = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;
  const { id } = req.params;

  const [workout] = await db('workouts')
    .where({ id, user_id: userId })
    .update({
      status: 'in_progress',
      started_at: new Date(),
      updated_at: new Date(),
    })
    .returning('*');

  if (!workout) {
    throw new AppError(404, 'Workout not found');
  }

  res.json({
    success: true,
    data: { workout },
  });
};

/**
 * Complete workout
 */
export const completeWorkout = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;
  const { id } = req.params;
  const { segments } = completeWorkoutSchema.parse(req.body);

  // Verify workout exists
  const workout = await db('workouts')
    .where({ id, user_id: userId })
    .first();

  if (!workout) {
    throw new AppError(404, 'Workout not found');
  }

  // Update segments
  await Promise.all(
    segments.map((segment) =>
      db('workout_segments')
        .where({ id: segment.id, workout_id: id })
        .update({
          actual_distance_km: segment.actualDistanceKm,
          actual_pace: segment.actualPace,
          actual_duration_minutes: segment.actualDurationMinutes,
          actual_heart_rate_avg: segment.actualHeartRateAvg,
          completion_status: segment.completionStatus,
          notes: segment.notes,
          updated_at: new Date(),
        })
    )
  );

  // Mark workout as completed
  const [updatedWorkout] = await db('workouts')
    .where({ id, user_id: userId })
    .update({
      status: 'completed',
      completed_at: new Date(),
      updated_at: new Date(),
    })
    .returning('*');

  logger.info(`Workout ${id} completed by user ${userId}`);

  res.json({
    success: true,
    data: { workout: updatedWorkout },
  });
};

/**
 * Update workout segment
 */
export const updateSegment = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;
  const { id, segmentId } = req.params;
  const updates = updateSegmentSchema.parse(req.body);

  // Verify workout belongs to user
  const workout = await db('workouts')
    .where({ id, user_id: userId })
    .first();

  if (!workout) {
    throw new AppError(404, 'Workout not found');
  }

  const dbUpdates: any = {
    updated_at: new Date(),
  };

  if (updates.actualDistanceKm) dbUpdates.actual_distance_km = updates.actualDistanceKm;
  if (updates.actualPace) dbUpdates.actual_pace = updates.actualPace;
  if (updates.actualDurationMinutes) dbUpdates.actual_duration_minutes = updates.actualDurationMinutes;
  if (updates.actualHeartRateAvg) dbUpdates.actual_heart_rate_avg = updates.actualHeartRateAvg;
  if (updates.completionStatus) dbUpdates.completion_status = updates.completionStatus;
  if (updates.notes) dbUpdates.notes = updates.notes;

  const [segment] = await db('workout_segments')
    .where({ id: segmentId, workout_id: id })
    .update(dbUpdates)
    .returning('*');

  if (!segment) {
    throw new AppError(404, 'Segment not found');
  }

  res.json({
    success: true,
    data: { segment },
  });
};

/**
 * Delete workout
 */
export const deleteWorkout = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;
  const { id } = req.params;

  const deleted = await db('workouts')
    .where({ id, user_id: userId })
    .delete();

  if (!deleted) {
    throw new AppError(404, 'Workout not found');
  }

  res.json({
    success: true,
    message: 'Workout deleted successfully',
  });
};

/**
 * Skip workout
 */
export const skipWorkout = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;
  const { id } = req.params;
  const { reason } = req.body;

  const [workout] = await db('workouts')
    .where({ id, user_id: userId })
    .update({
      status: 'skipped',
      ai_context: db.raw(`ai_context || ?`, [JSON.stringify({ skip_reason: reason })]),
      updated_at: new Date(),
    })
    .returning('*');

  if (!workout) {
    throw new AppError(404, 'Workout not found');
  }

  logger.info(`Workout ${id} skipped by user ${userId}. Reason: ${reason}`);

  res.json({
    success: true,
    data: { workout },
  });
};
