import { Response } from 'express';
import { z } from 'zod';
import db from '../../config/database';
import { AuthRequest } from '../middleware/auth.middleware';
import { AppError } from '../middleware/error.middleware';
import { calculateProgress } from '../../services/analytics/progress.service';

const createArchitectureSchema = z.object({
  name: z.string().min(1),
  description: z.string().optional(),
  weeksToRace: z.number().int().positive(),
  raceDate: z.string().transform((val) => new Date(val)).optional(),
  workoutsPerWeek: z.number().int().min(1).max(7),
  weeklyStructure: z.array(
    z.object({
      dayOfWeek: z.number().int().min(0).max(6),
      workoutType: z.string(),
      durationMinutes: z.number().positive().optional(),
      focus: z.string().optional(),
    })
  ),
  focusAreas: z.array(z.string()),
});

/**
 * Get user progress metrics
 */
export const getProgress = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;
  const { startDate, endDate, granularity = 'week' } = req.query;

  const progress = await calculateProgress(
    userId,
    startDate as string,
    endDate as string,
    granularity as 'day' | 'week' | 'month'
  );

  res.json({
    success: true,
    data: progress,
  });
};

/**
 * Get current performance profile
 */
export const getPerformanceProfile = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;

  // Get the most recent performance profile
  const profile = await db('performance_profiles')
    .where({ user_id: userId })
    .orderBy('week_starting', 'desc')
    .first();

  if (!profile) {
    res.json({
      success: true,
      data: null,
      message: 'No performance profile found. Complete workouts to generate profile.',
    });
    return;
  }

  res.json({
    success: true,
    data: { profile },
  });
};

/**
 * Get weekly summary
 */
export const getWeeklySummary = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;
  const { weekStarting } = req.query;

  let query = db('weekly_summaries').where({ user_id: userId });

  if (weekStarting) {
    query = query.where({ week_starting: weekStarting as string });
  } else {
    // Get most recent week
    query = query.orderBy('week_starting', 'desc').limit(1);
  }

  const summary = await query.first();

  if (!summary) {
    throw new AppError(404, 'Weekly summary not found');
  }

  res.json({
    success: true,
    data: { summary },
  });
};

/**
 * Get AI-generated performance insights
 */
export const getInsights = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;

  // Get recent performance profile
  const profile = await db('performance_profiles')
    .where({ user_id: userId })
    .orderBy('week_starting', 'desc')
    .first();

  if (!profile) {
    res.json({
      success: true,
      data: { insights: [] },
      message: 'Complete workouts to generate insights',
    });
    return;
  }

  // Generate insights based on profile
  const insights = [];

  // Running confidence insight
  if (profile.running_confidence < 0.4) {
    insights.push({
      type: 'warning',
      category: 'running',
      title: 'Low Running Confidence',
      description: 'Your running performance shows room for improvement. Focus on consistent aerobic sessions.',
      confidence: 0.8,
      actionItems: ['Add 1-2 easy running sessions per week', 'Focus on base building'],
    });
  } else if (profile.running_confidence > 0.7) {
    insights.push({
      type: 'milestone',
      category: 'running',
      title: 'Strong Running Foundation',
      description: 'Your running performance is excellent. Consider adding speed work.',
      confidence: 0.9,
    });
  }

  // Compromised running warning
  if (profile.compromised_running_count >= 2) {
    insights.push({
      type: 'warning',
      category: 'running',
      title: 'Compromised Running Sessions Detected',
      description: `${profile.compromised_running_count} sessions with less than 3km running. Consider adjusting workout balance.`,
      confidence: 1.0,
      actionItems: ['Increase running volume in hybrid workouts', 'Add dedicated running sessions'],
    });
  }

  // Strength insight
  if (profile.strength_confidence > 0.6) {
    insights.push({
      type: 'improvement',
      category: 'strength',
      title: 'Strength Progression',
      description: 'Your strength training is progressing well. Keep up the consistency.',
      confidence: 0.85,
    });
  }

  // Recovery insight
  if (profile.avg_readiness_score && profile.avg_readiness_score < 60) {
    insights.push({
      type: 'warning',
      category: 'recovery',
      title: 'Low Readiness Scores',
      description: 'Your average readiness is below optimal. Prioritize recovery.',
      confidence: 0.9,
      actionItems: ['Add recovery sessions', 'Ensure adequate sleep', 'Consider reducing workout intensity'],
    });
  }

  res.json({
    success: true,
    data: { insights },
  });
};

/**
 * Get training architecture by ID
 */
export const getTrainingArchitecture = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;
  const { id } = req.params;

  const architecture = await db('training_architectures')
    .where({ id, user_id: userId })
    .first();

  if (!architecture) {
    throw new AppError(404, 'Training architecture not found');
  }

  res.json({
    success: true,
    data: { architecture },
  });
};

/**
 * Create training architecture
 */
export const createTrainingArchitecture = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;
  const input = createArchitectureSchema.parse(req.body);

  // Deactivate other architectures
  await db('training_architectures')
    .where({ user_id: userId, is_active: true })
    .update({ is_active: false });

  const [architecture] = await db('training_architectures')
    .insert({
      user_id: userId,
      name: input.name,
      description: input.description,
      weeks_to_race: input.weeksToRace,
      race_date: input.raceDate,
      workouts_per_week: input.workoutsPerWeek,
      weekly_structure: JSON.stringify(input.weeklyStructure),
      focus_areas: JSON.stringify(input.focusAreas),
      is_active: true,
    })
    .returning('*');

  res.json({
    success: true,
    data: { architecture },
  });
};

/**
 * Update training architecture
 */
export const updateTrainingArchitecture = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user!.id;
  const { id } = req.params;
  const updates = req.body;

  const dbUpdates: any = {
    updated_at: new Date(),
  };

  if (updates.name) dbUpdates.name = updates.name;
  if (updates.description) dbUpdates.description = updates.description;
  if (updates.weeksToRace) dbUpdates.weeks_to_race = updates.weeksToRace;
  if (updates.raceDate) dbUpdates.race_date = new Date(updates.raceDate);
  if (updates.workoutsPerWeek) dbUpdates.workouts_per_week = updates.workoutsPerWeek;
  if (updates.weeklyStructure) dbUpdates.weekly_structure = JSON.stringify(updates.weeklyStructure);
  if (updates.focusAreas) dbUpdates.focus_areas = JSON.stringify(updates.focusAreas);
  if (typeof updates.isActive === 'boolean') dbUpdates.is_active = updates.isActive;

  const [architecture] = await db('training_architectures')
    .where({ id, user_id: userId })
    .update(dbUpdates)
    .returning('*');

  if (!architecture) {
    throw new AppError(404, 'Training architecture not found');
  }

  res.json({
    success: true,
    data: { architecture },
  });
};
