-- ============================================================
-- 08_pipeline_analysis.sql
-- SALES PIPELINE ANALYSIS
-- ============================================================


-- ============================================================
-- QUERY 1: Overall Pipeline Health
-- ============================================================

SELECT
    COUNT(*) AS total_opportunities,

    COUNT(*) FILTER (
        WHERE deal_stage IN ('Prospecting', 'Engaging')
    ) AS open_opportunities,

    COUNT(*) FILTER (
        WHERE deal_stage = 'Prospecting'
    ) AS prospecting_opportunities,

    COUNT(*) FILTER (
        WHERE deal_stage = 'Engaging'
    ) AS engaging_opportunities,

    COUNT(*) FILTER (
        WHERE deal_stage = 'Won'
    ) AS won_opportunities,

    COUNT(*) FILTER (
        WHERE deal_stage = 'Lost'
    ) AS lost_opportunities,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE deal_stage IN ('Prospecting', 'Engaging')
        ) / COUNT(*),
        2
    ) AS open_pipeline_percentage

FROM sales_pipeline;


-- ============================================================
-- QUERY 2: Pipeline by Deal Stage
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

ORDER BY opportunity_count DESC;


-- ============================================================
-- QUERY 3: Open Pipeline by Product
-- ============================================================

SELECT
    sp.product,

    COUNT(*) AS open_opportunities,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Prospecting'
    ) AS prospecting,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Engaging'
    ) AS engaging,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_open_pipeline

FROM sales_pipeline sp

WHERE sp.deal_stage IN ('Prospecting', 'Engaging')

GROUP BY sp.product

ORDER BY open_opportunities DESC;


-- ============================================================
-- QUERY 4: Open Pipeline by Region
-- ============================================================

SELECT
    st.regional_office AS region,

    COUNT(*) AS open_opportunities,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Prospecting'
    ) AS prospecting,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Engaging'
    ) AS engaging,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_open_pipeline

FROM sales_pipeline sp

JOIN sales_teams st
    ON sp.sales_agent = st.sales_agent

WHERE sp.deal_stage IN ('Prospecting', 'Engaging')

GROUP BY st.regional_office

ORDER BY open_opportunities DESC;


-- ============================================================
-- QUERY 5: Open Pipeline by Salesperson
-- ============================================================

SELECT
    st.sales_agent,
    st.regional_office,

    COUNT(*) AS open_opportunities,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Prospecting'
    ) AS prospecting,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Engaging'
    ) AS engaging,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Won'
    ) AS won_opportunities,

    COALESCE(
        SUM(sp.close_value) FILTER (
            WHERE sp.deal_stage = 'Won'
        ),
        0
    ) AS historical_won_revenue

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
-- QUERY 6: Average Age of Open Pipeline
-- IMPORTANT:
-- Uses the latest engage_date in the dataset as reference date.
-- Does NOT use CURRENT_DATE.
-- ============================================================

WITH reference_date AS (

    SELECT
        MAX(engage_date) AS max_engage_date

    FROM sales_pipeline

),

open_pipeline AS (

    SELECT
        sp.opportunity_id,
        sp.engage_date,
        r.max_engage_date,

        r.max_engage_date - sp.engage_date
            AS pipeline_age_days

    FROM sales_pipeline sp

    CROSS JOIN reference_date r

    WHERE
        sp.deal_stage = 'Engaging'
        AND sp.engage_date IS NOT NULL

)

SELECT

    COUNT(*) AS engaging_opportunities,

    ROUND(
        AVG(pipeline_age_days),
        2
    ) AS average_pipeline_age_days,

    MIN(pipeline_age_days)
        AS minimum_pipeline_age_days,

    MAX(pipeline_age_days)
        AS maximum_pipeline_age_days

FROM open_pipeline;


-- ============================================================
-- QUERY 7: Pipeline Age Distribution
-- ============================================================

WITH reference_date AS (

    SELECT
        MAX(engage_date) AS max_engage_date

    FROM sales_pipeline

),

age_data AS (

    SELECT

        sp.opportunity_id,

        CASE

            WHEN r.max_engage_date - sp.engage_date <= 30
                THEN '0-30 Days'

            WHEN r.max_engage_date - sp.engage_date <= 60
                THEN '31-60 Days'

            WHEN r.max_engage_date - sp.engage_date <= 90
                THEN '61-90 Days'

            ELSE '90+ Days'

        END AS pipeline_age_bucket

    FROM sales_pipeline sp

    CROSS JOIN reference_date r

    WHERE
        sp.deal_stage = 'Engaging'
        AND sp.engage_date IS NOT NULL

)

