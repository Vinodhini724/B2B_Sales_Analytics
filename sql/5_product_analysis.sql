-- ============================================================
-- 05_product_analysis.sql
-- Product-Level Sales Intelligence
-- ============================================================


-- ============================================================
-- Query 1: Product Performance Scorecard
-- ============================================================

SELECT
    p.product,
    p.series,
    p.sales_price,

    COUNT(sp.opportunity_id) AS total_opportunities,

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
        / NULLIF(
            COUNT(*) FILTER (
                WHERE sp.deal_stage IN ('Won', 'Lost')
            ),
            0
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

FROM products p

LEFT JOIN sales_pipeline sp
    ON sp.product = p.product

GROUP BY
    p.product,
    p.series,
    p.sales_price

ORDER BY won_revenue DESC;


-- ============================================================
-- Query 2: Product Revenue Ranking
-- ============================================================

SELECT
    product,
    SUM(close_value) AS won_revenue,

    RANK() OVER (
        ORDER BY SUM(close_value) DESC
    ) AS revenue_rank,

    ROUND(
        100.0 * SUM(close_value)
        / SUM(SUM(close_value)) OVER (),
        2
    ) AS revenue_contribution_percent

FROM sales_pipeline

WHERE deal_stage = 'Won'

GROUP BY product

ORDER BY revenue_rank;


-- ============================================================
-- Query 3: Product Win-Rate Ranking
-- ============================================================

SELECT
    product,

    COUNT(*) FILTER (
        WHERE deal_stage = 'Won'
    ) AS won_opportunities,

    COUNT(*) FILTER (
        WHERE deal_stage = 'Lost'
    ) AS lost_opportunities,

    ROUND(
        100.0 *
        COUNT(*) FILTER (WHERE deal_stage = 'Won')
        / NULLIF(
            COUNT(*) FILTER (
                WHERE deal_stage IN ('Won', 'Lost')
            ),
            0
        ),
        2
    ) AS win_rate_percent,

    RANK() OVER (
        ORDER BY
            COUNT(*) FILTER (WHERE deal_stage = 'Won')::NUMERIC
            /
            NULLIF(
                COUNT(*) FILTER (
                    WHERE deal_stage IN ('Won', 'Lost')
                ),
                0
            ) DESC
    ) AS win_rate_rank

FROM sales_pipeline

GROUP BY product

ORDER BY win_rate_rank;


-- ============================================================
-- Query 4: Product Opportunity Funnel
-- ============================================================

SELECT
    product,

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

    COUNT(*) AS total_opportunities

FROM sales_pipeline

GROUP BY product

ORDER BY total_opportunities DESC;


-- ============================================================
-- Query 5: Product Performance by Region
-- ============================================================

SELECT
    st.regional_office,
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
        / NULLIF(
            COUNT(*) FILTER (
                WHERE sp.deal_stage IN ('Won', 'Lost')
            ),
            0
        ),
        2
    ) AS win_rate_percent,

    COALESCE(
        SUM(sp.close_value)
        FILTER (WHERE sp.deal_stage = 'Won'),
        0
    ) AS won_revenue

FROM sales_pipeline sp

JOIN sales_teams st
    ON sp.sales_agent = st.sales_agent

GROUP BY
    st.regional_office,
    sp.product

ORDER BY
    st.regional_office,
    won_revenue DESC;


-- ============================================================
-- Query 6: Product Performance by Sales Agent
-- ============================================================

SELECT
    sp.product,
    st.sales_agent,
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
        / NULLIF(
            COUNT(*) FILTER (
                WHERE sp.deal_stage IN ('Won', 'Lost')
            ),
            0
        ),
        2
    ) AS win_rate_percent,

    COALESCE(
        SUM(sp.close_value)
        FILTER (WHERE sp.deal_stage = 'Won'),
        0
    ) AS won_revenue

FROM sales_pipeline sp

JOIN sales_teams st
    ON sp.sales_agent = st.sales_agent

GROUP BY
    sp.product,
    st.sales_agent,
    st.regional_office

HAVING COUNT(*) FILTER (
    WHERE sp.deal_stage IN ('Won', 'Lost')
) > 10

ORDER BY
    sp.product,
    won_revenue DESC;


-- ============================================================
-- Query 7: Product Sales Cycle
-- ============================================================

SELECT
    product,

    COUNT(*) AS completed_deals,

    ROUND(
        AVG(close_date - engage_date),
        2
    ) AS average_sales_cycle_days,

    PERCENTILE_CONT(0.5)
        WITHIN GROUP (
            ORDER BY close_date - engage_date
        ) AS median_sales_cycle_days,

    MIN(close_date - engage_date)
        AS fastest_deal_days,

    MAX(close_date - engage_date)
        AS slowest_deal_days

FROM sales_pipeline

WHERE engage_date IS NOT NULL
  AND close_date IS NOT NULL

GROUP BY product

ORDER BY average_sales_cycle_days;


-- ============================================================
-- Query 8: Product Revenue vs Volume
-- ============================================================

