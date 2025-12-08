/**
 * Weight Prescription Service
 * Calculates appropriate weights for exercises based on:
 * - User PRs (squat, deadlift)
 * - Fitness level (beginner, intermediate, advanced, elite)
 * - Gender
 * - Feedback and learning
 */

import { FitnessLevel, Gender } from '../../models/user.model';
import { UserPerformanceBenchmarks } from '../../models/onboarding.model';

// ====================
// Weight Estimates by Fitness Level
// ====================

interface WeightEstimates {
  sled_push: number; // kg
  sled_pull: number;
  kettlebell: number;
  dumbbell: number;
  sandbag: number;
  farmers_carry_each: number;
  wall_ball: number;
}

const MALE_WEIGHT_ESTIMATES: Record<FitnessLevel, WeightEstimates> = {
  beginner: {
    sled_push: 40,
    sled_pull: 25,
    kettlebell: 12,
    dumbbell: 10,
    sandbag: 20,
    farmers_carry_each: 16,
    wall_ball: 6,
  },
  intermediate: {
    sled_push: 70,
    sled_pull: 40,
    kettlebell: 20,
    dumbbell: 16,
    sandbag: 30,
    farmers_carry_each: 24,
    wall_ball: 9,
  },
  advanced: {
    sled_push: 100,
    sled_pull: 60,
    kettlebell: 28,
    dumbbell: 24,
    sandbag: 40,
    farmers_carry_each: 32,
    wall_ball: 9,
  },
  elite: {
    sled_push: 140,
    sled_pull: 85,
    kettlebell: 32,
    dumbbell: 32,
    sandbag: 50,
    farmers_carry_each: 40,
    wall_ball: 9,
  },
};

// Female estimates (~65% of male)
const FEMALE_MULTIPLIER = 0.65;

// ====================
// PR-Based Calculation Multipliers
// ====================

interface PRMultipliers {
  sled_push: number; // % of squat PR
  sled_pull: number;
  farmers_carry_each: number; // % of deadlift PR
  sandbag: number;
  goblet_squat: number;
}

const PR_MULTIPLIERS: PRMultipliers = {
  sled_push: 0.6, // 60% of squat PR
  sled_pull: 0.4, // 40% of squat PR
  farmers_carry_each: 0.25, // 25% of deadlift PR each hand
  sandbag: 0.4, // 40% of deadlift PR
  goblet_squat: 0.3, // 30% of squat PR
};

// ====================
// Main Weight Prescription Function
// ====================

export interface WeightPrescription {
  exercise: string;
  weight_kg: number;
  source: 'pr_based' | 'level_estimate' | 'user_pr';
  confidence: number; // 0.0 to 1.0
  notes?: string;
}

export interface PrescriptionOptions {
  user_id: string;
  fitness_level: FitnessLevel;
  gender: Gender;
  benchmarks?: UserPerformanceBenchmarks;
  week_number?: number; // For progressive overload
  conservative_start?: boolean; // First week = reduce by 20%
}

/**
 * Get weight prescription for a specific exercise
 */
export function prescribeWeight(
  exercise: string,
  options: PrescriptionOptions
): WeightPrescription {
  const { fitness_level, gender, benchmarks, week_number = 1, conservative_start = false } = options;

  let weight_kg: number;
  let source: 'pr_based' | 'level_estimate' | 'user_pr';
  let confidence: number;
  let notes: string | undefined;

  // Check if user has PRs for this exercise
  if (benchmarks) {
    // Try PR-based calculation first
    const prBased = calculateFromPR(exercise, benchmarks);
    if (prBased) {
      weight_kg = prBased.weight;
      source = 'pr_based';
      confidence = 0.85;
      notes = prBased.notes;
    } else {
      // Check if user has actual PR for this exercise
      const userPR = getUserExercisePR(exercise, benchmarks);
      if (userPR) {
        weight_kg = userPR;
        source = 'user_pr';
        confidence = 1.0;
        notes = 'Using your recorded PR';
      } else {
        // Fall back to fitness level estimate
        const estimate = estimateFromFitnessLevel(exercise, fitness_level, gender);
        weight_kg = estimate.weight;
        source = 'level_estimate';
        confidence = 0.6;
        notes = estimate.notes;
      }
    }
  } else {
    // No benchmarks, use fitness level
    const estimate = estimateFromFitnessLevel(exercise, fitness_level, gender);
    weight_kg = estimate.weight;
    source = 'level_estimate';
    confidence = 0.6;
    notes = estimate.notes;
  }

  // Apply conservative start (Week 1 = 80% of calculated weight)
  if (conservative_start && week_number === 1) {
    weight_kg *= 0.8;
    confidence *= 0.9;
    notes = (notes || '') + ' | Week 1: Starting conservative (-20%)';
  }

  // Round to nearest 2.5kg for practical loading
  weight_kg = Math.round(weight_kg / 2.5) * 2.5;

  return {
    exercise,
    weight_kg,
    source,
    confidence,
    notes,
  };
}

