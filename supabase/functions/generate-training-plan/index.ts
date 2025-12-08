// FLEXR - AI Training Plan Generation Edge Function (v2)
// Context-driven, personalized multi-week plan generation
// AI decides phase distribution based on full athlete context

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.0"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// ============================================================================
// TYPES
// ============================================================================

interface PlanRequest {
  user_id: string
  // Optional overrides (if not provided, fetch from database)
  goal?: string
  race_date?: string
  days_per_week?: number
  sessions_per_day?: number
  session_duration?: number
  program_start_date?: string
  preferred_recovery_day?: string  // e.g., "sunday", "saturday"
}

interface AthleteContext {
  // Identity
  userId: string
  age?: number
  gender?: string
  weightKg?: number
  heightCm?: number

  // Experience & Background
  trainingBackground?: string
  fitnessLevel?: string
  hasCompletedHyroxBefore: boolean
  numberOfHyroxRaces?: number
  bestHyroxTimeSeconds?: number
  bestHyroxDivision?: string
  justFinishedRace: boolean

  // Goals & Timeline
  primaryGoal?: string
  raceDate?: string
  targetTimeSeconds?: number
  totalWeeks: number

  // Training Setup
  daysPerWeek: number
  sessionsPerDay: number
  sessionDurationMinutes: number
  preferredTime?: string
  preferredWorkoutTypes?: string[]
  programStartDate?: string
  preferredRecoveryDay?: string  // Which day should be recovery (for 6-7 days/week)

  // Equipment
  equipmentLocation?: string
  equipment: string[]

  // Benchmarks
  running1kmSeconds?: number
  running5kmSeconds?: number
  zone2PaceSeconds?: number

  // Weaknesses & Focus Areas
  weakStations?: string[]
  injuries?: string[]
  motivationType?: string
}

interface WeekOverview {
  week_number: number
  phase: string
  phase_description: string
  focus: string
  intensity_guidance: string
  is_deload: boolean
  key_workouts: string[] // Brief descriptions like "Full simulation", "Long Zone 2 run"
}

interface PlanReasoning {
  starting_phase_rationale: string
  phase_distribution_reasoning: string
  key_focus_areas: string[]
  deload_rationale: string
  intensity_progression: string
  athlete_specific_notes: string
}

interface PlanSummary {
  total_weeks: number
  phases: Array<{
    name: string
    start_week: number
    end_week: number
    description: string
  }>
  deload_weeks: number[]
}

interface FullPlanResponse {
  plan_reasoning: PlanReasoning
  plan_summary: PlanSummary
  weeks: WeekOverview[]
}

interface WorkoutSegment {
  order_index: number
  segment_type: 'warmup' | 'run' | 'station' | 'strength' | 'cooldown' | 'rest' | 'transition'
  name: string
  instructions: string
  target_duration_seconds?: number
  target_distance_meters?: number
  target_reps?: number
  target_calories?: number
  sets?: number
  rest_between_sets_seconds?: number
  target_pace?: string
  target_heart_rate_zone?: number
  intensity_description?: string
  equipment?: string
  station_type?: string | null
}

interface PlannedWorkout {
  scheduled_date: string
  day_of_week: string
  session_number: number
  workout_type: string
  name: string
  watch_name: string
  description: string
  estimated_duration: number
  intensity: string
  ai_explanation: string
  segments: WorkoutSegment[]
}

interface DetailedWeekResponse {
  week_number: number
  workouts: PlannedWorkout[]
}

// ============================================================================
// HELPER: Validate that all required days have workouts
// ============================================================================

interface ValidationResult {
  isValid: boolean
  missingDays: string[]
  message: string
}

function validateWeekCoverage(
  weekWorkouts: PlannedWorkout[],
  daysPerWeek: number,
  sessionsPerDay: number,
  weekStartDate: string
): ValidationResult {
  const allDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
  const requiredDays = allDays.slice(0, Math.min(daysPerWeek, 7))

  // Check 1: Minimum workout count
  // For 7 days × 2 sessions:
  // - Mon-Fri: 5 days × 2 sessions = 10
  // - Saturday: 1 intense session
  // - Sunday: 1 recovery session
  // Total: 12 workouts
  const expectedMinWorkouts = daysPerWeek === 7
    ? (5 * sessionsPerDay) + 1 + 1  // 5 weekdays × sessions + 1 sat + 1 sun = 12 for 2 sessions
    : daysPerWeek * sessionsPerDay

  if (weekWorkouts.length < expectedMinWorkouts) {
    return {
      isValid: false,
      missingDays: [],
      message: `Not enough workouts: got ${weekWorkouts.length}, expected at least ${expectedMinWorkouts}`
    }
  }

  // Get all days that have workouts (by date, convert to day of week)
  const weekStart = new Date(weekStartDate + 'T00:00:00Z')
  const coveredDays = new Set<string>()

  for (const workout of weekWorkouts) {
    const workoutDate = new Date(workout.scheduled_date + 'T00:00:00Z')
    const dayIndex = workoutDate.getDay() // 0=Sunday
    const dayName = allDays[dayIndex === 0 ? 6 : dayIndex - 1] // Convert to Monday-based
    coveredDays.add(dayName)
  }

  // Also check by day_of_week field
  for (const workout of weekWorkouts) {
    if (workout.day_of_week) {
      coveredDays.add(workout.day_of_week.toLowerCase())
    }
  }

  const missingDays = requiredDays.filter(day => !coveredDays.has(day))

  if (missingDays.length > 0) {
    return {
      isValid: false,
      missingDays,
      message: `Week missing workouts for: ${missingDays.join(', ')}. Has workouts for: ${Array.from(coveredDays).join(', ')}`
    }
  }

  // Check 3: Verify critical days (Fri/Sat/Sun) are present
  if (daysPerWeek >= 6) {
    const criticalDays = ['friday', 'saturday', 'sunday']
    const missingCritical = criticalDays.filter(day => !coveredDays.has(day))
    if (missingCritical.length > 0) {
      return {
        isValid: false,
        missingDays: missingCritical,
        message: `CRITICAL DAYS MISSING: ${missingCritical.join(', ')}. Grok stopped early.`
      }
    }
  }

  return {
    isValid: true,
    missingDays: [],
    message: 'All required days have workouts'
  }
}

