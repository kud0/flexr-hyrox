-- FLEXR - Single Race Partner Constraint
-- Ensures users can only have ONE active race partner at a time
-- Part of business model: Race Partner is a premium feature with 1:1 pairing

-- Drop trigger if exists (for idempotent migrations)
DROP TRIGGER IF EXISTS enforce_single_race_partner ON user_relationships;
DROP FUNCTION IF EXISTS check_single_race_partner();

-- Function to check single race partner constraint
CREATE OR REPLACE FUNCTION check_single_race_partner()
RETURNS TRIGGER AS $$
BEGIN
  -- Only check for race_partner relationships with accepted status
  IF NEW.relationship_type = 'race_partner' AND NEW.status = 'accepted' THEN

    -- Check if user_a already has a race partner (excluding current relationship)
    IF EXISTS (
      SELECT 1 FROM user_relationships
      WHERE (user_a_id = NEW.user_a_id OR user_b_id = NEW.user_a_id)
        AND relationship_type = 'race_partner'
        AND status = 'accepted'
        AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
    ) THEN
      RAISE EXCEPTION 'User can only have one active race partner. Remove current partner first.'
        USING HINT = 'Race Partner is a premium 1:1 feature',
              ERRCODE = 'P0001';
    END IF;

    -- Check if user_b already has a race partner (excluding current relationship)
    IF EXISTS (
      SELECT 1 FROM user_relationships
      WHERE (user_a_id = NEW.user_b_id OR user_b_id = NEW.user_b_id)
        AND relationship_type = 'race_partner'
        AND status = 'accepted'
        AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
    ) THEN
      RAISE EXCEPTION 'Partner already has an active race partner. They must remove their current partner first.'
        USING HINT = 'Race Partner is a premium 1:1 feature',
              ERRCODE = 'P0001';
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to enforce constraint
CREATE TRIGGER enforce_single_race_partner
  BEFORE INSERT OR UPDATE ON user_relationships
  FOR EACH ROW
  EXECUTE FUNCTION check_single_race_partner();

-- Add comment for documentation
COMMENT ON FUNCTION check_single_race_partner() IS
  'Enforces business rule: Users can only have ONE active race partner at a time. This is part of the Race Partner premium subscription tier.';

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'Migration 016: Single race partner constraint successfully applied';
END $$;
