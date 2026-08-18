-- 02_amount_comparison.sql
--
-- Question: What is the average transaction amount for fraudulent vs.
-- legitimate transactions?
--
-- Why it matters: sets up whether "amount" alone is a usable fraud
-- signal, and motivates the amount-deviation feature used later.

SELECT
    CASE WHEN is_fraud = 1 THEN 'Fraud' ELSE 'Legitimate' END AS txn_type,
    COUNT(*)                                                  AS n_transactions,
    ROUND(AVG(amount), 2)                                     AS avg_amount,
    ROUND(MIN(amount), 2)                                     AS min_amount,
    ROUND(MAX(amount), 2)                                     AS max_amount
FROM transactions
WHERE is_refund_or_reversal = 0   -- exclude refunds/reversals, see Section 4
GROUP BY txn_type;
