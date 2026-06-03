"""
DBMS Mini Project: Parking Lot Management System
Part 8: Main Flask Application Core (app.py)

This file contains the complete routing structure and backend business logic.
It implements operator sessions, CRUD database operations, and calls SQL Stored
Procedures, Views, and Triggers through parameterized queries to ensure security
against SQL injection.

DBMS Concepts Demonstrated in this File:
1. Data Query Language (DQL) - Standard SELECT queries with dynamic parameters.
2. Stored Procedures - Atomic calls to `sp_park_vehicle` and `sp_check_out_vehicle`.
3. Database Views - Querying aggregated data using `vw_currently_parked` and `vw_slot_utilization`.
4. Referential Integrity - Managing Cascade deletions and foreign key checks.
"""

import os
import hashlib
from functools import wraps
from flask import Flask, render_template, request, redirect, url_for, session, flash, jsonify
import mysql.connector

# Import database helpers
import db

app = Flask(__name__)

# Secret key for encrypting sessions (essential for session-based user authentication)
app.secret_key = os.environ.get('FLASK_SECRET_KEY', 'parking_system_secure_secret_key_123')

# -----------------------------------------------------------------------------
# Decorator: Operator Login Required
# Ensures only logged-in system operators can access admin routes
# -----------------------------------------------------------------------------
def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            flash("Unauthorized Access! Please log in to proceed.", "danger")
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

# -----------------------------------------------------------------------------
# Utility: Password Hash Match Check
# Matches hashed input with SHA-256 database password hashes
# -----------------------------------------------------------------------------
def hash_password(password):
    return hashlib.sha256(password.encode('utf-8')).hexdigest()

# -----------------------------------------------------------------------------
# Route: Operator Login Page
# Demonstrates DQL (User authentication and lookup)
# -----------------------------------------------------------------------------
@app.route('/login', methods=['GET', 'POST'])
def login():
    # If operator is already logged in, redirect to dashboard
    if 'user_id' in session:
        return redirect(url_for('dashboard'))
        
    if request.method == 'POST':
        username = request.form.get('username', '').strip()
        password = request.form.get('password', '').strip()
        
        if not username or not password:
            flash("Please enter both username and password.", "warning")
            return render_template('login.html')
            
        # Hash the input password to match against stored SHA-256 database values
        hashed_input = hash_password(password)
        
        # DQL Query to authenticate
        query = "SELECT user_id, username, full_name FROM user WHERE username = %s AND password = %s"
        try:
            users = db.execute_read(query, (username, hashed_input))
            if users:
                # Establish Flask Session values
                session['user_id'] = users[0]['user_id']
                session['username'] = users[0]['username']
                session['full_name'] = users[0]['full_name']
                flash(f"Welcome back, {users[0]['full_name']}!", "success")
                return redirect(url_for('dashboard'))
            else:
                flash("Invalid Username or Password.", "danger")
        except Exception as e:
            flash("Database connection error. Please verify database configuration.", "danger")
            print(f"Login error: {e}")
            
    return render_template('login.html')

# -----------------------------------------------------------------------------
# Route: Operator Logout
# Clears active user session
# -----------------------------------------------------------------------------
@app.route('/logout')
def logout():
    session.clear()
    flash("You have successfully logged out.", "success")
    return redirect(url_for('login'))

# -----------------------------------------------------------------------------
# Route: Admin Dashboard
# Demonstrates Joins, Aggregations (GROUP BY), and querying Views
# -----------------------------------------------------------------------------
@app.route('/')
@login_required
def dashboard():
    try:
        # 1. Fetch overall Slot counts using aggregate COUNT & SUM on parking_slot table
        slots_query = """
            SELECT 
                COUNT(*) as total_slots,
                SUM(CASE WHEN status = 'Occupied' THEN 1 ELSE 0 END) as occupied_slots,
                SUM(CASE WHEN status = 'Available' THEN 1 ELSE 0 END) as available_slots
            FROM parking_slot;
        """
        slots_data = db.execute_read(slots_query)[0]
        
        # 2. Fetch today's cumulative revenue using aggregate SUM on parking_transaction table
        revenue_query = """
            SELECT COALESCE(SUM(fee), 0.00) as today_revenue 
            FROM parking_transaction 
            WHERE DATE(exit_time) = CURDATE() AND status = 'Completed';
        """
        revenue_data = db.execute_read(revenue_query)[0]
        
        # 3. Querying Database View: Get slot utilization stats per vehicle type
        utilization_stats = db.execute_read("SELECT * FROM vw_slot_utilization;")
        
        # 4. Fetch recent 5 transactions using INNER JOINs across 3 tables
        recent_transactions_query = """
            SELECT 
                t.transaction_id,
                v.license_plate,
                v.vehicle_type,
                s.slot_number,
                t.entry_time,
                t.exit_time,
                t.fee,
                t.status
            FROM parking_transaction t
            INNER JOIN vehicle v ON t.vehicle_id = v.vehicle_id
            INNER JOIN parking_slot s ON t.slot_id = s.slot_id
            ORDER BY t.entry_time DESC
            LIMIT 5;
        """
        recent_transactions = db.execute_read(recent_transactions_query)
        
        # Prepare context variables for rendering
        kpi_metrics = {
            'total': slots_data['total_slots'] or 0,
            'occupied': slots_data['occupied_slots'] or 0,
            'available': slots_data['available_slots'] or 0,
            'revenue': revenue_data['today_revenue'] or 0.00
        }
        
        return render_template(
            'dashboard.html', 
            kpis=kpi_metrics, 
            utilization=utilization_stats, 
            recent=recent_transactions
        )
    except Exception as e:
        flash("Error loading dashboard metrics.", "danger")
        print(f"Dashboard Load Error: {e}")
        return render_template('dashboard.html', kpis={'total':0, 'occupied':0, 'available':0, 'revenue':0.0}, utilization=[], recent=[])

