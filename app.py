import streamlit as st
import pandas as pd
import plotly.express as px
from src.database import run_query


# ============================================================
# PAGE CONFIGURATION
# ============================================================

st.set_page_config(
    page_title="Sales Intelligence",
    page_icon="📊",
    layout="wide"
)


# ============================================================
# CUSTOM CSS
# ============================================================

st.markdown(
    """
    <style>

    .main-title {
        font-size: 38px;
        font-weight: 700;
        margin-bottom: 5px;
    }

    .subtitle {
        font-size: 17px;
        color: #666;
        margin-bottom: 25px;
    }

    .section-title {
        font-size: 25px;
        font-weight: 650;
        margin-top: 25px;
        margin-bottom: 15px;
    }

    .insight-box {
        padding: 18px;
        border-radius: 10px;
        border: 1px solid #ddd;
        margin-bottom: 10px;
    }

    </style>
    """,
    unsafe_allow_html=True
)


# ============================================================
# HEADER
# ============================================================

st.markdown(
    '<div class="main-title">📊 Sales Revenue Intelligence</div>',
    unsafe_allow_html=True
)

st.markdown(
    """
    <div class="subtitle">
    B2B Sales Performance, Pipeline & Revenue Analytics
    </div>
    """,
    unsafe_allow_html=True
)


# ============================================================
# DATABASE CONNECTION TEST
# ============================================================

try:
    test_df = run_query("SELECT 1 AS connection_test")

    if test_df is None:
        st.error("Database connection failed.")
        st.stop()

except Exception as e:
    st.error(f"Database connection failed: {e}")
    st.stop()


# ============================================================
# LOAD CORE DATA
# ============================================================

@st.cache_data(ttl=300)
def load_core_data():

    query = """
    SELECT
        sp.opportunity_id,
        sp.sales_agent,
        sp.product,
        sp.account,
        sp.deal_stage,
        sp.engage_date,
        sp.close_date,
        sp.close_value,
        st.manager,
        st.regional_office,
        a.sector,
        a.office_location,
        a.employees,
        a.revenue AS account_revenue
    FROM sales_pipeline sp

    LEFT JOIN sales_teams st
        ON sp.sales_agent = st.sales_agent

    LEFT JOIN accounts a
        ON sp.account = a.account
    """

    return run_query(query)


df = load_core_data()

if df.empty:
    st.warning("No data returned from PostgreSQL.")
    st.stop()


# ============================================================
# DATA PREPARATION
# ============================================================

df["engage_date"] = pd.to_datetime(df["engage_date"], errors="coerce")
df["close_date"] = pd.to_datetime(df["close_date"], errors="coerce")

df["close_value"] = pd.to_numeric(
    df["close_value"],
    errors="coerce"
)

df["sales_cycle_days"] = (
    df["close_date"] - df["engage_date"]
).dt.days


# ============================================================
# SIDEBAR FILTERS
# ============================================================

st.sidebar.header("Dashboard Filters")

regions = sorted(
    df["regional_office"]
    .dropna()
    .unique()
    .tolist()
)

products = sorted(
    df["product"]
    .dropna()
    .unique()
    .tolist()
)

stages = sorted(
    df["deal_stage"]
    .dropna()
    .unique()
    .tolist()
)

selected_regions = st.sidebar.multiselect(
    "Region",
    regions,
    default=regions
)

selected_products = st.sidebar.multiselect(
    "Product",
    products,
    default=products
)

selected_stages = st.sidebar.multiselect(
    "Deal Stage",
    stages,
    default=stages
)


# ============================================================
# APPLY FILTERS
# ============================================================

filtered_df = df[
    df["regional_office"].isin(selected_regions)
    & df["product"].isin(selected_products)
    & df["deal_stage"].isin(selected_stages)
].copy()


if filtered_df.empty:
    st.warning("No opportunities match the selected filters.")
    st.stop()


# ============================================================
# KPI CALCULATIONS
# ============================================================

total_opportunities = len(filtered_df)

won_df = filtered_df[
    filtered_df["deal_stage"] == "Won"
]

lost_df = filtered_df[
    filtered_df["deal_stage"] == "Lost"
]

