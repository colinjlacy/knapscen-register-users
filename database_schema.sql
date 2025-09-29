-- =====================================================
-- MySQL Database Schema for Customer Management System
-- =====================================================
-- This file contains the complete database schema and sample data
-- for the customer management system scaffolding script.
--
-- Features:
-- - Corporate customer management with subscription tiers
-- - User management with role-based access
-- - Customer relationship touchpoint tracking
-- - UUID primary keys for all tables
-- - Proper foreign key relationships
-- =====================================================

-- Create database (optional - adjust name as needed)
-- CREATE DATABASE IF NOT EXISTS scaffold_db;
-- USE scaffold_db;

-- =====================================================
-- TABLE CREATION
-- =====================================================

-- Corporate customers table
-- Stores company information and subscription tiers
CREATE TABLE IF NOT EXISTS corporate_customers (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    name VARCHAR(64) NOT NULL,
    subscription_tier ENUM('basic', 'groovy', 'far-out') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_subscription_tier (subscription_tier),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- User roles table
-- Defines available user roles in the system
CREATE TABLE IF NOT EXISTS user_roles (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    role_name VARCHAR(64) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Users table
-- Stores user accounts linked to corporate customers and roles
CREATE TABLE IF NOT EXISTS users (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    customer_id CHAR(36) NOT NULL,
    role_id CHAR(36) NOT NULL,
    name VARCHAR(64) NOT NULL,
    email VARCHAR(64) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES corporate_customers(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES user_roles(id) ON DELETE RESTRICT,
    INDEX idx_customer_id (customer_id),
    INDEX idx_role_id (role_id),
    INDEX idx_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Customer relationship touchpoints table
-- Tracks CRM activities for each corporate customer
CREATE TABLE IF NOT EXISTS touchpoints (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    customer_id CHAR(36) NOT NULL,
    welcome_outreach DATE NULL,
    technical_onboarding DATE NULL,
    follow_up_call DATE NULL,
    feedback_session DATE NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES corporate_customers(id) ON DELETE CASCADE,
    INDEX idx_customer_id (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- SAMPLE DATA INSERTION
-- =====================================================

-- Insert user roles
INSERT INTO user_roles (id, role_name) VALUES 
    (UUID(), 'customer_account_owner'),
    (UUID(), 'admin_user'),
    (UUID(), 'generic_user')
ON DUPLICATE KEY UPDATE role_name = VALUES(role_name);

-- Insert corporate customers with different subscription tiers
-- INSERT INTO corporate_customers (id, name, subscription_tier) VALUES
--     (UUID(), 'TechCorp Solutions', 'far-out'),
--     (UUID(), 'StartupXYZ Inc.', 'basic'),
--     (UUID(), 'Enterprise Dynamics', 'groovy'),
--     (UUID(), 'Innovation Labs', 'far-out'),
--     (UUID(), 'Digital Ventures', 'basic');

-- -- Insert sample users (using subqueries to get role and customer IDs)
-- INSERT INTO users (id, customer_id, role_id, name, email) VALUES
--     -- TechCorp Solutions users
--     (UUID(), 
--      (SELECT id FROM corporate_customers WHERE name = 'TechCorp Solutions' LIMIT 1),
--      (SELECT id FROM user_roles WHERE role_name = 'customer_account_owner' LIMIT 1),
--      'John Smith', 'john.smith@techcorp.com'),
--     (UUID(), 
--      (SELECT id FROM corporate_customers WHERE name = 'TechCorp Solutions' LIMIT 1),
--      (SELECT id FROM user_roles WHERE role_name = 'admin_user' LIMIT 1),
--      'Sarah Johnson', 'sarah.johnson@techcorp.com'),
--     (UUID(), 
--      (SELECT id FROM corporate_customers WHERE name = 'TechCorp Solutions' LIMIT 1),
--      (SELECT id FROM user_roles WHERE role_name = 'generic_user' LIMIT 1),
--      'Mike Davis', 'mike.davis@techcorp.com'),
    
--     -- StartupXYZ Inc. users
--     (UUID(), 
--      (SELECT id FROM corporate_customers WHERE name = 'StartupXYZ Inc.' LIMIT 1),
--      (SELECT id FROM user_roles WHERE role_name = 'customer_account_owner' LIMIT 1),
--      'Alice Brown', 'alice.brown@startupxyz.com'),
--     (UUID(), 
--      (SELECT id FROM corporate_customers WHERE name = 'StartupXYZ Inc.' LIMIT 1),
--      (SELECT id FROM user_roles WHERE role_name = 'generic_user' LIMIT 1),
--      'Bob Wilson', 'bob.wilson@startupxyz.com'),
    
--     -- Enterprise Dynamics users
--     (UUID(), 
--      (SELECT id FROM corporate_customers WHERE name = 'Enterprise Dynamics' LIMIT 1),
--      (SELECT id FROM user_roles WHERE role_name = 'customer_account_owner' LIMIT 1),
--      'Carol White', 'carol.white@enterprise.com'),
--     (UUID(), 
--      (SELECT id FROM corporate_customers WHERE name = 'Enterprise Dynamics' LIMIT 1),
--      (SELECT id FROM user_roles WHERE role_name = 'admin_user' LIMIT 1),
--      'David Lee', 'david.lee@enterprise.com'),
    
--     -- Innovation Labs users
--     (UUID(), 
--      (SELECT id FROM corporate_customers WHERE name = 'Innovation Labs' LIMIT 1),
--      (SELECT id FROM user_roles WHERE role_name = 'customer_account_owner' LIMIT 1),
--      'Emma Garcia', 'emma.garcia@innovationlabs.com'),
    
--     -- Digital Ventures users
--     (UUID(), 
--      (SELECT id FROM corporate_customers WHERE name = 'Digital Ventures' LIMIT 1),
--      (SELECT id FROM user_roles WHERE role_name = 'customer_account_owner' LIMIT 1),
--      'Frank Miller', 'frank.miller@digitalventures.com');

-- -- Insert sample touchpoints with realistic dates
-- -- Note: Dates are relative to current date for demonstration
-- INSERT INTO touchpoints (id, customer_id, welcome_outreach, technical_onboarding, follow_up_call, feedback_session) VALUES
--     (UUID(), 
--      (SELECT id FROM corporate_customers WHERE name = 'TechCorp Solutions' LIMIT 1),
--      CURDATE() - INTERVAL 90 DAY,
--      CURDATE() - INTERVAL 83 DAY,
--      CURDATE() - INTERVAL 69 DAY,
--      CURDATE() - INTERVAL 45 DAY),
    
--     (UUID(), 
--      (SELECT id FROM corporate_customers WHERE name = 'StartupXYZ Inc.' LIMIT 1),
--      CURDATE() - INTERVAL 80 DAY,
--      NULL,
--      CURDATE() - INTERVAL 59 DAY,
--      NULL),
    
--     (UUID(), 
--      (SELECT id FROM corporate_customers WHERE name = 'Enterprise Dynamics' LIMIT 1),
--      CURDATE() - INTERVAL 70 DAY,
--      CURDATE() - INTERVAL 63 DAY,
--      NULL,
--      NULL),
    
--     (UUID(), 
--      (SELECT id FROM corporate_customers WHERE name = 'Innovation Labs' LIMIT 1),
--      CURDATE() - INTERVAL 60 DAY,
--      NULL,
--      CURDATE() - INTERVAL 39 DAY,
--      NULL),
    
--     (UUID(), 
--      (SELECT id FROM corporate_customers WHERE name = 'Digital Ventures' LIMIT 1),
--      CURDATE() - INTERVAL 50 DAY,
--      CURDATE() - INTERVAL 43 DAY,
--      CURDATE() - INTERVAL 29 DAY,
--      CURDATE() - INTERVAL 5 DAY);

-- =====================================================
-- SAMPLE QUERIES FOR DEMONSTRATION
-- =====================================================

-- View all corporate customers with their subscription tiers
-- SELECT id, name, subscription_tier, created_at FROM corporate_customers ORDER BY name;

-- View all users with their roles and company information
-- SELECT 
--     u.name as user_name,
--     u.email,
--     r.role_name,
--     c.name as company_name,
--     c.subscription_tier
-- FROM users u
-- JOIN user_roles r ON u.role_id = r.id
-- JOIN corporate_customers c ON u.customer_id = c.id
-- ORDER BY c.name, r.role_name;

-- View touchpoint status for all customers
-- SELECT 
--     c.name as company_name,
--     c.subscription_tier,
--     t.welcome_outreach,
--     t.technical_onboarding,
--     t.follow_up_call,
--     t.feedback_session
-- FROM corporate_customers c
-- LEFT JOIN touchpoints t ON c.id = t.customer_id
-- ORDER BY c.name;

-- Count users by role
-- SELECT 
--     r.role_name,
--     COUNT(u.id) as user_count
-- FROM user_roles r
-- LEFT JOIN users u ON r.id = u.role_id
-- GROUP BY r.id, r.role_name
-- ORDER BY user_count DESC;

-- Find customers with incomplete touchpoints
-- SELECT 
--     c.name as company_name,
--     CASE 
--         WHEN t.welcome_outreach IS NULL THEN 'Missing welcome_outreach'
--         WHEN t.technical_onboarding IS NULL THEN 'Missing technical_onboarding'
--         WHEN t.follow_up_call IS NULL THEN 'Missing follow_up_call'
--         WHEN t.feedback_session IS NULL THEN 'Missing feedback_session'
--         ELSE 'All touchpoints complete'
--     END as status
-- FROM corporate_customers c
-- LEFT JOIN touchpoints t ON c.id = t.customer_id;

-- =====================================================
-- SCHEMA INFORMATION
-- =====================================================

-- Table relationships:
-- corporate_customers (parent) → users (child) [1:many]
-- corporate_customers (parent) → touchpoints (child) [1:1]
-- user_roles (parent) → users (child) [1:many]

-- Subscription tiers:
-- 'basic': Entry-level subscription
-- 'groovy': Mid-tier subscription
-- 'far-out': Premium subscription

-- User roles:
-- 'customer_account_owner': Primary account holder
-- 'admin_user': Administrative privileges within the account
-- 'generic_user': Standard user access

-- Touchpoint types (post-sale CRM activities):
-- welcome_outreach: Initial customer contact
-- technical_onboarding: Technical setup assistance
-- follow_up_call: Regular check-in calls
-- feedback_session: Customer feedback collection