# -----------------------------------------------------------------------------
# Route: Vehicle Entry (Check-In)
# Demonstrates Stored Procedures (Writes vehicle metadata and allocates slots)
# -----------------------------------------------------------------------------
@app.route('/entry', methods=['GET', 'POST'])
@login_required
def vehicle_entry():
    # Fetch available slot categories counts to display on the entry form
    slots_summary = db.execute_read("SELECT * FROM vw_slot_utilization;")
    
    if request.method == 'POST':
        license_plate = request.form.get('license_plate', '').strip().upper()
        vehicle_type = request.form.get('vehicle_type', '').strip()
        owner_name = request.form.get('owner_name', '').strip() or 'Unknown'
        owner_phone = request.form.get('owner_phone', '').strip() or 'N/A'
        
        if not license_plate or not vehicle_type:
            flash("License Plate and Vehicle Type are mandatory fields.", "warning")
            return render_template('entry.html', slots_summary=slots_summary)
            
        try:
            # CALL Stored Procedure: sp_park_vehicle
            # Parameters: p_license_plate, p_vehicle_type, p_owner_name, p_owner_phone, OUT p_slot_number, OUT p_transaction_id
            # In Python mysql-connector, OUT parameters must be provided placeholders
            proc_params = [license_plate, vehicle_type, owner_name, owner_phone, '', 0]
            out_results = db.execute_stored_procedure('sp_park_vehicle', proc_params)
            
            allocated_slot = out_results[4] # OUT p_slot_number
            transaction_id = out_results[5] # OUT p_transaction_id
            
            # Note: Database Trigger 'trg_after_transaction_insert' automatically marks the slot as 'Occupied'
            
            flash(f"Success! Vehicle parked in slot {allocated_slot}. (Transaction ID: {transaction_id})", "success")
            return redirect(url_for('currently_parked'))
        except mysql.connector.Error as db_err:
            # Catch custom triggers/procedure SIGNAL error messages
            flash(f"Check-In Failed: {db_err.msg}", "danger")
        except Exception as e:
            flash("An unexpected error occurred during vehicle entry.", "danger")
            print(f"Vehicle Entry Error: {e}")
            
    return render_template('entry.html', slots_summary=slots_summary)

# -----------------------------------------------------------------------------
# Route: Vehicle Exit (Check-Out)
# Demonstrates Stored Procedures & Automatic Pricing Fee calculation
# -----------------------------------------------------------------------------
@app.route('/exit', methods=['GET', 'POST'])
@login_required
def vehicle_exit():
    # Fetch all active parked vehicles to fill the selection dropdown
    active_parkers = db.execute_read("SELECT * FROM vw_currently_parked ORDER BY slot_number ASC;")
    
    if request.method == 'POST':
        transaction_id = request.form.get('transaction_id')
        
        if not transaction_id:
            flash("Please select a vehicle to check out.", "warning")
            return redirect(url_for('vehicle_exit'))
            
        try:
            # CALL Stored Procedure: sp_check_out_vehicle
            # Parameters: IN p_transaction_id, OUT p_license_plate, OUT p_slot_number, OUT p_entry_time, OUT p_exit_time, OUT p_fee
            proc_params = [int(transaction_id), '', '', '', '', 0.0]
            out_results = db.execute_stored_procedure('sp_check_out_vehicle', proc_params)
            
            plate = out_results[1]       # OUT p_license_plate
            slot = out_results[2]        # OUT p_slot_number
            entry_t = out_results[3]     # OUT p_entry_time
            exit_t = out_results[4]      # OUT p_exit_time
            fee_calculated = out_results[5] # OUT p_fee
            
            # Note: Database Trigger 'trg_after_transaction_update' automatically marks the slot as 'Available'
            
            flash_msg = (
                f"Checkout Complete! Vehicle {plate} released from Slot {slot}. "
                f"Parked since {entry_t}. Exit Time: {exit_t}. "
                f"Total Calculated Fee: ${fee_calculated:,.2f}"
            )
            flash(flash_msg, "success")
            return redirect(url_for('dashboard'))
            
        except mysql.connector.Error as db_err:
            flash(f"Check-Out Failed: {db_err.msg}", "danger")
        except Exception as e:
            flash("An unexpected error occurred during vehicle exit.", "danger")
            print(f"Vehicle Exit Error: {e}")
            
    return render_template('exit.html', parkers=active_parkers)

