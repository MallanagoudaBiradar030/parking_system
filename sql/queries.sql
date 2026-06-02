-- ==========================================
-- DBMS Mini Project: Parking Lot Management System
-- Part 3: Standard DBMS Queries (queries.sql)
-- Author: DBMS Mini Project Student
-- ==========================================

USE parking_db;

-- -----------------------------------------------------------------------------
-- 1. DATA QUERY LANGUAGE (DQL) - SELECT & WHERE
-- Purpose: Find all active transactions for 'Car' vehicle types.
-- -----------------------------------------------------------------------------
SELECT 
    t.transaction_id, 
    v.license_plate, 
    v.vehicle_type, 
    t.entry_time
FROM 
    parking_transaction t
INNER JOIN 
    vehicle v ON t.vehicle_id = v.vehicle_id
WHERE 
    v.vehicle_type = 'Car' AND t.status = 'Active';


-- -----------------------------------------------------------------------------
-- 2. MULTI-TABLE INNER JOINs (3 Tables Joined)
-- Purpose: Extract complete dashboard report for currently parked vehicles.
-- Shows license, type, slot assigned, owner contact, and entry time.
-- -----------------------------------------------------------------------------
SELECT 
    t.transaction_id,
    v.license_plate,
    v.vehicle_type,
    s.slot_number,
    v.owner_name,
    v.owner_phone,
    t.entry_time
FROM 
    parking_transaction t
INNER JOIN 
    vehicle v ON t.vehicle_id = v.vehicle_id
INNER JOIN 
    parking_slot s ON t.slot_id = s.slot_id
WHERE 
    t.status = 'Active';


-- -----------------------------------------------------------------------------
-- 3. GROUP BY & AGGREGATIONS
-- Purpose: Extract monthly financial totals grouped by Month and Vehicle Type.
-- -----------------------------------------------------------------------------
SELECT 
    DATE_FORMAT(t.exit_time, '%Y-%m') AS billing_month,
    v.vehicle_type,
    COUNT(t.transaction_id) AS total_check_outs,
    SUM(t.fee) AS total_revenue_collected,
    AVG(t.fee) AS average_fee_per_vehicle
FROM 
    parking_transaction t
INNER JOIN 
    vehicle v ON t.vehicle_id = v.vehicle_id
WHERE 
    t.status = 'Completed'
GROUP BY 
    DATE_FORMAT(t.exit_time, '%Y-%m'), 
    v.vehicle_type
ORDER BY 
    billing_month DESC, 
    total_revenue_collected DESC;


-- -----------------------------------------------------------------------------
-- 4. SUBQUERY (In SELECT and WHERE clauses)
-- Purpose: Identify slot numbers that have hosted MORE transactions than the average.
-- -----------------------------------------------------------------------------
SELECT 
    s.slot_number,
    s.slot_type,
    (SELECT COUNT(*) FROM parking_transaction t WHERE t.slot_id = s.slot_id) AS transaction_count
FROM 
    parking_slot s
WHERE 
    (SELECT COUNT(*) FROM parking_transaction t WHERE t.slot_id = s.slot_id) > 
    (SELECT AVG(slot_usage.cnt) FROM (
        SELECT COUNT(*) AS cnt FROM parking_transaction GROUP BY slot_id
     ) AS slot_usage)
ORDER BY 
    transaction_count DESC;


-- -----------------------------------------------------------------------------
-- 5. SUBQUERY & LIMIT (Busiest Vehicle)
-- Purpose: Find details of the vehicle that has generated the highest cumulative fee.
-- -----------------------------------------------------------------------------
SELECT 
    vehicle_id, 
    license_plate, 
    vehicle_type, 
    owner_name
FROM 
    vehicle
WHERE 
    vehicle_id = (
        SELECT vehicle_id 
        FROM parking_transaction 
        GROUP BY vehicle_id 
        ORDER BY SUM(fee) DESC 
        LIMIT 1
    );


-- -----------------------------------------------------------------------------
-- 6. QUERYING A VIEW
-- Purpose: Querying the `vw_slot_utilization` view to fetch live percentage updates.
-- -----------------------------------------------------------------------------
SELECT 
    slot_type, 
    total_slots, 
    occupied_slots, 
    available_slots, 
    occupancy_rate_percent 
FROM 
    vw_slot_utilization;
