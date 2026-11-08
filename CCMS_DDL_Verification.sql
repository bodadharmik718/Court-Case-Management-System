-- Run after CCMS_DDL.sql in the same PostgreSQL database/schema.

-- 1. Confirm that all 31 expected base tables exist in the public schema.
SELECT COUNT(*) AS ccms_base_tables_found
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
  AND table_name IN (
    'court','courtroom','cause_list','hearing','judge','party','court_case',
    'judgment','court_order','lawyer','petition','evidence','witness',
    'adjournment','notification','audit_log','court_clerk','filing_defect',
    'case_status_history','bench','app_user','role','document','case_party',
    'case_witness','bench_judge','judge_court_order','judge_evidence',
    'lawyer_party','lawyer_case','hearing_witness'
  );

-- Expected result: 31

-- 2. List the CCMS tables that exist. The result should contain 31 rows.
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
  AND table_name IN (
    'court','courtroom','cause_list','hearing','judge','party','court_case',
    'judgment','court_order','lawyer','petition','evidence','witness',
    'adjournment','notification','audit_log','court_clerk','filing_defect',
    'case_status_history','bench','app_user','role','document','case_party',
    'case_witness','bench_judge','judge_court_order','judge_evidence',
    'lawyer_party','lawyer_case','hearing_witness'
  )
ORDER BY table_name;

-- 3. List primary-key, foreign-key, unique, and check constraints on CCMS tables.
SELECT
    tc.table_name,
    tc.constraint_type,
    tc.constraint_name
FROM information_schema.table_constraints AS tc
WHERE tc.table_schema = 'public'
  AND tc.table_name IN (
    'court','courtroom','cause_list','hearing','judge','party','court_case',
    'judgment','court_order','lawyer','petition','evidence','witness',
    'adjournment','notification','audit_log','court_clerk','filing_defect',
    'case_status_history','bench','app_user','role','document','case_party',
    'case_witness','bench_judge','judge_court_order','judge_evidence',
    'lawyer_party','lawyer_case','hearing_witness'
  )
ORDER BY tc.table_name, tc.constraint_type, tc.constraint_name;

-- 4. Confirm the current-status view exists.
SELECT table_name AS view_name
FROM information_schema.views
WHERE table_schema = 'public'
  AND table_name = 'case_current_status';

-- 5. Quick structural check of the derived-status view (it returns no rows
-- until case data are inserted, which is expected at this stage).
SELECT * FROM case_current_status LIMIT 10;

-- 6. Confirm that the app-user password hash needed by the sign-in screen exists.
SELECT column_name, is_nullable
FROM information_schema.columns
WHERE table_schema='public' AND table_name='app_user' AND column_name='password_hash';
