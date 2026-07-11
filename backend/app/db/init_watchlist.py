import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(__file__), "watchlist.db")

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # Create tables
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS aml_watchlist (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            first_name TEXT,
            last_name TEXT,
            dob TEXT,
            risk_level TEXT
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS sanctions_list (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            first_name TEXT,
            last_name TEXT,
            dob TEXT,
            list_name TEXT
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS pep_list (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            first_name TEXT,
            last_name TEXT,
            dob TEXT,
            classification TEXT,
            country TEXT
        )
    """)

    # Clear existing data
    cursor.execute("DELETE FROM aml_watchlist")
    cursor.execute("DELETE FROM sanctions_list")
    cursor.execute("DELETE FROM pep_list")

    # Seed data
    aml_data = [
        ("John", "Doe", "1990-01-01", "HIGH"),
        ("Jane", "Smith", "1985-05-15", "MEDIUM"),
        ("Evil", "Corp", "1970-12-12", "HIGH"),
        ("Poison", "Ivy", "1992-10-31", "HIGH")
    ]
    
    sanctions_data = [
        ("Bad", "Guy", "1980-01-01", "OFAC"),
        ("Test", "Sanction", "1995-05-05", "UN"),
        ("Osama", "Bin Laden", "1957-03-10", "OFAC")
    ]
    
    pep_data = [
        ("Polity", "Pete", "1960-11-22", "HIGH", "US"),
        ("May", "Mayor", "1975-04-18", "MEDIUM", "UK"),
        ("Test", "Pep", "1988-08-08", "LOW", "CA")
    ]

    cursor.executemany("INSERT INTO aml_watchlist (first_name, last_name, dob, risk_level) VALUES (?, ?, ?, ?)", aml_data)
    cursor.executemany("INSERT INTO sanctions_list (first_name, last_name, dob, list_name) VALUES (?, ?, ?, ?)", sanctions_data)
    cursor.executemany("INSERT INTO pep_list (first_name, last_name, dob, classification, country) VALUES (?, ?, ?, ?, ?)", pep_data)

    conn.commit()
    conn.close()
    print("Database initialized and seeded successfully.")

if __name__ == "__main__":
    init_db()
