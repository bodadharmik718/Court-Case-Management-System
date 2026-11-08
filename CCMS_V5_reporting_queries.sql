-- ============================================================================
-- CCMS V5 - Practical reporting queries
-- Run after CCMS_V5_schema.sql in the same database.
-- These are read-only examples for dashboards, registry reports and audits.
-- Replace the clearly marked example filter values for your own data.
-- ============================================================================

-- 1. Pending cases by court/forum and case category
SELECT current_forum_name, category_name, COUNT(*) AS pending_cases
FROM v_pending_case_dashboard
GROUP BY current_forum_name, category_name
ORDER BY current_forum_name, pending_cases DESC;

-- 2. Oldest pending cases in the system
SELECT case_id, cnr, case_title, current_forum_name, current_status_name,
       filing_date, days_since_filing
FROM v_pending_case_dashboard
ORDER BY days_since_filing DESC
LIMIT 50;

-- 3. Cases with no future scheduled hearing
SELECT vcs.case_id, vcs.cnr, vcs.case_title, vcs.current_forum_name,
       vcs.current_status_name, vcs.filing_date
FROM v_case_current_status vcs
JOIN case_status cs ON cs.status_code = vcs.current_status_code
WHERE cs.is_terminal = FALSE
  AND NOT EXISTS (
      SELECT 1 FROM hearing h
      WHERE h.case_id = vcs.case_id
        AND h.hearing_date >= CURRENT_DATE
        AND h.hearing_status = 'SCHEDULED'
  )
ORDER BY vcs.filing_date;

-- 4. Hearings scheduled for the next seven calendar days
SELECT *
FROM v_upcoming_hearings
WHERE hearing_date < CURRENT_DATE + 7
ORDER BY hearing_date, start_time;

-- 5. Published cause list for a selected date (change the date)
SELECT forum_name, list_date, session_name, version_number,
       sequence_number, cnr, case_title, hearing_purpose, bench_name, room_code
FROM v_cause_list_details
WHERE list_date = DATE '2026-11-03'
  AND publication_status = 'PUBLISHED'
ORDER BY forum_name, session_name, version_number, sequence_number;

-- 6. Upcoming hearing workload for each judge
SELECT judge_id, judge_name, upcoming_hearings
FROM v_judge_upcoming_hearing_load
ORDER BY upcoming_hearings DESC, judge_name;

-- 7. Average time to first final judgment by forum and case type
SELECT vcs.current_forum_name, vcs.case_type_name,
       COUNT(*) FILTER (WHERE d.days_to_first_final_judgment IS NOT NULL) AS disposed_cases,
       ROUND(AVG(d.days_to_first_final_judgment)::NUMERIC, 1) AS average_days,
       MIN(d.days_to_first_final_judgment) AS fastest_days,
       MAX(d.days_to_first_final_judgment) AS slowest_days
FROM v_case_disposal_time d
JOIN v_case_current_status vcs ON vcs.case_id = d.case_id
GROUP BY vcs.current_forum_name, vcs.case_type_name
ORDER BY vcs.current_forum_name, vcs.case_type_name;

-- 8. Complete status history for one case (replace 1 with a case_id)
SELECT h.changed_at, h.status_code, s.status_name,
       h.remarks, u.username AS changed_by
FROM case_status_history h
JOIN case_status s ON s.status_code = h.status_code
LEFT JOIN user_account u ON u.user_id = h.changed_by_user_id
WHERE h.case_id = 1
ORDER BY h.changed_at, h.case_status_history_id;

-- 9. Cases with the most adjournments
SELECT case_id, cnr, case_title, total_scheduled_hearings,
       total_adjournment_requests, approved_adjournments,
       rejected_adjournments, pending_adjournments
FROM v_case_adjournment_summary
ORDER BY approved_adjournments DESC, total_adjournment_requests DESC
LIMIT 50;

-- 10. Parties and their roles in a particular case
SELECT c.case_id, c.cnr, p.party_id,
       COALESCE(per.full_name, org.organization_name) AS party_name,
       cpr.role_name, cp.is_primary, cp.joined_on, cp.ceased_on
