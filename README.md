# ⚖️ Court Case Management System (CCMS)

[![Python](https://img.shields.io/badge/Python-3.12%2B-blue.svg?logo=python&logoColor=white)](https://www.python.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-18.0%2B-336791.svg?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Streamlit](https://img.shields.io/badge/Streamlit-1.37%2B-FF4B4B.svg?logo=streamlit&logoColor=white)](https://streamlit.io/)
[![Psycopg 3](https://img.shields.io/badge/Psycopg-3.2%2B-brightgreen.svg)](https://www.psycopg.org/psycopg3/)
[![Tests](https://img.shields.io/badge/Tests-17%20Passed-success.svg?logo=pytest&logoColor=white)](https://docs.pytest.org/)
[![Security](https://img.shields.io/badge/Security-Argon2id%20%7C%20Parameterized%20SQL-purple.svg)](https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html)

A secure, enterprise-grade **Court Case Management System (CCMS)** built for the **MC212 Database Management Systems** coursework. The system connects a responsive **Streamlit** web user interface to a normalized 31-table **PostgreSQL** relational database using **Psycopg 3**, featuring full CRUD workflows, role-based access control, cryptographic password hashing, automated identifier generation, and an append-only audit trail.

---

## 📌 Table of Contents

- [Overview & Architecture](#-overview--architecture)
- [Key Features](#-key-features)
- [Database Schema & Design](#-database-schema--design)
- [Tech Stack](#-tech-stack)
- [Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Database Setup](#database-setup)
  - [Environment Configuration](#environment-configuration)
  - [Running the Application](#running-the-application)
- [Demo Credentials](#-demo-credentials)
- [Automated Testing](#-automated-testing)
- [Repository Structure](#-repository-structure)
- [Security & Integrity Safeguards](#-security--integrity-safeguards)
- [Team & Acknowledgments](#-team--acknowledgments)

---

## 🏛️ Overview & Architecture

The Court Case Management System manages the end-to-end lifecycle of legal cases—from electronic petition filing and defect scrutiny to bench allocation, hearing scheduling, judicial order issuance, and non-destructive case archival.

```
                      ┌──────────────────────────────────────────────┐
                      │              Streamlit Frontend              │
                      │  (Public Portal / Authenticated Dashboard)   │
                      └──────────────────────┬───────────────────────┘
                                             │ HTTP / WebSockets
                                             ▼
                      ┌──────────────────────────────────────────────┐
                      │             Python Service Layer             │
                      │   Auth (Argon2id) | RBAC | Case Services     │
                      └──────────────────────┬───────────────────────┘
                                             │ Parameterized SQL (%s)
                                             ▼
                      ┌──────────────────────────────────────────────┐
                      │            Psycopg 3 Driver Pool             │
                      │  (Atomic Transactions & Context Management)  │
                      └──────────────────────┬───────────────────────┘
                                             │ TCP (5432)
                                             ▼
                      ┌──────────────────────────────────────────────┐
                      │        PostgreSQL 18 Relational DB          │
                      │   31 Tables | Append-Only Audit Triggers     │
                      └──────────────────────────────────────────────┘
```

---

## ✨ Key Features

### 🌐 1. Public Portal (Unauthenticated)
* **Public Case Search:** Search by Case Unique Identifier (CUID), Case Number Record (CNR), or Case Title for published, non-confidential cases.
* **Published Cause Lists:** View daily court rosters and download cause lists as CSV files.
* **Public Orders & Judgments:** Read and download certified, digitally signed judicial orders.

### ⚖️ 2. Comprehensive Case Registry (Full CRUD)
* **Create (INSERT):** Register new cases with automatic CUID/CNR generation, monetary valuations, and jurisdiction notes.
* **Read (SELECT):** Search, filter, and view detailed case litigation timelines, active bench assignments, and representations.
* **Update (UPDATE):** Edit permitted case parameters and confidentiality flags with constraint checks.
* **Delete (ARCHIVE):** Non-destructive case archival enforcing judicial record retention policies with audit reasons.

### 📝 3. E-Filing & Registry Scrutiny
* **Electronic Petition Submission:** Advocates file petitions with petitioner/respondent profiles and multi-document PDF uploads.
* **Transaction Safety:** Petitions, party links, counsel representation, and private documents are saved in a single atomic database transaction.
* **Defect Scrutiny:** Registry clerks approve or return filings, setting a 7-day cure window with automated notification queuing.
* **Court Fee Assessment:** Manual fee assessment, status tracking (Due/Paid/Waived), and payment reference recording.

### 📅 4. Judicial Bench & Hearing Scheduling
* **Bench Allocation:** Assign cases to single or multi-judge benches.
* **Conflict Detection:** Automated overlap checks prevent double-booking courtrooms or presiding judges on the same date and time.
* **Court Holiday Calendar:** Prevents scheduling on official court holidays.
* **Proceedings & Attendance:** Record hearing outcomes, attendee statuses (Present/Absent/Excused/Remote), and subsequent hearing dates.

### 📜 5. Judicial Orders & Agency Liaison
* **Draft Orders & Judgments:** Formulate order drafts with digital signature verification hashes before public dissemination.
* **Summons & Warrant Tracking:** Agency liaison updates for summons dispatch, warrant executions, and bail status.
* **Immutable Audit Trail:** PostgreSQL triggers reject modifications or deletions of audit events, signed orders, and status timelines.

---

## 🗄️ Database Schema & Design

The database schema comprises **31 normalized relational tables** in PostgreSQL:

| Table Category | Key Tables |
|---|---|
| **Core Judiciary** | `court`, `courtroom`, `judge`, `court_clerk`, `bench`, `bench_judge`, `court_holiday` |
| **Case & Litigation** | `court_case`, `case_party`, `case_status_history`, `case_bench_assignment`, `case_transfer_history` |
| **Parties & Counsel** | `party`, `lawyer`, `lawyer_case`, `lawyer_party`, `witness`, `case_witness` |
| **Filings & Scrutiny** | `petition`, `filing_defect`, `case_fee_assessment`, `document` |
| **Hearings & Proceedings** | `hearing`, `hearing_attendance`, `hearing_witness`, `cause_list`, `adjournment` |
| **Orders & Judgments** | `court_order`, `judgment`, `judge_court_order`, `judge_evidence`, `evidence` |
| **Security & Auditing** | `app_user`, `role`, `app_permission`, `role_permission`, `auth_event_log`, `audit_log`, `notification`, `notification_delivery_attempt`, `agency_liaison_event` |

---

## 💻 Tech Stack

* **Backend & Logic:** Python 3.12
* **Frontend UI:** Streamlit 1.37+
* **Database:** PostgreSQL 18
* **Database Driver:** Psycopg 3 (`psycopg[binary] >= 3.2`)
* **Security & Cryptography:** Argon2id (`argon2-cffi >= 23.1`), Bcrypt (`bcrypt >= 4.2`)
* **Data Processing:** Pandas (`pandas >= 2.2`)
* **Testing Suite:** Pytest (`pytest >= 8.0`)

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed on your machine:
* [Python 3.10+](https://www.python.org/downloads/)
* [PostgreSQL 16+](https://www.postgresql.org/download/) (PostgreSQL 18 recommended)
* Git

---

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/<your-username>/Court-Case-Management-System.git
   cd Court-Case-Management-System
   ```

2. **Create and activate a virtual environment:**
   ```powershell
   # Windows (PowerShell)
   python -m venv .venv
   .\.venv\Scripts\Activate.ps1

   # Linux / macOS
   python3 -m venv .venv
   source .venv/bin/activate
   ```

3. **Install required dependencies:**
   ```bash
   python -m pip install --upgrade pip
   python -m pip install -r requirements.txt
   ```

---

### Database Setup

1. **Start your PostgreSQL service** and open `psql` or `pgAdmin 4`.
2. **Create the database:**
   ```sql
   CREATE DATABASE ccms_lab11;
   ```
3. **Run the database migration scripts in order:**
   Connect to `ccms_lab11` and execute:
   * `CCMS_DDL.sql` (Creates 31 base relational tables and integrity constraints)
   * `CCMS_Real_Data.sql` (Populates ~85-110 synthetic seed rows per table)
   * `CCMS_DDL_Verification.sql` (Verifies schema integrity and row counts)
   * `CCMS_Functionality_Migration_001.sql` (Applies permissions, audit triggers, and security indices)

---

### Environment Configuration

1. Copy the example configuration to create your local `.env`:
   ```powershell
   # Windows PowerShell
   Copy-Item .env.example .env

   # Linux / macOS
   cp .env.example .env
   ```

2. Open `.env` and specify your local PostgreSQL credentials:
   ```ini
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=ccms_lab11
   DB_USER=postgres
   DB_PASSWORD=your_postgres_password_here
   DOCUMENT_STORAGE_PATH=storage/documents
   MAX_UPLOAD_BYTES=26214400
   ```
   > ⚠️ **Important:** Never commit `.env` to GitHub. It is ignored by `.gitignore`.

---

### Running the Application

Launch the Streamlit web server:

```powershell
python -m streamlit run app.py
```

Open your browser at:
👉 **`http://localhost:8501`**

---

## 🔑 Demo Credentials

All seeded accounts are initialized with the coursework demonstration password:
🔑 **Password:** `CourtAccess@2026`

| Username | Role | Permissions / Scope |
|---|---|---|
| `registry.admin` | **System Administrator** | Full administrative rights, user linking, audit access |
| `court.reader` | **Court Clerk** | Hearing proceedings, courtroom management, evidence |
| `filing.desk` | **Filing & Scrutiny Clerk** | Scrutinize petitions, issue defect notices, fee assessments |
| `case.manager` | **Case Manager** | Lifecycle transitions, case updates, bench assignments |
| `legal.aid` | **Advocate / Legal Counsel** | E-filing, petition submissions, adjournment requests |
| `cause.list` | **Cause List Clerk** | Cause list management and public publication |

---

## 🧪 Automated Testing

Run the test suite to verify authorization rules, case validators, database connections, and upload workflows:

```powershell
python -m pytest -q
```

**Result:**
```text
.................                                                        [100%]
17 passed in 0.39s
```

You can also verify Python compilation across all modules:
```powershell
python -m compileall .
```

---

## 📂 Repository Structure

```text
├── .streamlit/               # Streamlit configuration and themes
├── auth/                     # Argon2id password verification and RBAC checks
│   ├── coursework_auth.py    # Authentication logic against app_user
│   └── permissions.py        # Permission gatekeeper
├── config/                   # Settings and environment variables loader
│   └── settings.py
├── database/                 # Connection management and health checks
│   └── connection.py         # Context-managed Psycopg 3 connection pool
├── repositories/             # Parameterized SQL queries (CRUD)
│   └── coursework_case_repository.py
├── services/                 # Business logic and domain workflows
│   ├── access_service.py     # Public portal and admin user operations
│   ├── fee_service.py        # Fee assessment and payment recording
│   ├── filing_review_service.py # Filing scrutiny and defect handling
│   ├── filing_service.py     # E-filing transactional submissions
│   ├── judicial_service.py   # Cause lists, orders, and adjournments
│   ├── liaison_service.py    # Summons, warrants, and police liaison
│   ├── lifecycle_service.py  # Allowed case status state transitions
│   ├── notification_service.py # Queueing and dispatching email notices
│   ├── scheduling_service.py # Bench assignment and hearing conflict checks
│   └── transfer_service.py   # Inter-court case transfers
├── tests/                    # Pytest test cases
│   ├── test_authorization.py
│   ├── test_case_validator.py
│   ├── test_database.py
│   ├── test_document_upload.py
│   └── test_service_workflows.py
├── utils/                    # Secure upload helpers and validators
├── validators/               # Input validation for CUID/CNR/Dates
├── app.py                    # Main Streamlit web application
├── CCMS_DDL.sql              # Schema DDL (31 tables)
├── CCMS_Real_Data.sql        # Seed data script
├── CCMS_Functionality_Migration_001.sql # RBAC, triggers, audit tables
├── requirements.txt          # Python package dependencies
├── .env.example              # Template environment configuration
├── .gitignore                # Protects credentials and bytecode
└── README.md                 # Project documentation
```

---

## 🛡️ Security & Integrity Safeguards

* **Zero SQL Injection:** All database interactions strictly utilize `%s` placeholders with parameterized parameter tuples. String formatting (`f"..."`) is never used for SQL statements.
* **Argon2id Password Hashing:** User passwords are encrypted with Argon2id parameters (`t=2, m=19456, p=1`), providing resistance against GPU/ASIC brute-force attacks.
* **Account Lockout:** Failed login attempts are logged in `auth_event_log`. 5 consecutive failures trigger a temporary 15-minute lockout.
* **Append-Only Triggers:** Database triggers block `UPDATE` or `DELETE` on `audit_log`, `case_status_history`, and signed `court_order` records.
* **Non-destructive Archival:** Cases cannot be deleted from the database once filed; they are safely marked `archived_at` with a mandatory reason.

---

## 👥 Team & Acknowledgments

**MC212 – Database Management Systems**  
*Team 8:*
* **Boda Dharmik** (202503060)
* **Aambaliya Kirtan** (202503015)

Instructor: `minal_bhise@dau.ac.in`  
Teaching Assistants: `202303010@dau.ac.in`, `202303016@dau.ac.in`

---

*Developed for academic coursework. Do not reuse demo credentials in production environments.*
