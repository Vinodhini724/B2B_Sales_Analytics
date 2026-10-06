-- ============================================================
-- 06 CUSTOMER / ACCOUNT ANALYSIS
-- ============================================================


-- ============================================================
-- QUERY 1: Account-level sales performance
-- ============================================================

SELECT
    a.account,
    a.sector,
    a.office_location,
    COUNT(*) FILTER (WHERE sp.deal_stage = 'Won') AS won_opportunities,
    COUNT(*) FILTER (WHERE sp.deal_stage = 'Lost') AS lost_opportunities,
    COUNT(*) AS total_opportunities,

    ROUND(
        100.0 *
        COUNT(*) FILTER (WHERE sp.deal_stage = 'Won')
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE sp.deal_stage IN ('Won', 'Lost')
            ), 0
        ),
        2
    ) AS win_rate_percent,

    COALESCE(
        SUM(sp.close_value)
        FILTER (WHERE sp.deal_stage = 'Won'),
        0
    ) AS won_revenue,

    ROUND(
        AVG(sp.close_value)
        FILTER (WHERE sp.deal_stage = 'Won'),
        2
    ) AS average_won_deal

FROM accounts a
LEFT JOIN sales_pipeline sp
    ON a.account = sp.account

GROUP BY
    a.account,
    a.sector,
    a.office_location

ORDER BY won_revenue DESC;


-- ============================================================
-- QUERY 2: Top 20 accounts by won revenue
-- ============================================================

SELECT
    a.account,
    a.sector,
    a.office_location,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Won'
    ) AS won_opportunities,

    COALESCE(
        SUM(sp.close_value)
        FILTER (WHERE sp.deal_stage = 'Won'),
        0
    ) AS won_revenue,

    ROUND(
        AVG(sp.close_value)
        FILTER (WHERE sp.deal_stage = 'Won'),
        2
    ) AS average_deal_value

FROM accounts a
JOIN sales_pipeline sp
    ON a.account = sp.account

GROUP BY
    a.account,
    a.sector,
    a.office_location

HAVING COUNT(*) FILTER (
    WHERE sp.deal_stage = 'Won'
) > 0

ORDER BY won_revenue DESC

LIMIT 20;


-- ============================================================
-- QUERY 3: Account opportunity funnel
-- ============================================================

SELECT
    a.account,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Prospecting'
    ) AS prospecting_opportunities,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Engaging'
    ) AS engaging_opportunities,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Won'
    ) AS won_opportunities,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Lost'
    ) AS lost_opportunities,

    COUNT(*) AS total_opportunities

FROM accounts a
LEFT JOIN sales_pipeline sp
    ON a.account = sp.account

GROUP BY a.account

ORDER BY total_opportunities DESC;


-- ============================================================
-- QUERY 4: Sector performance
-- ============================================================

SELECT
    a.sector,

    COUNT(*) AS total_opportunities,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Won'
    ) AS won_opportunities,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Lost'
    ) AS lost_opportunities,

    COUNT(*) FILTER (
        WHERE sp.deal_stage IN ('Prospecting', 'Engaging')
    ) AS open_opportunities,

    ROUND(
        100.0 *
        COUNT(*) FILTER (WHERE sp.deal_stage = 'Won')
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE sp.deal_stage IN ('Won', 'Lost')
            ), 0
        ),
        2
    ) AS win_rate_percent,

    COALESCE(
        SUM(sp.close_value)
        FILTER (WHERE sp.deal_stage = 'Won'),
        0
    ) AS won_revenue,

    ROUND(
        AVG(sp.close_value)
        FILTER (WHERE sp.deal_stage = 'Won'),
        2
    ) AS average_won_deal

FROM accounts a
JOIN sales_pipeline sp
    ON a.account = sp.account

GROUP BY a.sector

ORDER BY won_revenue DESC;


-- ============================================================
-- QUERY 5: Geographic performance
-- ============================================================

SELECT
    a.office_location,

    COUNT(*) AS total_opportunities,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Won'
    ) AS won_opportunities,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Lost'
    ) AS lost_opportunities,

    ROUND(
        100.0 *
        COUNT(*) FILTER (WHERE sp.deal_stage = 'Won')
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE sp.deal_stage IN ('Won', 'Lost')
            ), 0
        ),
        2
    ) AS win_rate_percent,

    COALESCE(
        SUM(sp.close_value)
        FILTER (WHERE sp.deal_stage = 'Won'),
        0
    ) AS won_revenue

FROM accounts a
JOIN sales_pipeline sp
    ON a.account = sp.account

GROUP BY a.office_location

ORDER BY won_revenue DESC;


-- ============================================================
-- QUERY 6: Account size vs revenue performance
-- ============================================================

