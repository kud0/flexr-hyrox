import db from '../../config/database';
import logger from '../../utils/logger';

interface ProgressData {
  summary: {
    totalWorkouts: number;
    completedWorkouts: number;
    completionRate: number;
    totalDistanceKm: number;
    totalDurationMinutes: number;
    avgReadinessScore: number;
  };
  byType: Record<string, {
    planned: number;
    completed: number;
    completionRate: number;
    totalDuration: number;
  }>;
  timeline: Array<{
    period: string;
    workouts: number;
    distance: number;
    duration: number;
  }>;
  trends: {
    workoutFrequency: string;
    distanceTrend: string;
    readinessTrend: string;
  };
}

/**
 * Calculate comprehensive progress metrics
 */
export async function calculateProgress(
  userId: string,
  startDate?: string,
  endDate?: string,
  granularity: 'day' | 'week' | 'month' = 'week'
): Promise<ProgressData> {
  const start = startDate ? new Date(startDate) : getDefaultStartDate();
  const end = endDate ? new Date(endDate) : new Date();

  logger.info(`Calculating progress for user ${userId} from ${start} to ${end}`);

  // Get workouts in date range
  const workouts = await db('workouts')
    .where({ user_id: userId })
    .whereBetween('scheduled_date', [start, end]);

  const completedWorkouts = workouts.filter((w) => w.status === 'completed');

  // Get segments for distance calculation
  const completedWorkoutIds = completedWorkouts.map((w) => w.id);
  const segments = completedWorkoutIds.length > 0
    ? await db('workout_segments')
        .whereIn('workout_id', completedWorkoutIds)
        .where('completion_status', 'completed')
    : [];

  // Summary metrics
  const totalDistance = segments.reduce((sum, s) => sum + (parseFloat(s.actual_distance_km) || 0), 0);
  const totalDuration = completedWorkouts.reduce((sum, w) => sum + (w.total_duration_minutes || 0), 0);

  const readinessScores = completedWorkouts
    .filter((w) => w.readiness_score != null)
    .map((w) => w.readiness_score);

  const avgReadiness = readinessScores.length > 0
    ? readinessScores.reduce((sum, s) => sum + s, 0) / readinessScores.length
    : 0;

  // By type breakdown
  const byType: Record<string, any> = {};
  ['strength', 'running', 'hybrid', 'recovery', 'race_sim'].forEach((type) => {
    const typeWorkouts = workouts.filter((w) => w.type === type);
    const typeCompleted = typeWorkouts.filter((w) => w.status === 'completed');

    byType[type] = {
      planned: typeWorkouts.length,
      completed: typeCompleted.length,
      completionRate: typeWorkouts.length > 0 ? (typeCompleted.length / typeWorkouts.length) * 100 : 0,
      totalDuration: typeCompleted.reduce((sum, w) => sum + (w.total_duration_minutes || 0), 0),
    };
  });

  // Timeline data
  const timeline = generateTimeline(completedWorkouts, segments, start, end, granularity);

  // Trends analysis
  const trends = calculateTrends(timeline);

  return {
    summary: {
      totalWorkouts: workouts.length,
      completedWorkouts: completedWorkouts.length,
      completionRate: workouts.length > 0 ? (completedWorkouts.length / workouts.length) * 100 : 0,
      totalDistanceKm: Math.round(totalDistance * 10) / 10,
      totalDurationMinutes: totalDuration,
      avgReadinessScore: Math.round(avgReadiness * 10) / 10,
    },
    byType,
    timeline,
    trends,
  };
}

/**
 * Generate timeline data grouped by period
 */
function generateTimeline(
  workouts: any[],
  segments: any[],
  start: Date,
  end: Date,
  granularity: 'day' | 'week' | 'month'
): Array<any> {
  const timeline: Record<string, any> = {};

  workouts.forEach((workout) => {
    const period = getPeriodKey(new Date(workout.completed_at), granularity);

    if (!timeline[period]) {
      timeline[period] = {
        period,
        workouts: 0,
        distance: 0,
        duration: 0,
      };
    }

    timeline[period].workouts++;
    timeline[period].duration += workout.total_duration_minutes || 0;
  });

  segments.forEach((segment) => {
    const workout = workouts.find((w) => w.id === segment.workout_id);
    if (workout) {
      const period = getPeriodKey(new Date(workout.completed_at), granularity);
      if (timeline[period]) {
        timeline[period].distance += parseFloat(segment.actual_distance_km) || 0;
      }
    }
  });

  // Convert to array and sort
  return Object.values(timeline).sort((a, b) => a.period.localeCompare(b.period));
}

/**
 * Get period key based on granularity
 */