open_df = filtered_df[
    filtered_df["deal_stage"].isin(
        ["Prospecting", "Engaging"]
    )
]

won_opportunities = len(won_df)
lost_opportunities = len(lost_df)
open_opportunities = len(open_df)

won_revenue = won_df["close_value"].sum()

average_won_deal = (
    won_df["close_value"].mean()
    if not won_df.empty
    else 0
)

completed_opportunities = (
    won_opportunities + lost_opportunities
)

win_rate = (
    won_opportunities / completed_opportunities * 100
    if completed_opportunities > 0
    else 0
)

average_sales_cycle = (
    won_df["sales_cycle_days"].mean()
    if not won_df["sales_cycle_days"].dropna().empty
    else 0
)


# ============================================================
# KPI CARDS
# ============================================================

st.markdown(
    '<div class="section-title">Executive Overview</div>',
    unsafe_allow_html=True
)

col1, col2, col3, col4, col5 = st.columns(5)

with col1:
    st.metric(
        "Total Opportunities",
        f"{total_opportunities:,}"
    )

with col2:
    st.metric(
        "Won Revenue",
        f"${won_revenue:,.0f}"
    )

with col3:
    st.metric(
        "Win Rate",
        f"{win_rate:.2f}%"
    )

with col4:
    st.metric(
        "Open Opportunities",
        f"{open_opportunities:,}"
    )

with col5:
    st.metric(
        "Avg Won Deal",
        f"${average_won_deal:,.0f}"
    )


# ============================================================
# EXECUTIVE SUMMARY
# ============================================================

st.markdown(
    '<div class="section-title">Executive Summary</div>',
    unsafe_allow_html=True
)

summary_col1, summary_col2, summary_col3 = st.columns(3)

with summary_col1:

    st.info(
        f"""
        **Revenue Performance**

        Won revenue is **${won_revenue:,.0f}** across
        **{won_opportunities:,} won opportunities**.

        Average won deal value is
        **${average_won_deal:,.0f}**.
        """
    )


with summary_col2:

    st.info(
        f"""
        **Conversion Performance**

        The current completed-opportunity win rate is
        **{win_rate:.2f}%**.

        There are **{open_opportunities:,} open opportunities**
        requiring pipeline management.
        """
    )


with summary_col3:

    st.info(
        f"""
        **Sales Cycle**

        Average sales cycle for won opportunities is
        approximately **{average_sales_cycle:.1f} days**.

        This provides a benchmark for evaluating
        sales process efficiency.
        """
    )


# ============================================================
# REVENUE TREND
# ============================================================

st.markdown(
    '<div class="section-title">Revenue Trend</div>',
    unsafe_allow_html=True
)

monthly_revenue = (
    won_df
    .dropna(subset=["close_date"])
    .assign(
        month=lambda x:
        x["close_date"].dt.to_period("M").astype(str)
    )
    .groupby("month", as_index=False)
    .agg(
        won_revenue=("close_value", "sum"),
        won_opportunities=("opportunity_id", "count")
    )
)

if not monthly_revenue.empty:

    fig = px.line(
        monthly_revenue,
        x="month",
        y="won_revenue",
        markers=True,
        title="Monthly Won Revenue"
    )

    fig.update_layout(
        xaxis_title="Month",
        yaxis_title="Won Revenue",
        hovermode="x unified"
    )

    st.plotly_chart(
        fig,
        use_container_width=True
    )


# ============================================================
# PRODUCT PERFORMANCE
# ============================================================

st.markdown(
    '<div class="section-title">Product Performance</div>',
    unsafe_allow_html=True
)

product_summary = (
    filtered_df
    .groupby("product")
    .agg(
        total_opportunities=("opportunity_id", "count"),
        won_opportunities=(
            "deal_stage",
            lambda x: (x == "Won").sum()
        ),
        lost_opportunities=(
            "deal_stage",
            lambda x: (x == "Lost").sum()
        ),
        won_revenue=(
            "close_value",
            lambda x:
            x[filtered_df.loc[x.index, "deal_stage"] == "Won"].sum()
        )
    )
    .reset_index()
)

product_summary["completed_opportunities"] = (
    product_summary["won_opportunities"]
    + product_summary["lost_opportunities"]
)

