// FLEXR - Generate Next Week Edge Function
// Called on Sunday evening to generate detailed workouts for the upcoming week
// Uses the existing plan structure and generates detailed workouts for the next week

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.0"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// ============================================================================
// TYPES
// ============================================================================

interface GenerateNextWeekRequest {
  user_id: string
  week_number?: number  // Optional: specific week to generate. If not provided, generates next needed week
  action?: 'generate' | 'check_feedback_signal' | 'regenerate_if_needed'  // Action to perform
}

interface WeekOverview {
  week_number: number
  phase: string
  phase_description: string
  focus: string
  intensity_guidance: string
  is_deload: boolean
}

interface WorkoutSegment {
  segment_type: string
  station_type?: string
  name: string
  instructions: string
  target_duration_seconds?: number
  target_distance_meters?: number
  target_reps?: number
  target_pace?: string
  target_heart_rate_zone?: number
  intensity_description?: string
  sets?: number
  rest_between_sets_seconds?: number
}

interface DailyWorkout {
  day_of_week: string // "monday", "tuesday", etc.
  session_number: number
  workout_type: string
  name: string
  description: string
  estimated_duration: number
  intensity: string
  ai_explanation: string
  segments: WorkoutSegment[]
}

interface DetailedWeekResponse {
  week_number: number
  workouts: DailyWorkout[]
}

interface AthleteContext {
  userId: string
  daysPerWeek: number
  sessionsPerDay: number
  sessionDurationMinutes: number
  equipment: string[]
  preferredRecoveryDay?: string
  fitnessLevel?: string
  weakStations?: string[]
}

