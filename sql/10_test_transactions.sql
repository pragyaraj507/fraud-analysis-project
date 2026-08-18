-- 10_test_transactions.sql
--
-- Question: Identify "test transactions" -- a small-amount charge
-- immediately followed by a large charge on the same card within a
-- short window, a known fraud pattern used to test whether a stolen
-- card is still active.
--
-- Why it matters: this is a very specific, well-documented fraud
-- signature that a static amount-threshold rule completely misses,
-- since neither individual charge looks unusual on its own.

WITH ordered AS (
    SELECT
        card_id,
        amount,
        txn_datetime,
        is_fraud,
        LEAD(amount) OVER (PARTITION BY card_id ORDER BY txn_datetime)        AS next_amount,
        LEAD(txn_datetime) OVER (PARTITION BY card_id ORDER BY txn_datetime)  AS next_txn_datetime
    FROM transactions
    WHERE is_refund_or_reversal = 0
)
SELECT
    card_id,
    amount        AS test_charge_amount,
    txn_datetime  AS test_charge_time,
    next_amount   AS followup_charge_amount,
    next_txn_datetime AS followup_charge_time,
    ROUND((julianday(next_txn_datetime) - julianday(txn_datetime)) * 24 * 60, 1) AS minutes_between
FROM ordered
WHERE amount <= 2.00                       -- "small" test charge
  AND next_amount >= 100.00                -- immediately followed by a large charge
  AND (julianday(next_txn_datetime) - julianday(txn_datetime)) * 24 <= 1  -- within 1 hour
ORDER BY minutes_between ASC;
