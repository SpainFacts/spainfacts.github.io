import requests
import pandas as pd
import duckdb
import os

# --- Configuration ---
MOTHERDUCK_TOKEN = os.getenv('motherduck_token')
DATABASE_NAME = 'SpainFacts'
BASE_URL = "https://servicios.ine.es/wstempus/js/ES/DATOS_TABLA/"

# Dictionary of indicators to fetch.
# Keys are the table names we'll use in our database.
# Values are their corresponding INE table identifiers.
INDICATORS = {
    'ipc': '50902',          # Índice de Precios de Consumo (IPC)
    'unemployment': '4920'   # Tasa de paro por sexo y grupo de edad
}

def load_ine_data_to_motherduck():
    """
    Connects to the INE API, downloads data, and loads it into MotherDuck.
    """
    if not MOTHERDUCK_TOKEN:
        print("Error: motherduck_token environment variable not set.")
        return

    try:
        # Connect to MotherDuck
        con = duckdb.connect(f'md:{DATABASE_NAME}?motherduck_token={MOTHERDUCK_TOKEN}')
        print(f"Successfully connected to MotherDuck database: {DATABASE_NAME}")

        for table_name, table_id in INDICATORS.items():
            print(f"\nProcessing data for '{table_name}' (ID: {table_id})...")

            # --- 1. Extract data from INE API ---
            print("Fetching data from INE...")
            response = requests.get(f"{BASE_URL}{table_id}")
            response.raise_for_status()
            data = response.json()
            print("Data fetched successfully.")

            # --- 2. Transform data ---
            print("Transforming data...")
            if not data or 'Data' not in data[0]:
                print(f"Warning: No data found for '{table_name}' in the response.")
                continue

            latest_series = data[-1]['Data']
            df = pd.DataFrame(latest_series)

            df = df.rename(columns={'Fecha': 'date', 'Valor': 'value'})
            df['date'] = pd.to_datetime(df['date'], unit='ms')
            df['value'] = pd.to_numeric(df['value'])
            print("Data transformed successfully.")

            # --- 3. Load data to MotherDuck ---
            print(f"Loading data into MotherDuck table: {table_name}...")
            # Use CREATE OR REPLACE TABLE to make the operation idempotent
            # Use CREATE OR REPLACE TABLE to make the operation idempotent
            con.execute(f"CREATE OR REPLACE TABLE {table_name} AS SELECT * FROM df")
            print(f"Successfully loaded data into '{table_name}'.")

        print("\nVerifying all tables in the database...")
        all_tables = con.execute("SHOW TABLES").fetchall()
        print("Tables currently in database:")
        for table in all_tables:
            print(f"- {table[0]}")

        con.close()
        print("\nProcess complete. Connection closed.")

    except requests.exceptions.RequestException as e:
        print(f"Error fetching data from INE: {e}")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")

if __name__ == "__main__":
    load_ine_data_to_motherduck()