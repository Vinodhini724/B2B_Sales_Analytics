-- ============================================================
-- 09_advanced_analysis.sql
-- ADVANCED SALES INTELLIGENCE ANALYSIS
-- ============================================================


-- ============================================================
-- QUERY 1: Revenue Efficiency by Product
-- ============================================================

WITH product_metrics AS (

    SELECT
        sp.product,

        COUNT(*) AS total_opportunities,

        COUNT(*) FILTER (
            WHERE sp.deal_stage = 'Won'
        ) AS won_opportunities,

        COUNT(*) FILTER (
            WHERE sp.deal_stage IN ('Won', 'Lost')
        ) AS completed_opportunities,

        COALESCE(
            SUM(sp.close_value) FILTER (
                WHERE sp.deal_stage = 'Won'
            ),
            0
        ) AS won_revenue

    FROM sales_pipeline sp

    GROUP BY sp.product

)

SELECT
    product,
    total_opportunities,
    won_opportunities,

    ROUND(
        100.0 * won_opportunities /
        NULLIF(completed_opportunities, 0),
        2
    ) AS win_rate,

    won_revenue,

    ROUND(
        won_revenue /
        NULLIF(won_opportunities, 0),
        2
    ) AS average_won_deal,

    ROUND(
        won_revenue /
        NULLIF(total_opportunities, 0),
        2
    ) AS revenue_per_opportunity

FROM product_metrics

ORDER BY revenue_per_opportunity DESC;


-- ============================================================
-- QUERY 2: Revenue Efficiency by Region
-- ============================================================

SELECT
    st.regional_office AS region,

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
        COUNT(*) FILTER (
            WHERE sp.deal_stage = 'Won'
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE sp.deal_stage IN ('Won', 'Lost')
            ),
            0
        ),
        2
    ) AS win_rate,

    COALESCE(
        SUM(sp.close_value) FILTER (
            WHERE sp.deal_stage = 'Won'
        ),
        0
    ) AS won_revenue,

    ROUND(
        COALESCE(
            SUM(sp.close_value) FILTER (
                WHERE sp.deal_stage = 'Won'
            ),
            0
        )
        /
        NULLIF(COUNT(*), 0),
        2
    ) AS revenue_per_opportunity

FROM sales_pipeline sp

JOIN sales_teams st
    ON sp.sales_agent = st.sales_agent

GROUP BY st.regional_office

ORDER BY revenue_per_opportunity DESC;


-- ============================================================
-- QUERY 3: Salesperson Revenue Efficiency
-- ============================================================

SELECT
    st.sales_agent,
    st.regional_office,

    COUNT(*) AS total_opportunities,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Won'
    ) AS won_opportunities,

    COUNT(*) FILTER (
        WHERE sp.deal_stage IN ('Won', 'Lost')
    ) AS completed_opportunities,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE sp.deal_stage = 'Won'
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE sp.deal_stage IN ('Won', 'Lost')
            ),
            0
        ),
        2
    ) AS win_rate,

    COALESCE(
        SUM(sp.close_value) FILTER (
            WHERE sp.deal_stage = 'Won'
        ),
        0
    ) AS won_revenue,

    ROUND(
        COALESCE(
            SUM(sp.close_value) FILTER (
                WHERE sp.deal_stage = 'Won'
            ),
            0
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE sp.deal_stage = 'Won'
            ),
            0
        ),
        2
    ) AS average_won_deal,

    ROUND(
        COALESCE(
            SUM(sp.close_value) FILTER (
                WHERE sp.deal_stage = 'Won'
            ),
            0
        )
        /
        NULLIF(COUNT(*), 0),
        2
    ) AS revenue_per_opportunity

FROM sales_pipeline sp

JOIN sales_teams st
    ON sp.sales_agent = st.sales_agent

GROUP BY
    st.sales_agent,
    st.regional_office

HAVING COUNT(*) FILTER (
    WHERE sp.deal_stage IN ('Won', 'Lost')
) >= 30

ORDER BY revenue_per_opportunity DESC;


-- ============================================================
-- QUERY 4: High-Value Deal Performance
-- ============================================================

WITH overall_average AS (

    SELECT
        AVG(close_value) AS average_won_deal

    FROM sales_pipeline

    WHERE deal_stage = 'Won'

)

SELECT

    sp.product,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Won'
    ) AS won_opportunities,

    ROUND(
        AVG(sp.close_value) FILTER (
            WHERE sp.deal_stage = 'Won'
        ),
        2
    ) AS average_won_deal,

    ROUND(
        MAX(sp.close_value) FILTER (
            WHERE sp.deal_stage = 'Won'
        ),
        2
    ) AS maximum_won_deal,

    COUNT(*) FILTER (
        WHERE
            sp.deal_stage = 'Won'
            AND sp.close_value > oa.average_won_deal
    ) AS above_average_deals,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE
                sp.deal_stage = 'Won'
                AND sp.close_value > oa.average_won_deal
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE sp.deal_stage = 'Won'
            ),
            0
        ),
        2
    ) AS percentage_above_average

