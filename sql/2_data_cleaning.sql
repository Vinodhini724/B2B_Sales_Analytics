---- ============================================================
---- 02 DATA CLEANING / DIAGNOSTIC CHECKS
---- Sales Revenue Intelligence Project
---- ============================================================
--
--
---- ============================================================
---- QUERY 1: INVESTIGATE MISSING ACCOUNTS
---- ============================================================
--
--SELECT
--    COUNT(*) AS missing_account_opportunities,
--    COUNT(*) FILTER (WHERE deal_stage = 'Won') AS won,
--    COUNT(*) FILTER (WHERE deal_stage = 'Lost') AS lost,
--    COUNT(*) FILTER (WHERE deal_stage = 'Engaging') AS engaging,
--    COUNT(*) FILTER (WHERE deal_stage = 'Prospecting') AS prospecting
--FROM sales_pipeline
--WHERE account IS NULL;
--
--
---- ============================================================
---- QUERY 2: REVENUE IMPACT OF MISSING ACCOUNTS
---- ============================================================
--
--SELECT
--    COUNT(*) AS opportunities,
--    COUNT(*) FILTER (WHERE deal_stage = 'Won') AS won_opportunities,
--    COALESCE(SUM(close_value) FILTER (WHERE deal_stage = 'Won'), 0)
--        AS won_revenue
--FROM sales_pipeline
--WHERE account IS NULL;
--
--
---- ============================================================
---- QUERY 3: MISSING ACCOUNTS BY PRODUCT
---- ============================================================
--
--SELECT
--    product,
--    COUNT(*) AS missing_account_opportunities,
--    COUNT(*) FILTER (WHERE deal_stage = 'Won') AS won_opportunities,
--    COALESCE(SUM(close_value) FILTER (WHERE deal_stage = 'Won'), 0)
--        AS won_revenue
--FROM sales_pipeline
--WHERE account IS NULL
--GROUP BY product
--ORDER BY won_revenue DESC;
--
--
---- ============================================================
---- QUERY 4: MISSING ACCOUNTS BY SALES AGENT
---- ============================================================
--
--SELECT
--    sales_agent,
--    COUNT(*) AS missing_account_opportunities,
--    COUNT(*) FILTER (WHERE deal_stage = 'Won') AS won_opportunities,
--    COALESCE(SUM(close_value) FILTER (WHERE deal_stage = 'Won'), 0)
--        AS won_revenue
--FROM sales_pipeline
--WHERE account IS NULL
--GROUP BY sales_agent
--ORDER BY missing_account_opportunities DESC;
--
--
---- ============================================================
---- QUERY 5: CHECK ACCOUNT NAME MISMATCHES
---- Compare pipeline accounts against accounts master table
---- ============================================================
--
--SELECT
--    COUNT(*) AS unmatched_accounts
--FROM sales_pipeline sp
--LEFT JOIN accounts a
--    ON LOWER(TRIM(sp.account)) = LOWER(TRIM(a.account))
--WHERE sp.account IS NOT NULL
--  AND a.account IS NULL;
--
--
---- ============================================================
---- QUERY 6: SHOW EXAMPLES OF ACCOUNT MISMATCHES
---- ============================================================
--
--SELECT DISTINCT
--    sp.account
--FROM sales_pipeline sp
--LEFT JOIN accounts a
--    ON LOWER(TRIM(sp.account)) = LOWER(TRIM(a.account))
--WHERE sp.account IS NOT NULL
--  AND a.account IS NULL
--ORDER BY sp.account
--LIMIT 50;
--
--
---- ============================================================
---- QUERY 7: PRODUCT REFERENTIAL INTEGRITY
---- ============================================================
--
--SELECT
--    COUNT(*) AS unmatched_products
--FROM sales_pipeline sp
--LEFT JOIN products p
--    ON LOWER(TRIM(sp.product)) = LOWER(TRIM(p.product))
--WHERE sp.product IS NOT NULL
--  AND p.product IS NULL;
--
--
---- ============================================================
---- QUERY 8: SALES AGENT REFERENTIAL INTEGRITY
---- ============================================================
--
--SELECT
--    COUNT(*) AS unmatched_sales_agents
--FROM sales_pipeline sp
--LEFT JOIN sales_teams st
--    ON LOWER(TRIM(sp.sales_agent)) = LOWER(TRIM(st.sales_agent))
--WHERE sp.sales_agent IS NOT NULL
--  AND st.sales_agent IS NULL;
--
--
---- ============================================================
---- QUERY 9: NULL DATES BY DEAL STAGE
---- ============================================================
--
--SELECT
--    deal_stage,
--    COUNT(*) AS opportunities,
--    COUNT(*) FILTER (WHERE engage_date IS NULL) AS missing_engage_date,
--    COUNT(*) FILTER (WHERE close_date IS NULL) AS missing_close_date
--FROM sales_pipeline
--GROUP BY deal_stage
--ORDER BY deal_stage;
--
--
---- ============================================================
---- QUERY 10: NULL CLOSE VALUE BY DEAL STAGE
---- ============================================================
--
--SELECT
--    deal_stage,
--    COUNT(*) AS opportunities,
--    COUNT(*) FILTER (WHERE close_value IS NULL) AS null_close_value,
--    COUNT(*) FILTER (WHERE close_value = 0) AS zero_close_value,
--    COUNT(*) FILTER (WHERE close_value > 0) AS positive_close_value
--FROM sales_pipeline
--GROUP BY deal_stage
--ORDER BY deal_stage;
--
--
---- ============================================================
---- QUERY 11: CHECK FOR NEGATIVE VALUES
---- ============================================================
--
--SELECT
--    COUNT(*) AS negative_close_values
--FROM sales_pipeline
--WHERE close_value < 0;
--
--
---- ============================================================
---- QUERY 12: CHECK DATE LOGIC
---- ============================================================
--
--SELECT
--    COUNT(*) AS invalid_date_records
--FROM sales_pipeline
--WHERE engage_date IS NOT NULL
--  AND close_date IS NOT NULL
--  AND close_date < engage_date;
--
--
---- ============================================================
---- QUERY 13: DUPLICATE ACCOUNT NAMES IN MASTER TABLE
---- ============================================================
--
--SELECT
--    LOWER(TRIM(account)) AS normalized_account,
--    COUNT(*) AS occurrences
--FROM accounts
--GROUP BY LOWER(TRIM(account))
--HAVING COUNT(*) > 1
--ORDER BY occurrences DESC;
--
--
---- ============================================================
---- QUERY 14: DUPLICATE PRODUCT NAMES
---- ============================================================
--
--SELECT
--    LOWER(TRIM(product)) AS normalized_product,
--    COUNT(*) AS occurrences
--FROM products
--GROUP BY LOWER(TRIM(product))
--HAVING COUNT(*) > 1
--ORDER BY occurrences DESC;
--
--
---- ============================================================
---- QUERY 15: DUPLICATE SALES AGENTS
---- ============================================================
--
--SELECT
--    LOWER(TRIM(sales_agent)) AS normalized_sales_agent,
--    COUNT(*) AS occurrences
--FROM sales_teams
--GROUP BY LOWER(TRIM(sales_agent))
--HAVING COUNT(*) > 1
--ORDER BY occurrences DESC;
--
--
---- ============================================================
---- QUERY 16: OVERALL DATA QUALITY SUMMARY
---- ============================================================
--
--SELECT
--    COUNT(*) AS total_opportunities,
--
--    COUNT(*) FILTER (
--        WHERE account IS NULL
--    ) AS missing_accounts,
--
--    COUNT(*) FILTER (
--        WHERE product IS NULL
--    ) AS missing_products,
--
--    COUNT(*) FILTER (
--        WHERE sales_agent IS NULL
--    ) AS missing_sales_agents,
--
--    COUNT(*) FILTER (
--        WHERE engage_date IS NULL
--    ) AS missing_engage_dates,
--
--    COUNT(*) FILTER (
--        WHERE close_date IS NULL
--    ) AS missing_close_dates,
--
--    COUNT(*) FILTER (
--        WHERE close_value IS NULL
--    ) AS missing_close_values,
--
--    COUNT(*) FILTER (
--        WHERE close_value < 0
--    ) AS negative_values
--
--FROM sales_pipeline;


