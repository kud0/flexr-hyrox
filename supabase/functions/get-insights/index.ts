// FLEXR - AI Insights Generation
// Provides personalized training insights using Grok AI

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface InsightRequest {
  user_id: string
  insight_type?: 'weekly_summary' | 'training_balance' | 'race_readiness' | 'recovery' | 'compromised_running'
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const grokApiKey = Deno.env.get('GROK_API_KEY')!

    const supabase = createClient(supabaseUrl, supabaseServiceKey)
    const { user_id, insight_type }: InsightRequest = await req.json()

    // Fetch user data
    const [userResult, profileResult, workoutsResult, summariesResult] = await Promise.all([
      supabase.from('users').select('*').eq('id', user_id).single(),
      supabase.from('performance_profiles').select('*').eq('id', user_id).single(),
      supabase.from('workouts').select(`*, workout_segments (*)`).eq('user_id', user_id).order('created_at', { ascending: false }).limit(10),
      supabase.from('weekly_summaries').select('*').eq('user_id', user_id).order('week_end', { ascending: false }).limit(4)
    ])

    const user = userResult.data
    const profile = profileResult.data
    const workouts = workoutsResult.data || []
    const summaries = summariesResult.data || []

    // Build context for AI
    const context = buildInsightContext(user, profile, workouts, summaries)

    // Generate insights with Grok
    const prompt = buildInsightPrompt(insight_type || 'weekly_summary', context)

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
            content: `You are FLEXR AI, a HYROX training coach providing actionable insights.

Your insights should be:
- Specific and data-driven
- Actionable with clear recommendations
- Encouraging but honest
- Focused on HYROX performance

Respond in JSON format:
{
  "headline": "Short impactful headline (max 60 chars)",
  "summary": "2-3 sentence summary of the insight",
  "details": ["Bullet point 1", "Bullet point 2", ...],
  "recommendations": [
    {"action": "What to do", "reason": "Why it matters", "priority": "high|medium|low"}
  ],
  "metrics_highlight": {
    "label": "Key metric name",
    "value": "Value with units",
    "trend": "up|down|stable",
    "is_positive": true|false
  }
}`
          },
          {
            role: 'user',
            content: prompt
          }
        ],
        temperature: 0.7,
        max_tokens: 1000
      })
    })

    if (!grokResponse.ok) {
      throw new Error(`Grok API error: ${grokResponse.status}`)
    }

    const grokData = await grokResponse.json()
    const insightJson = grokData.choices[0].message.content

    let insight
    try {
      const cleanJson = insightJson.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim()
      insight = JSON.parse(cleanJson)
    } catch (e) {
      console.error('Failed to parse insight:', insightJson)
      throw new Error('Failed to parse AI response')
    }

    return new Response(
      JSON.stringify({
        success: true,
        insight_type: insight_type || 'weekly_summary',
        insight,
        generated_at: new Date().toISOString()
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      }
    )

  } catch (error) {
    console.error('Insight generation error:', error)
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500
      }
    )
  }
})

function buildInsightContext(user: any, profile: any, workouts: any[], summaries: any[]) {
  return {
    user: {
      goal: user?.training_goal,
      experience: user?.experience_level,
      race_date: user?.race_date,
      days_until_race: user?.race_date
        ? Math.ceil((new Date(user.race_date).getTime() - Date.now()) / (1000 * 60 * 60 * 24))
        : null
    },
    profile: {
      fresh_pace: profile?.fresh_run_pace_per_km,
      compromised_paces: profile?.compromised_run_paces,
      station_benchmarks: profile?.station_benchmarks,
      confidence_levels: profile?.confidence_levels,
      data_points: profile?.data_points_count
    },
    recent_training: {
      workout_count: workouts.length,
      total_duration_minutes: workouts.reduce((sum, w) => sum + (w.actual_duration_minutes || 0), 0),
      avg_readiness: workouts.length > 0
        ? workouts.reduce((sum, w) => sum + (w.readiness_score || 0), 0) / workouts.length
        : null,
      workout_types: workouts.map(w => w.workout_type)
    },
    weekly_trends: summaries.map(s => ({
      week: s.week_end,
      workouts: s.total_workouts,
      duration: s.total_duration_minutes,
      distance_km: s.total_distance_km
    }))
  }
}

function buildInsightPrompt(type: string, context: any): string {
  const base = `Analyze this HYROX athlete's data and provide ${type} insights:\n\n${JSON.stringify(context, null, 2)}\n\n`

  switch (type) {
    case 'weekly_summary':
      return base + `Focus on: Overall training load, key achievements, areas for improvement, and next week's focus.`

    case 'training_balance':
      return base + `Focus on: Balance between running and stations, weak stations vs strong stations, volume distribution.`

    case 'race_readiness':
      return base + `Focus on: Current fitness vs race requirements, gaps to address, confidence level for race day, taper recommendations.`

    case 'recovery':
      return base + `Focus on: Recovery trends, readiness patterns, signs of overtraining, rest recommendations.`

    case 'compromised_running':
      return base + `Focus on: Pace degradation patterns after each station, which stations affect running most, strategies to improve.`

    default:
      return base + `Provide a comprehensive training insight.`
  }
}
