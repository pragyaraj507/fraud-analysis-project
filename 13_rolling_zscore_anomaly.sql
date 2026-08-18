-- 13_rolling_zscore_anomaly.sql
--
-- Question: Rolling z-score anomaly detection -- using window functions
-- to compute each card's trailing 30-day rolling mean and standard
-- deviation, then flag any transaction more than 3 standard deviations
-- above that rolling mean, entirely within SQL.
--
-- Why it matters: this is a statistically principled version of query 12
-- -- instead of a fixed percentile, it flags anything that's an outlier
-- relative to that card's own recent *volatility*, not just its level.
--
-- Note: most SQL engines (including SQLite and, until v16, Postgres)
-- lack a native rolling STDDEV window function. This query computes the
-- rolling mean natively in SQL, and approximates rolling variance with a
-- second pass over the mean-of-squared-deviations -- which is correct
-- but harder to read than a single window call. The true, easiest-to-read
-- rolling stddev is computed in pandas (`.rolling().std()`) in the
-- Python Advanced Tier -- see notebooks/fraud_analysis.ipynb, Section 5.

WITH rolling_mean AS (
    SELECT
        rowid           AS txn_rowid,
        card_id,
        txn_datetime,
        amount,
        is_fraud,
        AVG(amount) OVER (
            PARTITION BY card_id
            ORDER BY txn_datetime
            ROWS BETWEEN 30 PRECEDING AND 1 PRECEDING
        ) AS rolling_avg
    FROM transactions
    WHERE is_refund_or_reversal = 0
),
rolling_var AS (
    SELECT
        rm.txn_rowid,
        rm.card_id,
        rm.txn_datetime,
        rm.amount,
        rm.is_fraud,
        rm.rolling_avg,
        -- approximate rolling stddev: mean squared deviation of the same
        -- trailing window from that window's own rolling_avg
        (
            SELECT AVG((t2.amount - rm.rolling_avg) * (t2.amount - rm.rolling_avg))
            FROM transactions t2
            WHERE t2.card_id = rm.card_id
              AND t2.txn_datetime < rm.txn_datetime
            ORDER BY t2.txn_datetime DESC
            LIMIT 30
        ) AS rolling_variance
    FROM rolling_mean rm
    WHERE rm.rolling_avg IS NOT NULL
)
SELECT
    card_id,
    txn_datetime,
    amount,
    is_fraud,
    ROUND(rolling_avg, 2)                                     AS rolling_avg_30txn,
    ROUND(SQRT(rolling_variance), 2)                          AS rolling_stddev_30txn,
    ROUND((amount - rolling_avg) / NULLIF(SQRT(rolling_variance), 0), 2) AS z_score
FROM rolling_var
WHERE rolling_variance IS NOT NULL
  AND amount > rolling_avg + 3 * SQRT(rolling_variance)
ORDER BY z_score DESC;