/**
 * Calculate weight from PRs (squat, deadlift)
 */
function calculateFromPR(
  exercise: string,
  benchmarks: UserPerformanceBenchmarks
): { weight: number; notes: string } | null {
  const { squat_pr_kg, deadlift_pr_kg } = benchmarks;

  switch (exercise.toLowerCase()) {
    case 'sled_push':
    case 'sled push':
      if (squat_pr_kg) {
        return {
          weight: squat_pr_kg * PR_MULTIPLIERS.sled_push,
          notes: `Calculated from squat PR (${squat_pr_kg}kg × 0.6)`,
        };
      }
      break;

    case 'sled_pull':
    case 'sled pull':
      if (squat_pr_kg) {
        return {
          weight: squat_pr_kg * PR_MULTIPLIERS.sled_pull,
          notes: `Calculated from squat PR (${squat_pr_kg}kg × 0.4)`,
        };
      }
      break;

    case 'farmers_carry':
    case 'farmers carry':
      if (deadlift_pr_kg) {
        return {
          weight: deadlift_pr_kg * PR_MULTIPLIERS.farmers_carry_each,
          notes: `Calculated from deadlift PR (${deadlift_pr_kg}kg × 0.25 each hand)`,
        };
      }
      break;

    case 'sandbag':
    case 'sandbag_lunges':
      if (deadlift_pr_kg) {
        return {
          weight: deadlift_pr_kg * PR_MULTIPLIERS.sandbag,
          notes: `Calculated from deadlift PR (${deadlift_pr_kg}kg × 0.4)`,
        };
      }
      break;

    case 'goblet_squat':
    case 'goblet squat':
      if (squat_pr_kg) {
        return {
          weight: squat_pr_kg * PR_MULTIPLIERS.goblet_squat,
          notes: `Calculated from squat PR (${squat_pr_kg}kg × 0.3)`,
        };
      }
      break;
  }

  return null;
}

/**
 * Get user's actual PR for exercise if available
 */
function getUserExercisePR(exercise: string, benchmarks: UserPerformanceBenchmarks): number | null {
  switch (exercise.toLowerCase()) {
    case 'sled_push':
    case 'sled push':
      return benchmarks.sled_push_weight_kg || null;

    case 'sled_pull':
    case 'sled pull':
      return benchmarks.sled_pull_weight_kg || null;

    case 'farmers_carry':
    case 'farmers carry':
      return benchmarks.farmers_carry_weight_kg || null;

    case 'wall_ball':
    case 'wall balls':
      // Wall ball weight is standard, but check if user has preference
      return null; // Let it fall through to estimate

    default:
      return null;
  }
}

/**
 * Estimate weight from fitness level
 */