product_summary["win_rate"] = (
    product_summary["won_opportunities"]
    /
    product_summary["completed_opportunities"]
    * 100
)

product_summary["revenue_per_opportunity"] = (
    product_summary["won_revenue"]
    /
    product_summary["total_opportunities"]
)


product_col1, product_col2 = st.columns(2)


with product_col1:

    fig = px.bar(
        product_summary.sort_values(
            "won_revenue",
            ascending=True
        ),
        x="won_revenue",
        y="product",
        orientation="h",
        title="Won Revenue by Product"
    )

    fig.update_layout(
        xaxis_title="Won Revenue",
        yaxis_title="Product"
    )

    st.plotly_chart(
        fig,
        use_container_width=True
    )


with product_col2:

    fig = px.bar(
        product_summary.sort_values(
            "win_rate",
            ascending=True
        ),
        x="win_rate",
        y="product",
        orientation="h",
        title="Win Rate by Product"
    )

    fig.update_layout(
        xaxis_title="Win Rate (%)",
        yaxis_title="Product"
    )

    st.plotly_chart(
        fig,
        use_container_width=True
    )


# ============================================================
# PRODUCT TABLE
# ============================================================

display_product = product_summary.copy()

display_product["won_revenue"] = display_product[
    "won_revenue"
].map(
    lambda x: f"${x:,.0f}"
)

display_product["win_rate"] = display_product[
    "win_rate"
].map(
    lambda x: f"{x:.2f}%"
)

display_product["revenue_per_opportunity"] = display_product[
    "revenue_per_opportunity"
].map(
    lambda x: f"${x:,.0f}"
)

st.dataframe(
    display_product[
        [
            "product",
            "total_opportunities",
            "won_opportunities",
            "lost_opportunities",
            "win_rate",
            "won_revenue",
            "revenue_per_opportunity"
        ]
    ],
    use_container_width=True,
    hide_index=True
)


# ============================================================
# REGIONAL PERFORMANCE
# ============================================================

st.markdown(
    '<div class="section-title">Regional Performance</div>',
    unsafe_allow_html=True
)

regional_summary = (
    filtered_df
    .groupby("regional_office")
    .agg(
        total_opportunities=("opportunity_id", "count"),

        won_opportunities=(
            "deal_stage",
            lambda x: (x == "Won").sum()
        ),

        lost_opportunities=(
            "deal_stage",
            lambda x: (x == "Lost").sum()
        ),

        won_revenue=(
            "close_value",
            lambda x:
            x[filtered_df.loc[x.index, "deal_stage"] == "Won"].sum()
        )
    )
    .reset_index()
)

regional_summary["completed_opportunities"] = (
    regional_summary["won_opportunities"]
    + regional_summary["lost_opportunities"]
)

regional_summary["win_rate"] = (
    regional_summary["won_opportunities"]
    /
    regional_summary["completed_opportunities"]
    * 100
)

regional_summary["revenue_per_opportunity"] = (
    regional_summary["won_revenue"]
    /
    regional_summary["total_opportunities"]
)


region_col1, region_col2 = st.columns(2)


with region_col1:

    fig = px.bar(
        regional_summary.sort_values(
            "won_revenue",
            ascending=True
        ),
        x="won_revenue",
        y="regional_office",
        orientation="h",
        title="Won Revenue by Region"
    )

    fig.update_layout(
        xaxis_title="Won Revenue",
        yaxis_title="Region"
    )

    st.plotly_chart(
        fig,
        use_container_width=True
    )


with region_col2:

    fig = px.bar(
        regional_summary.sort_values(
            "revenue_per_opportunity",
            ascending=True
        ),
        x="revenue_per_opportunity",
        y="regional_office",
        orientation="h",
        title="Revenue per Opportunity"
    )

    fig.update_layout(
        xaxis_title="Revenue per Opportunity",
        yaxis_title="Region"
    )

    st.plotly_chart(
        fig,
        use_container_width=True
    )


# ============================================================
# SALES PIPELINE
# ============================================================

st.markdown(
    '<div class="section-title">Sales Pipeline</div>',
    unsafe_allow_html=True
)

