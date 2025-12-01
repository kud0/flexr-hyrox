// FLEXR - Weekly AI Learning Engine
// Updates user performance profiles based on training data
// Runs weekly via Supabase cron or on-demand

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Learning weights: 70% historical, 30% new data
const HISTORICAL_WEIGHT = 0.7
const NEW_DATA_WEIGHT = 0.3

// Confidence thresholds
const HIGH_CONFIDENCE_SAMPLES = 10
const MEDIUM_CONFIDENCE_SAMPLES = 5
const LOW_CONFIDENCE_SAMPLES = 3

interface WeeklyData {
  user_id: string
  workouts: any[]
  segments: any[]
}

interface ProfileUpdate {
  fresh_run_pace_per_km: number | null
  compromised_run_paces: Record<string, number>
  station_benchmarks: Record<string, StationBenchmark>
  recovery_profile: RecoveryProfile
  confidence_levels: Record<string, string>
  last_updated: string
  data_points_count: number
}

interface StationBenchmark {
  avg_duration_seconds: number
  best_duration_seconds: number
  avg_reps_per_minute?: number
  trend: 'improving' | 'stable' | 'declining' | 'insufficient_data'
  sample_count: number
}

interface RecoveryProfile {
  avg_transition_time_seconds: number
  hr_recovery_rate: number // BPM drop per minute
  optimal_rest_duration_seconds: number
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    const { user_id, force_update } = await req.json()

    // Get date range for this week
    const oneWeekAgo = new Date()
    oneWeekAgo.setDate(oneWeekAgo.getDate() - 7)

    // Fetch this week's completed workouts with segments
    const { data: workouts, error: workoutsError } = await supabase
      .from('workouts')
      .select(`
        *,
        workout_segments (*)
      `)
      .eq('user_id', user_id)
      .eq('status', 'completed')
      .gte('completed_at', oneWeekAgo.toISOString())
      .order('completed_at', { ascending: false })

    if (workoutsError) throw workoutsError

