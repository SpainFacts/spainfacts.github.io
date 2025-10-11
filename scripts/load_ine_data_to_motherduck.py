import requests
import pandas as pd
import duckdb
import os

# --- Configuration ---
MOTHERDUCK_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6InNhbmp1YW5qb3JAZ21haWwuY29tIiwic2Vzc2lvbiI6InNhbmp1YW5qb3IuZ21haWwuY29tIiwicGF0IjoidHRUbzJacVJVV0ZkNE1FU3hxanNydHpyY2FSbEg3N19TeTN0NGhvYnliOCIsInVzZXJJZCI6ImNlMjU1MTlmLTQ1NmQtNDBlMy04MzY2LWM5MzlkYTEzMDVmMyIsImlzcyI6Im1kX3BhdCIsInJlYWRPbmx5IjpmYWxzZSwidG9rZW5UeXBlIjoicmVhZF93cml0ZSIsImlhdCI6MTc1OTkyODM3NX0.m_0VatsTyy2Uw3I9kgIGIoWnFI69ZSCf9ZXb9k1VFNo"
DATABASE_NAME = 'SpainFacts'
BASE_URL = "https://servicios.ine.es/wstempus/js/ES/DATOS_TABLA/"
BASE_URL="https://www.ine.es/wstempus/csv_sc/es/DATOS_TABLA/"
INDICATORS = {
    'ipc': '50902',          # Índice de Precios de Consumo (IPC)
    'unemployment': '65292'  # Tasa de paro por sexo y grupo de edad
}

def load_ine_data_to_motherduck():
    """
    Connects to the INE API, downloads data, and loads it into MotherDuck without renaming columns.
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

            # Print available columns for debugging
            print(f"Available columns in DataFrame for '{table_name}': {list(df.columns)}")

            # Handle data types without renaming columns
            if 'Fecha' in df.columns:
                df['Fecha'] = pd.to_datetime(df['Fecha'], unit='ms')
            if 'Valor' in df.columns:
                df['Valor'] = pd.to_numeric(df['Valor'], errors='coerce')

            # Convert other columns to string to ensure compatibility (modify as needed)
            for col in df.columns:
                if col not in ['Fecha', 'Valor']:
                    df[col] = df[col].astype(str)

            print("Data transformed successfully.")

            # --- 3. Load data to MotherDuck ---
            print(f"Loading data into MotherDuck table: {table_name}...")
            # Use CREATE OR REPLACE TABLE to make the operation idempotent
            con.execute(f"CREATE OR REPLACE TABLE {table_name} AS SELECT * FROM df")
            print(f"Successfully loaded data into '{table_name}'.")

            # Verify table schema
            schema = con.execute(f"DESCRIBE {table_name}").fetchall()
            print(f"Schema for table '{table_name}':")
            for col in schema:
                print(f"- {col[0]} ({col[1]})")

        # Verify all tables in the database
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