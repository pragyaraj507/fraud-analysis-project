-- 07_geo_impossible.sql
--
-- Question: Self-join transactions on card ID to detect geographically
-- impossible sequences -- two transactions too far apart geographically
-- to be physically possible given the time gap between them.
--
-- Why it matters: this is a real, industry-standard fraud-detection
-- technique -- a card can't legitimately swipe in NY and then TX ten
-- minutes later.
--
-- Simplification note: without lat/long in this schema, "impossible" is
-- approximated as a state change within a 2-hour window. With real
-- lat/long (as in the full IBM TabFormer file) this would compute actual
-- distance / time to derive an implied speed and flag anything exceeding
-- a plausible travel speed (e.g. > 500 mph).

WITH ordered_txns AS (
    SELECT
        card_id,
        amount,
        merchant_city,
        merchant_state,
        txn_datetime,
        LAG(merchant_state) OVER (PARTITION BY card_id ORDER BY txn_datetime) AS prev_state,
        LAG(txn_datetime) OVER (PARTITION BY card_id ORDER BY txn_datetime)   AS prev_time
    FROM transactions
    WHERE is_online_channel = 0   -- physical-location only; online has no geography
)
SELECT
    card_id,
    prev_state,
    merchant_state,
    prev_time,
    txn_datetime,
    ROUND((julianday(txn_datetime) - julianday(prev_time)) * 24, 2) AS hours_between
FROM ordered_txns
WHERE merchant_state != prev_state
  AND (julianday(txn_datetime) - julianday(prev_time)) * 24 < 2
ORDER BY hours_between ASC;
