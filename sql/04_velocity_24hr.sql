-- 04_velocity_24hr.sql
--
-- Question: Using a window function, compute each card's transaction
-- count in the trailing 24 hours (a velocity check).
--
-- Why it matters: velocity is the single strongest fraud-ring / stolen-card
-- signal in the whole project; queries 5, 8, and 9 all build on this idea.
--
-- Approach: for every transaction, count how many transactions on the
-- same card fall within the 24 hours ending at that transaction
-- (inclusive), using a self-join keyed on the card's transaction stream.
-- (SQLite has no RANGE-based time window frame, so this is expressed as
-- a correlated count rather than a native RANGE window — on Postgres this
-- can be written as a single window function with
-- RANGE BETWEEN INTERVAL '24 hours' PRECEDING AND CURRENT ROW.)

SELECT
    t.card_id,
    t.txn_datetime,
    t.amount,
    t.is_fraud,
    (
        SELECT COUNT(*)
        FROM transactions t2
        WHERE t2.card_id = t.card_id
          AND t2.txn_datetime <= t.txn_datetime
          AND t2.txn_datetime > datetime(t.txn_datetime, '-24 hours')
    ) AS txn_count_trailing_24hr
FROM transactions t
ORDER BY t.card_id, t.txn_datetime;

-- Postgres equivalent (native RANGE window, no self-join needed):
-- SELECT
--     card_id, txn_datetime, amount, is_fraud,
--     COUNT(*) OVER (
--         PARTITION BY card_id
--         ORDER BY txn_datetime
--         RANGE BETWEEN INTERVAL '24 hours' PRECEDING AND CURRENT ROW
--     ) AS txn_count_trailing_24hr
-- FROM transactions;