function estimateFromFitnessLevel(
  exercise: string,
  fitness_level: FitnessLevel,
  gender: Gender
): { weight: number; notes: string } {
  const baseEstimates = MALE_WEIGHT_ESTIMATES[fitness_level];

  let weight = 0;
  let exerciseKey = '';

  // Map exercise name to key
  switch (exercise.toLowerCase()) {
    case 'sled_push':
    case 'sled push':
      exerciseKey = 'sled_push';
      break;
    case 'sled_pull':
    case 'sled pull':
      exerciseKey = 'sled_pull';
      break;
    case 'kettlebell':
    case 'kettlebell_swing':
      exerciseKey = 'kettlebell';
      break;
    case 'dumbbell':
    case 'dumbbell_press':
      exerciseKey = 'dumbbell';
      break;
    case 'sandbag':
    case 'sandbag_lunges':
      exerciseKey = 'sandbag';
      break;
    case 'farmers_carry':
    case 'farmers carry':
      exerciseKey = 'farmers_carry_each';
      break;
    case 'wall_ball':
    case 'wall balls':
      exerciseKey = 'wall_ball';
      break;
    default:
      // Default to moderate weight
      weight = 20;
      exerciseKey = 'unknown';
  }

  if (exerciseKey !== 'unknown') {
    weight = baseEstimates[exerciseKey as keyof WeightEstimates];
  }

  // Apply gender adjustment
  if (gender === 'female') {
    weight *= FEMALE_MULTIPLIER;
  }

  return {
    weight,
    notes: `Estimated for ${fitness_level} ${gender}`,
  };
}

/**
 * Batch prescribe weights for multiple exercises
 */
export function prescribeWorkoutWeights(
  exercises: string[],
  options: PrescriptionOptions
): WeightPrescription[] {
  return exercises.map((exercise) => prescribeWeight(exercise, options));
}

/**
 * Adjust weight based on feedback
 */
export interface FeedbackAdjustment {
  current_weight: number;
  rpe: number; // 1-10
  could_do_more: 'yes' | 'maybe' | 'no';
}

export function adjustWeightFromFeedback(feedback: FeedbackAdjustment): {
  new_weight: number;
  change_percent: number;
  reasoning: string;
} {
  const { current_weight, rpe, could_do_more } = feedback;

  let multiplier = 1.0;
  let reasoning = '';

  // RPE-based adjustment
  if (rpe <= 4) {
    // Too easy
    multiplier = 1.2; // +20%
    reasoning = 'RPE too low (≤4) - increasing 20%';
  } else if (rpe <= 6) {
    // A bit easy
    multiplier = 1.1; // +10%
    reasoning = 'RPE moderate-low (5-6) - increasing 10%';
  } else if (rpe === 7 || rpe === 8) {
    // Perfect zone
    if (could_do_more === 'yes') {
      multiplier = 1.05; // +5% for progression
      reasoning = 'RPE good (7-8) but could do more - small increase';
    } else {
      multiplier = 1.0; // Maintain
      reasoning = 'RPE perfect (7-8) - maintaining weight';
    }
  } else if (rpe === 9) {
    // Hard
    multiplier = 0.95; // -5%
    reasoning = 'RPE high (9) - reducing 5%';
  } else if (rpe >= 10) {
    // Too hard
    multiplier = 0.9; // -10%
    reasoning = 'RPE too high (10) - reducing 10%';
  }

  // Could do more override
  if (could_do_more === 'yes' && multiplier < 1.1) {
    multiplier = 1.15; // +15%
    reasoning = 'Could do significantly more - increasing 15%';
  } else if (could_do_more === 'no' && multiplier > 0.95) {
    multiplier = 0.95; // -5%
    reasoning = 'At limit - small reduction';
  }

  const new_weight = Math.round((current_weight * multiplier) / 2.5) * 2.5; // Round to 2.5kg
  const change_percent = ((new_weight - current_weight) / current_weight) * 100;

  return {
    new_weight,
    change_percent,
    reasoning,
  };
}

/**
 * Progressive overload calculator (weekly progression)
 */
export function calculateProgressiveOverload(
  base_weight: number,
  week_number: number,
  progression_rate: 'slow' | 'moderate' | 'aggressive' = 'moderate'
): number {
  const rates = {
    slow: 0.025, // 2.5% per week
    moderate: 0.05, // 5% per week
    aggressive: 0.075, // 7.5% per week
  };

  const rate = rates[progression_rate];
  const new_weight = base_weight * (1 + rate * (week_number - 1));

  // Round to nearest 2.5kg
  return Math.round(new_weight / 2.5) * 2.5;
}