    if (!workouts || workouts.length === 0) {
      return new Response(
        JSON.stringify({
          success: true,
          message: 'No completed workouts this week',
          updated: false
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Fetch current profile
    const { data: currentProfile } = await supabase
      .from('performance_profiles')
      .select('*')
      .eq('user_id', user_id)
      .single()

    // Aggregate all segments
    const allSegments = workouts.flatMap(w => w.workout_segments || [])

    // Calculate new metrics
    const newMetrics = calculateWeeklyMetrics(allSegments)

    // Merge with existing profile using weighted average
    const updatedProfile = mergeProfiles(currentProfile, newMetrics)

    // Save updated profile
    const { data: savedProfile, error: saveError } = await supabase
      .from('performance_profiles')
      .upsert({
        user_id,
        ...updatedProfile,
        last_updated: new Date().toISOString()
      })
      .select()
      .single()

    if (saveError) throw saveError

    // Create weekly summary
    const summary = {
      user_id,
      week_start: oneWeekAgo.toISOString(),
      week_end: new Date().toISOString(),
      total_workouts: workouts.length,
      total_duration_minutes: workouts.reduce((sum, w) => sum + (w.actual_duration_minutes || 0), 0),
      total_distance_km: allSegments
        .filter(s => s.segment_type === 'run')
        .reduce((sum, s) => sum + (s.actual_distance_meters || 0), 0) / 1000,
      avg_readiness: workouts.reduce((sum, w) => sum + (w.readiness_score || 0), 0) / workouts.length,
      profile_changes: {
        fresh_run_pace_change: currentProfile?.fresh_run_pace_per_km
          ? updatedProfile.fresh_run_pace_per_km - currentProfile.fresh_run_pace_per_km
          : null
      }
    }

    const { error: summaryError } = await supabase
      .from('weekly_summaries')
      .insert(summary)

    if (summaryError) console.error('Failed to save weekly summary:', summaryError)

    return new Response(
      JSON.stringify({
        success: true,
        updated: true,
        profile: savedProfile,
        summary: {
          workouts_processed: workouts.length,
          segments_analyzed: allSegments.length,
          ...summary
        }
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      }
    )

  } catch (error) {
    console.error('Weekly learning error:', error)
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500
      }
    )
  }
})

function calculateWeeklyMetrics(segments: any[]) {
  const runSegments = segments.filter(s => s.segment_type === 'run' && s.actual_duration_seconds)
  const stationSegments = segments.filter(s => s.segment_type === 'station' && s.actual_duration_seconds)
  const transitionSegments = segments.filter(s => s.segment_type === 'transition')

  // Fresh run pace (runs at start of workout, not after stations)
  const freshRuns = runSegments.filter(s => !s.is_compromised && s.order_index <= 2)
  const freshRunPace = freshRuns.length > 0
    ? freshRuns.reduce((sum, s) => sum + (s.actual_duration_seconds / (s.actual_distance_meters / 1000)), 0) / freshRuns.length / 60
    : null

  // Compromised run paces by station
  const compromisedRuns = runSegments.filter(s => s.is_compromised && s.previous_station)
  const compromisedPacesByStation: Record<string, number[]> = {}

  compromisedRuns.forEach(run => {
    const station = run.previous_station
    if (!compromisedPacesByStation[station]) {
      compromisedPacesByStation[station] = []
    }
    const paceMinPerKm = (run.actual_duration_seconds / (run.actual_distance_meters / 1000)) / 60
    compromisedPacesByStation[station].push(paceMinPerKm)
  })

  const avgCompromisedPaces: Record<string, number> = {}
  for (const [station, paces] of Object.entries(compromisedPacesByStation)) {
    avgCompromisedPaces[station] = paces.reduce((a, b) => a + b, 0) / paces.length
  }

  // Station benchmarks
  const stationBenchmarks: Record<string, StationBenchmark> = {}
  const stationsByType = groupBy(stationSegments, 'station_type')

  for (const [stationType, stationData] of Object.entries(stationsByType)) {
    const durations = stationData.map(s => s.actual_duration_seconds).filter(Boolean)
    if (durations.length > 0) {
      stationBenchmarks[stationType] = {
        avg_duration_seconds: durations.reduce((a, b) => a + b, 0) / durations.length,
        best_duration_seconds: Math.min(...durations),
        sample_count: durations.length,
        trend: calculateTrend(durations)
      }
    }
  }

  // Recovery profile
  const transitionTimes = transitionSegments
    .map(s => s.actual_duration_seconds)
    .filter(Boolean)

  const avgTransitionTime = transitionTimes.length > 0
    ? transitionTimes.reduce((a, b) => a + b, 0) / transitionTimes.length
    : 60 // default 60 seconds

  // HR recovery (from segments with HR data)
  const segmentsWithHR = segments.filter(s => s.avg_heart_rate && s.segment_type === 'rest')
  const hrRecoveryRate = segmentsWithHR.length >= 2 ? 10 : 8 // BPM per minute (simplified)

  return {
    fresh_run_pace_per_km: freshRunPace,
    compromised_run_paces: avgCompromisedPaces,
    station_benchmarks: stationBenchmarks,
    recovery_profile: {
      avg_transition_time_seconds: avgTransitionTime,
      hr_recovery_rate: hrRecoveryRate,
      optimal_rest_duration_seconds: Math.max(30, avgTransitionTime * 0.8)
    },
    data_points_count: segments.length
  }
}

function mergeProfiles(existing: any | null, newData: any): ProfileUpdate {
  if (!existing) {
    // First profile - use new data directly
    return {
      ...newData,
      confidence_levels: calculateConfidenceLevels(newData),
      last_updated: new Date().toISOString()
    }
  }

  // Weighted merge
  const merged: ProfileUpdate = {
    fresh_run_pace_per_km: weightedAverage(
      existing.fresh_run_pace_per_km,
      newData.fresh_run_pace_per_km,
      HISTORICAL_WEIGHT,
      NEW_DATA_WEIGHT
    ),
    compromised_run_paces: mergeRecords(
      existing.compromised_run_paces || {},
      newData.compromised_run_paces || {}
    ),
    station_benchmarks: mergeStationBenchmarks(
      existing.station_benchmarks || {},
      newData.station_benchmarks || {}
    ),
    recovery_profile: {
      avg_transition_time_seconds: weightedAverage(
        existing.recovery_profile?.avg_transition_time_seconds,
        newData.recovery_profile.avg_transition_time_seconds,
        HISTORICAL_WEIGHT,
        NEW_DATA_WEIGHT
      ),
      hr_recovery_rate: weightedAverage(
        existing.recovery_profile?.hr_recovery_rate,
        newData.recovery_profile.hr_recovery_rate,
        HISTORICAL_WEIGHT,
        NEW_DATA_WEIGHT
      ),
      optimal_rest_duration_seconds: weightedAverage(
        existing.recovery_profile?.optimal_rest_duration_seconds,
        newData.recovery_profile.optimal_rest_duration_seconds,
        HISTORICAL_WEIGHT,
        NEW_DATA_WEIGHT
      )
    },
    confidence_levels: {},
    last_updated: new Date().toISOString(),
    data_points_count: (existing.data_points_count || 0) + newData.data_points_count
  }

  merged.confidence_levels = calculateConfidenceLevels(merged)
  return merged
}

function weightedAverage(
  oldValue: number | null | undefined,
  newValue: number | null | undefined,
  oldWeight: number,
  newWeight: number
): number | null {
  if (oldValue == null && newValue == null) return null
  if (oldValue == null) return newValue!
  if (newValue == null) return oldValue
  return oldValue * oldWeight + newValue * newWeight
}

function mergeRecords(
  existing: Record<string, number>,
  newData: Record<string, number>
): Record<string, number> {
  const merged: Record<string, number> = { ...existing }
  for (const [key, value] of Object.entries(newData)) {
    if (merged[key]) {
      merged[key] = merged[key] * HISTORICAL_WEIGHT + value * NEW_DATA_WEIGHT
    } else {
      merged[key] = value
    }
  }
  return merged
}

function mergeStationBenchmarks(
  existing: Record<string, StationBenchmark>,
  newData: Record<string, StationBenchmark>
): Record<string, StationBenchmark> {
  const merged: Record<string, StationBenchmark> = { ...existing }

  for (const [station, benchmark] of Object.entries(newData)) {
    if (merged[station]) {
      merged[station] = {
        avg_duration_seconds: weightedAverage(
          merged[station].avg_duration_seconds,
          benchmark.avg_duration_seconds,
          HISTORICAL_WEIGHT,
          NEW_DATA_WEIGHT
        )!,
        best_duration_seconds: Math.min(merged[station].best_duration_seconds, benchmark.best_duration_seconds),
        sample_count: merged[station].sample_count + benchmark.sample_count,
        trend: benchmark.trend // Use latest trend
      }
    } else {
      merged[station] = benchmark
    }
  }

  return merged
}

function calculateConfidenceLevels(profile: any): Record<string, string> {
  const levels: Record<string, string> = {}

  // Running confidence
  const runSamples = profile.data_points_count || 0
  if (runSamples >= HIGH_CONFIDENCE_SAMPLES) {
    levels.running = 'high'
  } else if (runSamples >= MEDIUM_CONFIDENCE_SAMPLES) {
    levels.running = 'medium'
  } else if (runSamples >= LOW_CONFIDENCE_SAMPLES) {
    levels.running = 'low'
  } else {
    levels.running = 'estimated'
  }

  // Station confidence (per station)
  for (const [station, benchmark] of Object.entries(profile.station_benchmarks || {}) as [string, StationBenchmark][]) {
    if (benchmark.sample_count >= HIGH_CONFIDENCE_SAMPLES) {
      levels[station] = 'high'
    } else if (benchmark.sample_count >= MEDIUM_CONFIDENCE_SAMPLES) {
      levels[station] = 'medium'
    } else if (benchmark.sample_count >= LOW_CONFIDENCE_SAMPLES) {
      levels[station] = 'low'
    } else {
      levels[station] = 'estimated'
    }
  }

  return levels
}

function calculateTrend(values: number[]): 'improving' | 'stable' | 'declining' | 'insufficient_data' {
  if (values.length < 3) return 'insufficient_data'

  // Simple linear regression
  const n = values.length
  const xMean = (n - 1) / 2
  const yMean = values.reduce((a, b) => a + b, 0) / n

  let numerator = 0
  let denominator = 0

  for (let i = 0; i < n; i++) {
    numerator += (i - xMean) * (values[i] - yMean)
    denominator += (i - xMean) ** 2
  }

  const slope = numerator / denominator
  const percentChange = (slope / yMean) * 100

  // For duration, negative slope = improving (faster)
  if (percentChange < -2) return 'improving'
  if (percentChange > 2) return 'declining'
  return 'stable'
}

function groupBy<T>(array: T[], key: keyof T): Record<string, T[]> {
  return array.reduce((groups, item) => {
    const value = String(item[key])
    if (!groups[value]) groups[value] = []
    groups[value].push(item)
    return groups
  }, {} as Record<string, T[]>)
}
