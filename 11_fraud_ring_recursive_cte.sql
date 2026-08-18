-- 11_fraud_ring_recursive_cte.sql
--
-- Question: Fraud ring detection using a recursive CTE -- find chains of
-- cards transacting at the same merchant within a short time window, a
-- pattern consistent with a coordinated fraud ring rather than an
-- isolated incident.
--
-- Why it matters: an isolated fraud flag on one card is noise; the same
-- merchant getting hit by several different cards within a tight window
-- is a materially different (and often bigger) problem worth escalating
-- differently.

WITH RECURSIVE fraud_chain AS (
    -- Anchor: every confirmed-fraud transaction starts its own chain
    SELECT
        card_id,
        merchant_id,
        txn_datetime,
        1 AS chain_length
    FROM transactions
    WHERE is_fraud = 1

    UNION ALL

    -- Recursive step: extend the chain with any other card hitting the
    -- same merchant within 1 hour of the current chain's timestamp
    SELECT
        t.card_id,
        t.merchant_id,
        t.txn_datetime,
        fc.chain_length + 1
    FROM transactions t
    JOIN fraud_chain fc
      ON t.merchant_id = fc.merchant_id
     AND t.txn_datetime BETWEEN fc.txn_datetime AND datetime(fc.txn_datetime, '+1 hour')
     AND t.card_id != fc.card_id                 -- must be a *different* card to count as a ring
    WHERE fc.chain_length < 10                    -- guard against runaway recursion
)
SELECT
    merchant_id,
    MAX(chain_length)              AS ring_size,
    COUNT(DISTINCT card_id)        AS distinct_cards_involved
FROM fraud_chain
GROUP BY merchant_id
HAVING MAX(chain_length) >= 3
ORDER BY ring_size DESC;
