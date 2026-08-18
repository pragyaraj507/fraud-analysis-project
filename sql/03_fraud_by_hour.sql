-- 03_fraud_by_hour.sql
--
-- Question: Which hours of day see the highest fraud rate?
--
-- Why it matters: time-of-day is one of the cheapest signals to add to a
-- rules engine, and sets up the "late night" pattern used in feature
-- engineering.

SELECT
    CAST(strftime('%H', txn_datetime) AS INTEGER) AS hour_of_day,
    COUNT(*)                                       AS total_transactions,
    SUM(is_fraud)                                  AS fraud_transactions,
    ROUND(100.0 * SUM(is_fraud) / COUNT(*), 3)     AS fraud_rate_pct
FROM transactions
GROUP BY hour_of_day
ORDER BY fraud_rate_pct DESC;
