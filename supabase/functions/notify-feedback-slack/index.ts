// FLEXR - Slack Notification for User Feedback
// Sends a Slack message when new feedback is submitted

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const SLACK_WEBHOOK_URL = Deno.env.get('SLACK_FEEDBACK_WEBHOOK_URL')
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface FeedbackPayload {
  type: 'INSERT'
  table: string
  record: {
    id: string
    user_id: string
    category: string
    message: string
    app_context: string | null
    training_week: number | null
    days_since_signup: number | null
    created_at: string
  }
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const payload: FeedbackPayload = await req.json()

    if (!payload.record) {
      return new Response(JSON.stringify({ error: 'No record in payload' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const { user_id, category, message, training_week, days_since_signup, app_context } = payload.record

    // Fetch user email from Supabase
    let userEmail = 'Unknown user'
    let userName = ''

    if (user_id && SUPABASE_URL && SUPABASE_SERVICE_ROLE_KEY) {
      try {
        const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
        const { data: user } = await supabase
          .from('users')
          .select('email, name')
          .eq('id', user_id)
          .single()

        if (user?.email) {
          userEmail = user.email
          userName = user.name || ''
        }
      } catch (e) {
        console.error('Failed to fetch user:', e)
      }
    }

    // Format category for display
    const categoryEmoji: Record<string, string> = {
      'feature_request': '💡',
      'bug_report': '🐛',
      'general': '💬',
      'pulse_check': '❤️'
    }

    const categoryName: Record<string, string> = {
      'feature_request': 'Feature Request',
      'bug_report': 'Bug Report',
      'general': 'General Feedback',
      'pulse_check': 'Quick Pulse'
    }

    const emoji = categoryEmoji[category] || '📩'
    const name = categoryName[category] || category

    // Build context string
    const contextParts: string[] = []
    if (training_week) contextParts.push(`Week ${training_week}`)
    if (days_since_signup) contextParts.push(`Day ${days_since_signup}`)
    if (app_context) contextParts.push(`from ${app_context}`)
    const contextStr = contextParts.length > 0 ? contextParts.join(' • ') : 'New user'

    // Build user display string
    const userDisplay = userName ? `${userName} (${userEmail})` : userEmail

    // Build Slack message
    const slackMessage = {
      blocks: [
        {
          type: "header",
          text: {
            type: "plain_text",
            text: `${emoji} New ${name}`,
            emoji: true
          }
        },
        {
          type: "section",
          text: {
            type: "mrkdwn",
            text: `*Message:*\n${message}`
          }
        },
        {
          type: "section",
          fields: [
            {
              type: "mrkdwn",
              text: `*From:*\n${userDisplay}`
            },
            {
              type: "mrkdwn",
              text: `*Context:*\n${contextStr}`
            }
          ]
        },
        {
          type: "divider"
        }
      ]
    }

    // Send to Slack
    if (!SLACK_WEBHOOK_URL) {
      console.error('SLACK_FEEDBACK_WEBHOOK_URL not configured')
      return new Response(JSON.stringify({ error: 'Slack webhook not configured' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const slackResponse = await fetch(SLACK_WEBHOOK_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(slackMessage)
    })

    if (!slackResponse.ok) {
      const errorText = await slackResponse.text()
      console.error('Slack error:', errorText)
      return new Response(JSON.stringify({ error: 'Slack send failed', details: errorText }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    console.log(`✅ Slack notification sent for ${category} feedback`)

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (error) {
    console.error('Error:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
