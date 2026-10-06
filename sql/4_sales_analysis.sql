-- ============================================================
-- 04_sales_analysis.sql
-- Core Sales Performance Analysis
-- ============================================================


-- ============================================================
-- Query 1: Overall Sales Performance
-- ============================================================

SELECT
    COUNT(*) FILTER (WHERE deal_stage = 'Won') AS won_opportunities,
    COUNT(*) FILTER (WHERE deal_stage = 'Lost') AS lost_opportunities,
    COUNT(*) FILTER (
        WHERE deal_stage IN ('Prospecting', 'Engaging')
    ) AS open_opportunities,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE deal_stage = 'Won')
        / NULLIF(
            COUNT(*) FILTER (WHERE deal_stage IN ('Won', 'Lost')),
            0
        ),
        2
    ) AS win_rate_percent,
    SUM(close_value) FILTER (WHERE deal_stage = 'Won') AS total_won_revenue,
    ROUND(
        AVG(close_value) FILTER (WHERE deal_stage = 'Won'),
        2
    ) AS average_won_deal
FROM sales_pipeline;


-- ============================================================
-- Query 2: Sales Performance by Deal Stage
-- ============================================================

SELECT
    deal_stage,
    COUNT(*) AS opportunity_count,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_opportunities
FROM sales_pipeline
GROUP BY deal_stage
ORDER BY opportunity_count DESC;


-- ============================================================
-- Query 3: Monthly Won Revenue
-- ============================================================

SELECT
    DATE_TRUNC('month', close_date)::DATE AS month,
    COUNT(*) AS won_opportunities,
    SUM(close_value) AS won_revenue,
    ROUND(AVG(close_value), 2) AS average_deal_value
FROM sales_pipeline
WHERE deal_stage = 'Won'
GROUP BY DATE_TRUNC('month', close_date)
ORDER BY month;


-- ============================================================
-- Query 4: Product Performance
-- ============================================================

SELECT
    p.product,
    p.series,
    COUNT(*) FILTER (WHERE sp.deal_stage = 'Won')
        AS won_opportunities,
    COUNT(*) FILTER (WHERE sp.deal_stage = 'Lost')
        AS lost_opportunities,
    COUNT(*) AS total_opportunities,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE sp.deal_stage = 'Won')
        / NULLIF(
            COUNT(*) FILTER (
                WHERE sp.deal_stage IN ('Won', 'Lost')
            ),
            0
        ),
        2
    ) AS win_rate_percent,
    COALESCE(
        SUM(sp.close_value) FILTER (WHERE sp.deal_stage = 'Won'),
        0
    ) AS won_revenue,
    ROUND(
        AVG(sp.close_value) FILTER (WHERE sp.deal_stage = 'Won'),
        2
    ) AS average_won_deal
FROM products p
LEFT JOIN sales_pipeline sp
    ON sp.product = p.product
GROUP BY p.product, p.series
ORDER BY won_revenue DESC;


-- ============================================================
-- Query 5: Regional Performance
-- ============================================================

SELECT
    st.regional_office,
    COUNT(*) FILTER (WHERE sp.deal_stage = 'Won')
        AS won_opportunities,
    COUNT(*) FILTER (WHERE sp.deal_stage = 'Lost')
        AS lost_opportunities,
    COUNT(*) AS total_opportunities,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE sp.deal_stage = 'Won')
        / NULLIF(
            COUNT(*) FILTER (
                WHERE sp.deal_stage IN ('Won', 'Lost')
            ),
            0
        ),
        2
    ) AS win_rate_percent,
    COALESCE(
        SUM(sp.close_value) FILTER (WHERE sp.deal_stage = 'Won'),
        0
    ) AS won_revenue,
    ROUND(
        AVG(sp.close_value) FILTER (WHERE sp.deal_stage = 'Won'),
        2
    ) AS average_won_deal
FROM sales_pipeline sp
JOIN sales_teams st
    ON sp.sales_agent = st.sales_agent
GROUP BY st.regional_office
ORDER BY won_revenue DESC;


-- ============================================================
-- Query 6: Salesperson Performance
-- ============================================================

SELECT
    st.sales_agent,
    st.manager,
    st.regional_office,
    COUNT(*) FILTER (WHERE sp.deal_stage = 'Won')
        AS won_opportunities,
    COUNT(*) FILTER (WHERE sp.deal_stage = 'Lost')
        AS lost_opportunities,
    COUNT(*) AS total_opportunities,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE sp.deal_stage = 'Won')
        / NULLIF(
            COUNT(*) FILTER (
                WHERE sp.deal_stage IN ('Won', 'Lost')
            ),
            0
        ),
        2
    ) AS win_rate_percent,
    COALESCE(
        SUM(sp.close_value) FILTER (WHERE sp.deal_stage = 'Won'),
        0
    ) AS won_revenue,
    ROUND(
        AVG(sp.close_value) FILTER (WHERE sp.deal_stage = 'Won'),
        2
    ) AS average_won_deal
FROM sales_pipeline sp
JOIN sales_teams st
    ON sp.sales_agent = st.sales_agent
GROUP BY
    st.sales_agent,
    st.manager,
    st.regional_office
ORDER BY won_revenue DESC;


-- ============================================================
-- Query 7: Top Accounts by Won Revenue
-- ============================================================

