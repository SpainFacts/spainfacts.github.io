import duckdb
import os

def list_tables():
    """
    Connects to the MotherDuck database and lists all tables.
    """
    token = os.getenv('motherduck_token')
    if not token:
        print("Error: motherduck_token environment variable not set.")
        return

    try:
        # Connect to MotherDuck, specifying the database name
        con = duckdb.connect(f'md:SpainFacts?motherduck_token={token}')

        print("Successfully connected to MotherDuck database: SpainFacts")

        # Query to list all tables
        tables = con.execute("SHOW TABLES").fetchall()

        if tables:
            print("\nTables found in the database:")
            for table in tables:
                print(f"- {table[0]}")
        else:
            print("\nNo tables found in the database.")

        con.close()

    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    list_tables()