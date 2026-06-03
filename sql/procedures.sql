-- ==========================================
-- DBMS Mini Project: Parking Lot Management System
-- Part 6: Database Stored Procedures (procedures.sql)
-- Author: DBMS Mini Project Student
-- ==========================================

USE parking_db;

-- Drop existing procedures to avoid creation collisions
DROP PROCEDURE IF EXISTS sp_park_vehicle;
DROP PROCEDURE IF EXISTS sp_check_out_vehicle;

DELIMITER //

-- -----------------------------------------------------------------------------
-- Stored Procedure 1: sp_park_vehicle
-- Objective: Atomic entry handling for a vehicle.
-- Description:
--   1. Check if the vehicle already exists in the 'vehicle' table.
--      If not, insert it; if yes, retrieve its vehicle_id.
--   2. Check if the vehicle is already parked (active transaction exists).
--      If yes, raise an exception.
--   3. Find the first available slot corresponding to the vehicle's type.
--      If no slot is available, raise an exception.
--   4. Insert the active transaction. The trigger trg_after_transaction_insert
--      will automatically update the slot's status to 'Occupied'.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_park_vehicle (
    IN p_license_plate VARCHAR(20),
    IN p_vehicle_type VARCHAR(20),
    IN p_owner_name VARCHAR(100),
    IN p_owner_phone VARCHAR(15),
    OUT p_slot_number VARCHAR(10),
    OUT p_transaction_id INT
)
BEGIN
    DECLARE v_vehicle_id INT DEFAULT NULL;
    DECLARE v_slot_id INT DEFAULT NULL;
    DECLARE v_active_count INT DEFAULT 0;
    DECLARE v_not_found BOOLEAN DEFAULT FALSE;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_not_found = TRUE;

    -- 1. Upsert Vehicle: Check if vehicle exists
    SELECT vehicle_id INTO v_vehicle_id
    FROM vehicle
    WHERE license_plate = p_license_plate
    LIMIT 1;

    IF v_not_found THEN
        SET v_not_found = FALSE;
        SET v_vehicle_id = NULL;
    END IF;

    IF v_vehicle_id IS NULL THEN
        -- Insert new vehicle if not found
        INSERT INTO vehicle (license_plate, vehicle_type, owner_name, owner_phone)
        VALUES (p_license_plate, p_vehicle_type, p_owner_name, p_owner_phone);
        SET v_vehicle_id = LAST_INSERT_ID();
    ELSE
        -- Update details in case they changed
        UPDATE vehicle
        SET owner_name = p_owner_name, owner_phone = p_owner_phone
        WHERE vehicle_id = v_vehicle_id;
    END IF;

    -- 2. Prevent Double Parking: Check if already parked
    SELECT COUNT(*) INTO v_active_count
    FROM parking_transaction
    WHERE vehicle_id = v_vehicle_id AND status = 'Active';

    IF v_active_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Vehicle is already checked into the parking lot.';
    END IF;

    -- 3. Slot Assignment: Find first available slot of matching type
    SELECT slot_id, slot_number INTO v_slot_id, p_slot_number
    FROM parking_slot
    WHERE slot_type = p_vehicle_type AND status = 'Available'
    ORDER BY slot_number ASC
    LIMIT 1;

    IF v_not_found THEN
        SET v_slot_id = NULL;
        SET v_not_found = FALSE;
    END IF;

    IF v_slot_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No available slots found for this vehicle type.';
    END IF;

    -- 4. Create Transaction: Insert into transaction table
    INSERT INTO parking_transaction (vehicle_id, slot_id, entry_time, status)
    VALUES (v_vehicle_id, v_slot_id, NOW(), 'Active');
    
    SET p_transaction_id = LAST_INSERT_ID();
END //


-- -----------------------------------------------------------------------------
-- Stored Procedure 2: sp_check_out_vehicle
-- Objective: Atomic check-out and fee calculation handling.
-- Description:
--   1. Verify if transaction exists and is currently active.
--   2. Calculate parking duration: round up to the nearest hour.
--   3. Apply fee tiers:
--      - Bike: 2.00 / hour
--      - Car: 5.00 / hour
--      - Truck: 10.00 / hour
--      - Minimum charge is 1 hour.
--   4. Update transaction to 'Completed' status with calculated exit_time and fee.
--      The trigger trg_after_transaction_update will automatically release the slot!
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_check_out_vehicle (
    IN p_transaction_id INT,
    OUT p_license_plate VARCHAR(20),
    OUT p_slot_number VARCHAR(10),
    OUT p_entry_time DATETIME,
    OUT p_exit_time DATETIME,
    OUT p_fee DECIMAL(10,2)
)
BEGIN
    DECLARE v_status VARCHAR(20) DEFAULT NULL;
    DECLARE v_entry_time DATETIME DEFAULT NULL;
    DECLARE v_vehicle_type VARCHAR(20) DEFAULT NULL;
    DECLARE v_duration_seconds INT DEFAULT 0;
    DECLARE v_hours INT DEFAULT 0;
    DECLARE v_hourly_rate DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_slot_id INT DEFAULT NULL;
    DECLARE v_not_found BOOLEAN DEFAULT FALSE;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_not_found = TRUE;

    -- 1. Check if transaction exists and is active
    SELECT 
        t.status, t.entry_time, v.vehicle_type, v.license_plate, s.slot_number, s.slot_id
    INTO 
        v_status, v_entry_time, v_vehicle_type, p_license_plate, p_slot_number, v_slot_id
    FROM 
        parking_transaction t
    INNER JOIN 
        vehicle v ON t.vehicle_id = v.vehicle_id
    INNER JOIN 
        parking_slot s ON t.slot_id = s.slot_id
    WHERE 
        t.transaction_id = p_transaction_id
    LIMIT 1;

    IF v_not_found THEN
        SET v_not_found = FALSE;
        SET v_status = NULL;
    END IF;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaction ID not found.';
    ELSEIF v_status = 'Completed' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Vehicle has already checked out.';
    END IF;

    -- Set exit time
    SET p_exit_time = NOW();
    SET p_entry_time = v_entry_time;

    -- 2. Duration calculation (in seconds)
    SET v_duration_seconds = TIMESTAMPDIFF(SECOND, v_entry_time, p_exit_time);
    
    -- Round up to nearest hour (min 1 hour)
    SET v_hours = CEIL(v_duration_seconds / 3600.0);
    IF v_hours < 1 THEN
        SET v_hours = 1;
    END IF;

    -- 3. Set hourly rates based on vehicle type
    IF v_vehicle_type = 'Bike' THEN
        SET v_hourly_rate = 2.00;
    ELSEIF v_vehicle_type = 'Car' THEN
        SET v_hourly_rate = 5.00;
    ELSEIF v_vehicle_type = 'Truck' THEN
        SET v_hourly_rate = 10.00;
    ELSE
        SET v_hourly_rate = 5.00; -- Default
    END IF;

    -- Calculate fee
    SET p_fee = v_hours * v_hourly_rate;

    -- 4. Complete Transaction
    UPDATE parking_transaction
    SET 
        exit_time = p_exit_time,
        fee = p_fee,
        status = 'Completed'
    WHERE 
        transaction_id = p_transaction_id;
END //

DELIMITER ;
