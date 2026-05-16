# Faculty Information Storage System

## Database Systems Lab Project

### Instructor
Ali Hassan

### Group Members
- Muhammad Gulsher
- Muhammad Ali Bilal


### Semester
BSSE-A

---

# Project Overview

The Faculty Information Storage System is a relational database project developed for managing faculty-related information in educational institutions. The system replaces manual and spreadsheet-based record management with a centralized database solution.

The project stores and manages:

- Faculty personal information
- Department records
- Faculty qualifications
- Workload/course assignments
- User authentication data

The project follows database normalization principles and uses MySQL relational database concepts including ERD design, schema development, DDL, DML, and validation queries.

---

# Technologies Used

- MySQL
- MySQL Workbench
- GitHub
- CSV Data Files
- SQL (DDL & DML)

---

# Project Milestones

## Milestone 1 — ERD & Relational Schema

### Completed Tasks
- Created Entity Relationship Diagram (ERD)
- Designed relational database schema
- Defined relationships and cardinalities
- Added integrity constraints
- Initial normalization analysis

### Deliverables
- ERD Diagram
- Relational Schema Documentation

---

## Milestone 2 — Normalization & ERD Update

### Completed Tasks
- Applied First Normal Form (1NF)
- Applied Second Normal Form (2NF)
- Applied Third Normal Form (3NF)
- Identified redundant attributes
- Removed redundancy from schema
- Updated ERD after normalization

### Major Improvement
- Removed redundant `faculty_count` attribute from department table

### Deliverables
- Normalization Documentation
- Updated ERD
- Final Normalized Schema

---

## Milestone 3 — Dataset Preprocessing

### Tasks
- Generate realistic synthetic data
- Clean and preprocess dataset
- Handle missing values and formatting issues
- Create CSV files for each table
- Prepare project-specific dataflow documentation

### Deliverables
- CSV Files
- Dataflow Documentation

---

## Milestone 4 — Database Setup (DDL)

### Tasks
- Create database tables using SQL
- Define:
  - Primary Keys
  - Foreign Keys
  - NOT NULL constraints
  - UNIQUE constraints
  - CHECK constraints
- Add indexes
- Verify schema in MySQL Workbench

### Deliverables
- DDL Scripts
- Verified EER Diagram

---

## Milestone 5 — Data Population (DML)

### Tasks
- Import CSV data into database
- Execute INSERT statements
- Perform UPDATE and DELETE operations
- Run validation queries

### Validation Queries
- COUNT(*) checks
- NULL checks
- JOIN integrity checks

### Deliverables
- DML Scripts
- Validation Query Outputs

---

# Database Tables

The system contains the following tables:

1. faculty
2. department
3. qualifications
4. workload
5. users

---

# Relationships

| Relationship | Type |
|---|---|
| faculty → department | Many-to-One |
| faculty → qualifications | One-to-Many |
| faculty → workload | One-to-Many |
| users → faculty | Optional One-to-One |

---

# Normalization

The database schema conforms to:

- First Normal Form (1NF)
- Second Normal Form (2NF)
- Third Normal Form (3NF)

Normalization was applied to:
- reduce redundancy
- improve consistency
- maintain referential integrity

---

#
