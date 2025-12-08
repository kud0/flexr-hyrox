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
  workout_type?: 'full_simulation' | 'half_simulation' | 'station_focus' | 'running' | 'strength' | 'functional' | 'recovery'
  target_duration_minutes?: number
  focus_stations?: string[]
  strength_focus?: 'upper' | 'lower' | 'full_body'
}

interface WorkoutSegment {
  segment_type: 'run' | 'station' | 'transition' | 'rest' | 'warmup' | 'cooldown' | 'strength' | 'finisher'
  station_type?: string
  exercise_name?: string
  sets?: number
  reps_per_set?: number
  weight_suggestion?: string
  target_duration_seconds?: number
  target_distance_meters?: number
  target_reps?: number
  notes?: string
  order_index: number
}

interface WorkoutSection {
  type: 'warmup' | 'strength' | 'wod' | 'finisher' | 'cooldown'
  label: string
  format?: 'emom' | 'amrap' | 'for_time' | 'tabata' | 'rounds' | null
  format_details?: {
    total_minutes?: number
    rounds?: number
    movements_per_round?: number
    work_seconds?: number
    rest_seconds?: number
    time_cap_minutes?: number
  }
  segments: WorkoutSegment[]
}

interface GeneratedWorkout {
  name: string
  description: string
  estimated_duration_minutes: number
  difficulty: 'easy' | 'moderate' | 'hard' | 'very_hard'
  sections?: WorkoutSection[]  // New format: sections with nested segments
  segments?: WorkoutSegment[]  // Old format: flat segment list (HYROX, strength)
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
    const grokModel = Deno.env.get('GROK_MODEL') || 'grok-4-1-fast-non-reasoning'

    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Parse request
    const { user_id, readiness_score, workout_type, target_duration_minutes, focus_stations, strength_focus }: WorkoutRequest = await req.json()

