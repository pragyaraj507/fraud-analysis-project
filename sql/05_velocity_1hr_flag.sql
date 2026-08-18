-- 05_velocity_1hr_flag.sql
--
-- Question: Flag cards with more than N transactions within a 1-hour
-- window using LAG()/LEAD() on the transaction timestamp, partitioned by
-- card ID.
--
-- Why it matters: catches the "rapid-fire" pattern (a stolen card being
-- drained quickly) that a single trailing-count query can smooth over.

WITH lagged AS (
    SELECT
        card_id,
        txn_datetime,
        amount,
        is_fraud,
        LAG(txn_datetime, 2) OVER (PARTITION BY card_id ORDER BY txn_datetime) AS txn_2_back
    FROM transactions
),
flagged AS (
    SELECT
        *,
        -- True if this transaction and the 2 preceding it on the same
        -- card all happened within a single 1-hour window -> N = 3+
        CASE
            WHEN txn_2_back IS NOT NULL
             AND (julianday(txn_datetime) - julianday(txn_2_back)) * 24 <= 1
            THEN 1 ELSE 0
        END AS is_high_velocity_1hr
    FROM lagged
)
SELECT *
FROM flagged
WHERE is_high_velocity_1hr = 1
ORDER BY card_id, txn_datetime;