# -----------------------------------------------------------------------------
# Route: Parking Slots Visual Map
# Demonstrates DQL (Retrieves visual representation of all slots in the system)
# -----------------------------------------------------------------------------
@app.route('/slots')
@login_required
def slots_map():
    try:
        # Retrieve all slot records ordered alphabetically by slot code (e.g. B-01, C-01)
        slots = db.execute_read("SELECT * FROM parking_slot ORDER BY slot_number ASC;")
        return render_template('slots.html', slots=slots)
    except Exception as e:
        flash("Error loading parking slots layout map.", "danger")
        print(f"Slots Map Error: {e}")
        return render_template('slots.html', slots=[])

# -----------------------------------------------------------------------------
# Route: Currently Parked Vehicles Ledger
# Demonstrates querying Database Views (vw_currently_parked)
# -----------------------------------------------------------------------------
@app.route('/parked')
@login_required
def currently_parked():
    try:
        # Querying the view directly simplifies the multi-table joins on Python end
        parkers = db.execute_read("SELECT * FROM vw_currently_parked ORDER BY entry_time DESC;")
        return render_template('parked.html', parkers=parkers)
    except Exception as e:
        flash("Error fetching parked vehicles roster.", "danger")
        print(f"Parked List Error: {e}")
        return render_template('parked.html', parkers=[])

# -----------------------------------------------------------------------------
# Route: Monthly Revenue Reports
# Demonstrates Joins, GROUP BY aggregations, and data preparation for charting
# -----------------------------------------------------------------------------
@app.route('/revenue')
@login_required
def revenue_report():
    try:
        # Fetch the monthly revenue aggregated using vw_monthly_revenue_summary View
        revenue_summary = db.execute_read("SELECT * FROM vw_monthly_revenue_summary ORDER BY revenue_month DESC;")
        
        # Prepare charts data: Group total revenue per month for Chart.js display
        chart_query = """
            SELECT 
                DATE_FORMAT(exit_time, '%b %Y') as month_label,
                SUM(fee) as total_earnings
            FROM parking_transaction
            WHERE status = 'Completed'
            GROUP BY DATE_FORMAT(exit_time, '%Y-%m'), DATE_FORMAT(exit_time, '%b %Y')
            ORDER BY DATE_FORMAT(exit_time, '%Y-%m') ASC
            LIMIT 12;
        """
        chart_data = db.execute_read(chart_query)
        
        # Format structures for JS insertion
        labels = [row['month_label'] for row in chart_data]
        earnings = [float(row['total_earnings']) for row in chart_data]
        
        return render_template(
            'revenue.html', 
            reports=revenue_summary, 
            labels=labels, 
            earnings=earnings
        )
    except Exception as e:
        flash("Error aggregating monthly revenue reports.", "danger")
        print(f"Revenue Report Error: {e}")
        return render_template('revenue.html', reports=[], labels=[], earnings=[])

# -----------------------------------------------------------------------------
# Route: DBMS Project Integrated Documentation
# Renders college project report detailing Abstract, ERD, Schema, Normalization
# -----------------------------------------------------------------------------
@app.route('/docs')
def documentation():
    return render_template('documentation.html')

# -----------------------------------------------------------------------------
# Flask Application Bootstrapper Hook
# Automatic database setup checking on server boot!
# -----------------------------------------------------------------------------
def initialize_system():
    """
    Validates connection to the database. If tables do not exist,
    it automatically runs the database initializer scripts to bootstrap the system.
    """
    print("Verifying database schema connection...")
    try:
        # Check if the database and users table exists by running a quick count
        db.execute_read("SELECT COUNT(*) FROM user;")
        print("Database verification complete. Schema loaded correctly.")
    except Exception:
        print("Database not initialized or empty. Executing schema and data seeds...")
        success = db.init_db()
        if success:
            print("Database successfully bootstrapped on startup!")
        else:
            print("WARNING: Database setup failed on startup. Please verify local MySQL configurations.")

if __name__ == '__main__':
    # Initialize/Bootstrap Database before launching Flask dev server
    initialize_system()
    
    # Run Flask development server
    # Runs on standard local host port 5000. Easy to test on Linux Mint.
    app.run(host='0.0.0.0', port=5000, debug=True)