SELECT

    pipeline_age_bucket,

    COUNT(*) AS opportunity_count,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage

FROM age_data

GROUP BY pipeline_age_bucket

ORDER BY

    CASE pipeline_age_bucket

        WHEN '0-30 Days' THEN 1
        WHEN '31-60 Days' THEN 2
        WHEN '61-90 Days' THEN 3
        WHEN '90+ Days' THEN 4

    END;


-- ============================================================
-- QUERY 8: Pipeline Age by Product
-- ============================================================

WITH reference_date AS (

    SELECT
        MAX(engage_date) AS max_engage_date

    FROM sales_pipeline

)

SELECT

    sp.product,

    COUNT(*) AS engaging_opportunities,

    ROUND(
        AVG(
            r.max_engage_date - sp.engage_date
        ),
        2
    ) AS average_pipeline_age_days,

    MIN(
        r.max_engage_date - sp.engage_date
    ) AS minimum_age_days,

    MAX(
        r.max_engage_date - sp.engage_date
    ) AS maximum_age_days

FROM sales_pipeline sp

CROSS JOIN reference_date r

WHERE
    sp.deal_stage = 'Engaging'
    AND sp.engage_date IS NOT NULL

GROUP BY sp.product

ORDER BY average_pipeline_age_days DESC;


-- ============================================================
-- QUERY 9: Oldest Open Opportunities
-- ============================================================

WITH reference_date AS (

    SELECT
        MAX(engage_date) AS max_engage_date

    FROM sales_pipeline

)

SELECT

    sp.opportunity_id,
    sp.sales_agent,
    sp.product,
    sp.account,
    sp.deal_stage,
    sp.engage_date,

    r.max_engage_date - sp.engage_date
        AS pipeline_age_days

FROM sales_pipeline sp

CROSS JOIN reference_date r

WHERE
    sp.deal_stage = 'Engaging'
    AND sp.engage_date IS NOT NULL

ORDER BY pipeline_age_days DESC

LIMIT 20;


-- ============================================================
-- QUERY 10: Stalled Opportunities by Salesperson
-- Stalled = Engaging opportunity older than 90 days
-- relative to the dataset's latest engage_date.
-- ============================================================

WITH reference_date AS (

    SELECT
        MAX(engage_date) AS max_engage_date

    FROM sales_pipeline

)

SELECT

    st.sales_agent,
    st.regional_office,

    COUNT(*) AS stalled_opportunities,

    COUNT(*) FILTER (
        WHERE
            r.max_engage_date - sp.engage_date > 90
    ) AS over_90_days,

    ROUND(
        AVG(
            r.max_engage_date - sp.engage_date
        ),
        2
    ) AS average_age_days

FROM sales_pipeline sp

JOIN sales_teams st
    ON sp.sales_agent = st.sales_agent

CROSS JOIN reference_date r

WHERE
    sp.deal_stage = 'Engaging'
    AND sp.engage_date IS NOT NULL
    AND r.max_engage_date - sp.engage_date > 90

GROUP BY
    st.sales_agent,
    st.regional_office

ORDER BY stalled_opportunities DESC;


-- ============================================================
-- QUERY 11: Open Pipeline by Sector
-- ============================================================

SELECT

    COALESCE(
        a.sector,
        'Missing Account'
    ) AS sector,

    COUNT(*) AS open_opportunities,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Prospecting'
    ) AS prospecting,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Engaging'
    ) AS engaging

FROM sales_pipeline sp

LEFT JOIN accounts a
    ON sp.account = a.account

WHERE
    sp.deal_stage IN ('Prospecting', 'Engaging')

GROUP BY
    COALESCE(
        a.sector,
        'Missing Account'
    )

ORDER BY open_opportunities DESC;


-- ============================================================
-- QUERY 12: Pipeline Concentration by Account
-- ============================================================

WITH account_pipeline AS (

    SELECT
        sp.account,

        COUNT(*) FILTER (
            WHERE sp.deal_stage IN ('Prospecting', 'Engaging')
        ) AS open_opportunities

    FROM sales_pipeline sp

    WHERE sp.account IS NOT NULL

    GROUP BY sp.account

),