stage_summary = (
    filtered_df
    .groupby("deal_stage")
    .size()
    .reset_index(name="opportunities")
)

stage_order = [
    "Prospecting",
    "Engaging",
    "Won",
    "Lost"
]

stage_summary["sort_order"] = (
    stage_summary["deal_stage"]
    .map(
        {
            "Prospecting": 1,
            "Engaging": 2,
            "Won": 3,
            "Lost": 4
        }
    )
)

stage_summary = stage_summary.sort_values(
    "sort_order"
)

fig = px.bar(
    stage_summary,
    x="deal_stage",
    y="opportunities",
    title="Opportunity Funnel by Deal Stage",
    text="opportunities"
)

fig.update_layout(
    xaxis_title="Deal Stage",
    yaxis_title="Number of Opportunities"
)

st.plotly_chart(
    fig,
    use_container_width=True
)


# ============================================================
# OPEN PIPELINE BY PRODUCT
# ============================================================

open_pipeline = filtered_df[
    filtered_df["deal_stage"].isin(
        ["Prospecting", "Engaging"]
    )
]

if not open_pipeline.empty:

    pipeline_product = (
        open_pipeline
        .groupby("product")
        .size()
        .reset_index(
            name="open_opportunities"
        )
        .sort_values(
            "open_opportunities",
            ascending=False
        )
    )

    fig = px.bar(
        pipeline_product,
        x="product",
        y="open_opportunities",
        title="Open Opportunities by Product",
        text="open_opportunities"
    )

    fig.update_layout(
        xaxis_title="Product",
        yaxis_title="Open Opportunities"
    )

    st.plotly_chart(
        fig,
        use_container_width=True
    )


# ============================================================
# SALES PERSON PERFORMANCE
# ============================================================

st.markdown(
    '<div class="section-title">Salesperson Performance</div>',
    unsafe_allow_html=True
)

salesperson_summary = (
    filtered_df
    .groupby(
        [
            "sales_agent",
            "regional_office"
        ]
    )
    .agg(
        total_opportunities=("opportunity_id", "count"),

        won_opportunities=(
            "deal_stage",
            lambda x: (x == "Won").sum()
        ),

        lost_opportunities=(
            "deal_stage",
            lambda x: (x == "Lost").sum()
        ),

        open_opportunities=(
            "deal_stage",
            lambda x:
            x.isin(
                ["Prospecting", "Engaging"]
            ).sum()
        ),

        won_revenue=(
            "close_value",
            lambda x:
            x[
                filtered_df.loc[
                    x.index,
                    "deal_stage"
                ] == "Won"
            ].sum()
        )
    )
    .reset_index()
)

salesperson_summary["completed_opportunities"] = (
    salesperson_summary["won_opportunities"]
    +
    salesperson_summary["lost_opportunities"]
)

salesperson_summary["win_rate"] = (
    salesperson_summary["won_opportunities"]
    /
    salesperson_summary["completed_opportunities"]
    * 100
)

salesperson_summary["average_won_deal"] = (
    salesperson_summary["won_revenue"]
    /
    salesperson_summary["won_opportunities"]
)


sales_col1, sales_col2 = st.columns(2)


with sales_col1:

    top_salespeople = (
        salesperson_summary
        .sort_values(
            "won_revenue",
            ascending=False
        )
        .head(10)
    )

    fig = px.bar(
        top_salespeople.sort_values(
            "won_revenue"
        ),
        x="won_revenue",
        y="sales_agent",
        orientation="h",
        title="Top 10 Salespeople by Revenue"
    )

    fig.update_layout(
        xaxis_title="Won Revenue",
        yaxis_title="Salesperson"
    )

    st.plotly_chart(
        fig,
        use_container_width=True
    )


with sales_col2:

    top_win_rate = (
        salesperson_summary[
            salesperson_summary[
                "completed_opportunities"
            ] >= 30
        ]
        .sort_values(
            "win_rate",
            ascending=False
        )
        .head(10)
    )

    fig = px.bar(
        top_win_rate.sort_values(
            "win_rate"
        ),
        x="win_rate",
        y="sales_agent",
        orientation="h",
        title="Top 10 Salespeople by Win Rate"
    )

    fig.update_layout(
        xaxis_title="Win Rate (%)",
        yaxis_title="Salesperson"
    )

    st.plotly_chart(
        fig,
        use_container_width=True
    )


