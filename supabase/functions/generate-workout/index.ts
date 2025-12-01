// FLEXR - AI Workout Generation Edge Function
// Uses Grok AI (x.ai) to generate personalized HYROX workouts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface WorkoutRequest {
  user_id: string
  readiness_score: number
  workout_type?: 'full_simulation' | 'half_simulation' | 'station_focus' | 'running' | 'strength' | 'recovery'
  target_duration_minutes?: number
  focus_stations?: string[]
}

interface WorkoutSegment {
  segment_type: 'run' | 'station' | 'transition' | 'rest' | 'warmup' | 'cooldown'
  station_type?: string
  target_duration_seconds?: number
  target_distance_meters?: number
  target_reps?: number
  notes?: string
  order_index: number
}

interface GeneratedWorkout {
  name: string
  description: string
  estimated_duration_minutes: number
  difficulty: 'easy' | 'moderate' | 'hard' | 'very_hard'
  segments: WorkoutSegment[]
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const grokApiKey = Deno.env.get('GROK_API_KEY')!

    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Parse request
    const { user_id, readiness_score, workout_type, target_duration_minutes, focus_stations }: WorkoutRequest = await req.json()

    // Fetch user data in parallel
    const [userResult, profileResult, architectureResult, recentWorkoutsResult] = await Promise.all([
      supabase.from('users').select('*').eq('id', user_id).single(),
      supabase.from('performance_profiles').select('*').eq('user_id', user_id).single(),
      supabase.from('training_architectures').select('*').eq('user_id', user_id).eq('is_active', true).single(),
      supabase.from('workouts').select('*').eq('user_id', user_id).order('created_at', { ascending: false }).limit(5)
    ])

    const user = userResult.data
    const profile = profileResult.data
    const architecture = architectureResult.data
    const recentWorkouts = recentWorkoutsResult.data || []

    // Build the AI prompt
    const prompt = buildWorkoutPrompt({
      user,
      profile,
      architecture,
      recentWorkouts,
      readiness_score,
      workout_type,
      target_duration_minutes,
      focus_stations
    })

    // Call Grok AI
    const grokResponse = await fetch('https://api.x.ai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${grokApiKey}`
      },
      body: JSON.stringify({
        model: 'grok-4-1-fast-non-reasoning',
        messages: [
          {
            role: 'system',
            content: `You are FLEXR AI, an expert HYROX training coach. You create personalized workouts based on user data, performance history, and readiness scores.

HYROX workout format:
- 8 stations: Ski Erg (1000m), Sled Push (50m), Sled Pull (50m), Burpee Broad Jump (80m), Rowing (1000m), Farmers Carry (200m), Sandbag Lunges (100m), Wall Balls (100 reps)
- 1km run between each station
- Total: 8km running + 8 stations

Key concepts:
- "Compromised running" = running pace degradation after intense station work
- Fresh run pace vs post-station pace varies by 15-45% depending on fitness
- Recovery profile affects transition times
- Readiness score (1-100) should modulate intensity

ALWAYS respond with valid JSON matching this schema:
{
  "name": "string",
  "description": "string",
  "estimated_duration_minutes": number,
  "difficulty": "easy" | "moderate" | "hard" | "very_hard",
  "segments": [
    {
      "segment_type": "run" | "station" | "transition" | "rest" | "warmup" | "cooldown",
      "station_type": "ski_erg" | "sled_push" | "sled_pull" | "burpee_broad_jump" | "rowing" | "farmers_carry" | "sandbag_lunges" | "wall_balls" | null,
      "target_duration_seconds": number | null,
      "target_distance_meters": number | null,
      "target_reps": number | null,
      "notes": "string" | null,
      "order_index": number
    }
  ]
}`
          },
          {
            role: 'user',
            content: prompt
          }
        ],
        temperature: 0.7,
        max_tokens: 2000
      })
    })

    if (!grokResponse.ok) {
      const error = await grokResponse.text()
      console.error('Grok API error:', error)
      throw new Error(`Grok API error: ${grokResponse.status}`)
    }

    const grokData = await grokResponse.json()
    const workoutJson = grokData.choices[0].message.content

    // Parse the JSON response (handle markdown code blocks)
    let workout: GeneratedWorkout
    try {
      const cleanJson = workoutJson.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim()
      workout = JSON.parse(cleanJson)
    } catch (e) {
      console.error('Failed to parse Grok response:', workoutJson)
      throw new Error('Failed to parse AI response')
    }

    // Save workout to database
    const { data: savedWorkout, error: saveError } = await supabase
      .from('workouts')
      .insert({
        user_id,
        name: workout.name,
        description: workout.description,
        workout_type: workout_type || 'ai_generated',
        status: 'planned',
        estimated_duration_minutes: workout.estimated_duration_minutes,
        difficulty: workout.difficulty,
        readiness_score,
        ai_context: {
          prompt_summary: `Readiness: ${readiness_score}, Type: ${workout_type}`,
          model: 'grok-4-1-fast-non-reasoning',
          generated_at: new Date().toISOString()
        }
      })
      .select()
      .single()

    if (saveError) throw saveError

    // Save segments
    const segmentsToInsert = workout.segments.map(seg => ({
      workout_id: savedWorkout.id,
      ...seg
    }))

    const { error: segmentError } = await supabase
      .from('workout_segments')
      .insert(segmentsToInsert)

    if (segmentError) throw segmentError

    // Return the complete workout
    return new Response(
      JSON.stringify({
        success: true,
        workout: {
          ...savedWorkout,
          segments: workout.segments
        }
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      }
    )

  } catch (error) {
    console.error('Error generating workout:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500
      }
    )
  }
})