SELECT
    a.account,
    a.sector,
    a.office_location,
    COUNT(*) FILTER (WHERE sp.deal_stage = 'Won')
        AS won_opportunities,
    SUM(sp.close_value) FILTER (WHERE sp.deal_stage = 'Won')
        AS won_revenue,
    ROUND(
        AVG(sp.close_value) FILTER (WHERE sp.deal_stage = 'Won'),
        2
    ) AS average_deal_value
FROM sales_pipeline sp
JOIN accounts a
    ON sp.account = a.account
WHERE sp.deal_stage = 'Won'
GROUP BY
    a.account,
    a.sector,
    a.office_location
ORDER BY won_revenue DESC
LIMIT 20;


-- ============================================================
-- Query 8: Sales Cycle by Salesperson
-- ============================================================

SELECT
    st.sales_agent,
    st.regional_office,
    COUNT(*) AS completed_deals,
    ROUND(
        AVG(sp.close_date - sp.engage_date),
        2
    ) AS average_sales_cycle_days,
    MIN(sp.close_date - sp.engage_date)
        AS fastest_deal_days,
    MAX(sp.close_date - sp.engage_date)
        AS slowest_deal_days
FROM sales_pipeline sp
JOIN sales_teams st
    ON sp.sales_agent = st.sales_agent
WHERE sp.engage_date IS NOT NULL
  AND sp.close_date IS NOT NULL
GROUP BY
    st.sales_agent,
    st.regional_office
ORDER BY average_sales_cycle_days ASC;


-- ============================================================
-- Query 9: Sales Cycle by Product
-- ============================================================

SELECT
    sp.product,
    COUNT(*) AS completed_deals,
    ROUND(
        AVG(sp.close_date - sp.engage_date),
        2
    ) AS average_sales_cycle_days,
    MIN(sp.close_date - sp.engage_date)
        AS fastest_deal_days,
    MAX(sp.close_date - sp.engage_date)
        AS slowest_deal_days
FROM sales_pipeline sp
WHERE sp.engage_date IS NOT NULL
  AND sp.close_date IS NOT NULL
GROUP BY sp.product
ORDER BY average_sales_cycle_days ASC;


-- ============================================================
-- Query 10: Pipeline by Stage
-- Focuses on opportunity volume because open stages
-- have NULL close_value.
-- ============================================================

SELECT
    deal_stage,
    COUNT(*) AS opportunity_count,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_pipeline
FROM sales_pipeline
GROUP BY deal_stage
ORDER BY
    CASE deal_stage
        WHEN 'Prospecting' THEN 1
        WHEN 'Engaging' THEN 2
        WHEN 'Won' THEN 3
        WHEN 'Lost' THEN 4
        ELSE 5
    END;


-- ============================================================
-- Query 11: Open Opportunities by Product
-- ============================================================

SELECT
    product,
    COUNT(*) AS open_opportunities
FROM sales_pipeline
WHERE deal_stage IN ('Prospecting', 'Engaging')
GROUP BY product
ORDER BY open_opportunities DESC;


-- ============================================================
-- Query 12: Revenue Contribution by Product
-- ============================================================

SELECT
    product,
    SUM(close_value) AS won_revenue,
    ROUND(
        100.0 * SUM(close_value)
        / SUM(SUM(close_value)) OVER (),
        2
    ) AS revenue_contribution_percent
FROM sales_pipeline
WHERE deal_stage = 'Won'
GROUP BY product
ORDER BY won_revenue DESC;


-- ============================================================
-- Query 13: Revenue Contribution by Region
-- ============================================================

SELECT
    st.regional_office,
    SUM(sp.close_value) AS won_revenue,
    ROUND(
        100.0 * SUM(sp.close_value)
        / SUM(SUM(sp.close_value)) OVER (),
        2
    ) AS revenue_contribution_percent
FROM sales_pipeline sp
JOIN sales_teams st
    ON sp.sales_agent = st.sales_agent
WHERE sp.deal_stage = 'Won'
GROUP BY st.regional_office
ORDER BY won_revenue DESC;


-- ============================================================
-- Query 14: Manager Performance
-- ============================================================

SELECT
    st.manager,
    st.regional_office,
    COUNT(*) FILTER (WHERE sp.deal_stage = 'Won')
        AS won_opportunities,
    COUNT(*) FILTER (WHERE sp.deal_stage = 'Lost')
        AS lost_opportunities,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE sp.deal_stage = 'Won')
        / NULLIF(
            COUNT(*) FILTER (
                WHERE sp.deal_stage IN ('Won', 'Lost')
            ),
            0
        ),
        2
    ) AS win_rate_percent,
    SUM(sp.close_value) FILTER (WHERE sp.deal_stage = 'Won')
        AS won_revenue,
    ROUND(
        AVG(sp.close_value) FILTER (WHERE sp.deal_stage = 'Won'),
        2
    ) AS average_won_deal
FROM sales_pipeline sp
JOIN sales_teams st
    ON sp.sales_agent = st.sales_agent
GROUP BY
    st.manager,
    st.regional_office
ORDER BY won_revenue DESC;


-- ============================================================
-- Query 15: High-Value Won Deals
-- ============================================================

SELECT
    sp.opportunity_id,
    sp.account,
    sp.product,
    sp.sales_agent,
    sp.close_value,
    sp.engage_date,
    sp.close_date,
    (sp.close_date - sp.engage_date) AS sales_cycle_days
FROM sales_pipeline sp
WHERE sp.deal_stage = 'Won'
ORDER BY sp.close_value DESC
LIMIT 20;