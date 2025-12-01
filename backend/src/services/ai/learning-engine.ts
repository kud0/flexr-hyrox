import db from '../../config/database';
import env from '../../config/env';
import logger from '../../utils/logger';
import { LearningContext, PerformanceProfile } from '../../models/performance.model';

/**
 * Update performance profile with weekly learning (0.7 old + 0.3 new weighting)
 */
export async function updatePerformanceProfile(
  userId: string,
  weekStarting: Date
): Promise<PerformanceProfile> {
  const weekEnding = new Date(weekStarting);
  weekEnding.setDate(weekEnding.getDate() + 7);

  // Get previous profile
  const previousProfile = await db('performance_profiles')
    .where({ user_id: userId })
    .where('week_starting', '<', weekStarting)
    .orderBy('week_starting', 'desc')
    .first();

  // Get completed workouts for this week
  const weekWorkouts = await db('workouts')
    .where({ user_id: userId, status: 'completed' })
    .whereBetween('completed_at', [weekStarting, weekEnding]);

  // Get workout segments for detailed analysis
  const workoutIds = weekWorkouts.map((w) => w.id);
  const segments = workoutIds.length > 0
    ? await db('workout_segments')
        .whereIn('workout_id', workoutIds)
        .where('completion_status', 'completed')
    : [];

  // Calculate new metrics
  const newMetrics = calculateWeeklyMetrics(weekWorkouts, segments);

  // Apply weighted learning (0.7 old + 0.3 new)
  const weightOld = env.AI_LEARNING_WEIGHT_OLD;
  const weightNew = env.AI_LEARNING_WEIGHT_NEW;

  const profile: any = {
    user_id: userId,
    week_starting: weekStarting,
    version: (previousProfile?.version || 0) + 1,
  };

  // Running metrics
  profile.avg_pace_km = newMetrics.avgPaceKm;
  profile.total_running_distance_km = newMetrics.totalRunningDistanceKm;
  profile.compromised_running_count = newMetrics.compromisedRunningCount;

  // Strength metrics
  profile.strength_sessions_completed = newMetrics.strengthSessionsCompleted;
  profile.strength_progression = JSON.stringify(newMetrics.strengthProgression);

  // Recovery metrics
  profile.avg_readiness_score = newMetrics.avgReadinessScore;
  profile.recovery_sessions_completed = newMetrics.recoverySessionsCompleted;

  // Confidence levels (weighted)
  if (previousProfile) {
    profile.running_confidence = weightOld * previousProfile.running_confidence + weightNew * newMetrics.runningConfidence;
    profile.strength_confidence = weightOld * previousProfile.strength_confidence + weightNew * newMetrics.strengthConfidence;
    profile.endurance_confidence = weightOld * previousProfile.endurance_confidence + weightNew * newMetrics.enduranceConfidence;
  } else {
    // No previous profile - use new metrics directly
    profile.running_confidence = newMetrics.runningConfidence;
    profile.strength_confidence = newMetrics.strengthConfidence;
    profile.endurance_confidence = newMetrics.enduranceConfidence;
  }

  // Completion rates
  profile.workout_completion_rate = JSON.stringify(newMetrics.completionRate);

  // AI adjustments tracking
  profile.ai_adjustments = JSON.stringify({
    compromised_running_detected: newMetrics.compromisedRunningCount >= 2,
    low_readiness_detected: newMetrics.avgReadinessScore < 60,
    confidence_changes: previousProfile ? {
      running: profile.running_confidence - previousProfile.running_confidence,
      strength: profile.strength_confidence - previousProfile.strength_confidence,
      endurance: profile.endurance_confidence - previousProfile.endurance_confidence,
    } : null,
  });

  // Insert or update profile
  const [updatedProfile] = await db('performance_profiles')
    .insert(profile)
    .onConflict(['user_id', 'week_starting'])
    .merge()
    .returning('*');

  logger.info(`Updated performance profile for user ${userId}, week ${weekStarting.toISOString()}`);

  return updatedProfile;
}

/**
 * Calculate weekly metrics from workouts
 */
