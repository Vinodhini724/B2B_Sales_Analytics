-- ============================================================
-- SALES REVENUE INTELLIGENCE
-- 01 - DATA QUALITY AUDIT
-- ============================================================
-- Purpose:
-- Validate the CRM Sales database before performing
-- business analysis.
-- ============================================================


-- ============================================================
-- 1. ROW COUNTS
-- ============================================================

SELECT 'accounts' AS table_name, COUNT(*) AS row_count
FROM accounts

UNION ALL

SELECT 'products', COUNT(*)
FROM products

UNION ALL

SELECT 'sales_pipeline', COUNT(*)
FROM sales_pipeline

UNION ALL

SELECT 'sales_teams', COUNT(*)
FROM sales_teams;


-- ============================================================
-- 2. NULL VALUE AUDIT
-- ============================================================

SELECT
    'accounts' AS table_name,
    COUNT(*) - COUNT(account) AS account_nulls,
    COUNT(*) - COUNT(sector) AS sector_nulls,
    COUNT(*) - COUNT(year_established) AS year_established_nulls,
    COUNT(*) - COUNT(revenue) AS revenue_nulls,
    COUNT(*) - COUNT(employees) AS employees_nulls,
    COUNT(*) - COUNT(office_location) AS office_location_nulls,
    COUNT(*) - COUNT(subsidiary_of) AS subsidiary_of_nulls
FROM accounts

UNION ALL

SELECT
    'products',
    COUNT(*) - COUNT(product),
    COUNT(*) - COUNT(series),
    COUNT(*) - COUNT(sales_price),
    NULL,
    NULL,
    NULL,
    NULL
FROM products

UNION ALL

SELECT
    'sales_teams',
    COUNT(*) - COUNT(sales_agent),
    COUNT(*) - COUNT(manager),
    COUNT(*) - COUNT(regional_office),
    NULL,
    NULL,
    NULL,
    NULL
FROM sales_teams;


-- Sales pipeline NULL audit

SELECT
    COUNT(*) - COUNT(opportunity_id) AS opportunity_id_nulls,
    COUNT(*) - COUNT(sales_agent) AS sales_agent_nulls,
    COUNT(*) - COUNT(product) AS product_nulls,
    COUNT(*) - COUNT(account) AS account_nulls,
    COUNT(*) - COUNT(deal_stage) AS deal_stage_nulls,
    COUNT(*) - COUNT(engage_date) AS engage_date_nulls,
    COUNT(*) - COUNT(close_date) AS close_date_nulls,
    COUNT(*) - COUNT(close_value) AS close_value_nulls
FROM sales_pipeline;


-- ============================================================
-- 3. DUPLICATE OPPORTUNITIES
-- ============================================================

SELECT
    opportunity_id,
    COUNT(*) AS occurrence_count
FROM sales_pipeline
GROUP BY opportunity_id
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC;


-- Total number of duplicated opportunity IDs

SELECT
    COUNT(*) AS duplicate_opportunity_ids
FROM (
    SELECT opportunity_id
    FROM sales_pipeline
    GROUP BY opportunity_id
    HAVING COUNT(*) > 1
) AS duplicates;


-- ============================================================
-- 4. DEAL STAGE VALIDATION
-- ============================================================

SELECT
    deal_stage,
    COUNT(*) AS opportunity_count
FROM sales_pipeline
GROUP BY deal_stage
ORDER BY opportunity_count DESC;


-- ============================================================
-- 5. PRODUCT VALIDATION
-- ============================================================

SELECT
    product,
    COUNT(*) AS opportunity_count
FROM sales_pipeline
GROUP BY product
ORDER BY opportunity_count DESC;


-- ============================================================
-- 6. SALES AGENT VALIDATION
-- ============================================================

SELECT
    sales_agent,
    COUNT(*) AS opportunity_count
FROM sales_pipeline
GROUP BY sales_agent
ORDER BY opportunity_count DESC;


-- ============================================================
-- 7. REFERENTIAL INTEGRITY
-- ============================================================
-- Check whether every account in sales_pipeline
-- exists in accounts.


SELECT DISTINCT
    sp.account
FROM sales_pipeline AS sp
LEFT JOIN accounts AS a
    ON TRIM(sp.account) = TRIM(a.account)
WHERE a.account IS NULL
ORDER BY sp.account;


-- Check whether every product exists in products.

SELECT DISTINCT
    sp.product
FROM sales_pipeline AS sp
LEFT JOIN products AS p
    ON TRIM(sp.product) = TRIM(p.product)
WHERE p.product IS NULL
ORDER BY sp.product;


-- Check whether every sales agent exists in sales_teams.

SELECT DISTINCT
    sp.sales_agent
FROM sales_pipeline AS sp
LEFT JOIN sales_teams AS st
    ON TRIM(sp.sales_agent) = TRIM(st.sales_agent)
WHERE st.sales_agent IS NULL
ORDER BY sp.sales_agent;


-- ============================================================
-- 8. DATE VALIDATION
-- ============================================================

SELECT
    COUNT(*) FILTER (
        WHERE engage_date IS NULL
    ) AS missing_engage_date,

    COUNT(*) FILTER (
        WHERE close_date IS NULL
    ) AS missing_close_date,

    COUNT(*) FILTER (
        WHERE close_date < engage_date
    ) AS close_before_engage,

    COUNT(*) FILTER (
        WHERE close_date > CURRENT_DATE
    ) AS future_close_dates

FROM sales_pipeline;


-- ============================================================
-- 9. CLOSE VALUE VALIDATION
-- ============================================================

SELECT
    COUNT(*) FILTER (
        WHERE close_value IS NULL
    ) AS null_close_value,

    COUNT(*) FILTER (
        WHERE close_value = 0
    ) AS zero_close_value,

    COUNT(*) FILTER (
        WHERE close_value < 0
    ) AS negative_close_value,

    MIN(close_value) AS minimum_close_value,

    MAX(close_value) AS maximum_close_value,

    ROUND(AVG(close_value), 2) AS average_close_value

FROM sales_pipeline;


-- ============================================================
-- 10. CLOSE VALUE BY DEAL STAGE
-- ============================================================
-- Important for understanding how this dataset records
-- financial values across the sales funnel.


SELECT
    deal_stage,
    COUNT(*) AS opportunities,
    COUNT(close_value) AS opportunities_with_value,
    SUM(close_value) AS total_close_value,
    ROUND(AVG(close_value), 2) AS average_close_value
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
-- 11. SALES CYCLE VALIDATION
-- ============================================================

SELECT
    MIN(close_date - engage_date) AS minimum_sales_cycle_days,

    MAX(close_date - engage_date) AS maximum_sales_cycle_days,

    ROUND(
        AVG(close_date - engage_date),
        2
    ) AS average_sales_cycle_days,

    PERCENTILE_CONT(0.50)
        WITHIN GROUP (
            ORDER BY close_date - engage_date
        ) AS median_sales_cycle_days

FROM sales_pipeline
WHERE engage_date IS NOT NULL
  AND close_date IS NOT NULL;


-- ============================================================
-- 12. EXTREME CLOSE VALUES
-- ============================================================

SELECT
    opportunity_id,
    account,
    product,
    deal_stage,
    close_value
FROM sales_pipeline
WHERE close_value IS NOT NULL
ORDER BY close_value DESC
LIMIT 10;


-- ============================================================
-- END OF DATA QUALITY AUDIT
-- ============================================================