FROM case_party cp
JOIN case_file c ON c.case_id = cp.case_id
JOIN party p ON p.party_id = cp.party_id
JOIN case_party_role cpr ON cpr.party_role_code = cp.party_role_code
LEFT JOIN person per ON per.person_id = p.person_id
LEFT JOIN organization org ON org.organization_id = p.organization_id
WHERE c.case_id = 1
ORDER BY cp.is_primary DESC, cpr.role_name, party_name;

-- 11. Current lawyer representations for a case
SELECT c.case_id, c.cnr,
       per.full_name AS lawyer_name,
       reg.bar_council_name, reg.bar_registration_number,
       COALESCE(party_person.full_name, party_org.organization_name) AS represented_party,
       cpr.role_name, lr.appointed_on
FROM lawyer_representation lr
JOIN lawyer_profile lp ON lp.lawyer_id = lr.lawyer_id
JOIN person per ON per.person_id = lp.person_id
LEFT JOIN lawyer_registration reg ON reg.lawyer_id = lp.lawyer_id
JOIN case_party cp ON cp.case_party_id = lr.case_party_id
JOIN case_party_role cpr ON cpr.party_role_code = cp.party_role_code
JOIN case_file c ON c.case_id = cp.case_id
JOIN party p ON p.party_id = cp.party_id
LEFT JOIN person party_person ON party_person.person_id = p.person_id
LEFT JOIN organization party_org ON party_org.organization_id = p.organization_id
WHERE c.case_id = 1
  AND lr.ended_on IS NULL
  AND lr.representation_status = 'ACTIVE'
ORDER BY lawyer_name;

-- 12. Workload and experience specializations of each lawyer
SELECT p.full_name AS lawyer_name, ls.specialization_name,
       lsp.years_experience, lsp.is_primary, load.active_case_count,
       load.total_cases_ever_represented
FROM lawyer_profile lp
JOIN person p ON p.person_id = lp.person_id
LEFT JOIN lawyer_specialization lsp ON lsp.lawyer_id = lp.lawyer_id
LEFT JOIN legal_specialization ls ON ls.specialization_code = lsp.specialization_code
LEFT JOIN v_lawyer_active_case_load load ON load.lawyer_id = lp.lawyer_id
ORDER BY lawyer_name, lsp.is_primary DESC, ls.specialization_name;

-- 13. Potential lawyer conflict: same lawyer represents opposing sides in one case
-- This is a screening report, not a legal finding of professional misconduct.
SELECT lp.lawyer_id, per.full_name AS lawyer_name,
       c.case_id, c.cnr, c.case_title,
       STRING_AGG(DISTINCT cpr.role_name, ', ' ORDER BY cpr.role_name) AS represented_roles
FROM lawyer_representation lr
JOIN lawyer_profile lp ON lp.lawyer_id = lr.lawyer_id
JOIN person per ON per.person_id = lp.person_id
JOIN case_party cp ON cp.case_party_id = lr.case_party_id
JOIN case_party_role cpr ON cpr.party_role_code = cp.party_role_code
JOIN case_file c ON c.case_id = cp.case_id
WHERE lr.ended_on IS NULL
  AND lr.representation_status = 'ACTIVE'
GROUP BY lp.lawyer_id, per.full_name, c.case_id, c.cnr, c.case_title
HAVING BOOL_OR(cpr.party_role_code IN ('PETITIONER','PLAINTIFF','APPELLANT','COMPLAINANT'))
   AND BOOL_OR(cpr.party_role_code IN ('DEFENDANT','RESPONDENT','ACCUSED'));

-- 14. Open filing defects that are overdue
SELECT * FROM v_open_filing_defects
WHERE is_overdue = TRUE
ORDER BY cure_deadline, identified_at;

-- 15. Filing scrutiny / verification segregation-of-duties report
-- Compares the latest review at each stage; this is an operational check.
WITH latest_stage_review AS (
    SELECT DISTINCT ON (filing_id, review_stage)
           filing_id, review_stage, reviewed_by_user_id, review_result, reviewed_at
    FROM filing_review
    ORDER BY filing_id, review_stage, reviewed_at DESC, filing_review_id DESC
)
SELECT cf.filing_id, cf.filing_number, cf.title,
       s.reviewed_by_user_id AS scrutiny_user_id,
       v.reviewed_by_user_id AS verification_user_id,
       CASE
         WHEN s.filing_id IS NULL THEN 'INCOMPLETE: scrutiny missing'
         WHEN v.filing_id IS NULL THEN 'INCOMPLETE: verification missing'
         WHEN s.reviewed_by_user_id IS NULL OR v.reviewed_by_user_id IS NULL
           THEN 'INCOMPLETE: reviewer not recorded'
         WHEN s.reviewed_by_user_id = v.reviewed_by_user_id
           THEN 'REVIEW: same user performed both stages'
         ELSE 'PASS: different users'
       END AS segregation_result
