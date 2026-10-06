import psycopg2
import pandas as pd


# PostgreSQL connection settings
DB_CONFIG = {
    "host": "localhost",
    "database": "sales_intelligence",
    "user": "postgres",
    "password": "123",
    "port": "5432"
}


def get_connection():
    """Create and return a PostgreSQL database connection."""
    return psycopg2.connect(**DB_CONFIG)


def run_query(query):
    """Execute a SQL query and return the result as a Pandas DataFrame."""
    conn = get_connection()

    try:
        df = pd.read_sql_query(query, conn)
        return df

    finally:
        conn.close()