function getPeriodKey(date: Date, granularity: 'day' | 'week' | 'month'): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');

  switch (granularity) {
    case 'day':
      return `${year}-${month}-${day}`;
    case 'week':
      const weekNum = getWeekNumber(date);
      return `${year}-W${String(weekNum).padStart(2, '0')}`;
    case 'month':
      return `${year}-${month}`;
    default:
      return `${year}-${month}-${day}`;
  }
}

/**
 * Get ISO week number
 */
function getWeekNumber(date: Date): number {
  const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
  const dayNum = d.getUTCDay() || 7;
  d.setUTCDate(d.getUTCDate() + 4 - dayNum);
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  return Math.ceil((((d.getTime() - yearStart.getTime()) / 86400000) + 1) / 7);
}

/**
 * Calculate trends from timeline data
 */
function calculateTrends(timeline: Array<any>): any {
  if (timeline.length < 2) {
    return {
      workoutFrequency: 'stable',
      distanceTrend: 'stable',
      readinessTrend: 'stable',
    };
  }

  const recentPeriods = timeline.slice(-4); // Last 4 periods
  const olderPeriods = timeline.slice(-8, -4); // Previous 4 periods

  // Workout frequency trend
  const recentAvgWorkouts = recentPeriods.reduce((sum, p) => sum + p.workouts, 0) / recentPeriods.length;
  const olderAvgWorkouts = olderPeriods.length > 0
    ? olderPeriods.reduce((sum, p) => sum + p.workouts, 0) / olderPeriods.length
    : recentAvgWorkouts;

  const workoutChange = recentAvgWorkouts - olderAvgWorkouts;
  const workoutFrequency = workoutChange > 0.5 ? 'increasing' : workoutChange < -0.5 ? 'decreasing' : 'stable';

  // Distance trend
  const recentAvgDistance = recentPeriods.reduce((sum, p) => sum + p.distance, 0) / recentPeriods.length;
  const olderAvgDistance = olderPeriods.length > 0
    ? olderPeriods.reduce((sum, p) => sum + p.distance, 0) / olderPeriods.length
    : recentAvgDistance;

  const distanceChange = recentAvgDistance - olderAvgDistance;
  const distanceTrend = distanceChange > 1 ? 'increasing' : distanceChange < -1 ? 'decreasing' : 'stable';

  return {
    workoutFrequency,
    distanceTrend,
    readinessTrend: 'stable', // Would need readiness data in timeline
  };
}

/**
 * Get default start date (90 days ago)
 */
function getDefaultStartDate(): Date {
  const date = new Date();
  date.setDate(date.getDate() - 90);
  return date;
}

/**
 * Generate weekly summary
 */
export async function generateWeeklySummary(userId: string, weekStarting: Date): Promise<any> {
  const weekEnding = new Date(weekStarting);
  weekEnding.setDate(weekEnding.getDate() + 7);

  const workouts = await db('workouts')
    .where({ user_id: userId })
    .whereBetween('scheduled_date', [weekStarting, weekEnding]);

  const completed = workouts.filter((w) => w.status === 'completed');

  // Get segments
  const completedIds = completed.map((w) => w.id);
  const segments = completedIds.length > 0
    ? await db('workout_segments')
        .whereIn('workout_id', completedIds)
        .where('completion_status', 'completed')
    : [];

  const totalDistance = segments.reduce((sum, s) => sum + (parseFloat(s.actual_distance_km) || 0), 0);
  const totalDuration = completed.reduce((sum, w) => sum + (w.total_duration_minutes || 0), 0);

  const readinessScores = completed
    .filter((w) => w.readiness_score != null)
    .map((w) => w.readiness_score);

  const avgReadiness = readinessScores.length > 0
    ? readinessScores.reduce((sum, s) => sum + s, 0) / readinessScores.length
    : null;

  // Breakdown by type
  const breakdown: Record<string, number> = {};
  completed.forEach((w) => {
    breakdown[w.type] = (breakdown[w.type] || 0) + 1;
  });

  // Insert/update summary
  const [summary] = await db('weekly_summaries')
    .insert({
      user_id: userId,
      week_starting: weekStarting,
      week_ending: weekEnding,
      workouts_planned: workouts.length,
      workouts_completed: completed.length,
      total_duration_minutes: totalDuration,
      total_distance_km: totalDistance,
      avg_readiness_score: avgReadiness,
      workout_breakdown: JSON.stringify(breakdown),
    })
    .onConflict(['user_id', 'week_starting'])
    .merge()
    .returning('*');

  logger.info(`Generated weekly summary for user ${userId}, week ${weekStarting.toISOString()}`);

  return summary;
}