# ============================================================
# SALESPERSON TABLE
# ============================================================

display_salespeople = (
    salesperson_summary
    .sort_values(
        "won_revenue",
        ascending=False
    )
    .copy()
)

display_salespeople["won_revenue"] = (
    display_salespeople["won_revenue"]
    .map(lambda x: f"${x:,.0f}")
)

display_salespeople["average_won_deal"] = (
    display_salespeople["average_won_deal"]
    .map(lambda x: f"${x:,.0f}")
)

display_salespeople["win_rate"] = (
    display_salespeople["win_rate"]
    .map(lambda x: f"{x:.2f}%")
)

st.dataframe(
    display_salespeople[
        [
            "sales_agent",
            "regional_office",
            "total_opportunities",
            "open_opportunities",
            "won_opportunities",
            "lost_opportunities",
            "win_rate",
            "won_revenue",
            "average_won_deal"
        ]
    ],
    use_container_width=True,
    hide_index=True
)


# ============================================================
# ACCOUNT INTELLIGENCE
# ============================================================

st.markdown(
    '<div class="section-title">Account Intelligence</div>',
    unsafe_allow_html=True
)

account_summary = (
    filtered_df[
        filtered_df["account"].notna()
    ]
    .groupby("account")
    .agg(
        total_opportunities=("opportunity_id", "count"),

        won_opportunities=(
            "deal_stage",
            lambda x: (x == "Won").sum()
        ),

        open_opportunities=(
            "deal_stage",
            lambda x:
            x.isin(
                ["Prospecting", "Engaging"]
            ).sum()
        ),

        won_revenue=(
            "close_value",
            lambda x:
            x[
                filtered_df.loc[
                    x.index,
                    "deal_stage"
                ] == "Won"
            ].sum()
        )
    )
    .reset_index()
)

account_summary["completed_opportunities"] = (
    account_summary["total_opportunities"]
    -
    account_summary["open_opportunities"]
)

account_summary["win_rate"] = (
    account_summary["won_opportunities"]
    /
    account_summary["completed_opportunities"]
    * 100
)

account_summary["priority"] = "Monitor"

account_summary.loc[
    (
        account_summary["open_opportunities"] >= 10
    )
    &
    (
        account_summary["won_opportunities"] >= 50
    ),
    "priority"
] = "High Priority"

account_summary.loc[
    (
        account_summary["priority"] == "Monitor"
    )
    &
    (
        account_summary["open_opportunities"] >= 5
    )
    &
    (
        account_summary["won_opportunities"] >= 25
    ),
    "priority"
] = "Growth Opportunity"


priority_accounts = (
    account_summary[
        account_summary["priority"]
        != "Monitor"
    ]
    .sort_values(
        [
            "priority",
            "won_revenue"
        ],
        ascending=[True, False]
    )
)


st.dataframe(
    priority_accounts[
        [
            "account",
            "won_opportunities",
            "open_opportunities",
            "win_rate",
            "won_revenue",
            "priority"
        ]
    ],
    use_container_width=True,
    hide_index=True
)


# ============================================================
# SALES CYCLE ANALYSIS
# ============================================================

st.markdown(
    '<div class="section-title">Sales Cycle Analysis</div>',
    unsafe_allow_html=True
)

sales_cycle_df = filtered_df[
    (
        filtered_df["deal_stage"] == "Won"
    )
    &
    (
        filtered_df["sales_cycle_days"].notna()
    )
].copy()

