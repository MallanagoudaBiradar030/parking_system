-- ==========================================
-- DBMS Mini Project: Parking Lot Management System
-- Part 2: Database DML Seed Data (sample_data.sql)
-- Author: DBMS Mini Project Student
-- ==========================================

USE parking_db;

-- Clear any existing records to ensure idempotent script execution
-- (Order of deletion matters due to Foreign Key Constraints!)
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE parking_transaction;
TRUNCATE TABLE parking_slot;
TRUNCATE TABLE vehicle;
TRUNCATE TABLE user;
SET FOREIGN_KEY_CHECKS = 1;

-- ------------------------------------------
-- 1. Insert 5 Sample Users (Operators & Administrators)
-- Passwords are encrypted using SHA2('password_string', 256) inside MySQL
-- ------------------------------------------
INSERT INTO user (username, password, full_name) VALUES
('admin', SHA2('admin123', 256), 'System Administrator'),
('john_op', SHA2('op123', 256), 'John Doe (Operator)'),
('sarah_op', SHA2('op123', 256), 'Sarah Connor (Operator)'),
('robert_mgr', SHA2('mgr123', 256), 'Robert Baratheon (Manager)'),
('elena_op', SHA2('op123', 256), 'Elena Gilbert (Operator)');

-- ------------------------------------------
-- 2. Insert 15 Physical Parking Slots
-- 5 Cars, 5 Bikes, 5 Trucks. A few will start as 'Occupied'
-- ------------------------------------------
INSERT INTO parking_slot (slot_number, slot_type, status) VALUES
('C-01', 'Car', 'Occupied'),
('C-02', 'Car', 'Available'),
('C-03', 'Car', 'Available'),
('C-04', 'Car', 'Available'),
('C-05', 'Car', 'Occupied'),
('B-01', 'Bike', 'Occupied'),
('B-02', 'Bike', 'Available'),
('B-03', 'Bike', 'Available'),
('B-04', 'Bike', 'Available'),
('B-05', 'Bike', 'Available'),
('T-01', 'Truck', 'Occupied'),
('T-02', 'Truck', 'Available'),
('T-03', 'Truck', 'Available'),
('T-04', 'Truck', 'Available'),
('T-05', 'Truck', 'Available');

-- ------------------------------------------
-- 3. Insert 5 Sample Vehicles
-- ------------------------------------------
INSERT INTO vehicle (license_plate, vehicle_type, owner_name, owner_phone) VALUES
('MH-12-AB-1234', 'Car', 'Aditya Verma', '9876543210'),
('KA-51-XY-9876', 'Bike', 'Karthik Gowda', '9988776655'),
('DL-01-CD-4567', 'Car', 'Devika Sen', '9555667788'),
('TS-07-EF-8888', 'Truck', 'Balaji Transports', '9000111222'),
('KL-11-GH-5555', 'Bike', 'Faisal Rahman', '9123456789');

-- ------------------------------------------
-- 4. Insert 5 Parking Transactions
-- 3 Historical (Completed with fees) and 2 Active (Currently Parked)
-- ------------------------------------------
-- Note: Setting specific past dates for transactions to demonstrate monthly revenue
INSERT INTO parking_transaction (vehicle_id, slot_id, entry_time, exit_time, fee, status) VALUES
-- 1. Completed Car Transaction (Parked for 4 hours, fee = 20.00)
(1, 1, '2026-05-15 10:00:00', '2026-05-15 14:00:00', 20.00, 'Completed'),

-- 2. Completed Bike Transaction (Parked for 2 hours, fee = 4.00)
(2, 6, '2026-05-18 09:30:00', '2026-05-18 11:30:00', 4.00, 'Completed'),

-- 3. Completed Truck Transaction (Parked for 5 hours, fee = 50.00)
(4, 11, '2026-05-20 08:00:00', '2026-05-20 13:00:00', 50.00, 'Completed'),

-- 4. Active Car Transaction (Currently parked in C-01)
(3, 1, '2026-06-02 08:00:00', NULL, 0.00, 'Active'),

-- 5. Active Bike Transaction (Currently parked in B-01)
(5, 6, '2026-06-02 09:15:00', NULL, 0.00, 'Active');
