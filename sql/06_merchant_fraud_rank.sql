-- 06_merchant_fraud_rank.sql
--
-- Question: Rank merchants by fraud rate, restricted to merchants with a
-- minimum of 100 transactions to avoid small-sample noise.
--
-- Why it matters: feeds the "merchant risk" component of the composite
-- risk score in query 08.

SELECT
    merchant_id,
    merchant_name,
    mcc,
    COUNT(*)                                   AS total_transactions,
    SUM(is_fraud)                              AS fraud_transactions,
    ROUND(100.0 * SUM(is_fraud) / COUNT(*), 3) AS fraud_rate_pct,
    RANK() OVER (ORDER BY 1.0 * SUM(is_fraud) / COUNT(*) DESC) AS fraud_rate_rank
FROM transactions
GROUP BY merchant_id, merchant_name, mcc
HAVING COUNT(*) >= 100
ORDER BY fraud_rate_rank;
