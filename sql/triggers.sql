-- ==========================================
-- DBMS Mini Project: Parking Lot Management System
-- Part 5: Database Triggers (triggers.sql)
-- Author: DBMS Mini Project Student
-- ==========================================

USE parking_db;

-- Drop existing triggers to avoid creation collisions
DROP TRIGGER IF EXISTS trg_after_transaction_insert;
DROP TRIGGER IF EXISTS trg_after_transaction_update;

DELIMITER //

-- -----------------------------------------------------------------------------
-- Trigger 1: trg_after_transaction_insert
-- Objective: Automate status updates on physical slots when vehicles enter.
-- Description: When a new active transaction is inserted into 'parking_transaction',
--              automatically change the status of the associated parking slot
--              from 'Available' to 'Occupied'.
-- -----------------------------------------------------------------------------
CREATE TRIGGER trg_after_transaction_insert
AFTER INSERT ON parking_transaction
FOR EACH ROW
BEGIN
    IF NEW.status = 'Active' THEN
        UPDATE parking_slot 
        SET status = 'Occupied' 
        WHERE slot_id = NEW.slot_id;
    END IF;
END //

-- -----------------------------------------------------------------------------
-- Trigger 2: trg_after_transaction_update
-- Objective: Automate status updates on physical slots when vehicles exit.
-- Description: When a transaction's status changes from 'Active' to 'Completed'
--              (i.e., vehicle checked out, fee paid), automatically release
--              the associated parking slot by updating status to 'Available'.
-- -----------------------------------------------------------------------------
CREATE TRIGGER trg_after_transaction_update
AFTER UPDATE ON parking_transaction
FOR EACH ROW
BEGIN
    -- Detect check-out transition: status goes from 'Active' to 'Completed'
    IF OLD.status = 'Active' AND NEW.status = 'Completed' THEN
        UPDATE parking_slot 
        SET status = 'Available' 
        WHERE slot_id = NEW.slot_id;
    END IF;
END //

DELIMITER ;