// ============================================================================
// HELPER: Calculate correct number of workouts per week
// ============================================================================

function getWorkoutsPerWeekRequirement(daysPerWeek: number, sessionsPerDay: number, preferredRecoveryDay?: string): string {
  const recoveryDay = (preferredRecoveryDay || 'sunday').toLowerCase()

  if (daysPerWeek === 7) {
    // 7 days - be EXTREMELY explicit with table format
    const totalWorkouts = (daysPerWeek - 1) * sessionsPerDay + 1 // Recovery day has 1 session

    return `## ⚠️ CRITICAL: EXACT 7-DAY SCHEDULE REQUIRED ⚠️

YOU MUST GENERATE EXACTLY THIS SCHEDULE - NO EXCEPTIONS:

| Day       | day_of_week | Workouts Required |
|-----------|-------------|-------------------|
| Monday    | "monday"    | ${sessionsPerDay === 2 ? '2 workouts (session_number: 1 and 2)' : '1 workout'} |
| Tuesday   | "tuesday"   | ${sessionsPerDay === 2 ? '2 workouts (session_number: 1 and 2)' : '1 workout'} |
| Wednesday | "wednesday" | ${sessionsPerDay === 2 ? '2 workouts (session_number: 1 and 2)' : '1 workout'} |
| Thursday  | "thursday"  | ${sessionsPerDay === 2 ? '2 workouts (session_number: 1 and 2)' : '1 workout'} |
| Friday    | "friday"    | ${sessionsPerDay === 2 ? '2 workouts (session_number: 1 and 2)' : '1 workout'} |
| Saturday  | "saturday"  | ${sessionsPerDay === 2 ? '2 workouts (session_number: 1 and 2)' : '1 workout'} |
| Sunday    | "sunday"    | 1 workout (recovery day) |

RULES:
1. Your JSON response MUST contain workouts for ALL 7 days
2. FRIDAY must have workouts with day_of_week: "friday"
3. SATURDAY must have workouts with day_of_week: "saturday"
4. SUNDAY must have workouts with day_of_week: "sunday"
5. Total workout objects in your response: ${totalWorkouts}

DO NOT STOP AT THURSDAY. CONTINUE TO FRIDAY, SATURDAY, SUNDAY.`

  } else if (daysPerWeek === 6) {
    return `## SCHEDULE REQUIREMENT
Generate workouts for 6 days: Monday through Saturday.
Recovery day: ${recoveryDay} (no workout)
Each training day: ${sessionsPerDay} session(s)
INCLUDE FRIDAY AND SATURDAY!`

  } else {
    return `- Create EXACTLY ${daysPerWeek * sessionsPerDay} workouts per week`
  }
}

function getIntenseDay(recoveryDay: string): string {
  const dayOrder = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
  const recoveryIndex = dayOrder.indexOf(recoveryDay.toLowerCase())
  const intenseIndex = recoveryIndex === 0 ? 6 : recoveryIndex - 1
  return dayOrder[intenseIndex]
}

// ============================================================================
// HELPER: Get recovery day rules based on user preference
// ============================================================================