FROM case_filing cf
LEFT JOIN latest_stage_review s
  ON s.filing_id = cf.filing_id AND s.review_stage = 'INITIAL_SCRUTINY'
LEFT JOIN latest_stage_review v
  ON v.filing_id = cf.filing_id AND v.review_stage = 'VERIFICATION'
ORDER BY cf.filing_id;

-- 16. Filing queue by status and age
SELECT filing_status_code, COUNT(*) AS filing_count,
       MIN(submitted_at) AS oldest_submission,
       ROUND(AVG(CURRENT_DATE - submitted_at::DATE)::NUMERIC, 1) AS average_age_days
FROM case_filing
GROUP BY filing_status_code
ORDER BY filing_count DESC;

-- 17. Evidence counts by admission status and evidence type
SELECT evidence_type_code, admission_status,
       COUNT(*) AS evidence_count,
       MIN(submission_date) AS first_submission,
       MAX(submission_date) AS latest_submission
FROM evidence_item
GROUP BY evidence_type_code, admission_status
ORDER BY evidence_type_code, evidence_count DESC;

-- 18. Full chain-of-custody history for an evidence item (replace 1)
SELECT e.evidence_id, e.evidence_title,
       ce.event_at, ce.event_type, ce.from_custodian, ce.to_custodian,
       ce.location_description, u.username AS recorded_by, ce.notes
FROM evidence_custody_event ce
JOIN evidence_item e ON e.evidence_id = ce.evidence_id
LEFT JOIN user_account u ON u.user_id = ce.recorded_by_user_id
WHERE e.evidence_id = 1
ORDER BY ce.event_at, ce.custody_event_id;

-- 19. Witness summons that have not been served
SELECT ws.summons_id, c.case_id, c.cnr,
       COALESCE(per.full_name, org.organization_name) AS witness_name,
       ws.issued_on, ws.service_status, ws.next_required_date, ws.return_reason
FROM witness_summons ws
JOIN case_party cp ON cp.case_party_id = ws.case_party_id
JOIN case_file c ON c.case_id = cp.case_id
JOIN party p ON p.party_id = cp.party_id
LEFT JOIN person per ON per.person_id = p.person_id
LEFT JOIN organization org ON org.organization_id = p.organization_id
WHERE ws.service_status IN ('ISSUED','UNSERVED')
ORDER BY ws.issued_on;

-- 20. Witness attendance and testimony by hearing
SELECT h.hearing_id, h.hearing_date, c.cnr,
       per.full_name AS witness_name, hw.attendance_status,
       hw.testimony_summary, hw.testimony_recorded_at
FROM hearing_witness hw
JOIN hearing h ON h.hearing_id = hw.hearing_id
JOIN case_file c ON c.case_id = h.case_id
JOIN case_party cp ON cp.case_party_id = hw.case_party_id
JOIN party p ON p.party_id = cp.party_id
JOIN person per ON per.person_id = p.person_id
ORDER BY h.hearing_date DESC;

-- 21. Orders and judgments for one case (replace 1)
SELECT co.order_id, co.order_date, cot.order_type_name,
       co.order_number, co.order_status,
       j.judgment_id, j.judgment_type, j.pronouncement_date,
       j.is_final, j.verdict_summary
FROM court_order co
JOIN court_order_type cot ON cot.order_type_code = co.order_type_code
LEFT JOIN judgment j ON j.order_id = co.order_id
WHERE co.case_id = 1
ORDER BY co.order_date, co.order_id;

-- 22. Appeals and the orders challenged
SELECT ad.appeal_case_id, appeal_case.cnr AS appeal_cnr,
       ad.original_case_id, original_case.cnr AS original_cnr,
       ad.appeal_type, ad.filed_on,
       co.order_id, co.order_date, ad.appeal_status, ad.outcome_summary
