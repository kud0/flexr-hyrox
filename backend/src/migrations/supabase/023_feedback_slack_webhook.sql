-- Trigger to notify Slack on new user feedback
-- This uses Supabase's pg_net extension to call our Edge Function

-- Note: The actual webhook is configured in Supabase Dashboard under:
-- Database > Webhooks > Create new webhook
--
-- Settings:
--   Name: notify-feedback-slack
--   Table: user_feedback_requests
--   Events: INSERT
--   Type: Supabase Edge Function
--   Function: notify-feedback-slack
--
-- Alternatively, use pg_net directly (requires enabling the extension):

-- Enable pg_net extension if not already enabled
-- CREATE EXTENSION IF NOT EXISTS pg_net;

-- Create function to call Edge Function via HTTP
CREATE OR REPLACE FUNCTION notify_slack_on_feedback()
RETURNS TRIGGER AS $$
DECLARE
  supabase_url TEXT := current_setting('app.settings.supabase_url', true);
  service_key TEXT := current_setting('app.settings.service_role_key', true);
BEGIN
  -- Call the Edge Function
  PERFORM net.http_post(
    url := supabase_url || '/functions/v1/notify-feedback-slack',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || service_key
    ),
    body := jsonb_build_object(
      'type', 'INSERT',
      'table', 'user_feedback_requests',
      'record', row_to_json(NEW)
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger (commented out - use Dashboard webhook instead for simplicity)
-- CREATE TRIGGER on_feedback_inserted
--   AFTER INSERT ON user_feedback_requests
--   FOR EACH ROW
--   EXECUTE FUNCTION notify_slack_on_feedback();

-- RECOMMENDED: Use Supabase Dashboard to create a Database Webhook instead
-- It's simpler and doesn't require pg_net setup