function getRecoveryDayRules(preferredRecoveryDay?: string, daysPerWeek?: number): string {
  // Only apply recovery day logic for 6-7 days/week
  if (!daysPerWeek || daysPerWeek < 6) {
    return ''
  }

  const recoveryDay = preferredRecoveryDay?.toLowerCase() || 'sunday'

  // Determine intense day (day before recovery)
  const dayOrder = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
  const recoveryIndex = dayOrder.indexOf(recoveryDay)
  const intenseIndex = recoveryIndex === 0 ? 6 : recoveryIndex - 1
  const intenseDay = dayOrder[intenseIndex]

  const capitalized = (s: string) => s.charAt(0).toUpperCase() + s.slice(1)

  return `- ${capitalized(intenseDay)} = HARD WORKOUT DAY (simulation, long run, or tough station work) - ONLY 1 workout this day (not 2)
- ${capitalized(recoveryDay)} = EASY/RECOVERY DAY (Zone 2 run or light mobility) - ONLY 1 workout this day (not 2)
- IMPORTANT: BOTH days MUST have a workout - they are NOT rest days! They just have 1 session instead of 2.`
}

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const grokApiKey = Deno.env.get('GROK_API_KEY')!
    const grokModel = Deno.env.get('GROK_MODEL') || 'grok-4-1-fast-non-reasoning'

    const supabase = createClient(supabaseUrl, supabaseServiceKey)
    console.log(`Using Grok model: ${grokModel}`)

    const request: PlanRequest = await req.json()
    console.log(`Generating plan for user: ${request.user_id}`)

    // Step 1: Fetch full athlete context from database
    const athleteContext = await fetchAthleteContext(supabase, request)
    console.log(`Athlete context loaded: ${athleteContext.totalWeeks} weeks, background: ${athleteContext.trainingBackground}`)

    // Step 2: Generate full plan structure (reasoning + all weeks overview)
    const fullPlan = await generatePlanStructure(grokApiKey, grokModel, athleteContext)
    console.log(`Plan structure generated: ${fullPlan.weeks.length} weeks, ${fullPlan.plan_summary.phases.length} phases`)

    // Step 3: Generate detailed workouts for first 2 weeks only (to avoid token limit/JSON truncation)
    // Additional weeks can be generated on-demand later
    const weeksToGenerate = Math.min(2, athleteContext.totalWeeks)
    const detailedWeeks = await generateDetailedWeeks(
      grokApiKey,
      grokModel,
      athleteContext,
      fullPlan,
      1,
      weeksToGenerate
    )
    console.log(`Generated detailed workouts for weeks 1-${weeksToGenerate}`)

    // Step 4: Save everything to database
    await savePlanToDatabase(supabase, request.user_id, athleteContext, fullPlan, detailedWeeks)
    console.log('Plan saved to database')

    return new Response(
      JSON.stringify({
        success: true,
        plan_reasoning: fullPlan.plan_reasoning,
        plan_summary: fullPlan.plan_summary,
        weeks_overview: fullPlan.weeks,
        detailed_weeks_generated: weeksToGenerate
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      }
    )

  } catch (error) {
    console.error('Error generating plan:', error)
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

// ============================================================================
// FETCH ATHLETE CONTEXT
// ============================================================================

async function fetchAthleteContext(
  supabase: SupabaseClient,
  request: PlanRequest
): Promise<AthleteContext> {

  // Fetch user data
  const { data: user, error: userError } = await supabase
    .from('users')
    .select('*')
    .eq('id', request.user_id)
    .single()

  if (userError || !user) {
    throw new Error(`Failed to fetch user: ${userError?.message || 'User not found'}`)
  }

  // Fetch benchmarks (optional)
  const { data: benchmarks } = await supabase
    .from('user_performance_benchmarks')
    .select('*')
    .eq('user_id', request.user_id)
    .order('updated_at', { ascending: false })
    .limit(1)
    .single()

  // Fetch equipment (optional)
  const { data: equipment } = await supabase
    .from('user_equipment_access')
    .select('*')
    .eq('user_id', request.user_id)
    .single()

  // Fetch weaknesses (optional)
  const { data: weaknesses } = await supabase
    .from('user_weaknesses')
    .select('*')
    .eq('user_id', request.user_id)
    .single()

  // Calculate total weeks
  let totalWeeks = 12 // default
  const raceDate = request.race_date || user.race_date
  if (raceDate) {
    const raceDateObj = new Date(raceDate)
    const today = new Date()
    const weeksUntil = Math.ceil((raceDateObj.getTime() - today.getTime()) / (7 * 24 * 60 * 60 * 1000))
    totalWeeks = Math.max(4, Math.min(24, weeksUntil)) // Clamp between 4 and 24 weeks
  }

  // Build equipment list
  const equipmentList: string[] = []
  if (equipment) {
    if (equipment.has_skierg) equipmentList.push('ski_erg')
    if (equipment.has_sled) equipmentList.push('sled')
    if (equipment.has_rower) equipmentList.push('rower')
    if (equipment.has_wall_ball) equipmentList.push('wall_balls')
    if (equipment.has_sandbag) equipmentList.push('sandbag')
    if (equipment.has_farmers_handles) equipmentList.push('farmers_handles')
    if (equipment.has_barbell) equipmentList.push('barbell')
    if (equipment.has_squat_rack) equipmentList.push('squat_rack')
    if (equipment.has_pullup_bar) equipmentList.push('pullup_bar')
    if (equipment.has_kettlebells) equipmentList.push('kettlebells')
    if (equipment.has_dumbbells) equipmentList.push('dumbbells')
    if (equipment.has_assault_bike) equipmentList.push('assault_bike')
  }

  return {
    userId: request.user_id,
    age: user.age,
    gender: user.gender,
    weightKg: user.weight_kg,
    heightCm: user.height_cm,

    trainingBackground: user.training_background,
    fitnessLevel: user.fitness_level,
    hasCompletedHyroxBefore: user.has_completed_hyrox_before || false,
    numberOfHyroxRaces: user.number_of_hyrox_races,
    bestHyroxTimeSeconds: user.best_hyrox_time_seconds,
    bestHyroxDivision: user.best_hyrox_division,
    justFinishedRace: user.just_finished_race || false,

    primaryGoal: request.goal || user.primary_goal,
    raceDate: raceDate,
    targetTimeSeconds: user.target_time_seconds,
    totalWeeks: totalWeeks,

    daysPerWeek: request.days_per_week || user.days_per_week || 4,
    sessionsPerDay: request.sessions_per_day || user.sessions_per_day || 1,
    sessionDurationMinutes: request.session_duration || user.preferred_workout_duration_minutes || 60,
    preferredTime: user.preferred_time,
    preferredWorkoutTypes: user.preferred_workout_types,
    programStartDate: request.program_start_date || user.program_start_date,
    preferredRecoveryDay: request.preferred_recovery_day || user.preferred_recovery_day || 'sunday',

    equipmentLocation: equipment?.location_type || user.equipment_location,
    equipment: equipmentList.length > 0 ? equipmentList : ['full_gym'],

    running1kmSeconds: benchmarks?.running_1km_seconds,
    running5kmSeconds: benchmarks?.running_5km_seconds,
    zone2PaceSeconds: benchmarks?.running_zone2_pace_seconds,

    weakStations: weaknesses?.weak_stations,
    injuries: weaknesses?.injuries,
    motivationType: weaknesses?.motivation_type
  }
}

// ============================================================================
// GENERATE PLAN STRUCTURE (AI Call 1)
// ============================================================================

async function generatePlanStructure(
  apiKey: string,
  model: string,
  context: AthleteContext
): Promise<FullPlanResponse> {

  const systemPrompt = getPlanStructureSystemPrompt(context)
  const userPrompt = buildPlanStructurePrompt(context)

  const response = await fetch('https://api.x.ai/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`
    },
    body: JSON.stringify({
      model: model,
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt }
      ],
      temperature: 0.7,
      max_tokens: 8000
    })
  })

  if (!response.ok) {
    const error = await response.text()
    throw new Error(`Grok API error: ${response.status} - ${error}`)
  }

  const data = await response.json()
  const content = data.choices[0].message.content

  return parseJsonResponse<FullPlanResponse>(content)
}

// ============================================================================
// GENERATE DETAILED WEEKS (AI Call 2+)
// ============================================================================

