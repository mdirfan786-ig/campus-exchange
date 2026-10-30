-- ============================================================================
-- CAMPUS PRODUCT EXCHANGE SYSTEM (CampusX)
-- Relational Database Schema & Implementation (MySQL 8.0+)
-- Course / Mini-Project: Database Management Systems (DBMS)
-- ============================================================================

DROP DATABASE IF EXISTS campus_product_exchange;
CREATE DATABASE campus_product_exchange 
  CHARACTER SET utf8mb4 
  COLLATE utf8mb4_unicode_ci;

USE campus_product_exchange;

-- ----------------------------------------------------------------------------
-- 1. TABLE: students
-- Stores registered campus students and their profile reputation
-- ----------------------------------------------------------------------------
CREATE TABLE students (
    student_id VARCHAR(20) PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    department VARCHAR(100) NOT NULL,
    academic_year ENUM('1', '2', '3', '4') NOT NULL DEFAULT '1',
    section VARCHAR(5) NOT NULL DEFAULT 'A',
    college_email VARCHAR(120) NOT NULL UNIQUE,
    phone_number VARCHAR(20) NOT NULL,
    password_hash VARCHAR(255) NOT NULL DEFAULT '$2b$10$demoDefaultHashedPassword',
    avatar_url VARCHAR(255),
    trust_rating DECIMAL(3,2) NOT NULL DEFAULT 5.00 CHECK (trust_rating BETWEEN 1.00 AND 5.00),
    total_lent INT UNSIGNED NOT NULL DEFAULT 0,
    total_borrowed INT UNSIGNED NOT NULL DEFAULT 0,
    total_completed INT UNSIGNED NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_student_email (college_email),
    INDEX idx_student_dept (department)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 2. TABLE: product_categories
-- Categories for academic study materials and equipment
-- ----------------------------------------------------------------------------
CREATE TABLE product_categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    icon_class VARCHAR(50) DEFAULT 'bi-box-seam',
    color_hex VARCHAR(10) DEFAULT '#2563eb',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 3. TABLE: campus_locations
-- Designated campus pickup and meeting points across blocks and halls
-- ----------------------------------------------------------------------------
CREATE TABLE campus_locations (
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    location_name VARCHAR(100) NOT NULL UNIQUE,
    campus_block VARCHAR(50) NOT NULL,
    floor_level VARCHAR(30) DEFAULT 'Ground Floor',
    is_active BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 4. TABLE: products
-- Academic items registered by students for lending/sharing
-- ----------------------------------------------------------------------------
CREATE TABLE products (
    product_id VARCHAR(20) PRIMARY KEY,
    owner_id VARCHAR(20) NOT NULL,
    category_id INT NOT NULL,
    product_name VARCHAR(150) NOT NULL,
    description TEXT NOT NULL,
    item_condition ENUM('Brand New', 'Like New', 'Excellent', 'Good') NOT NULL DEFAULT 'Good',
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    available_hours VARCHAR(100) DEFAULT '9:00 AM - 5:00 PM',
    location_id INT NOT NULL,
    quantity INT UNSIGNED NOT NULL DEFAULT 1 CHECK (quantity > 0),
    image_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_products_owner FOREIGN KEY (owner_id) 
        REFERENCES students(student_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_products_category FOREIGN KEY (category_id) 
        REFERENCES product_categories(category_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_products_location FOREIGN KEY (location_id) 
        REFERENCES campus_locations(location_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_product_available (is_available),
    INDEX idx_product_category (category_id)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 5. TABLE: product_requests
-- Urgent product loan broadcasts created by students
-- ----------------------------------------------------------------------------
CREATE TABLE product_requests (
    request_id VARCHAR(20) PRIMARY KEY,
    requester_id VARCHAR(20) NOT NULL,
    category_id INT NOT NULL,
    product_name VARCHAR(150) NOT NULL,
    quantity INT UNSIGNED NOT NULL DEFAULT 1 CHECK (quantity > 0),
    reason TEXT NOT NULL,
    urgency_level ENUM('Normal', 'Important', 'Urgent', 'Emergency') NOT NULL DEFAULT 'Emergency',
    location_id INT NOT NULL,
    custom_location_notes VARCHAR(200),
    required_date VARCHAR(50) DEFAULT 'Today',
    required_time VARCHAR(50) DEFAULT 'Immediate',
    additional_notes TEXT,
    status ENUM('Waiting', 'Accepted', 'In Progress', 'Completed', 'Cancelled') NOT NULL DEFAULT 'Waiting',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_requests_requester FOREIGN KEY (requester_id) 
        REFERENCES students(student_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_requests_category FOREIGN KEY (category_id) 
        REFERENCES product_categories(category_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_requests_location FOREIGN KEY (location_id) 
        REFERENCES campus_locations(location_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_requests_status (status),
    INDEX idx_requests_urgency (urgency_level)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 6. TABLE: exchanges
-- Links a product request to a lender student who accepted the request
-- ----------------------------------------------------------------------------
CREATE TABLE exchanges (
    exchange_id INT AUTO_INCREMENT PRIMARY KEY,
    request_id VARCHAR(20) NOT NULL UNIQUE,
    lender_id VARCHAR(20) NOT NULL,
    borrower_id VARCHAR(20) NOT NULL,
    pickup_instructions TEXT NOT NULL,
    exchange_status ENUM('Accepted', 'Handed Over', 'Returned', 'Cancelled') NOT NULL DEFAULT 'Accepted',
    accepted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    handed_over_at TIMESTAMP NULL,
    returned_at TIMESTAMP NULL,
    CONSTRAINT fk_exchanges_request FOREIGN KEY (request_id) 
        REFERENCES product_requests(request_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_exchanges_lender FOREIGN KEY (lender_id) 
        REFERENCES students(student_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_exchanges_borrower FOREIGN KEY (borrower_id) 
        REFERENCES students(student_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_different_parties CHECK (lender_id <> borrower_id),
    INDEX idx_exchanges_status (exchange_status)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 7. TABLE: transactions
-- Permanent audit log and lifecycle history of all campus exchanges
-- ----------------------------------------------------------------------------
CREATE TABLE transactions (
    transaction_id VARCHAR(20) PRIMARY KEY,
    exchange_id INT NOT NULL,
    request_id VARCHAR(20) NOT NULL,
    product_name VARCHAR(150) NOT NULL,
    requester_id VARCHAR(20) NOT NULL,
    provider_id VARCHAR(20) NOT NULL,
    location_id INT NOT NULL,
    transaction_status ENUM('Active', 'Returned', 'Completed', 'Cancelled') NOT NULL DEFAULT 'Active',
    transaction_date DATE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_txns_exchange FOREIGN KEY (exchange_id) 
        REFERENCES exchanges(exchange_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_txns_requester FOREIGN KEY (requester_id) 
        REFERENCES students(student_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_txns_provider FOREIGN KEY (provider_id) 
        REFERENCES students(student_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_txns_location FOREIGN KEY (location_id) 
        REFERENCES campus_locations(location_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_txns_status (transaction_status),
    INDEX idx_txns_date (transaction_date)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 8. TABLE: notifications
-- In-app alert broadcasts and individual exchange updates
-- ----------------------------------------------------------------------------
CREATE TABLE notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    recipient_id VARCHAR(20) NOT NULL,
    title VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,
    notification_type ENUM('alert', 'info', 'success', 'warning') NOT NULL DEFAULT 'info',
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    target_link VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_notif_recipient (recipient_id),
    INDEX idx_notif_unread (is_read)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 9. TABLE: student_feedback_reviews
-- Ratings and reviews submitted after exchange completion
-- ----------------------------------------------------------------------------
CREATE TABLE student_feedback_reviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id VARCHAR(20) NOT NULL,
    reviewer_id VARCHAR(20) NOT NULL,
    reviewee_id VARCHAR(20) NOT NULL,
    rating INT UNSIGNED NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comments VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_reviews_txn FOREIGN KEY (transaction_id) 
        REFERENCES transactions(transaction_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_reviews_reviewer FOREIGN KEY (reviewer_id) 
        REFERENCES students(student_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_reviews_reviewee FOREIGN KEY (reviewee_id) 
        REFERENCES students(student_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;


-- ============================================================================
-- RELATIONAL VIEWS (FOR REPORTING & DBMS LAB DEMO)
-- ============================================================================

CREATE OR REPLACE VIEW v_active_urgent_requests AS
SELECT 
    pr.request_id,
    pr.product_name,
    pc.category_name,
    pr.quantity,
    pr.urgency_level,
    pr.reason,
    cl.location_name,
    cl.campus_block,
    s.full_name AS requester_name,
    s.department AS requester_dept,
    s.phone_number AS requester_phone,
    pr.required_date,
    pr.required_time,
    pr.status,
    pr.created_at
FROM product_requests pr
JOIN students s ON pr.requester_id = s.student_id
JOIN product_categories pc ON pr.category_id = pc.category_id
JOIN campus_locations cl ON pr.location_id = cl.location_id
WHERE pr.status IN ('Waiting', 'Accepted')
ORDER BY 
    CASE pr.urgency_level
        WHEN 'Emergency' THEN 1
        WHEN 'Urgent' THEN 2
        WHEN 'Important' THEN 3
        ELSE 4
    END,
    pr.created_at DESC;

CREATE OR REPLACE VIEW v_transaction_audit AS
SELECT 
    t.transaction_id,
    t.product_name,
    req.full_name AS borrower_name,
    req.department AS borrower_dept,
    prov.full_name AS lender_name,
    prov.department AS lender_dept,
    cl.location_name,
    t.transaction_date,
    t.transaction_status,
    t.notes
FROM transactions t
JOIN students req ON t.requester_id = req.student_id
JOIN students prov ON t.provider_id = prov.student_id
JOIN campus_locations cl ON t.location_id = cl.location_id
ORDER BY t.created_at DESC;

CREATE OR REPLACE VIEW v_student_leaderboard AS
SELECT 
    s.student_id,
    s.full_name,
    s.department,
    s.trust_rating,
    s.total_lent,
    s.total_borrowed,
    s.total_completed,
    COUNT(DISTINCT p.product_id) AS products_registered
FROM students s
LEFT JOIN products p ON s.student_id = p.owner_id
GROUP BY s.student_id, s.full_name, s.department, s.trust_rating, s.total_lent, s.total_borrowed, s.total_completed
ORDER BY s.total_lent DESC, s.trust_rating DESC;


-- ============================================================================
-- SEED DATA INSERTION
-- ============================================================================

INSERT INTO product_categories (category_id, category_name, description, icon_class, color_hex) VALUES
(1, 'Stationery', 'Pens, pencils, markers, exam pads, erasers, and highlighters.', 'bi-pencil-fill', '#0284c7'),
(2, 'Calculators', 'University exam approved scientific and non-programmable calculators.', 'bi-calculator-fill', '#2563eb'),
(3, 'Geometry Tools', 'Mini drafters, compass kits, T-squares, set squares, and rulers.', 'bi-rulers', '#0891b2'),
(4, 'Books', 'Engineering textbooks, syllabus guides, reference manuals, and lecture notes.', 'bi-journal-bookmark-fill', '#4f46e5'),
(5, 'Lab Equipment', 'White laboratory aprons, digital multimeters, IC breadboards, and test probes.', 'bi-cpu-fill', '#7c3aed'),
(6, 'Electronics', 'Laptop PD fast chargers, USB-C cables, power banks, and OTG adapters.', 'bi-plug-fill', '#ea580c'),
(7, 'Sports Items', 'Badminton rackets, table tennis paddles, footballs, and sporting accessories.', 'bi-trophy-fill', '#16a34a'),
(8, 'Other', 'Other miscellaneous campus academic and hostel study accessories.', 'bi-box-seam', '#64748b');

INSERT INTO campus_locations (location_id, location_name, campus_block, floor_level) VALUES
(1, 'Main block ground floor', 'Main Block', 'Ground Floor'),
(2, 'Main block 1st floor', 'Main Block', '1st Floor'),
(3, 'Main block 2nd floor', 'Main Block', '2nd Floor'),
(4, 'Main block 3rd floor', 'Main Block', '3rd Floor'),
(5, 'Techpark ground floor', 'Techpark', 'Ground Floor'),
(6, 'Techpark 1st floor', 'Techpark', '1st Floor'),
(7, 'Techpark 2nd floor', 'Techpark', '2nd Floor'),
(8, 'Tech park 3rd floor', 'Techpark', '3rd Floor'),
(9, 'Academic block ground floor', 'Academic Block', 'Ground Floor'),
(10, 'Academic block 1st floor', 'Academic Block', '1st Floor'),
(11, 'Academic block 2nd floor', 'Academic Block', '2nd Floor'),
(12, 'Academic block 3rd floor', 'Academic Block', '3rd Floor');

INSERT INTO students (student_id, full_name, department, academic_year, section, college_email, phone_number, trust_rating, total_lent, total_borrowed, total_completed) VALUES
('STU1001', 'Mohamed Irfan N', 'Computer Science & Engineering', '3', 'A', 'mohamed.irfan@example.com', '+91 98451 23450', 4.90, 8, 5, 12),
('STU1002', 'Rahul Sharma', 'Mechanical Engineering', '2', 'B', 'rahul@example.com', '+91 98451 23451', 4.80, 11, 3, 14),
('STU1003', 'Priya Patel', 'Electronics & Communication', '4', 'A', 'priya@example.com', '+91 98451 23452', 5.00, 9, 4, 13),
('STU1004', 'Irfan Khan', 'Information Technology', '3', 'B', 'irfan@example.com', '+91 98451 23453', 4.95, 7, 6, 11);

INSERT INTO products (product_id, owner_id, category_id, product_name, description, item_condition, is_available, available_hours, location_id, quantity, image_url) VALUES
('PROD101', 'STU1001', 2, 'Casio FX-991EX Scientific Calculator', 'Original non-programmable scientific calculator with matrix solver. Allowed in university semester exams.', 'Excellent', TRUE, '8:30 AM - 5:00 PM', 1, 1, 'https://images.unsplash.com/photo-1587145820266-a5951ee6f620?w=400'),
('PROD102', 'STU1002', 3, 'Engineering Drawing Mini Drafter & T-Square', 'Precision metal clamp drafter with scale rules. Perfect for machine drawing & civil graphics labs.', 'Good', TRUE, '9:00 AM - 4:30 PM', 5, 1, 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=400'),
('PROD103', 'STU1003', 5, 'Digital Multimeter with Test Probes', 'True-RMS digital multimeter with probe leads for voltage, resistance, diode, and continuity test.', 'Like New', TRUE, '10:00 AM - 6:00 PM', 7, 1, 'https://images.unsplash.com/photo-1581092335397-9583fe92d232?w=400'),
('PROD104', 'STU1001', 5, 'White Chemistry Laboratory Coat (Size L)', 'Pure cotton protective white lab coat with deep pockets. Clean and ironed for practicals.', 'Good', TRUE, '11:00 AM - 3:00 PM', 9, 1, 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=400'),
('PROD105', 'STU1004', 6, '65W USB Type-C Fast Charger + 2m Cable', 'Multi-protocol PD charger suitable for laptops, iPad, and Android smartphones.', 'Like New', TRUE, 'All Day', 10, 1, 'https://images.unsplash.com/photo-1609592807664-96426db4f61f?w=400'),
('PROD106', 'STU1001', 4, 'Data Structures & Algorithms by Cormen (CLRS)', 'Standard reference text for algorithms course and competitive programming. Clean pages.', 'Good', TRUE, '9:00 AM - 5:00 PM', 6, 1, 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=400'),
('PROD107', 'STU1002', 3, 'Complete Geometry Compass & Protractor Box', 'Stainless steel compass, divider, protractor, set squares, and 15cm ruler in metal tin.', 'Brand New', FALSE, '10:00 AM - 1:00 PM', 3, 1, 'https://images.unsplash.com/photo-1583485088034-697b5bc54ccd?w=400'),
('PROD108', 'STU1004', 7, 'Yonex Badminton Racket Pair with Shuttles', 'High tension carbon frame rackets with tube of nylon shuttlecocks. For campus evening games.', 'Good', TRUE, '4:00 PM - 7:30 PM', 12, 2, 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=400');

INSERT INTO product_requests (request_id, requester_id, category_id, product_name, quantity, reason, urgency_level, location_id, required_date, required_time, additional_notes, status) VALUES
('REQ1024', 'STU1001', 2, 'Scientific Calculator', 1, 'Maths Semester Examination (Calculus-II). My calculator battery died.', 'Emergency', 1, 'Today', '10:00 AM', 'Waiting in Main block ground floor. Can return immediately at 1:15 PM once exam finishes.', 'Waiting'),
('REQ1025', 'STU1003', 3, 'Engineering Drafter & Clamp', 1, 'Machine Drawing Lab Internal Assessment', 'Urgent', 5, 'Today', '11:30 AM', 'Need a working clamp drafter for 2 hours. Will handle with extreme care.', 'Waiting'),
('REQ1026', 'STU1004', 5, 'Digital Multimeter', 1, 'IoT Circuit Troubleshooting for Mini Project', 'Important', 7, 'Today', '02:00 PM', 'Need to test voltage drops across breadboard resistor array.', 'Accepted'),
('REQ1027', 'STU1001', 5, 'White Lab Coat', 1, 'Organic Chemistry Practical Examination', 'Normal', 9, 'Yesterday', '09:30 AM', 'Forgot lab coat in hostel room before lab.', 'Completed'),
('REQ1028', 'STU1002', 6, '65W USB-C Laptop Charger', 1, 'Laptop battery died right before Capstone Presentation', 'Emergency', 6, 'Today', '03:15 PM', 'Need for Dell XPS / MacBook charging during slide deck presentation.', 'Waiting');

INSERT INTO exchanges (exchange_id, request_id, lender_id, borrower_id, pickup_instructions, exchange_status, accepted_at, handed_over_at, returned_at) VALUES
(1, 'REQ1027', 'STU1004', 'STU1001', 'Exchanged in Academic block ground floor lobby. Item returned in clean condition.', 'Returned', '2026-09-23 08:30:00', '2026-09-23 09:15:00', '2026-09-23 13:00:00'),
(2, 'REQ1026', 'STU1002', 'STU1004', 'I am in Main block 1st floor. Collect anytime before 2:15 PM.', 'Accepted', '2026-09-24 16:00:00', '2026-09-24 16:30:00', NULL);

INSERT INTO transactions (transaction_id, exchange_id, request_id, product_name, requester_id, provider_id, location_id, transaction_status, transaction_date, notes) VALUES
('TXN001', 1, 'REQ1027', 'White Lab Coat', 'STU1001', 'STU1004', 9, 'Completed', '2026-09-23', 'Exchanged in morning and returned by 1:00 PM. Verified clean.'),
('TXN002', 2, 'REQ1026', 'Digital Multimeter', 'STU1004', 'STU1002', 7, 'Active', '2026-09-24', 'Handed over at 1:45 PM. Expected return 4:30 PM.'),
('TXN003', 1, 'REQ1024', 'Casio FX-991EX Calculator', 'STU1003', 'STU1001', 1, 'Completed', '2026-09-22', 'Exam emergency exchange. Returned immediately.'),
('TXN004', 2, 'REQ1025', 'Data Structures (CLRS Book)', 'STU1002', 'STU1001', 10, 'Returned', '2026-09-21', 'Returned back to bookshelf after evening study session.');

INSERT INTO notifications (notification_id, recipient_id, title, message, notification_type, is_read, target_link, created_at) VALUES
(1, 'STU1001', 'Urgent Request Match', 'Your calculator request #REQ1024 has 2 nearby matching students with available items!', 'alert', FALSE, '/request/REQ1024', '2026-09-24 18:35:00'),
(2, 'STU1004', 'Request Accepted!', 'Rahul Sharma accepted your request for Digital Multimeter. Pickup location: Main block 1st floor.', 'success', FALSE, '/request/REQ1026', '2026-09-24 18:15:00'),
(3, 'STU1001', 'Exchange Completed', 'Transaction TXN001 (White Lab Coat) has been marked as Completed and Returned.', 'info', TRUE, '/transactions', '2026-09-23 15:15:00'),
(4, 'STU1002', 'Return Reminder', 'Reminder: Digital Multimeter (TXN002) is due to be returned by 4:30 PM today.', 'warning', TRUE, '/transactions', '2026-09-24 16:30:00'),
(5, 'ALL', 'New Urgent Campus Request', 'Rahul Sharma urgently needs a 65W USB-C Charger in Techpark 1st floor.', 'alert', FALSE, '/request/REQ1028', '2026-09-24 18:30:00');

INSERT INTO student_feedback_reviews (transaction_id, reviewer_id, reviewee_id, rating, comments) VALUES
('TXN001', 'STU1001', 'STU1004', 5, 'Life saver! Provided clean lab coat right before the professor locked the exam door.'),
('TXN003', 'STU1003', 'STU1001', 5, 'Returned calculator right after calculus exam with full battery. Highly recommend!'),
('TXN004', 'STU1002', 'STU1001', 5, 'Book was in pristine condition, very polite student.');
