-- Scenario: Fitness Center Management System
-- You've been hired to design a database for a fitness center chain. The system needs to handle:

-- Members: People who join the gym with membership plans (monthly, quarterly, annual)
-- Trainers: Certified fitness trainers who work at specific gym locations
-- Classes: Group fitness classes like Yoga, Spinning, CrossFit, etc. Classes have a maximum capacity and are scheduled at specific times
-- Personal Training Sessions: One-on-one sessions between members and trainers
-- Gym Locations: The chain has multiple gym locations across the city
-- Equipment: Track fitness equipment at each location (treadmills, weights, etc.) for maintenance purposes
-- Check-ins: Log when members enter a gym location (for attendance tracking)

-- Your Task
-- Design the database structure for this fitness center. Please provide:
-- The tables you would create (list each table name)
-- For each table, list:
    -- All fields/columns
    -- The data type for each field
    -- Which field(s) serve as the primary key
    -- Any foreign keys and what they reference
    -- Describe the relationships between tables (one-to-one, one-to-many, many-to-many)

-- Additional Requirements to Consider

-- A member can have only one active membership at a time, but needs membership history
-- Members can attend multiple classes, and classes can have multiple members (with capacity limits)
-- A trainer can teach multiple classes and can work at multiple gym locations
-- Personal training sessions must be scheduled in advance with a specific date/time
-- Track equipment maintenance history (when was it last serviced, next service date)
-- Members can check in at any location in the chain
-- Classes are recurring (e.g., "Yoga Mondays at 6 PM") but also need to track individual class occurrences
-- Store trainer certifications and specialties


CREATE DATABASE IF NOT EXISTS fitness_center_management_system;
USE fitness_center_management_system;

CREATE TABLE address(
    id UUID PRIMARY KEY,
    street VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    zip_code VARCHAR(10) NOT NULL,
    country VARCHAR(100) NOT NULL DEFAULT 'USA'
);

CREATE TABLE member(
    id UUID PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) NOT NULL,
    date_of_birth DATE,
    address_id UUID NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (address_id) REFERENCES address(id)
);

CREATE TABLE trainer(
    id UUID PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) NOT NULL,
    hire_date DATE NOT NULL,
    address_id UUID NOT NULL,
    FOREIGN KEY (address_id) REFERENCES address(id)
);

CREATE TABLE gym_location(
    id UUID PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    address_id UUID NOT NULL,
    opening_time TIME,
    closing_time TIME,
    FOREIGN KEY (address_id) REFERENCES address(id)
);

CREATE TABLE trainer_location(
    trainer_id UUID NOT NULL,
    gym_location_id UUID NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    PRIMARY KEY (trainer_id, gym_location_id),
    FOREIGN KEY (trainer_id) REFERENCES trainer(id) ON DELETE CASCADE,
    FOREIGN KEY (gym_location_id) REFERENCES gym_location(id) ON DELETE CASCADE
);

CREATE TABLE trainer_certification(
    id UUID PRIMARY KEY,
    trainer_id UUID NOT NULL,
    certification_name VARCHAR(255) NOT NULL,
    issuing_organization VARCHAR(255),
    certification_date DATE NOT NULL,
    expiry_date DATE,
    FOREIGN KEY (trainer_id) REFERENCES trainer(id) ON DELETE CASCADE
);

CREATE TABLE trainer_specialty(
    id UUID PRIMARY KEY,
    trainer_id UUID NOT NULL,
    specialty VARCHAR(100) NOT NULL,
    FOREIGN KEY (trainer_id) REFERENCES trainer(id) ON DELETE CASCADE
);