FROM sales_pipeline sp

CROSS JOIN overall_average oa

GROUP BY sp.product

ORDER BY average_won_deal DESC;


-- ============================================================
-- QUERY 5: Product-Region Opportunity
-- ============================================================

SELECT

    st.regional_office AS region,

    sp.product,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Won'
    ) AS won_opportunities,

    COUNT(*) FILTER (
        WHERE sp.deal_stage IN ('Won', 'Lost')
    ) AS completed_opportunities,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE sp.deal_stage = 'Won'
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE sp.deal_stage IN ('Won', 'Lost')
            ),
            0
        ),
        2
    ) AS win_rate,

    COALESCE(
        SUM(sp.close_value) FILTER (
            WHERE sp.deal_stage = 'Won'
        ),
        0
    ) AS won_revenue,

    ROUND(
        AVG(sp.close_value) FILTER (
            WHERE sp.deal_stage = 'Won'
        ),
        2
    ) AS average_won_deal

FROM sales_pipeline sp

JOIN sales_teams st
    ON sp.sales_agent = st.sales_agent

GROUP BY
    st.regional_office,
    sp.product

HAVING COUNT(*) FILTER (
    WHERE sp.deal_stage IN ('Won', 'Lost')
) >= 20

ORDER BY won_revenue DESC;


-- ============================================================
-- QUERY 6: Sales Cycle vs Revenue
-- ============================================================

WITH sales_cycle_data AS (

    SELECT

        CASE
            WHEN sp.close_date - sp.engage_date <= 30
                THEN '0-30 Days'

            WHEN sp.close_date - sp.engage_date <= 60
                THEN '31-60 Days'

            WHEN sp.close_date - sp.engage_date <= 90
                THEN '61-90 Days'

            ELSE '90+ Days'

        END AS sales_cycle_bucket,

        sp.close_value

    FROM sales_pipeline sp

    WHERE
        sp.deal_stage = 'Won'
        AND sp.engage_date IS NOT NULL
        AND sp.close_date IS NOT NULL

),

cycle_summary AS (

    SELECT

        sales_cycle_bucket,

        COUNT(*) AS won_opportunities,

        ROUND(
            AVG(close_value),
            2
        ) AS average_deal_value,

        ROUND(
            SUM(close_value),
            2
        ) AS total_revenue

    FROM sales_cycle_data

    GROUP BY sales_cycle_bucket

)

SELECT

    sales_cycle_bucket,
    won_opportunities,
    average_deal_value,
    total_revenue

FROM cycle_summary

ORDER BY

    CASE
        WHEN sales_cycle_bucket = '0-30 Days' THEN 1
        WHEN sales_cycle_bucket = '31-60 Days' THEN 2
        WHEN sales_cycle_bucket = '61-90 Days' THEN 3
        WHEN sales_cycle_bucket = '90+ Days' THEN 4
    END;


-- ============================================================
-- QUERY 7: Account Revenue Opportunity Score
-- ============================================================

WITH account_metrics AS (

    SELECT

        sp.account,

        COUNT(*) FILTER (
            WHERE sp.deal_stage = 'Won'
        ) AS won_opportunities,

        COUNT(*) FILTER (
            WHERE sp.deal_stage IN ('Prospecting', 'Engaging')
        ) AS open_opportunities,

        COUNT(*) FILTER (
            WHERE sp.deal_stage IN ('Won', 'Lost')
        ) AS completed_opportunities,

        COALESCE(
            SUM(sp.close_value) FILTER (
                WHERE sp.deal_stage = 'Won'
            ),
            0
        ) AS historical_revenue

    FROM sales_pipeline sp

    WHERE sp.account IS NOT NULL

    GROUP BY sp.account

),

scored_accounts AS (

    SELECT

        account,
        won_opportunities,
        open_opportunities,
        historical_revenue,

        ROUND(
            100.0 * won_opportunities /
            NULLIF(completed_opportunities, 0),
            2
        ) AS win_rate,

        CASE

            WHEN
                open_opportunities >= 10
                AND won_opportunities >= 50
                THEN 'High Priority'

            WHEN
                open_opportunities >= 5
                AND won_opportunities >= 25
                THEN 'Growth Opportunity'

            ELSE 'Monitor'

        END AS account_priority

    FROM account_metrics

    WHERE completed_opportunities >= 10

)

SELECT

    account,
    won_opportunities,
    open_opportunities,
    historical_revenue,
    win_rate,
    account_priority

FROM scored_accounts

ORDER BY

    CASE
        WHEN account_priority = 'High Priority' THEN 1
        WHEN account_priority = 'Growth Opportunity' THEN 2
        ELSE 3
    END,

    historical_revenue DESC;


-- ============================================================
-- QUERY 8: Salesperson Workload vs Historical Performance
-- ============================================================