async function generateDetailedWeeks(
  apiKey: string,
  model: string,
  context: AthleteContext,
  planStructure: FullPlanResponse,
  startWeek: number,
  endWeek: number
): Promise<DetailedWeekResponse[]> {

  const systemPrompt = getDetailedWorkoutsSystemPrompt(context)
  const weekDates = calculateWeekDates(context.totalWeeks, context.programStartDate)

  // Retry logic for BOTH JSON parsing AND missing days validation
  const maxRetries = 3
  let lastError: Error | null = null
  let missingDaysFeedback = ''

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      // Build user prompt, including feedback about missing days on retry
      let userPrompt = buildDetailedWorkoutsPrompt(context, planStructure, startWeek, endWeek)
      if (missingDaysFeedback) {
        userPrompt = `${missingDaysFeedback}\n\n${userPrompt}`
      }

      console.log(`Generating detailed weeks (attempt ${attempt}/${maxRetries})...`)

      const response = await fetch('https://api.x.ai/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`
        },
        body: JSON.stringify({
          model: model,
          messages: [
            { role: 'system', content: systemPrompt + '\n\nCRITICAL: Output ONLY valid JSON. Double-check all commas between array elements. Every } or ] that is followed by another { or [ needs a comma between them.' },
            { role: 'user', content: userPrompt }
          ],
          temperature: attempt === 1 ? 0.7 : (attempt === 2 ? 0.5 : 0.3), // Lower temperature on retry
          max_tokens: 24000
        })
      })

      if (!response.ok) {
        const error = await response.text()
        throw new Error(`Grok API error: ${response.status} - ${error}`)
      }

      const data = await response.json()
      const content = data.choices[0].message.content

      if (data.choices[0].finish_reason === 'length') {
        console.warn('WARNING: Response truncated due to token limit')
      }

      const parsed = parseJsonResponse<{ weeks: DetailedWeekResponse[] }>(content)

      // VALIDATION: Check that each week has all required days AND minimum count
      if (context.daysPerWeek >= 6) {
        const allMissingDays: string[] = []
        // Mon-Fri: 5 days × sessions, Sat: 1 intense, Sun: 1 recovery
        const expectedMin = context.daysPerWeek === 7
          ? (5 * context.sessionsPerDay) + 1 + 1  // 12 for 2 sessions/day
          : context.daysPerWeek * context.sessionsPerDay

        for (const week of parsed.weeks) {
          const weekIndex = week.week_number - 1
          const weekStartDate = weekDates[weekIndex]?.start
          if (!weekStartDate) continue

          const validation = validateWeekCoverage(week.workouts, context.daysPerWeek, context.sessionsPerDay, weekStartDate)
          if (!validation.isValid) {
            console.warn(`Week ${week.week_number} validation failed: ${validation.message}`)
            allMissingDays.push(`Week ${week.week_number}: ${validation.message}`)
          }
        }

        if (allMissingDays.length > 0) {
          // Set feedback for retry
          missingDaysFeedback = `⚠️ PREVIOUS ATTEMPT FAILED VALIDATION ⚠️

${allMissingDays.join('\n')}

REQUIREMENTS:
- Training days per week: ${context.daysPerWeek}
- Sessions per day: ${context.sessionsPerDay}
- Expected minimum workouts per week: ${expectedMin}

YOU MUST include workouts for ALL 7 days of each week:
- Monday through Friday: ${context.sessionsPerDay} workouts each (session_number: 1 and 2)
- Saturday: 1 intense workout (session_number: 1 only)
- Sunday: 1 recovery workout (session_number: 1 only)

FRIDAY, SATURDAY, and SUNDAY ARE REQUIRED.
Do NOT stop at Thursday. Continue generating through Sunday.
Saturday and Sunday should each have EXACTLY 1 workout, not ${context.sessionsPerDay}.

THIS IS ATTEMPT ${attempt + 1}/${maxRetries}. If you fail again, the request will fail.
`
          throw new Error(`Validation failed: ${allMissingDays.join('; ')}`)
        }
      }

      console.log(`✅ All weeks validated successfully`)
      return parsed.weeks

    } catch (e) {
      lastError = e
      console.error(`Attempt ${attempt} failed: ${e.message}`)
      if (attempt < maxRetries) {
        console.log('Retrying with enhanced prompt and lower temperature...')
        await new Promise(r => setTimeout(r, 1000)) // Wait 1 second before retry
      }
    }
  }

  throw lastError || new Error('Failed to generate detailed weeks after retries')
}

// ============================================================================
// SYSTEM PROMPTS
// ============================================================================

function getPlanStructureSystemPrompt(context: AthleteContext): string {
  // Build dynamic weekly pattern based on recovery day preference
  let weeklyPattern = ''
  if (context.daysPerWeek >= 6) {
    const recoveryDay = context.preferredRecoveryDay?.toLowerCase() || 'sunday'
    const dayOrder = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
    const recoveryIndex = dayOrder.indexOf(recoveryDay)
    const intenseIndex = recoveryIndex === 0 ? 6 : recoveryIndex - 1
    const intenseDay = dayOrder[intenseIndex]
    const capitalize = (s: string) => s.charAt(0).toUpperCase() + s.slice(1)

    weeklyPattern = `
ELITE WEEKLY PATTERN (for 2 sessions/day):
- Most weekdays: 2 sessions (AM: running/cardio, PM: strength/stations)
- ${capitalize(intenseDay)}: INTENSE session (simulations, long volume) - SINGLE session only
- ${capitalize(recoveryDay)}: RECOVERY (Zone 2 run or complete rest) - SINGLE session only`
  } else {
    weeklyPattern = `
WEEKLY PATTERN:
- Spread training days evenly through the week
- Include at least 1 recovery/easy day per week`
  }

  return `You are FLEXR AI, an expert HYROX and hybrid fitness coach. You create PERSONALIZED training plans based on each athlete's unique context.

YOUR ROLE:
You analyze the athlete's background, experience, goals, and timeline to create an optimal periodized training plan. You DO NOT use generic templates - every decision is based on THIS athlete's specific situation.

HYROX RACE FORMAT (for context):
8 stations with 1km run between each (8km total running):
1. Ski Erg - 1000m
2. Sled Push - 50m (152kg men / 102kg women)
3. Sled Pull - 50m (103kg men / 78kg women)
4. Burpee Broad Jump - 80m
5. Rowing - 1000m
6. Farmers Carry - 200m (2x24kg men / 2x16kg women)
7. Sandbag Lunges - 100m (20kg men / 10kg women)
8. Wall Balls - 100 reps (9kg men / 6kg women)

TRAINING PHASES:
- recovery: Post-race or injury recovery (if needed)
- base: Building aerobic foundation and movement patterns
- build: Increasing intensity, HYROX-specific work
- peak: Race-specific maximum intensity, simulations
- taper: Reduced volume, maintained intensity before race
${weeklyPattern}

DELOAD WEEKS:
- Place strategically based on training load accumulation
- Typically every 3-5 weeks depending on intensity
- 40% volume reduction, maintained movement quality

YOUR OUTPUT:
Provide plan_reasoning explaining YOUR decisions for THIS athlete, then the full week-by-week structure.

RESPOND ONLY WITH VALID JSON. NO markdown, NO explanation outside JSON.`
}

