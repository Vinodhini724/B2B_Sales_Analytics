-- ============================================================
-- 07 SALES TEAM ANALYSIS
-- ============================================================


-- ============================================================
-- QUERY 1: Salesperson performance scorecard
-- ============================================================

SELECT
    st.sales_agent,
    st.manager,
    st.regional_office,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Won'
    ) AS won_opportunities,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Lost'
    ) AS lost_opportunities,

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

FROM sales_teams st
LEFT JOIN sales_pipeline sp
    ON st.sales_agent = sp.sales_agent

GROUP BY
    st.sales_agent,
    st.manager,
    st.regional_office

ORDER BY won_revenue DESC;


-- ============================================================
-- QUERY 2: Salesperson revenue ranking
-- ============================================================

SELECT
    st.sales_agent,
    st.manager,
    st.regional_office,

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
    ) AS average_won_deal,

    RANK() OVER (
        ORDER BY
            COALESCE(
                SUM(sp.close_value)
                FILTER (WHERE sp.deal_stage = 'Won'),
                0
            ) DESC
    ) AS revenue_rank

FROM sales_teams st
LEFT JOIN sales_pipeline sp
    ON st.sales_agent = sp.sales_agent

GROUP BY
    st.sales_agent,
    st.manager,
    st.regional_office

ORDER BY revenue_rank;


-- ============================================================
-- QUERY 3: Salesperson win-rate ranking
-- ============================================================

SELECT
    st.sales_agent,
    st.manager,
    st.regional_office,

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
    ) AS win_rate_percent

FROM sales_teams st
JOIN sales_pipeline sp
    ON st.sales_agent = sp.sales_agent

GROUP BY
    st.sales_agent,
    st.manager,
    st.regional_office

HAVING COUNT(*) FILTER (
    WHERE sp.deal_stage IN ('Won', 'Lost')
) >= 30

ORDER BY win_rate_percent DESC;

-- ============================================================
-- QUERY 4: Salesperson Sales Cycle
-- ============================================================

SELECT
    st.sales_agent,
    st.manager,
    st.regional_office,

    COUNT(*) AS completed_deals,

    ROUND(
        AVG(
            (sp.close_date - sp.engage_date)::NUMERIC
        ),
        2
    ) AS average_sales_cycle_days,

    PERCENTILE_CONT(0.5)
    WITHIN GROUP (
        ORDER BY (sp.close_date - sp.engage_date)
    ) AS median_sales_cycle_days

FROM sales_teams st
JOIN sales_pipeline sp
    ON st.sales_agent = sp.sales_agent

WHERE
    sp.engage_date IS NOT NULL
    AND sp.close_date IS NOT NULL

GROUP BY
    st.sales_agent,
    st.manager,
    st.regional_office

ORDER BY average_sales_cycle_days;

-- ============================================================
-- QUERY 5: Manager performance
-- ============================================================

SELECT
    st.manager,

    COUNT(DISTINCT st.sales_agent) AS sales_agents,

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
    ) AS won_revenue,

    ROUND(
        AVG(sp.close_value)
        FILTER (WHERE sp.deal_stage = 'Won'),
        2
    ) AS average_won_deal

FROM sales_teams st
JOIN sales_pipeline sp
    ON st.sales_agent = sp.sales_agent

GROUP BY st.manager

ORDER BY won_revenue DESC;


-- ============================================================
-- QUERY 6: Regional sales-team performance
-- ============================================================

SELECT
    st.regional_office,

    COUNT(DISTINCT st.sales_agent) AS sales_agents,

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

FROM sales_teams st
JOIN sales_pipeline sp
    ON st.sales_agent = sp.sales_agent

GROUP BY st.regional_office

ORDER BY won_revenue DESC;


-- ============================================================
-- QUERY 7: Salesperson product specialization
-- ============================================================

SELECT
    st.sales_agent,
    sp.product,

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

FROM sales_teams st
JOIN sales_pipeline sp
    ON st.sales_agent = sp.sales_agent

GROUP BY
    st.sales_agent,
    sp.product

HAVING COUNT(*) FILTER (
    WHERE sp.deal_stage IN ('Won', 'Lost')
) >= 10

ORDER BY
    st.sales_agent,
    won_revenue DESC;


-- ============================================================
-- QUERY 8: High-performing salespeople
-- ============================================================

SELECT
    st.sales_agent,
    st.manager,
    st.regional_office,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Won'
    ) AS won_opportunities,

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

FROM sales_teams st
JOIN sales_pipeline sp
    ON st.sales_agent = sp.sales_agent

GROUP BY
    st.sales_agent,
    st.manager,
    st.regional_office

HAVING
    COUNT(*) FILTER (
        WHERE sp.deal_stage IN ('Won', 'Lost')
    ) >= 30

    AND
    100.0 *
    COUNT(*) FILTER (WHERE sp.deal_stage = 'Won')
    /
    NULLIF(
        COUNT(*) FILTER (
            WHERE sp.deal_stage IN ('Won', 'Lost')
        ), 0
    ) >= 65

ORDER BY won_revenue DESC;


-- ============================================================
-- QUERY 9: Salespeople with largest open workload
-- ============================================================

SELECT
    st.sales_agent,
    st.manager,
    st.regional_office,

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

FROM sales_teams st
JOIN sales_pipeline sp
    ON st.sales_agent = sp.sales_agent

GROUP BY
    st.sales_agent,
    st.manager,
    st.regional_office

HAVING COUNT(*) FILTER (
    WHERE sp.deal_stage IN ('Prospecting', 'Engaging')
) > 0

ORDER BY open_opportunities DESC;


-- ============================================================
-- QUERY 10: Salesperson performance classification
-- ============================================================

WITH salesperson_metrics AS (

    SELECT
        st.sales_agent,
        st.manager,
        st.regional_office,

        COUNT(*) FILTER (
            WHERE sp.deal_stage = 'Won'
        ) AS won_opportunities,

        COUNT(*) FILTER (
            WHERE sp.deal_stage IN ('Won', 'Lost')
        ) AS completed_opportunities,

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

    FROM sales_teams st
    JOIN sales_pipeline sp
        ON st.sales_agent = sp.sales_agent

    GROUP BY
        st.sales_agent,
        st.manager,
        st.regional_office
)

SELECT
    sales_agent,
    manager,
    regional_office,
    won_opportunities,
    completed_opportunities,
    win_rate_percent,
    won_revenue,

    CASE
        WHEN won_revenue >= 400000
             AND win_rate_percent >= 65
            THEN 'Top Performer'

        WHEN won_revenue >= 250000
             OR win_rate_percent >= 65
            THEN 'Strong Performer'

        WHEN win_rate_percent < 55
            THEN 'Needs Improvement'

        ELSE 'Developing'
    END AS performance_category

FROM salesperson_metrics

ORDER BY won_revenue DESC;