interface TrainingPlanContext {
  totalWeeks: number
  goal: string
  raceDate?: string
  targetTime?: string
  planReasoning?: {
    keyFocusAreas: string[]
    intensityProgression: string
    athleteSpecificNotes: string
  }
  allPhases: {
    phase: string
    startWeek: number
    endWeek: number
    description: string
  }[]
  deloadWeeks: number[]
}

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const request: GenerateNextWeekRequest = await req.json()
    const action = request.action || 'generate'
    console.log(`Action: ${action} for user: ${request.user_id}`)

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const grokApiKey = Deno.env.get('GROK_API_KEY')!
    const grokModel = Deno.env.get('GROK_MODEL') || 'grok-3-mini-beta'

    const supabase = createClient(supabaseUrl, supabaseKey)

    // Action: Check feedback signal only (no generation)
    if (action === 'check_feedback_signal') {
      return await handleCheckFeedbackSignal(supabase, request.user_id)
    }

    // Action: Regenerate next week if strong feedback signal detected
    if (action === 'regenerate_if_needed') {
      return await handleRegenerateIfNeeded(supabase, request.user_id, grokApiKey, grokModel)
    }

    // Default action: Generate next week
    // Step 1: Find the next week that needs detailed workouts
    const weekToGenerate = await findNextWeekToGenerate(supabase, request.user_id, request.week_number)

    if (!weekToGenerate) {
      return new Response(
        JSON.stringify({
          success: true,
          message: 'All weeks already have detailed workouts',
          week_generated: null
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )
    }

    console.log(`Will generate week ${weekToGenerate.week_number}`)

    // Step 2: Get athlete context
    const athleteContext = await getAthleteContext(supabase, request.user_id)

    // Step 3: Get the FULL training plan context (phases, total weeks, goal, etc.)
    const planContext = await getTrainingPlanContext(supabase, request.user_id)

    // Step 4: Get the week overview from training_weeks
    const weekOverview = await getWeekOverview(supabase, request.user_id, weekToGenerate.week_number)

    // Step 5: Get previous week's performance feedback (if available)
    const previousWeekFeedback = await getPreviousWeekFeedback(supabase, request.user_id, weekToGenerate.week_number - 1)

    // Step 6: Generate detailed workouts for this week
    const detailedWeek = await generateDetailedWeek(
      grokApiKey,
      grokModel,
      athleteContext,
      planContext,
      weekOverview,
      previousWeekFeedback,
      weekToGenerate.start_date
    )

    // Step 6: Save workouts to database
    const saveResult = await saveWeekWorkouts(supabase, request.user_id, weekToGenerate, detailedWeek)
    console.log(`Week ${weekToGenerate.week_number} workouts saved: ${saveResult.inserted} inserted, ${saveResult.failed} failed`)

    return new Response(
      JSON.stringify({
        success: true,
        week_generated: weekToGenerate.week_number,
        workouts_created: saveResult.inserted,
        workouts_failed: saveResult.failed,
        workouts_expected: detailedWeek.workouts.length
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    console.error('Error generating next week:', error)
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})

// ============================================================================
// ACTION HANDLERS
// ============================================================================

async function handleCheckFeedbackSignal(
  supabase: SupabaseClient,
  userId: string
): Promise<Response> {
  // Find current week
  const currentWeek = await getCurrentWeekNumber(supabase, userId)
  if (!currentWeek) {
    return new Response(
      JSON.stringify({ success: false, error: 'No active training plan found' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 404 }
    )
  }

  // Get feedback aggregation for current week
  const aggregation = await aggregateWeekFeedback(supabase, userId, currentWeek)

  // Check if next week already exists
  const nextWeekHasWorkouts = await weekHasWorkouts(supabase, userId, currentWeek + 1)

  return new Response(
    JSON.stringify({
      success: true,
      current_week: currentWeek,
      feedback: aggregation ? {
        signal: aggregation.signal,
        avg_rpe: aggregation.avgRpe,
        avg_mood: aggregation.avgMood,
        common_tags: aggregation.commonTags,
        workouts_with_feedback: aggregation.workoutsWithFeedback,
        completion_rate: aggregation.completionRate
      } : null,
      next_week_exists: nextWeekHasWorkouts,
      should_regenerate: aggregation ? shouldRegenerateNextWeek(aggregation.signal) : false
    }),
    { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
  )
}

async function handleRegenerateIfNeeded(
  supabase: SupabaseClient,
  userId: string,
  grokApiKey: string,
  grokModel: string
): Promise<Response> {
  // Find current week
  const currentWeek = await getCurrentWeekNumber(supabase, userId)
  if (!currentWeek) {
    return new Response(
      JSON.stringify({ success: false, error: 'No active training plan found' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 404 }
    )
  }

  // Get feedback aggregation for current week
  const aggregation = await aggregateWeekFeedback(supabase, userId, currentWeek)

  if (!aggregation || !shouldRegenerateNextWeek(aggregation.signal)) {
    return new Response(
      JSON.stringify({
        success: true,
        regenerated: false,
        reason: aggregation ? `Signal is "${aggregation.signal}" - not strong enough to trigger regeneration` : 'No feedback data'
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )
  }

  // Check if next week exists - if so, delete it to regenerate
  const nextWeek = currentWeek + 1
  const nextWeekHasWorkouts = await weekHasWorkouts(supabase, userId, nextWeek)

  if (nextWeekHasWorkouts) {
    // Delete existing workouts for next week
    const { data: weekData } = await supabase
      .from('training_weeks')
      .select('start_date')
      .eq('user_id', userId)
      .eq('week_number', nextWeek)
      .single()

    if (weekData) {
      const weekEnd = new Date(new Date(weekData.start_date).getTime() + 7 * 24 * 60 * 60 * 1000)

      // Delete segments first (via cascade) then workouts
      const { data: workoutsToDelete } = await supabase
        .from('planned_workouts')
        .select('id')
        .eq('user_id', userId)
        .gte('scheduled_date', weekData.start_date)
        .lt('scheduled_date', weekEnd.toISOString())

      if (workoutsToDelete?.length) {
        const workoutIds = workoutsToDelete.map(w => w.id)

        // Delete segments
        await supabase
          .from('planned_workout_segments')
          .delete()
          .in('planned_workout_id', workoutIds)

        // Delete workouts
        await supabase
          .from('planned_workouts')
          .delete()
          .in('id', workoutIds)

        console.log(`Deleted ${workoutsToDelete.length} workouts from week ${nextWeek} for regeneration`)
      }
    }
  }

  // Now regenerate with feedback context
  const weekToGenerate = await findNextWeekToGenerate(supabase, userId, nextWeek)
  if (!weekToGenerate) {
    return new Response(
      JSON.stringify({ success: false, error: 'Could not find week to regenerate' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }

  // Generate with feedback context
  const athleteContext = await getAthleteContext(supabase, userId)
  const planContext = await getTrainingPlanContext(supabase, userId)
  const weekOverview = await getWeekOverview(supabase, userId, nextWeek)

  // Use current week's feedback (this is the strong signal that triggered regeneration)
  const detailedWeek = await generateDetailedWeek(
    grokApiKey,
    grokModel,
    athleteContext,
    planContext,
    weekOverview,
    aggregation.summary,  // Pass the strong feedback signal
    weekToGenerate.start_date
  )

  const saveResult = await saveWeekWorkouts(supabase, userId, weekToGenerate, detailedWeek)

  return new Response(
    JSON.stringify({
      success: true,
      regenerated: true,
      signal: aggregation.signal,
      week_regenerated: nextWeek,
      workouts_created: saveResult.inserted,
      workouts_failed: saveResult.failed
    }),
    { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
  )
}

function shouldRegenerateNextWeek(signal: FeedbackAggregation['signal']): boolean {
  // Only regenerate for strong signals that require adjustment
  return signal === 'too_easy' || signal === 'too_hard' || signal === 'needs_adjustment'
}

async function getCurrentWeekNumber(supabase: SupabaseClient, userId: string): Promise<number | null> {
  const today = new Date()
  today.setHours(0, 0, 0, 0)

  const { data: week } = await supabase
    .from('training_weeks')
    .select('week_number')
    .eq('user_id', userId)
    .lte('start_date', today.toISOString())
    .order('start_date', { ascending: false })
    .limit(1)
    .single()

  return week?.week_number || null
}

async function weekHasWorkouts(supabase: SupabaseClient, userId: string, weekNumber: number): Promise<boolean> {
  const { data: week } = await supabase
    .from('training_weeks')
    .select('start_date')
    .eq('user_id', userId)
    .eq('week_number', weekNumber)
    .single()

  if (!week) return false

  const weekEnd = new Date(new Date(week.start_date).getTime() + 7 * 24 * 60 * 60 * 1000)

  const { count } = await supabase
    .from('planned_workouts')
    .select('id', { count: 'exact', head: true })
    .eq('user_id', userId)
    .gte('scheduled_date', week.start_date)
    .lt('scheduled_date', weekEnd.toISOString())

  return (count || 0) > 0
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

async function findNextWeekToGenerate(
  supabase: SupabaseClient,
  userId: string,
  specificWeek?: number
): Promise<{ week_number: number; start_date: string; week_id: string } | null> {

  // Get all training weeks
  const { data: weeks, error } = await supabase
    .from('training_weeks')
    .select('id, week_number, start_date')
    .eq('user_id', userId)
    .order('week_number', { ascending: true })

  if (error || !weeks?.length) {
    console.error('Failed to fetch training weeks:', error)
    return null
  }

  // For each week, check if it has workouts
  for (const week of weeks) {
    // If specific week requested, skip others
    if (specificWeek && week.week_number !== specificWeek) continue

    const { count } = await supabase
      .from('planned_workouts')
      .select('id', { count: 'exact', head: true })
      .eq('user_id', userId)
      .gte('scheduled_date', week.start_date)
      .lt('scheduled_date', new Date(new Date(week.start_date).getTime() + 7 * 24 * 60 * 60 * 1000).toISOString())

    if (count === 0) {
      return {
        week_number: week.week_number,
        start_date: week.start_date,
        week_id: week.id
      }
    }
  }

  return null
}

async function getAthleteContext(supabase: SupabaseClient, userId: string): Promise<AthleteContext> {
  // First try to get athlete context from training_plans (most accurate)
  const { data: plan } = await supabase
    .from('training_plans')
    .select('athlete_context')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .limit(1)
    .single()

  // Fallback to users table
  const { data: user } = await supabase
    .from('users')
    .select('*')
    .eq('id', userId)
    .single()

  // Prefer values from athlete_context (stored during plan generation) over users table
  const athleteCtx = plan?.athlete_context || {}

  return {
    userId,
    daysPerWeek: athleteCtx.daysPerWeek || user?.training_days_per_week || 4,
    sessionsPerDay: athleteCtx.sessionsPerDay || user?.sessions_per_day || 1,
    sessionDurationMinutes: athleteCtx.sessionDurationMinutes || user?.session_duration || 60,
    equipment: athleteCtx.equipment || user?.equipment_available || [],
    preferredRecoveryDay: athleteCtx.preferredRecoveryDay || user?.preferred_recovery_day,
    fitnessLevel: athleteCtx.fitnessLevel || user?.fitness_level || 'intermediate',
    weakStations: athleteCtx.weakStations || user?.weak_stations || []
  }
}

async function getTrainingPlanContext(supabase: SupabaseClient, userId: string): Promise<TrainingPlanContext> {
  // Get the training plan with reasoning
  const { data: plan } = await supabase
    .from('training_plans')
    .select('*')
    .eq('user_id', userId)
    .order('start_date', { ascending: false })
    .limit(1)
    .single()

  // Get all training weeks to build phases overview
  const { data: weeks } = await supabase
    .from('training_weeks')
    .select('week_number, phase, phase_description, is_deload')
    .eq('user_id', userId)
    .order('week_number', { ascending: true })

  // Build phases array by grouping consecutive weeks with same phase
  const allPhases: TrainingPlanContext['allPhases'] = []
  let currentPhase: { phase: string; startWeek: number; endWeek: number; description: string } | null = null

  for (const week of (weeks || [])) {
    if (!currentPhase || currentPhase.phase !== week.phase) {
      if (currentPhase) {
        allPhases.push(currentPhase)
      }
      currentPhase = {
        phase: week.phase,
        startWeek: week.week_number,
        endWeek: week.week_number,
        description: week.phase_description || ''
      }
    } else {
      currentPhase.endWeek = week.week_number
    }
  }
  if (currentPhase) {
    allPhases.push(currentPhase)
  }

  // Find deload weeks
  const deloadWeeks = (weeks || [])
    .filter(w => w.is_deload)
    .map(w => w.week_number)

  // Parse plan reasoning if available
  let planReasoning: TrainingPlanContext['planReasoning'] = undefined
  if (plan?.plan_reasoning) {
    const reasoning = typeof plan.plan_reasoning === 'string'
      ? JSON.parse(plan.plan_reasoning)
      : plan.plan_reasoning
    planReasoning = {
      keyFocusAreas: reasoning.key_focus_areas || [],
      intensityProgression: reasoning.intensity_progression || '',
      athleteSpecificNotes: reasoning.athlete_specific_notes || ''
    }
  }

  return {
    totalWeeks: plan?.total_weeks || weeks?.length || 12,
    goal: plan?.goal || 'complete_race',
    raceDate: plan?.race_date,
    targetTime: plan?.target_time,
    planReasoning,
    allPhases,
    deloadWeeks
  }
}

async function getWeekOverview(
  supabase: SupabaseClient,
  userId: string,
  weekNumber: number
): Promise<WeekOverview> {
  const { data: week } = await supabase
    .from('training_weeks')
    .select('*')
    .eq('user_id', userId)
    .eq('week_number', weekNumber)
    .single()

  return {
    week_number: weekNumber,
    phase: week?.phase || 'build',
    phase_description: week?.phase_description || '',
    focus: week?.focus || 'General fitness',
    intensity_guidance: week?.intensity_guidance || 'Moderate effort',
    is_deload: week?.is_deload || false
  }
}

interface FeedbackAggregation {
  summary: string
  signal: 'too_easy' | 'just_right' | 'too_hard' | 'needs_adjustment' | 'neutral'
  avgRpe: number | null
  avgMood: number | null
  commonTags: string[]
  userNotes: string[]
  completionRate: number
  workoutsWithFeedback: number
}

async function getPreviousWeekFeedback(
  supabase: SupabaseClient,
  userId: string,
  previousWeekNumber: number
): Promise<string | null> {
  const aggregation = await aggregateWeekFeedback(supabase, userId, previousWeekNumber)
  if (!aggregation) return null
  return aggregation.summary
}

async function aggregateWeekFeedback(
  supabase: SupabaseClient,
  userId: string,
  weekNumber: number
): Promise<FeedbackAggregation | null> {
  if (weekNumber < 1) return null

  // Get week date range
  const { data: week } = await supabase
    .from('training_weeks')
    .select('start_date')
    .eq('user_id', userId)
    .eq('week_number', weekNumber)
    .single()

  if (!week) return null

  const weekStart = new Date(week.start_date)
  const weekEnd = new Date(weekStart.getTime() + 7 * 24 * 60 * 60 * 1000)

  // Get workout completion status
  const { data: workouts } = await supabase
    .from('planned_workouts')
    .select('id, status, workout_type')
    .eq('user_id', userId)
    .gte('scheduled_date', week.start_date)
    .lt('scheduled_date', weekEnd.toISOString())

  if (!workouts?.length) return null

  const completed = workouts.filter(w => w.status === 'completed').length
  const total = workouts.length
  const completionRate = Math.round((completed / total) * 100)

  // Get workout feedback (using actual column names: rpe_score, mood_score, tags, free_text)
  const { data: feedback } = await supabase
    .from('workout_feedback')
    .select('rpe_score, mood_score, tags, free_text')
    .eq('user_id', userId)
    .gte('created_at', week.start_date)
    .lt('created_at', weekEnd.toISOString())

  // Calculate averages
  const rpeScores = (feedback || []).filter(f => f.rpe_score).map(f => f.rpe_score as number)
  const moodScores = (feedback || []).filter(f => f.mood_score).map(f => f.mood_score as number)
  const avgRpe = rpeScores.length > 0 ? rpeScores.reduce((a, b) => a + b, 0) / rpeScores.length : null
  const avgMood = moodScores.length > 0 ? moodScores.reduce((a, b) => a + b, 0) / moodScores.length : null

  // Aggregate tags
  const allTags: string[] = (feedback || []).flatMap(f => f.tags || [])
  const tagCounts: Record<string, number> = {}
  for (const tag of allTags) {
    tagCounts[tag] = (tagCounts[tag] || 0) + 1
  }
  const commonTags = Object.entries(tagCounts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([tag]) => tag)

  // Collect user notes
  const userNotes = (feedback || [])
    .map(f => f.free_text)
    .filter((note): note is string => !!note && note.trim().length > 0)

  // Determine signal based on tags and RPE
  let signal: FeedbackAggregation['signal'] = 'neutral'

  // Count difficulty-related tags
  const tooEasyCount = tagCounts['too_easy'] || 0
  const tooHardCount = tagCounts['too_hard'] || 0
  const justRightCount = tagCounts['just_right'] || 0

  // Strong signal thresholds: 3+ occurrences or majority of feedback
  const feedbackCount = feedback?.length || 0
  const majorityThreshold = Math.ceil(feedbackCount / 2)

  if (tooEasyCount >= 3 || (tooEasyCount >= majorityThreshold && tooEasyCount > tooHardCount)) {
    signal = 'too_easy'
  } else if (tooHardCount >= 3 || (tooHardCount >= majorityThreshold && tooHardCount > tooEasyCount)) {
    signal = 'too_hard'
  } else if (justRightCount >= majorityThreshold) {
    signal = 'just_right'
  } else if (avgRpe !== null) {
    // RPE-based signal
    if (avgRpe <= 4) signal = 'too_easy'
    else if (avgRpe >= 8) signal = 'too_hard'
    else signal = 'just_right'
  }

  // Check for concerning patterns
  const injuryConcern = tagCounts['injury_concern'] || 0
  const minorPain = tagCounts['minor_pain'] || 0
  const exhausted = tagCounts['exhausted'] || 0
  if (injuryConcern > 0 || minorPain >= 2 || exhausted >= 3) {
    signal = 'needs_adjustment'
  }

  // Build summary for Grok
  let summary = `Previous week (Week ${weekNumber}): ${completed}/${total} workouts completed (${completionRate}%)`

  if (avgRpe !== null) {
    summary += `\n- Average RPE: ${avgRpe.toFixed(1)}/10 (${rpeDescription(avgRpe)})`
  }
  if (avgMood !== null) {
    summary += `\n- Average mood post-workout: ${avgMood.toFixed(1)}/5`
  }
  if (commonTags.length > 0) {
    summary += `\n- Most common feedback tags: ${commonTags.join(', ')}`
  }
  if (userNotes.length > 0) {
    summary += `\n- User notes: "${userNotes.slice(0, 2).join('", "')}"`
  }

  // Add signal interpretation
  summary += `\n\n⚡ FEEDBACK SIGNAL: ${signal.toUpperCase()}`
  switch (signal) {
    case 'too_easy':
      summary += '\n→ Athlete found workouts too easy. INCREASE intensity/volume this week.'
      break
    case 'too_hard':
      summary += '\n→ Athlete found workouts too hard. REDUCE intensity/volume this week or add more recovery.'
      break
    case 'needs_adjustment':
      summary += '\n→ Athlete reported pain/injury concerns. PRIORITIZE recovery and reduce impact exercises.'
      break
    case 'just_right':
      summary += '\n→ Current difficulty level is appropriate. Continue progressive overload as planned.'
      break
  }

  return {
    summary,
    signal,
    avgRpe,
    avgMood,
    commonTags,
    userNotes,
    completionRate,
    workoutsWithFeedback: feedback?.length || 0
  }
}

function rpeDescription(rpe: number): string {
  if (rpe <= 2) return 'very easy'
  if (rpe <= 4) return 'easy'
  if (rpe <= 6) return 'moderate'
  if (rpe <= 8) return 'hard'
  return 'very hard'
}

// Validate that all required days have workouts
function validateWeekCoverage(
  workouts: DailyWorkout[],
  daysPerWeek: number,
  sessionsPerDay: number
): { isValid: boolean; missingDays: string[]; message: string } {
  const allDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
  const weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday']
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

  if (workouts.length < expectedMinWorkouts) {
    return {
      isValid: false,
      missingDays: [],
      message: `Not enough workouts: got ${workouts.length}, expected at least ${expectedMinWorkouts}`
    }
  }

  // Check 2: Count sessions per day
  const sessionsPerDayMap: Record<string, number> = {}
  for (const workout of workouts) {
    if (workout.day_of_week) {
      const day = workout.day_of_week.toLowerCase()
      sessionsPerDayMap[day] = (sessionsPerDayMap[day] || 0) + 1
    }
  }

  // Check 3: Verify each day has correct number of sessions
  if (daysPerWeek === 7 && sessionsPerDay === 2) {
    const issues: string[] = []

    // Mon-Fri must have 2 sessions each
    for (const day of weekdays) {
      const count = sessionsPerDayMap[day] || 0
      if (count !== 2) {
        issues.push(`${day}: has ${count} sessions, needs 2`)
      }
    }

    // Saturday must have exactly 1 session
    const satCount = sessionsPerDayMap['saturday'] || 0
    if (satCount !== 1) {
      issues.push(`saturday: has ${satCount} sessions, needs 1`)
    }

    // Sunday must have exactly 1 session
    const sunCount = sessionsPerDayMap['sunday'] || 0
    if (sunCount !== 1) {
      issues.push(`sunday: has ${sunCount} sessions, needs 1`)
    }

    if (issues.length > 0) {
      return {
        isValid: false,
        missingDays: [],
        message: `Wrong session counts: ${issues.join('; ')}`
      }
    }
  } else {
    // Generic check for other configurations
    const coveredDays = new Set<string>(Object.keys(sessionsPerDayMap))
    const missingDays = requiredDays.filter(day => !coveredDays.has(day))

    if (missingDays.length > 0) {
      return {
        isValid: false,
        missingDays,
        message: `Week missing workouts for: ${missingDays.join(', ')}. Has workouts for: ${Array.from(coveredDays).join(', ')}`
      }
    }

    // Verify critical days (Fri/Sat/Sun) are present
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
  }

  return { isValid: true, missingDays: [], message: 'All required days have workouts' }
}

async function generateDetailedWeek(
  apiKey: string,
  model: string,
  context: AthleteContext,
  planContext: TrainingPlanContext,
  weekOverview: WeekOverview,
  previousWeekFeedback: string | null,
  weekStartDate: string
): Promise<DetailedWeekResponse> {

  // Retry logic for validation failures
  const maxRetries = 3
  let lastError: Error | null = null
  let missingDaysFeedback = ''

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      let prompt = buildWorkoutGenerationPrompt(context, planContext, weekOverview, previousWeekFeedback, weekStartDate)

      // Add feedback about missing days on retry
      if (missingDaysFeedback) {
        prompt = `${missingDaysFeedback}\n\n${prompt}`
      }

      console.log(`Generating detailed week (attempt ${attempt}/${maxRetries})...`)

      const response = await fetch('https://api.x.ai/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`
        },
        body: JSON.stringify({
          model,
          messages: [
            { role: 'system', content: getSystemPrompt() },
            { role: 'user', content: prompt }
          ],
          temperature: attempt === 1 ? 0.7 : (attempt === 2 ? 0.5 : 0.3),
          max_tokens: 8000
        })
      })

      if (!response.ok) {
        throw new Error(`Grok API error: ${response.status}`)
      }

      const result = await response.json()
      const content = result.choices[0]?.message?.content

      if (!content) {
        throw new Error('No content in Grok response')
      }

      const parsed = parseJsonResponse<DetailedWeekResponse>(content)

      // VALIDATION: Check that all required days have workouts AND minimum count
      if (context.daysPerWeek >= 6) {
        const validation = validateWeekCoverage(parsed.workouts, context.daysPerWeek, context.sessionsPerDay)
        if (!validation.isValid) {
          console.warn(`Week validation failed: ${validation.message}`)

          // Calculate expected workouts for error message
          // Mon-Fri: 5 days × sessions, Sat: 1 intense, Sun: 1 recovery
          const expectedMin = context.daysPerWeek === 7
            ? (5 * context.sessionsPerDay) + 1 + 1  // 12 for 2 sessions/day
            : context.daysPerWeek * context.sessionsPerDay

          missingDaysFeedback = `⚠️ PREVIOUS ATTEMPT FAILED VALIDATION ⚠️

${validation.message}

REQUIREMENTS:
- Training days per week: ${context.daysPerWeek}
- Sessions per day: ${context.sessionsPerDay}
- Expected minimum workouts: ${expectedMin}
- You returned: ${parsed.workouts.length} workouts

YOU MUST include workouts for ALL 7 days of the week:
- Monday through Friday: ${context.sessionsPerDay} workouts each (session_number: 1 and 2)
- Saturday: 1 intense workout (session_number: 1 only)
- Sunday: 1 recovery workout (session_number: 1 only)

FRIDAY, SATURDAY, and SUNDAY ARE REQUIRED.
Do NOT stop at Thursday. Continue generating through Sunday.
Saturday and Sunday should each have EXACTLY 1 workout, not ${context.sessionsPerDay}.

THIS IS ATTEMPT ${attempt + 1}/${maxRetries}. If you fail again, the request will fail.
`
          throw new Error(`Validation failed: ${validation.message}`)
        }
      }

      console.log(`✅ Week validated successfully`)
      return parsed

    } catch (e) {
      lastError = e instanceof Error ? e : new Error(String(e))
      console.error(`Attempt ${attempt} failed: ${lastError.message}`)
      if (attempt < maxRetries) {
        console.log('Retrying with enhanced prompt and lower temperature...')
        await new Promise(r => setTimeout(r, 1000))
      }
    }
  }

  throw lastError || new Error('Failed to generate detailed week after retries')
}

function getSystemPrompt(): string {
  return `You are an elite HYROX coach creating personalized training plans.
Generate detailed, actionable workouts that are appropriate for the athlete's level.
Always respond with valid JSON only - no markdown, no explanation text.`
}

function buildWorkoutGenerationPrompt(
  context: AthleteContext,
  planContext: TrainingPlanContext,
  weekOverview: WeekOverview,
  previousWeekFeedback: string | null,
  weekStartDate: string
): string {
  const startDate = new Date(weekStartDate)
  const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
  const startDayName = dayNames[startDate.getDay()]

  // Build phases overview string
  const phasesOverview = planContext.allPhases
    .map(p => `  - ${p.phase.toUpperCase()} (Week ${p.startWeek}-${p.endWeek}): ${p.description}`)
    .join('\n')

  // Calculate weeks until race if we have a race date
  let weeksUntilRace = ''
  if (planContext.raceDate) {
    const raceDate = new Date(planContext.raceDate)
    const weekStart = new Date(weekStartDate)
    const daysUntil = Math.ceil((raceDate.getTime() - weekStart.getTime()) / (1000 * 60 * 60 * 24))
    const weeksLeft = Math.ceil(daysUntil / 7)
    weeksUntilRace = `- Weeks until race: ${weeksLeft}`
  }

  return `Generate detailed workouts for Week ${weekOverview.week_number} of ${planContext.totalWeeks}.

## FULL TRAINING CYCLE CONTEXT
This week is part of a ${planContext.totalWeeks}-week periodized training program.

### Goal: ${planContext.goal}
${planContext.raceDate ? `### Race Date: ${planContext.raceDate}` : ''}
${planContext.targetTime ? `### Target Time: ${planContext.targetTime}` : ''}
${weeksUntilRace}

### Plan Structure (All Phases):
${phasesOverview}

### Deload Weeks: ${planContext.deloadWeeks.length > 0 ? planContext.deloadWeeks.join(', ') : 'None scheduled'}

${planContext.planReasoning ? `### AI Coach Focus Areas:
${planContext.planReasoning.keyFocusAreas.map(a => `  - ${a}`).join('\n')}

### Intensity Progression Strategy:
${planContext.planReasoning.intensityProgression}

### Athlete-Specific Notes:
${planContext.planReasoning.athleteSpecificNotes}` : ''}

## THIS WEEK (Week ${weekOverview.week_number})
- Phase: ${weekOverview.phase} - ${weekOverview.phase_description}
- Focus: ${weekOverview.focus}
- Intensity Guidance: ${weekOverview.intensity_guidance}
- Is deload week: ${weekOverview.is_deload}
- Week starts: ${startDayName}, ${weekStartDate}

## ATHLETE SETUP
- Training days per week: ${context.daysPerWeek}
- Sessions per day: ${context.sessionsPerDay}
- Session duration: ${context.sessionDurationMinutes} minutes
- Fitness level: ${context.fitnessLevel}
- Recovery day: ${context.preferredRecoveryDay || 'Sunday'}
- Equipment: ${context.equipment.join(', ') || 'Full gym access'}
${context.weakStations?.length ? `- Weak stations to focus on: ${context.weakStations.join(', ')}` : ''}

${previousWeekFeedback ? `## PREVIOUS WEEK FEEDBACK\n${previousWeekFeedback}\nAdjust this week's workouts based on this feedback.` : ''}

## IMPORTANT: FOLLOW THE PERIODIZATION
- Ensure workouts MATCH the current phase (${weekOverview.phase})
- Volume and intensity should align with where we are in the ${planContext.totalWeeks}-week cycle
- ${weekOverview.week_number <= 2 ? 'Early weeks: Focus on building base and technique' : ''}
- ${weekOverview.week_number > planContext.totalWeeks - 3 ? 'Final weeks: Taper and sharpen, reduce volume' : ''}
- ${weekOverview.is_deload ? 'DELOAD WEEK: Reduce volume by 40%, maintain some intensity' : ''}

## OUTPUT FORMAT
Return JSON with this exact structure:
{
  "week_number": ${weekOverview.week_number},
  "workouts": [
    {
      "day_of_week": "monday",
      "session_number": 1,
      "workout_type": "full_simulation|half_simulation|station_focus|running|strength|recovery",
      "name": "Workout name",
      "description": "Brief description",
      "estimated_duration": 60,
      "intensity": "recovery|easy|moderate|hard|very_hard|max_effort",
      "ai_explanation": "Why this workout on this day in the context of Week ${weekOverview.week_number}/${planContext.totalWeeks}",
      "segments": [
        {
          "segment_type": "warmup|run|station|cooldown|rest|transition",
          "station_type": "ski_erg|sled_push|sled_pull|burpee_broad_jump|rowing|farmers_carry|sandbag_lunges|wall_balls",
          "name": "Segment name",
          "instructions": "Detailed instructions",
          "target_duration_seconds": 300,
          "target_distance_meters": 1000,
          "target_reps": 50,
          "target_pace": "5:30/km",
          "target_heart_rate_zone": 2,
          "intensity_description": "Easy pace, conversational",
          "sets": 3,
          "rest_between_sets_seconds": 60
        }
      ]
    }
  ]
}

${getExplicitScheduleRequirement(context.daysPerWeek, context.sessionsPerDay, context.preferredRecoveryDay)}`
}

function getExplicitScheduleRequirement(daysPerWeek: number, sessionsPerDay: number, preferredRecoveryDay?: string): string {
  const recoveryDay = (preferredRecoveryDay || 'sunday').toLowerCase()

  if (daysPerWeek === 7) {
    // 7 days - be EXTREMELY explicit
    // Mon-Fri: 2 sessions each, Sat: 1 intense, Sun: 1 recovery = 12 total
    const totalWorkouts = (5 * sessionsPerDay) + 1 + 1  // 12 for sessionsPerDay=2
    return `## ⚠️ CRITICAL: EXACT 7-DAY SCHEDULE REQUIRED ⚠️

YOU MUST GENERATE EXACTLY THIS SCHEDULE - NO EXCEPTIONS:

| Day       | day_of_week | Workouts Required |
|-----------|-------------|-------------------|
| Monday    | "monday"    | ${sessionsPerDay === 2 ? '2 workouts (session_number: 1 and 2)' : '1 workout'} |
| Tuesday   | "tuesday"   | ${sessionsPerDay === 2 ? '2 workouts (session_number: 1 and 2)' : '1 workout'} |
| Wednesday | "wednesday" | ${sessionsPerDay === 2 ? '2 workouts (session_number: 1 and 2)' : '1 workout'} |
| Thursday  | "thursday"  | ${sessionsPerDay === 2 ? '2 workouts (session_number: 1 and 2)' : '1 workout'} |
| Friday    | "friday"    | ${sessionsPerDay === 2 ? '2 workouts (session_number: 1 and 2)' : '1 workout'} |
| Saturday  | "saturday"  | 1 workout (intense/simulation day, session_number: 1) |
| Sunday    | "sunday"    | 1 workout (recovery day, session_number: 1) |

RULES:
1. Your JSON response MUST contain workouts for ALL 7 days
2. FRIDAY must have workouts with day_of_week: "friday"
3. SATURDAY must have EXACTLY 1 workout (intense simulation/race practice)
4. SUNDAY must have EXACTLY 1 workout (active recovery)
5. Total workout objects in your response: ${totalWorkouts}

DO NOT STOP AT THURSDAY. CONTINUE TO FRIDAY, SATURDAY, SUNDAY.`

  } else if (daysPerWeek === 6) {
    return `## SCHEDULE REQUIREMENT
Generate workouts for 6 days: Monday through Saturday.
Recovery day: ${recoveryDay} (no workout)
Each training day: ${sessionsPerDay} session(s)
INCLUDE FRIDAY AND SATURDAY!`

  } else {
    return `## SCHEDULE REQUIREMENT
Generate ${daysPerWeek} workout days with ${sessionsPerDay} session(s) each.
Place recovery/rest on ${recoveryDay}.`
  }
}

function parseJsonResponse<T>(content: string): T {
  // Clean up the response - remove markdown code blocks if present
  let cleaned = content.trim()
  if (cleaned.startsWith('```json')) {
    cleaned = cleaned.slice(7)
  } else if (cleaned.startsWith('```')) {
    cleaned = cleaned.slice(3)
  }
  if (cleaned.endsWith('```')) {
    cleaned = cleaned.slice(0, -3)
  }
  cleaned = cleaned.trim()

  return JSON.parse(cleaned) as T
}

async function saveWeekWorkouts(
  supabase: SupabaseClient,
  userId: string,
  weekInfo: { week_number: number; start_date: string },
  detailedWeek: DetailedWeekResponse
): Promise<{ inserted: number; failed: number }> {
  const weekStartDate = new Date(weekInfo.start_date)
  let inserted = 0
  let failed = 0

  // Map day names to offsets
  const dayOffsets: Record<string, number> = {
    'sunday': 0, 'monday': 1, 'tuesday': 2, 'wednesday': 3,
    'thursday': 4, 'friday': 5, 'saturday': 6
  }

  // Adjust if week starts on Monday (common in training calendars)
  const startDayOfWeek = weekStartDate.getDay()

  for (const workout of detailedWeek.workouts) {
    const dayOffset = dayOffsets[workout.day_of_week.toLowerCase()] || 0

    // Calculate the actual date for this workout
    let daysToAdd = dayOffset - startDayOfWeek
    if (daysToAdd < 0) daysToAdd += 7

    const workoutDate = new Date(weekStartDate)
    workoutDate.setDate(workoutDate.getDate() + daysToAdd)

    // Normalize workout_type to valid DB values
    const validWorkoutTypes = ['full_simulation', 'half_simulation', 'station_focus', 'running', 'strength', 'recovery']
    let workoutType = workout.workout_type?.toLowerCase().replace(/-/g, '_') || 'strength'
    // Map common aliases
    if (workoutType === 'hyrox_simulation' || workoutType === 'simulation') workoutType = 'full_simulation'
    if (workoutType === 'intervals' || workoutType === 'hiit') workoutType = 'station_focus'
    if (!validWorkoutTypes.includes(workoutType)) workoutType = 'strength'

    // Normalize intensity to valid DB values
    const validIntensities = ['recovery', 'easy', 'moderate', 'hard', 'very_hard', 'max_effort']
    let intensity = workout.intensity?.toLowerCase().replace(/-/g, '_') || 'moderate'
    if (!validIntensities.includes(intensity)) intensity = 'moderate'

    // Insert the workout (ensure minimum duration of 15 for recovery days)
    const { data: insertedWorkout, error: workoutError } = await supabase
      .from('planned_workouts')
      .insert({
        user_id: userId,
        name: workout.name,
        description: workout.description,
        workout_type: workoutType,
        scheduled_date: workoutDate.toISOString(),
        day_of_week: workout.day_of_week?.toLowerCase() || null,
        week_number: weekInfo.week_number,
        session_number: workout.session_number,
        estimated_duration: Math.max(workout.estimated_duration || 15, 15), // Minimum 15 min
        intensity: intensity,
        ai_explanation: workout.ai_explanation,
        status: 'planned'
      })
      .select('id')
      .single()

    if (workoutError) {
      console.error(`Failed to insert ${workout.day_of_week} session ${workout.session_number}:`, workoutError.message, workoutError.details)
      failed++
      continue
    }

    inserted++

    // Insert segments
    if (workout.segments?.length && insertedWorkout?.id) {
      const segmentInserts = workout.segments.map((seg, idx) => ({
        planned_workout_id: insertedWorkout.id,
        order_index: idx,
        segment_type: seg.segment_type,
        station_type: seg.station_type,
        name: seg.name,
        instructions: seg.instructions,
        target_duration_seconds: seg.target_duration_seconds,
        target_distance_meters: seg.target_distance_meters,
        target_reps: seg.target_reps,
        target_pace: seg.target_pace,
        target_heart_rate_zone: seg.target_heart_rate_zone,
        intensity_description: seg.intensity_description,
        sets: seg.sets,
        rest_between_sets_seconds: seg.rest_between_sets_seconds
      }))

      const { error: segmentError } = await supabase
        .from('planned_workout_segments')
        .insert(segmentInserts)

      if (segmentError) {
        console.error('Failed to insert segments:', segmentError)
      }
    }
  }

  console.log(`Saved ${inserted}/${detailedWeek.workouts.length} workouts (${failed} failed)`)
  return { inserted, failed }
}