    console.log(`Generating workout: type=${workout_type}, strength_focus=${strength_focus}, readiness=${readiness_score}, model=${grokModel}`)

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
      focus_stations,
      strength_focus
    })

    // Call Grok AI
    const grokResponse = await fetch('https://api.x.ai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${grokApiKey}`
      },
      body: JSON.stringify({
        model: grokModel,
        messages: [
          {
            role: 'system',
            content: getSystemPrompt(workout_type)
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

    // Handle both old format (flat segments) and new format (sections)
    // New format: workout.sections array with nested segments
    // Old format: workout.segments flat array
    let orderIndex = 0
    const allSegments: (WorkoutSegment & { section_type?: string, section_label?: string, section_format?: string, section_format_details?: any })[] = []
    let sectionsMetadata: any[] | null = null
    let sectionsForResponse: WorkoutSection[] | null = null

    if (workout.sections && Array.isArray(workout.sections)) {
      // New sections-based format (functional workouts)
      sectionsForResponse = workout.sections

      for (const section of workout.sections) {
        for (const seg of section.segments) {
          allSegments.push({
            ...seg,
            order_index: orderIndex++,
            section_type: section.type,
            section_label: section.label,
            section_format: section.format || undefined,
            section_format_details: section.format_details || undefined
          })
        }
      }

      // Build sections metadata for UI grouping
      sectionsMetadata = workout.sections.map((section: WorkoutSection) => ({
        type: section.type,
        label: section.label,
        format: section.format || null,
        format_details: section.format_details || null,
        segment_count: section.segments.length
      }))
    } else if (workout.segments && Array.isArray(workout.segments)) {
      // Old flat segments format (HYROX, strength, etc.)
      for (const seg of workout.segments) {
        allSegments.push({
          ...seg,
          order_index: orderIndex++
        })
      }
      // No sections metadata for old format
      sectionsMetadata = null
      sectionsForResponse = null
    } else {
      throw new Error('Invalid workout format: missing sections or segments')
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
        sections_metadata: sectionsMetadata,
        ai_context: {
          prompt_summary: `Readiness: ${readiness_score}, Type: ${workout_type}`,
          model: grokModel,
          generated_at: new Date().toISOString()
        }
      })
      .select()
      .single()

    if (saveError) throw saveError

    // Save segments - sanitize AI response to ensure correct types
    const segmentsToInsert = allSegments.map(seg => ({
      workout_id: savedWorkout.id,
      segment_type: seg.segment_type,
      station_type: seg.station_type || null,
      exercise_name: seg.exercise_name || null,
      sets: typeof seg.sets === 'number' ? seg.sets : null,
      reps_per_set: typeof seg.reps_per_set === 'number' ? seg.reps_per_set : null,
      weight_suggestion: typeof seg.weight_suggestion === 'string' ? seg.weight_suggestion : null,
      target_duration_seconds: typeof seg.target_duration_seconds === 'number' ? seg.target_duration_seconds : null,
      target_distance_meters: typeof seg.target_distance_meters === 'number' ? seg.target_distance_meters : null,
      target_reps: typeof seg.target_reps === 'number' ? seg.target_reps : null,
      notes: seg.notes || null,
      order_index: seg.order_index,
      section_type: seg.section_type,
      section_label: seg.section_label,
      section_format: seg.section_format || null,
      section_format_details: seg.section_format_details || null
    }))

    const { error: segmentError } = await supabase
      .from('workout_segments')
      .insert(segmentsToInsert)

    if (segmentError) throw segmentError

    // Return the complete workout (with sections if available)
    return new Response(
      JSON.stringify({
        success: true,
        workout: {
          ...savedWorkout,
          sections: sectionsForResponse
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
  strength_focus?: string
}): string {
  const { user, profile, architecture, recentWorkouts, readiness_score, workout_type, target_duration_minutes, focus_stations, strength_focus } = data

  // Adjust intro based on workout type
  let prompt: string
  if (workout_type === 'strength') {
    const focusLabel = strength_focus === 'upper' ? 'Upper Body' : strength_focus === 'lower' ? 'Lower Body' : 'Full Body'
    prompt = `Generate a GYM-BASED ${focusLabel} STRENGTH workout for this athlete:\n\n`
  } else if (workout_type === 'functional') {
    prompt = `Generate a 60-MINUTE FUNCTIONAL FITNESS CLASS (CrossFit-style) for this athlete:\n\n`
  } else {
    prompt = `Generate a HYROX workout for this athlete:\n\n`
  }

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
  if (strength_focus) {
    const focusLabel = strength_focus === 'upper' ? 'Upper Body' : strength_focus === 'lower' ? 'Lower Body' : 'Full Body'
    prompt += `- Strength focus: ${focusLabel}\n`
  }

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

function getSystemPrompt(workout_type?: string): string {
  // Base context about FLEXR
  const baseContext = `You are FLEXR AI, an expert fitness coach specializing in HYROX and hybrid fitness training. You create personalized workouts based on user data, performance history, and readiness scores.`

  // For strength workouts, use gym-based format
  if (workout_type === 'strength') {
    return `${baseContext}

Generate a COMPREHENSIVE GYM-BASED STRENGTH SESSION (~45-60 minutes).

This is a REAL lifting session - not a quick circuit. Structure it like a proper gym day:

WORKOUT STRUCTURE:
1. WARM-UP (8-10 min): Dynamic stretches, mobility work, light activation
2. MAIN COMPOUND LIFTS (25-30 min): 2-3 heavy barbell movements with proper rest
3. ACCESSORY WORK (15-20 min): 3-4 supporting exercises
4. COOL-DOWN (5 min): Static stretching

EXERCISE SELECTION (choose based on focus):
UPPER PUSH: Bench Press, Overhead Press, Incline DB Press, Dips, Push-ups
UPPER PULL: Barbell Rows, Pull-ups/Chin-ups, Lat Pulldown, Cable Rows, Face Pulls
LOWER: Back Squat, Front Squat, Deadlift, Romanian Deadlift, Bulgarian Split Squat, Leg Press, Hip Thrust
CORE: Planks, Hanging Leg Raises, Ab Wheel, Pallof Press, Dead Bugs, Cable Woodchops
ACCESSORY: Bicep Curls, Tricep Extensions, Lateral Raises, Rear Delt Flyes, Calf Raises

PROGRAMMING PRINCIPLES:
- Main lifts: 4-5 sets of 3-6 reps (strength focus) or 3-4 sets of 8-12 reps (hypertrophy)
- Accessories: 3 sets of 10-15 reps
- Rest 2-3 min between heavy compounds, 60-90 sec between accessories
- Include warm-up sets ramping to working weight

FORMAT RULES:
- Use segment_type: "strength" for exercises
- Include exercise_name, sets, reps_per_set
- Add weight_suggestion as percentage ("75% 1RM") or RPE ("RPE 7-8")
- Always include warmup and cooldown segments

ALWAYS respond with ONLY valid JSON (no markdown, no explanation) matching this structure:
{
  "name": "Upper Body Strength",
  "description": "A comprehensive upper body session",
  "estimated_duration_minutes": 55,
  "difficulty": "moderate",
  "segments": [
    {
      "segment_type": "warmup",
      "exercise_name": "Dynamic Warm-up",
      "target_duration_seconds": 480,
      "notes": "Arm circles, band pull-aparts, light cardio",
      "order_index": 0
    },
    {
      "segment_type": "strength",
      "exercise_name": "Barbell Back Squat",
      "sets": 4,
      "reps_per_set": 6,
      "weight_suggestion": "75% 1RM",
      "notes": "Full depth, 3 min rest between sets",
      "order_index": 1
    }
  ]
}

Generate 8-12 total segments including warmup and cooldown. Use segment_type "strength" for all exercises.`
  }

  // For functional workouts - CrossFit class style
  if (workout_type === 'functional') {
    return `${baseContext}

Generate a 60-MINUTE FUNCTIONAL FITNESS CLASS using a SECTIONS-based structure.

IMPORTANT EQUIPMENT RULES:
- STRENGTH section: Barbells ARE allowed (coached compound lifts)
- WOD/FINISHER section: NO BARBELLS (beginners can't safely use them under fatigue)
- NEVER USE: Sleds (sled push/sled pull) - most gyms don't have these

EQUIPMENT BY SECTION:
STRENGTH: Barbells, Dumbbells, Kettlebells
WOD/FINISHER: Dumbbells, Kettlebells, Rower, Assault Bike, Ski Erg, Wall balls, Box, Pull-up bar, Rings, Jump rope, Sandbags, Farmer carry (KBs/DBs), Bodyweight movements

RESPONSE FORMAT - Return SECTIONS, not flat segments:
{
  "name": "Squat Day + EMOM",
  "description": "Back squat strength followed by a conditioning EMOM",
  "estimated_duration_minutes": 60,
  "difficulty": "moderate",
  "sections": [
    {
      "type": "warmup",
      "label": "WARM-UP",
      "format": null,
      "segments": [
        {"segment_type": "warmup", "exercise_name": "Warm-up", "target_duration_seconds": 600, "notes": "400m row, then 3 rounds: 10 air squats, 10 leg swings each side, 10 push-ups. Finish with empty barbell: 5 good mornings, 5 squats"}
      ]
    },
    {
      "type": "strength",
      "label": "STRENGTH",
      "format": null,
      "segments": [
        {"segment_type": "strength", "exercise_name": "Back Squat", "sets": 4, "reps_per_set": 6, "weight_suggestion": "70-75% 1RM", "notes": "2-3 min rest between sets"},
        {"segment_type": "strength", "exercise_name": "Romanian Deadlift", "sets": 3, "reps_per_set": 10, "weight_suggestion": "Moderate DBs or barbell", "notes": "90 sec rest"}
      ]
    },
    {
      "type": "wod",
      "label": "WOD",
      "format": "emom",
      "format_details": {"total_minutes": 16, "rounds": 4, "movements_per_round": 4},
      "segments": [
        {"segment_type": "station", "exercise_name": "Cal Row", "target_duration_seconds": 60, "target_reps": 15, "notes": "15/12 cal"},
        {"segment_type": "station", "exercise_name": "Wall Balls", "target_duration_seconds": 60, "target_reps": 15, "notes": "9/6kg ball"},
        {"segment_type": "station", "exercise_name": "KB Swings", "target_duration_seconds": 60, "target_reps": 15, "notes": "24/16kg"},
        {"segment_type": "station", "exercise_name": "Burpees", "target_duration_seconds": 60, "target_reps": 8}
      ]
    },
    {
      "type": "finisher",
      "label": "FINISHER",
      "format": "tabata",
      "format_details": {"rounds": 8, "work_seconds": 20, "rest_seconds": 10},
      "segments": [
        {"segment_type": "finisher", "exercise_name": "Assault Bike", "target_duration_seconds": 20, "notes": "Max effort"}
      ]
    },
    {
      "type": "cooldown",
      "label": "COOL-DOWN",
      "format": null,
      "segments": [
        {"segment_type": "cooldown", "exercise_name": "Cool-down", "target_duration_seconds": 300, "notes": "2 min easy walk, then: 1 min pigeon pose each side, 1 min quad stretch each side, 30 sec child's pose"}
      ]
    }
  ]
}

WOD FORMAT OPTIONS:
- "emom": Every Minute On the Minute - format_details: {total_minutes, rounds, movements_per_round}
- "amrap": As Many Rounds As Possible - format_details: {time_cap_minutes}
- "for_time": Complete workout as fast as possible - format_details: {time_cap_minutes, rounds}
- "tabata": 20s work / 10s rest - format_details: {rounds, work_seconds, rest_seconds}
- "rounds": X rounds for quality - format_details: {rounds}

IMPORTANT RULES:
1. For EMOM/AMRAP: List each UNIQUE movement ONCE in segments (the format_details describe repetition)
2. For Tabata: List each UNIQUE exercise ONCE (format_details describe the 8 rounds structure)
3. WOD movements: NO BARBELLS - use DBs, KBs, machines, bodyweight
4. Warm-up/Cool-down: Include SPECIFIC instructions in notes field
5. Use realistic rep schemes for the format (EMOM movements should be completable in ~40-45 sec)

Return ONLY valid JSON with the sections structure shown above.`
  }

  // Default HYROX-focused prompt
  return `${baseContext}

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
}