if not sales_cycle_df.empty:

    cycle_summary = (
        sales_cycle_df
        .assign(
            cycle_bucket=lambda x:
            pd.cut(
                x["sales_cycle_days"],
                bins=[
                    0,
                    30,
                    60,
                    90,
                    float("inf")
                ],
                labels=[
                    "0-30 Days",
                    "31-60 Days",
                    "61-90 Days",
                    "90+ Days"
                ]
            )
        )
        .groupby(
            "cycle_bucket",
            observed=True
        )
        .agg(
            won_opportunities=(
                "opportunity_id",
                "count"
            ),
            average_deal_value=(
                "close_value",
                "mean"
            ),
            total_revenue=(
                "close_value",
                "sum"
            )
        )
        .reset_index()
    )

    cycle_col1, cycle_col2 = st.columns(2)

    with cycle_col1:

        fig = px.bar(
            cycle_summary,
            x="cycle_bucket",
            y="won_opportunities",
            title="Won Opportunities by Sales Cycle"
        )

        st.plotly_chart(
            fig,
            use_container_width=True
        )

    with cycle_col2:

        fig = px.bar(
            cycle_summary,
            x="cycle_bucket",
            y="average_deal_value",
            title="Average Deal Value by Sales Cycle"
        )

        st.plotly_chart(
            fig,
            use_container_width=True
        )


# ============================================================
# HIGH-VALUE DEALS
# ============================================================

st.markdown(
    '<div class="section-title">High-Value Won Deals</div>',
    unsafe_allow_html=True
)

high_value_deals = (
    won_df[
        won_df["close_value"].notna()
    ]
    .sort_values(
        "close_value",
        ascending=False
    )
    .head(15)
    [
        [
            "opportunity_id",
            "sales_agent",
            "product",
            "account",
            "close_date",
            "close_value"
        ]
    ]
    .copy()
)

high_value_deals["close_value"] = (
    high_value_deals["close_value"]
    .map(lambda x: f"${x:,.0f}")
)

st.dataframe(
    high_value_deals,
    use_container_width=True,
    hide_index=True
)


# ============================================================
# MANAGEMENT INSIGHTS
# ============================================================

st.markdown(
    '<div class="section-title">Management Insights</div>',
    unsafe_allow_html=True
)

# Best product
if not product_summary.empty:

    best_revenue_product = (
        product_summary
        .sort_values(
            "won_revenue",
            ascending=False
        )
        .iloc[0]
    )

    best_win_product = (
        product_summary
        .sort_values(
            "win_rate",
            ascending=False
        )
        .iloc[0]
    )

else:
    best_revenue_product = None
    best_win_product = None


# Best region
if not regional_summary.empty:

    best_region = (
        regional_summary
        .sort_values(
            "won_revenue",
            ascending=False
        )
        .iloc[0]
    )

    best_efficiency_region = (
        regional_summary
        .sort_values(
            "revenue_per_opportunity",
            ascending=False
        )
        .iloc[0]
    )

else:
    best_region = None
    best_efficiency_region = None


insight1, insight2 = st.columns(2)


with insight1:

    if best_revenue_product is not None:

        st.success(
            f"""
            **Product Insight**

            **{best_revenue_product['product']}** is the
            largest revenue contributor with
            **${best_revenue_product['won_revenue']:,.0f}**
            in won revenue.

            **{best_win_product['product']}** has the highest
            win rate at
            **{best_win_product['win_rate']:.2f}%**.
            """
        )


with insight2:

    if best_region is not None:

        st.success(
            f"""
            **Regional Insight**

            **{best_region['regional_office']}** generates the
            highest total won revenue at
            **${best_region['won_revenue']:,.0f}**.

            **{best_efficiency_region['regional_office']}** has
            the highest revenue per opportunity at
            **${best_efficiency_region['revenue_per_opportunity']:,.0f}**.
            """
        )


# ============================================================
# DATASET INFORMATION
# ============================================================

with st.expander("Dataset Information"):

    info_col1, info_col2, info_col3 = st.columns(3)

    with info_col1:
        st.metric(
            "Accounts",
            df["account"].nunique()
        )

    with info_col2:
        st.metric(
            "Products",
            df["product"].nunique()
        )

    with info_col3:
        st.metric(
            "Salespeople",
            df["sales_agent"].nunique()
        )

    st.write(
        f"""
        **Source:** PostgreSQL relational database

        **Pipeline records:** {len(df):,}

        **Tables:** accounts, products, sales_pipeline, sales_teams

        **Analytics:** SQL + PostgreSQL + Python + Streamlit + Plotly
        """
    )


# ============================================================
# FOOTER
# ============================================================

st.markdown("---")

st.caption(
    "Sales Revenue Intelligence | PostgreSQL + SQL + Python + Streamlit"
)