SELECT

    st.sales_agent,

    st.regional_office,

    COUNT(*) FILTER (
        WHERE sp.deal_stage IN ('Prospecting', 'Engaging')
    ) AS open_opportunities,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Won'
    ) AS won_opportunities,

    COALESCE(
        SUM(sp.close_value) FILTER (
            WHERE sp.deal_stage = 'Won'
        ),
        0
    ) AS historical_revenue,

    ROUND(
        COALESCE(
            SUM(sp.close_value) FILTER (
                WHERE sp.deal_stage = 'Won'
            ),
            0
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE sp.deal_stage = 'Won'
            ),
            0
        ),
        2
    ) AS average_won_deal,

    CASE

        WHEN COUNT(*) FILTER (
            WHERE sp.deal_stage IN ('Prospecting', 'Engaging')
        ) >= 100
            THEN 'Very High Workload'

        WHEN COUNT(*) FILTER (
            WHERE sp.deal_stage IN ('Prospecting', 'Engaging')
        ) >= 70
            THEN 'High Workload'

        WHEN COUNT(*) FILTER (
            WHERE sp.deal_stage IN ('Prospecting', 'Engaging')
        ) >= 40
            THEN 'Moderate Workload'

        ELSE 'Low Workload'

    END AS workload_category

FROM sales_pipeline sp

JOIN sales_teams st
    ON sp.sales_agent = st.sales_agent

GROUP BY
    st.sales_agent,
    st.regional_office

HAVING COUNT(*) FILTER (
    WHERE sp.deal_stage IN ('Prospecting', 'Engaging')
) > 0

ORDER BY open_opportunities DESC;


-- ============================================================
-- QUERY 9: Opportunity Conversion Funnel
-- ============================================================

SELECT

    COUNT(*) AS total_opportunities,

    COUNT(*) FILTER (
        WHERE deal_stage = 'Prospecting'
    ) AS prospecting,

    COUNT(*) FILTER (
        WHERE deal_stage = 'Engaging'
    ) AS engaging,

    COUNT(*) FILTER (
        WHERE deal_stage = 'Won'
    ) AS won,

    COUNT(*) FILTER (
        WHERE deal_stage = 'Lost'
    ) AS lost,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE deal_stage = 'Won'
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE deal_stage IN ('Won', 'Lost')
            ),
            0
        ),
        2
    ) AS completed_win_rate,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE deal_stage = 'Won'
        )
        /
        NULLIF(COUNT(*), 0),
        2
    ) AS overall_win_conversion

FROM sales_pipeline;


-- ============================================================
-- QUERY 10: Executive Sales Intelligence Summary
-- ============================================================

WITH metrics AS (

    SELECT

        COUNT(*) AS total_opportunities,

        COUNT(*) FILTER (
            WHERE deal_stage = 'Won'
        ) AS won_opportunities,

        COUNT(*) FILTER (
            WHERE deal_stage = 'Lost'
        ) AS lost_opportunities,

        COUNT(*) FILTER (
            WHERE deal_stage IN ('Prospecting', 'Engaging')
        ) AS open_opportunities,

        COUNT(*) FILTER (
            WHERE deal_stage = 'Engaging'
        ) AS engaging_opportunities,

        COALESCE(
            SUM(close_value) FILTER (
                WHERE deal_stage = 'Won'
            ),
            0
        ) AS total_won_revenue,

        AVG(close_value) FILTER (
            WHERE deal_stage = 'Won'
        ) AS average_won_deal,

        AVG(
            close_date - engage_date
        ) FILTER (
            WHERE
                deal_stage = 'Won'
                AND engage_date IS NOT NULL
                AND close_date IS NOT NULL
        ) AS average_sales_cycle

    FROM sales_pipeline

),

final_metrics AS (

    SELECT

        total_opportunities,
        won_opportunities,
        lost_opportunities,
        open_opportunities,
        engaging_opportunities,
        total_won_revenue,
        average_won_deal,
        average_sales_cycle,

        ROUND(
            100.0 *
            open_opportunities /
            NULLIF(total_opportunities, 0),
            2
        ) AS open_pipeline_percentage,

        ROUND(
            100.0 *
            won_opportunities /
            NULLIF(
                won_opportunities + lost_opportunities,
                0
            ),
            2
        ) AS win_rate,

        ROUND(
            100.0 *
            engaging_opportunities /
            NULLIF(open_opportunities, 0),
            2
        ) AS engaging_share_of_open_pipeline

    FROM metrics

)

SELECT

    total_opportunities,
    won_opportunities,
    lost_opportunities,
    open_opportunities,

    open_pipeline_percentage,

    win_rate,

    ROUND(
        total_won_revenue,
        2
    ) AS total_won_revenue,

    ROUND(
        average_won_deal,
        2
    ) AS average_won_deal,

    ROUND(
        average_sales_cycle,
        2
    ) AS average_sales_cycle_days,

    engaging_share_of_open_pipeline

FROM final_metrics;