# B2B Sales Analytics

A SQL-driven sales analytics application for evaluating B2B sales pipeline, revenue, conversion, product and regional performance.

## Analysis
- Pipeline performance
- Revenue performance
- Win rate and conversion
- Product performance
- Regional performance
- Sales opportunity analysis

## Technology
- PostgreSQL
- SQL
- Python
- Pandas
- Plotly
- Streamlit
- psycopg2

## Database Configuration

Use environment variables for database credentials rather than storing passwords in source code.

Example:
```text
DB_HOST=localhost
DB_PORT=5432
DB_NAME=your_database
DB_USER=your_username
DB_PASSWORD=your_password
```

## Run
```bash
pip install -r requirements.txt
streamlit run app.py
```
