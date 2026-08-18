-- 12_dynamic_percentile_threshold.sql
--
-- Question: Dynamic, per-card thresholds using PERCENTILE_CONT -- flag a
-- transaction if it exceeds that specific card's own 95th-percentile
-- historical spend, instead of applying one static dollar threshold to
-- every card regardless of that customer's normal spending behavior.
--
-- Why it matters: a $500 charge is unremarkable for a card that
-- routinely spends $400-600, but highly anomalous for a card that never
-- exceeds $50 -- a single fixed threshold cannot capture this.
--
-- Portability note: PostgreSQL supports PERCENTILE_CONT natively (shown
-- below). SQLite has no percentile function, so the SQLite version
-- approximates it with a windowed cumulative-distribution calculation.

-- ---- PostgreSQL (native) ----
-- WITH card_p95 AS (
--     SELECT
--         card_id,
--         PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY amount) AS p95_amount
--     FROM transactions
--     WHERE is_refund_or_reversal = 0
--     GROUP BY card_id
-- )
-- SELECT t.*, cp.p95_amount
-- FROM transactions t
-- JOIN card_p95 cp ON cp.card_id = t.card_id
-- WHERE t.amount > cp.p95_amount;

-- ---- SQLite (percentile approximated via cumulative distribution) ----
WITH ranked AS (
    SELECT
        card_id,
        amount,
        PERCENT_RANK() OVER (PARTITION BY card_id ORDER BY amount) AS pct_rank
    FROM transactions
    WHERE is_refund_or_reversal = 0
),
card_p95 AS (
    -- smallest amount whose cumulative percent rank is >= 0.95, per card
    SELECT card_id, MIN(amount) AS p95_amount
    FROM ranked
    WHERE pct_rank >= 0.95
    GROUP BY card_id
)
SELECT
    t.card_id,
    t.txn_datetime,
    t.amount,
    t.is_fraud,
    cp.p95_amount AS card_p95_threshold
FROM transactions t
JOIN card_p95 cp ON cp.card_id = t.card_id
WHERE t.amount > cp.p95_amount
ORDER BY t.card_id, t.txn_datetime;
