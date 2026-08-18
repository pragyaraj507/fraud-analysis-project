-- 01_overall_fraud_rate.sql
--
-- Question: What is the overall fraud rate, and how does it vary by
-- merchant category (MCC)?
--
-- Why it matters: this is the baseline number every other metric in the
-- project gets compared against, and the MCC breakdown is the first hint
-- of where fraud concentrates.

-- Overall fraud rate
SELECT
    COUNT(*)                                   AS total_transactions,
    SUM(is_fraud)                              AS fraud_transactions,
    ROUND(100.0 * SUM(is_fraud) / COUNT(*), 3) AS fraud_rate_pct
FROM transactions;

-- Fraud rate by merchant category (MCC)
SELECT
    mcc,
    COUNT(*)                                   AS total_transactions,
    SUM(is_fraud)                              AS fraud_transactions,
    ROUND(100.0 * SUM(is_fraud) / COUNT(*), 3) AS fraud_rate_pct
FROM transactions
GROUP BY mcc
ORDER BY fraud_rate_pct DESC;
