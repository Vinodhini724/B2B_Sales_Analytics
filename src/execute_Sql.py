import sys
import os
import psycopg2
import pandas as pd


# ============================================================
# DATABASE CONFIGURATION
# ============================================================

DB_CONFIG = {
    "host": "localhost",
    "database": "sales_intelligence",
    "user": "postgres",
    "password": "123",
    "port": "5432"
}



# ============================================================
# SQL DIRECTORY
# ============================================================

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SQL_DIR = os.path.join(BASE_DIR, "sql")


# ============================================================
# DATABASE CONNECTION
# ============================================================

def get_connection():
    return psycopg2.connect(**DB_CONFIG)


# ============================================================
# LOAD SQL FILE
# ============================================================

def load_sql_file(filename):

    filepath = os.path.join(SQL_DIR, filename)

    if not os.path.exists(filepath):
        print(f"\nERROR: SQL file not found:")
        print(filepath)
        sys.exit(1)

    with open(filepath, "r", encoding="utf-8") as file:
        return file.read()


# ============================================================
# EXECUTE SQL QUERY
# ============================================================

def execute_query(conn, query):

    query = query.strip()

    if not query:
        return

    # Remove leading comments to identify query type
    lines = []

    for line in query.splitlines():

        stripped = line.strip()

        if stripped and not stripped.startswith("--"):
            lines.append(stripped)

    if not lines:
        return

    clean_query = " ".join(lines)
    query_type = clean_query.split()[0].upper()

    cursor = conn.cursor()

    try:

        # ====================================================
        # SELECT QUERY
        # ====================================================

        if query_type in ["SELECT", "WITH"]:

            df = pd.read_sql_query(query, conn)

            if df.empty:
                print("No rows returned.")

            else:
                print(df.to_string(index=False))


        # ====================================================
        # DATABASE MODIFICATION
        # ====================================================

        else:

            cursor.execute(query)

            conn.commit()

            print(f"SUCCESS: {query_type} executed successfully.")

            if cursor.rowcount >= 0:
                print(f"Rows affected: {cursor.rowcount}")


    except Exception as e:

        conn.rollback()

        print("ERROR:")
        print(e)


    finally:

        cursor.close()


# ============================================================
# EXECUTE SQL FILE
# ============================================================

def execute_sql_file(filename):

    print("\n" + "=" * 80)
    print(f"EXECUTING: {filename}")
    print("=" * 80)

    sql = load_sql_file(filename)

    # Split SQL file into individual statements
    queries = sql.split(";")

    conn = get_connection()

    try:

        query_number = 1

        for query in queries:

            query = query.strip()

            if not query:
                continue

            print("\n" + "-" * 80)
            print(f"QUERY {query_number}")
            print("-" * 80)

            execute_query(conn, query)

            query_number += 1

    finally:

        conn.close()

    print("\n" + "=" * 80)
    print("EXECUTION COMPLETE")
    print("=" * 80)


# ============================================================
# MAIN
# ============================================================

def main():

    if len(sys.argv) != 2:

        print("\nUsage:")
        print("python src/execute_Sql.py <sql_file_number>")

        print("\nExamples:")
        print("python src/execute_Sql.py 01")
        print("python src/execute_Sql.py 02")
        print("python src/execute_Sql.py 04")

        sys.exit(1)

    number = sys.argv[1]

    try:
        number = f"{int(number)}"

    except ValueError:

        print("ERROR: Enter a valid SQL file number.")
        sys.exit(1)

    matching_files = [
        file
        for file in os.listdir(SQL_DIR)
        if file.startswith(number + "_") and file.endswith(".sql")
    ]

    if not matching_files:

        print(f"\nERROR: No SQL file found starting with '{number}_'")

        print("\nAvailable SQL files:")

        for file in sorted(os.listdir(SQL_DIR)):

            if file.endswith(".sql"):
                print(" ", file)

        sys.exit(1)

    filename = matching_files[0]

    execute_sql_file(filename)


if __name__ == "__main__":
    main()