import env from '../../config/env';
import logger from '../../utils/logger';
import { GenerateWorkoutRequest, CreateWorkoutInput, CreateSegmentInput } from '../../models/workout.model';
import supabaseAdmin from '../../config/supabase';
import grokClient from './grok-client';

interface GeneratedWorkoutData {
  title: string;
  description: string;
  type: string;
  difficulty: string;
  total_duration_minutes: number;
  segments: CreateSegmentInput[];
  ai_context: Record<string, any>;
}

/**
 * Generate AI-powered workout based on user profile, training architecture, and readiness
 */
export async function generateAIWorkout(
  request: GenerateWorkoutRequest,
  user: any,
  architecture: any
): Promise<GeneratedWorkoutData> {
  try {
    // Get performance profile for learning context
    const { data: performanceProfile } = await supabaseAdmin
      .from('performance_profiles')
      .select('*')
      .eq('user_id', request.user_id)
      .order('week_starting', { ascending: false })
      .limit(1)
      .single();

    // Get recent workouts for context
    const twoWeeksAgo = new Date();
    twoWeeksAgo.setDate(twoWeeksAgo.getDate() - 14);

    const { data: recentWorkouts } = await supabaseAdmin
      .from('workouts')
      .select('*')
      .eq('user_id', request.user_id)
      .gte('completed_at', twoWeeksAgo.toISOString())
      .order('completed_at', { ascending: false })
      .limit(5);

    // Build AI prompt
    const prompt = buildWorkoutPrompt(request, user, architecture, performanceProfile, recentWorkouts);

    logger.info(`Generating workout for user ${request.user_id} with readiness ${request.readiness_score}`);

    // Call Grok AI
    const response = await grokClient.createChatCompletion(
      [
        {
          role: 'system',
          content: `You are an expert HYROX training coach. Generate structured workouts that balance running and strength training.

CRITICAL RULES:
1. ALWAYS include meaningful running volume (minimum 3km for hybrid workouts)
2. Track "compromised running" - sessions with less than 3km running damage long-term performance
3. Adjust difficulty based on readiness score (0-100 scale)
4. Consider performance profile confidence levels for exercise selection
5. Return ONLY valid JSON, no additional text or markdown

Response format:
{
  "title": "Workout Title",
  "description": "Brief description",
  "type": "hybrid|strength|running|recovery|race_sim",
  "difficulty": "easy|moderate|hard|very_hard",
  "totalDurationMinutes": 60,
  "segments": [
    {
      "orderIndex": 0,
      "type": "warmup|strength|cardio|hybrid|cooldown",
      "name": "Segment Name",
      "instructions": "Detailed instructions",
      "durationMinutes": 10,
      "sets": 3,
      "reps": 10,
      "distanceKm": 5.0,
      "targetPace": "5:30/km",
      "targetHeartRate": "140-160 bpm",
      "restSeconds": 60,
      "exercises": [
        {
          "name": "Exercise Name",
          "sets": 3,
          "reps": 10,
          "weightKg": 20,
          "restSeconds": 60,
          "instructions": "Form cues",
          "tempo": "3-0-1-0"
        }
      ]
    }
  ]
}`,
        },
        {
          role: 'user',
          content: prompt,
        },
      ],
      {
        temperature: env.AI_TEMPERATURE,
        maxTokens: env.AI_WORKOUT_MAX_TOKENS,
      }
    );

    // Parse AI response (handles markdown code blocks)
    const workoutData = grokClient.parseJsonResponse(response);

    // Validate and transform
    const workout: GeneratedWorkoutData = {
      title: workoutData.title,
      description: workoutData.description,
      type: workoutData.type,
      difficulty: workoutData.difficulty,
      total_duration_minutes: workoutData.totalDurationMinutes,
      segments: workoutData.segments.map((seg: any) => ({
        order_index: seg.orderIndex,
        type: seg.type,
        name: seg.name,
        instructions: seg.instructions,
        duration_minutes: seg.durationMinutes,
        sets: seg.sets,
        reps: seg.reps,
        distance_km: seg.distanceKm,
        target_pace: seg.targetPace,
        target_heart_rate: seg.targetHeartRate,
        rest_seconds: seg.restSeconds,
        exercises: seg.exercises,
        metadata: seg.metadata,
      })),
      ai_context: {
        readiness_score: request.readiness_score,
        performance_profile_version: performanceProfile?.version || 0,
        ai_model: env.GROK_MODEL,
        generated_at: new Date().toISOString(),
        prompt_tokens: response.usage?.prompt_tokens,
        completion_tokens: response.usage?.completion_tokens,
      },
    };

    logger.info(`Generated ${workout.type} workout: ${workout.title}`);

    return workout;
  } catch (error) {
    logger.error('Failed to generate AI workout:', error);
    throw new Error('Failed to generate workout. Please try again.');
  }
}

