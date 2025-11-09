import duckdb
import json
import os

def load_data_to_motherduck():
    # Get the MotherDuck token from the environment variable
    motherduck_token ="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6InNhbmp1YW5qb3JAZ21haWwuY29tIiwic2Vzc2lvbiI6InNhbmp1YW5qb3IuZ21haWwuY29tIiwicGF0IjoiUFdTODhQaDNLZktDRzBKeFBkbHpwei1Ec0V0bkxrbWtUeXExRXVjR3FNQSIsInVzZXJJZCI6ImNlMjU1MTlmLTQ1NmQtNDBlMy04MzY2LWM5MzlkYTEzMDVmMyIsImlzcyI6Im1kX3BhdCIsInJlYWRPbmx5IjpmYWxzZSwidG9rZW5UeXBlIjoicmVhZF93cml0ZSIsImlhdCI6MTc1NjE0MTg2OX0.T3o2iFg44fbs_4-tbYBg-Xler4ILxsBb9WpZFOAZoX8" #os.getenv('motherduck_token')
    if not motherduck_token:
        raise ValueError("motherduck_token environment variable not set")

    # Connect to MotherDuck
    con = duckdb.connect(f'md:SpainFacts?motherduck_token={motherduck_token}')

    # Load the cleaned data from the JSON file
    with open('./observatorios_cleaned.json', 'r') as f:
        data = json.load(f)

    # Create a table and insert the data
    con.execute("CREATE OR REPLACE TABLE observatorios (name VARCHAR, creation_year INTEGER, is_active BOOLEAN, scope VARCHAR)")

    # Use a prepared statement to insert data
    for row in data:
        con.execute("INSERT INTO observatorios VALUES (?, ?, ?, ?)", [row['name'], row['creation_year'], row['is_active'], row['scope']])

    con.close()

if __name__ == "__main__":
    load_data_to_motherduck()