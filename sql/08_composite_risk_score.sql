-- 08_composite_risk_score.sql
--
-- Question: Build a multi-step risk score using a CTE that combines
-- velocity (query 4), amount deviation from that card's historical
-- average, and merchant risk (query 6) into a single composite query.
--
-- Why it matters: this is the first "production-style" query in the
-- project -- combining several weak signals into one score is exactly
-- how a real detection layer would be structured.

WITH card_avg AS (
    SELECT card_id, AVG(amount) AS card_avg_amount
    FROM transactions
    WHERE is_refund_or_reversal = 0
    GROUP BY card_id
),
merchant_risk AS (
    SELECT merchant_id, 1.0 * SUM(is_fraud) / COUNT(*) AS merchant_fraud_rate
    FROM transactions
    GROUP BY merchant_id
    HAVING COUNT(*) >= 100
),
velocity AS (
    SELECT
        t.rowid AS txn_rowid,
        (
            SELECT COUNT(*)
            FROM transactions t2
            WHERE t2.card_id = t.card_id
              AND t2.txn_datetime <= t.txn_datetime
              AND t2.txn_datetime > datetime(t.txn_datetime, '-24 hours')
        ) AS txn_count_trailing_24hr
    FROM transactions t
)
SELECT
    t.rowid                                                       AS txn_id,
    t.card_id,
    t.txn_datetime,
    t.amount,
    t.is_fraud,
    v.txn_count_trailing_24hr,
    ROUND(ABS(t.amount - ca.card_avg_amount), 2)                  AS amount_deviation,
    ROUND(COALESCE(mr.merchant_fraud_rate, 0), 4)                 AS merchant_fraud_rate,
    -- Composite score: simple weighted sum, normalized components.
    -- Weights are illustrative -- the Python notebook tunes these
    -- properly via the logistic-regression coefficients.
    ROUND(
        0.4 * (v.txn_count_trailing_24hr / 10.0)
      + 0.3 * (ABS(t.amount - ca.card_avg_amount) / NULLIF(ca.card_avg_amount, 0))
      + 0.3 * COALESCE(mr.merchant_fraud_rate, 0) * 10
    , 4) AS composite_risk_score
FROM transactions t
JOIN card_avg ca      ON ca.card_id = t.card_id
JOIN velocity v        ON v.txn_rowid = t.rowid
LEFT JOIN merchant_risk mr ON mr.merchant_id = t.merchant_id
ORDER BY composite_risk_score DESC
LIMIT 200;