FROM appeal_detail ad
JOIN case_file appeal_case ON appeal_case.case_id = ad.appeal_case_id
JOIN case_file original_case ON original_case.case_id = ad.original_case_id
LEFT JOIN court_order co ON co.order_id = ad.challenged_order_id
ORDER BY ad.filed_on DESC;

-- 23. Statutory provisions linked to cases
SELECT c.case_id, c.cnr, c.case_title,
       s.short_title, s.enactment_year,
       lp.provision_reference, lp.provision_heading,
       clp.application_side, clp.notes
FROM case_legal_provision clp
JOIN case_file c ON c.case_id = clp.case_id
JOIN legal_provision lp ON lp.provision_id = clp.provision_id
JOIN statute s ON s.statute_id = lp.statute_id
ORDER BY c.case_id, s.short_title, lp.provision_reference;

-- 24. Outstanding court fees by case
SELECT case_id, cnr, case_title, outstanding_amount
FROM v_outstanding_case_fees
WHERE outstanding_amount > 0
ORDER BY outstanding_amount DESC;

-- 25. Failed or pending notifications
SELECT n.notification_id, n.recipient_user_id, u.username,
       n.case_id, n.title, n.delivery_channel, n.notification_status,
       n.created_at, MAX(a.attempted_at) AS last_attempt,
       MAX(a.failure_reason) FILTER (WHERE a.attempt_status = 'FAILED') AS last_failure_reason
FROM notification n
JOIN user_account u ON u.user_id = n.recipient_user_id
LEFT JOIN notification_delivery_attempt a ON a.notification_id = n.notification_id
WHERE n.notification_status IN ('PENDING','QUEUED','FAILED')
GROUP BY n.notification_id, n.recipient_user_id, u.username,
         n.case_id, n.title, n.delivery_channel, n.notification_status, n.created_at
ORDER BY n.created_at;

-- 26. Recent audit events for a case (replace 1)
SELECT a.event_timestamp, a.action_code, a.entity_name,
       a.entity_primary_key, u.username, a.reason,
       a.before_state, a.after_state
FROM audit_log a
LEFT JOIN user_account u ON u.user_id = a.user_id
WHERE a.case_id = 1
ORDER BY a.event_timestamp DESC
LIMIT 100;

-- 27. Possible courtroom double-bookings (requires scheduled start/end times)
SELECT h1.hearing_id AS hearing_1, h2.hearing_id AS hearing_2,
       h1.forum_id, h1.courtroom_id, h1.hearing_date,
       h1.start_time AS start_1, h1.end_time AS end_1,
       h2.start_time AS start_2, h2.end_time AS end_2
FROM hearing h1
JOIN hearing h2 ON h2.courtroom_id = h1.courtroom_id
  AND h2.hearing_date = h1.hearing_date
  AND h2.hearing_id > h1.hearing_id
WHERE h1.courtroom_id IS NOT NULL
  AND h1.start_time IS NOT NULL AND h1.end_time IS NOT NULL
  AND h2.start_time IS NOT NULL AND h2.end_time IS NOT NULL
  AND h1.hearing_status = 'SCHEDULED'
  AND h2.hearing_status = 'SCHEDULED'
  AND h1.start_time < h2.end_time
  AND h2.start_time < h1.end_time;

-- 28. Possible judge double-bookings across benches
SELECT jp.judge_id, person.full_name AS judge_name,
       h1.hearing_id AS hearing_1, h2.hearing_id AS hearing_2,
       h1.hearing_date, h1.start_time AS start_1, h1.end_time AS end_1,
       h2.start_time AS start_2, h2.end_time AS end_2
FROM judge_profile jp
JOIN person ON person.person_id = jp.person_id
JOIN judge_bench_assignment a1 ON a1.judge_id = jp.judge_id
JOIN hearing h1 ON h1.bench_id = a1.bench_id
JOIN judge_bench_assignment a2 ON a2.judge_id = jp.judge_id
JOIN hearing h2 ON h2.bench_id = a2.bench_id
WHERE h2.hearing_id > h1.hearing_id
  AND h1.hearing_date = h2.hearing_date
  AND h1.hearing_status = 'SCHEDULED'
  AND h2.hearing_status = 'SCHEDULED'
  AND h1.start_time IS NOT NULL AND h1.end_time IS NOT NULL
  AND h2.start_time IS NOT NULL AND h2.end_time IS NOT NULL
  AND h1.start_time < h2.end_time
  AND h2.start_time < h1.end_time
  AND a1.start_date <= h1.hearing_date
  AND (a1.end_date IS NULL OR a1.end_date >= h1.hearing_date)
  AND a2.start_date <= h2.hearing_date
  AND (a2.end_date IS NULL OR a2.end_date >= h2.hearing_date);

