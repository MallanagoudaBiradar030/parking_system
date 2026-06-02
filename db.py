"""
DBMS Mini Project: Parking Lot Management System
Part 7: Database Connection Manager and Utilities (db.py)

This module handles connection pooling to the MySQL database and provides utility
functions for executing DDL, DML, and Stored Procedures. It also includes an automatic
database initialization routine to bootstrap the tables and sample data.
"""

import os
import mysql.connector
from mysql.connector import Error

# Database connection configuration (Can be customized or loaded from environment variables)
DB_HOST = os.environ.get('DB_HOST', 'localhost')
DB_USER = os.environ.get('DB_USER', 'root')
DB_PASSWORD = os.environ.get('DB_PASSWORD', '')  # Set your MySQL root password here
DB_NAME = os.environ.get('DB_NAME', 'parking_db')

def get_db_connection(include_database=True):
    """
    Establishes and returns a connection to the MySQL server.
    If include_database is True, it will attempt to connect directly to DB_NAME.
    """
    try:
        if include_database:
            connection = mysql.connector.connect(
                host="localhost",
                user="root",
                password="mriqmallu45",
                database="parking_db",
                autocommit=True
            )
        else:
            # Connect to server only (useful for database creation DDL)
            connection = mysql.connector.connect(
                host="localhost",
                user="root",
                password="mriqmallu45",
                autocommit=True
            )
        return connection
    except Error as e:
        print(f"Error connecting to MySQL: {e}")
        return None

def execute_query(query, params=None):
    """
    Executes an INSERT, UPDATE, or DELETE query and returns the last inserted ID.
    Used for write operations. Handles parameter binding to prevent SQL injection.
    """
    conn = get_db_connection()
    if not conn:
        raise Exception("Database connection failed.")
    
    cursor = conn.cursor()
    try:
        cursor.execute(query, params or ())
        last_id = cursor.lastrowid
        cursor.close()
        conn.close()
        return last_id
    except Error as e:
        cursor.close()
        conn.close()
        print(f"Database error during execute: {e}")
        raise e

def execute_read(query, params=None):
    """
    Executes a SELECT query and returns the result as a list of dictionaries.
    Dictionaries map column names to values, making it highly intuitive for Flask templates.
    """
    conn = get_db_connection()
    if not conn:
        raise Exception("Database connection failed.")
    
    # dictionary=True converts result tuples into Python dicts (e.g., row['license_plate'])
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(query, params or ())
        results = cursor.fetchall()
        cursor.close()
        conn.close()
        return results
    except Error as e:
        cursor.close()
        conn.close()
        print(f"Database error during read: {e}")
        raise e

def execute_stored_procedure(procedure_name, params=None):
    """
    Executes a Stored Procedure and returns the OUT parameters and cursor results.
    `params` should be a tuple or list of inputs/outputs matching the procedure signature.
    """
    conn = get_db_connection()
    if not conn:
        raise Exception("Database connection failed.")
    
    cursor = conn.cursor()
    try:
        # callproc returns a tuple containing the modified parameter list
        out_params = cursor.callproc(procedure_name, params or ())
        cursor.close()
        conn.close()
        return out_params
    except Error as e:
        cursor.close()
        conn.close()
        print(f"Database error during stored procedure call: {e}")
        raise e

def parse_and_execute_sql_file(file_path):
    """
    Reads an SQL file, strips comments/DELIMITER statements,
    and executes each statement sequentially.
    Crucial for automatic DB setup without requiring MySQL CLI.
    """
    if not os.path.exists(file_path):
        print(f"SQL file not found: {file_path}")
        return False
        
    print(f"Executing SQL file: {file_path}")
    conn = get_db_connection(include_database=False)
    if not conn:
        return False
        
    cursor = conn.cursor()
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            
        statements = []
        current_statement = []
        in_trigger_or_proc = False
        
        for line in lines:
            line_str = line.strip()
            
            # Skip comments and delimiter declarations
            if not line_str or line_str.startswith('--') or line_str.startswith('#') or line_str.startswith('DELIMITER'):
                continue
            
            current_statement.append(line)
            
            # Check for statement boundaries
            # Handle procedural delimiter '//'
            if '//' in line_str:
                statement_str = "".join(current_statement).replace('//', ';').strip()
                if statement_str:
                    statements.append(statement_str)
                current_statement = []
            elif ';' in line_str and not in_trigger_or_proc:
                # Standard SQL statements end with a semicolon
                statement_str = "".join(current_statement).strip()
                if statement_str:
                    statements.append(statement_str)
                current_statement = []
                
        # Execute each statement
        for stmt in statements:
            if stmt.strip():
                # If statement sets active DB, handle it
                if stmt.strip().upper().startswith("USE "):
                    db_target = stmt.strip().split()[1].replace(';', '')
                    cursor.execute(f"USE {db_target}")
                else:
                    cursor.execute(stmt)
                    
        cursor.close()
        conn.close()
        return True
    except Error as e:
        print(f"Error executing {file_path}: {e}")
        if 'cursor' in locals():
            cursor.close()
        if 'conn' in locals():
            conn.close()
        return False

def init_db():
    """
    Initializes the database by sequentially running:
    1. schema.sql
    2. sample_data.sql
    3. views.sql
    4. triggers.sql
    5. procedures.sql
    """
    print("Initializing Database Setup...")
    
    # 1. Connect without database context first to create database
    conn = get_db_connection(include_database=False)
    if not conn:
        print("CRITICAL: Cannot connect to MySQL server. Please check host, username, and password.")
        return False
    
    cursor = conn.cursor()
    try:
        cursor.execute("CREATE DATABASE IF NOT EXISTS parking_db;")
        cursor.close()
        conn.close()
    except Error as e:
        print(f"CRITICAL: Failed to create database: {e}")
        cursor.close()
        conn.close()
        return False

    # 2. Sequentially execute DDL and DML scripts
    base_dir = os.path.dirname(os.path.abspath(__file__))
    sql_dir = os.path.join(base_dir, 'sql')
    
    steps = [
        ('schema.sql', 'Tables and Indexes DDL Schema'),
        ('sample_data.sql', 'Initial seed data insertion'),
        ('views.sql', 'Aggregated reporting Views'),
        ('triggers.sql', 'Status automation Triggers'),
        ('procedures.sql', 'Atomic Stored Procedures')
    ]
    
    for filename, description in steps:
        path = os.path.join(sql_dir, filename)
        success = parse_and_execute_sql_file(path)
        if not success:
            print(f"CRITICAL: Failed during {description} setup ({filename}).")
            return False
            
    print("Database successfully initialized!")
    return True

if __name__ == '__main__':
    # When run directly, setup/recreate the entire database
    init_db()