function buildWorkoutPrompt(data: {
  user: any
  profile: any
  architecture: any
  recentWorkouts: any[]
  readiness_score: number
  workout_type?: string
  target_duration_minutes?: number
  focus_stations?: string[]
}): string {
  const { user, profile, architecture, recentWorkouts, readiness_score, workout_type, target_duration_minutes, focus_stations } = data

  let prompt = `Generate a HYROX workout for this athlete:\n\n`

  // User context
  prompt += `## ATHLETE PROFILE\n`
  prompt += `- Training goal: ${user?.training_goal || 'train_style'}\n`
  prompt += `- Experience level: ${user?.experience_level || 'intermediate'}\n`
  if (user?.race_date) {
    const daysUntilRace = Math.ceil((new Date(user.race_date).getTime() - Date.now()) / (1000 * 60 * 60 * 24))
    prompt += `- Race in ${daysUntilRace} days\n`
  }
  prompt += `\n`

  // Training architecture
  if (architecture) {
    prompt += `## TRAINING ARCHITECTURE\n`
    prompt += `- Days per week: ${architecture.days_per_week}\n`
    prompt += `- Sessions per day: ${architecture.sessions_per_day}\n`
    prompt += `- Session types: ${JSON.stringify(architecture.session_types)}\n`
    prompt += `\n`
  }

  // Performance profile (if available)
  if (profile) {
    prompt += `## PERFORMANCE DATA\n`
    prompt += `- Fresh run pace: ${profile.fresh_run_pace_per_km || 'unknown'} min/km\n`
    if (profile.compromised_run_paces) {
      prompt += `- Compromised run paces by station:\n`
      for (const [station, pace] of Object.entries(profile.compromised_run_paces)) {
        prompt += `  - After ${station}: ${pace} min/km\n`
      }
    }
    if (profile.station_benchmarks) {
      prompt += `- Station benchmarks:\n`
      for (const [station, benchmark] of Object.entries(profile.station_benchmarks as Record<string, any>)) {
        prompt += `  - ${station}: ${benchmark.avg_duration_seconds}s avg\n`
      }
    }
    prompt += `\n`
  }

  // Recent workouts
  if (recentWorkouts.length > 0) {
    prompt += `## RECENT TRAINING (last ${recentWorkouts.length} workouts)\n`
    recentWorkouts.forEach((w, i) => {
      prompt += `${i + 1}. ${w.name} - ${w.workout_type} (${w.status})\n`
    })
    prompt += `\n`
  }

  // Today's context
  prompt += `## TODAY'S CONTEXT\n`
  prompt += `- Readiness score: ${readiness_score}/100\n`
  if (workout_type) prompt += `- Requested type: ${workout_type}\n`
  if (target_duration_minutes) prompt += `- Target duration: ${target_duration_minutes} minutes\n`
  if (focus_stations?.length) prompt += `- Focus stations: ${focus_stations.join(', ')}\n`

  // Readiness-based guidance
  prompt += `\n## INTENSITY GUIDANCE\n`
  if (readiness_score >= 80) {
    prompt += `High readiness - athlete is fresh. Can push intensity.\n`
  } else if (readiness_score >= 60) {
    prompt += `Moderate readiness - balanced workout appropriate.\n`
  } else if (readiness_score >= 40) {
    prompt += `Lower readiness - reduce intensity, focus on technique.\n`
  } else {
    prompt += `Low readiness - recovery-focused session recommended.\n`
  }

  prompt += `\nGenerate an appropriate workout. Include warmup and cooldown.`

  return prompt
}