CREATE TABLE membership_plan(
    id UUID PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    duration_type ENUM('monthly', 'quarterly', 'annual', 'trial') NOT NULL,
    duration_days INT NOT NULL,  -- 30, 90, 365, 7, etc.
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE membership_history(
    id UUID PRIMARY KEY,
    member_id UUID NOT NULL,
    plan_id UUID NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status ENUM('active', 'expired', 'cancelled') DEFAULT 'active',
    cancellation_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (member_id) REFERENCES member(id) ON DELETE CASCADE,
    FOREIGN KEY (plan_id) REFERENCES membership_plan(id),
    INDEX idx_member_status (member_id, status)
);

CREATE TABLE class_template(
    id UUID PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    day_of_week ENUM('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
    start_time TIME NOT NULL,
    duration_minutes INT NOT NULL,
    capacity INT NOT NULL CHECK(capacity > 0),
    gym_location_id UUID NOT NULL,
    trainer_id UUID,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (gym_location_id) REFERENCES gym_location(id),
    FOREIGN KEY (trainer_id) REFERENCES trainer(id) ON DELETE SET NULL
);

CREATE TABLE class_occurrence(
    id UUID PRIMARY KEY,
    class_template_id UUID NOT NULL,
    scheduled_date DATE NOT NULL,
    start_time TIME NOT NULL,
    duration_minutes INT NOT NULL,
    actual_capacity INT,
    status ENUM('scheduled', 'completed', 'cancelled') DEFAULT 'scheduled',
    cancellation_reason TEXT,
    FOREIGN KEY (class_template_id) REFERENCES class_template(id),
    UNIQUE KEY unique_class_date (class_template_id, scheduled_date),
    INDEX idx_scheduled_date (scheduled_date)
);

CREATE TABLE class_booking(
    id UUID PRIMARY KEY,
    class_occurrence_id UUID NOT NULL,
    member_id UUID NOT NULL,
    booked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    attended BOOLEAN DEFAULT FALSE,
    cancelled_at TIMESTAMP,
    FOREIGN KEY (class_occurrence_id) REFERENCES class_occurrence(id) ON DELETE CASCADE,
    FOREIGN KEY (member_id) REFERENCES member(id) ON DELETE CASCADE,
    UNIQUE KEY unique_member_class (class_occurrence_id, member_id)
);

CREATE TABLE personal_training_session(
    id UUID PRIMARY KEY,
    member_id UUID NOT NULL,
    trainer_id UUID NOT NULL,
    gym_location_id UUID NOT NULL,
    scheduled_datetime TIMESTAMP NOT NULL,
    duration_minutes INT DEFAULT 60,
    status ENUM('scheduled', 'completed', 'cancelled', 'no_show') DEFAULT 'scheduled',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (member_id) REFERENCES member(id),
    FOREIGN KEY (trainer_id) REFERENCES trainer(id),
    FOREIGN KEY (gym_location_id) REFERENCES gym_location(id),
    INDEX idx_trainer_date (trainer_id, scheduled_datetime),
    INDEX idx_member_date (member_id, scheduled_datetime)
);

CREATE TABLE equipment(
    id UUID PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    serial_number VARCHAR(100),
    purchase_date DATE,
    quantity INT NOT NULL DEFAULT 1,
    status ENUM('operational', 'maintenance', 'broken', 'retired') DEFAULT 'operational',
    gym_location_id UUID NOT NULL,
    FOREIGN KEY (gym_location_id) REFERENCES gym_location(id)
);

CREATE TABLE equipment_maintenance(
    id UUID PRIMARY KEY,
    equipment_id UUID NOT NULL,
    maintenance_date DATE NOT NULL,
    next_service_date DATE,
    maintenance_type ENUM('routine', 'repair', 'inspection') NOT NULL,
    notes TEXT,
    performed_by VARCHAR(255),
    cost DECIMAL(10,2),
    FOREIGN KEY (equipment_id) REFERENCES equipment(id) ON DELETE CASCADE,
    INDEX idx_equipment_next_service (equipment_id, next_service_date)
);

CREATE TABLE check_in(
    id UUID PRIMARY KEY,
    member_id UUID NOT NULL,
    gym_location_id UUID NOT NULL,
    check_in_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (member_id) REFERENCES member(id) ON DELETE CASCADE,
    FOREIGN KEY (gym_location_id) REFERENCES gym_location(id),
    INDEX idx_member_checkin (member_id, check_in_time),
    INDEX idx_location_checkin (gym_location_id, check_in_time)
);