function calculateWeeklyMetrics(workouts: any[], segments: any[]) {
  const metrics: any = {
    avgPaceKm: null,
    totalRunningDistanceKm: 0,
    compromisedRunningCount: 0,
    strengthSessionsCompleted: 0,
    strengthProgression: {},
    avgReadinessScore: null,
    recoverySessionsCompleted: 0,
    runningConfidence: 0.5,
    strengthConfidence: 0.5,
    enduranceConfidence: 0.5,
    completionRate: {},
  };

  if (workouts.length === 0) {
    return metrics;
  }

  // Running analysis
  const runningSegments = segments.filter((s) => s.type === 'cardio' || s.type === 'hybrid');
  if (runningSegments.length > 0) {
    const totalDistance = runningSegments.reduce((sum, s) => sum + (s.actual_distance_km || 0), 0);
    const totalPaceSum = runningSegments
      .filter((s) => s.actual_pace)
      .reduce((sum, s) => sum + parsePace(s.actual_pace), 0);

    metrics.totalRunningDistanceKm = totalDistance;
    metrics.avgPaceKm = totalPaceSum / runningSegments.length;

    // Detect compromised running (< 3km in a session)
    const hybridWorkouts = workouts.filter((w) => w.type === 'hybrid');
    for (const workout of hybridWorkouts) {
      const workoutRunning = segments
        .filter((s) => s.workout_id === workout.id && (s.type === 'cardio' || s.type === 'hybrid'))
        .reduce((sum, s) => sum + (s.actual_distance_km || 0), 0);

      if (workoutRunning < 3) {
        metrics.compromisedRunningCount++;
      }
    }

    // Running confidence based on consistency and volume
    const avgSessionDistance = totalDistance / runningSegments.length;
    metrics.runningConfidence = Math.min(
      1.0,
      (avgSessionDistance / 5.0) * 0.5 + // Distance component
      (runningSegments.length / 3) * 0.3 + // Consistency component
      (metrics.compromisedRunningCount === 0 ? 0.2 : 0) // No compromised sessions bonus
    );
  }

  // Strength analysis
  const strengthWorkouts = workouts.filter((w) => w.type === 'strength' || w.type === 'hybrid');
  metrics.strengthSessionsCompleted = strengthWorkouts.length;

  const strengthSegments = segments.filter((s) => s.type === 'strength' && s.exercises);
  if (strengthSegments.length > 0) {
    // Track progression (simplified - could be more sophisticated)
    const exerciseWeights: Record<string, number[]> = {};

    strengthSegments.forEach((seg) => {
      const exercises = typeof seg.exercises === 'string' ? JSON.parse(seg.exercises) : seg.exercises;
      exercises?.forEach((ex: any) => {
        if (ex.weight_kg) {
          if (!exerciseWeights[ex.name]) {
            exerciseWeights[ex.name] = [];
          }
          exerciseWeights[ex.name].push(ex.weight_kg);
        }
      });
    });

    metrics.strengthProgression = exerciseWeights;

    // Strength confidence based on consistency
    metrics.strengthConfidence = Math.min(
      1.0,
      (metrics.strengthSessionsCompleted / 2) * 0.6 + 0.4
    );
  }

  // Recovery analysis
  metrics.recoverySessionsCompleted = workouts.filter((w) => w.type === 'recovery').length;

  const readinessScores = workouts
    .filter((w) => w.readiness_score != null)
    .map((w) => w.readiness_score);

  if (readinessScores.length > 0) {
    metrics.avgReadinessScore = readinessScores.reduce((sum, s) => sum + s, 0) / readinessScores.length;
  }

  // Endurance confidence (combination of running + workout completion)
  const completedCount = workouts.length;
  metrics.enduranceConfidence = Math.min(
    1.0,
    (completedCount / 4) * 0.5 + // Completion consistency
    (metrics.totalRunningDistanceKm / 15) * 0.5 // Volume component
  );

  // Completion rate by type
  const workoutsByType: Record<string, number> = {};
  workouts.forEach((w) => {
    workoutsByType[w.type] = (workoutsByType[w.type] || 0) + 1;
  });

  metrics.completionRate = workoutsByType;

  return metrics;
}

/**
 * Parse pace string (e.g., "5:30/km") to decimal minutes
 */
function parsePace(paceStr: string): number {
  try {
    const match = paceStr.match(/(\d+):(\d+)/);
    if (match) {
      return parseInt(match[1]) + parseInt(match[2]) / 60;
    }
  } catch (error) {
    logger.warn(`Failed to parse pace: ${paceStr}`);
  }
  return 0;
}

/**
 * Get learning context for AI workout generation
 */
export async function getLearningContext(userId: string): Promise<LearningContext> {
  const user = await db('users').where({ id: userId }).first();

  const currentProfile = await db('performance_profiles')
    .where({ user_id: userId })
    .orderBy('week_starting', 'desc')
    .first();

  const previousProfiles = await db('performance_profiles')
    .where({ user_id: userId })
    .orderBy('week_starting', 'desc')
    .limit(4)
    .offset(1);

  const recentWorkouts = await db('workouts')
    .where({ user_id: userId })
    .where('completed_at', '>=', db.raw("NOW() - INTERVAL '14 days'"))
    .orderBy('completed_at', 'desc');

  // Count compromised running sessions
  const compromisedCount = currentProfile?.compromised_running_count || 0;

  return {
    user_id: userId,
    current_profile: currentProfile,
    previous_profiles: previousProfiles,
    recent_workouts: recentWorkouts,
    compromised_running_sessions: compromisedCount,
    fitness_level: user.fitness_level,
    goals: user.goals,
    injuries: user.injuries,
  };
}

/**
 * Trigger weekly profile update (called by cron or after workout completion)
 */
export async function triggerWeeklyUpdate(userId: string): Promise<void> {
  const now = new Date();
  const weekStarting = getWeekStartDate(now);

  // Check if profile already exists for this week
  const existing = await db('performance_profiles')
    .where({ user_id: userId, week_starting: weekStarting })
    .first();

  if (!existing) {
    await updatePerformanceProfile(userId, weekStarting);
    logger.info(`Created new performance profile for user ${userId}`);
  } else {
    // Update existing profile with latest data
    await updatePerformanceProfile(userId, weekStarting);
    logger.info(`Updated existing performance profile for user ${userId}`);
  }
}

/**
 * Get start of week (Monday)
 */
function getWeekStartDate(date: Date): Date {
  const d = new Date(date);
  const day = d.getDay();
  const diff = d.getDate() - day + (day === 0 ? -6 : 1); // Adjust when day is Sunday
  d.setDate(diff);
  d.setHours(0, 0, 0, 0);
  return d;
}