SELECT
    CASE
        WHEN a.employees < 1000 THEN 'Small'
        WHEN a.employees < 5000 THEN 'Medium'
        ELSE 'Large'
    END AS account_size,

    COUNT(DISTINCT a.account) AS account_count,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Won'
    ) AS won_opportunities,

    COALESCE(
        SUM(sp.close_value)
        FILTER (WHERE sp.deal_stage = 'Won'),
        0
    ) AS won_revenue,

    ROUND(
        AVG(sp.close_value)
        FILTER (WHERE sp.deal_stage = 'Won'),
        2
    ) AS average_won_deal

FROM accounts a
JOIN sales_pipeline sp
    ON a.account = sp.account

GROUP BY
    CASE
        WHEN a.employees < 1000 THEN 'Small'
        WHEN a.employees < 5000 THEN 'Medium'
        ELSE 'Large'
    END

ORDER BY won_revenue DESC;


-- ============================================================
-- QUERY 7: Account revenue potential vs sales performance
-- ============================================================

SELECT
    a.account,
    a.sector,
    a.revenue AS account_revenue,
    a.employees,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Won'
    ) AS won_opportunities,

    COALESCE(
        SUM(sp.close_value)
        FILTER (WHERE sp.deal_stage = 'Won'),
        0
    ) AS won_revenue,

    ROUND(
        100.0 *
        COUNT(*) FILTER (WHERE sp.deal_stage = 'Won')
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE sp.deal_stage IN ('Won', 'Lost')
            ), 0
        ),
        2
    ) AS win_rate_percent

FROM accounts a
JOIN sales_pipeline sp
    ON a.account = sp.account

GROUP BY
    a.account,
    a.sector,
    a.revenue,
    a.employees

ORDER BY a.revenue DESC

LIMIT 20;


-- ============================================================
-- QUERY 8: Accounts with largest open opportunity volume
-- ============================================================

SELECT
    a.account,
    a.sector,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Prospecting'
    ) AS prospecting_opportunities,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Engaging'
    ) AS engaging_opportunities,

    COUNT(*) FILTER (
        WHERE sp.deal_stage IN ('Prospecting', 'Engaging')
    ) AS open_opportunities,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Won'
    ) AS won_opportunities,

    COALESCE(
        SUM(sp.close_value)
        FILTER (WHERE sp.deal_stage = 'Won'),
        0
    ) AS historical_won_revenue

FROM accounts a
JOIN sales_pipeline sp
    ON a.account = sp.account

GROUP BY
    a.account,
    a.sector

HAVING COUNT(*) FILTER (
    WHERE sp.deal_stage IN ('Prospecting', 'Engaging')
) > 0

ORDER BY open_opportunities DESC

LIMIT 20;


-- ============================================================
-- QUERY 9: Customer concentration
-- ============================================================

WITH account_revenue AS (
    SELECT
        a.account,
        COALESCE(
            SUM(sp.close_value)
            FILTER (WHERE sp.deal_stage = 'Won'),
            0
        ) AS won_revenue
    FROM accounts a
    LEFT JOIN sales_pipeline sp
        ON a.account = sp.account
    GROUP BY a.account
),

ranked_accounts AS (
    SELECT
        account,
        won_revenue,
        RANK() OVER (
            ORDER BY won_revenue DESC
        ) AS revenue_rank
    FROM account_revenue
)

SELECT
    CASE
        WHEN revenue_rank <= 5 THEN 'Top 5 Accounts'
        WHEN revenue_rank <= 10 THEN 'Top 6-10 Accounts'
        ELSE 'Remaining Accounts'
    END AS account_group,

    COUNT(*) AS account_count,

    SUM(won_revenue) AS won_revenue,

    ROUND(
        100.0 * SUM(won_revenue)
        /
        NULLIF(
            (SELECT SUM(won_revenue)
             FROM account_revenue),
            0
        ),
        2
    ) AS revenue_contribution_percent

FROM ranked_accounts

GROUP BY
    CASE
        WHEN revenue_rank <= 5 THEN 'Top 5 Accounts'
        WHEN revenue_rank <= 10 THEN 'Top 6-10 Accounts'
        ELSE 'Remaining Accounts'
    END

ORDER BY won_revenue DESC;


-- ============================================================
-- QUERY 10: Accounts with unusually high win rates
-- ============================================================

SELECT
    a.account,
    a.sector,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Won'
    ) AS won_opportunities,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Lost'
    ) AS lost_opportunities,

    ROUND(
        100.0 *
        COUNT(*) FILTER (WHERE sp.deal_stage = 'Won')
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE sp.deal_stage IN ('Won', 'Lost')
            ), 0
        ),
        2
    ) AS win_rate_percent,

    COALESCE(
        SUM(sp.close_value)
        FILTER (WHERE sp.deal_stage = 'Won'),
        0
    ) AS won_revenue

FROM accounts a
JOIN sales_pipeline sp
    ON a.account = sp.account

GROUP BY
    a.account,
    a.sector

HAVING COUNT(*) FILTER (
    WHERE sp.deal_stage IN ('Won', 'Lost')
) >= 10

ORDER BY win_rate_percent DESC

LIMIT 20;