-- Merge duplicate bank_accounts for the same user when iban_last4 + account_holder match.
-- Keeps the best row (primary > verified > oldest), reassigns payment links and connections, then deletes dupes.
-- Run inside a transaction; review the SELECT previews first.

BEGIN;

CREATE TEMP TABLE bank_account_dupes AS
WITH ranked AS (
  SELECT
    id,
    user_id,
    iban_last4,
    account_holder,
    is_primary,
    verified,
    created_at,
    ROW_NUMBER() OVER (
      PARTITION BY user_id, iban_last4, account_holder
      ORDER BY is_primary DESC, verified DESC, created_at ASC
    ) AS rn
  FROM bank_accounts
)
SELECT
  r.id AS dupe_id,
  k.id AS keeper_id
FROM ranked r
JOIN ranked k
  ON k.user_id = r.user_id
 AND k.iban_last4 = r.iban_last4
 AND k.account_holder = r.account_holder
 AND k.rn = 1
WHERE r.rn > 1;

-- Preview
SELECT 'dupes_to_merge' AS step, count(*) FROM bank_account_dupes;

UPDATE payment_links pl
SET bank_account_id = d.keeper_id
FROM bank_account_dupes d
WHERE pl.bank_account_id = d.dupe_id;

UPDATE bank_connections bc
SET bank_account_id = d.keeper_id
FROM bank_account_dupes d
WHERE bc.bank_account_id = d.dupe_id;

DELETE FROM bank_accounts ba
USING bank_account_dupes d
WHERE ba.id = d.dupe_id;

-- Ensure at most one primary per user
WITH primaries AS (
  SELECT
    id,
    user_id,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at ASC) AS rn
  FROM bank_accounts
  WHERE is_primary = true
)
UPDATE bank_accounts ba
SET is_primary = false
FROM primaries p
WHERE ba.id = p.id AND p.rn > 1;

COMMIT;
