import duckdb
import json
import os

def load_data_to_motherduck():
    # Get the MotherDuck token from the environment variable
    motherduck_token = os.getenv('motherduck_token')
    if not motherduck_token:
        raise ValueError("motherduck_token environment variable not set")

    # Connect to MotherDuck
    con = duckdb.connect(f'md:SpainFacts?motherduck_token={motherduck_token}')

    # Load the cleaned data from the JSON file
    with open('scripts/observatorios_cleaned.json', 'r') as f:
        data = json.load(f)

    # Create a table and insert the data
    con.execute("CREATE OR REPLACE TABLE observatorios (name VARCHAR, creation_year INTEGER, is_active BOOLEAN, scope VARCHAR)")

    # Use a prepared statement to insert data
    for row in data:
        con.execute("INSERT INTO observatorios VALUES (?, ?, ?, ?)", [row['name'], row['creation_year'], row['is_active'], row['scope']])

    con.close()

if __name__ == "__main__":
    load_data_to_motherduck()