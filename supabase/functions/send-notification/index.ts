// FLEXR - Push Notification Service
// Uses Supabase + APNs for iOS push notifications

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface NotificationRequest {
  user_id: string
  type: 'workout_reminder' | 'workout_ready' | 'weekly_summary' | 'achievement' | 'race_countdown' | 'rest_day'
  title?: string
  body?: string
  data?: Record<string, any>
}

// Notification templates
const templates: Record<string, { title: string, body: string }> = {
  workout_reminder: {
    title: "Time to Train! 💪",
    body: "Your workout is ready. Let's crush it!"
  },
  workout_ready: {
    title: "Workout Generated",
    body: "Your AI-powered workout is ready. Tap to start."
  },
  weekly_summary: {
    title: "Weekly Summary Ready 📊",
    body: "See how you performed this week and what's next."
  },
  achievement: {
    title: "New Achievement! 🏆",
    body: "You've unlocked something special. Tap to see."
  },
  race_countdown: {
    title: "Race Day Approaching",
    body: "X days until your race. Stay focused!"
  },
  rest_day: {
    title: "Rest Day Reminder 😴",
    body: "Recovery is training too. Take it easy today."
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const apnsKeyId = Deno.env.get('APNS_KEY_ID')!
    const apnsTeamId = Deno.env.get('APNS_TEAM_ID')!
    const apnsPrivateKey = Deno.env.get('APNS_PRIVATE_KEY')!
    const apnsBundleId = Deno.env.get('APNS_BUNDLE_ID') || 'com.flexr.app'

    const supabase = createClient(supabaseUrl, supabaseServiceKey)
    const { user_id, type, title, body, data }: NotificationRequest = await req.json()

    // Get user's device tokens
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id, name, device_tokens, notifications_enabled')
      .eq('id', user_id)
      .single()

    if (userError || !user) {
      throw new Error('User not found')
    }

    if (!user.notifications_enabled) {
      return new Response(
        JSON.stringify({ success: true, sent: false, reason: 'notifications_disabled' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const deviceTokens = user.device_tokens || []
    if (deviceTokens.length === 0) {
      return new Response(
        JSON.stringify({ success: true, sent: false, reason: 'no_device_tokens' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get template or use custom
    const template = templates[type] || { title: 'FLEXR', body: 'You have a notification' }
    const notificationTitle = title || template.title
    const notificationBody = body || template.body

    // Generate JWT for APNs
    const jwt = await generateAPNsJWT(apnsKeyId, apnsTeamId, apnsPrivateKey)

    // Send to all device tokens
    const results = await Promise.all(
      deviceTokens.map(token => sendAPNsNotification(
        token,
        jwt,
        apnsBundleId,
        {
          aps: {
            alert: {
              title: notificationTitle,
              body: notificationBody.replace('X', data?.days_until_race || '')
            },
            sound: 'default',
            badge: 1
          },
          ...data
        }
      ))
    )

    // Log notification
    await supabase.from('notification_logs').insert({
      user_id,
      type,
      title: notificationTitle,
      body: notificationBody,
      sent_at: new Date().toISOString(),
      success: results.every(r => r.success)
    }).catch(() => {}) // Don't fail if logging fails

    return new Response(
      JSON.stringify({
        success: true,
        sent: true,
        results
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      }
    )

  } catch (error) {
    console.error('Notification error:', error)
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500
      }
    )
  }
})

async function generateAPNsJWT(keyId: string, teamId: string, privateKey: string): Promise<string> {
  const header = {
    alg: 'ES256',
    kid: keyId
  }

  const payload = {
    iss: teamId,
    iat: Math.floor(Date.now() / 1000)
  }

  // Import the private key
  const keyData = privateKey.replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s/g, '')

  const binaryKey = Uint8Array.from(atob(keyData), c => c.charCodeAt(0))

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    binaryKey,
    { name: 'ECDSA', namedCurve: 'P-256' },
    false,
    ['sign']
  )

  // Create JWT
  const encoder = new TextEncoder()
  const headerB64 = btoa(JSON.stringify(header)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')
  const payloadB64 = btoa(JSON.stringify(payload)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')
  const signingInput = `${headerB64}.${payloadB64}`

  const signature = await crypto.subtle.sign(
    { name: 'ECDSA', hash: 'SHA-256' },
    cryptoKey,
    encoder.encode(signingInput)
  )

  const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')

  return `${signingInput}.${signatureB64}`
}

async function sendAPNsNotification(
  deviceToken: string,
  jwt: string,
  bundleId: string,
  payload: any
): Promise<{ success: boolean, error?: string }> {
  const isProduction = Deno.env.get('APNS_PRODUCTION') === 'true'
  const host = isProduction
    ? 'api.push.apple.com'
    : 'api.sandbox.push.apple.com'

  try {
    const response = await fetch(`https://${host}/3/device/${deviceToken}`, {
      method: 'POST',
      headers: {
        'authorization': `bearer ${jwt}`,
        'apns-topic': bundleId,
        'apns-push-type': 'alert',
        'apns-priority': '10',
        'content-type': 'application/json'
      },
      body: JSON.stringify(payload)
    })

    if (response.ok) {
      return { success: true }
    } else {
      const error = await response.json().catch(() => ({ reason: 'unknown' }))
      return { success: false, error: error.reason }
    }
  } catch (error) {
    return { success: false, error: error.message }
  }
}