function getDetailedWorkoutsSystemPrompt(context: AthleteContext): string {
  // Build dynamic recovery day rules
  let recoveryRules = ''
  if (context.daysPerWeek >= 6) {
    const recoveryDay = context.preferredRecoveryDay?.toLowerCase() || 'sunday'
    const dayOrder = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
    const recoveryIndex = dayOrder.indexOf(recoveryDay)
    const intenseIndex = recoveryIndex === 0 ? 6 : recoveryIndex - 1
    const intenseDay = dayOrder[intenseIndex]
    const capitalize = (s: string) => s.charAt(0).toUpperCase() + s.slice(1)

    recoveryRules = `
2. ${capitalize(intenseDay)} = INTENSE (simulation or long session) - SINGLE session only
3. ${capitalize(recoveryDay)} = RECOVERY (Zone 2 or rest) - SINGLE session only`
  } else {
    recoveryRules = `
2. Include at least 1 recovery day per week`
  }

  return `You are FLEXR AI generating detailed workout segments for a HYROX training plan.

SEGMENT TYPES:
- "warmup": Dynamic warm-up before main workout
- "run": Running segment (include target_distance_meters, target_pace)
- "station": HYROX station work (include station_type)
- "strength": Gym-based strength exercise (include equipment)
- "cooldown": Cool-down stretching/mobility
- "rest": Rest period between sets
- "transition": Movement between exercises

STATION TYPES (exact values):
ski_erg, sled_push, sled_pull, burpee_broad_jump, rowing, farmers_carry, sandbag_lunges, wall_balls

WORKOUT TYPES:
- full_simulation: All 8 stations + 8km running
- half_simulation: 4 stations + 4km running
- station_focus: 2-3 stations with runs between
- running: Pure running (intervals, tempo, Zone 2)
- strength: Gym-based strength work
- recovery: Light movement, Zone 2, mobility

INTENSITY LEVELS:
recovery, easy, moderate, hard, very_hard

CRITICAL RULES:
1. Each RUN and STATION must be SEPARATE segments (never combined!)${recoveryRules}
4. watch_name: max 12 characters, ALL CAPS
5. Every segment needs order_index, segment_type, name, instructions, and at least one target

RESPOND ONLY WITH VALID JSON. NO markdown, NO explanation outside JSON.`
}

// ============================================================================
// PROMPT BUILDERS
// ============================================================================

function buildPlanStructurePrompt(context: AthleteContext): string {
  const weekDates = calculateWeekDates(context.totalWeeks, context.programStartDate)

  return `Generate a PERSONALIZED ${context.totalWeeks}-week training plan structure.

## ATHLETE CONTEXT (Analyze this to make decisions)

IDENTITY:
- Age: ${context.age || 'Unknown'}
- Gender: ${context.gender || 'Unknown'}
- Weight: ${context.weightKg ? `${context.weightKg}kg` : 'Unknown'}
- Height: ${context.heightCm ? `${context.heightCm}cm` : 'Unknown'}

EXPERIENCE & BACKGROUND:
- Training background: ${context.trainingBackground || 'Unknown'}
- Fitness level: ${context.fitnessLevel || 'intermediate'}
- Previous HYROX races: ${context.hasCompletedHyroxBefore ? context.numberOfHyroxRaces || 'Yes, count unknown' : 'None'}
${context.bestHyroxTimeSeconds ? `- Best HYROX time: ${formatTime(context.bestHyroxTimeSeconds)}` : '- Best HYROX time: N/A'}
${context.bestHyroxDivision ? `- Division: ${context.bestHyroxDivision}` : ''}
- Just finished a race: ${context.justFinishedRace ? 'YES - consider recovery needs' : 'NO'}

CURRENT FITNESS (benchmarks):
${context.running1kmSeconds ? `- 1km time: ${formatTime(context.running1kmSeconds)}` : '- 1km time: Not tested'}
${context.running5kmSeconds ? `- 5km time: ${formatTime(context.running5kmSeconds)}` : '- 5km time: Not tested'}
${context.zone2PaceSeconds ? `- Zone 2 pace: ${formatPace(context.zone2PaceSeconds)}/km` : '- Zone 2 pace: Unknown'}

GOALS & TIMELINE:
- Primary goal: ${context.primaryGoal || 'General HYROX preparation'}
- Race date: ${context.raceDate || 'No specific race'}
${context.targetTimeSeconds ? `- Target time: ${formatTime(context.targetTimeSeconds)}` : ''}
- Total weeks available: ${context.totalWeeks}

TRAINING SETUP:
- Days per week: ${context.daysPerWeek}
- Sessions per day: ${context.sessionsPerDay}
- Session duration: ${context.sessionDurationMinutes} minutes
- Preferred time: ${context.preferredTime || 'Flexible'}
${context.preferredWorkoutTypes ? `- Preferred workout types: ${context.preferredWorkoutTypes.join(', ')}` : ''}

EQUIPMENT:
- Location: ${context.equipmentLocation || 'Full gym'}
- Available: ${context.equipment.join(', ')}

${context.weakStations ? `WEAK STATIONS: ${context.weakStations.join(', ')}` : ''}
${context.injuries ? `INJURIES/LIMITATIONS: ${context.injuries.join(', ')}` : ''}
${context.motivationType ? `MOTIVATION TYPE: ${context.motivationType}` : ''}

## YOUR TASK

Based on ALL the context above, decide:

1. **Starting Phase**: What phase should this athlete begin at?
   - Don't assume everyone starts at base
   - A veteran with 8 weeks doesn't need base
   - A beginner with 20 weeks needs more foundation

2. **Phase Distribution**: How many weeks for each phase?
   - Adapt to THEIR timeline and experience
   - Not a formula - a personalized decision

3. **Key Focus Areas**: What does THIS athlete need most?
   - Write these like a coach would SAY them to an athlete
   - Short, punchy, human phrases (2-5 words each)
   - Examples: "Build running endurance", "Master sled technique", "Improve wall ball stamina"
   - DO NOT include numbers, zones, paces, weights, or bodyweight
   - DO NOT sound robotic or technical

4. **Deload Placement**: Where should recovery weeks go?

5. **Weekly Structure**: For each week, what's the focus and intensity?

6. **Coach Notes**: Write like you're talking to the athlete
   - Be conversational, not robotic
   - Give practical advice they can use
   - Skip numbers and metrics - focus on mindset and approach

## WEEK DATES
${weekDates.map((d, i) => `Week ${i + 1}: ${d.start} to ${d.end}`).join('\n')}

## KEY FOCUS AREAS EXAMPLES (choose style like these):
GOOD: "Build running base", "Master sled technique", "Wall ball endurance", "Improve SkiErg pacing"
BAD: "Running aerobic capacity (target Zone 2 to 5:00/km)", "Strength at 87kg bodyweight"

## COACH NOTES - CRITICAL INSTRUCTIONS:
Write notes a REAL COACH would give about the TRAINING ITSELF. NOT generic life advice.

GOOD coach notes (training-specific, actionable):
- "Keep your runs conversational this phase - if you can't talk, you're going too fast. We're building your aerobic engine."
- "Sled work is about technique now, not speed. Low hips, short powerful steps, eyes forward."
- "Don't chase times yet. Consistent effort across all 8 stations matters more than crushing one."
- "Wall balls: focus on catching in the squat, not at the top. It's a rhythm exercise."
- "SkiErg pulls should feel sustainable. If your arms burn out in 2 minutes, you're pulling too hard."

BAD coach notes (generic, useless, repeating user preferences):
- "Morning sessions work great for your schedule" (NO - user already knows their schedule)
- "Stay consistent with sleep and recovery" (NO - generic life advice)
- "Listen to your body" (NO - meaningless filler)
- "At 87kg, focus on sled technique" (NO - don't mention bodyweight)

The athlete PAID for this - give them REAL coaching insights about movements, pacing, technique, and phase-specific strategy.

## JSON STRUCTURE
{
  "plan_reasoning": {
    "starting_phase_rationale": "Why I'm starting this athlete at [phase] because...",
    "phase_distribution_reasoning": "Given their [specific context], I've allocated...",
    "key_focus_areas": ["Build running base", "Master sled technique", "Improve rowing stamina"],
    "deload_rationale": "Deloads at weeks X, Y because...",
    "intensity_progression": "Starting easy and building gradually...",
    "athlete_specific_notes": "Write like talking to a friend - practical, warm, no metrics"
  },
  "plan_summary": {
    "total_weeks": ${context.totalWeeks},
    "phases": [
      {"name": "phase_name", "start_week": 1, "end_week": 4, "description": "What this achieves"}
    ],
    "deload_weeks": [4, 8]
  },
  "weeks": [
    {
      "week_number": 1,
      "phase": "base|build|peak|taper|recovery",
      "phase_description": "What this phase achieves for THIS athlete",
      "focus": "Specific focus for this week",
      "intensity_guidance": "How hard to push this week",
      "is_deload": false,
      "key_workouts": ["Brief workout description 1", "Brief workout description 2"]
    }
  ]
}`
}