grouped_pipeline AS (

    SELECT

        CASE
            WHEN open_opportunities >= 10
                THEN '10+ Open Opportunities'

            WHEN open_opportunities >= 5
                THEN '5-9 Open Opportunities'

            WHEN open_opportunities >= 2
                THEN '2-4 Open Opportunities'

            ELSE '1 Open Opportunity'
        END AS account_pipeline_group,

        COUNT(*) AS account_count,

        SUM(open_opportunities) AS open_opportunities

    FROM account_pipeline

    WHERE open_opportunities > 0

    GROUP BY
        CASE
            WHEN open_opportunities >= 10
                THEN '10+ Open Opportunities'

            WHEN open_opportunities >= 5
                THEN '5-9 Open Opportunities'

            WHEN open_opportunities >= 2
                THEN '2-4 Open Opportunities'

            ELSE '1 Open Opportunity'
        END
)

SELECT
    account_pipeline_group,
    account_count,
    open_opportunities

FROM grouped_pipeline

ORDER BY
    CASE account_pipeline_group
        WHEN '10+ Open Opportunities' THEN 1
        WHEN '5-9 Open Opportunities' THEN 2
        WHEN '2-4 Open Opportunities' THEN 3
        WHEN '1 Open Opportunity' THEN 4
    END;


-- ============================================================
-- QUERY 13: Accounts with Highest Open Pipeline
-- ============================================================

SELECT

    sp.account,

    COUNT(*) AS open_opportunities,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Prospecting'
    ) AS prospecting,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Engaging'
    ) AS engaging,

    COUNT(*) FILTER (
        WHERE sp.deal_stage = 'Engaging'
        AND sp.engage_date IS NOT NULL
    ) AS aged_engaging_opportunities

FROM sales_pipeline sp

WHERE
    sp.deal_stage IN ('Prospecting', 'Engaging')
    AND sp.account IS NOT NULL

GROUP BY sp.account

ORDER BY open_opportunities DESC

LIMIT 25;


-- ============================================================
-- QUERY 14: Stalled Pipeline by Region
-- Stalled = Engaging opportunity older than 90 days
-- ============================================================

WITH reference_date AS (

    SELECT
        MAX(engage_date) AS max_engage_date

    FROM sales_pipeline

)

SELECT

    st.regional_office AS region,

    COUNT(*) AS stalled_opportunities,

    COUNT(*) FILTER (
        WHERE
            r.max_engage_date - sp.engage_date > 90
    ) AS over_90_days,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_stalled_pipeline

FROM sales_pipeline sp

JOIN sales_teams st
    ON sp.sales_agent = st.sales_agent

CROSS JOIN reference_date r

WHERE
    sp.deal_stage = 'Engaging'
    AND sp.engage_date IS NOT NULL
    AND r.max_engage_date - sp.engage_date > 90

GROUP BY st.regional_office

ORDER BY stalled_opportunities DESC;


-- ============================================================
-- QUERY 15: Final Pipeline Health Summary
-- ============================================================

WITH reference_date AS (

    SELECT
        MAX(engage_date) AS max_engage_date

    FROM sales_pipeline

),

pipeline_summary AS (

    SELECT

        COUNT(*) AS total_opportunities,

        COUNT(*) FILTER (
            WHERE deal_stage IN ('Prospecting', 'Engaging')
        ) AS open_opportunities,

        COUNT(*) FILTER (
            WHERE deal_stage = 'Prospecting'
        ) AS prospecting,

        COUNT(*) FILTER (
            WHERE deal_stage = 'Engaging'
        ) AS engaging,

        COUNT(*) FILTER (
            WHERE
                deal_stage = 'Engaging'
                AND engage_date IS NOT NULL
                AND r.max_engage_date - engage_date > 90
        ) AS stalled_over_90_days,

        COUNT(*) FILTER (
            WHERE account IS NULL
        ) AS missing_account_records,

        COUNT(*) FILTER (
            WHERE close_value IS NULL
        ) AS missing_close_value_records

    FROM sales_pipeline sp

    CROSS JOIN reference_date r

)

SELECT

    total_opportunities,
    open_opportunities,
    prospecting,
    engaging,

    stalled_over_90_days,

    ROUND(
        100.0 * open_opportunities /
        total_opportunities,
        2
    ) AS open_pipeline_percentage,

    ROUND(
        100.0 * stalled_over_90_days /
        NULLIF(engaging, 0),
        2
    ) AS stalled_percentage_of_engaging,

    missing_account_records,
    missing_close_value_records

FROM pipeline_summary;