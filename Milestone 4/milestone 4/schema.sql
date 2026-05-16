-- ============================================================
--  Faculty Information Storage System
--  Milestone 4 — DDL Script (schema.sql)
--
--  Subject   : Database Systems Lab
--  Instructor: Ali Hassan
--  Group     : Muhammad Gulsher | Muhammad Ali Bilal
--  Semester  : BSSE-A
--  Commit    : M4: DDL scripts added, EER diagram verified
-- ============================================================

-- ── 0. Database Setup ────────────────────────────────────────
DROP DATABASE IF EXISTS faculty_info_system;
CREATE DATABASE faculty_info_system
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE faculty_info_system;

-- Disable FK checks during table creation to allow any order
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
--  TABLE 1: department
--
--  Stores all university departments.
--  NOTE: faculty_count was removed in Milestone 2 (3NF fix)
--        because it is a derived value. Use the aggregate
--        query below to get headcount dynamically:
--        SELECT dept_id, COUNT(*) AS total FROM faculty
--        GROUP BY dept_id;
--
--  Referenced by: faculty.dept_id
-- ============================================================
CREATE TABLE department (
    dept_id   INT            NOT NULL AUTO_INCREMENT,
    dept_name VARCHAR(100)   NOT NULL,
    hod_name  VARCHAR(100)   NULL,

    -- ── Constraints ─────────────────────────────────────────
    CONSTRAINT pk_department PRIMARY KEY (dept_id),
    CONSTRAINT uq_dept_name  UNIQUE      (dept_name),

    -- ── Check constraints ────────────────────────────────────
    -- dept_name must not be blank
    CONSTRAINT chk_dept_name_notempty
        CHECK (TRIM(dept_name) <> '')

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='University departments. faculty_count removed (M2 3NF).';


-- ── Indexes on department ────────────────────────────────────
-- dept_name is frequently searched (filter faculty by dept name)
CREATE INDEX idx_dept_name ON department(dept_name);


-- ============================================================
--  TABLE 2: faculty
--
--  Core table — stores all faculty member records.
--  dept_id is a FK to department (Many-to-One relationship).
--  One faculty belongs to exactly one department.
-- ============================================================
CREATE TABLE faculty (
    faculty_id    INT                  NOT NULL AUTO_INCREMENT,
    name          VARCHAR(100)         NOT NULL,
    email         VARCHAR(100)         NOT NULL,
    phone         VARCHAR(20)          NULL,
    cnic          VARCHAR(15)          NOT NULL,
    gender        ENUM('Male','Female') NOT NULL,
    date_of_birth DATE                 NULL,
    dept_id       INT                  NOT NULL,
    created_at    TIMESTAMP            NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- ── Constraints ─────────────────────────────────────────
    CONSTRAINT pk_faculty    PRIMARY KEY (faculty_id),
    CONSTRAINT uq_faculty_email UNIQUE  (email),
    CONSTRAINT uq_faculty_cnic  UNIQUE  (cnic),

    -- FK → department
    CONSTRAINT fk_faculty_dept
        FOREIGN KEY (dept_id)
        REFERENCES  department(dept_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    -- ── Check constraints ────────────────────────────────────
    -- Name must not be blank
    CONSTRAINT chk_faculty_name_notempty
        CHECK (TRIM(name) <> ''),

    -- Email must contain @ symbol (basic format check)
    CONSTRAINT chk_faculty_email_format
        CHECK (email LIKE '%@%.%'),

    -- CNIC must match Pakistani format: XXXXX-XXXXXXX-X
    CONSTRAINT chk_faculty_cnic_format
        CHECK (cnic REGEXP '^[0-9]{5}-[0-9]{7}-[0-9]$'),

    -- Date of birth must be in the past if provided
    CONSTRAINT chk_faculty_dob_past
        CHECK (date_of_birth IS NULL OR date_of_birth < CURDATE())

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Faculty member records. FK to department.';


-- ── Indexes on faculty ───────────────────────────────────────
-- FK column (required for FK performance in InnoDB)
CREATE INDEX idx_faculty_dept_id     ON faculty(dept_id);
-- Frequently filtered columns
CREATE INDEX idx_faculty_name        ON faculty(name);
CREATE INDEX idx_faculty_gender      ON faculty(gender);
CREATE INDEX idx_faculty_created_at  ON faculty(created_at);


-- ============================================================
--  TABLE 3: qualifications
--
--  Stores academic qualifications of faculty members.
--  One faculty member may have multiple qualifications (1:N).
--  Each row = one degree held by one faculty member.
-- ============================================================
CREATE TABLE qualifications (
    qual_id        INT          NOT NULL AUTO_INCREMENT,
    faculty_id     INT          NOT NULL,
    degree         VARCHAR(100) NOT NULL,
    institution    VARCHAR(150) NOT NULL,
    year_completed YEAR         NULL,

    -- ── Constraints ─────────────────────────────────────────
    CONSTRAINT pk_qualifications PRIMARY KEY (qual_id),

    -- FK → faculty
    CONSTRAINT fk_qual_faculty
        FOREIGN KEY (faculty_id)
        REFERENCES  faculty(faculty_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    -- Prevent exact duplicate qualification for same faculty
    CONSTRAINT uq_qual_faculty_degree_inst
        UNIQUE (faculty_id, degree, institution),

    -- ── Check constraints ────────────────────────────────────
    -- Degree name must not be blank
    CONSTRAINT chk_qual_degree_notempty
        CHECK (TRIM(degree) <> ''),

    -- Institution name must not be blank
    CONSTRAINT chk_qual_inst_notempty
        CHECK (TRIM(institution) <> ''),

    -- Year must be realistic (not before 1900, not in future)
    CONSTRAINT chk_qual_year_range
        CHECK (year_completed IS NULL
               OR (year_completed >= 1900
                   AND year_completed <= YEAR(CURDATE())))

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Academic qualifications. One faculty may have many.';


-- ── Indexes on qualifications ────────────────────────────────
-- FK column (InnoDB FK performance)
CREATE INDEX idx_qual_faculty_id  ON qualifications(faculty_id);
-- Frequently filtered: degree type, institution
CREATE INDEX idx_qual_degree      ON qualifications(degree);
CREATE INDEX idx_qual_institution ON qualifications(institution);
CREATE INDEX idx_qual_year        ON qualifications(year_completed);


-- ============================================================
--  TABLE 4: workload
--
--  Tracks courses assigned to each faculty member per semester.
--  One faculty member may have many workload records (1:N).
--  Each row = one course assigned to one faculty in one semester.
-- ============================================================
CREATE TABLE workload (
    workload_id  INT          NOT NULL AUTO_INCREMENT,
    faculty_id   INT          NOT NULL,
    course_name  VARCHAR(150) NOT NULL,
    credit_hours TINYINT      NOT NULL,
    semester     VARCHAR(20)  NOT NULL,

    -- ── Constraints ─────────────────────────────────────────
    CONSTRAINT pk_workload PRIMARY KEY (workload_id),

    -- FK → faculty
    CONSTRAINT fk_workload_faculty
        FOREIGN KEY (faculty_id)
        REFERENCES  faculty(faculty_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    -- A faculty member cannot teach the same course twice in the same semester
    CONSTRAINT uq_workload_faculty_course_sem
        UNIQUE (faculty_id, course_name, semester),

    -- ── Check constraints ────────────────────────────────────
    -- Course name must not be blank
    CONSTRAINT chk_workload_course_notempty
        CHECK (TRIM(course_name) <> ''),

    -- Credit hours must be between 1 and 6
    CONSTRAINT chk_workload_credits_range
        CHECK (credit_hours BETWEEN 1 AND 6),

    -- Semester must not be blank
    CONSTRAINT chk_workload_semester_notempty
        CHECK (TRIM(semester) <> '')

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Course assignments per faculty per semester.';


-- ── Indexes on workload ──────────────────────────────────────
-- FK column (InnoDB FK performance)
CREATE INDEX idx_workload_faculty_id  ON workload(faculty_id);
-- Frequently filtered: by semester, by course name
CREATE INDEX idx_workload_semester    ON workload(semester);
CREATE INDEX idx_workload_course_name ON workload(course_name);


-- ============================================================
--  TABLE 5: users
--
--  Handles authentication for admins and faculty portal users.
--  faculty_id is nullable — admin accounts are not linked to
--  any faculty record; faculty-role accounts are linked 1:1.
-- ============================================================
CREATE TABLE users (
    user_id    INT                    NOT NULL AUTO_INCREMENT,
    username   VARCHAR(50)            NOT NULL,
    password   VARCHAR(255)           NOT NULL,
    role       ENUM('admin','faculty') NOT NULL,
    faculty_id INT                    NULL,
    last_login TIMESTAMP              NULL,

    -- ── Constraints ─────────────────────────────────────────
    CONSTRAINT pk_users      PRIMARY KEY (user_id),
    CONSTRAINT uq_username   UNIQUE      (username),

    -- FK → faculty (nullable — admins have no faculty record)
    CONSTRAINT fk_users_faculty
        FOREIGN KEY (faculty_id)
        REFERENCES  faculty(faculty_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    -- ── Check constraints ────────────────────────────────────
    -- Username must not be blank
    CONSTRAINT chk_users_username_notempty
        CHECK (TRIM(username) <> ''),

    -- Password hash must be at least 60 chars (bcrypt minimum)
    CONSTRAINT chk_users_password_length
        CHECK (CHAR_LENGTH(password) >= 60),

    -- Business rule: if role is 'faculty', faculty_id must be set
    -- (admin rows intentionally have NULL faculty_id)
    CONSTRAINT chk_users_faculty_role
        CHECK (role = 'admin' OR faculty_id IS NOT NULL)

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Auth table. Admin accounts: faculty_id NULL. Faculty accounts: faculty_id linked.';


-- ── Indexes on users ─────────────────────────────────────────
-- FK column (InnoDB FK performance)
CREATE INDEX idx_users_faculty_id ON users(faculty_id);
-- Frequently queried: role filter, last login audit
CREATE INDEX idx_users_role       ON users(role);
CREATE INDEX idx_users_last_login ON users(last_login);


-- ── Re-enable FK checks ──────────────────────────────────────
SET FOREIGN_KEY_CHECKS = 1;


-- ============================================================
--  VERIFICATION QUERIES
--  Run after creation to confirm schema is correct.
--  (These are SELECT only — no data modification)
-- ============================================================

-- List all tables in the database
SHOW TABLES;

-- Show full CREATE statement for each table (includes all constraints & indexes)
SHOW CREATE TABLE department\G
SHOW CREATE TABLE faculty\G
SHOW CREATE TABLE qualifications\G
SHOW CREATE TABLE workload\G
SHOW CREATE TABLE users\G

-- Confirm all indexes were created
SHOW INDEX FROM department;
SHOW INDEX FROM faculty;
SHOW INDEX FROM qualifications;
SHOW INDEX FROM workload;
SHOW INDEX FROM users;

-- Confirm all foreign keys
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'faculty_info_system'
  AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME;

-- ============================================================
--  GitHub Commit Message:
--  M4: DDL scripts added, EER diagram verified
-- ============================================================