function buildDetailedWorkoutsPrompt(
  context: AthleteContext,
  planStructure: FullPlanResponse,
  startWeek: number,
  endWeek: number
): string {
  const weeksToGenerate = planStructure.weeks.slice(startWeek - 1, endWeek)
  const weekDates = calculateWeekDates(context.totalWeeks, context.programStartDate)

  // Calculate actual first training day
  const actualStartDate = context.programStartDate ? new Date(context.programStartDate) : new Date()
  const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
  const actualStartDayName = dayNames[actualStartDate.getDay()]
  const actualStartDateStr = actualStartDate.toISOString().split('T')[0]

  return `Generate DETAILED workouts for weeks ${startWeek}-${endWeek}.

## ATHLETE CONTEXT
- Training background: ${context.trainingBackground || 'Unknown'}
- Fitness level: ${context.fitnessLevel || 'intermediate'}
- Days per week: ${context.daysPerWeek}
- Sessions per day: ${context.sessionsPerDay}
- Session duration: ${context.sessionDurationMinutes} minutes
- Equipment: ${context.equipment.join(', ')}
${context.weakStations ? `- Focus on weak stations: ${context.weakStations.join(', ')}` : ''}
${context.injuries ? `- Avoid/modify for: ${context.injuries.join(', ')}` : ''}

## CRITICAL: PROGRAM START DATE
- User's FIRST training day is: ${actualStartDayName}, ${actualStartDateStr}
- The FIRST workout in the entire plan MUST be on ${actualStartDateStr}
- For Week 1: DO NOT generate workouts for any day BEFORE ${actualStartDayName}
- If program starts on ${actualStartDayName}, the earliest scheduled_date in your response must be "${actualStartDateStr}"
- Any workouts before this date will be REJECTED

## PLAN CONTEXT
Key focus areas: ${planStructure.plan_reasoning.key_focus_areas.join(', ')}
Intensity progression: ${planStructure.plan_reasoning.intensity_progression}

## WEEKS TO GENERATE
${weeksToGenerate.map(w => `
Week ${w.week_number} (${weekDates[w.week_number - 1].start} to ${weekDates[w.week_number - 1].end}):
- Phase: ${w.phase}
- Focus: ${w.focus}
- Intensity: ${w.intensity_guidance}
- Is deload: ${w.is_deload}
- Key workouts: ${w.key_workouts.join(', ')}
`).join('\n')}

## REQUIREMENTS
${getWorkoutsPerWeekRequirement(context.daysPerWeek, context.sessionsPerDay, context.preferredRecoveryDay)}
${getRecoveryDayRules(context.preferredRecoveryDay, context.daysPerWeek)}
${context.sessionsPerDay > 1 ? `
- For 2-session days: session_number=1 for AM, session_number=2 for PM
- AM sessions: running or cardio-focused
- PM sessions: strength or station-focused
- IMPORTANT: Intense day and Recovery day get ONLY 1 session (not 2)` : ''}
- Every workout MUST have segments array
- Runs and stations must be SEPARATE segments
- watch_name: max 12 characters, ALL CAPS

## JSON STRUCTURE
{
  "weeks": [
    {
      "week_number": ${startWeek},
      "workouts": [
        {
          "scheduled_date": "${weekDates[startWeek - 1].start}",
          "day_of_week": "Monday",
          "session_number": 1,
          "workout_type": "running|station_focus|strength|recovery|full_simulation|half_simulation",
          "name": "Workout Name",
          "watch_name": "SHORT NAME",
          "description": "What this workout achieves",
          "estimated_duration": 60,
          "intensity": "easy|moderate|hard|very_hard|recovery",
          "ai_explanation": "Why this workout for this athlete",
          "segments": [
            {
              "order_index": 1,
              "segment_type": "warmup|run|station|strength|cooldown|rest",
              "name": "Segment Name",
              "instructions": "Detailed instructions",
              "target_duration_seconds": 300,
              "target_distance_meters": 1000,
              "target_reps": null,
              "target_pace": "5:30",
              "target_heart_rate_zone": 2,
              "station_type": null,
              "equipment": null
            }
          ]
        }
      ]
    }
  ]
}`
}

