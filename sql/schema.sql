-- ==========================================
-- DBMS Mini Project: Parking Lot Management System
-- Part 1: Database DDL Schema (schema.sql)
-- Author: DBMS Mini Project Student
-- ==========================================

-- Create the database if it doesn't already exist
CREATE DATABASE IF NOT EXISTS parking_db;
USE parking_db;

-- ------------------------------------------
-- Table 1: user (System Operators/Admins)
-- ------------------------------------------
CREATE TABLE IF NOT EXISTS user (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(256) NOT NULL, -- SHA-256 Hash of passwords for simple, zero-dep security
    full_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ------------------------------------------
-- Table 2: vehicle (Details of parked vehicles)
-- ------------------------------------------
CREATE TABLE IF NOT EXISTS vehicle (
    vehicle_id INT AUTO_INCREMENT PRIMARY KEY,
    license_plate VARCHAR(20) UNIQUE NOT NULL,
    vehicle_type VARCHAR(20) NOT NULL,
    owner_name VARCHAR(100) DEFAULT 'Unknown',
    owner_phone VARCHAR(15) DEFAULT 'N/A',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- Constraint: Validate vehicle types
    CONSTRAINT chk_vehicle_type CHECK (vehicle_type IN ('Car', 'Bike', 'Truck'))
) ENGINE=InnoDB;

-- ------------------------------------------
-- Table 3: parking_slot (Physical slot states)
-- ------------------------------------------
CREATE TABLE IF NOT EXISTS parking_slot (
    slot_id INT AUTO_INCREMENT PRIMARY KEY,
    slot_number VARCHAR(10) UNIQUE NOT NULL,
    slot_type VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'Available',
    -- Constraints: Validate slot types and statuses
    CONSTRAINT chk_slot_type CHECK (slot_type IN ('Car', 'Bike', 'Truck')),
    CONSTRAINT chk_slot_status CHECK (status IN ('Available', 'Occupied'))
) ENGINE=InnoDB;

-- ------------------------------------------
-- Table 4: parking_transaction (Entry/Exit Logs)
-- ------------------------------------------
CREATE TABLE IF NOT EXISTS parking_transaction (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    vehicle_id INT NOT NULL,
    slot_id INT NOT NULL,
    entry_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    exit_time DATETIME NULL,
    fee DECIMAL(10,2) DEFAULT 0.00,
    status VARCHAR(20) DEFAULT 'Active',
    -- Foreign Keys linking tables (Referential Integrity Constraints)
    FOREIGN KEY (vehicle_id) REFERENCES vehicle(vehicle_id) ON DELETE CASCADE,
    FOREIGN KEY (slot_id) REFERENCES parking_slot(slot_id) ON DELETE CASCADE,
    -- Constraints: Validate transaction status and numerical fee values
    CONSTRAINT chk_transaction_status CHECK (status IN ('Active', 'Completed')),
    CONSTRAINT chk_transaction_fee CHECK (fee >= 0.00)
) ENGINE=InnoDB;

-- ------------------------------------------
-- DBMS Concept: Indexes (DQL Search Optimization)
-- ------------------------------------------
-- Speed up queries filtering/searching vehicles by license plate
CREATE INDEX idx_vehicle_plate ON vehicle(license_plate);

-- Speed up transaction lookup based on whether it is active or completed
CREATE INDEX idx_transaction_status ON parking_transaction(status);

-- Speed up query filters on transaction entry dates (vital for revenue reports)
CREATE INDEX idx_transaction_entry ON parking_transaction(entry_time);