/**
 * Build comprehensive prompt for workout generation
 */
function buildWorkoutPrompt(
  request: GenerateWorkoutRequest,
  user: any,
  architecture: any,
  performanceProfile: any,
  recentWorkouts: any[]
): string {
  const sections = [];

  // User Profile
  sections.push(`USER PROFILE:
- Fitness Level: ${user.fitness_level}
- Age: ${user.age || 'Not specified'}
- Goals: ${user.goals?.join(', ') || 'General fitness'}
- Injuries: ${user.injuries?.length > 0 ? user.injuries.join(', ') : 'None'}
- Readiness Score: ${request.readiness_score}/100`);

  // Training Architecture
  sections.push(`TRAINING PLAN:
- Plan: ${architecture.name}
- Weeks to Race: ${architecture.weeks_to_race}
- Focus Areas: ${architecture.focus_areas?.join(', ') || 'Balanced'}
- Workouts per Week: ${architecture.workouts_per_week}`);

  // Performance Profile (AI Learning)
  if (performanceProfile) {
    sections.push(`PERFORMANCE INSIGHTS (AI Learning):
- Running Confidence: ${(performanceProfile.running_confidence * 100).toFixed(0)}%
- Strength Confidence: ${(performanceProfile.strength_confidence * 100).toFixed(0)}%
- Endurance Confidence: ${(performanceProfile.endurance_confidence * 100).toFixed(0)}%
- Avg Pace: ${performanceProfile.avg_pace_km ? performanceProfile.avg_pace_km + ' min/km' : 'N/A'}
- Compromised Running Count: ${performanceProfile.compromised_running_count} (WARNING if ≥2)
- Avg Readiness: ${performanceProfile.avg_readiness_score || 'N/A'}`);
  }

  // Recent Workouts Context
  if (recentWorkouts && recentWorkouts.length > 0) {
    sections.push(`RECENT WORKOUTS (Last 2 weeks):
${recentWorkouts.map((w, i) => `${i + 1}. ${w.type} - ${w.status} - ${w.difficulty}`).join('\n')}`);
  }

  // Workout Requirements
  sections.push(`WORKOUT REQUIREMENTS:
- Scheduled Date: ${request.scheduled_date.toISOString().split('T')[0]}
- Preferred Type: ${request.preferred_type || 'Based on training plan'}
- Time Available: ${request.time_available_minutes || architecture.workouts_per_week * 60} minutes
- Location: ${request.location || 'gym'}`);

  // Specific Instructions
  sections.push(`INSTRUCTIONS:
1. Create a ${request.preferred_type || 'balanced'} workout appropriate for readiness score ${request.readiness_score}/100
2. If readiness < 60: Focus on recovery or lighter intensity
3. If readiness 60-75: Moderate intensity, standard volume
4. If readiness > 75: Can push harder, include intensity work
5. For hybrid workouts: MINIMUM 3km running (compromised if less)
6. Adjust exercise selection based on confidence levels
7. Consider injuries: ${user.injuries?.length > 0 ? user.injuries.join(', ') : 'None'}
8. Return ONLY valid JSON, no markdown or extra text`);

  return sections.join('\n\n');
}