// ============================================================================
// DATABASE OPERATIONS
// ============================================================================

async function savePlanToDatabase(
  supabase: SupabaseClient,
  userId: string,
  context: AthleteContext,
  planStructure: FullPlanResponse,
  detailedWeeks: DetailedWeekResponse[]
): Promise<void> {

  // 1. Delete existing plan data for this user
  // First get existing workout IDs to delete their segments
  const { data: existingWorkouts } = await supabase
    .from('planned_workouts')
    .select('id')
    .eq('user_id', userId)

  if (existingWorkouts && existingWorkouts.length > 0) {
    const workoutIds = existingWorkouts.map(w => w.id)
    await supabase.from('planned_workout_segments').delete().in('planned_workout_id', workoutIds)
  }

  await supabase.from('planned_workouts').delete().eq('user_id', userId)
  await supabase.from('training_weeks').delete().eq('user_id', userId)
  await supabase.from('training_plans').delete().eq('user_id', userId)

  // 2. Create training plan
  const planStart = getWeekStart(new Date())
  const { error: planError } = await supabase
    .from('training_plans')
    .insert({
      user_id: userId,
      start_date: planStart.toISOString(),
      total_weeks: context.totalWeeks,
      current_week: 1,
      goal: context.primaryGoal || 'HYROX preparation',
      race_date: context.raceDate,
      plan_reasoning: planStructure.plan_reasoning,
      athlete_context: context,
      generation_model: 'grok-4-1',
      generation_timestamp: new Date().toISOString()
    })

  if (planError) {
    console.error('Plan save error:', planError)
    throw new Error(`Failed to save plan: ${planError.message}`)
  }

  // 3. Save all week overviews
  const weekDates = calculateWeekDates(context.totalWeeks, context.programStartDate)
  for (const week of planStructure.weeks) {
    const { error: weekError } = await supabase
      .from('training_weeks')
      .insert({
        user_id: userId,
        week_number: week.week_number,
        total_weeks: context.totalWeeks,
        phase: week.phase,
        focus: week.focus,
        phase_description: week.phase_description,
        intensity_guidance: week.intensity_guidance,
        is_deload: week.is_deload,
        start_date: new Date(weekDates[week.week_number - 1].start).toISOString()
      })

    if (weekError) {
      console.error(`Week ${week.week_number} save error:`, weekError)
    }
  }

  // 4. Save detailed workouts
  // Calculate the actual start date to filter out workouts before user's start date
  const programStartDate = context.programStartDate ? new Date(context.programStartDate) : new Date()
  programStartDate.setHours(0, 0, 0, 0)

  // Use weekDates already calculated above for week number calculation
  function getCorrectWeekNumber(workoutDate: Date): number {
    for (let i = 0; i < weekDates.length; i++) {
      const weekStart = new Date(weekDates[i].start + 'T00:00:00Z')
      const weekEnd = new Date(weekDates[i].end + 'T23:59:59Z')
      if (workoutDate >= weekStart && workoutDate <= weekEnd) {
        return i + 1 // Week numbers are 1-indexed
      }
    }
    return 1 // Default to week 1 if not found
  }

  for (const week of detailedWeeks) {
    for (const workout of week.workouts) {
      const workoutDate = new Date(workout.scheduled_date + 'T00:00:00Z')

      // Skip workouts scheduled before the user's program start date
      if (workoutDate < programStartDate) {
        console.log(`Skipping workout ${workout.name} on ${workout.scheduled_date} - before start date ${context.programStartDate}`)
        continue
      }

      const scheduledDate = workoutDate.toISOString()

      // Calculate correct week number based on date, not what Grok said
      const correctWeekNumber = getCorrectWeekNumber(workoutDate)

      // Ensure watch_name is max 12 characters
      const truncatedWatchName = (workout.watch_name || workout.name || 'WORKOUT').substring(0, 12).toUpperCase()

      const { data: savedWorkout, error: workoutError } = await supabase
        .from('planned_workouts')
        .insert({
          user_id: userId,
          scheduled_date: scheduledDate,
          day_of_week: workout.day_of_week,
          week_number: correctWeekNumber,
          session_number: workout.session_number,
          workout_type: workout.workout_type,
          name: workout.name,
          watch_name: truncatedWatchName,
          description: workout.description,
          estimated_duration: workout.estimated_duration,
          intensity: workout.intensity,
          ai_explanation: workout.ai_explanation,
          status: 'planned'
        })
        .select()
        .single()

      if (workoutError) {
        console.error(`Workout save error (${workout.name}):`, workoutError)
        continue
      }

      // Save segments
      if (workout.segments && workout.segments.length > 0) {
        const segmentsToInsert = workout.segments.map(seg => ({
          planned_workout_id: savedWorkout.id,
          order_index: seg.order_index,
          segment_type: normalizeSegmentType(seg.segment_type),
          name: seg.name || `Segment ${seg.order_index}`, // Ensure name is never null
          instructions: seg.instructions || '',
          target_duration_seconds: seg.target_duration_seconds,
          target_distance_meters: seg.target_distance_meters,
          target_reps: seg.target_reps,
          target_calories: seg.target_calories,
          sets: seg.sets,
          rest_between_sets_seconds: seg.rest_between_sets_seconds,
          target_pace: seg.target_pace,
          target_heart_rate_zone: seg.target_heart_rate_zone,
          intensity_description: seg.intensity_description,
          equipment: seg.equipment,
          station_type: seg.station_type
        }))

        const { error: segmentsError } = await supabase
          .from('planned_workout_segments')
          .insert(segmentsToInsert)

        if (segmentsError) {
          console.error(`Segments save error:`, segmentsError)
        }
      }
    }
  }
}