-- 29. Pending-case age distribution
SELECT current_forum_name, case_age_bucket, COUNT(*) AS case_count
FROM v_pending_case_dashboard
GROUP BY current_forum_name, case_age_bucket
ORDER BY current_forum_name, case_age_bucket;

-- 30. Case transfer history
SELECT ct.case_id, c.cnr, c.case_title,
       from_forum.forum_name AS transferred_from,
       to_forum.forum_name AS transferred_to,
       ct.transfer_date, ct.transfer_reason, ct.order_reference
FROM case_transfer ct
JOIN case_file c ON c.case_id = ct.case_id
JOIN forum from_forum ON from_forum.forum_id = ct.from_forum_id
JOIN forum to_forum ON to_forum.forum_id = ct.to_forum_id
ORDER BY ct.transfer_date DESC;

-- 31. Court staff currently assigned to each forum
SELECT f.forum_name, p.full_name AS staff_name,
       sa.staff_role, sa.start_date, sa.end_date
FROM staff_assignment sa
JOIN court_staff cs ON cs.court_staff_id = sa.court_staff_id
JOIN person p ON p.person_id = cs.person_id
JOIN forum f ON f.forum_id = sa.forum_id
WHERE sa.end_date IS NULL OR sa.end_date >= CURRENT_DATE
ORDER BY f.forum_name, sa.staff_role, staff_name;

-- 32. Cases still pending for more than three years
SELECT case_id, cnr, case_title, current_forum_name,
       current_status_name, filing_date, days_since_filing
FROM v_pending_case_dashboard
WHERE days_since_filing > 1095
ORDER BY days_since_filing DESC;

-- 33. Case details with represented parties and lawyers (replace 1)
SELECT c.case_id, c.cnr, cpr.role_name,
       COALESCE(party_person.full_name, party_org.organization_name) AS party_name,
       lawyer_person.full_name AS lawyer_name,
       lr.appointed_on, lr.ended_on, lr.representation_status
FROM case_file c
JOIN case_party cp ON cp.case_id = c.case_id
JOIN case_party_role cpr ON cpr.party_role_code = cp.party_role_code
JOIN party p ON p.party_id = cp.party_id
LEFT JOIN person party_person ON party_person.person_id = p.person_id
LEFT JOIN organization party_org ON party_org.organization_id = p.organization_id
LEFT JOIN lawyer_representation lr ON lr.case_party_id = cp.case_party_id
LEFT JOIN lawyer_profile lp ON lp.lawyer_id = lr.lawyer_id
LEFT JOIN person lawyer_person ON lawyer_person.person_id = lp.person_id
WHERE c.case_id = 1
ORDER BY cpr.role_name, party_name, lawyer_name;

-- 34. Cases lacking a CNR or current local registration number
SELECT c.case_id, c.case_title, c.filing_date,
       CASE WHEN c.cnr IS NULL THEN TRUE ELSE FALSE END AS missing_cnr,
       CASE WHEN cr.case_registration_id IS NULL THEN TRUE ELSE FALSE END AS missing_current_registration
FROM case_file c
LEFT JOIN case_registration cr ON cr.case_id = c.case_id AND cr.is_current = TRUE
WHERE c.cnr IS NULL OR cr.case_registration_id IS NULL
ORDER BY c.filing_date;

-- 35. Count disposals by month and forum
SELECT co.issuing_forum_id, f.forum_name,
       DATE_TRUNC('month', j.pronouncement_date)::DATE AS disposal_month,
       COUNT(DISTINCT co.case_id) AS cases_with_final_judgment
FROM judgment j
JOIN court_order co ON co.order_id = j.order_id
JOIN forum f ON f.forum_id = co.issuing_forum_id
WHERE j.is_final = TRUE
GROUP BY co.issuing_forum_id, f.forum_name, DATE_TRUNC('month', j.pronouncement_date)
ORDER BY disposal_month, forum_name;