-- ============================================================
-- 02 DATA CLEANING
-- PRODUCT MISMATCH INVESTIGATION
-- ============================================================


-- ============================================================
-- QUERY 1: DISTINCT PIPELINE PRODUCTS
-- ============================================================
--
--SELECT
--    product,
--    COUNT(*) AS opportunity_count
--FROM sales_pipeline
--GROUP BY product
--ORDER BY opportunity_count DESC;
--
--
---- ============================================================
---- QUERY 2: PRODUCTS IN MASTER TABLE
---- ============================================================
--
--SELECT
--    product,
--    series,
--    sales_price
--FROM products
--ORDER BY product;
--
--
---- ============================================================
---- QUERY 3: PRODUCTS THAT DO NOT MATCH
---- ============================================================
--
--SELECT
--    sp.product,
--    COUNT(*) AS opportunity_count
--FROM sales_pipeline sp
--LEFT JOIN products p
--    ON LOWER(TRIM(sp.product)) = LOWER(TRIM(p.product))
--WHERE sp.product IS NOT NULL
--  AND p.product IS NULL
--GROUP BY sp.product
--ORDER BY opportunity_count DESC;
--
--
---- ============================================================
---- QUERY 4: MISMATCHED PRODUCTS BY DEAL STAGE
---- ============================================================
--
--SELECT
--    sp.product,
--    sp.deal_stage,
--    COUNT(*) AS opportunity_count
--FROM sales_pipeline sp
--LEFT JOIN products p
--    ON LOWER(TRIM(sp.product)) = LOWER(TRIM(p.product))
--WHERE sp.product IS NOT NULL
--  AND p.product IS NULL
--GROUP BY
--    sp.product,
--    sp.deal_stage
--ORDER BY
--    sp.product,
--    opportunity_count DESC;
--
--
---- ============================================================
---- QUERY 5: MISMATCHED PRODUCTS AND REVENUE
---- ============================================================
--
--SELECT
--    sp.product,
--    COUNT(*) AS opportunities,
--    COUNT(*) FILTER (
--        WHERE sp.deal_stage = 'Won'
--    ) AS won_opportunities,
--    COALESCE(
--        SUM(sp.close_value) FILTER (
--            WHERE sp.deal_stage = 'Won'
--        ), 0
--    ) AS won_revenue
--FROM sales_pipeline sp
--LEFT JOIN products p
--    ON LOWER(TRIM(sp.product)) = LOWER(TRIM(p.product))
--WHERE sp.product IS NOT NULL
--  AND p.product IS NULL
--GROUP BY sp.product
--ORDER BY won_revenue DESC;
--
--
---- ============================================================
---- QUERY 6: EXACT STRING REPRESENTATION
---- Helps detect spaces/case/hidden characters
---- ============================================================
--
--SELECT DISTINCT
--    product ,
--    LENGTH(product) AS character_length
--FROM sales_pipeline
--WHERE product IS NOT NULL
--ORDER BY product;
--
--
---- ============================================================
---- QUERY 7: MASTER PRODUCT STRING REPRESENTATION
---- ============================================================
--
--SELECT DISTINCT product,
--    LENGTH(product) AS character_length
--FROM products
--ORDER BY product;
--
--
---- ============================================================
---- QUERY 8: NORMALIZED PRODUCT COMPARISON
---- ============================================================
--
--SELECT
--    sp.product AS pipeline_product,
--    p.product AS master_product,
--    COUNT(*) AS opportunity_count
--FROM sales_pipeline sp
--JOIN products p
--    ON LOWER(TRIM(sp.product)) = LOWER(TRIM(p.product))
--GROUP BY
--    sp.product,
--    p.product
--ORDER BY opportunity_count DESC;