// ============================================================================
// HELPERS
// ============================================================================

function getWeekStart(date: Date): Date {
  const d = new Date(date)
  const day = d.getDay()
  const diff = d.getDate() - day + (day === 0 ? -6 : 1) // Monday start
  d.setDate(diff)
  d.setHours(0, 0, 0, 0)
  return d
}

function calculateWeekDates(totalWeeks: number, programStartDate?: string): Array<{ start: string, end: string }> {
  const dates: Array<{ start: string, end: string }> = []

  // Use programStartDate if provided, otherwise use current week's Monday
  let weekStart: Date
  if (programStartDate) {
    // Start from the Monday of the week containing programStartDate
    weekStart = getWeekStart(new Date(programStartDate))
  } else {
    weekStart = getWeekStart(new Date())
  }

  for (let i = 0; i < totalWeeks; i++) {
    const start = new Date(weekStart.getTime() + i * 7 * 24 * 60 * 60 * 1000)
    const end = new Date(start.getTime() + 6 * 24 * 60 * 60 * 1000)
    dates.push({
      start: start.toISOString().split('T')[0],
      end: end.toISOString().split('T')[0]
    })
  }

  return dates
}

function formatTime(seconds: number): string {
  const hours = Math.floor(seconds / 3600)
  const mins = Math.floor((seconds % 3600) / 60)
  const secs = Math.floor(seconds % 60)

  if (hours > 0) {
    return `${hours}:${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
  }
  return `${mins}:${secs.toString().padStart(2, '0')}`
}

function formatPace(secondsPerKm: number): string {
  const mins = Math.floor(secondsPerKm / 60)
  const secs = Math.floor(secondsPerKm % 60)
  return `${mins}:${secs.toString().padStart(2, '0')}`
}

// Normalize segment types to match database check constraint
// Valid types: 'warmup', 'run', 'station', 'cooldown', 'rest', 'transition'
function normalizeSegmentType(type: string): string {
  const normalized = type?.toLowerCase() || 'station'

  // Map common AI-generated types to valid database types
  const typeMap: Record<string, string> = {
    'warmup': 'warmup',
    'warm-up': 'warmup',
    'warm_up': 'warmup',
    'run': 'run',
    'running': 'run',
    'station': 'station',
    'cooldown': 'cooldown',
    'cool-down': 'cooldown',
    'cool_down': 'cooldown',
    'rest': 'rest',
    'transition': 'transition',
    // Map non-standard types to closest match
    'strength': 'station',  // Strength exercises are treated as stations
    'exercise': 'station',
    'circuit': 'station',
    'intervals': 'run',
    'interval': 'run',
    'jog': 'run',
    'sprint': 'run',
    'recovery': 'rest',
    'mobility': 'cooldown',
    'stretch': 'cooldown',
    'stretching': 'cooldown'
  }

  return typeMap[normalized] || 'station' // Default to 'station' for unknown types
}

function parseJsonResponse<T>(content: string): T {
  // Clean up the JSON - remove markdown code blocks if present
  let cleanJson = content
    .replace(/```json\n?/g, '')
    .replace(/```\n?/g, '')
    .trim()

  // Find JSON object
  const jsonStart = cleanJson.indexOf('{')
  const jsonEnd = cleanJson.lastIndexOf('}')
  if (jsonStart !== -1 && jsonEnd !== -1) {
    cleanJson = cleanJson.substring(jsonStart, jsonEnd + 1)
  }

  // Try parsing directly first
  try {
    return JSON.parse(cleanJson)
  } catch (firstError) {
    console.warn('Initial JSON parse failed, attempting repairs...')

    // Apply common LLM JSON fixes
    let repairedJson = cleanJson

    // Fix 1: Remove trailing commas before ] or }
    repairedJson = repairedJson.replace(/,\s*([\]\}])/g, '$1')

    // Fix 2: Add missing commas between array elements (common issue)
    // Look for pattern: "}" or "]" or number or "string" followed by newline/space then "{" or "[" or number or '"'
    repairedJson = repairedJson.replace(/(\}|\]|"|\d)\s*\n\s*(\{|\[|"|\d)/g, '$1,\n$2')

    // Fix 3: Remove any control characters that might have snuck in
    repairedJson = repairedJson.replace(/[\x00-\x1F\x7F]/g, (char) => {
      if (char === '\n' || char === '\r' || char === '\t') return char
      return ''
    })

    // Fix 4: Escape unescaped quotes inside strings (tricky - be conservative)
    // This handles common case where LLM outputs: "description": "Use "moderate" weight"
    // We look for patterns like ": "...unescaped"quote..." and try to fix
    // This is a simplified approach - full fix would need proper parsing

    try {
      return JSON.parse(repairedJson)
    } catch (secondError) {
      console.error('JSON Parse Error after repairs:', secondError.message)
      console.error('Original content length:', content.length)
      console.error('First 1000 chars:', cleanJson.substring(0, 1000))
      console.error('Last 500 chars:', cleanJson.substring(cleanJson.length - 500))

      // Try to find the error location
      const match = secondError.message.match(/position (\d+)/)
      if (match) {
        const pos = parseInt(match[1])
        console.error(`Error context around position ${pos}:`, cleanJson.substring(Math.max(0, pos - 100), pos + 100))
      }

      throw new Error(`Failed to parse AI response: ${secondError.message}`)
    }
  }
}
// Updated: Thu Dec  5 19:50:00 CET 2025 - Reduced to 2 weeks to avoid JSON truncation
