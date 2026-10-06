-- ============================================================
-- 03_database_validation.sql
-- Final validation after data cleaning
-- ============================================================


-- ============================================================
-- Query 1: Validate table row counts
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
-- Query 2: Check duplicate opportunity IDs
-- ============================================================

SELECT
    opportunity_id,
    COUNT(*) AS duplicate_count
FROM sales_pipeline
GROUP BY opportunity_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


-- ============================================================
-- Query 3: Validate product relationships
-- Every non-null pipeline product should exist in products
-- ============================================================

SELECT
    COUNT(*) AS unmatched_products
FROM sales_pipeline sp
LEFT JOIN products p
    ON LOWER(TRIM(sp.product)) = LOWER(TRIM(p.product))
WHERE sp.product IS NOT NULL
  AND p.product IS NULL;


-- ============================================================
-- Query 4: Show product values used in pipeline
-- ============================================================

SELECT
    sp.product,
    COUNT(*) AS opportunity_count
FROM sales_pipeline sp
GROUP BY sp.product
ORDER BY opportunity_count DESC;


-- ============================================================
-- Query 5: Validate account relationships
-- NULL accounts are allowed for open opportunities
-- ============================================================

SELECT
    COUNT(*) AS unmatched_accounts
FROM sales_pipeline sp
LEFT JOIN accounts a
    ON LOWER(TRIM(sp.account)) = LOWER(TRIM(a.account))
WHERE sp.account IS NOT NULL
  AND a.account IS NULL;


-- ============================================================
-- Query 6: Count missing accounts by deal stage
-- ============================================================

SELECT
    deal_stage,
    COUNT(*) AS missing_account_opportunities
FROM sales_pipeline
WHERE account IS NULL
GROUP BY deal_stage
ORDER BY missing_account_opportunities DESC;


-- ============================================================
-- Query 7: Validate sales agent relationships
-- ============================================================

SELECT
    COUNT(*) AS unmatched_sales_agents
FROM sales_pipeline sp
LEFT JOIN sales_teams st
    ON LOWER(TRIM(sp.sales_agent)) = LOWER(TRIM(st.sales_agent))
WHERE sp.sales_agent IS NOT NULL
  AND st.sales_agent IS NULL;


-- ============================================================
-- Query 8: Validate deal stages
-- ============================================================

SELECT
    deal_stage,
    COUNT(*) AS opportunity_count
FROM sales_pipeline
GROUP BY deal_stage
ORDER BY opportunity_count DESC;


-- ============================================================
-- Query 9: Validate close values by deal stage
-- ============================================================

SELECT
    deal_stage,
    COUNT(*) AS opportunity_count,
    COUNT(close_value) AS non_null_close_values,
    COUNT(*) FILTER (WHERE close_value IS NULL) AS null_close_values,
    MIN(close_value) AS minimum_close_value,
    MAX(close_value) AS maximum_close_value,
    COALESCE(SUM(close_value), 0) AS total_close_value
FROM sales_pipeline
GROUP BY deal_stage
ORDER BY deal_stage;


-- ============================================================
-- Query 10: Check invalid negative close values
-- ============================================================

SELECT
    COUNT(*) AS negative_close_values
FROM sales_pipeline
WHERE close_value < 0;


-- ============================================================
-- Query 11: Validate date logic
-- ============================================================

SELECT
    COUNT(*) AS invalid_dates
FROM sales_pipeline
WHERE engage_date IS NOT NULL
  AND close_date IS NOT NULL
  AND close_date < engage_date;


-- ============================================================
-- Query 12: Validate sales cycle
-- ============================================================

SELECT
    MIN(close_date - engage_date) AS minimum_sales_cycle_days,
    MAX(close_date - engage_date) AS maximum_sales_cycle_days,
    ROUND(AVG(close_date - engage_date), 2) AS average_sales_cycle_days
FROM sales_pipeline
WHERE engage_date IS NOT NULL
  AND close_date IS NOT NULL;


-- ============================================================
-- Query 13: Final Won revenue validation
-- ============================================================

SELECT
    COUNT(*) AS won_opportunities,
    SUM(close_value) AS total_won_revenue,
    ROUND(AVG(close_value), 2) AS average_won_deal
FROM sales_pipeline
WHERE deal_stage = 'Won';


-- ============================================================
-- Query 14: Validate Won opportunities
-- Won deals should have positive close values
-- ============================================================

SELECT
    COUNT(*) AS invalid_won_deals
FROM sales_pipeline
WHERE deal_stage = 'Won'
  AND (close_value IS NULL OR close_value <= 0);


-- ============================================================
-- Query 15: Validate Lost opportunities
-- Lost deals should have zero close value
-- ============================================================

SELECT
    COUNT(*) AS invalid_lost_deals
FROM sales_pipeline
WHERE deal_stage = 'Lost'
  AND (close_value IS NULL OR close_value <> 0);


-- ============================================================
-- Query 16: Validate open opportunities
-- Prospecting and Engaging should not have close values
-- ============================================================

SELECT
    deal_stage,
    COUNT(*) AS invalid_open_deals
FROM sales_pipeline
WHERE deal_stage IN ('Prospecting', 'Engaging')
  AND close_value IS NOT NULL
GROUP BY deal_stage;


-- ============================================================
-- Query 17: Final overall validation summary
-- ============================================================

SELECT
    COUNT(*) AS total_opportunities,
    COUNT(*) FILTER (WHERE deal_stage = 'Won') AS won_opportunities,
    COUNT(*) FILTER (WHERE deal_stage = 'Lost') AS lost_opportunities,
    COUNT(*) FILTER (WHERE deal_stage IN ('Prospecting', 'Engaging')) AS open_opportunities,
    COUNT(*) FILTER (WHERE account IS NULL) AS missing_accounts,
    COUNT(*) FILTER (WHERE close_value IS NULL) AS missing_close_values,
    SUM(close_value) FILTER (WHERE deal_stage = 'Won') AS total_won_revenue
FROM sales_pipeline;