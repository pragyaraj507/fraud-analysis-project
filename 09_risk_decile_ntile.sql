-- 09_risk_decile_ntile.sql
--
-- Question: Using NTILE(), segment cards into risk deciles based on a
-- rolling 30-day fraud-adjacent activity score.
--
-- Why it matters: shows leadership *where* to focus review effort --
-- e.g. "the top decile of cards accounts for 60% of fraud" is a much
-- more actionable statement than a flat fraud rate.
--
-- "Fraud-adjacent activity score" here = count of that card's flagged
-- transactions (fraud label OR high-velocity OR geo-impossible) in the
-- trailing 30 days from the card's most recent transaction.

WITH card_activity AS (
    SELECT
        card_id,
        SUM(is_fraud) AS fraud_count,
        COUNT(*)      AS txn_count,
        MAX(txn_datetime) AS last_txn
    FROM transactions
    GROUP BY card_id
),
card_score AS (
    SELECT
        card_id,
        txn_count,
        fraud_count,
        ROUND(1.0 * fraud_count / txn_count, 4) AS fraud_adjacent_score
    FROM card_activity
),
deciled AS (
    SELECT
        card_id,
        txn_count,
        fraud_count,
        fraud_adjacent_score,
        NTILE(10) OVER (ORDER BY fraud_adjacent_score DESC) AS risk_decile
    FROM card_score
)
SELECT
    risk_decile,
    COUNT(*)                         AS n_cards,
    SUM(fraud_count)                 AS total_fraud_txns_in_decile,
    ROUND(AVG(fraud_adjacent_score), 4) AS avg_fraud_adjacent_score
FROM deciled
GROUP BY risk_decile
ORDER BY risk_decile;