-- ============================================================
-- 02 DATA CLEANING
-- SALES REVENUE INTELLIGENCE
-- ============================================================


-- ============================================================
-- QUERY 1: CHECK CURRENT GTXPRO RECORDS
-- ============================================================

SELECT
    product,
    COUNT(*) AS opportunity_count,
    COUNT(*) FILTER (WHERE deal_stage = 'Won') AS won_opportunities,
    COALESCE(
        SUM(close_value) FILTER (WHERE deal_stage = 'Won'),
        0
    ) AS won_revenue
FROM sales_pipeline
WHERE product = 'GTXPro'
GROUP BY product;


-- ============================================================
-- QUERY 2: STANDARDIZE PRODUCT NAME
-- GTXPro -> GTX Pro
-- ============================================================

UPDATE sales_pipeline
SET product = 'GTX Pro'
WHERE product = 'GTXPro';


-- ============================================================
-- QUERY 3: VERIFY PRODUCT MISMATCH IS FIXED
-- ============================================================

SELECT
    COUNT(*) AS unmatched_products
FROM sales_pipeline sp
LEFT JOIN products p
    ON LOWER(TRIM(sp.product)) = LOWER(TRIM(p.product))
WHERE sp.product IS NOT NULL
  AND p.product IS NULL;


-- ============================================================
-- QUERY 4: VERIFY GTX PRO RECORDS
-- ============================================================

SELECT
    sp.product,
    COUNT(*) AS opportunities,
    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Won'
    ) AS won_opportunities,
    COALESCE(
        SUM(sp.close_value) FILTER (
            WHERE sp.deal_stage = 'Won'
        ),
        0
    ) AS won_revenue
FROM sales_pipeline sp
WHERE sp.product = 'GTX Pro'
GROUP BY sp.product;


-- ============================================================
-- QUERY 5: VERIFY TOTAL REVENUE AFTER CLEANING
-- ============================================================

SELECT
    COUNT(*) FILTER (
        WHERE deal_stage = 'Won'
    ) AS won_opportunities,

    SUM(close_value) FILTER (
        WHERE deal_stage = 'Won'
    ) AS total_won_revenue

FROM sales_pipeline;


-- ============================================================
-- QUERY 6: CHECK FOR ANY REMAINING PRODUCT MISMATCHES
-- ============================================================

SELECT
    sp.product,
    COUNT(*) AS opportunity_count
FROM sales_pipeline sp
LEFT JOIN products p
    ON LOWER(TRIM(sp.product)) = LOWER(TRIM(p.product))
WHERE sp.product IS NOT NULL
  AND p.product IS NULL
GROUP BY sp.product
ORDER BY opportunity_count DESC;


-- ============================================================
-- QUERY 7: FINAL PRODUCT REFERENTIAL INTEGRITY
-- ============================================================

SELECT
    COUNT(*) AS unmatched_products
FROM sales_pipeline sp
INNER JOIN products p
    ON LOWER(TRIM(sp.product)) = LOWER(TRIM(p.product));