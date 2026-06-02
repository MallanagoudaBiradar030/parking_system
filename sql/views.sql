-- ==========================================
-- DBMS Mini Project: Parking Lot Management System
-- Part 4: Database Views (views.sql)
-- Author: DBMS Mini Project Student
-- ==========================================

USE parking_db;

-- Drop existing views to prevent creation conflicts
DROP VIEW IF EXISTS vw_currently_parked;
DROP VIEW IF EXISTS vw_slot_utilization;
DROP VIEW IF EXISTS vw_monthly_revenue_summary;

-- ------------------------------------------
-- View 1: vw_currently_parked
-- Joins Vehicle, ParkingSlot, and ParkingTransaction for currently active parkers.
-- Demonstrates multi-table INNER JOINs.
-- ------------------------------------------
CREATE VIEW vw_currently_parked AS
SELECT 
    t.transaction_id,
    v.vehicle_id,
    v.license_plate,
    v.vehicle_type,
    v.owner_name,
    v.owner_phone,
    s.slot_id,
    s.slot_number,
    t.entry_time
FROM 
    parking_transaction t
INNER JOIN 
    vehicle v ON t.vehicle_id = v.vehicle_id
INNER JOIN 
    parking_slot s ON t.slot_id = s.slot_id
WHERE 
    t.status = 'Active' AND t.exit_time IS NULL;

-- ------------------------------------------
-- View 2: vw_slot_utilization
-- Combines Slot aggregate counts to display utilization percentages.
-- Demonstrates Subqueries and Subquery columns in SELECT.
-- ------------------------------------------
CREATE VIEW vw_slot_utilization AS
SELECT 
    slot_type,
    COUNT(*) AS total_slots,
    SUM(CASE WHEN status = 'Occupied' THEN 1 ELSE 0 END) AS occupied_slots,
    SUM(CASE WHEN status = 'Available' THEN 1 ELSE 0 END) AS available_slots,
    ROUND((SUM(CASE WHEN status = 'Occupied' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS occupancy_rate_percent
FROM 
    parking_slot
GROUP BY 
    slot_type;

-- ------------------------------------------
-- View 3: vw_monthly_revenue_summary
-- Summarizes financial transactions grouped by Month and Vehicle Type.
-- Demonstrates GROUP BY, DATE formatting, and SUM functions.
-- ------------------------------------------
CREATE VIEW vw_monthly_revenue_summary AS
SELECT 
    DATE_FORMAT(exit_time, '%Y-%m') AS revenue_month,
    v.vehicle_type,
    COUNT(t.transaction_id) AS total_completed_trips,
    SUM(t.fee) AS monthly_revenue
FROM 
    parking_transaction t
INNER JOIN 
    vehicle v ON t.vehicle_id = v.vehicle_id
WHERE 
    t.status = 'Completed' AND t.exit_time IS NOT NULL
GROUP BY 
    DATE_FORMAT(exit_time, '%Y-%m'), v.vehicle_type;