SELECT
    product,

    COUNT(*) FILTER (
        WHERE deal_stage = 'Won'
    ) AS won_deals,

    SUM(close_value) FILTER (
        WHERE deal_stage = 'Won'
    ) AS won_revenue,

    ROUND(
        AVG(close_value)
        FILTER (WHERE deal_stage = 'Won'),
        2
    ) AS average_deal_value,

    ROUND(
        100.0 *
        COUNT(*) FILTER (WHERE deal_stage = 'Won')
        / SUM(
            COUNT(*) FILTER (WHERE deal_stage = 'Won')
        ) OVER (),
        2
    ) AS volume_contribution_percent,

    ROUND(
        100.0 *
        SUM(close_value) FILTER (WHERE deal_stage = 'Won')
        / SUM(
            SUM(close_value) FILTER (WHERE deal_stage = 'Won')
        ) OVER (),
        2
    ) AS revenue_contribution_percent

FROM sales_pipeline

GROUP BY product

ORDER BY won_revenue DESC;


-- ============================================================
-- Query 9: Product Pricing vs Actual Average Deal
-- ============================================================

SELECT
    p.product,
    p.series,
    p.sales_price,

    ROUND(
        AVG(sp.close_value)
        FILTER (WHERE sp.deal_stage = 'Won'),
        2
    ) AS average_won_deal,

    ROUND(
        AVG(sp.close_value)
        FILTER (WHERE sp.deal_stage = 'Won')
        - p.sales_price,
        2
    ) AS average_difference_from_list_price

FROM products p

LEFT JOIN sales_pipeline sp
    ON sp.product = p.product

GROUP BY
    p.product,
    p.series,
    p.sales_price

ORDER BY average_won_deal DESC;


-- ============================================================
-- Query 10: High-Value Product Deals
-- ============================================================

SELECT
    product,

    COUNT(*) FILTER (
        WHERE deal_stage = 'Won'
        AND close_value >= 5000
    ) AS high_value_won_deals,

    COUNT(*) FILTER (
        WHERE deal_stage = 'Won'
    ) AS total_won_deals,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE deal_stage = 'Won'
            AND close_value >= 5000
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE deal_stage = 'Won'
            ),
            0
        ),
        2
    ) AS high_value_deal_percentage,

    MAX(close_value) FILTER (
        WHERE deal_stage = 'Won'
    ) AS maximum_won_deal

FROM sales_pipeline

GROUP BY product

ORDER BY high_value_won_deals DESC;


-- ============================================================
-- Query 11: Open Pipeline by Product
-- ============================================================

SELECT
    product,

    COUNT(*) FILTER (
        WHERE deal_stage = 'Prospecting'
    ) AS prospecting_opportunities,

    COUNT(*) FILTER (
        WHERE deal_stage = 'Engaging'
    ) AS engaging_opportunities,

    COUNT(*) FILTER (
        WHERE deal_stage IN ('Prospecting', 'Engaging')
    ) AS total_open_opportunities,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE deal_stage IN ('Prospecting', 'Engaging')
        )
        / SUM(
            COUNT(*) FILTER (
                WHERE deal_stage IN ('Prospecting', 'Engaging')
            )
        ) OVER (),
        2
    ) AS open_pipeline_share_percent

FROM sales_pipeline

GROUP BY product

ORDER BY total_open_opportunities DESC;


-- ============================================================
-- Query 12: Identify Product Strength
-- Combines revenue, win rate and deal size
-- ============================================================

SELECT
    product,

    ROUND(
        100.0 *
        COUNT(*) FILTER (WHERE deal_stage = 'Won')
        / NULLIF(
            COUNT(*) FILTER (
                WHERE deal_stage IN ('Won', 'Lost')
            ),
            0
        ),
        2
    ) AS win_rate_percent,

    SUM(close_value)
        FILTER (WHERE deal_stage = 'Won')
        AS won_revenue,

    ROUND(
        AVG(close_value)
        FILTER (WHERE deal_stage = 'Won'),
        2
    ) AS average_won_deal,

    CASE
        WHEN
            SUM(close_value)
                FILTER (WHERE deal_stage = 'Won')
            >= 2000000
            AND
            COUNT(*) FILTER (WHERE deal_stage = 'Won')::NUMERIC
            /
            NULLIF(
                COUNT(*) FILTER (
                    WHERE deal_stage IN ('Won', 'Lost')
                ),
                0
            ) >= 0.60
        THEN 'Core Performer'

        WHEN
            COUNT(*) FILTER (WHERE deal_stage = 'Won')::NUMERIC
            /
            NULLIF(
                COUNT(*) FILTER (
                    WHERE deal_stage IN ('Won', 'Lost')
                ),
                0
            ) >= 0.64
        THEN 'High Conversion'

        WHEN
            SUM(close_value)
                FILTER (WHERE deal_stage = 'Won')
            < 100000
        THEN 'Low Revenue'

        ELSE 'Developing'
    END AS product_category

FROM sales_pipeline

GROUP BY product

ORDER BY won_revenue DESC;