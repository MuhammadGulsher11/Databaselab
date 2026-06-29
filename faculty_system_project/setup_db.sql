-- ============================================================
--  Faculty Information Storage System
--  setup_db.sql  —  Run this ONCE before starting the app
--
--  Subject   : Database Systems Lab
--  Instructor: Ali Hassan
--  Group     : Muhammad Gulsher | Muhammad Ali Bilal
--  Semester  : BSSE-A
--
--  HOW TO RUN:
--    Option 1: MySQL Workbench → open this file → Run (Ctrl+Shift+Enter)
--    Option 2: mysql -u root -p < setup_db.sql
--
--  Default Login After Setup:
--    Username: admin
--    Password: admin123
-- ============================================================

DROP DATABASE IF EXISTS faculty_info_system;
CREATE DATABASE faculty_info_system
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE faculty_info_system;

SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
--  TABLE 1: department
-- ============================================================
CREATE TABLE department (
    dept_id   INT          NOT NULL AUTO_INCREMENT,
    dept_name VARCHAR(100) NOT NULL,
    hod_name  VARCHAR(100) NULL,

    CONSTRAINT pk_department PRIMARY KEY (dept_id),
    CONSTRAINT uq_dept_name  UNIQUE (dept_name),
    CONSTRAINT chk_dept_name_notempty CHECK (TRIM(dept_name) <> '')

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='University departments.';

CREATE INDEX idx_dept_name ON department(dept_name);


-- ============================================================
--  TABLE 2: faculty
-- ============================================================
CREATE TABLE faculty (
    faculty_id    INT          NOT NULL AUTO_INCREMENT,
    name          VARCHAR(100) NOT NULL,
    email         VARCHAR(100) NOT NULL,
    phone         VARCHAR(20)  NULL,
    cnic          VARCHAR(15)  NOT NULL,
    gender        ENUM('Male','Female') NOT NULL,
    date_of_birth DATE         NULL,
    dept_id       INT          NOT NULL,
    created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_faculty               PRIMARY KEY (faculty_id),
    CONSTRAINT uq_faculty_email         UNIQUE (email),
    CONSTRAINT uq_faculty_cnic          UNIQUE (cnic),

    CONSTRAINT fk_faculty_dept
        FOREIGN KEY (dept_id) REFERENCES department(dept_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT chk_faculty_name_notempty CHECK (TRIM(name)  <> ''),
    CONSTRAINT chk_faculty_email_format  CHECK (email LIKE '%@%.%'),
    CONSTRAINT chk_faculty_cnic_format   CHECK (cnic REGEXP '^[0-9]{5}-[0-9]{7}-[0-9]$')

    -- chk_faculty_dob_past removed: MySQL disallows CURDATE() in CHECK constraints
    -- DOB validation is enforced at the application layer (app.py)

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_faculty_dept_id    ON faculty(dept_id);
CREATE INDEX idx_faculty_name       ON faculty(name);
CREATE INDEX idx_faculty_gender     ON faculty(gender);
CREATE INDEX idx_faculty_created_at ON faculty(created_at);


-- ============================================================
--  TABLE 3: qualifications
-- ============================================================
CREATE TABLE qualifications (
    qual_id        INT          NOT NULL AUTO_INCREMENT,
    faculty_id     INT          NOT NULL,
    degree         VARCHAR(100) NOT NULL,
    institution    VARCHAR(150) NOT NULL,
    year_completed YEAR         NULL,

    CONSTRAINT pk_qualifications           PRIMARY KEY (qual_id),

    CONSTRAINT fk_qual_faculty
        FOREIGN KEY (faculty_id) REFERENCES faculty(faculty_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT uq_qual_faculty_degree_inst UNIQUE (faculty_id, degree, institution),

    CONSTRAINT chk_qual_degree_notempty    CHECK (TRIM(degree)      <> ''),
    CONSTRAINT chk_qual_inst_notempty      CHECK (TRIM(institution) <> ''),
    CONSTRAINT chk_qual_year_min           CHECK (year_completed IS NULL OR year_completed >= 1900)

    -- chk_qual_year_max removed: MySQL 8 disallows YEAR(CURDATE()) in CHECK constraints
    -- (Error 3814 — non-deterministic function not permitted)
    -- Upper-bound validation enforced at application layer in app.py

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_qual_faculty_id  ON qualifications(faculty_id);
CREATE INDEX idx_qual_degree      ON qualifications(degree);
CREATE INDEX idx_qual_institution ON qualifications(institution);
CREATE INDEX idx_qual_year        ON qualifications(year_completed);


-- ============================================================
--  TABLE 4: workload
-- ============================================================
CREATE TABLE workload (
    workload_id  INT          NOT NULL AUTO_INCREMENT,
    faculty_id   INT          NOT NULL,
    course_name  VARCHAR(150) NOT NULL,
    credit_hours TINYINT      NOT NULL,
    semester     VARCHAR(20)  NOT NULL,

    CONSTRAINT pk_workload PRIMARY KEY (workload_id),
    CONSTRAINT fk_workload_faculty
        FOREIGN KEY (faculty_id) REFERENCES faculty(faculty_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT uq_workload_faculty_course_sem UNIQUE (faculty_id, course_name, semester),
    CONSTRAINT chk_workload_course_notempty   CHECK (TRIM(course_name) <> ''),
    CONSTRAINT chk_workload_credits_range     CHECK (credit_hours BETWEEN 1 AND 6),
    CONSTRAINT chk_workload_semester_notempty CHECK (TRIM(semester) <> '')

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_workload_faculty_id  ON workload(faculty_id);
CREATE INDEX idx_workload_semester    ON workload(semester);
CREATE INDEX idx_workload_course_name ON workload(course_name);


-- ============================================================
--  TABLE 5: users
-- ============================================================
CREATE TABLE users (
    user_id       INT           NOT NULL AUTO_INCREMENT,
    username      VARCHAR(50)   NOT NULL,
    user_password VARCHAR(255)  NOT NULL,
    role          ENUM('admin','faculty') NOT NULL,
    faculty_id    INT           NULL,
    last_login    TIMESTAMP     NULL,

    CONSTRAINT pk_users    PRIMARY KEY (user_id),
    CONSTRAINT uq_username UNIQUE (username),

    CONSTRAINT fk_users_faculty
        FOREIGN KEY (faculty_id) REFERENCES faculty(faculty_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT chk_users_username_notempty CHECK (username <> ''),
    CONSTRAINT chk_users_password_length   CHECK (CHAR_LENGTH(user_password) >= 64)

    -- chk_users_faculty_role removed: MySQL Error 3823
    -- A column used in a FK referential action cannot also appear in a CHECK constraint
    -- This rule is enforced at the application layer in app.py

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_users_faculty_id ON users(faculty_id);
CREATE INDEX idx_users_role       ON users(role);
CREATE INDEX idx_users_last_login ON users(last_login);

SET FOREIGN_KEY_CHECKS = 1;


-- ============================================================
--  SEED DATA — Sample Departments
-- ============================================================
INSERT INTO department (dept_name, hod_name) VALUES
('Computer Science',            'Dr. Tariq Mehmood'),
('Software Engineering',        'Dr. Ayesha Siddiqui'),
('Electrical Engineering',      'Dr. Imran Khalid'),
('Mathematics',                 'Dr. Nadia Farooq'),
('Physics',                     'Dr. Bilal Akhtar'),
('Business Administration',     'Dr. Saima Raza'),
('English Literature',          'Dr. Zara Hussain');


-- ============================================================
--  SEED DATA — Sample Faculty
-- ============================================================
INSERT INTO faculty (name, email, phone, cnic, gender, date_of_birth, dept_id) VALUES
('Dr. Ahmed Ali',       'ahmed.ali@fis.edu.pk',       '0300-1234567', '35201-1234567-1', 'Male',   '1975-03-15', 1),
('Dr. Sara Khan',       'sara.khan@fis.edu.pk',       '0321-2345678', '35202-2345678-2', 'Female', '1980-07-22', 1),
('Prof. Usman Butt',    'usman.butt@fis.edu.pk',      '0333-3456789', '35203-3456789-3', 'Male',   '1978-11-05', 2),
('Dr. Fatima Malik',    'fatima.malik@fis.edu.pk',    '0345-4567890', '35204-4567890-4', 'Female', '1983-02-18', 2),
('Dr. Kamran Shah',     'kamran.shah@fis.edu.pk',     '0300-5678901', '35205-5678901-5', 'Male',   '1972-09-30', 3),
('Ms. Nadia Hassan',    'nadia.hassan@fis.edu.pk',    '0321-6789012', '35206-6789012-6', 'Female', '1990-05-12', 4),
('Mr. Bilal Qureshi',   'bilal.qureshi@fis.edu.pk',   '0333-7890123', '35207-7890123-7', 'Male',   '1988-12-25', 5);


-- ============================================================
--  SEED DATA — Qualifications
-- ============================================================
INSERT INTO qualifications (faculty_id, degree, institution, year_completed) VALUES
(1, 'PhD Computer Science',     'LUMS Lahore',           2005),
(1, 'MS Computer Science',      'COMSATS University',    2001),
(2, 'PhD Artificial Intelligence','University of Punjab', 2010),
(2, 'BS Computer Science',      'GC University Lahore',  2003),
(3, 'PhD Software Engineering', 'NED University',        2007),
(3, 'MS Software Engineering',  'FAST NUCES',            2003),
(4, 'PhD Information Systems',  'Quaid-i-Azam University',2012),
(5, 'PhD Electrical Engineering','UET Lahore',           2004),
(6, 'MS Mathematics',           'Islamabad University',  2014),
(7, 'MS Physics',               'University of Karachi', 2015);


-- ============================================================
--  SEED DATA — Workload
-- ============================================================
INSERT INTO workload (faculty_id, course_name, credit_hours, semester) VALUES
(1, 'Database Systems',         3, 'Fall-2024'),
(1, 'Data Structures',          3, 'Fall-2024'),
(2, 'Artificial Intelligence',  3, 'Fall-2024'),
(2, 'Machine Learning',         3, 'Fall-2024'),
(3, 'Software Engineering',     3, 'Fall-2024'),
(3, 'Design Patterns',          2, 'Fall-2024'),
(4, 'Information Systems',      3, 'Fall-2024'),
(5, 'Digital Logic Design',     3, 'Fall-2024'),
(5, 'Circuits & Electronics',   3, 'Fall-2024'),
(6, 'Calculus I',               3, 'Fall-2024'),
(7, 'Applied Physics',          3, 'Fall-2024');


-- ============================================================
--  SEED DATA — Default Admin User
--  Password: admin123  (SHA-256 hash)
-- ============================================================
INSERT INTO users (username, user_password, role, faculty_id) VALUES
('admin',
 '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9',
 'admin',
 NULL);

-- ============================================================
--  VERIFICATION
-- ============================================================
SELECT 'Setup complete!' AS status;
SELECT TABLE_NAME, TABLE_ROWS
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'faculty_info_system';
